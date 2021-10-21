#!/bin/bash
# =============================================================================
#
# - Copyright (C) 2021     George Li <yongxinl@outlook.com>
#
# - This is part of Family website project.
#
#   or you can generate the crontab code by site
#   http://www.openjs.com/scripts/jslibrary/demos/crontab.php
#
# - This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
# =============================================================================

## Function Library ----------------------------------------------------------
print_info "*** Checking for required libraries." 2> /dev/null ||
   source "/etc/functions.bash" 2> /dev/null ||
   source "$(dirname $(if [ "$( echo "${0%/*}" )" != "$( echo "${0}" )" ] ; then cd "$( echo "${0%/*}" )"; fi; pwd))/functions.bash" 2> /dev/null

if [[ $? -ne 0 ]]; then
   echo "Unable to find required function Library file, exit !!!"
   exit 1
fi

## Vars ----------------------------------------------------------------------
# declare version
script_version="1.1.0"

## Functions -----------------------------------------------------------------
# return script help
show_usage() {
    printf "\n"
    printf 'usage: %s [OPTIONS] PATH | URL \n' "$(basename $0)"
    printf "\n"
    printf "%s\n" "build or download docker image from [PATH] or [URL]."
    printf "\n"
    printf "%s\n" "Options"
    printf "\t%s\n" "-b, --backup:          Backup Database"
    printf "\t%s\n" "-c, --create:          Create Db and User"
    printf "\t%s\n" "-r, --restore:         Restore Database"
    printf "\t%s\n" "-u, --upgrae:          System Upgrade"
    printf "\t%s\n" "-h, --help:            Prints Help"
    printf "\n"
}

function init() {
    # retrieve DB user/password
    if [ -f "${parent_path}/LocalSettings.php" ]; then

        print_info "retriving Wiki DB information ..."
        db_name=$(sed -n 's/^$wgDBname = "\([^"]*\)";/\1/p' ${parent_path}/LocalSettings.php)
        db_user=$(sed -n 's/^$wgDBuser = "\([^"]*\)";/\1/p' ${parent_path}/LocalSettings.php)
        db_pass=$(sed -n 's/^$wgDBpassword = "\([^"]*\)";/\1/p' ${parent_path}/LocalSettings.php)
        sv_name=$(sed -n 's/^$wgServer = "\([^"]*\)";/\1/p' ${parent_path}/LocalSettings.php)
        db_prod="library"

    elif [ -f "${parent_path}/.env" ]; then

        print_info "retriving FireflyIII DB information ..."
        db_name=$(sed -n 's/^DB_DATABASE=\([^"]*\)/\1/p' ${parent_path}/.env)
        db_user=$(sed -n 's/^DB_USERNAME=\([^"]*\)/\1/p' ${parent_path}/.env)
        db_pass=$(sed -n 's/^DB_PASSWORD=\([^"]*\)/\1/p' ${parent_path}/.env)
        db_prod="budget"

    elif [ -f "${parent_path}/config.php" ]; then

        print_info "retriving FireflyIII DB information ..."
        db_name=$(sed -n 's/^$CFG->dbname    = \([^"]*\)/\1/p' ${parent_path}/config.php | tr -d "';")
        db_user=$(sed -n 's/^$CFG->dbuser    = \([^"]*\)/\1/p' ${parent_path}/config.php | tr -d "';")
        db_pass=$(sed -n 's/^$CFG->dbpass    = \([^"]*\)/\1/p' ${parent_path}/config.php | tr -d "';")
        db_prod="scholar"

    else
        exit_fail "Unable to find required configuration file in ${parent_path} directory ..."
    fi

    # declare variables
    def_bkname="${parent_path}/dbs/theLijia-${db_prod}-$(date '+%y%m').sql.gz"
    def_wkroot="/tmp/upload$$"
    ena_bkfile="false"

}

