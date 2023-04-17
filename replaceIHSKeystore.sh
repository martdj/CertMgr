#!/bin/bash
version=1.2
# let's define some variables
file1=/appl/tools/certs/cert.pem
file2=/appl/tools/certs/temp.pem
url=blog.martdj.nl
serverip=192.168.7.100
keystorepw=A-very-secret-password
############## Functions ##################
remove_keystore()
{
        rm -f /opt/IBM/HTTPServer/ssl/ihskey.*
}

replace_certificate()
{
        rm -f $file1
        mv $file2 $file1
}

create_p12()
{
        openssl pkcs12 -export -out /appl/tools/certs/martdj.nl.cert.p12 -in /appl/tools/certs/cert.pem -inkey /appl/tools/certs/martdj.nl.key -password pass:$keystorepw
}

create_keystore()
{
        # Create a new keystore
        /opt/IBM/HTTPServer/bin/gskcapicmd -keydb -create -db /opt/IBM/HTTPServer/ssl/ihskey.kdb -pw $keystorepw -stash
        /opt/IBM/HTTPServer/bin/gskcapicmd -cert -add -db /opt/IBM/HTTPServer/ssl/ihskey.kdb -pw $keystorepw -file /appl/tools/certs/lets-encrypt-r3.pem -label lets-encrypt-r3
        /opt/IBM/HTTPServer/bin/gskcapicmd -cert -add -db /opt/IBM/HTTPServer/ssl/ihskey.kdb -pw $keystorepw -file /appl/tools/certs/isrgrootx1.pem -label isrgrootx1
        /opt/IBM/HTTPServer/bin/gskcapicmd -cert -import -db /appl/tools/certs/martdj.nl.cert.p12 -pw $keystorepw -target /opt/IBM/HTTPServer/ssl/ihskey.kdb -target_pw $keystorepw
        /opt/IBM/HTTPServer/bin/gskcapicmd -cert -setdefault -label CN=*.martdj.nl -db /opt/IBM/HTTPServer/ssl/ihskey.kdb -stashed
}

show_certs()
{
        # and print the output
        /opt/IBM/HTTPServer/bin/gskcapicmd -cert -list -db /opt/IBM/HTTPServer/ssl/ihskey.kdb -stashed
}

##################### start script #####################
openssl s_client -servername $url:7443 -showcerts -connect $serverip:7443  </dev/null 2>/dev/null | sed -ne '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/p' > $file2
# test if the command went well. If not, the file would be empty
if [ -s $file2 ]; then
        # The file is not-empty. We double check by checking if the file contains some common text for a certificate
        if grep -Fq "CERTIFICATE-----" $file2; then
           # We continue. Let's see if the certificate is the same as the current one
           if ! cmp --silent "$file1" "$file2"; then
                # The file is not-empty.
                replace_certificate
                remove_keystore
                create_p12
                create_keystore
                show_certs
                echo "all done"
           else
                # The file is empty.
                rm -f $file2
                echo "Nothing to do"
           fi

        else
           # code if not found. abort
           rm -f $file2
           echo "Nothing to do"
        fi
else
        # The file is empty. remove the file and abort
        rm -f $file2
        echo "Nothing to do"
fi
