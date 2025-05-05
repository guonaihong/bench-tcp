#!/bin/bash

# Run benchmark with 10,000 concurrent connections
"$(dirname "$0")/benchmark-core.sh" 10000 100s

# Exit with the same status as the core script
exit $? 