function create_db () {

    local _dbname="$1"
    local _dbuser="$2"
    local _dbpass="$3"

    print_info "Preparing working directory ${def_wkroot} ...";
    if [ ! -d "${def_wkroot}" ]; then
        mkdir -p "${def_wkroot}";
    else
        rm -rf "${def_wkroot}/*";
    fi

    print_info "database does not existed, we are going to create the user/database again!"
    print_info "Create database ${_dbname} and user ${_dbuser} ..."
    echo "/* - drop database if exists. */" > ${def_wkroot}/preparedb.sql
    echo "DROP DATABASE IF EXISTS ${_dbname};" >> ${def_wkroot}/preparedb.sql
    echo "/* - create database if not exists. */" >> ${def_wkroot}/preparedb.sql
    echo "CREATE DATABASE IF NOT EXISTS ${_dbname} /*\!40100 DEFAULT CHARACTER SET utf8 */;" >> ${def_wkroot}/preparedb.sql
    echo "GRANT USAGE" >> ${def_wkroot}/preparedb.sql
    echo "      ON *.*" >> ${def_wkroot}/preparedb.sql
    echo "      TO '${_dbuser}'@'localhost'" >> ${def_wkroot}/preparedb.sql
    echo "      IDENTIFIED BY '${_dbpass}';" >> ${def_wkroot}/preparedb.sql
    echo "GRANT SELECT," >> ${def_wkroot}/preparedb.sql
    echo "      INSERT," >> ${def_wkroot}/preparedb.sql
    echo "      UPDATE," >> ${def_wkroot}/preparedb.sql
    echo "      DELETE," >> ${def_wkroot}/preparedb.sql
    echo "      CREATE," >> ${def_wkroot}/preparedb.sql
    echo "      DROP," >> ${def_wkroot}/preparedb.sql
    echo "      INDEX," >> ${def_wkroot}/preparedb.sql
    echo "      ALTER," >> ${def_wkroot}/preparedb.sql
    echo "      CREATE TEMPORARY TABLES," >> ${def_wkroot}/preparedb.sql
    echo "      LOCK TABLES," >> ${def_wkroot}/preparedb.sql
    echo "      CREATE VIEW," >> ${def_wkroot}/preparedb.sql
    echo "      SHOW VIEW," >> ${def_wkroot}/preparedb.sql
    echo "      CREATE ROUTINE," >> ${def_wkroot}/preparedb.sql
    echo "      ALTER ROUTINE," >> ${def_wkroot}/preparedb.sql
    echo "      EXECUTE," >> ${def_wkroot}/preparedb.sql
    echo "      EVENT," >> ${def_wkroot}/preparedb.sql
    echo "      TRIGGER" >> ${def_wkroot}/preparedb.sql
    echo "      ON ${_dbname}.*" >> ${def_wkroot}/preparedb.sql
    echo "      TO '${_dbuser}'@'localhost';" >> ${def_wkroot}/preparedb.sql
    echo "FLUSH PRIVILEGES;" >> ${def_wkroot}/preparedb.sql
    echo "/* - reset user password if necessary." >> ${def_wkroot}/preparedb.sql
    echo "UPDATE mysql.user" >> ${def_wkroot}/preparedb.sql
    echo "      SET authentication_string = PASSWORD('${_dbpass}'), password_expired = 'N'" >> ${def_wkroot}/preparedb.sql
    echo "      WHERE User = '${_dbuser}' AND Host = 'localhost'; */" >> ${def_wkroot}/preparedb.sql

    print_warn "Please enter root user MySQL password!"
    while IFS= read -p "$prompt" -r -s -n 1 char
    do
        if [[ $char == $'\0' ]]; then
            break
        fi
        prompt='*'
        rootpasswd+="$char"
    done

    mysql -uroot -p${rootpasswd} < ${def_wkroot}/preparedb.sql
    if [ $? -ne 0 ]; then
        exit $?
    else
        print_info "Cleanup working directory ${def_wkroot} ...";
        rm -rf ${def_wkroot}
        exit_success "User and Database have be create successful ..."
    fi

}

function check_db () {

    local _dbname="$1"
    local _dbuser="$2"
    local _dbpass="$3"

    # check if user/database exists in MySQL server
    # you might see the error message if the user does not exist in the database,  it can be ignored.
    result="$(mysql -u${_dbuser} -p${_dbpass} --skip-column-names -e "SHOW DATABASES" | grep -w ${_dbname})"

    if [ "${result}" != "${_dbname}" ]; then
        create_db "${_dbname}" "${_dbuser}" "${_dbpass}"
    fi

}

