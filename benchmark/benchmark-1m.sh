#!/bin/bash

# Source the config file to get ENABLED_SERVERS
source "$(dirname "$0")/config.sh"

# Start all enabled servers
echo "Starting servers..."
"$(dirname "$0")/start-servers.sh"

# Wait a bit for servers to be ready
sleep 2

# Function to get start and end ports for a server
get_port_range() {
    local server=$1
    # Convert server name to uppercase and replace - with _
    local server_upper=$(echo "$server" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
    local start_var="${server_upper}_START_PORT"
    local end_var="${server_upper}_END_PORT"
    echo "${!start_var} ${!end_var}"
}

# Run benchmarks for each enabled server
echo "Running benchmarks..."
for server in "${ENABLED_SERVERS[@]}"; do
    echo "Benchmarking $server..."
    # Get port range for this server
    read start_port end_port <<< $(get_port_range "$server")
    
    # Run bench-tcp with port range
    echo "Testing $server on port range $start_port-$end_port..."
    ../bench-tcp -n 1000000 -addr "127.0.0.1:$start_port-$end_port"
done

# Stop all servers
echo "Stopping servers..."
"$(dirname "$0")/stop-servers.sh"

echo "Benchmark complete!" 