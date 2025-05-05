#!/bin/bash

# This is a core benchmark script that can be called with different parameters
# Usage: benchmark-core.sh [concurrency] [duration] [extra_args]
# Example: benchmark-core.sh 10000 100s

# Default values
CONCURRENCY=${1:-10000}  # Default to 10k connections if not specified
DURATION=${2:-100s}      # Default to 100 seconds if not specified
EXTRA_ARGS=${3:-""}      # Additional arguments to pass to bench-tcp

# Stop any existing servers first
echo "Stopping any existing servers..."
"$(dirname "$0")/stop-servers.sh"

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

echo "Running benchmarks with concurrency: $CONCURRENCY, duration: $DURATION"

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
    
    # Run the benchmark with specified parameters
    "$BENCH_BIN" -d "$DURATION" -c "$CONCURRENCY" --addr "127.0.0.1:${!start_var}-${!end_var}" --open-tmp-result $EXTRA_ARGS
done

# Stop all servers
echo "Stopping servers..."
"$(dirname "$0")/stop-servers.sh"

echo "Benchmark complete!" 