function backup_db () {

    local _bkname="$1"
    local _dbname="$2"
    local _dbuser="$3"
    local _dbpass="$4"

    print_info "Preparing working directory ${def_wkroot} ...";
    if [ ! -d "${def_wkroot}" ]; then
        mkdir -p "${def_wkroot}";
    else
        rm -rf "${def_wkroot}/*";
    fi

    if [ ! -d "$(dirname ${_bkname})" ]; then
        mkdir -p "$(dirname ${_bkname})"
    fi

    print_info "Backup database to $(basename ${_bkname%.*}) ..."
    cd ${def_wkroot}
    mysqldump -h localhost -u${_dbuser} -p${_dbpass} ${_dbname} > "${def_wkroot}/$(basename ${def_bkname%%.*}).sql";
    gzip -9 "${def_wkroot}/$(basename ${def_bkname%%.*}).sql";

    if [ "${ena_bkfile}" == "true" ]; then

        print_info "Starting File backup ..."
        if [ ${db_prod} == "library" ]; then
            print_info "Backup Wiki files ..."
            cp -r "${parent_path}/LocalSettings.php" "${def_wkroot}/" > /dev/null
            cp -r "${parent_path}/conf.d" "${def_wkroot}/" > /dev/null
            cp -r "${parent_path}/images" "${def_wkroot}/" > /dev/null
        elif  [ ${db_prod} == "budget" ]; then
            print_info "Backup FireflyIII files ..."
            cp -r "${parent_path}/.env" "${def_wkroot}/env.txt" > /dev/null
            cp -r "${parent_path}/conf.d" "${def_wkroot}/" > /dev/null
            mkdir -p "${def_wkroot}/storage" > /dev/null
            cp -r "${parent_path}/storage/upload" "${def_wkroot}/storage/upload" > /dev/null
            cp -r "${parent_path}/storage/export" "${def_wkroot}/storage/export" > /dev/null
        fi
    fi

    if [ "${_bkname##*.}" == "gz" ]; then

        # remove extension name .gz
        _bkname="${_bkname%.*}";

        if [ "${_bkname%%.*}" == "${_bkname}" ] || [ "${_bkname##*.}" == "sql" ]; then
            print_warn "Since gzip will not recursively compress a directory, we backup the DATABASE only ..."
            print_info "Compress backup files using GZIP ..."
            cp "${def_wkroot}/$(basename ${def_bkname%%.*}).sql.gz" "${_bkname%%.*}.sql.gz" > /dev/null
        elif [ "${_bkname##*.}" == "tar" ]; then
            print_info "Compress backup files using TAR ..."
            tar -czvf "${_bkname%%.*}.tar.gz" . > /dev/null
        else
            print_warn "Could not find valid file type, compress files by TAR instead ..."
            tar -czvf "${_bkname%%.*}.tar.gz" . > /dev/null
        fi

    elif [ "${ena_bkfile}" == "true" ]; then
        print_warn "Could not find valid file type, compress files by TAR instead ..."
        tar -czvf "${_bkname%%.*}.tar.gz" . > /dev/null
    else
        print_warn "Could not find valid file type ..."
        print_info "Compress backup file (Database only) by GZIP ..."
        cp "${def_wkroot}/$(basename ${def_bkname%%.*}).sql.gz" "${_bkname%%.*}.sql.gz" > /dev/null
    fi

    print_info "Cleanup working directory ${def_wkroot} ...";
    rm -rf "${def_wkroot}";
    exit_success "Backup successfully !!!"

}

