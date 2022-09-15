#!/bin/bash
#
# use this script to parse out Unix Epoch times and convert them to syslog style timestamps
# I use this to make awslogsd capable of ingesting /var/log/audit/audit.log
# 
# example usage: epochtohuman.sh /var/log/audit/audit.log

IFS=$'\n'

lines=(`tail -n 20 $1`)

for olin in ${lines[*]}; do
  datt=`echo $olin | perl -nle '/msg=audit\(([0-9]{10}\.[0-9]{3}):/  && print "$1"'`
  date_human_readable=`date -d @$datt +%b\ %d\ %H:%M:%S`
  echo ${date_human_readable}" "${olin}
done