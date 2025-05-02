package main

import (
	"log"

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

func main() {
	server := NewServer("127.0.0.1:58080")
	server.Start()
	defer server.Stop()

	<-make(chan int)
}
