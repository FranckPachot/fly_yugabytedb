FROM yugabytedb/yugabyte:latest
RUN  echo zone > /var/zone
ADD  start.sh .
RUN  chmod a+x start.sh
ENV RF=3
CMD ./start.sh
