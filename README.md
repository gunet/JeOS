# JeOS
GUNet Just enough OS (based on Debian)

## Docker
The final ISO image will be in the folder `/var/jeos/final`. We must volume mount it in order to have it available after
the Docker container has finished.
The recommened way to run the container is:
`docker run --rm -v ${PWD}/final:/var/jeos/final --privileged ghcr.io/gunet/jeos-builder:<version>`

### Environment variables
The following environment variables are available. For network configuration, the general path is to use DHCP provided ones and *only* if these are not available, then use the ones in environment variables (if they are provided):
* `NET_IP`: The static IP in CIDR form (ie `192.168.2.1/24`).
* `NET_GATEWAY`: The gateway IP. Only if IP has already been passed.
* `NET_NAMESERVERS`: Nameserver IPs to use, separated by space (ie `8.8.8.8 4.4.4.4`)
* `NET_HOSTNAME`: The hostname to set (ie `sso.gunet.gr`)
* `NET_DOMAIN`: The domain to set (ie `gunet.gr`)
* `NET_STATIC`: If set to `yes` then we only perform static network configuration and **all** the above variables **must** be set
* `ROOT_PASSWORD`: The (plaintext) root password

### Building
* Default `ARG` values:
  - ARG DEBIAN_VERSION=11.8.0
  - ARG DEBIAN_REPO=https://cdimage.debian.org/mirror/cdimage/archive/${DEBIAN_VERSION}/amd64/iso-cd
  - ARG DEBIAN_ISO=debian-${DEBIAN_VERSION}-amd64-netinst.iso
* Simple build: `docker build -t ghcr.io/gunet/jeos-builder .`
* Build for another debian version: `docker build --build-arg DEBIAN_VERSION=<version> -t ghcr.io/gunet/jeos-builder .`

### Available versions
* `latest`: `11.8.0`

## Size
* Docker image: `510 MB`
* JeOS ISO CD: `450 MB`
* JeOS installation: `3.2 GB`

## Notes for repo files
### Run
In order to produce a Just Enough Operating System iso image, we need to run the script __mkiso.sh__ as follows:
`sudo ./mkiso.sh`
It uses the following two environment variables:
* `DEBIAN_ISO` to find the Debian ISO in `$(pwd)/debian/${DEBIAN_ISO}`
* `DEBIAN_VERSION` (if available) to use it in the name of the produced ISO file. The default name is `$(pwd)/final/gunet-jeos-debian.iso` and if the `DEBIAN_VERSION` variable is available `$(pwd)/final/gunet-jeos-debian-${DEBIAN_VERSION}.iso`

The `DEBIAN_ISO` file is a Debian ISO file from the Debian project. An archive of ISO images for previous
Debian versions can be found [here](https://cdimage.debian.org/mirror/cdimage/archive/)

### Configuration
The produced .iso file installs a Debian OS, by requesting only the root password and the network configuration paramenters, in case DHCP fails, during the installation if the necessary environment variables are not available. All the configuration must be located into _gunet/_ folder. In the current configuration, _gunet/_ folder contains the follwing:
* <ins>_preseed.cfg_</ins>: This file contains all the configuration of d-i installer that automates the installation procedure. The parameters are set to produce an as minimal as possible installation. During the _late_command_ step, we add further configuration and run scripts that we want to include in the installation procedure.
* <ins>_00norecommends_</ins>: This file is copied into the _/etc/apt/apt.conf.d/_ folder by the late_command of d-i installer and prevents the installation of suggested and recommended packages during package installation via ```apt```.
* <ins>_disableipv6.conf_</ins>: This file is copied into the _/etc/sysctl.d/_ folder by the late_command of d-i installer and disables ipv6 network configuration.
* <ins>_locale_</ins>: This file is copied into the _/etc/default/_ folder by the late_command of d-i installer and sets up the locale configuration.
* <ins>_sources.list_</ins>: This file is copied into the _/etc/apt/_ folder by the late_command of d-i installer and defines the repos from which the packages will be installed via ```apt```.
* <ins>_internal_custom_script.sh_</ins>: This script is executed by the late_command of d-i installer and adds or removes packages to/from the initial installation. Any package addition or removal should be included here.
* <ins>_custom_script.sh_</ins>: This script is executed by the late_command of d-i installer and configures services(i.e. the port of the ssh server) and removes files or folders. Any configuration of system services should be included here.
  - In our case we change the ssh port from the default `22` to `65432`.
* <ins>_install_docker_</ins>: This script installs docker.

***Note***: For any further addition to the above, the new configuration file or script must be included in the _gunet/_ file and the respective changes in the late_command of the preseed.cfg file must be performed.