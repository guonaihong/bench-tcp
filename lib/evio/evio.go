package main

import (
	"fmt"
	"log"
	"sync"

	"github.com/guonaihong/bench-tcp/pkg/port"
	"github.com/tidwall/evio"
)

// Server represents a TCP echo server using evio
type Server struct {
	addr string
}

// NewServer creates a new TCP echo server
func NewServer(addr string) *Server {
	return &Server{
		addr: addr,
	}
}

// Start starts the TCP echo server
func (s *Server) Start() error {
	var events evio.Events
	events.NumLoops = -1 // Use the default number of loops

	// Handle new connections
	events.Serving = func(srv evio.Server) (action evio.Action) {
		log.Printf("TCP echo server listening on %s", s.addr)
		return
	}

	// Handle data
	events.Data = func(c evio.Conn, in []byte) (out []byte, action evio.Action) {
		// Echo back the received data
		out = in
		return
	}

	// Handle connection opened
	events.Opened = func(c evio.Conn) (out []byte, opts evio.Options, action evio.Action) {
		opts.ReuseInputBuffer = true
		// log.Printf("Opened: %s", c.RemoteAddr().String())
		return
	}

	// Handle connection closed
	events.Closed = func(c evio.Conn, err error) (action evio.Action) {
		// log.Printf("Closed: %s, err: %v", c.RemoteAddr().String(), err)
		return
	}

	// Start the server
	return evio.Serve(events, "tcp://"+s.addr)
}

// Stop stops the TCP echo server
func (s *Server) Stop() error {
	// evio doesn't provide a way to stop the server
	// The server will stop when the process exits
	return nil
}

func startServer(port int, wg *sync.WaitGroup) {
	defer wg.Done()

	addr := fmt.Sprintf("127.0.0.1:%d", port)
	server := NewServer(addr)
	log.Printf("Starting EVIO server on %s", addr)

	if err := server.Start(); err != nil {
		log.Printf("Server on port %d failed: %v", port, err)
		return
	}
}

func main() {
	// Get port range from environment variables
	portRange, err := port.GetPortRange("EVIO")
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
