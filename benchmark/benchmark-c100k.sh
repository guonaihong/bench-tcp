#!/bin/bash


make clean
make

# Run benchmark with 100,000 concurrent connections
"$(dirname "$0")/benchmark-core.sh" 100000 100s

# Exit with the same status as the core script
exit $? 