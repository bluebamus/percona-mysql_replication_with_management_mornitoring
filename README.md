# percona-mysql_replication_with_management_mornitoring
It supports percona mysql replication and management with orchestrator, sqlproxy and monitoring with prometheus and grafana.

# Notice
### Docker-compose network
- 'Slave_IO_Running' goes into 'connecting' state due to network connectivity issues when running multiple database containers on one server. 
- If you connect to a any slave container and enter 'mysql -h<master server> -urepl -prepl' once than the parameter value of 'Slave_IO_Running' becomes yes.
### If you want to create docker bridge network before running docker-compose
- use docker command
``` shell
docker network create --driver bridge <network name>
ex) docker network create --driver bridge mybridge
```
- modify docker-compose.yml
  - before
    ``` yml
    networks:
    mybridge:
        #external: true
        driver: bridge
    ```
  - after
    ``` yml
    networks:
    mybridge:
        external: true
        #driver: bridge
    ```
  - It means docker-compose will use an existing network named "mybridge".
- use docker network command
  ``` shell
  docker network ls -f, --format, --no-trunc, -q
  docker network create <option> network
    ex) docker network create --driver=bridge mybridge
  docker network connect <option> network container name
  docker network disconnect <option> network container name
  docker network inspect <option> network name
  docker network rm <network name>
  ```
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
## Docker-compose
1. move compose folder
2. run docker-compose
``` shell
# if you want to get logs
docker-compose up

# if you want to run by deamon mode
docker-compose up -d
```
3. move script folder
4. run script
   - depending on your Linux OS type, run one.
5. it accesses one of the slave containers, makes one connection to the master's mysql server and terminates it.
``` shell
docker exec -it <slave container> bash
mysql -hdb001 -uroot -proot
```
6. check slave status
``` shell
docker exec -it <slave container> bash
mysql -uroot -proot
mysql> show slave status\G
...
Master_Host: db001
...
Slave_IO_Running: Yes
Slave_SQL_Running: Yes
...
```
## Orchestrator
1. connect master container
``` shell
docker exec -it db001 bash
```
2. run query in mysql cli
``` shell
CREATE USER orc_client_user@'%' IDENTIFIED BY 'orc_client_password'
GRANT SUPER, PROCESS, REPLICATION SLAVE, RELOAD ON *.* TO orc_client_user@'%'
GRANT SELECT ON mysql.slave_master_info TO orc_client_user@'%'
```
3. go webbrowger
- http://{docker host ip}:3000/web/clusters
  - ex)http://localhost:3000/web/clusters   
![orchestrator-discover](https://user-images.githubusercontent.com/24231446/151568247-c8af3453-5849-4a29-a512-1099dca2b71c.png)
4. check board   
![board1](https://user-images.githubusercontent.com/24231446/151568706-40bc7949-f961-4e49-af76-73ce34191f8a.png)
![board2](https://user-images.githubusercontent.com/24231446/151568719-2018ae12-4c7e-4b73-b1f5-0f36c4dc2af4.png)

## ProxySQL
1. connect ProxySQL
``` shell
mysql -h127.0.0.1 -P16032 -uradmin -pradmin --prompt "ProxySQL Admin>"
ProxySQL Admin> INSERT INTO mysql_servers(hostgroup_id, hostname, port) VALUES (10, 'db001', 3306)
ProxySQL Admin> INSERT INTO mysql_servers(hostgroup_id, hostname, port) VALUES (20, 'db001', 3306)
ProxySQL Admin> INSERT INTO mysql_servers(hostgroup_id, hostname, port) VALUES (20, 'db002', 3306)
ProxySQL Admin> INSERT INTO mysql_servers(hostgroup_id, hostname, port) VALUES (20, 'db003', 3306)
ProxySQL Admin> INSERT INTO mysql_replication_hostgroups VALUES (10,20,'read_only','')
ProxySQL Admin> LOAD MYSQL SERVERS TO RUNTIME
ProxySQL Admin> SAVE MYSQL SERVERS TO DISK

ProxySQL Admin> INSERT INTO mysql_users(username,password,default_hostgroup,transaction_persistent) VALUES ('appuser','apppass',10,0)
ProxySQL Admin> LOAD MYSQL USERS TO RUNTIME
ProxySQL Admin> SAVE MYSQL USERS TO DISK

ProxySQL Admin> INSERT INTO mysql_query_rules(rule_id,active,match_pattern,destination_hostgroup) VALUES (1,1,'^SELECT.*FOR UPDATE$',10)
ProxySQL Admin> INSERT INTO mysql_query_rules(rule_id,active,match_pattern,destination_hostgroup) VALUES (2,1,'^SELECT',20)
ProxySQL Admin> LOAD MYSQL USERS TO RUNTIME
ProxySQL Admin> SAVE MYSQL USERS TO DISK
```
2. create test database at master database
``` mysql
mysql> create database testdb default character set utf8;
mysql> create table testdb.insert_test(hostname varchar(5) not null, insert_time datetime not null);

mysql> create user appuser@'%' identified by 'apppass';
mysql> grant select, insert, update, delete on testdb.* to appuser@'%';

mysql> create user 'monitor'@'%' identified by 'monitor';
mysql> grant REPLICATION CLIENT on *.* to 'monitor'@'%';

mysql> flush privileges;
```
3. test
``` shell
mysql -h127.0.0.1 -P16033 -uappuser -papppass -N -e "select @@hostname,now()" 2>&1| grep -v "Warning"

mysql -uappuser -papppass -h127.0.0.1 -P16033 -N -e "insert into testdb.insert_test select @@hostname,now()" 2>&1| grep -v "Warning"  
```
# Reference
- [인프런 - 따라하며 배우는 MySQL on Docker 학습 정리 - Master/Slave Replication 구성](https://devspoon.tistory.com/19)
- [인프런 - 따라하며 배우는 MySQL on Docker 학습 정리 - Orchestrator를 이용한 HA(High Availability) 구성 방법 (1)](https://devspoon.tistory.com/20)
- [인프런 - 따라하며 배우는 MySQL on Docker 학습 정리 - Orchestrator를 이용한 HA(High Availability) HA 매뉴얼 테스트[수동 관리] (2)](https://devspoon.tistory.com/21)
- [인프런 - 따라하며 배우는 MySQL on Docker 학습 정리 - Orchestrator를 이용한 HA(High Availability) HA 매뉴얼 테스트[자동 복구] (3)](https://devspoon.tistory.com/22)
- [인프런 - 따라하며 배우는 MySQL on Docker 학습 정리 - ProxySQL을 이용한 Proxy Layer 구축 (1)](https://devspoon.tistory.com/23)
- [인프런 - 따라하며 배우는 MySQL on Docker 학습 정리 - ProxySQL 실습 (2)](https://devspoon.tistory.com/24)
- [인프런 - 따라하며 배우는 MySQL on Docker 학습 정리 - ProxySQL 실습 : Insert (3)](https://devspoon.tistory.com/25)