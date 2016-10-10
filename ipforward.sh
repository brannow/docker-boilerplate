#!/bin/sh

sudo ifconfig lo0 172.17.0.3 alias
sudo ipfw add fwd 172.17.0.3,80 tcp from me to 127.0.0.1 dst-port 8001 
sudo ipfw add fwd 172.17.0.3,443 tcp from me to 127.0.0.1 dst-port 8443
