##############################################################
### wait to see 3 addresses 
##############################################################
until [ $( nslookup "$FLY_APP_NAME.internal" | grep -c "$FLY_APP_NAME.internal" ) -ge $RF ]
do
 echo "Waiting $FLY_APP_NAME to be scaled to 3 pods for starting master (run: flyctl scale count $RF )" ; sleep 1
done
##############################################################
### get the 3 addresses where the masters will be started
##############################################################
master_addresses=$(nslookup $FLY_APP_NAME.internal | grep -A1 "$FLY_APP_NAME.internal" | awk '/^Address:/{print "["$2"]:7100"}' | paste -sd,)
set | grep ^master_addresses
##############################################################
### create the master (only if there's not already 3 )
##############################################################
pgrep -fl /home/yugabyte/bin/yb-master ||
 if
  [ $( /home/yugabyte/bin/yb-admin --master_addresses "$master_addresses" list_all_masters | grep -c "ALIVE" ) -lt $RF ]
 then
 /home/yugabyte/bin/yb-master --master_addresses="${master_addresses}" \
 --webserver_port=8080 \
 --default_memory_limit_to_ram_ratio=0.30 --enable_ysql=true \
 --server_broadcast_addresses="[${FLY_PUBLIC_IP}]:7100" --rpc_bind_addresses="[::]:7100" \
 --placement_cloud FLY --placement_region "${FLY_REGION}" --placement_zone "$(curl -s ipinfo.io | awk -F'"' '$2=="loc"{sub(/,/,"/");print $4}')" \
 --use_private_ip=cloud --replication_factor=$RF --fs_data_dirs=/data &
 fi
##############################################################
### wait to see a yb-master leader before starting tserver
##############################################################
until
 /home/yugabyte/bin/yb-admin --master_addresses "$master_addresses" list_all_masters | grep -C42 -E "ALIVE.*LEADER"
do
 waiting to see a master leader...
done
pgrep -fl /home/yugabyte/bin/yb-tserver ||
/home/yugabyte/bin/yb-tserver --tserver_master_addrs="${master_addresses}" \
 --enable_ysql=true \
 --default_memory_limit_to_ram_ratio=0.30 \
 --server_broadcast_addresses="[${FLY_PUBLIC_IP}]:9100" --rpc_bind_addresses="[::]:9100" \
 --placement_cloud FLY --placement_region "${FLY_REGION}" --placement_zone "$(curl -s ipinfo.io | awk -F'"' '$2=="loc"{sub(/,/,"/");print $4}')" \
 --use_private_ip=cloud --replication_factor=$RF --fs_data_dirs=/data
##############################################################
### all good
##############################################################
