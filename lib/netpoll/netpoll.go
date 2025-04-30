package netpoll

import (
	"context"
	"log"
	"net"

	"github.com/cloudwego/netpoll"
)

// Server represents a TCP echo server using netpoll
type Server struct {
	addr string
	ln   net.Listener
}

// NewServer creates a new TCP echo server
func NewServer(addr string) *Server {
	return &Server{
		addr: addr,
	}
}

// Start starts the TCP echo server
func (s *Server) Start() error {
	// Create listener
	ln, err := net.Listen("tcp", s.addr)
	if err != nil {
		return err
	}
	s.ln = ln

	// Create event loop
	eventLoop, err := netpoll.NewEventLoop(
		func(ctx context.Context, connection netpoll.Connection) error {
			// Read data from the connection
			reader := connection.Reader()
			data, err := reader.Next(reader.Len())
			if err != nil {
				return err
			}

			// Echo back the received data
			writer := connection.Writer()
			writer.Write(data)
			return connection.Flush()
		},
		netpoll.WithOnConnect(func(ctx context.Context, connection netpoll.Connection) context.Context {
			log.Printf("OnConnect: %s", connection.RemoteAddr())
			return ctx
		}),
		netpoll.WithOnDisconnect(func(ctx context.Context, connection netpoll.Connection) {
			log.Printf("OnDisconnect: %s", connection.RemoteAddr())
		}),
	)
	if err != nil {
		return err
	}

	log.Printf("TCP echo server listening on %s", s.addr)
	return eventLoop.Serve(ln)
}

// Stop stops the TCP echo server
func (s *Server) Stop() error {
	if s.ln != nil {
		return s.ln.Close()
	}
	return nil
}
