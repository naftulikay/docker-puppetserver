FROM centos:7
MAINTAINER Naftuli Tzvi Kay <rfkrocktk@gmail.com>

ENV LANG en_US.UTF-8

ENV PUPPET_SERVER_VERSION=2.4.0-1.el7
ENV PUPPETDB_TERMINUS_VERSION=4.1.2-1.el7

ENV IMAGE_RELEASE=3

# upgrade all packages for security vulnerabilities
RUN yum upgrade -y >/dev/null

# install epel repository
RUN yum install -y epel-release >/dev/null

# preemptively create the puppet user and group
RUN groupadd -g 8140 -r puppet && \
    useradd -u 8140 -g 8140 -r -s /usr/sbin/nologin puppet

# install puppetlabs server repository
RUN rpm -Uvh https://yum.puppetlabs.com/puppetlabs-release-pc1-el-7.noarch.rpm >/dev/null

# install puppet server and ruby
RUN yum install -y puppetserver-$PUPPET_SERVER_VERSION \
    puppetdb-termini-$PUPPETDB_TERMINUS_VERSION
    ruby ruby-devel rubygems rubygems-devel make git gcc >/dev/null
# test it installed everything
RUN test -e /usr/bin/ruby && \
    test -e /usr/bin/gem && \
    test -d /etc/puppetlabs/puppetserver && \
    test -d /opt/puppetlabs/server

# install bundle, rake, and r10k deployment tools
RUN gem install bundler rake >/dev/null
# test that it installed everything
RUN for i in bundle rake ; do \
        set -e ; test -f /usr/local/bin/$i ; \
    done

# configure logging to stdout over JSON
ADD files/logback.xml files/request-logging.xml /etc/puppetlabs/puppetserver/

# create and chown directories
RUN install --directory --owner=puppet --group=puppet --mode=0775 /var/run/puppetlabs/puppetserver && \
    install --directory --owner=puppet --group=puppet --mode=0770 /srv/puppet/deploy && \
    chown -R puppet:puppet /etc/puppetlabs/puppet /etc/puppetlabs/code /etc/puppetlabs/puppetserver /srv/puppet

# backup configuration files
RUN install -d -m 0755 -o puppet -g puppet /usr/share/puppet{,server,code}/backup/etc && \
    cp -r /etc/puppetlabs/puppet/* /usr/share/puppet/backup/etc && \
    cp -r /etc/puppetlabs/puppetserver/* /usr/share/puppetserver/backup/etc/ && \
    cp -r /etc/puppetlabs/code/* /usr/share/puppetcode/backup/etc/ && \
    chown -R puppet:puppet /usr/share/puppet{,server,code}/backup/etc/

# install puppet start script
ADD scripts/puppetserver.sh /usr/local/bin/start-puppet-server
RUN chmod 0775 /usr/local/bin/start-puppet-server

# clean up
RUN yum clean all >/dev/null

# expose puppet server port
EXPOSE 8140

# run everything as puppet user
USER puppet

# volumes
VOLUME ["/etc/puppetlabs/puppet", "/etc/puppetlabs/code", "/etc/puppetlabs/puppetserver", "/srv/puppet/deploy"]

# start puppet server
ENTRYPOINT ["/usr/local/bin/start-puppet-server"]
