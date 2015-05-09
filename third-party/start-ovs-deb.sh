#!/bin/bash

OPTIND=1
nodownload=0
verbose=0

while getopts "h?v?n" opt; do
    case "$opt" in
    h|\?)
        echo "Please read the script ;)"
        exit 0
        ;;  
    v)  verbose=1
        ;;
    n)  nodownload=1
        ;;
    esac
done

shift $((OPTIND-1))

[ "$1" = "--" ] && shift

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

if [ "$nodownload" == "0" ]; then
    echos "Starting to install Openvswitch with support for NSH"
    git clone https://github.com/priteshk/ovs.git
    if [ $? -gt 0 ]; then
        endspin "ERROR:Cloning git repo failed."
        exit 1
    fi
fi

spin
cd ovs
spin
git stash
spin
git checkout nsh-v8
spin
git branch -v >&3
spin
git clean -x -d -f

spin
echos "Removing old ovs configuration."
sudo /etc/init.d/openvswitch-switch stop
spin
sudo kill `cd /usr/local/var/run/openvswitch && cat ovsdb-server.pid ovs-vswitchd.pid`
spin
sudo rm -rf /usr/local/var/run/openvswitch
spin
sudo mkdir -p /usr/local/var/run/openvswitch
spin
sudo rm -rf /usr/local/etc/openvswitch
spin
sudo mkdir -p /usr/local/etc/openvswitch
spin
sudo rm -rf /var/run/openvswitch
spin
sudo mkdir -p /var/run/openvswitch
spin
sudo rm -rf /etc/openvswitch
spin
sudo mkdir -p /etc/openvswitch
spin
sudo rm -rf /var/log/openvswitch
spin
sudo mkdir -p /var/log/openvswitch
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
sudo dpkg --force-all --purge openvswitch-switch
spin
sudo dpkg --force-all --purge openvswitch-common
spin
sudo dpkg --force-all --purge openvswitch-datapath-dkms
spin
sudo rm /tmp/ovsdb.txt
spin
touch /tmp/ovsdb.txt
spin
sudo rm /tmp/vswitch.txt
spin
touch /tmp/vswitch.txt
spin
./boot.sh
spin
./configure --with-linux=/lib/modules/`uname -r`/build
spin
sudo make uninstall

spin
sudo apt-get install -y build-essential
spin
sudo apt-get install -y fakeroot
spin
sudo apt-get install -y debhelper
spin
sudo apt-get install -y autoconf
spin
sudo apt-get install -y automake
spin
sudo apt-get install -y libssl-dev
spin
sudo apt-get install -y bzip2
spin
sudo apt-get install -y openssl
spin
sudo apt-get install -y graphviz
spin
sudo apt-get install -y python-all
spin
sudo apt-get install -y procps
spin
sudo apt-get install -y python-qt4
spin
sudo apt-get install -y python-zopeinterface
spin
sudo apt-get install -y python-twisted-conch
spin
sudo apt-get install -y libtool

spin
sudo dpkg-checkbuilddeps
echos "Checking Build Dependencies."
if [ $? -gt 0 ]; then
    endspin "ERROR:Build Dependencies not met."
    exit 1
fi

spin
echos "Creating Debian Packages."
rm ../openvswitch-*.deb
rm ../python-openvswitch*.deb
DEB_BUILD_OPTIONS='parallel=8 nocheck' fakeroot debian/rules binary
if [ $? -gt 0 ]; then
    endspin "ERROR:Creating Debian packages failed."
    exit 1
fi

spin
echos "Installing kernel module using dkms."
sudo apt-get install -y linux-headers-`uname -r`
sudo apt-get install -y dkms
sudo dpkg --install ../openvswitch-datapath-dkms*
if [ $? -gt 0 ]; then
    endspin "ERROR:Installing openvswitch kernel module failed."
    exit 1
fi

spin
echos "Installing openvswitch userland packages."
sudo dpkg --install ../openvswitch-common*
sudo dpkg --install ../openvswitch-switch*
if [ $? -gt 0 ]; then
    endspin "ERROR:Installing openvswitch userland packages failed."
    exit 1
fi

spin
sudo /etc/init.d/openvswitch-switch restart

spin
sudo lsmod | grep -i open

spin
sudo ovs-vsctl add-br br1
spin
sudo ovs-vsctl show >&3
spin

echos "Install Complete!"
