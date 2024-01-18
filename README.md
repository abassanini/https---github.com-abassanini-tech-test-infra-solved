# Immfly Infra Test Solution
This is the solution repo for the test provided [here](https://github.com/immfly/tech-test-infra)

## TL;DR
After the `git clone`,  `cd` into the project dir and:
```sh
bash service-run.sh 
```
> `sh service-run.sh` will fail because of the bash syntax used

## Assets provided
- `vm.xml`: Virtual machine XML definition for `libvirt`

## Required Software/Packages
- `virsh` >=6.0.0
    - Install references:
        - [Ubuntu](https://ubuntu.com/server/docs/virtualization-libvirt)
        - [Debian](https://wiki.debian.org/KVM)
        - [RedHat](https://access.redhat.com/documentation/es-es/red_hat_enterprise_linux/7/html/virtualization_deployment_and_administration_guide/sect-installing_the_virtualization_packages-installing_virtualization_packages_on_an_existing_red_hat_enterprise_linux_system)
- `docker` >=24.0.7
    - [Install reference](https://docs.docker.com/engine/install/)
- `bash` >=5.0
    - Not tested with `zsh`, but should work in any POSIX shell

## Prerequisites
- Download the VM image
```sh
wget https://immfly-infra-technical-test.s3-eu-west-1.amazonaws.com/debian10-ssh.img.tar.xz
```
- Extract the image
```sh
tar xf debian10-ssh.img.tar.xz
```
- To boot the virtual machine, configure the ${PATH_TO_VM_DISK_FILE} variable in the `assets/vm.xml` domain file with the location where the virtual machine image was extracted.
~~~xml
    <disk type='file' device='disk'>
      <driver name='qemu' type='raw'/>
      <source file='${PATH_TO_VM_DISK_FILE}'/>          <!-- change this -->
      <backingStore/>
      <target dev='vda' bus='virtio'/>
      <alias name='virtio-disk0'/>
      <address type='pci' domain='0x0000' bus='0x04' slot='0x00' function='0x0'/>
    </disk>
~~~
- Customize the parameters in the VM definition according to your host resources by editing the `assets/vm.xml` file.
    > For a better experience, it is recommended to configure at least 4G RAM and 2 vCPUs, otherwise the `docker` engine will run slowly
~~~xml
<domain type='qemu' id='9'>
  <name>immfly-debian10</name>
  <uuid>4b68e38d-1bbc-4327-9da1-be6f688b182a</uuid>
  <memory unit='KiB'>3906250</memory>                   <!-- adjust this -->
  <currentMemory unit='KiB'>3906250</currentMemory>     <!-- adjust this -->
  <vcpu placement='static'>2</vcpu>                     <!-- adjust this -->
~~~
- Please keep the name and MAC address of the definition
~~~xml
<domain type='qemu' id='9'>
  <name>immfly-debian10</name>              <!-- keep this -->
  ...
      <interface type='network'>
      <mac address='52:54:00:c0:e9:b1'/>    <!-- and this -->
      <source network='default' bridge='virbr0'/>
      <target dev='vnet0'/>
      <model type='virtio'/>
      <alias name='net0'/>
      <address type='pci' domain='0x0000' bus='0x01' slot='0x00' function='0x0'/>
    </interface>
~~~
- Import the VM image, locally or on a remote host using `virsh`
```
virsh define assets/vm.xml
```
> The main shell script `service-run.sh` will try to guess the target ip address.  If the VM is running on a remote host, the discovery will not be possible.  In this scenario, please configure the VM IP in the `$TARGET_IP` shell variable.  Further instructions in the following sections
- Start the VM
```
virsh start immfly-debian10
```

## VM IP address
There are several methods to obtain the VM IP address.  Ex:
- From the VM Console using [`virt-manager`](https://virt-manager.org/)
- Using `virsh` to extract the address
```
virsh domifaddr immfly-debian10
```
- Using `virsh` to list the DHCP leases
```
virsh net-dhcp-leases default
```
Use one of them to get the VM IP address.  It's needed to run the main `service-run.sh` script 

## Directory Structure Example
```sh
❯ tree -La 3
.
├── .gitignore
├── README.md
├── ansible
│   ├── .vault.pass
│   ├── app-build.yml
│   ├── bootstrap.yml
│   ├── clean-repos.yml
│   ├── create-user.yml
│   ├── docker-install.yml
│   ├── docker-run.yml
│   ├── docker-stop.yml
│   ├── group_vars
│   │   └── immfly
│   ├── inventory
│   │   └── hosts
│   ├── site-shutdown.yml
│   ├── site.yml
│   ├── templates
│   │   └── default.conf.j2
│   └── webserver-conf.yml
├── assets
│   └── vm.xml
├── docker
│   ├── clock_app
│   │   ├── Dockerfile
│   │   ├── app
│   │   ├── requirements.txt
│   │   └── venv
│   ├── clock_web
│   │   ├── conf
│   │   └── html
│   └── docker-compose.yaml
├── service-run.sh
├── service-stop.sh
└── utils
    ├── common.sh
    ├── env.sh
    └── virsh-ip.sh
```

## Password file
A password file `.vault.pass` is required to run the ansible playbooks, because the provided `rsa` key file provided is now encrypted using `ansible-vault`.  Once you have received the `.vault.pass` file, please copy it to the `ansible/` directory

## Environment Variables
There are a few shell environment variables to configure the application and deployment
- `TARGET_IP`: the IP address of the VM
    >This is a required parameter.  Without it, the main shell script `service-run.sh` will not run
- `APP_USER`: The user who will run the containers.  The deployment will create it and assign it to the correct OS groups.  Default: `app-user`
- `APP_PORT`: The port of the backend application.  Default `8000`
- `WEB_PORT`: The port of the Nginx web frontend.  Default `80`
- Please make sure to export the needed variables, before running the main shell script (or master script).  Ex:
```
export TARGET_IP="192.168.122.190"
```

## Running the master script
There's a master script `service-run.sh` that reads the environment variables and tries to guess the VM IP address.  
The script will fail(2) if:
- Could not get the IP address
- Could not make an SSH connection to the VM IP address

Finally, it will run `ansible` using `docker`, and execute the necessary steps (`playbooks`) to deploy and run the Nginx web front-end and the Python FastAPI backend application.

```sh
bash service-run.sh
```
> `sh service-run.sh` will fail because of the bash syntax used

## Stopping the containers
There's a stop shell script called `service-stop.sh`.  It bootstraps ansible container again and connects to the VM to stop and remove the docker containers and docker networks.
```sh
bash service-stop.sh
```
> `sh service-stop.sh` will fail because of the bash syntax used

## Cleaning Up 💣
- Stop the containers (previous section)
- Stop and delete the VM
```sh
virsh shutdown immfly-debian10 && virsh undefine immfly-debian10
```
- Delete the VM disk file
```sh
rm -f debian10-ssh.img
```
- Delete the local repo clone 🙁
- See you! 👋🏻

## Caveats
- No `ssh-agent` was needed because the private key `rsa` does not have a passphrase and to avoid exposing the private key in the git repository, it was encrypted using `ansible-vault`
- It would be better to use `docker-compose` to control the deployment of the containers as a unit, but it's currently broken with ansible.  A `docker-compose.yml` file is provided for a future use
- For testing purposes it may be better to use a `qcow2` disk in the VM.  It allows disk snapshots and reverts
```sh
qemu-img convert -f raw -O qcow2 debian10-ssh.img debian10-ssh.qcow2
```
- The services run as an application user, but `docker` still runs the daemon with privileges.  To avoid this, [`podman`](https://podman.io/) would be a better choice.
```sh
root@debian:~# ss -tlnp
State                Recv-Q               Send-Q                             Local Address:Port                             Peer Address:Port
LISTEN               0                    128                                      0.0.0.0:80                                    0.0.0.0:*                   users:(("docker-proxy",pid=7955,fd=4))
LISTEN               0                    128                                      0.0.0.0:8000                                  0.0.0.0:*                   users:(("docker-proxy",pid=7775,fd=4))
```