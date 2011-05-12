After you've installed the Warehouse module on all slurm compute
nodes, use "memcached-show-servers.pl" to create a memcached.conf.pl
file for you:

 (
  set -ex
  echo '$Warehouse::memcached_servers_arrayref = ['
  srun -N47 memcached-show-servers.pl
  echo '];'
 ) | sudo bash -c 'cat > /etc/warehouse/memcached.conf.pl'

Then distribute memcached.conf.pl to all compute nodes:

 sudo salloc -N47 sbcast --force \
   /etc/warehouse/memcached.conf.pl \
   /etc/warehouse/memcached.conf.pl
