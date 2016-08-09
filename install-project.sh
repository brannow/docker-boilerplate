#!/bin/sh

# system environment
export BOLERPLATEROOT="/var/docker/boilerplate"
HOSTPROJECTROOT="/var/www/projects" 

#########
#
# LOGIC 
#
#########

if [ -z "$1" ]
  then
    echo "No Project name given"
    exit 0
fi
PROJECTDIR=$1
export PROJECTROOT="$HOSTPROJECTROOT/$PROJECTDIR"

# directory not exist start clone logic
if [ ! -d "$PROJECTROOT" ]; then
  
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

git clone $REPOSITORY --branch $BRANCH  $PROJECTROOT

fi

# docker build area

echo "start docker module"
if [ ! -f "$PROJECTROOT/docker-compose.yml" ]; then
   echo "no docker-compose.yml file found in Porject Root -- abort docker module"
fi

COMMAND="build"
if [ ! -z "$2" ]
  then
    COMMAND=$2
fi

docker-compose -f "$PROJECTROOT/docker-compose.yml" $COMMAND
