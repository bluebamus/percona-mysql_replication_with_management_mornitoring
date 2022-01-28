#!/bin/bash

chmod 777 -R ../volumes/db/db00*/data/
chmod 777 -R ../volumes/db/db00*/log/
chmod 777 -R ../volumes/management/proxysql/data/
chmod 777 -R ../volumes/mornitoring/prometheus/data/

chmod 655 -R ../volumes/db/db00*/conf/
chmod 655 -R ../volumes/management/proxysql/conf/
chmod 655 -R ../volumes/management/orchestrator/conf/
chmod 655 -R ../volumes/mornitoring/prometheus/conf/

chown mysql:mysql ../volumes/db/db00*/conf/my.cnf