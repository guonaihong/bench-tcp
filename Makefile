all: build-linux build-mac

build-linux:
	GOOS=linux GOARCH=amd64 go build -o bench-tcp.linux ./cmd/bench-tcp/bench-tcp.go

build-mac:
	GOOS=darwin GOARCH=amd64 go build -o bench-tcp.mac ./cmd/bench-tcp/bench-tcp.go