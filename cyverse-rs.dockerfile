FROM cyverse/irods-rs:4.1.10

### Switch back to root for installation
USER root

### Install wget for usage inside this script
RUN yum --assumeyes install wget && \
### Create vault base
    mkdir /irods_vault && \
### Install iRODS NetCDF plugins
    yum --assumeyes install \
        https://files.renci.org/pub/irods/releases/4.1.10/centos7/irods-runtime-4.1.10-centos7-x86_64.rpm
COPY plugins/*.rpm /tmp/
RUN yum --assumeyes install \
        /tmp/irods-api-plugin-netcdf-1.0-centos7.rpm \
        /tmp/irods-icommands-netcdf-1.0-centos7.rpm \
        /tmp/irods-microservice-plugin-netcdf-1.0-centos7.rpm && \
    rm --force /tmp/*

### Install Set AVU plugin
COPY plugins/libmsiSetAVU.so /var/lib/irods/plugins/microservices

### Install support for UUID generation
RUN yum --assumeyes install uuidd && \
### Install cmd scripts
    wget --directory-prefix /var/lib/irods/iRODS/server/bin/cmd \
         https://raw.githubusercontent.com/cyverse/ds-playbooks/master/irods/files/cmd-common/de-archive-data \
         https://raw.githubusercontent.com/cyverse/ds-playbooks/master/irods/files/cmd-common/de-create-collection \
         https://raw.githubusercontent.com/cyverse/ds-playbooks/master/irods/files/cmd-common/delete-scheduled-rule \
         https://raw.githubusercontent.com/cyverse/ds-playbooks/master/irods/files/cmd-common/generateuuid \
         https://raw.githubusercontent.com/cyverse/ds-playbooks/master/irods/files/cmd-common/sanimal-ingest \
         https://raw.githubusercontent.com/cyverse/ds-playbooks/master/irods/files/cmd-common/set-uuid && \
    chown irods:irods /var/lib/irods/iRODS/server/bin/cmd/* && \
    chmod ug+x /var/lib/irods/iRODS/server/bin/cmd/*

### Install iRODS configuration files
COPY env-rules/* /etc/irods/
RUN wget --directory-prefix /etc/irods \
         https://raw.githubusercontent.com/cyverse/ds-playbooks/master/irods/files/rule-bases/aegis.re \
         https://raw.githubusercontent.com/cyverse/ds-playbooks/master/irods/files/rule-bases/avra.re \
         https://raw.githubusercontent.com/cyverse/ds-playbooks/master/irods/files/rule-bases/bisque.re \
         https://raw.githubusercontent.com/cyverse/ds-playbooks/master/irods/files/rule-bases/calliope.re \
         https://raw.githubusercontent.com/cyverse/ds-playbooks/master/irods/files/rule-bases/coge.re \
         https://raw.githubusercontent.com/cyverse/ds-playbooks/master/irods/files/rule-bases/de.re \
         https://raw.githubusercontent.com/cyverse/ds-playbooks/master/irods/files/rule-bases/ipc-amqp.re \
         https://raw.githubusercontent.com/cyverse/ds-playbooks/master/irods/files/rule-bases/ipc-custom.re \
         https://raw.githubusercontent.com/cyverse/ds-playbooks/master/irods/files/rule-bases/ipc-housekeeping.re \
         https://raw.githubusercontent.com/cyverse/ds-playbooks/master/irods/files/rule-bases/ipc-json.re \
         https://raw.githubusercontent.com/cyverse/ds-playbooks/master/irods/files/rule-bases/ipc-logic.re \
         https://raw.githubusercontent.com/cyverse/ds-playbooks/master/irods/files/rule-bases/ipc-repl.re \
         https://raw.githubusercontent.com/cyverse/ds-playbooks/master/irods/files/rule-bases/ipc-services.re \
         https://raw.githubusercontent.com/cyverse/ds-playbooks/master/irods/files/rule-bases/ipc-uuid.re \
         https://raw.githubusercontent.com/cyverse/ds-playbooks/master/irods/files/rule-bases/pire.re \
         https://raw.githubusercontent.com/cyverse/ds-playbooks/master/irods/files/rule-bases/sanimal.re \
         https://raw.githubusercontent.com/cyverse/ds-playbooks/master/irods/files/rule-bases/sciapps.re \
         https://raw.githubusercontent.com/cyverse/ds-playbooks/master/irods/files/rule-bases/sernec.re
COPY config/hosts_config.json config/server_config.json /etc/irods/
COPY config/irods_environment.json /var/lib/irods/.irods
RUN chown irods:irods /etc/irods/* /var/lib/irods/.irods/irods_environment.json && \
    chmod -R ug+r /etc/irods /var/lib/irods && \
### Ensure .irods/ and log/ are group writeable
    chmod ug+w /var/lib/irods/.irods /var/lib/irods/iRODS/server/log

### Add script to handle start and stop extras
COPY scripts/periphery.sh /periphery
RUN chown irods:irods /periphery && \
    chmod ug+x /periphery && \
### Clean up yum repository
    yum --assumeyes remove wget && \
    yum --assumeyes clean all && \
    rm --force --recursive /var/cache/yum

VOLUME /var/lib/irods/iRODS/server/log /var/lib/irods/iRODS/server/log/proc

EXPOSE 1247/tcp 1248/tcp 20000-20009/tcp 20000-20009/udp

ENV IRODS_CONTROL_PLANE_KEY=TEMPORARY__32byte_ctrl_plane_key
ENV IRODS_NEGOTIATION_KEY=TEMPORARY_32byte_negotiation_key
ENV IRODS_ZONE_KEY=TEMPORARY_zone_key

CMD [ "/periphery" ]

### Prepare onbuild instantiation logic
COPY scripts/on-build-instantiate.sh /on-build-instantiate
RUN chmod u+x /on-build-instantiate

ONBUILD ARG IRODS_CLERVER_USER=ipc_admin
ONBUILD ARG IRODS_DEFAULT_RES=CyVerseRes
ONBUILD ARG IRODS_HOST_UID
ONBUILD ARG IRODS_RES_SERVER
ONBUILD ARG IRODS_STORAGE_RES

ONBUILD ENV IRODS_STORAGE_RES="$IRODS_STORAGE_RES"

ONBUILD RUN /on-build-instantiate && \
            rm --force /on-build-instantiate

ONBUILD VOLUME /irods_vault/"$IRODS_STORAGE_RES"

ONBUILD USER irods-host-user

