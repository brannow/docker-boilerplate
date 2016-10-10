#!/bin/sh

# add this script in the login hook
# MAC ONLY
# defaults write com.apple.loginwindow LoginHook /Users/benjamin/Docker/docker-boilerplate/inject_docker_ip.sh
# edit the path to the script location

# you can additionaly add a fancy hostname e.g. 'docker' as sample hostname in your /etc/hosts
#172.0.0.1    docker

# then you can call all your docker container with the hostname 'docker' without any ip and ports


echo "
rdr pass on lo0 inet proto tcp from 172.0.0.1 to any port = 80 -> 127.0.0.1 port 8001
rdr pass on lo0 inet proto tcp from 172.0.0.1 to any port = 443 -> 127.0.0.1 port 8443
" | sudo pfctl -ef -

#sudo pfctl -s nat
#sudo pfctl -F all -f /etc/pf.conf

ifconfig lo0 alias 172.0.0.1
