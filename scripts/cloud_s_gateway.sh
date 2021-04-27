#!/usr/bin/env bash

## Traffic going to the internet
route add default gw 172.30.30.1

### NAT rules ###
### If port 8080 was not specified, messages did not get through, with specifying the port number everything worked fine again. It had been discussed in demo session that this was tedious to do, but it turns out to be necessary in this case.
### (3 tests consecutively did not work without specifying and when adding port number everything worked again )
sudo iptables -t nat -A PREROUTING -p tcp --dport 8080 -s 172.16.16.16/32 -j DNAT --to-destination 10.2.0.2
sudo iptables -t nat -A PREROUTING -p udp --dport 8080 -s 172.16.16.16/32 -j DNAT --to-destination 10.2.0.2
sudo iptables -t nat -A POSTROUTING -p udp --dport 8080 -o enp0s8 -j MASQUERADE
sudo iptables -t nat -A POSTROUTING -p tcp --dport 8080 -o enp0s8 -j MASQUERADE

## Save the iptables rules
iptables-save > /etc/iptables/rules.v4
ip6tables-save > /etc/iptables/rules.v6

## Set the password for vpn connection!
cat > /etc/ipsec.secrets << EOFPasswd
172.30.30.30 172.16.16.16 : PSK "dKVLhZa/cXQg2x3CCRxUYqfQPFMp0HO2" 
172.30.30.30 172.17.17.17 : PSK "syMhWOzOvfwoQ9lg/C6q/+DSJEEOkIWO"
EOFPasswd

## Configure the connection A <--> S and B <--> S
cat > /etc/ipsec.conf << EOFConfig
config setup 
    charondebug="all"
    uniqueids=yes 

conn %default
    keyexchange=ikev2
    ike=aes256-sha2_256-modp2048! 
    esp=aes256-sha2_256! 
    ikelifetime=1h
    lifetime=8h 
    # dpddelay=30 # 30 is default
    dpdtimeout=120 
    dpdaction=restart
    auto=start

conn S_TO_A 
    type = tunnel
    authby=secret 
    left=172.30.30.30
    leftsubnet=172.30.30.30/32
    right=172.16.16.16
    rightsubnet=172.16.16.16/32

conn S_TO_B 
    type = tunnel
    authby=secret 
    left=172.30.30.30
    leftsubnet=172.30.30.30/32
    right=172.17.17.17
    rightsubnet=172.17.17.17/16
EOFConfig

sudo ipsec restart
