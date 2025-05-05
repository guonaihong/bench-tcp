#!/bin/bash

# Source the config file to get ENABLED_SERVERS
source "$(dirname "$0")/config.sh"

# Export port ranges as environment variables for lib servers
for server in "${ENABLED_SERVERS[@]}"; do
    # Convert server name to uppercase and replace - with _
    server_upper=$(echo "$server" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
    start_var="${server_upper}_START_PORT"
    end_var="${server_upper}_END_PORT"
    
    # Export port ranges to environment variables
    export "$server_upper"_START_PORT="${!start_var}"
    export "$server_upper"_END_PORT="${!end_var}"
    echo "Exported $server_upper port range: ${!start_var}-${!end_var}"
done

# Start all enabled servers
echo "Starting servers..."
"$(dirname "$0")/start-servers.sh"

# Wait a bit for servers to be ready
sleep 2

# Detect OS type to use correct binary
OSTYPE=$(uname -s)
if [[ "$OSTYPE" == "Linux" ]]; then
    BENCH_BIN="bin/bench-tcp.linux"
elif [[ "$OSTYPE" == "Darwin" ]]; then
    BENCH_BIN="bin/bench-tcp.mac"
else
    echo "Unsupported OS: $OSTYPE"
    exit 1
fi

# Run benchmarks for each enabled server
echo "Running benchmarks..."
for server in "${ENABLED_SERVERS[@]}"; do
    echo "Benchmarking $server..."
    
    # Convert server name to uppercase and replace - with _
    server_upper=$(echo "$server" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
    start_var="${server_upper}_START_PORT"
    end_var="${server_upper}_END_PORT"
    
    # Run bench-tcp with port range
    echo "Testing $server on port range ${!start_var}-${!end_var}..."
    
    if [ ! -x "$BENCH_BIN" ]; then
        echo "Error: Benchmark executable not found or not executable: $BENCH_BIN"
        exit 1
    fi
    
    "$BENCH_BIN" -d 100s -c 100000 --addr "127.0.0.1:${!start_var}-${!end_var}" --open-tmp-result
    #"$BENCH_BIN" -n 1000000 --addr "127.0.0.1:${!start_var}-${!end_var}" --open-tmp-result
done

# Stop all servers
echo "Stopping servers..."
"$(dirname "$0")/stop-servers.sh"

echo "Benchmark complete!" 