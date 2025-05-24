package main

import (
	"bufio"
	"bytes"
	"context"
	"crypto/md5"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net"
	"os"
	"strconv"
	"strings"
	"sync"
	"sync/atomic"
	"time"

	_ "net/http/pprof"

	"github.com/guonaihong/bench-tcp/pkg/port"
	"github.com/guonaihong/bench-tcp/report"
	"github.com/guonaihong/clop"
)

// https://github.com/snapview/tokio-tungstenite/blob/master/examples/autobahn-client.rs

// --verify-file 用于检查向服务端发送一个大文件，服务端echo返回的数据是否一致，用于检查服务端是否有丢包
// ./bench-tcp --verify-file /path/to/file.txt --addr localhost:8080
type Client struct {
	Addr           string        `clop:"short;long" usage:"server address (e.g., ws://host:port or ws://host:minport-maxport)" default:""`
	Name           string        `clop:"short;long" usage:"Server name" default:""`
	Label          string        `clop:"long" usage:"Title of the chart for the line graph" default:""`
	Total          int           `clop:"short;long" usage:"Total number of runs" default:"100"`
	PayloadSize    int           `clop:"short;long" usage:"Size of the payload" default:"1024"`
	Conns          int           `clop:"long" usage:"Number of connections" default:"10000"`
	Concurrency    int           `clop:"short;long" usage:"Number of concurrent goroutines" default:"1000"`
	Duration       time.Duration `clop:"short;long" usage:"Duration of the test"`
	OpenCheck      bool          `clop:"long" usage:"Perform open check"`
	OpenTmpResult  bool          `clop:"long" usage:"Display temporary result"`
	JSON           bool          `clop:"long" usage:"Output JSON result"`
	Text           string        `clop:"long" usage:"Text to send"`
	SaveErr        bool          `clop:"long" usage:"Save error log"`
	LimitPortRange int           `clop:"short;long" usage:"Limit port range (1 for limited, -1 for unlimited)" default:"1"`
	VerifyFile     string        `clop:"long" usage:"File path to verify echo content"`
	Debug          bool          `clop:"long" usage:"Debug mode"`
	mu             sync.Mutex

	result []int

	addrs []string
	index int64

	ctx    context.Context
	cancel context.CancelCauseFunc
}

func (c *Client) getAddrs() string {
	curIndex := int(atomic.AddInt64(&c.index, 1))
	return c.addrs[curIndex%len(c.addrs)]
}

var recvCount int64
var sendCount int64

var payload []byte

// var payload = []byte()

type echoHandler struct {
	// done chan struct{}
	data  chan struct{}
	total int
	curr  int

	*Client
}

func (e *echoHandler) sendFile(c net.Conn) (fileContent []byte, expectedMD5 [16]byte) {
	// Calculate expected MD5
	file, err := os.Open(e.VerifyFile)
	if err != nil {
		fmt.Printf("Error opening file: %v\n", err)
		return
	}
	defer file.Close()

	// Read file content
	fileContent, err = io.ReadAll(file)
	if err != nil {
		fmt.Printf("Error reading file: %v\n", err)
		return
	}

	// Calculate MD5 of file content
	expectedMD5 = md5.Sum(fileContent)

	go func() {
		br := bufio.NewReader(bytes.NewReader(fileContent))
		total := 0
		buf := make([]byte, 1024)
		sendBytes := []byte{}
		for {
			n, err := br.Read(buf)
			if err != nil {
				fmt.Printf("read file error: %v\n", err)

				break
			}
			c.Write(buf[:n])
			sendBytes = append(sendBytes, buf[:n]...)
			total += n
			fmt.Printf("send bytes size: %d\n", total)
		}

		fmt.Printf("file send done, total: %d, send bytes md5: %x\n", total, md5.Sum(sendBytes))
	}()

	return fileContent, expectedMD5
}

func (e *echoHandler) readLoop(c net.Conn) {
	buf := make([]byte, 1024)
	var receivedData []byte
	var expectedMD5 [16]byte

	var fileContent []byte
	if e.VerifyFile != "" {
		fileContent, expectedMD5 = e.sendFile(c)
	}

	for {
		n, err := c.Read(buf)
		if err != nil {
			fmt.Printf("read socket error: %v\n", err)
			return
		}
		atomic.AddInt64(&recvCount, 1)

		if e.VerifyFile != "" {
			receivedData = append(receivedData, buf[:n]...)
			if len(receivedData) == len(fileContent) {
				// Calculate MD5 of received data
				fmt.Printf("recv bytes size: %d\n", len(receivedData))
				receivedMD5 := md5.Sum(receivedData)
				if receivedMD5 != expectedMD5 {
					fmt.Printf("MD5 verification failed. Expected: %x, Got: %x\n", expectedMD5, receivedMD5)
					if e.SaveErr {
						os.WriteFile("fileContent.send.log", fileContent, 0644)
						os.WriteFile("fileContent.recv.log", receivedData, 0644)
					}
					panic("MD5 verification failed")
				}
				fmt.Printf("MD5 verification successful: %x\n", receivedMD5)
				c.Close()
				return
			}
		}

		if e.VerifyFile == "" {
			c.Write(buf[:n])
		}

		if e.OpenCheck {
			if !bytes.Equal(buf[:n], payload) {
				if e.SaveErr {
					os.WriteFile(fmt.Sprintf("%x.err.log", c), payload, 0644)
					os.WriteFile(fmt.Sprintf("%v.success.log", c), buf, 0644)
				}
				panic("payload not equal")
			}
		}
		atomic.AddInt64(&sendCount, 1)

		if e.VerifyFile == "" {
			select {
			case _, ok := <-e.data:
				if !ok {
					c.Close()
					if e.Debug {
						fmt.Printf("data chan close\n")
					}
					return
				}
			default:
			}
		}
	}
}

