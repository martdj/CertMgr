#!/bin/bash

# let's define some variables
file1=/etc/nginx/ssl/cert.pem
file2=/etc/nginx/ssl/temp.pem
url=blog.martdj.nl
serverip=192.168.1.100

# and some functions we'll use
replace_certificate()
{
        rm -f $file1
        mv $file2 $file1
}

restart_nginx()
{
        systemctl reload nginx.service
}

#start with getting the certificate
openssl s_client -servername $url -showcerts -connect $serverip:7443  </dev/null 2>/dev/null | sed -ne '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/p' > $file2

# test if the command went well. If not, the file would be empty
if [ -s $file2 ]; then
        # The file is not-empty. We double check by checking if the file contains some common text for a certificate
        if grep -Fq "CERTIFICATE-----" $file2; then
           # We continue. Let's see if the certificate is the same as the current one
           if ! cmp --silent "$file1" "$file2"; then
                # The file is not-empty.
                replace_certificate
                restart_nginx
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
