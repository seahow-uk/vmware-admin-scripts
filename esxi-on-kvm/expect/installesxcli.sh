#!/usr/bin/expect -f

set timeout 5
set ESXCLIFILE "esxcli/esxcli-7.0.0-15866526-lin64.sh"
set ESXIROOT "/scripts/vmware-admin-scripts/esxi-on-kvm"
catch {set ESXCLIFILE $env(ESXCLIFILE)}
catch {set ESXIROOT $env(ESXIROOT)}

spawn ${ESXIROOT}/${ESXCLIFILE}

expect {
    "Press any key to continue to the EULA" {
        sleep 0.2
        send "x";
    }
    timeout {
        send_user "\nTimeout 1\n";
        exit 1
    }
}

expect {
    "esxcli_eula.txt" {
        sleep 0.2
        send "q";
        sleep 1
        send "y";
        exp_continue;
    }
    timeout {
        send_user "\nTimeout 2\n";
        exit 1
    }
}  