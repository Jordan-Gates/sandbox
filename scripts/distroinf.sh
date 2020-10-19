#!/bin/bash
#Getting linux os info
#
# Am I root?
if [ "x$(id -u)" != 'x0' ]; then
    echo 'Error: this script can only be executed by root'
    exit 1
fi

# Detect OS
case $(head -n1 /etc/issue | cut -f 1 -d ' ') in
    Debian)     type="debian" ;;
    Ubuntu)     type="ubuntu" ;;
    Amazon)     type="amazon" ;;
    *)          type="rhel" ;;
esac

#start ib bytes
human_size_print(){
while read B dummy; do
  [ $B -lt 1024 ] && echo ${B} bytes && break
  KB=$(((B+512)/1024))
  [ $KB -lt 1024 ] && echo ${KB} KB && break
  MB=$(((KB+512)/1024))
  [ $MB -lt 1024 ] && echo ${MB} MB && break
  GB=$(((MB+512)/1024))
  [ $GB -lt 1024 ] && echo ${GB} GB && break
  echo $(((GB+512)/1024)) TB
done
}

#start in kb
human_memsize_print(){
while read KB dummy; do
  [ $KB -lt 1024 ] && echo ${KB} KB && break
  MB=$(((KB+512)/1024))
  [ $MB -lt 1024 ] && echo ${MB} MB && break
  GB=$(((MB+512)/1024))
  [ $GB -lt 1024 ] && echo ${GB} GB && break
  TB=$(((GB+512)/1024))
  [ $TB -lt 1024 ] && echo ${TB} TB && break
  echo $(((TB+512)/1024)) PB
done
}




case $type in
    "ubuntu")
        memory=$(grep 'MemTotal' /proc/meminfo |tr ' ' '\n' |grep [0-9])
        arch=$(uname -i)
        os='ubuntu'
        release="$(lsb_release -s -r)"
        codename="$(lsb_release -s -c)"
        ;;
    "rhel")
        memory=$(grep 'MemTotal' /proc/meminfo |tr ' ' '\n' |grep [0-9])
        arch=$(uname -i)
        os=$(cut -f 1 -d ' ' /etc/redhat-release)
        release=$(grep -o "[0-9]" /etc/redhat-release |head -n1)
        codename="${os}_$release"
        ;;
    "debian")
        memory=$(grep 'MemTotal' /proc/meminfo |tr ' ' '\n' |grep [0-9])
        arch=$(uname -i)
        os='debian'
        release=$(cat /etc/debian_version|grep -o [0-9]|head -n1)
        codename="$(cat /etc/os-release |grep VERSION= |cut -f 2 -d \(|cut -f 1 -d \))"
        ;;
    "amazon")
        memory=$(grep 'MemTotal' /proc/meminfo |tr ' ' '\n' |grep [0-9])
        arch=$(uname -i)
        os='rhel'
        release='6'
        codename="${os}_$release"
        ;;
    *)
        echo -n "Unknown operating system detected"
        exit 1;
    ;;
esac


clear
echo "Linux distribution info $0"
echo "----------------------------------------"
echo "Operating system: Linux"
echo "Operating system distribution: $type"
echo "Operating system architecture: $arch"
echo "Operating system release: $release"
echo "Operating system code name: $codename"
echo ""
echo "--------"
echo "MEMORY "
echo "--------"
echo -n -e "Total Memory: $memory about "
echo $memory | human_memsize_print
#check the swap 
if free | awk '/^Swap:/ {exit !$2}'; then
swapsize=$(free | awk '/^Swap:/ ' |  awk 'END{print $2}')
echo -n -e "Total Swap size: $swapsize KB about "
echo $swapsize | human_memsize_print
else
echo "System  does not have any swap space"
fi
echo ""
free -mh
echo ""
echo "--------"
echo "CPU"
echo "--------"
lscpu | egrep 'Model name|Socket|Thread|NUMA|CPU\(s\)'
echo ""
echo "--------"
echo "Load & logged users "
echo "--------"
w
echo ""
echo "--------"
echo "WAN/Public IP"
echo "--------"
if ! command -v dig &> /dev/null
then
    #dig command not found i will use external site https://www.cyberciti.biz/faq/how-to-find-my-public-ip-address-from-command-line-on-a-linux/
    server_ip="$(curl -s ifconfig.co)"
    printf "Server public ip4 %s\n" $server_ip
else 
    dig TXT +short o-o.myaddr.l.google.com @ns1.google.com | awk -F'"' '{ print $2}'
fi
echo "----------------------------------------"
