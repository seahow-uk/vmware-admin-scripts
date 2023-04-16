#!/bin/bash -x

    ## this needs to run under a 3.6 venv
    source $ESXIROOT/dcli_venv/bin/activate

    VCSAJSONSOURCE=$ESXIROOT/JSON/vcsa-install-$VSPHEREVERSION.json

## Stage 1: deploy vcsas - one to each of n number hosts

    let vcsaoctet=10
    let esxindex=1

    for ((i=1; i<=2; i++))
    do
        ## clone json
        
        VCSAJSONTARGET="$ESXIROOT/JSON/vcsa$i.json"
        cp -f $VCSAJSONSOURCE $VCSAJSONTARGET

        ## prep json
        sed -i "s/TARGETIPPLACEHOLDER/$MANAGEMENTOCTET.$vcsaoctet/g" $VCSAJSONTARGET
        sed -i "s/TARGETHOSTNAMEPLACEHOLDER/esxi$esxindex.$DNSDOMAIN/g" $VCSAJSONTARGET
        sed -i "s/VCSAFQDNPLACEHOLDER/vcsa$i.$DNSDOMAIN/g" $VCSAJSONTARGET
        sed -i "s/VCSANAMEPLACEHOLDER/vcsa$i/g" $VCSAJSONTARGET
        sed -i "s/DNS1PLACEHOLDER/$DNSIPADDRESS1/g" $VCSAJSONTARGET
        sed -i "s/DNS2PLACEHOLDER/$DNSIPADDRESS2/g" $VCSAJSONTARGET
        sed -i "s/HOSTPASSWORDPLACEHOLDER/$HOSTPASSWORD/g" $VCSAJSONTARGET
        sed -i "s/SSOPASSWORDPLACEHOLDER/$SSOPASSWORD/g" $VCSAJSONTARGET
        sed -i "s/SSODOMAINPLACEHOLDER/lab$i.local/g" $VCSAJSONTARGET
        sed -i "s/SITEPLACEHOLDER/lab$i/g" $VCSAJSONTARGET

        MY_THUMBPRINT=`echo -n | openssl s_client -connect esxi$esxindex.$DNSDOMAIN:443 2>/dev/null | openssl x509 -noout -fingerprint -sha1 | awk -F= '{ print $2 }'`
        echo "esxi$esxindex's thumbprint=$MY_THUMBPRINT"

        ## take the relevant hosts out of maintenance mode
        echo "taking esxi$esxindex out of maintenance mode..."
        esxcli --server="esxi$esxindex.$DNSDOMAIN" --username="root" --password="$HOSTPASSWORD" --thumbprint="$MY_THUMBPRINT" system maintenanceMode set --enable false

        let vcsaoctet=vcsaoctet+$IPSPERLAB ## 10 ips per lab so vcsas will live at 192.168.10,20,30,40,50
        let esxindex=esxindex+$HOSTSPERLAB ## 5 hosts per lab
    done

    sleep 30

    ## Deploy the vcsa appliances
    mkdir -p /var/log/vcsa1 /var/log/vcsa2 

    $ESXIROOT/vcsa-extracted/$VSPHEREVERSION/vcsa-cli-installer/lin64/vcsa-deploy install $ESXIROOT/JSON/vcsa1.json --accept-eula --acknowledge-ceip --no-esx-ssl-verify --skip-ovftool-verification -v --log-dir=/var/log/vcsa1 > /dev/null 2>&1 &
    $ESXIROOT/vcsa-extracted/$VSPHEREVERSION/vcsa-cli-installer/lin64/vcsa-deploy install $ESXIROOT/JSON/vcsa2.json --accept-eula --acknowledge-ceip --no-esx-ssl-verify --skip-ovftool-verification -v --log-dir=/var/log/vcsa2 > /dev/null 2>&1 &
  
    # now wait until those are complete
    wait

    ## Pause until the vcsas are settled down - this appears to need 30 sec

    sleep 30

exit 0



    
    

    




