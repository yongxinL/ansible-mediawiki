#!/bin/bash
# =============================================================================
#
# - Copyright (C) 2016     George Li <yongxinl@outlook.com>
# - ver: 1.0
#
# - you can execute this script every minute by cron in Linux,
#   add following line by executing command: crontab -e
#
#   * * * * * {{ mediawiki_root }}/imagesUploader.sh /dataLibrary/imagesUpload >/dev/null
#   or you can generate the crontab code by site
#   http://www.openjs.com/scripts/jslibrary/demos/crontab.php
#
# - This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
# =============================================================================

## Shell Opts ----------------------------------------------------------------
set -e

## Vars ----------------------------------------------------------------------
_self_root="$( if [ "$( echo "${0%/*}" )" != "$( echo "${0}" )" ] ; then cd "$( echo "${0%/*}" )"; fi; pwd )";

# enable debug
debug_mode=${DEBUG:-off};

## Functions -----------------------------------------------------------------
info_block "checking for required libraries." 2> /dev/null ||
    source "${_self_root}/scripts_library.sh";

## Main ----------------------------------------------------------------------
if [ ! -f "${_self_root}/LocalSettings.php" ]; then
    exit_fail "WARNING: Please run this script from MediaWiki root directory!"
fi

wgDBname=$(sed -n 's/^$wgDBname = "\([^"]*\)";/\1/p' ${_self_root}/LocalSettings.php)
wgDBuser=$(sed -n 's/^$wgDBuser = "\([^"]*\)";/\1/p' ${_self_root}/LocalSettings.php)
wgDBpasswd=$(sed -n 's/^$wgDBpassword = "\([^"]*\)";/\1/p' ${_self_root}/LocalSettings.php)

echo " To create a sqldump, please use below command: "
echo " mysqldump -h localhost -u root -p ${wgDBname} > ${_self_root}/dbs/wikidb_dump_$(date '+%Y%m%d').sql"

read -p "Are you sure you want to continue? <y/N> " prompt
if [[ $prompt == "y" || $prompt == "Y" || $prompt == "yes" || $prompt == "Yes" ]]; then

    echo "Please enter root user MySQL password!"
    read rootpasswd
    log_info "Create user and database ..."
    mysql -uroot -p${rootpasswd} -e "CREATE DATABASE ${wgDBname} /*\!40100 DEFAULT CHARACTER SET utf8 */;"
    mysql -uroot -p${rootpasswd} -e "CREATE USER ${wgDBuser}@localhost IDENTIFIED BY '${wgDBpasswd}';"
    mysql -uroot -p${rootpasswd} -e "GRANT ALL PRIVILEGES ON ${wgDBname}.* TO '${wgDBuser}'@'localhost';"
    mysql -uroot -p${rootpasswd} -e "FLUSH PRIVILEGES;"
    if [ -f "${_self_root}/dbs/wikidb_dump.sql" ]; then
        log_info "import database backup ..."
        mysql -uroot -p${rootpasswd} ${wgDBname} < dbs/wikidb_dump.sql
        php ${_self_root}/maintenance/update.php --quick
    fi

fi