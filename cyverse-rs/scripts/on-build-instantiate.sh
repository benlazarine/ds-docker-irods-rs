#! /bin/bash
#
# Usage:
#  on-build-instantiate
#
# This program expands the build time templates.
#
# To allow iRODS to run as a non-root user and still mount volumes, this script
# allows for the ability to run iRODS with as a user from the docker host
# server. To do this, set the environment variable IRODS_HOST_UID to the UID of 
# the host user to run iRODS as.
#
# This program expects the following environment variables to be defined.
#
# IRODS_CLERVER_USER  the name of the rodsadmin user representing the resource 
#                     server within the zone
# IRODS_DEFAULT_RES   the name of coordinating resource this server will use by 
#                     default
# IRODS_HOST_UID      (optional) the UID of the hosting server to run iRODS as 
#                     instead of the default user defined in the container
# IRODS_RES_SERVER    the FQDN or address used by the rest of the grid to 
#                     communicate with this server
# IRODS_STORAGE_RES   the unix file system resource to server

set -e


main()
{
  local irodsZoneName
  irodsZoneName=$(jq -r '.irods_zone_name' /var/lib/irods/.irods/irods_environment.json)

  jq_in_place \
    "(.host_entries[] | select(.address_type == \"local\") | .addresses)
       |= . + [{\"address\": \"$IRODS_RES_SERVER\"}]" \
    /etc/irods/hosts_config.json

  jq_in_place \
    ".default_resource_directory |= \"/irods_vault/$IRODS_STORAGE_RES\" |
     .default_resource_name      |= \"$IRODS_DEFAULT_RES\" |
     .zone_user                  |= \"$IRODS_CLERVER_USER\"" \
    /etc/irods/server_config.json

  jq_in_place \
    ".irods_cwd              |= \"/iplant/home/$IRODS_CLERVER_USER\" |
     .irods_default_resource |= \"$IRODS_DEFAULT_RES\" |
     .irods_home             |= \"/iplant/home/$IRODS_CLERVER_USER\" |
     .irods_host             |= \"$IRODS_RES_SERVER\" |
     .irods_user_name        |= \"$IRODS_CLERVER_USER\"" \
    /var/lib/irods/.irods/irods_environment.json

  sed --in-place "s/__IRODS_DEFAULT_RES__/$IRODS_DEFAULT_RES/" /etc/irods/ipc-env.re

  local hostUID
  if [ -n "$IRODS_HOST_UID" ]
  then
    hostUID="$IRODS_HOST_UID"
  else
    hostUID=$(id --user irods)
  fi

  useradd --no-create-home --non-unique \
          --comment 'iRODS Administrator (host user)' \
          --groups irods \
          --home-dir /var/lib/irods \
          --shell /bin/bash \
          --uid "$hostUID" \
          irods-host-user

  mkdir --mode ug+w /irods_vault/"$IRODS_STORAGE_RES"
  chown irods:irods /irods_vault/"$IRODS_STORAGE_RES"
}


jq_in_place()
{
  local filter="$1"
  local file="$2"

  jq "$filter" "$file" | awk 'BEGIN { RS=""; getline<"-"; print>ARGV[1] }' "$file"
}


main
