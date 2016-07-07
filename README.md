docker-puppetserver
===================

A Docker image that runs the latest Puppet Server 2 from the RHEL 7 Puppet Labs repository.

The `develop/2.x` branch is for development on Puppet Server 2 images, and anything that makes it into the
`releases/2.x` branch can be considered a release.

This image is baked with the following useful Puppet utilities:

 - Ruby 2.0.0 (`/usr/bin/ruby`)
 - `git`
 - `bundler`
 - `rake`
 - Build utilities such as `make` and `gcc` for native Ruby extension compilation.

A fully-functioning SystemD unit exists in the examples directory. If you're on RHEL 7, it's probably the quickest
way to get started.

## Running

Running it is as simple as:

```
sudo docker run -it -p 8140:8140 rfkrocktk/puppetserver:2.4.0-3
```

As simple as that. Default values are assumed mirroring the SystemD unit provided by Puppet Labs, meaning that the JVM
will allocate 2 GiB of minimum and maximum heap size. This can be tweaked with the `JAVA_ARGS` environment variable:

```
sudo docker run -it -p 8140:8140 -e JAVA_ARGS="-Xms4g -Xmx4g" rfkrocktk/puppetserver:2.4.0-3
```

Configuration can be dropped into the machine using volumes, documented below. The container's defined `ENTRYPOINT`
passes all arguments to the Puppet Server process, therefore to run the server in debug mode:

```
sudo docker run -it -p 8140:8140 rfkrocktk/puppetserver:2.4.0-3 -d
```

The final `-d` is passed into the Puppet Server's start arguments, putting the server in debug mode with more verbose
logging.

### Logging

All logging is done straight to standard output. Logging is in JSON format for easy parseability.

### Security

The Puppet Server is started as the `puppet` user with a UID of `8140` as mentioned in the "Volumes" section below.

If the Puppet Server process is compromised due to a security bug, `root` access won't be immediately possible
without a privilege escalation attack on the kernel.

For ease of configuration, [`--net host`][docker-net-host] is possible, but not recommended. If not using `--net host`,
port 8140 must be forwarded to the host and the host's hostname must be passed into the container using the `--hostname`
parameter to `docker run`.

Examples:

```
# the secure way, you should do it this way
sudo /usr/bin/docker run -p 8140:8140 --hostname $(hostname) rfkrocktk/puppetserver:2.4.0-3
# the insecure way, don't do it this way unless you understand and accept the risks
sudo /usr/bin/docker run --net host rfkrocktk/puppetserver:2.4.0-3
```

### Environment Variables

There are a few environment variables used in starting the Puppet Server, but only one is directly relevant to users
of this container.

<table>
    <thead>
        <tr>
            <th>Name</th>
            <th>Default</th>
            <th>Description</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td><pre>JAVA_ARGS</pre></td>
            <td><pre>-Xms2g -Xmx2g</td>
            <td>
                <p>JVM arguments to pass directly to the Java process on boot.</p>
                <p>The defaults here are the same as given in the SystemD unit that ships with Puppet Server 2.
                   It is recommended to give at least 2GiB of RAM to the Puppet Server.</p>
            </td>
        </tr>
    </tbody>
</table>

### Volumes

There are a number of useful volumes that you'll likely want to mount on your host to persist data across restarts
of the container.

Unless otherwise stated, files and directories are owned by user `puppet` and group `puppet`, with a UID and GID of
`8140`, the same as the port the Puppet Server binds to. To maintain correct file ownership, it is recommended that the
administrator create a similar user and group on the server with the same UID and GID so that it's easy to fix and
maintain correct ownership.

**NOTE:** In order for the Puppet Server to use volumes properly, the volumes must be created before starting the
container the first time and must be owned by user `puppet` and group `puppet` where the UID and GID are `8140`.

<table>
    <thead>
        <tr>
            <th>Container Path</th>
            <th>Description</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td><pre>/srv/puppet/deploy</pre></td>
            <td>
                <p>A good place to stage your <code>r10k</code> deployments from. Bind mount this somewhere on your host
                   and have this directory be the root directory for the local working copy of the Git repository used
                   as the Puppet codebase.</p>
                <p><code>/srv/puppet</code> is the home directory for the <code>puppet</code> user, so if this directory
                   is directly mounted as a volume, certain files may be clobbered in the user's home directory.</p>
            </td>
        </tr>
        <tr>
            <td><pre>/etc/puppetlabs/puppet</pre></td>
            <td>
                <p>Root directory for Puppet configuration.</p>
                <p>If you plan on doing <code>r10k</code> deployments, it is advised to mount this externally on the
                   host so that deployed code exists across container restarts.</p>
            </td>
        </tr>
        <tr>
            <td><pre>/etc/puppetlabs/code</pre></td>
            <td>
                <p>Puppet code gets deployed here.</p>
                <p>I'm not sure how this differs from <code>/etc/puppetlabs/puppet</code>, Puppet Server 2 changed
                   everything.</p>
            </td>
        <tr>
            <td><pre>/etc/puppetlabs/puppetserver</pre></td>
            <td>
                <p>Root directory for Puppet Server configuration.</p>
            </td>
        </tr>
    </tbody>
</table>

Please note that the startup script will restore missing files and directories to the configuration directories on
server start. This is to make life with volumes less of a nightmare. The script will _not_ overwrite existing files.
However, it may recreate deleted files. If you see files show up again that shouldn't, please create a file named
`.norestore` in `/etc/puppetlabs/puppet` and `/etc/puppetlabs/puppetserver` as necessary and this will prevent the
script from recreating deleted files.

## Getting Shell

If you need to acquire shell to your Puppet Server to e.g. sign certificates, this can be easily done by naming your
container on start:

```
sudo docker run --name puppetserver --hostname puppetserver -p 8140:8140 \
    rfkrocktk/puppetserver:2.4.0-3
```

Now that the container is running, we can acquire a shell using the Docker `exec` command:

```
$ sudo docker exec -it puppetserver bash
[puppet@puppetserver /srv/puppet]$
```

Sign away, young champion.

### Versioning

We are following Puppet's own package versioning with one caveat. Instead of following their package's RPM release
version, we introduce an `IMAGE_RELEASE` environment variable as a release version. This value _may_ correspond to the
RPM package's release version or may not. The reason given is that if a security bug is introduced in a dependent
system library (e.g. [Heartbleed][heartbleed], [the GNU libc bug][glibc-bug], etc.), we can bump this value and have the
image rebuilt using the latest dependencies.

This works because upon bumping the version, Docker will invalidate the cache and start the image build from that
position:

```
ENV IMAGE_RELEASE=1
# upgrade all packages
RUN yum upgrade -y >/dev/null
```

If/when such a security bug is found, bump the release version and rebuild to upgrade all packages:

```
ENV IMAGE_RELEASE=2
# upgrade all packages
RUN yum upgrade -y >/dev/null
```

Another reason that the `IMAGE_RELEASE` version may not correspond to the package's release version is in case of
image-specific bug fixes or improvements.

 [heartbleed]: http://heartbleed.com/
 [glibc-bug]: https://bugzilla.redhat.com/show_bug.cgi?id=CVE-2015-0235
 [docker-net-host]: https://docs.docker.com/engine/reference/run/#network-host
