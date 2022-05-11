
# destroy old cluster
fly volumes list | awk '/data/{print "fly volumes delete --yes "$1}' | sh
fly destroy yb --yes

# create 3 volumes in 3 regions
for reg in ord cdg ams ; do fly volumes create data --region $reg --size 10 ; done

# deploy to 3 VMs so that the yb-masters are crated
fly deploy
flyctl scale count 3
timeout 3 fly logs

# can scale more to create tservers - 6 in total
for reg in ord cdg ams ; do fly volumes create data --region $reg --size 10 ; done
flyctl scale count 6
timeout 90 fly logs

# check the servers are visible
fly ssh console
ysqlsh
select * from yb_servers();
