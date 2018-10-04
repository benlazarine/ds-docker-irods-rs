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
The base image will be hosted on Docker Hub in the `cyverse` repository.

All of the sensitive information that would normally be set in the iRODS
configuration files as well as the clerver password have been removed. They must
be provided in a file named `cyverse-secrets.env` that will be loaded at run
time.

docker-compose was chosen as the tool to manage the building of the top level
image as well as starting and stopping its container instance.

```bash
prompt> docker-compose build
prompt> docker-compose up -d
```

If for some reason a base image upgrade doesn't work, the resource server can be
reverted to the last good base image by modifying the Dockerfile to use the tag
of the good image. Used the commands above to redeploy the reverted resource
server.


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
