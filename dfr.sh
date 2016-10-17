#!/bin/sh

# system environment

PROJECTDIR=$1
export PROJECTROOT="$HOSTPROJECTROOT/$PROJECTDIR"
KERNEL='L'
case "$OSTYPE" in
  linux*)   KERNEL="L" ;;
  darwin*)  KERNEL="D" ;; 
  win*)     KERNEL="W" ;;
  cygwin*)  KERNEL="W" ;;
  bsd*)     KERNEL="D" ;;
  solaris*) KERNEL="L" ;;
  *)        KERNEL="U" ;;
esac

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
  echo "dfr.sh [PROJECT_NAME] [COMMAND]"
  echo ""
  echo "    PROJECT_NAME: is the name of the project folder under $1"
  echo "    COMMAND: all docker-compose commands are supported"
  echo "             for more information exec 'docker-compose help'"
  echo ""
  echo "    install"
  echo "              execute the docker-install.sh script in the container"
  echo ""
  echo "    backup [sql-destination]"
  echo "              dumped the given database into a bzip-file (ALL DATABASES)"
  echo ""
  echo "    backup-db [DB-name] [sql-destination]"
  echo "              dumped the given database into a bzip-file (ALL DATABASES)"
  echo ""
  echo "    restore [sql-source]"
  echo "              restore a database dump into the database"
  echo ""
  echo "    inject-key [host_key_path] [(optional default=id_rsa) container_key_name]"
  echo "              copy from host system into a running container an ssh private key"
}


#########
# DOCKER COMPOSE
#########
_docker_exec()
{
  # docker build area
  if [ ! -f "$PROJECTROOT/docker-compose.yml" ]; then
    echo "no docker-compose.yml file found in Porject Root -- abort docker module"
    exit 1
  fi

  COMMAND=$1
  if [ ! -z "$1" ]
    then
      if [ "$1" = "up" ]
        then
          COMMAND="$1 -d"
      fi
      docker-compose -f "$PROJECTROOT/docker-compose.yml" $COMMAND
  fi


}

#########
# GIT CLONE
#########
_git_clone()
{
  # directory not exist start clone logic
  if [ ! -z $PROJECTROOT ] && [ ! -d "$PROJECTROOT" ]; then

  echo "directory not exist, start git clone module"
  echo "Please enter Repository and Branch in Format: "
  echo ""
  echo "Repository: git@github.com/sampleRepository.git"
  echo "Branch: develop | master | feature/fancyFeature | ..."
  echo ""
  echo ""
  echo -n 'Enter git Repository:'
  read REPOSITORY
  echo -n 'Enter git branch [develop]:'
  read BRANCH

  if [ -z "$BRANCH" ]; then
    BRANCH="develop"
  fi

  if [ -z "$REPOSITORY"  ] || [ -z "$BRANCH" ]; then
     echo "Repository or branch is empty -- abort"
     exit 1
  fi

  git clone $REPOSITORY --branch $BRANCH $PROJECTROOT

  fi
}

#########
# post exec project script
#########
_post_install()
{
  if [ ! -f "$PROJECTROOT/docker-install.sh" ]; then
        echo "under $PROJECTROOT, no docker-install.sh found"
       exit 1;
  fi

  _docker_exec "up"

  CONTAINER_ID=$(docker-compose -f $PROJECTROOT/docker-compose.yml ps -q app)
  USERID=$(docker exec -i $CONTAINER_ID sh -c "stat -c '%u' /usr/local/bin")
  echo "exec as $USERID"
  docker exec -i -u $USERID $CONTAINER_ID sh docker-install.sh $CONTAINER_ID
  echo "done."
  _call_container
}

#########
# output container information
#########
_call_container()
{
    CONTAINER_ID=$(docker-compose -f $PROJECTROOT/docker-compose.yml ps -q app)
    if [ ! -z "$CONTAINER_ID" ]
     then
        RUNNING=$(docker inspect --format="{{ .State.Running }}" $CONTAINER_ID 2> /dev/null)

        if [ ! "$RUNNING" = "false" ]; then
            echo "container id: $CONTAINER_ID"
            echo "container status: running"

            CONTAINER_IP=$(docker inspect -f '{{ .NetworkSettings.IPAddress }}' $CONTAINER_ID)
            if [ ! -z "$CONTAINER_IP" ]
            then
                echo "container ip: $CONTAINER_IP"
                echo "url: http://$CONTAINER_IP"
                #echo "open default browser"
                #/bin/bash sensible-browser "http://$CONTAINER_IP" &
            else
                echo "container is not reachable"
            fi
        fi
     else
     echo "container ID not found"
     exit 1
    fi
}

#########
# database
#########

_database_backup()
{
    CONTAINER_ID=$(docker-compose -f $PROJECTROOT/docker-compose.yml ps -q app)

    if [ -z "$CONTAINER_ID" ]; then
        echo "cannot find docker container... abort"
        exit 1
    fi

    MYSQL_CONTAINER_ID=$(docker-compose -f $PROJECTROOT/docker-compose.yml ps -q mysql)
    APP_RUNNING=$(docker inspect --format="{{ .State.Running }}" $CONTAINER_ID 2> /dev/null)
    MYSQL_RUNNING=$(docker inspect --format="{{ .State.Running }}" $MYSQL_CONTAINER_ID 2> /dev/null)

    if [ "$APP_RUNNING" = "true" ] && [ "$MYSQL_RUNNING" = "true" ]
    then
        echo "app and mysql container are running ... extract databases"
        cd $PROJECTROOT
        docker exec -i $CONTAINER_ID mysqldump --opt --single-transaction --add-drop-database --events --all-databases --routines --comments | bzip2 > $1
        echo "Done."
    fi
}

