#!/bin/bash

LOG_FILE=ovs-$$.out
ERR_FILE=ovs-$$.err

# Close STDOUT file descriptor and Copy it to 3
exec 3<&1
exec 1<&-
# Close STDERR FD and Copy it to 4
exec 4<&2
exec 2<&-

# Open STDOUT as $LOG_FILE file for read and write.
exec 1>$LOG_FILE

# Redirect STDERR to STDOUT
exec 2>$ERR_FILE

C="0" # count
spin() {
    case "$(($C % 4))" in
        0) char="/"
        ;;
        1) char="-"
        ;;
        2) char="\\"
        ;;
        3) char="|"
        ;;
    esac
    echo -ne $char "\r" >&3
    C=$[$C+1]
}

endspin() {
    printf "\r%s\nPlease check logfile: $LOG_FILE\n" "$@" >&3
}

echos () {
    printf "\r%s\n" "$@" >&3
}

echos "Starting to install Openvswitch with support for NSH"
git clone https://github.com/priteshk/ovs.git
if [ $? -gt 0 ]; then
    endspin "ERROR:Cloning git repo failed."
    exit 1
fi

spin
cd ovs
spin
git checkout nsh-v8
spin
git branch -v >&3
spin
git clean -x -d -f
spin

spin
echos "Configuring ovs."
./boot.sh && ./configure --with-linux=/lib/modules/`uname -r`/build
if [ $? -gt 0 ]; then
    endspin "ERROR:Configuring ovs failed."
    exit 1
fi

spin
echos "Removing old ovs configuration."
sudo kill `cd /usr/local/var/run/openvswitch && cat ovsdb-server.pid ovs-vswitchd.pid`
spin
sudo rm -rf /usr/local/var/run/openvswitch
spin
sudo mkdir -p /usr/local/var/run/openvswitch
spin
sudo rmmod openvswitch
spin
sudo rmmod gre
spin
sudo rmmod vxlan
spin
sudo rmmod libcrc32c
spin
sudo rmmod openvswitch
spin
sudo rm /tmp/ovsdb.txt
spin
touch /tmp/ovsdb.txt
spin
sudo rm /tmp/vswitch.txt
spin
touch /tmp/vswitch.txt

spin
make
if [ $? -gt 0 ]; then
    endspin "ERROR:Compiling ovs failed."
    exit 1
fi

spin
echos "Installing ovs userland programs."
sudo make install
if [ $? -gt 0 ]; then
    endspin "ERROR:sudo make install failed."
    exit 1
fi

spin
echos "Loading kernel modules."
sudo modprobe gre
if [ $? -gt 0 ]; then
    endspin "ERROR:Couldn't insert the gre kernel module."
    exit 1
fi

spin
sudo modprobe libcrc32c
if [ $? -gt 0 ]; then
    endspin "ERROR:Couldn't insert the libcrc32c kernel module."
    exit 1
fi

spin
sudo insmod datapath/linux/openvswitch.ko
if [ $? -gt 0 ]; then
    endspin "ERROR:Couldn't insert the openvswitch kernel module."
    exit 1
fi

spin
sudo lsmod | grep -i open
spin
sudo rm -rf /usr/local/etc/openvswitch
spin
sudo mkdir -p /usr/local/etc/openvswitch
spin
echos "Creating vswitch ovsschema."
sudo ovsdb-tool create /usr/local/etc/openvswitch/conf.db vswitchd/vswitch.ovsschema
if [ $? -gt 0 ]; then
    endspin "ERROR:Couldn't create vswitch.ovsschema."
    exit 1
fi

spin
echos "Starting ovsdb-server."
sudo ovsdb-server --remote=punix:/usr/local/var/run/openvswitch/db.sock \
                  --remote=db:Open_vSwitch,Open_vSwitch,manager_options \
                  --private-key=db:Open_vSwitch,SSL,private_key \
                  --certificate=db:Open_vSwitch,SSL,certificate \
                  --bootstrap-ca-cert=db:Open_vSwitch,SSL,ca_cert \
                  --pidfile --detach --verbose=info --log-file=/tmp/ovsdb.txt
if [ $? -gt 0 ]; then
    endspin "ERROR:Couldn't start ovsdb-server."
    exit 1
fi

spin
echos "Starting ovs-vsctl."
sudo ovs-vsctl --no-wait init
if [ $? -gt 0 ]; then
    endspin "ERROR:Couldn't start ovs-vsctl."
    exit 1
fi

spin
echos "Starting ovs-vswitchd."
sudo ovs-vswitchd --pidfile --detach --verbose=info --log-file=/tmp/vswitch.txt
if [ $? -gt 0 ]; then
    endspin "ERROR:Couldn't start ovs-vswitchd."
    exit 1
fi

spin
sudo ovs-vsctl add-br br1
spin
sudo ovs-vsctl show >&3
spin

echos "Install Complete!"
