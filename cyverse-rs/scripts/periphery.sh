#!/bin/bash


main()
{
  local cmd="$*"

  case "$cmd" in
    before_start)
      set_server_secrets
      ;;
    after_start)
      set_resource_status up
      ;;
    before_stop)
      set_resource_status down
      ;;
    after_stop)
      ;;
    *)
      ;;
  esac
}


jq_in_place()
{
  local filter="$1"
  local file="$2"

  jq "$filter" "$file" | awk 'BEGIN { RS=""; getline<"-"; print>ARGV[1] }' "$file"
}


set_resource_status()
{
  local status="$1"

  printf 'bringing %s %s\n' "$IRODS_STORAGE_RES" "$status"
  iadmin modresc "$IRODS_STORAGE_RES" status "$status"
}


set_server_secrets()
{
  jq_in_place \
    ".irods_server_control_plane_key |= \"$IRODS_CONTROL_PLANE_KEY\"" \
    /var/lib/irods/.irods/irods_environment.json

  jq_in_place \
    ".negotiation_key          |= \"$IRODS_NEGOTIATION_KEY\" |
     .server_control_plane_key |= \"$IRODS_CONTROL_PLANE_KEY\" |
     .zone_key                 |= \"$IRODS_ZONE_KEY\"" \
    /etc/irods/server_config.json
}



main "$@"
