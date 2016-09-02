# docker-boilerplate

## Requirements
For Linux and MacOS you need [Git](https://git-scm.com/) on your computer.

If you are on Linux please install the following software:

* [Docker-Engine](https://docs.docker.com/engine/installation/linux/)
* [Docker-Compose](https://docs.docker.com/compose/install/)

If you are on MacOS please installe the following software:

* [Docker](https://download.docker.com/mac/stable/Docker.dmg)

## Installation
Open a terminal and clone the boilerplate repository into a reachable location (Linux: `/var/docker/fr-boilerplate`, MacOS: `~/Docker/fr-boilerplate`) on your computer.
```
mkdir ~/Docker/fr-boilerplate && cd ~/Docker/fr-boilerplate
git clone git@github.com:brannow/docker-boilerplate.git dev-boilerplate
```

Make the project shell file `dfr.sh` executable with:
```
cd dev-boilerplate
chmod +x dfr.sh
```

## Configuration
### required

After you cloned the repository copy the `.bash_profile` script into your home directory. If you have already a `.bash_profile` please include the content of the fr-boilerplate `.bash_profile`.

Edit your `.bash_profile` and uncomment the correct export variables and aliases.
On Linux look for the `#Linux` comment, on MacOS look for `#MacOS`.

We use an alias for the helper scripts `dfr` so you can use dfr on your terminal. `dfr` is a abbrevation for 'docker familie redlich'.
The variable `BOILERPLATEROOT` point to your cloned fr-boilerplate repository. `HOSTPROJECTROOT` must point to the folder where you store your webroot projects inside.

### optional
*it will use the https://github.com/webdevops/php-docker-boilerplate presets*  

Create your own Dockerfile.* under your BOILERPLATEROOT (`environment-sbahn.development.yml`).

## Structure
The logic for setting up projects is pretty straight forward. We have a variable `HOSTPROJECTROOT` (/Users/$(whoami)/Projects) with all your project sources inside.
And to this variable the project folders are attached to identfy the place where to map the web folder inside your container.
For example:

* $HOSTPROJECTROOT/project_a  
* $HOSTPROJECTROOT/project_b
* $HOSTPROJECTROOT/project_abc  

Every project must contains a new `docker-compose.yml` - its the blueprint for the fr-boilerplate factory.
The boilerplate factory generates us the docker container.

## Setup a new project
Create a new directory under your HOSTPROJECTROOT (`$HOSTPROJECTROOT/project_a`), copy the BOILERPLATEROOT/docker-compose.development.yml file into your project root.
As default we provide PHP5.6, mysql5.7 and Apache2.4, if you want to start a PHP7 project use the Dockerfile-php70.development file.

**Rename the file inside your project root to `docker-compose.yml`**
  
???? in ```app.Dockerfile``` change the name of the Dockerfile if needed (the location is relative ```build: ${BOLERPLATEROOT}``` ) ????  
  
### Script Helper dfr.sh
Open a terminal and change your path to your projects folder (`~/Projects`). If you set the alias correct you can use from now on `dfr` on your terminal.

The script follows the principle of `./dfr.sh [PROJECT_DIRECTORY_NAME] [DOCKER_COMPOSE_COMMAND]`.
The first argument is project directory name in your HOSTPROJECTROOT  
The second, is the docker-compose command (see more: `docker-compose help`)

Assuming your project is called `project_a`, type `dfr project_a build` inside your terminal.
The first launch of the docker containers can took a while, next projects will be start in seconds. Grab yourself a coffee and what for magic. :)
 
dfr.sh checks if your HOSTPROJECTROOT contains already the given directory name, if not it will try to download from a git repository:
```
benjamin: ./~$ ./dfr.sh project_a build
directory not exist, start git clone module
Please enter Repository and Branch in Format: 

Repository: git@github.com/sampleRepository.git
Branch: develop | master | feature/fancyFeature | ...

Enter git Repository:git@github.com:brannow/docker-test-1.git
Enter git branch [develop]: master
clone to '/Users/b.rannow/Projects/project_a' ...
```

The script takes the `docker-compose.yml` in the project directory (in this case: `/Users/b.rannow/Projects/project_a/docker-compose.yml`)
and execute it with docker-compose (default command is `build`)  

```
dfr project_a post-install
```

will execute the next install scripts (composer, npm, etc...). If you want to customize your project further you can create a `docker-install.sh` inside your project folder and install other software.

![gif-Magic](https://raw.githubusercontent.com/brannow/docker-boilerplate/master/tty.gif)

### Work with an existing project
If you start working on a existing project again you just have to start the docker container with.
```
dfr project_a up
```

## Commands

dfr [PROJECT_NAME] [COMMAND]

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
dumped the given database into a bzip-file (only the given DB-name)

``` restore [sql-source] ```   
restore a database dump into the database

``` inject-key [host_key_path] [(optional default=id_rsa) container_key_name] ```   
 copy from host system into a running container an ssh private key

## Start Project
Start your container with:

```
docker start container_name
```

or (more comfortable way)

```
install-project my_project_directory up
```

## Default Behaviors
Docker will create at the first startup the same IP's every build/start please do not count on it, use the url at the end of the script.

**Under macOS there is currently a bug with the IP expose. You have to use locahost:8001.**

```
> dfr project_a up
Creating project_a_mysql_1
Creating project_a_app_1
container id: 24b24afaf3dc351c4fbae24491138320cc6247a2570a402c7780988dfe67310f
container is running...
container ip: 172.18.0.6
url: http://172.18.0.6
```

### MySQL
For the database connection use `mysql` as hostname. Username is `root` and password `dev`

#### Import the database
For importing the database you need a .sql file with a `CREATE DATABASE` statement inside. So docker can create and setup the correct database.
If your .sql file for exmaple is called db_1235.sql use the following command. At the moment only .sql and .bz files are supported.

**The .sql file has to be stored unter your project root (`project_a/data/db/db_1235.sql`)**
```
dfr project_a restore db_1235.sql
```

#### Exporting the database
If you export the database a .bz archive is always created. The export command is build like `dfr project_a backup-db #databasename# #target#.bz`
```
dfr project_a backup-db typo3 typo3.bz
```

## Public Keys Injector
If you need to pull from key restricted repository you have to copy your public keys to the docker container. Lucky for you we have a script ready.
```
dfr project_a inject-key ~/.ssh/id_rsa
```

### What commands are implemented?
Have a look at `dfr --help`

### UNIX Permissions
The BUILD task will execute a bootstrap script that set the container Webserver user permissions to the same as your working Directory (HOSTPROJECTROOT)   

example: your Host system user runs with userid 1000  and every file in your project root is owned by your system user   

the container working directory will have the same user rights. Per default the webserver runs in a seperate user (www-data) it will give conflicts if we don't change this.

1. the bootstrap script looks for current user id and group id of your HOSTPROJECTROOT and checked if this is already existing on your image, if nor create a new user (docker-user:docker-group) with the correct user and group ids.
2. Inject the compatible user/Group in the apache2/envvars.

NOTE: this is NOT a proper Production behavior! it makes your life easier ONLY for Development.
don't mess with your Production user system!
