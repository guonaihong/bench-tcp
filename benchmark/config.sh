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
NET_TCP_START_PORT=1000
NET_TCP_END_PORT=1030

# Second port range (18080-18120)
UIO_START_PORT=1100
UIO_END_PORT=1130

# Third port range (28080-28120)
EVIO_START_PORT=1200
EVIO_END_PORT=1230

# Fourth port range (38080-38120)
NETPOLL_START_PORT=1300
NETPOLL_END_PORT=1330

# Fifth port range (48080-48120)
GNET_START_PORT=1400
GNET_END_PORT=1430

# Sixth port range (58080-58120)
GEV_START_PORT=1500
GEV_END_PORT=1530

# Seventh port range (68080-68120)
NBIO_START_PORT=1600
NBIO_END_PORT=1630

# Eighth port range (78080-78120)
RPCX_START_PORT=1700
RPCX_END_PORT=1730

# Ninth port range (88080-88120)
GRPC_START_PORT=1800
GRPC_END_PORT=1830

# Tenth port range (98080-98120)
THRIFT_START_PORT=1900
THRIFT_END_PORT=1930 