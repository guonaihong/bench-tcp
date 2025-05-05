package main

import (
	"fmt"
	"log"
	"net"
	"sync"

	"github.com/guonaihong/bench-tcp/pkg/port"
)

func startServer(port int, wg *sync.WaitGroup) {
	defer wg.Done()

	ln, err := net.Listen("tcp", fmt.Sprintf(":%d", port))

	if err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}

	for {

		conn, err := ln.Accept()

		if err != nil {
			log.Fatalf("Failed to accept connection: %v", err)
		}

		go func(conn net.Conn) {

			buf := make([]byte, 1024)
			for {
				n, err := conn.Read(buf)
				if err != nil {
					log.Fatalf("Failed to read from connection: %v", err)
				}
				conn.Write(buf[:n])
			}
		}(conn)

	}

}

func main() {
	// Get port range from environment variables
	portRange, err := port.GetPortRange("NET_TCP")
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
