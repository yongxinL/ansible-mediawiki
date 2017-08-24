#!/bin/bash
# =============================================================================
#
# - Copyright (C) 2017     George Li <yongxinl@outlook.com>
#
# - This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
# =============================================================================

## Function Library ----------------------------------------------------------
print_info "*** Checking for required libraries." 2> /dev/null ||
    source "functions.bash";

## Vars ----------------------------------------------------------------------
# declare version
script_version="1.0.5"

# declare Logs, simple or verbose
log_level=verbose
log_file=/var/log/mediawiki.log

## Functions -----------------------------------------------------------------

## Main ----------------------------------------------------------------------
if [ ! -f "${script_path}/LocalSettings.php" ]; then
    exit_fail "Please run this script in MediaWiki root directory! "
fi

if [ -f "${script_path}/preparedb.sql" ]; then
	rm -f "${script_path}/preparedb.sql"
fi

# retrieve DB user/password
db_name=$(sed -n 's/^$wgDBname = "\([^"]*\)";/\1/p' ${script_path}/LocalSettings.php)
db_user=$(sed -n 's/^$wgDBuser = "\([^"]*\)";/\1/p' ${script_path}/LocalSettings.php)
db_pass=$(sed -n 's/^$wgDBpassword = "\([^"]*\)";/\1/p' ${script_path}/LocalSettings.php)

print_info "You should need below command to create the database dump.
mysqldump -h localhost -u root -p ${db_name} > ${script_path}/dbs/wikidb_dump_$(date '+%Y%m%d').sql"

read -p "Are you sure you want to continue? <y/N> " prompt
if [[ $prompt == "y" || $prompt == "Y" || $prompt == "yes" || $prompt == "Yes" ]]; then

    echo "Please enter root user MySQL password!"
    read rootpasswd
    print_info "Create wiki database ${db_name} and user ${db_user} ..."
    echo "/* - drop database if exists. */" > ${script_path}/preparedb.sql
    echo "DROP DATABASE IF EXISTS ${db_name};" >> ${script_path}/preparedb.sql
    echo "/* - create database if not exists. */" >> ${script_path}/preparedb.sql
    echo "CREATE DATABASE IF NOT EXISTS ${db_name} /*\!40100 DEFAULT CHARACTER SET utf8 */;" >> ${script_path}/preparedb.sql
    echo "/* - there is not create user if not exist command, " >> ${script_path}/preparedb.sql
    echo "     but grant privileges will create user first if user doesn't exist! */" >> ${script_path}/preparedb.sql
    echo "GRANT ALL PRIVILEGES ON ${db_name}.* TO '${db_user}'@'localhost';" >> ${script_path}/preparedb.sql
    echo "/* - reset user password. */" >> ${script_path}/preparedb.sql
    echo "UPDATE mysql.user" >> ${script_path}/preparedb.sql
    echo "    SET authentication_string = PASSWORD('${db_pass}'), password_expired = 'N'" >> ${script_path}/preparedb.sql
    echo "    WHERE User = '${db_user}' AND Host = 'localhost';" >> ${script_path}/preparedb.sql
    echo "/* - flush privileges. */" >> ${script_path}/preparedb.sql
    echo "FLUSH PRIVILEGES;" >> ${script_path}/preparedb.sql
    mysql -uroot -p${rootpasswd} < ${script_path}/preparedb.sql
    if [ $? -ne 0 ]; then
    	exit_fail
    else
    	rm -f ${script_path}/preparedb.sql
    fi

    if [ -f "${script_path}/dbs/wikidb_dump.sql" ]; then
        print_info "import database backup ..."
        mysql -uroot -p${rootpasswd} ${db_name} < ${script_path}/dbs/wikidb_dump.sql
        php ${script_path}/maintenance/update.php --quick
    fi

fi