#!/bin/bash

## enable autostart on all hosts (do it last so it catches the installed vms)
  for ((i = 1; i <= 10; i++)); do
  sshpass -p "$HOSTPASSWORD" ssh "esxi$i.$DNSDOMAIN" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "vim-cmd hostsvc/autostartmanager/enable_autostart true"
  done

exit 0
