#!/bin/bash

set -e

JAVA_ARGS="${JAVA_ARGS:--Xms2g -Xmx2g -XX:MaxPermSize=256m}"

INSTALL_DIR="/usr/share/puppetserver"
CONFIG="${CONFIG:-/etc/puppetserver/conf.d}"
BOOTSTRAP_CONFIG="${BOOTSTRAP_CONFIG:-/etc/puppetserver/bootstrap.cfg}"

# copied from SystemD unit provided by puppet server
exec /usr/bin/java $JAVA_ARGS \
          '-XX:OnOutOfMemoryError=kill -9 %%p' \
          -XX:+HeapDumpOnOutOfMemoryError \
          -XX:HeapDumpPath=/tmp \
          -Djava.security.egd=/dev/urandom \
          -cp "${INSTALL_DIR}/puppet-server-release.jar:/etc/puppetserver/" clojure.main \
          -m puppetlabs.trapperkeeper.main \
          --config "${CONFIG}" \
          -b "${BOOTSTRAP_CONFIG}" $@
