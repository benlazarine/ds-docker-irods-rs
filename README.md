# ds-docker-irods-rs

A docker image intended to be a base image for an iRODS resource server
configured for the CyVerse Data Store.

## Design

The containerized resource server is designed so that it is as simple as
possible for a trusted third party organization to support given the following
constraints.

* Other than the resource server being off line, down time at the third party
  site should not impact the CyVerse Data Store.
* Maintenance of the resource server can be done by CyVerse without requiring
  full root access to the hosting server.
* Failed upgrades can be easily reverted.
* Sensitive information is stored in a separate artifact from the rest of the
  deployment logic.

The container logic consists of two image layers. The base image holds all of
the logic common to all Data Store resource servers. The top level image holds
all of the logic that is specific to the resource server inside the container.
This repository provides the source for the base image. At some point it will be
hosted on Docker Hub in the `cyverse` repository.

The base image requires several Docker configuration values that need to be
defined at either the build time of a derivative image or the run time of a
container. The ones that need to be defined at build time should be provided as
build arguments, while the ones that need to be defined at run time should be
provided as environment variables.

Here are the required build arguments.

Build Argument               | Required | Default       | Description
---------------------------- | -------- | ------------- | -----------
`CYVERSE_DS_CLERVER_USER`    | no       | ipc_admin     | the name of the rodsadmin user representing the resource server within the zone
`CYVERSE_DS_DEFAULT_RES`     | no       | CyVerseRes    | the name of the resource to use by default during direct client connnections to this resource server
`CYVERSE_DS_HOST_UID`        | no       |               | the UID of the hosting server to run iRODS as instead of the default user defined in the container
`CYVERSE_DS_RES_SERVER`      | yes      |               | the FQDN or address used by the rest of the grid to communicate with this server
`CYVERSE_DS_STORAGE_RES`     | yes      |               | the name of the unix file system resource that will be served

Here are the required environment variables.

Environment Variable           | Description
------------------------------ | -----------
`CYVERSE_DS_CLERVER_PASSWORD`  | the password used to authenticate `CYVERSE_DS_CLERVER_USER`
`CYVERSE_DS_CONTROL_PLANE_KEY` | the encryption key required for communicating over the relevant iRODS grid control plane
`CYVERSE_DS_NEGOTIATION_KEY`   | the encryption key shared by the iplant zone for advanced negotiation during client connections
`CYVERSE_DS_ZONE_KEY`          | the shared secret used during server-to-server communication

The base image provides following volumes that should be mapped to a container
host's filesystem.

Volume                                 | Description
-------------------------------------- | -----------
`/irods_vault/$CYVERSE_DS_STORAGE_RES` | This is the vault holding the files served by the contained resource server. `$CYVERSE_DS_STORAGE_RES` is the build argument mentioned above.
`/var/lib/irods/iRODS/server/log`      | This is the location where the log files will be written.
`/var/lib/irods/iRODS/server/log/proc` | This is the location where agent PID files are kept. It should be mounted as a `tmpfs`.

The base image exposes the following IP ports.

Port(s)         | Purpose
--------------- | -------
1247/tcp        | This is the port used for iRODS zone communication, both client-server and server-server.
1248/tcp        | This is the port used for iRODS grid communication.
20000-20009/tcp | This is the ephemeral port range used for parallel transfers and client reconnections.
20000-20009/udp | This is the ephemeral port range used for RBUDP based file transfers.

## Building the Base Image

The base image is named _cyverse/ds-irods-rs-onbuild_. The command `./build` can
be used to build it.

Each time an image is built, it is tagged with the UTC time when the build
started. The tag has an ISO 8601 style form
_**yyyy**-**MM**-**dd**T**hh**-**mm**-**ss**_ where _**yyyy**_ is the four digit
year, _**MM**_ is the two digit month of the year number, _**dd**__ is the two
digit day of the month number, _**hh**_ is the two digit hour of the day,
_**mm**_ is the two digit minutes past the hour, and _**ss**_ is the two digit
seconds past the minute. The _latest_ tag will point to the most recent build.

```bash
prompt> date -u
Thu Oct  4 17:31:13 UTC 2018

prompt> ./build

prompt> docker images
REPOSITORY                    TAG                   IMAGE ID            CREATED             SIZE
cyverse/ds-irods-rs-onbuild   2018-10-04T17-31-34   173d2520be37        6 seconds ago       455MB
cyverse/ds-irods-rs-onbuild   latest                173d2520be37        6 seconds ago       455MB
irods-dev-build               4.1.10-centos7        4bb3f8ba5f7a        2 minutes ago       689MB
irods-plugin-build            4.1.10-centos7        c9c136645a08        3 minutes ago       700MB
centos                        7                     5182e96772bf        8 weeks ago         200MB
```

## Repository Dependencies

This repository has two subtrees. The master branch of the
https://github.com/cyverse/irods-netcdf-build is attached to the directory
`irods-netcdf-build`. The master branch of the
https://github.com/cyverse/irods-setavu-plugin is attached to the directory
`irods-setavu-plugin`.
