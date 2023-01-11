#!/bin/bash -x

## the idea of this script is to have cron run it periodically to post the most current state of the nested vmware environment to a file under /var/log
## for troubleshooting purposes.  I like to have cloudwatch pick it up every 5 minutes so I can easily see things about the vmware environment without having to actually log in and look

## this needs to run under a 3.6 venv
source $ESXIROOT/dcli_venv/bin/activate

## Dump the config of the vcenter/clusters/etc to a file in /var/log
dcli +server vcsa1.${DNSDOMAIN} +skip +username administrator@${SSODOMAINBASE}1.${SSODOMAINSUFFIX} +password ${SSOPASSWORD} com vmware appliance vcenter settings v1 configcurrent get &> /var/log/vcsa1.state
dcli +server vcsa2.${DNSDOMAIN} +skip +username administrator@${SSODOMAINBASE}2.${SSODOMAINSUFFIX} +password ${SSOPASSWORD} com vmware appliance vcenter settings v1 configcurrent get &> /var/log/vcsa2.state

## leave the 3.6 venv
deactivate