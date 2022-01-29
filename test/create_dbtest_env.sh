#!/bin/bash

MASTER_NODE='db001'

EXEC_MASTER="sudo docker exec ${MASTER_NODE} mysql -uroot -proot -N -e "

# For ProxySQL
${EXEC_MASTER} "CREATE DATABASE testdb DEFAULT CHARACTER SET=utf8" 2>&1 | grep -v "Using a password"
${EXEC_MASTER} "CREATE TABLE testdb.insert_test(hostname varchar(5) not null, insert_time datetime not null)" 2>&1 | grep -v "Using a password"
${EXEC_MASTER} "CREATE USER appuser@'%' IDENTIFIED BY 'apppass'" 2>&1 | grep -v "Using a password"
${EXEC_MASTER} "GRANT SELECT, INSERT, UPDATE, DELETE ON testdb.* TO appuser@'%'" 2>&1 | grep -v "Using a password"
${EXEC_MASTER} "CREATE USER monitor@'%' IDENTIFIED BY 'monitor'" 2>&1 | grep -v "Using a password"
${EXEC_MASTER} "GRANT REPLICATION CLIENT ON *.* TO monitor@'%'" 2>&1 | grep -v "Using a password"