package gev

import (
	"log"

	"github.com/Allenxuxu/gev"
	"github.com/Allenxuxu/gev/connection"
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
	return s.srv.Start()
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
func (h *echoHandler) OnMessage(c *connection.Connection, data []byte) interface{} {
	// Echo back the received data
	c.Send(data)
	return nil
}

// OnClose is called when a connection has been closed
func (h *echoHandler) OnClose(c *connection.Connection) {
	log.Printf("OnClose: %s", c.PeerAddr())
}
