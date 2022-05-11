# YugabyteDB on Fly.io

This is an example YugabyteDB cluster that runs on multiple Fly.io regions.

## Install flyctl
```
curl -sL https://fly.io/install.sh | sh
export FLYCTL_INSTALL="/home/opc/.fly"
export PATH="$FLYCTL_INSTALL/bin:$PATH"
```


```

# destroy
fly volumes list | awk '/data/{print "fly volumes delete --yes "$1}' | sh
fly destroy yb --yes

# config
REGIONS="fra cdg lhr"
VOL_GB=1
# deploy
fly launch --region "${REGIONS%% *}" --name yb --copy-config --no-deploy --now
for reg in ${REGIONS} ; do fly volumes create data --region $reg --size "${VOL_GB}" ; done
fly deploy
timeout 15 fly logs
flyctl scale count 3
timeout 15 fly logs
fly ips list

```


flyctl volumes list | awk '
NR>1 && NF>9{
 print "flyctl ssh console " $7 ".vm.yb.internal -C " q "sed -e s/zone/" $6 "/ -i /var/zone" q " ; flyctl vm restart " $7 " ; sleep 5 " 
}' q="'" | sh -x 





flyctl volumes list | awk 'NR>1 && NF>9{print "echo " q "echo "$6" > /var/zone" q "| fly ssh console " $7 ".vm.yb.internal" }' q="'" 

flyctl volumes list | awk 'NR>1{print "echo " q "cat "$6"> /var/zone" q "| fly ssh console " $7 ".vm.yb.internal" }' q="'"


fly ssh console .vm.yb.internal
$ ./bin/yb-ts-cli [ --server_address=<host>:<port> ] set_flag [ --force ] <flag> <value>

yb-ts-cli set_flag --force placement_zone xxx

