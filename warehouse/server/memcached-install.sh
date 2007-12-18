#!/bin/sh

set -ex
cd /tmp

if ! which memcached
then
    apt-get install -y memcached
fi

mkdir -p /var/service/memcached/log/main
cat >/var/service/memcached/run <<'EOF'
#!/bin/sh
size="`grep MemTotal /proc/meminfo | tr -dc 0-9`"
size="$(($size/2000))"
if [ "$size" -gt 3000 ]
then
  size=3000
fi
killall memcached
exec memcached -u nobody -m "$size"
EOF
chmod +x /var/service/memcached/run

cat >/var/service/memcached/log/run <<EOF
#!/bin/sh
exec svlogd -tt main
EOF
chmod +x /var/service/memcached/log/run

chmod 0 /etc/init.d/memcached
