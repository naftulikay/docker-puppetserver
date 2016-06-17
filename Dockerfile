FROM centos:7
MAINTAINER Naftuli Tzvi Kay <rfkrocktk@gmail.com>

ENV LANG en_US.UTF-8

ENV PUPPET_SERVER_VERSION=1.1.3-1.el7

ENV IMAGE_RELEASE=2

# upgrade all packages for security vulnerabilities
RUN yum upgrade -y >/dev/null

# install epel repository and sudo
RUN yum install -y epel-release sudo >/dev/null

# preemptively create the puppet user and group
RUN groupadd -g 8140 -r puppet && \
    useradd -u 8140 -g 8140 -r -s /bin/false puppet

# install puppetlabs server repository
RUN rpm -Uvh https://yum.puppetlabs.com/puppetlabs-release-el-7.noarch.rpm >/dev/null

# install puppet server and ruby
RUN yum install -y puppetserver-$PUPPET_SERVER_VERSION \
     ruby ruby-devel rubygems rubygems-devel >/dev/null
# test it installed everything
RUN test -e /usr/bin/ruby && \
    test -e /usr/bin/gem

# install bundle, rake, and r10k deployment tools
RUN gem install bundler rake r10k librarian-puppet >/dev/null
# test that it installed everything
RUN for i in bundle rake r10k librarian-puppet ; do \
        set -e ; test -f /usr/local/bin/$i ; \
    done

# configure logging to stdout over JSON
ADD files/logback.xml files/request-logging.xml /etc/puppetserver/

# create and chown directories
RUN install --directory --owner=puppet --group=puppet --mode=0775 /var/run/puppet && \
     chown -R puppet:puppet /etc/puppetserver /var/lib/puppet /usr/share/puppetserver

# install puppet start script
ADD scripts/puppetserver.sh /usr/local/bin/start-puppet-server
RUN chmod 0775 /usr/local/bin/start-puppet-server

# expose puppet server port
EXPOSE 8140

USER puppet

# start puppet server
ENTRYPOINT ["/usr/local/bin/start-puppet-server"]
