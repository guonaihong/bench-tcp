#!/bin/bash

# Run benchmark with 1,000,000 concurrent connections
"$(dirname "$0")/benchmark-core.sh" 1000000 100s

# Exit with the same status as the core script
exit $? 