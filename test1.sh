#!/bin/sh
cp /etc/hosts /etc/hosts1 
cat /etc/hosts1 | grep -v 'test-admin.local.net' > /etc/hosts
rm -f /etc/hosts1

echo $IP test-admin.local.net >> /etc/hosts
curl -s http://test-admin.local.net
curl --cacert /certs/ca.pem -s https://test-admin.local.net
