FROM centos:7
MAINTAINER Naftuli Tzvi Kay <rfkrocktk@gmail.com>

ENV LANG en_US.UTF-8

ENV PUPPET_SERVER_VERSION=1.1.3-1.el7

ENV IMAGE_RELEASE=3

# upgrade all packages for security vulnerabilities
RUN yum upgrade -y >/dev/null

# install epel repository
RUN yum install -y epel-release >/dev/null

# preemptively create the puppet user and group
RUN groupadd -g 8140 -r puppet && \
    useradd -u 8140 -g 8140 -r -s /bin/false -m -d /srv/puppet puppet

# install puppetlabs server repository
RUN rpm -Uvh https://yum.puppetlabs.com/puppetlabs-release-el-7.noarch.rpm >/dev/null

# install puppet server and ruby
RUN yum install -y puppetserver-$PUPPET_SERVER_VERSION \
     ruby ruby-devel rubygems rubygems-devel make git gcc >/dev/null
# test it installed everything
RUN test -e /usr/bin/ruby && \
    test -e /usr/bin/gem

# install bundle, rake, and r10k deployment tools
RUN gem install bundler rake r10k librarian-puppet >/dev/null
# test that it installed everything
RUN for i in bundle rake r10k librarian-puppet ; do \
        set -e ; test -f /usr/local/bin/$i ; \
    done

# configure logging exclusively to stdout
ADD files/logback.xml files/request-logging.xml /etc/puppetserver/

# create and chown directories
RUN install --directory --owner=puppet --group=puppet --mode=0775 /var/run/puppet && \
    install --directory --owner=puppet --group=puppet --mode=0770 /srv/puppet/deploy && \
     chown -R puppet:puppet /etc/puppetserver /var/lib/puppet /usr/share/puppetserver

# install puppet start script
ADD scripts/puppetserver.sh /usr/local/bin/start-puppet-server
RUN chmod 0775 /usr/local/bin/start-puppet-server

# define volumes
# configuration files
VOLUME /etc/puppet
VOLUME /etc/puppetserver
# do your r10k/rake/bundle deploys from here
VOLUME /srv/puppet/deploy
# puppet data, possibly including TLS certs
VOLUME /var/lib/puppet

# expose puppet server port
EXPOSE 8140

# run everything as user puppet
USER puppet

# work in the user's homedir
WORKDIR /srv/puppet

# start puppet server
ENTRYPOINT ["/usr/local/bin/start-puppet-server"]
