#!/bin/bash 

ETH0IP=`ifconfig ovs-uplink | awk '/inet / {print $2}'`
THIRDOCTET="$(cut -d'.' -f3 <<< $ETH0IP)"
FOURTHOCTET="$(cut -d'.' -f4 <<< $ETH0IP)"
echo "$ADPASSWORD" | kinit $ADUSER

# this pre-creates a machine account in AD for when you're ready to go down that rathole
# OUDN=$(awk -v str="$DNSDOMAIN" 'BEGIN {gsub("[.]", ",DC=", str); print "CN=Computers,DC="str}')

## delete any old L0.$DNSDOMAIN records from prior runs
echo -e "update delete L0.$DNSDOMAIN\n\nsend" | nsupdate -g

## inject L0.$DNSDOMAIN A record
echo -e "zone $DNSDOMAIN.\nupdate add L0.$DNSDOMAIN 86400 A 192.168.$THIRDOCTET.$FOURTHOCTET\n\nsend" | nsupdate -g

for ((i=1; i<=$ESXHOSTCOUNT; i++))
do
  let OCTET=200+$i
  echo -e "192.168.20.$OCTET esxi$i.$DNSDOMAIN" >> /etc/hosts
  echo -e "zone $DNSDOMAIN\nupdate add esxi$i.$DNSDOMAIN 86400 A 192.168.20.$OCTET\n\nsend" | nsupdate -g
  echo -e "add $OCTET.20.168.192.in-addr.arpa. 86400 PTR esxi$i.$DNSDOMAIN.\nsend" | nsupdate -g
done

let vcsaoctet=10

for ((i=1; i<=2; i++))
do
  # add entries to the L0 hostfile... just in case
  echo -e "192.168.20.$vcsaoctet vcsa$i.$DNSDOMAIN" >> /etc/hosts

  # add A records to ad dns
  echo -e "zone $DNSDOMAIN.\nupdate add vcsa$i.$DNSDOMAIN 86400 A 192.168.20.$vcsaoctet\n\nsend" | nsupdate -g

  # add PTR record to ad dns (only vcsa REALLY needs this)
  echo -e "add $vcsaoctet.20.168.192.in-addr.arpa. 86400 PTR vcsa$i.$DNSDOMAIN.\nsend" | nsupdate -g

  let vcsaoctet=vcsaoctet+10 

done

# add entries to the L0 hostfile... just in case
echo -e "192.168.20.236 veeam-01a.$DNSDOMAIN" >> /etc/hosts
echo -e "192.168.30.236 cifs-01a.$DNSDOMAIN" >> /etc/hosts
echo -e "192.168.40.236 mssql-01a.$DNSDOMAIN" >> /etc/hosts
echo -e "192.168.20.250 vtl-01a.$DNSDOMAIN" >> /etc/hosts
echo -e "192.168.20.80 fas2040-01a.$DNSDOMAIN" >> /etc/hosts
echo -e "192.168.20.225 vnx-01a.$DNSDOMAIN" >> /etc/hosts

# add A records to ad dns
echo -e "zone $DNSDOMAIN.\nupdate add veeam-01a.$DNSDOMAIN 86400 A 192.168.20.236\n\nsend" | nsupdate -g
echo -e "zone $DNSDOMAIN.\nupdate add cifs-01a.$DNSDOMAIN 86400 A 192.168.30.236\n\nsend" | nsupdate -g
echo -e "zone $DNSDOMAIN.\nupdate add mssql-01a.$DNSDOMAIN 86400 A 192.168.40.236\n\nsend" | nsupdate -g
echo -e "zone $DNSDOMAIN.\nupdate add vtl-01a.$DNSDOMAIN 86400 A 192.168.20.250\n\nsend" | nsupdate -g
echo -e "zone $DNSDOMAIN.\nupdate add fas2040-01a.$DNSDOMAIN 86400 A 192.168.20.80\n\nsend" | nsupdate -g
echo -e "zone $DNSDOMAIN.\nupdate add vnx-01a.$DNSDOMAIN 86400 A 192.168.20.225\n\nsend" | nsupdate -g
echo -e "zone $DNSDOMAIN.\nupdate add vnx-01a.$DNSDOMAIN 86400 A 192.168.20.225\n\nsend" | nsupdate -g

# add PTR record to ad dns (only vcsa REALLY needs this)
echo -e "add 236.20.168.192.in-addr.arpa. 86400 PTR veeam-01a.$DNSDOMAIN.\nsend" | nsupdate -g
echo -e "add 236.30.168.192.in-addr.arpa. 86400 PTR cifs-01a.$DNSDOMAIN.\nsend" | nsupdate -g
echo -e "add 236.40.168.192.in-addr.arpa. 86400 PTR mssql-01a.$DNSDOMAIN.\nsend" | nsupdate -g
echo -e "add 250.20.168.192.in-addr.arpa. 86400 PTR vtl-01a.$DNSDOMAIN.\nsend" | nsupdate -g
echo -e "add 80.20.168.192.in-addr.arpa. 86400 PTR fas2040-01a.$DNSDOMAIN.\nsend" | nsupdate -g
echo -e "add 225.20.168.192.in-addr.arpa. 86400 PTR vnx-01a.$DNSDOMAIN.\nsend" | nsupdate -g