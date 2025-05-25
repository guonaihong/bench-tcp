/*
 * Copyright 2024 the urpc project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package main

import (
	"fmt"
	"log"
	"os"
	"os/signal"
	"sync"

	"github.com/guonaihong/bench-tcp/pkg/port"
	"github.com/urpc/uio"
)

func startServer(port int, wg *sync.WaitGroup, quit chan os.Signal) {
	defer wg.Done()

	var events uio.Events

	events.MaxBufferSize = 8 * 1024
	events.FullDuplex = true
	events.OnOpen = func(c uio.Conn) {
		c.SetNoDelay(true)
		// log.Printf("[%d] connection opened: %s", port, c.RemoteAddr())
	}

	events.OnData = func(c uio.Conn) error {
		_, err := c.WriteTo(c)
		return err
	}

	events.OnClose = func(c uio.Conn, err error) {
		// log.Printf("[%d] connection closed: %s", port, c.RemoteAddr())
	}

	go func() {
		s := <-quit
		events.Close(fmt.Errorf("received signal: %v", s))
	}()

	addr := fmt.Sprintf("127.0.0.1:%d", port)
	log.Printf("Starting UIO server on %s", addr)

	if err := events.Serve(fmt.Sprintf(":%d", port)); err != nil {
		log.Printf("Server on port %d failed: %v", port, err)
	}
}

func main() {
	// Get port range from environment variables
	portRange, err := port.GetPortRange("UIO")
	if err != nil {
		log.Fatalf("Failed to get port range: %v", err)
	}

	// Setup signal handling
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, os.Interrupt, os.Kill)

	var wg sync.WaitGroup

	// Start a server for each port in the range
	for port := portRange.Start; port <= portRange.End; port++ {
		wg.Add(1)
		go startServer(port, &wg, quit)
	}

	// Wait for all servers to exit
	wg.Wait()
}
