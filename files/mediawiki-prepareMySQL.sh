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
script_path="$( if [ "$( echo "${0%/*}" )" != "$( echo "${0}" )" ] ; then cd "$( echo "${0%/*}" )"; fi; pwd )"
script_usage="Usage: $0"

## Functions -----------------------------------------------------------------

## Main ----------------------------------------------------------------------
if [ ! -f "${script_path}/LocalSettings.php" ]; then
    exit_fail "Please run this script in MediaWiki root directory! "
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
    print_info "Create user and database ..."
    mysql -uroot -p${rootpasswd} -e "CREATE DATABASE ${wgDBname} /*\!40100 DEFAULT CHARACTER SET utf8 */;"
    mysql -uroot -p${rootpasswd} -e "CREATE USER ${wgDBuser}@localhost IDENTIFIED BY '${wgDBpasswd}';"
    mysql -uroot -p${rootpasswd} -e "GRANT ALL PRIVILEGES ON ${wgDBname}.* TO '${wgDBuser}'@'localhost';"
    mysql -uroot -p${rootpasswd} -e "FLUSH PRIVILEGES;"
    if [ -f "${_self_root}/dbs/wikidb_dump.sql" ]; then
        print_info "import database backup ..."
        mysql -uroot -p${rootpasswd} ${db_name} < dbs/wikidb_dump.sql
        php ${script_path}/maintenance/update.php --quick
    fi

fi