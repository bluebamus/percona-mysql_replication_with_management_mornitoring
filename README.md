# percona-mysql_replication_with_management_mornitoring
It supports percona mysql replication and management with orchestrator, sqlproxy and monitoring with prometheus and grafana.

# Notice
- 'Slave_IO_Running' goes into 'connecting' state due to network connectivity issues when running multiple database containers on one server. 
- If you connect to a any slave container and enter 'mysql -h<master server> -urepl -prepl' once, 'Slave_IO_Running' becomes yes.
# Working environment

# If you want to build a Dockerfile clearly, refer to the site below.
- [percona server download site](https://www.percona.com/downloads/Percona-Server-5.7/LATEST/)
- [prometheus node download site](https://prometheus.io/download/#node_exporter)
- [prometheus mysqld download site](https://prometheus.io/download/#mysqld_exporter)
- [percona official github site for docker](https://github.com/percona/percona-docker/tree/master/percona-server-5.7)

# Required file, you must create it yourself.
- mysqld_exporter : .my.cnf 
  - If you want to access another server, you need to modify the host address in .my.cnf.
# How to start!

# Reference