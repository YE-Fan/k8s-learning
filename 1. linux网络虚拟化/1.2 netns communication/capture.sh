#!/bin/bash
if [ "$#" -ne 1]; then
    echo "Incorect args, Usage:: $0 <interface>"
    exit 1
fi
# sudo apt install tshark
# usage: ./capture.sh veth10

sudo tshark -f "not port 22" -i $1 -T fields \
-e ip.src \
-e ip.dst \
-e frame.protocols \
-E header=y