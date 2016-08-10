# docker-boilerplate

## Requirements
* Docker-Engine ( https://docs.docker.com/engine/installation/linux/ )
* Docker-Compose  ( https://docs.docker.com/compose/install/ )
* Git

## structure
the logic is simple,  
we have a seperate HOSTPROJECTROOT with all project source.  
$HOSTPROJECTROOT/project_a  
$HOSTPROJECTROOT/project_b
$HOSTPROJECTROOT/project_abc  

every project contains a ```docker-compose.yml``` - its the blueprint for the Boilerplate factory.
  The Boilerplate factory generates us the handy docker container.

## Installation
clone the boilerplate onto a good reachable location ( '/var/docker/boilerplate' e.g.)  
for the install script - a alias is a nice thing:
~/.bash_aliases:
```
alias install-project="/var/docker/boilerplate/install-project.sh"
```
make the install-project.sh executeable with:
```
chmod +x /var/docker/boilerplate/install-project.sh
```

## Configuration
### required
in ```install-project.sh``` edit:
```
# system environment
export BOLERPLATEROOT="/var/docker/boilerplate/docker-boilerplate"
HOSTPROJECTROOT="/var/www/projects" 
```

```BOLERPLATEROOT``` is the location for the 'docker-boilerplate' that contains the Dockerfiles
```HOSTPROJECTROOT``` is  your working directory on your local machine.

### optional
*it will use the https://github.com/webdevops/php-docker-boilerplate presets*  

create your own Dockerfile.* under your BOLERPLATEROOT

## create a new project
create a new directory under your HOSTPROJECTROOT and copy the BOLERPLATEROOT/docker-compose.development.yml into (rename to ```docker-compose.yml``` !)  
  
in ```docker-compose.yml```:
in ```app.Dockerfile``` change the name of the Dockerfile if needed (the location is relative ```build: ${BOLERPLATEROOT}``` )  

(sample project: https://github.com/brannow/docker-test-1 )
  
##   install-project.sh

./install-project.sh [PROJECT_DIRECTORY_NAME] [DOCKER_COMPOSE_COMMAND]

the first argument is project directory name in your HOSTPROJECTROOT  
the second, is the docker-compose command (see more: ```docker-compose help```)

install-project.sh check if your HOSTPROJECTROOT contains already the given directory name, if not it will try to download from a git repository:
```
benjamin: ./~$ ./install-project.sh docker-test-123 build
directory not exist, start git clone module
Please enter Repository and Branch in Format: 

Repository: git@github.com/sampleRepository.git
Branch: develop | master | feature/fancyFeature | ...


Enter git Repository:git@github.com:brannow/docker-test-1.git
Enter git branch [develop]: master
clone to '/var/www/projects/docker-test-123' ...
```

lookup for the ```docker-compose.yml``` in the project directory (in this case: ```/var/www/projects/docker-test-123/docker-compose.yml```)
execute with docker-compose (default command is ```build```)  

```
install-project docker-test-123 post-install
```
will execute a install script (composer, npm, database import etc...)
the install script must under ```$HOSTPROJECTROOT/PROJECT_NAME/install.sh```

![](https://raw.githubusercontent.com/brannow/docker-boilerplate/master/tty.gif)


## Start Project
start your container with:
```
docker start container_name
```
or (more comfortable way)
```
install-project my_project_directory start
```