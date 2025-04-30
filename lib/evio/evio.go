package evio

import (
	"log"

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
		log.Printf("Opened: %s", c.RemoteAddr().String())
		return
	}

	// Handle connection closed
	events.Closed = func(c evio.Conn, err error) (action evio.Action) {
		log.Printf("Closed: %s, err: %v", c.RemoteAddr().String(), err)
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
