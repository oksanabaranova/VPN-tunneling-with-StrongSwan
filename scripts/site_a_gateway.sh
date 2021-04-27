#!/usr/bin/env bash

## NAT traffic going to the internet
route add default gw 172.16.16.1 
iptables -t nat -A POSTROUTING -o enp0s8 -j MASQUERADE

## Save the iptables rules
iptables-save > /etc/iptables/rules.v4
ip6tables-save > /etc/iptables/rules.v6

## Set the password for vpn connection!
cat > /etc/ipsec.secrets << EOFPasswd
172.16.16.16 172.30.30.30 : PSK "dKVLhZa/cXQg2x3CCRxUYqfQPFMp0HO2"
EOFPasswd

## Configure the connection A <--> S
cat > /etc/ipsec.conf << EOFConfig
config setup
    # strictcrlpolicy=yes
    # uniqueids = no 
    # Add connections here. 
    charondebug="all" 
    uniqueids=yes 

conn %default
    keyexchange=ikev2

conn A_TO_S 
    type = tunnel
    authby=secret 
    left=172.16.16.16
    leftsubnet=172.16.16.16/32
    right=172.30.30.30 
    rightsubnet=172.30.30.30/32 
    ike=aes256-sha2_256-modp2048! 
    esp=aes256-sha2_256! 
    ikelifetime=1h
    lifetime=8h 
    dpddelay=30 
    dpdtimeout=120 
    dpdaction=restart 
    auto=start
EOFConfig

sudo ipsec restart
