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
Tue Dec 19 17:21:45 UTC 2017

prompt> ./build

prompt> docker images
REPOSITORY                    TAG                   IMAGE ID            CREATED              SIZE
cyverse/ds-irods-rs-onbuild   2017-12-19T17-21-46   56654afeedbf        9 seconds ago       457MB
cyverse/ds-irods-rs-onbuild   latest                56654afeedbf        9 seconds ago       457MB
irods-dev-build               4.1.10-centos7        82b9967cb458        About a minute ago   719MB
irods-plugin-build            4.1.10-centos7        4565bc1db9fe        3 minutes ago        730MB
centos                        7                     3fa822599e10        2 weeks ago          204MB
```

## Repository Dependencies

This repository has two subtrees. The master branch of the
https://github.com/cyverse/irods-netcdf-build is attached to the directory
`irods-netcdf-build`. The master branch of the
https://github.com/cyverse/irods-setavu-plugin is attached to the directory
`irods-setavu-plugin`.
