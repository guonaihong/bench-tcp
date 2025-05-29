#!/bin/bash

make clean
make

# Run benchmark with 10,000 concurrent connections
"$(dirname "$0")/benchmark-core.sh" 1000 120s

# Exit with the same status as the core script
exit $? 
