#!/bin/sh

echo "
rdr pass on lo0 inet proto tcp from 172.0.0.1 to any port = 80 -> 127.0.0.1 port 8001
rdr pass on lo0 inet proto tcp from 172.0.0.1 to any port = 443 -> 127.0.0.1 port 8443
" | sudo pfctl -ef -

#sudo pfctl -s nat
#sudo pfctl -F all -f /etc/pf.conf


ifconfig lo0 alias 172.0.0.1
