package main

import (
	"flag"
	"fmt"
	"log"
	"sync"

	"github.com/guonaihong/bench-tcp/pkg/port"
	"github.com/panjf2000/gnet/v2"
)

type echoServer struct {
	gnet.BuiltinEventEngine

	eng       gnet.Engine
	addr      string
	multicore bool
}

func (es *echoServer) OnBoot(eng gnet.Engine) gnet.Action {
	es.eng = eng
	log.Printf("echo server with multi-core=%t is listening on %s\n", es.multicore, es.addr)
	return gnet.None
}

func (es *echoServer) OnTraffic(c gnet.Conn) gnet.Action {
	buf, _ := c.Next(-1)
	c.Write(buf)
	return gnet.None
}

func startServer(port int, multicore bool, wg *sync.WaitGroup) {
	defer wg.Done()

	addr := fmt.Sprintf("tcp://127.0.0.1:%d", port)
	echo := &echoServer{
		addr:      addr,
		multicore: multicore,
	}

	log.Printf("Starting gnet server on %s", addr)
	if err := gnet.Run(echo, echo.addr, gnet.WithMulticore(multicore)); err != nil {
		log.Printf("Server on port %d failed: %v", port, err)
	}
}

func main() {
	var multicore bool
	flag.BoolVar(&multicore, "multicore", false, "--multicore true")
	flag.Parse()

	// Get port range from environment variables
	portRange, err := port.GetPortRange("GNET")
	if err != nil {
		log.Fatalf("Failed to get port range: %v", err)
	}

	var wg sync.WaitGroup

	// Start a server for each port in the range
	for port := portRange.Start; port <= portRange.End; port++ {
		wg.Add(1)
		go startServer(port, multicore, &wg)
	}

	// Wait for all servers to exit
	wg.Wait()
}
