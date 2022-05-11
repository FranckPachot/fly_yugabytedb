zone=$(cat /var/zone)
##############################################################
### wait to see enough pods for the Replication Factor 
##############################################################
echo "Waiting $FLY_APP_NAME to be scaled to the minimum of $RF pods (run: flyctl scale count $RF )"
until [ $( dig +short aaaa ${FLY_APP_NAME}.internal @fdaa::3 | wc -l ) -ge $RF ]
do
 sleep 1
done
##############################################################
### get the 3 addresses where the masters will be started
##############################################################
master_addresses=$( dig +short aaaa ${FLY_APP_NAME}.internal @fdaa::3 | sed -e 's/$/:7100/' | paste -sd,)
##############################################################
### create the master (only if there's not already 3 )
##############################################################
pgrep -fl /home/yugabyte/bin/yb-master ||
 if
  [ $( /home/yugabyte/bin/yb-admin --master_addresses "$master_addresses" list_all_masters | grep -c "ALIVE" ) -lt $RF ]
 then
 /home/yugabyte/bin/yb-master --master_addresses="${master_addresses}" \
 --webserver_port=7000 \
 --default_memory_limit_to_ram_ratio=0.30 --enable_ysql=true \
 --server_broadcast_addresses="[${FLY_PUBLIC_IP}]:7100" --rpc_bind_addresses="[::]:7100" \
 --placement_cloud FLY --placement_region "${FLY_REGION}" --placement_zone "${zone}" \
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
 --placement_cloud FLY --placement_region "${FLY_REGION}" --placement_zone "${zone}" \
 --use_private_ip=cloud --replication_factor=$RF --fs_data_dirs=/data
##############################################################
### all good
##############################################################
