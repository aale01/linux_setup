#!/bin/bash

arch=$(uname -a)

cpuf=$(grep "physical id" /proc/cpuinfo | sort -u | wc -l)
cpuv=$(grep "processor" /proc/cpuinfo | wc -l)

ram_total=$(free --mega | awk '/Mem:/ {print $2}')
ram_use=$(free --mega | awk '/Mem:/ {print $3}')
ram_percent=$(free --mega | awk '/Mem:/ {printf "%.2f", $3/$2*100}')

disk_total=$(df -BG --total | awk '/total/ {print $2}')
disk_use=$(df -BG --total | awk '/total/ {print $3}')
disk_percent=$(df -BG --total | awk '/total/ {print $5}')

cpu_fin=$(top -bn1 | awk '/Cpu\(s\)/ {print 100 - $8}')

lb=$(who -b | awk '{print $3 " " $4}')

lvmu=$(lsblk | grep -q lvm && echo yes || echo no)

tcpc=$(ss -ta | grep ESTAB | wc -l)

ulog=$(who | awk '{print $1}' | sort -u | wc -l)

ip=$(hostname -I | awk '{print $1}')
mac=$(ip link | awk '/link\/ether/ {printf "%s%s", sep, $2; sep=", "}')

cmnd=$(journalctl _COMM=sudo -n 1000 --no-pager 2>/dev/null | grep COMMAND | wc -l)

echo "
	Architecture: $arch
	CPU physical: $cpuf
	vCPU: $cpuv
	Memory Usage: $ram_use/${ram_total}MB ($ram_percent%)
	Disk Usage: $disk_use/$disk_total ($disk_percent)
	CPU load: $cpu_fin%
	Last boot: $lb
	LVM use: $lvmu
	Connections TCP: $tcpc ESTABLISHED
	Users logged: $ulog
	Network: IP $ip ($mac)
	Sudo commands: $cmnd
"
