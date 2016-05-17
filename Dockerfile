FROM centos:7
MAINTAINER Naftuli Tzvi Kay <rfkrocktk@gmail.com>

ENV LANG en_US.UTF-8

ENV PUPPET_SERVER_VERSION=1.1.3-1.el7

ENV IMAGE_RELEASE=1

# upgrade all packages for security vulnerabilities

# install epel repository and sudo
RUN yum install -y epel-release sudo >/dev/null

# install puppetlabs server repository
RUN rpm -Uvh https://yum.puppetlabs.com/puppetlabs-release-el-7.noarch.rpm >/dev/null

# install puppet server
RUN yum install -y puppetserver-$PUPPET_SERVER_VERSION >/dev/null

# install puppet start script
ADD scripts/puppetserver.sh /usr/local/sbin/start-puppet-server
RUN chmod 0700 /usr/local/sbin/start-puppet-server

# expose puppet server port
EXPOSE 8140

# start puppet server
CMD ["/usr/local/sbin/start-puppet-server"]
