package main

import (
	"fmt"
	"log"
	"runtime"
	"sync"

	"github.com/guonaihong/bench-tcp/pkg/port"
	"github.com/lesismal/nbio"
)

// Server represents a TCP echo server using nbio
type Server struct {
	engine *nbio.Engine
}

// NewServer creates a new TCP echo server
func NewServer(addr string) *Server {
	engine := nbio.NewEngine(nbio.Config{
		Network:            "tcp",
		Addrs:              []string{addr},
		MaxWriteBufferSize: 6 * 1024 * 1024,
		NPoller:            runtime.NumCPU(),
		EpollMod:           nbio.EPOLLET,
	})

	// handle new connection
	engine.OnOpen(func(c *nbio.Conn) {
		log.Printf("OnOpen: %s", c.RemoteAddr().String())
	})

	// handle connection closed
	engine.OnClose(func(c *nbio.Conn, err error) {
		log.Printf("OnClose: %s, err: %v", c.RemoteAddr().String(), err)
	})

	// handle data
	engine.OnData(func(c *nbio.Conn, data []byte) {
		// echo back the received data
		c.Write(data)
	})

	return &Server{
		engine: engine,
	}
}

// Start starts the TCP echo server
func (s *Server) Start() error {
	return s.engine.Start()
}

// Stop stops the TCP echo server
func (s *Server) Stop() {
	s.engine.Stop()
}

func startServer(port int, wg *sync.WaitGroup) {
	defer wg.Done()

	addr := fmt.Sprintf("127.0.0.1:%d", port)
	server := NewServer(addr)
	log.Printf("Starting NBIO server on %s", addr)

	if err := server.Start(); err != nil {
		log.Printf("Server on port %d failed: %v", port, err)
		return
	}
	defer server.Stop()

	// Keep the server running
	select {}
}

func main() {
	// Get port range from environment variables
	portRange, err := port.GetPortRange("NBIO")
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
