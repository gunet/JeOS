# JeOS
GUNet Just enough OS (based on Debian)

## Docker
The final ISO image will be in the folder `/var/jeos/final`. We must volume mount it in order to have it available after
the Docker container has finished.
The recommened way to run the container is:
`docker run --rm -v ${PWD}/final:/var/jeos/final --privileged ghcr.io/gunet/jeos-builder:<version>`

### Available versions
* `latest`: `11.8.0`

## Size
* Docker image: `510 MB`
* JeOS ISO CD: `450 MB`
* JeOS installation: `3.2 GB`

## Notes for repo files
### Run
In order to produce a Just Enough Operating System iso image, we need to run the script __mkiso.sh__ as follows:
```sudo ./mkiso.sh <debian_image>.iso```
The `<debian_image.iso>` file is a Debian ISO file from the Debian project. An archive of ISO images for previous
Debian versions can be found [here](https://cdimage.debian.org/mirror/cdimage/archive/)

***Notes***:
* The script will produce the ***JeOS iso file*** _gunet-jeos.iso_ into the ***Working Directory***.
* We must run the script with ***sudo*** privileges.

### Configuration
The produced .iso file installs a Debian OS, by requesting only the root password and the network configuration paramenters, in case DHCP fails, during the installation. All the configuration must be located into _gunet/_ folder. In the current configuration, _gunet/_ folder contains the follwing:
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