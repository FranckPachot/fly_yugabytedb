FROM yugabytedb/yugabyte:latest
ADD  start.sh .
RUN  chmod a+x start.sh
ENV RF=3
CMD ./start.sh
