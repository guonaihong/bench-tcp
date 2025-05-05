#!/bin/bash

# Array of enabled servers (uncomment the ones you want to run)
ENABLED_SERVERS=(
    # "net-tcp"
    # "uio"
    # "evio"
    # "netpoll"
    # "gnet"
    # "gev"
    "nbio"
)

# Port ranges for different libraries
# Format: LIB_NAME_START_PORT-LIB_NAME_END_PORT

# First port range (8080-8120)
NET_TCP_START_PORT=8080
NET_TCP_END_PORT=8120

# Second port range (18080-18120)
UIO_START_PORT=18080
UIO_END_PORT=18120

# Third port range (28080-28120)
EVIO_START_PORT=28080
EVIO_END_PORT=28120

# Fourth port range (38080-38120)
NETPOLL_START_PORT=38080
NETPOLL_END_PORT=38120

# Fifth port range (48080-48120)
GNET_START_PORT=48080
GNET_END_PORT=48120

# Sixth port range (58080-58120)
GEV_START_PORT=58080
GEV_END_PORT=58120

# Seventh port range (68080-68120)
NBIO_START_PORT=68080
NBIO_END_PORT=68120

# Eighth port range (78080-78120)
RPCX_START_PORT=78080
RPCX_END_PORT=78120

# Ninth port range (88080-88120)
GRPC_START_PORT=88080
GRPC_END_PORT=88120

# Tenth port range (98080-98120)
THRIFT_START_PORT=98080
THRIFT_END_PORT=98120 