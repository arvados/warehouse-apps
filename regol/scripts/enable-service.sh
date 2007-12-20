#!/bin/sh

set -ex

which regol-service

mkdir -p /var/service/regol/log/main

cat >/var/service/regol/run <<EOF
#!/bin/sh
exec regol-service 2>&1
EOF
chmod +x /var/service/regol/run

cat >/var/service/regol/log/run <<EOF
#!/bin/sh
exec svlogd -tt main
EOF
chmod +x /var/service/regol/log/run

set +ex

echo Wait 10 seconds:
sleep 10
sv status /var/service/regol/
