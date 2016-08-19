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
will execute a install script (composer, npm, etc...)
the install script must under ```$HOSTPROJECTROOT/PROJECT_NAME/docker-install.sh```

![](https://raw.githubusercontent.com/brannow/docker-boilerplate/master/tty.gif)


## Commands

install-project.sh [PROJECT_NAME] [COMMAND]

PROJECT_NAME: is the name of the project folder under $1
COMMAND: all docker-compose commands are supported
for more information exec 'docker-compose help'

``` install ```   
execute the docker-install.sh script in the container

``` create [type=] ```   
dumped the given database into a file

``` backup [sql-destination] ```   
dumped the given database into a bzip-file (ALL DATABASES)

``` backup-db [DB-name] [sql-destination] ```   
dumped the given database into a bzip-file (ALL DATABASES)

``` restore [sql-source] ```   
restore a database dump into the database

``` inject-key [host_key_path] [(optional default=id_rsa) container_key_name] ```   
 copy from host system into a running container an ssh private key

## Start Project
start your container with:
```
docker start container_name
```
or (more comfortable way)
```
install-project my_project_directory up
```
## Default Behaviors
Docker will create at the first sign the same IP's every build/start don't count on it, use the url at the end of the script.  

```
> install-project docker-test up
Creating dockertest_mysql_1
Creating dockertest_app_1
container id: 24b24afaf3dc351c4fbae24491138320cc6247a2570a402c7780988dfe67310f
container is running...
container ip: 172.18.0.6
url: http://172.18.0.6

```

### MySQL
connect your project NOT to the mysql docker ip use instead ```mysql``` as hostname - it will be updates in the app-container hosts file  

mysql_username: root  
mysql_password: dev  

### UNIX Permissions
the BUILD task will execute a bootstrap script that set the container Webserver user permissions to the same as your working Directory (HOSTPROJECTROOT)   

example: your Host system user runs with userid 1000  and every file in your project root is owned by your system user   

the container working directory will have the same user rights. Per default the webserver runs in a seperate user (www-data) it will give conflicts if we don't change this.

1. the bootstrap script looks for current user id and group id of your HOSTPROJECTROOT and checked if this is already existing on your image, if nor create a new user (docker-user:docker-group) with the correct user and group ids.
2. Inject the compatible user/Group in the apache2/envvars.

NOTE: this is NOT a proper Production behavior! it makes your life easier ONLY for Development.
don't mess with your Production user system!
