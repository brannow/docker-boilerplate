#!/usr/bin/env bash

# auto complete script for fast shell access to your docker container
# simply type docker-shell PROJECTNAME ... and press tab!
# replace projectname with your projectname - project directory name

_complete_docker_container_names() {
	local cur=${COMP_WORDS[COMP_CWORD]}
        COMPREPLY=($(compgen -W "$(docker ps | awk '{if(NR>1) print $NF}')" -- $cur))
	return 0
}

docker-shell() {
    docker exec -i -t $1 /bin/bash
}
alias docker-bash=docker-shell
complete -F _complete_docker_container_names docker-shell