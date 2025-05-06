package main

import (
	"context"
	"fmt"
	"log"
	"log/slog"
	"sync"

	_ "net/http/pprof"

	"github.com/antlabs/pulse"
	"github.com/guonaihong/bench-tcp/pkg/port"
)

// 必须是空结构体
type handler struct{}

func (h *handler) OnOpen(c *pulse.Conn, err error) {
	if err != nil {
		fmt.Println("OnOpen error:", err)
		return
	}
	fmt.Println("OnOpen success")
}

func (h *handler) OnData(c *pulse.Conn, data []byte) {

	c.Write(data)
}

func (h *handler) OnClose(c *pulse.Conn, err error) {
	if err != nil {
		fmt.Println("OnClose error:", err)
		return
	}
	fmt.Println("OnClose success")
}

func startServer(port int, wg *sync.WaitGroup) {
	defer wg.Done()

	// Start pulse echo server
	el, err := pulse.NewMultiEventLoop(
		context.Background(),
		pulse.WithCallback(&handler{}),
		pulse.WithLogLevel[[]byte](slog.LevelError),
		pulse.WithTaskType[[]byte](pulse.TaskTypeInEventLoop),
		pulse.WithTriggerType[[]byte](pulse.TriggerTypeEdge),
		pulse.WithEventLoopReadBufferSize[[]byte](8*1024),
	)
	if err != nil {
		panic(err.Error())
	}

	slog.Info("Pulse echo server started on :%d", port)
	el.ListenAndServe(fmt.Sprintf(":%d", port))
}

func main() {

	go func() {
		// http.ListenAndServe(":6060", nil)
	}()
	// Get port range from environment variables
	portRange, err := port.GetPortRange("PULSE")
	if err != nil {
		log.Fatalf("Failed to get port range: %v", err)
	}

	var wg sync.WaitGroup

	// Start a server for each port in the range
	for port := portRange.Start; port <= portRange.End; port++ {
		wg.Add(1)
		go startServer(port, &wg)
	}

	// Wait for all servers to exit
	wg.Wait()
}
