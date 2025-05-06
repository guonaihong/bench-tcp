/*
 * Copyright 2021 CloudWeGo
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package main

import (
	"context"
	"fmt"
	"log"
	"sync"
	"time"

	"github.com/bytedance/gopkg/util/gopool"
	"github.com/cloudwego/netpoll"
	"github.com/guonaihong/bench-tcp/pkg/port"
)

var _ netpoll.OnPrepare = prepare
var _ netpoll.OnConnect = connect
var _ netpoll.OnRequest = handle
var _ netpoll.CloseCallback = close

func prepare(connection netpoll.Connection) context.Context {
	return context.Background()
}

func close(connection netpoll.Connection) error {
	// fmt.Printf("[%v] connection closed\n", connection.RemoteAddr())
	return nil
}

func connect(ctx context.Context, connection netpoll.Connection) context.Context {
	// fmt.Printf("[%v] connection established\n", connection.RemoteAddr())
	connection.AddCloseCallback(close)
	return ctx
}

func handle(ctx context.Context, connection netpoll.Connection) error {
	reader, writer := connection.Reader(), connection.Writer()
	defer reader.Release()

	msg, _ := reader.ReadString(reader.Len())
	// fmt.Printf("[recv msg] %v\n", msg)

	writer.WriteString(msg)
	writer.Flush()

	return nil
}

func startServer(port int, wg *sync.WaitGroup) {
	defer wg.Done()

	gopool.SetCap(100000)

	netpoll.Configure(netpoll.Config{
		Runner: func(ctx context.Context, task func()) {
			task()
		},
	})
	network, address := "tcp", fmt.Sprintf("127.0.0.1:%d", port)
	listener, err := netpoll.CreateListener(network, address)
	if err != nil {
		log.Printf("Failed to create listener on port %d: %v", port, err)
		return
	}

	eventLoop, err := netpoll.NewEventLoop(
		handle,
		netpoll.WithOnPrepare(prepare),
		netpoll.WithOnConnect(connect),
		netpoll.WithReadTimeout(time.Second),
	)
	if err != nil {
		log.Printf("Failed to create event loop on port %d: %v", port, err)
		return
	}

	log.Printf("Starting Netpoll server on %s", address)
	if err := eventLoop.Serve(listener); err != nil {
		log.Printf("Server on port %d failed: %v", port, err)
	}
}

func main() {
	// Get port range from environment variables
	portRange, err := port.GetPortRange("NETPOLL")
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
