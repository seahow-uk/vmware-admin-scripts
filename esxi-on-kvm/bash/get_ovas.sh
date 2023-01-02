#!/bin/bash

## download WordPress virtual appliance
  mkdir -p $ESXIROOT/OVA/wordpress
  wget https://bitnami.com/redirect/to/1160995/bitnami-wordpress-5.5.1-1-linux-debian-10-x86_64.ova -O $ESXIROOT/OVA/wordpress/bitnami-wordpress-5.5.1-1-linux-debian-10-x86_64.ova

## download mySQL virtual appliance
  mkdir -p $ESXIROOT/OVA/mysql
  wget https://bitnami.com/redirect/to/1153209/bitnami-mysql-8.0.21-4-r08-linux-debian-10-x86_64-nami.ova -O $ESXIROOT/OVA/mysql/bitnami-mysql-8.0.21-4-r08-linux-debian-10-x86_64-nami.ova

## download suiteCRM virtual appliance
  mkdir -p $ESXIROOT/OVA/suitecrm
  wget https://bitnami.com/redirect/to/1135281/bitnami-suitecrm-7.11.15-2-linux-debian-10-x86_64.ova -O $ESXIROOT/OVA/suitecrm/bitnami-suitecrm-7.11.15-2-linux-debian-10-x86_64.ova

## download odoo virtual appliance
  mkdir -p $ESXIROOT/OVA/odoo
  wget https://bitnami.com/redirect/to/1149978/bitnami-odoo-13.0.20200915-0-linux-debian-10-x86_64.ova -O $ESXIROOT/OVA/odoo/bitnami-odoo-13.0.20200915-0-linux-debian-10-x86_64.ova

## download resourcespace virtual appliance
  mkdir -p $ESXIROOT/OVA/resourcespsace
  wget https://bitnami.com/redirect/to/1129319/bitnami-resourcespace-9.3.15737-0-linux-debian-10-x86_64.ova -O $ESXIROOT/OVA/resourcespace/bitnami-resourcespace-9.3.15737-0-linux-debian-10-x86_64.ova

exit 0