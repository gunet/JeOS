#!/bin/bash

# converts IPv4 as "A.B.C.D" to integer
# ip4_to_int 192.168.0.1
# => 3232235521
ip4_to_int() {
  IFS=. read -r i j k l <<EOF
$1
EOF
  echo $(( (i << 24) + (j << 16) + (k << 8) + l ))
}

# converts interger to IPv4 as "A.B.C.D"
#
# int_to_ip4 3232235521
# => 192.168.0.1
int_to_ip4() {
  echo "$(( ($1 >> 24) % 256 )).$(( ($1 >> 16) % 256 )).$(( ($1 >> 8) % 256 )).$(( $1 % 256 ))"
}

# returns the ip part of an CIDR
#
# cidr_ip "172.16.0.10/22"
# => 172.16.0.10
cidr_ip() {
  IFS=/ read -r ip _ <<EOF
$1
EOF
  echo $ip
}

# returns the prefix part of an CIDR
#
# cidr_prefix "172.16.0.10/22"
# => 22
cidr_prefix() {
  IFS=/ read -r _ prefix <<EOF
$1
EOF
  echo $prefix
}

# returns net mask in numeric format from prefix size
#
# netmask_of_prefix 8
# => 4278190080
int_netmask_of_prefix() {
  netmask_int=$((4294967295 ^ (1 << (32 - $1)) - 1))
  echo $netmask_int
}

# returns net mask in IPv4 format from prefix size
#
# netmask_of_prefix 24
# => 255.255.255.0
netmask_of_prefix() {
  netmask_int=$(int_netmask_of_prefix $1)
  netmask=$(int_to_ip4 $netmask_int)
  echo $netmask
}

# IP=$1
# echo "IP/net is ${IP}"
# echo "IP is $(cidr_ip ${IP})"
# prefix=$(cidr_prefix ${IP})
# echo "Prefix is ${prefix}"
# echo "Netmask is $(netmask_of_prefix ${prefix})"