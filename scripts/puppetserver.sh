#!/bin/bash

set -e

# define functions
function restore-backup-files() {
    source_dir="$1"
    dest_dir="$2"

    if [ -f "$dest_dir/.norestore" ]; then
        # don't restore anything into this directory.
        return 0;
    fi

    # create directories if they don't exist
    find $source_dir -mindepth 1 -type d | sort | while read d ; do
        trimmed_d="$(echo $d | sed "s:$source_dir/::g")"
        test -d "$dest_dir/$trimmed_d" || mkdir -p -m 0755 "$dest_dir/$trimmed_d"
    done

    # create files if they don't exist
    find $source_dir -mindepth 1 -type f | sort | while read f ; do
        trimmed_f="$(echo $f | sed "s:$source_dir/::g")"
        test -f "$dest_dir/$trimmed_f" || ( cat "$f" > "$dest_dir/$trimmed_f" && \
             chmod 0644 "$dest_dir/$trimmed_f" )
    done
}

# restore default config files if they don't exist
restore-backup-files /usr/share/puppet/backup/etc /etc/puppet/
restore-backup-files /usr/share/puppetserver/backup/etc /etc/puppetserver/

# define defaults for environment variables
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
