#!/bin/bash

# Array of enabled servers (uncomment the ones you want to run)
ENABLED_SERVERS=(
     "net-tcp"
    # "uio"
    # "evio"
    # "netpoll"
    # "gnet"
    # "gev"
    #"nbio"
    #"pulse"
)

# Port ranges for different libraries
# Format: LIB_NAME_START_PORT-LIB_NAME_END_PORT

# First port range (1000-1030)
NET_TCP_START_PORT=1000
NET_TCP_END_PORT=1030

# Second port range (1100-1130)
UIO_START_PORT=1100
UIO_END_PORT=1130

# Third port range (1200-1230)
EVIO_START_PORT=1200
EVIO_END_PORT=1230

# Fourth port range (1300-1330)
NETPOLL_START_PORT=1300
NETPOLL_END_PORT=1330

# Fifth port range (1400-1430)
GNET_START_PORT=1400
GNET_END_PORT=1430

# Sixth port range (1500-1530)
GEV_START_PORT=1500
GEV_END_PORT=1530

# Seventh port range (1600-1630)
NBIO_START_PORT=1600
# NBIO_END_PORT=1600
NBIO_END_PORT=1630

# Eighth port range (1700-1730)
PULSE_START_PORT=1700
PULSE_END_PORT=1730
