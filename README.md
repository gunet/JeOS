# JeOS

GUNet Just enough OS (based on Debian)

## Docker

The final ISO image will be in the folder `/var/jeos/final`. We must volume mount it in order to have it available after
the Docker container has finished.
The recommended way to run the container is:

```bash
docker run --rm -v ${PWD}/final:/var/jeos/final --privileged ghcr.io/gunet/jeos-builder:<version>
```

### Environment variables

The following environment variables are available. For network configuration, the general path is to use DHCP provided ones and *only* if these are not available, then use the ones in environment variables (if they are provided):

* `NET_IP`: The static IP in CIDR form (ie `192.168.2.1/24`).
* `NET_GATEWAY`: The gateway IP. Only if IP has already been passed.
* `NET_NAMESERVERS`: Name Server IPs to use, separated by space (ie `8.8.8.8 4.4.4.4`)
* `NET_HOSTNAME`: The hostname to set (ie `sso.gunet.gr`)
* `NET_DOMAIN`: The domain to set (ie `gunet.gr`)
* `NET_STATIC`: If set to `yes` then we only perform static network configuration and **all** the above variables **must** be set
* `ROOT_PASSWORD`: The (plaintext) root password

The `NET_HOSTNAME` and `NET_DOMAIN` can be helpful even in a DHCP configuration in order to *avoid* the installer asking for the corresponding values.

If no environment variables are passed then the installer will just ask more questions. The purpose of the environment variables is mainly to avoid asking questions and making the installation completely non-interactive (for instance in order to use the produced ISO as input to a [packer](https://github.com/gunet/packer) template).

Sample full `vm.env` file (include with `--env-file vm.env` option in `docker run`):

```bash
NET_IP=123.123.123.123/25
NET_GATEWAY=123.123.123.1
NET_NAMESERVERS=8.8.8.8
NET_HOSTNAME=vm.gunet.gr
NET_DOMAIN=gunet.gr
NET_STATIC=yes
ROOT_PASSWORD=password
```

### ssh keys

* By default root is allowed public key ssh access in the resulting VM
* If you volume mount an `authorized_keys` file under `gunet/` folder then it will be used in the resulting ISO: `-v ${PWD}/authorized_keys:/var/jeos/gunet/authorized_keys`

### Special Notes

* The ssh server will listen on port `65432` instead of the default `22`

### Building

* Default `ARG` values:
  * ARG DEBIAN_VERSION=11.8.0
  * ARG DEBIAN_REPO=<https://cdimage.debian.org/mirror/cdimage/archive/${DEBIAN_VERSION}/amd64/iso-cd>
  * ARG DEBIAN_ISO=debian-${DEBIAN_VERSION}-amd64-netinst.iso
* Simple build: `docker build -t ghcr.io/gunet/jeos-builder .`
* Build for another debian version: `docker build --build-arg DEBIAN_VERSION=<version> -t ghcr.io/gunet/jeos-builder .`

### Available versions

* Debian 11: `latest`: `11.8.0`
* Debian 12: `12.2.0`

## HTTP Server

You can use the `httpd` Docker image to run an httpd server to temporarily expose the ISO image in order to use in web installations (will listen on port `80`):
`docker run --rm -p 80:80 --name jeos-web -v ${PWD}/final:/usr/local/apache2/htdocs/ httpd:2.4`

## Mount

If you want to mount the resulting ISO image locally:

* `mkdir /mnt/iso`
* `mount -o loop final/gunet-jeos-debian-<version>.iso /mnt/iso`
* To unmount: `umount /mnt/iso`

## Size

* Docker image:
  * Debian 11: `510 MB`
  * Debian 12: `760 MB`
* JeOS ISO CD:
  * Debian 11: `450 MB`
  * Debian 12: `750 MB`
* JeOS installation:
  * Debian 11: `1.2 GB`
  * Debian 12: `1.8 GB`

## Notes for repo files

### Run

In order to produce a Just Enough Operating System iso image, we need to run the script [mkiso.sh](mkiso.sh) as follows:

```bash
sudo ./mkiso.sh
```

It uses the following two environment variables:

* `DEBIAN_ISO` to find the Debian ISO in `$(pwd)/debian/${DEBIAN_ISO}`
* `DEBIAN_VERSION` (if available) to use it in the name of the produced ISO file. The default name is `$(pwd)/final/gunet-jeos-debian.iso` and if the `DEBIAN_VERSION` variable is available `$(pwd)/final/gunet-jeos-debian-${DEBIAN_VERSION}.iso`

The `DEBIAN_ISO` file is a Debian ISO file from the Debian project. An archive of ISO images for previous
Debian versions can be found [here](https://cdimage.debian.org/mirror/cdimage/archive/)

### Configuration

The produced .iso file installs a Debian OS, by requesting only the root password and the network configuration parameters, in case DHCP fails, during the installation if the necessary environment variables are not available. All the configuration must be located into [gunet/](gunet/) folder. In the current configuration, [gunet/](gunet/) folder contains the following:

* [preseed.cfg](gunet/preseed.cfg): This file contains all the configuration of d-i installer that automates the installation procedure. The parameters are set to produce an as minimal as possible installation. During the *late_command* step, we add further configuration and run scripts that we want to include in the installation procedure.
* [00norecommends](gunet/00norecommends): This file is copied into the */etc/apt/apt.conf.d/* folder by the late_command of d-i installer and prevents the installation of suggested and recommended packages during package installation via ```apt```.
* [disableipv6.conf](gunet/disableipv6.conf): This file is copied into the */etc/sysctl.d/* folder by the late_command of d-i installer and disables ipv6 network configuration.
* [locale](gunet/locale): This file is copied into the */etc/default/* folder by the late_command of d-i installer and sets up the locale configuration.
* [sources.list](gunet/sources.list): This file is copied into the */etc/apt/* folder by the late_command of d-i installer and defines the repos from which the packages will be installed via ```apt```.
* [internal_custom_script.sh](gunet/internal_custom_script.sh): This script is executed by the late_command of d-i installer and adds or removes packages to/from the initial installation. Any package addition or removal should be included here.
* [custom_script.sh](gunet/custom_script.sh): This script is executed by the late_command of d-i installer and configures services(i.e. the port of the ssh server) and removes files or folders. Any configuration of system services should be included here.
  * In our case we change the ssh port from the default `22` to `65432`.
* [install_docker](gunet/install_docker): This script installs docker.

***Note***: For any further addition to the above, the new configuration file or script must be included in the [gunet/](gunet/) file and the respective changes in the late_command of the preseed.cfg file must be performed.