_database_single_backup()
{
    CONTAINER_ID=$(docker-compose -f $PROJECTROOT/docker-compose.yml ps -q app)

    if [ -z "$CONTAINER_ID" ]; then
        echo "cannot find docker container... abort"
        exit 1
    fi

    MYSQL_CONTAINER_ID=$(docker-compose -f $PROJECTROOT/docker-compose.yml ps -q mysql)
    APP_RUNNING=$(docker inspect --format="{{ .State.Running }}" $CONTAINER_ID 2> /dev/null)
    MYSQL_RUNNING=$(docker inspect --format="{{ .State.Running }}" $MYSQL_CONTAINER_ID 2> /dev/null)

    if [ "$APP_RUNNING" = "true" ] && [ "$MYSQL_RUNNING" = "true" ]
    then
        echo "app and mysql container are running ... extract databases"
        cd $PROJECTROOT
        if [ ! -z "$1" ]; then
            docker exec -i $CONTAINER_ID mysqldump --opt --single-transaction --add-drop-database --events --routines --comments --databases $1 | bzip2 > $2
            echo "Done."
        fi
    fi
}

_database_restore()
{
    CONTAINER_ID=$(docker-compose -f $PROJECTROOT/docker-compose.yml ps -q app)

    if [ -z "$CONTAINER_ID" ]; then
        echo "cannot find docker container... abort"
        exit 1
    fi

    MYSQL_CONTAINER_ID=$(docker-compose -f $PROJECTROOT/docker-compose.yml ps -q mysql)
    APP_RUNNING=$(docker inspect --format="{{ .State.Running }}" $CONTAINER_ID 2> /dev/null)
    MYSQL_RUNNING=$(docker inspect --format="{{ .State.Running }}" $MYSQL_CONTAINER_ID 2> /dev/null)

    if [ "$APP_RUNNING" = "true" ] && [ "$MYSQL_RUNNING" = "true" ]
    then
        echo "app and mysql container are running ... restore database"
        cd $PROJECTROOT
        if [ ! -f "$1" ]; then
            echo "No Database file found"
            exit 1
        fi

        FILE_TYPE=$(file -b $1 | awk '{print $1}')
        echo "detect $1 as $FILE_TYPE file"
        IS_INJECTED=0
        if [ $FILE_TYPE = "UTF-8" ]; then
            echo "inject Plain SQL data"
            cat "$1" | docker exec -i $CONTAINER_ID mysql
            IS_INJECTED=1
        fi

        if [ $FILE_TYPE = "bzip2" ]; then
            echo "inject bzip2 SQL data"
            bzcat "$1" | docker exec -i $CONTAINER_ID mysql
            IS_INJECTED=1
        fi

        if [ ! $IS_INJECTED = 1 ]; then
            echo "unknown file type ... abort"
            exit 1
        fi

        echo "FLUSH PRIVILEGES;" | docker exec -i $CONTAINER_ID mysql
        echo "Done."
    fi
}

#########
# SSH KEY
#########

_inject_ssh_key()
{
    if [ ! -f "$1" ]; then
        echo "key not found - abort"
        exit 1
    fi

    SSH_KEY=$(cat $1)
    KEY_NAME="id_rsa"
    if [ ! -z "$2" ]; then
        KEY_NAME=$2
    fi

    CONTAINER_ID=$(docker-compose -f $PROJECTROOT/docker-compose.yml ps -q app)
    USERID=$(docker exec -i $CONTAINER_ID sh -c "stat -c '%u' /usr/local/bin")
    docker exec -i -u $USERID $CONTAINER_ID sh -c "mkdir -p ~/.ssh && echo '$SSH_KEY' > ~/.ssh/$KEY_NAME && chmod 600 ~/.ssh/$KEY_NAME"
    docker exec -i -u $USERID $CONTAINER_ID sh -c "if [ ! -f ~/.ssh/config ]; then echo 'Host github.com\n\tStrictHostKeyChecking no\nHost frs.plan.io\n\tStrictHostKeyChecking no\n' > ~/.ssh/config; fi"
    docker exec -i -u $USERID $CONTAINER_ID sh -c "echo 'IdentityFile ~/.ssh/$KEY_NAME\n' >> ~/.ssh/config"
    docker exec -i -u $USERID $CONTAINER_ID sh -c 'cd ~ && eval $(ssh-agent) && ssh-add'
}

#########
# MAIN
#########

hash docker 2>/dev/null || { echo >&2 "docker engine not installed.  Aborting."; exit 1; }
hash docker-compose 2>/dev/null || { echo >&2 "docker-compose not installed.  Aborting."; exit 1; }

if [ -z "$1" ]
  then
    _help $HOSTPROJECTROOT
    exit 1
fi

#if [ "$2" = "post-install" ]
#   then
#        _post_install $PROJECTROOT
#   else
#        _git_clone $PROJECTROOT
#        _docker_exec $2
#        _call_container $PROJECTROOT
#fi



case "$2" in
    install)
        _post_install
        ;;

    backup)
        _database_backup $3
        ;;

    inject-key)
        _inject_ssh_key $3 $4
        ;;

    backup-db)
        _database_single_backup $3 $4
        ;;

    restore)
        _database_restore $3
        ;;

    create)
        echo "create new empty project - soon"
        ;;

    *)
         _git_clone
        _docker_exec $2
        _call_container
        exit 1

esac

exit 1