func (client *Client) runTest(currTotal int, data chan struct{}) {
	curAddr := client.getAddrs()
	c, err := net.Dial("tcp", curAddr)
	if err != nil {
		fmt.Printf("Dial %s, fail:%v\n", curAddr, err)
		return
	}

	if client.VerifyFile == "" {
		c.Write(payload)
	}
	(&echoHandler{Client: client, curr: currTotal, total: currTotal, data: data}).readLoop(c)
}

// 生产者
func (c *Client) producer(data chan struct{}) {
	defer func() {
		close(data)

		if c.OpenTmpResult {
			fmt.Printf("bye bye producer\n")
		}
	}()

	// 如果设置了验证文件，则不进行生产者生产数据
	if c.VerifyFile != "" {
		return
	}
	if c.Duration > 0 {
		tk := time.NewTicker(c.Duration)
		for {
			select {
			case <-tk.C:
				// 时间到了
				// 排空chan
				for {
					select {
					case <-data:
					default:
						return
					}
				}
			case data <- struct{}{}:
			}
		}
	} else {
		for i := 0; i < c.Total; i++ {
			data <- struct{}{}
		}
	}
}

// 消费者
func (c *Client) consumer(data chan struct{}) {
	var wg sync.WaitGroup
	wg.Add(c.Concurrency)
	defer func() {
		wg.Wait()
		c.cancel(errors.New("wait all consumer done"))
		if !c.JSON {
			for i, v := range c.result {
				fmt.Printf("%ds:%d/s ", i+1, v)
			}
		}
		fmt.Printf("\n")
	}()

	for i := 0; i < c.Concurrency; i++ {
		go func(i int) {
			defer wg.Done()

			c.runTest(c.Total/c.Concurrency, data)
			if c.Debug {
				fmt.Printf("bye bye consumer:%d\n", i)
			}
		}(i)
	}
}

func (c *Client) printTps(now time.Time, sec *int) {
	recvCount := atomic.LoadInt64(&recvCount)
	sendCount := atomic.LoadInt64(&sendCount)
	n := int64(time.Since(now).Seconds())
	if n == 0 {
		n = 1
	}

	if c.OpenTmpResult {
		fmt.Printf("sec: %d, recv-count: %d, send-count:%d recv-tps: %d, send-tps: %d\n", *sec, recvCount, sendCount, recvCount/n, sendCount/n)
	}

	c.mu.Lock()
	c.result = append(c.result, int(recvCount/n))
	c.mu.Unlock()
}

func (c *Client) tpsLog(now time.Time) {
	nw := time.NewTicker(time.Second)
	sec := 1
	for {
		select {
		case <-nw.C:
			c.printTps(now, &sec)
			sec++
			nw.Reset(time.Second)
		case <-c.ctx.Done():
			if c.JSON {
				var d report.Dataset
				d.Label = c.Label
				d.Data = c.result
				d.Tension = 0.1
				all, err := json.Marshal(d)
				if err != nil {
					panic(err)
				}

				os.Stdout.Write(all)
			}
			return
		}
	}
}

func (c *Client) initAddrs() error {
	if c.Addr == "" {
		return fmt.Errorf("addr is required")
	}

	// Check if the address contains a port range
	if strings.Contains(c.Addr, ":") {
		parts := strings.Split(c.Addr, ":")
		if len(parts) != 2 {
			return fmt.Errorf("invalid address format")
		}

		host := parts[0]
		portStr := parts[1]

		// Check if it's a port range
		if strings.Contains(portStr, "-") {
			portRange := strings.Split(portStr, "-")
			if len(portRange) != 2 {
				return fmt.Errorf("invalid port range format")
			}

			start, err := strconv.Atoi(portRange[0])
			if err != nil {
				return fmt.Errorf("invalid start port: %v", err)
			}

			end, err := strconv.Atoi(portRange[1])
			if err != nil {
				return fmt.Errorf("invalid end port: %v", err)
			}

			// Generate addresses for the port range
			for port := start; port <= end; port++ {
				c.addrs = append(c.addrs, fmt.Sprintf("%s:%d", host, port))
			}
		} else {
			// Single port
			c.addrs = []string{c.Addr}
		}
	} else {
		// Try to get port range from environment variables
		if c.Name != "" {
			portRange, err := port.GetPortRange(c.Name)
			if err == nil {
				host := c.Addr
				for p := portRange.Start; p <= portRange.End; p++ {
					c.addrs = append(c.addrs, fmt.Sprintf("%s:%d", host, p))
				}
			} else {
				// Fallback to single address
				c.addrs = []string{c.Addr}
			}
		} else {
			c.addrs = []string{c.Addr}
		}
	}

	if len(c.addrs) == 0 {
		return fmt.Errorf("no valid addresses found")
	}

	return nil
}

func main() {
	var client Client
	clop.Bind(&client)

	// Initialize addresses with port ranges
	if err := client.initAddrs(); err != nil {
		fmt.Printf("Error initializing addresses: %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("addrs: %v\n", client.addrs)

	// Initialize payload
	if client.Text != "" {
		payload = []byte(client.Text)
	} else {
		payload = make([]byte, client.PayloadSize)
		for i := 0; i < client.PayloadSize; i++ {
			payload[i] = 'a'
		}
	}

	// Create context
	client.ctx, client.cancel = context.WithCancelCause(context.Background())

	data := make(chan struct{})

	var wg sync.WaitGroup
	wg.Add(2)
	defer wg.Wait()

	go func() {
		defer wg.Done()
		client.producer(data)
	}()
	go func() {
		defer wg.Done()
		client.consumer(data)
	}()

	go client.tpsLog(time.Now())
}
