FROM centos:7
MAINTAINER Naftuli Tzvi Kay <rfkrocktk@gmail.com>

ENV LANG en_US.UTF-8

ENV PUPPET_SERVER_VERSION=2.4.0-1.el7

ENV IMAGE_RELEASE=2

# upgrade all packages for security vulnerabilities
RUN yum upgrade -y >/dev/null

# install epel repository and sudo
RUN yum install -y epel-release sudo >/dev/null

# preemptively create the puppet user and group
RUN groupadd -g 8140 -r puppet && \
    useradd -u 8140 -g 8140 -r -s /bin/false puppet

# install puppetlabs server repository
RUN rpm -Uvh https://yum.puppetlabs.com/puppetlabs-release-pc1-el-7.noarch.rpm >/dev/null

# install puppet server and ruby
RUN yum install -y puppetserver-$PUPPET_SERVER_VERSION \
    ruby ruby-devel rubygems rubygems-devel >/dev/null
# test it installed everything
RUN test -e /usr/bin/ruby && \
    test -e /usr/bin/gem && \
    test -d /etc/puppetlabs/puppetserver && \
    test -d /opt/puppetlabs/server

# install bundle, rake, and r10k deployment tools
RUN gem install bundler rake r10k librarian-puppet >/dev/null
# test that it installed everything
RUN for i in bundle rake r10k librarian-puppet ; do \
        set -e ; test -f /usr/local/bin/$i ; \
    done

# configure logging to stdout over JSON
ADD files/logback.xml files/request-logging.xml /etc/puppetlabs/puppetserver/

# create and chown directories
RUN install --directory --owner=puppet --group=puppet --mode=0775 /var/run/puppetlabs/puppetserver && \
    chown -R puppet:puppet /etc/puppetlabs/puppet /etc/puppetlabs/code /etc/puppetlabs/puppetserver

# install puppet start script
ADD scripts/puppetserver.sh /usr/local/bin/start-puppet-server
RUN chmod 0775 /usr/local/bin/start-puppet-server

# clean up
RUN yum clean all >/dev/null

# expose puppet server port
EXPOSE 8140

# run everything as puppet user
USER puppet

# start puppet server
ENTRYPOINT ["/usr/local/bin/start-puppet-server"]
