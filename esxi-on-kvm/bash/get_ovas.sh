#!/bin/bash -x

. $ESXIROOT/bash/configure_l0_env.sh

	  mkdir -p $ESXIROOT/OVA/odoo
  	mkdir -p $ESXIROOT/OVA/resourcespace
    mkdir -p $ESXIROOT/OVA/suitecrm
    mkdir -p $ESXIROOT/OVA/mysql
    mkdir -p $ESXIROOT/OVA/wordpress
    mkdir -p $ESXIROOT/OVA/lampstack

## download WordPress virtual appliance

  wget https://bitnami.com/redirect/to/1160995/bitnami-wordpress-5.5.1-1-linux-debian-10-x86_64.ova -O $ESXIROOT/OVA/wordpress/bitnami-wordpress-5.5.1-1-linux-debian-10-x86_64.ova

## download mySQL virtual appliance

  wget https://bitnami.com/redirect/to/1153209/bitnami-mysql-8.0.21-4-r08-linux-debian-10-x86_64-nami.ova -O $ESXIROOT/OVA/mysql/bitnami-mysql-8.0.21-4-r08-linux-debian-10-x86_64-nami.ova

## download suiteCRM virtual appliance

  wget https://bitnami.com/redirect/to/1135281/bitnami-suitecrm-7.11.15-2-linux-debian-10-x86_64.ova -O $ESXIROOT/OVA/suitecrm/bitnami-suitecrm-7.11.15-2-linux-debian-10-x86_64.ova

## download odoo virtual appliance

  wget https://bitnami.com/redirect/to/1149978/bitnami-odoo-13.0.20200915-0-linux-debian-10-x86_64.ova -O $ESXIROOT/OVA/odoo/bitnami-odoo-13.0.20200915-0-linux-debian-10-x86_64.ova

## download resourcespace virtual appliance

  wget https://bitnami.com/redirect/to/1129319/bitnami-resourcespace-9.3.15737-0-linux-debian-10-x86_64.ova -O $ESXIROOT/OVA/resourcespace/bitnami-resourcespace-9.3.15737-0-linux-debian-10-x86_64.ova

## download LAMP virtual appliance

  wget https://bitnami.com/redirect/to/2261033/bitnami-lampstack-8.2.1-1-r01-linux-vm-debian-11-x86_64-nami.ova -O $ESXIROOT/OVA/lampstack/bitnami-lampstack-8.2.1-1-r01-linux-vm-debian-11-x86_64-nami.ova

exit 0