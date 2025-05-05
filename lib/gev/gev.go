package main

import (
	"fmt"
	"log"
	"sync"

	"github.com/Allenxuxu/gev"
	"github.com/Allenxuxu/gev/connection"
	"github.com/guonaihong/bench-tcp/pkg/port"
)

// Server represents a TCP echo server using gev
type Server struct {
	addr string
	srv  *gev.Server
}

// NewServer creates a new TCP echo server
func NewServer(addr string) *Server {
	return &Server{
		addr: addr,
	}
}

// Start starts the TCP echo server
func (s *Server) Start() error {
	handler := &echoHandler{}
	srv, err := gev.NewServer(handler,
		gev.Network("tcp"),
		gev.Address(s.addr),
	)
	if err != nil {
		return err
	}
	s.srv = srv

	log.Printf("TCP echo server listening on %s", s.addr)
	s.srv.Start()
	return nil
}

// Stop stops the TCP echo server
func (s *Server) Stop() {
	if s.srv != nil {
		s.srv.Stop()
	}
}

// echoHandler implements gev.EventHandler
type echoHandler struct{}

// OnConnect is called when a new connection has been opened
func (h *echoHandler) OnConnect(c *connection.Connection) {
	log.Printf("OnConnect: %s", c.PeerAddr())
}

// OnMessage is called when socket receives data from peer
func (h *echoHandler) OnMessage(c *connection.Connection, ctx interface{}, data []byte) interface{} {
	// Echo back the received data
	c.Send(data)
	return nil
}

// OnClose is called when a connection has been closed
func (h *echoHandler) OnClose(c *connection.Connection) {
	log.Printf("OnClose: %s", c.PeerAddr())
}

func startServer(port int, wg *sync.WaitGroup) {
	defer wg.Done()

	addr := fmt.Sprintf("127.0.0.1:%d", port)
	server := NewServer(addr)
	log.Printf("Starting GEV server on %s", addr)

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
	portRange, err := port.GetPortRange("GEV")
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
