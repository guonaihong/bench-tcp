#!/bin/bash

# Source the config file
source "$(dirname "$0")/config.sh"

# Function to get port range for a server
get_port_range() {
    local lib_name=$1
    local start_var="${lib_name^^}_START_PORT"  # Convert to uppercase
    local end_var="${lib_name^^}_END_PORT"
    start_var=${start_var//-/_}  # Replace - with _ for variable names
    end_var=${end_var//-/_}
    
    # Use indirect reference to get the values
    echo "${!start_var} ${!end_var}"
}

# Function to start a server
start_server() {
    local lib_name=$1
    local port_range
    port_range=$(get_port_range "$lib_name")
    read -r start_port end_port <<< "$port_range"
    
    echo "Starting $lib_name server on port range $start_port-$end_port"
    
    # Start the server in the background
    cd "$(dirname "$0")/../lib/$lib_name" || exit 1
    go run . &
    
    # Store the PID
    echo $! > "/tmp/bench-tcp-$lib_name.pid"
}

# Start enabled servers
for server in "${ENABLED_SERVERS[@]}"; do
    start_server "$server"
done

echo "All enabled servers started. PIDs stored in /tmp/bench-tcp-*.pid"
echo "Use stop-servers.sh to stop all servers" 