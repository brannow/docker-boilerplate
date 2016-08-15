#!/bin/sh

# system environment
export BOLERPLATEROOT="/var/docker/boilerplate/docker-boilerplate"
HOSTPROJECTROOT="/var/www/projects"


PROJECTDIR=$1
export PROJECTROOT="$HOSTPROJECTROOT/$PROJECTDIR"

#########
#
# LOGIC
#
#########

#########
# PRINT HELP
#########
_help()
{
  echo "install-project.sh [PROJECT_NAME] [COMMAND]"
  echo ""
  echo "    PROJECT_NAME: is the name of the project folder under $1"
  echo "    COMMAND: all docker-compose commands are supported"
  echo "             for more information exec 'docker-compose help'"
  echo ""
  echo "             'post-install' is a special command it will execute"
  echo "             a install.sh bash script, under the project directory"
}


#########
# DOCKER COMPOSE
#########
_docker_exec()
{
  # docker build area
  if [ ! -f "$PROJECTROOT/docker-compose.yml" ]; then
    echo "no docker-compose.yml file found in Porject Root -- abort docker module"
    exit 0
  fi

  COMMAND="build"
  if [ ! -z "$1" ]
    then
      COMMAND=$1
  fi

  if [ "$1" = "up" ]
    then
      COMMAND="$1 -d"
  fi

  docker-compose -f "$PROJECTROOT/docker-compose.yml" $COMMAND
}

#########
# GIT CLONE
#########
_git_clone()
{
  # directory not exist start clone logic
  if [ ! -z $1 ] && [ ! -d "$1" ]; then

  echo "directory not exist, start git clone module"
  echo "Please enter Repository and Branch in Format: "
  echo ""
  echo "Repository: git@github.com/sampleRepository.git"
  echo "Branch: develop | master | feature/fancyFeature | ..."
  echo ""
  echo ""
  echo -n "Enter git Repository:"
  read REPOSITORY
  echo -n "Enter git branch [develop]: "
  read BRANCH

  if [ -z "BRANCH" ]; then
    BRANCH="develop"
  fi

  if [ -z "$REPOSITORY"  ] || [ -z "BRANCH" ]; then
     echo "Repository or branch is empty -- abort"
     exit 0
  fi

  git clone $REPOSITORY --branch $BRANCH $1

  fi
}

#########
# post exec project script
#########
_post_install()
{
  if [ ! -f "$1/docker-install.sh" ]; then
        echo "under $1, no docker-install.sh found"
       exit 0;
  fi

  _docker_exec "up"
  sleep 5

  CONTAINER_ID=$(docker-compose -f $1/docker-compose.yml ps -q app)

  (cd $1 && sh $1/docker-install.sh "$CONTAINER_ID")
}

#########
# output container information
#########
_call_container()
{
    CONTAINER_ID=$(docker-compose -f $1/docker-compose.yml ps -q app)
    if [ ! -z "$CONTAINER_ID" ]
     then
        RUNNING=$(docker inspect --format="{{ .State.Running }}" $CONTAINER_ID 2> /dev/null)

        if [ ! "$RUNNING" = "false" ]; then
            echo "container id: $CONTAINER_ID"
            echo "container is running..."

            CONTAINER_IP=$(docker inspect -f '{{ .NetworkSettings.IPAddress }}' $CONTAINER_ID)
            if [ ! -z "$CONTAINER_IP" ]
            then
                echo "container ip: $CONTAINER_IP"
                echo "url: http://$CONTAINER_IP"
                #echo "open default browser"
                #/bin/bash sensible-browser "http://$CONTAINER_IP" &
            else
                echo "container is not running"
            fi
        fi
     else
     echo "container ID not found"
     exit 0
    fi
}

#########
# MAIN
#########

hash docker 2>/dev/null || { echo >&2 "Docker not installed.  Aborting."; exit 1; }
hash docker-compose 2>/dev/null || { echo >&2 "Docker not installed.  Aborting."; exit 1; }

if [ -z "$1" ]
  then
    _help $HOSTPROJECTROOT
    exit 0
fi

if [ "$2" = "post-install" ]
   then
        _post_install $PROJECTROOT
   else
        _git_clone $PROJECTROOT
        _docker_exec $2
        _call_container $PROJECTROOT
fi
exit 0
