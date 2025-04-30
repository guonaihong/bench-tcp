package gnet

import (
	"context"
	"log"
	"time"

	"github.com/panjf2000/gnet/v2"
)

// Server represents a TCP echo server using gnet
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
	log.Printf("TCP echo server listening on %s", s.addr)
	return gnet.Run(&echoServer{addr: s.addr}, s.addr)
}

// Stop stops the TCP echo server
func (s *Server) Stop() error {
	return gnet.Stop(context.Background(), s.addr)
}

// echoServer implements gnet.EventHandler
type echoServer struct {
	gnet.BuiltinEventEngine
	addr string
}

// OnBoot is called when the engine is ready for accepting connections
func (es *echoServer) OnBoot(eng gnet.Engine) (action gnet.Action) {
	log.Printf("echo server is listening on %s", es.addr)
	return
}

// OnOpen is called when a new connection has been opened
func (es *echoServer) OnOpen(c gnet.Conn) (out []byte, action gnet.Action) {
	log.Printf("OnOpen: %s", c.RemoteAddr().String())
	return
}

// OnClose is called when a connection has been closed
func (es *echoServer) OnClose(c gnet.Conn, err error) (action gnet.Action) {
	log.Printf("OnClose: %s, err: %v", c.RemoteAddr().String(), err)
	return
}

// OnTraffic is called when socket receives data from peer
func (es *echoServer) OnTraffic(c gnet.Conn) (action gnet.Action) {
	// Read data from the connection
	data, _ := c.Next(-1)

	// Echo back the received data
	c.Write(data)
	return
}

// OnTick is called when the engine ticks
func (es *echoServer) OnTick() (delay time.Duration, action gnet.Action) {
	return time.Second, gnet.None
}
