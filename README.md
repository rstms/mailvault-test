mailvault-config
----------------

## Overview

This project is used to administer a mailvault installation on a Windows 10 machine.

[Mailvault](https://github.com/rstms/mailvault) is a containerized multiservice system
which implements a local cache of a remote IMAP server, automatically syncronizing the
contents.  The mail directories are stored in an encrypted-at-rest filesystem located
in the docker local volume.

Multiple mailstore instances are configured by creating files in the local docker volume,
and entries in the file `docker-compose.yml`.  

For each instance, the following files are needed:
Path | Created | Description 
---- | ------- | -----------
<INSTANCE>.key | manually at installation | encryption key for mail backing store and configuration files
<INSTANCE>.yml | manually at installation | ansible-vault encrypted config file referenced on each instance startup
<INSTANCE>.dat | automatically during first startup | backing store for LUKS-encrypted mail partition


## Prerequisites:

 - [Docker Desktop](https://docs.docker.com/docker-for-windows/install/)
 - credentials for IMAP server user accounts


## Initial Configuration

**Warning!** If a mailvault exists, these commands can *destroy* it!  Proceed with care.

Choose configuration values:

Value         | Example  | File               | Description
------------- | -------- | ------------------ | ---------------------
name          | mv-test  | config.yml         | Instance name used for various components of system.
device        | loop0    | config.yml         | Loopback device `/dev/loopX` used within the docker VM, must be unique for each instance.
image-size    | loop0    | config.yml         | Loopback device `/dev/loopX` used within the docker VM, must be unique for each instance.
ssh-port      | 10022    | docker-compose.yml | listen port for admin connections  
imap-port     | 10443    | docker-compose.yml | imap port for mail client confguration  



Choose an instance name, for example `m-test`  

The instance name will be used for various components of the system:
 - docker container name: `mv-test` visible in `docker ps`
 - key file used for the data and config files: mv-test.key
 - data store file: `mv-test.dat` 
 - startup configuration file: `mv-test.yml`


Create the local docker volume:
```
docker volume create mailstore
```

Create a key file for the instance:
```
mailvault key >mailstore-test.key
```

Copy the key to the volume:
```
mailvault put mailstore-test.key
```

Create the configuration file `mv-test.yml`:
```
name: mv-test
device: loop1
image_size: 2
imap_server: imap.cypress-trading.com
sudo_user: mkrueger
imap_users:
  mkrueger: { uid: 1000, gid: 1000, password: XXXXXX }
  test1: { uid: 1025, gid: 1027, password: XXXXXX }
  test2: { uid: 1026, gid: 1028, password: XXXXXX }
  test3: { uid: 1027, gid: 1029, password: XXXXXXX }
```

Copy the configuration to the mailvault:
```
mailvault put mv-test.yml
```

Delete the local configuration file:
```
del mv-test.yml
```

Encrypt the config file:
```
mailvault encrypt mv-test.yml mv-test.key
```

Edit the `docker-compose.yml` file:
```
version: '3'

volumes:
  mailvault:
    external: true

services:
  mv-test:
    container_name: mv-test
    hostname: mv-test
    image: "rstms/mailvault:latest"
    privileged: true
    ports:
      - "10022:22"
      - "10143:143"
    volumes:
      - mailvault:/var/vault
```

Start the mailvault instances:
```
docker-compose up
```

The first time this starts, it will create the encrypted volume and
begin synchronization.  The volume will persist across shutdown/restart
of the system as well as the docker container.

At this point the local email program may be configured to access the IMAP server at the listen port configured
in `docker-compose.yml`  In the example, the server is at 127.0.0.1:10022 The protocol is unencrypted IMAP with a plain-text password.