function restore_db () {

    local _bkname="$1"
    local _dbname="$2"
    local _dbuser="$3"
    local _dbpass="$4"

    if [ ! -f ${_bkname} ]; then
        exit_fail "the backup file could not be found!!!"
    fi

    print_info "Preparing working directory ${def_wkroot} ...";
    if [ ! -d "${def_wkroot}" ]; then
        mkdir -p "${def_wkroot}";
    else
        rm -rf "${def_wkroot}/*";
    fi

    if [ "${_bkname##*.}" == 'gz' ]; then

        print_info "Extracting Backup file (step.1) ..."
        gzip -dc < "${_bkname}" > "${def_wkroot}/$(basename ${_bkname%.*})"

        # Update directory and filename
        _bkname="${def_wkroot}/$(basename ${_bkname%.*})"

        if { tar -ztf "${_bkname}" || tar -tf "${_bkname}"; } > /dev/null 2>&1; then
            print_info "Extracting Backup file (step.2) ..."
            tar -xvf "${_bkname}" --directory "${def_wkroot}" > /dev/null
            rm -f "${_bkname}" > /dev/null

            if [ ! -z $(find ${def_wkroot} -name '*.sql.gz') ]; then
                _bkname=$(basename $(find ${def_wkroot} -name '*.sql.gz'))
                print_info ${_bkname}
                print_info "${def_wkroot}/$(basename ${_bkname%.*})"
                gzip -dc < $(find ${def_wkroot} -name '*.sql.gz') > "${def_wkroot}/$(basename ${_bkname%.*})"
            fi
        fi

        if [ -z $(find ${def_wkroot} -name '*.sql') ]; then
            exit_fail "Unable to find the SQL dump file ..."
        else
            print_info "SQL dump file find! Restoring Database ..."
            mysql -u${_dbuser} -p${_dbpass} ${_dbname} < "$(find ${def_wkroot} -name '*.sql')";
            print_info "Restore Databaes is Done!"
        fi

    fi

    if [ ${db_prod} == "library" ]; then

        read -p "Do you need to update the wiki server name? <y/N> " prompt
        if [[ $prompt == "y" || $prompt == "Y" || $prompt == "yes" || $prompt == "Yes" ]]; then

			read -p "What is the new server name (with http(s)://):? " sv_updn

            if [ ! -z "${sv_updn}" ]; then
                print_info "update server name in the configuration file (LocalSettings.php) ..."
                sed -i -e 's,'"${sv_name}"','"${sv_updn}"',' ${parent_path}/LocalSettings.php

                if ! grep -q $(echo "$sv_updn" | sed -e 's|^[^/]*//||' -e 's|/.*$||') "/etc/hosts"; then
                    echo "127.0.0.1       $(echo "$sv_updn" | sed -e 's|^[^/]*//||' -e 's|/.*$||')" >> /etc/hosts;
                fi
            fi
        fi

        print_info "Do maintenance after restoring database (Wiki) ..."
		cd ${parent_path}
        php ${parent_path}/maintenance/update.php --quick

    elif  [ ${db_prod} == "budget" ]; then

        print_info "Do maintenance after restoring database (Firefly III) ..."
        rm -rf ${parent_path}/bootstrap/cache/*
        php ${parent_path}/artisan cache:clear
        php ${parent_path}/artisan view:clear
        php ${parent_path}/artisan twig:clean
        php ${parent_path}/artisan view:cache
        php ${parent_path}/artisan firefly:upgrade-database
        php ${parent_path}/artisan firefly:verify

    fi

    print_info "Cleanup working directory ${def_wkroot} ...";
    rm -rf "${def_wkroot}";
    exit_success "Restore successfully !!!"

}


function upgrade () {

    if [ ${db_prod} == "library" ]; then

		print_info "please upgrade the MediaWiki using ansible playbook ..."

	elif  [ ${db_prod} == "budget" ]; then
	
        read -p "Do you want to update the Firefly III  (Budget) ? <y/N> " prompt
        if [[ $prompt == "y" || $prompt == "Y" || $prompt == "yes" || $prompt == "Yes" ]]; then

			print_info "version info ..."
		fi

	elif  [ ${db_prod} == "scholar" ]; then

        read -p "Do you want to update the Moodle (Scholar) ? <y/N> " prompt
        if [[ $prompt == "y" || $prompt == "Y" || $prompt == "yes" || $prompt == "Yes" ]]; then

			print_info "version info ..."
		fi
		
	fi

}

## Main -----------------------------------------------------------------------
## initializing
init

# parsing arguments
# use -gt 0 to consume one or more arguments per pass in the loop (e.g.
# some arguments don't have a corresponding value to go with it such
# as in the --default example).
# arg_optional_
while [ $# -gt 0 ]; do
    _key="$1"
    case "$_key" in
        -b|--backup|--backup=*)
             _val="${_key##--backup=}"
            if [ "${_val}" = "${_key}" ]; then
                if [ $# -lt 2 ]; then
                    _val="${def_bkname}";
                else
                    _val="$2";
                    shift;
                fi
            fi
            backup_db "${_val}" "${db_name}" "${db_user}" "${db_pass}";
            ;;
        -r|--restore|--restore=)
             _val="${_key##--restore=}"
            if [ "${_val}" = "${_key}" ]; then
                if [ $# -lt 2 ]; then
                    _val="${def_bkname}";
                else
                    _val="$2";
                    shift;
                fi
            fi
            check_db "${db_name}" "${db_user}" "${db_pass}";
            restore_db "${_val}" "${db_name}" "${db_user}" "${db_pass}";
            ;;
        -c|--create)
            create_db "${db_name}" "${db_user}" "${db_pass}";
            ;;
        -u|--upgrade|--version=)
             _val="${_key##--restore=}"
            if [ "${_val}" = "${_key}" ]; then
                if [ $# -lt 2 ]; then
                    _val="${def_bkname}";
                else
                    _val="$2";
                    shift;
                fi
            fi
            upgrade;
            ;;
        *)
            show_usage;
            exit 0;
            ;;
    esac
    shift
done