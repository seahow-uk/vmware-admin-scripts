#!/usr/bin/expect -f
set timeout -1
set ADPASSWORD "Aws2022@"
catch {set ADPASSWORD $env(ADPASSWORD)}

spawn passwd root
expect "New password: "
send -- "$ADPASSWORD\r"
expect "Retype new password: "
send -- "$ADPASSWORD\r"
expect eof