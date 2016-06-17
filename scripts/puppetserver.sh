#!/bin/bash

set -e

JAVA_ARGS="${JAVA_ARGS:--Xms2g -Xmx2g}"

INSTALL_DIR="${INSTALL_DIR:-/opt/puppetlabs/server/apps/puppetserver}"
CONFIG="${CONFIG:-/etc/puppetlabs/puppetserver/conf.d}"
BOOTSTRAP_CONFIG="${BOOTSTRAP_CONFIG:-/etc/puppetlabs/puppetserver/bootstrap.cfg}"
SERVICE_STOP_RETRIES="${SERVICE_STOP_RETRIES:-60}"

# copied from SystemD unit provided by puppet server
exec /usr/bin/java $JAVA_ARGS \
    '-XX:OnOutOfMemoryError=kill -9 %%p' \
    -Djava.security.egd=/dev/urandom \
    -cp "${INSTALL_DIR}/puppet-server-release.jar" clojure.main \
    -m puppetlabs.trapperkeeper.main \
    --config "${CONFIG}" \
    -b "${BOOTSTRAP_CONFIG}" $@
