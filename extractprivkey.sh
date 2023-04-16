#!/bin/bash
Creator="Martijn de Jong"
CreatorMail="martdj@martdj.nl"
Version=20230416

##### variables #####
tempkey=privkeypw.pem
keyfile=privkey.pem
certfile=cert.pem
#####################

usage()
{
  echo $Version created by $Creator
  echo "Usage: extractprivkey.sh <certfile.p12|pfx> ec|rsa (optional)"
  echo
  return 0
}

get_keytype()
{
  if [ "$2" = "rsa" ]; then
    KeyType="rsa"
  elif [ "$2" = "ec" ]; then
    KeyType="ec"
  else
    echo "No keytype given. ECDSA implied"
    KeyType="ec"
  fi
}

get_password()
{
  read -s -p "Certificate Password: " password
}

get_key()
{
  openssl pkcs12 -in $p12file -nodes -nocerts -out $tempkey -password pass:$password
  openssl $KeyType -in $tempkey -out $keyfile
  rm -f $tempkey
}

get_cert()
{
  openssl pkcs12 -info -in $p12file -nokeys -password pass:$password -out $certfile
}

p12file=$1
if [ ! -z $p12file ] && [ -f $p12file ]; then
  p12file=$1
  get_keytype
  get_password
  get_key
  get_cert
  echo "you can find your private key and certificate as $keyfile and $certfile"
else
  usage
fi
