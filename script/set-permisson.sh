#!/bin/bash

rm ../volumes/db/db00*/data/* -rf
rm ../volumes/management/proxysql/data/* -rf
rm ../volumes/mornitoring/prometheus/data/* -rf

chmod 777 -R ../volumes/db/db00*/
chmod 777 -R ../volumes/management/proxysql/
chmod 777 -R ../volumes/mornitoring/prometheus/

chmod 644 -R ../volumes/db/db00*/conf/*
chmod 644 -R ../volumes/management/proxysql/conf/*
chmod 644 -R ../volumes/management/orchestrator/conf/*
chmod 644 -R ../volumes/mornitoring/prometheus/conf/*

chown mysql:mysql ../volumes/db/db00*/conf/my.cnf