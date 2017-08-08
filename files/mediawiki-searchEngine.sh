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
log_level=simple
log_file=/var/log/mediawiki.log

script_usage="Usage: $0"
es_engine_host="localhost"
es_engine_url="http://${es_engine_host}:9200"

## Functions -----------------------------------------------------------------
function do_configure {

    print_info "Please verify the Elasticsearch version before continue ... 
        - Mediawiki 1.27 require Elasticsearch 1.x !
        - Mediawiki 1.28 require Elasticsearch 2.x !
        - Mediawiki 1.29 and higher require Elasticsearch 5.x !"

    read -p "Are you sure you want to continue? <y/N> " prompt
    if [[ $prompt == "y" || $prompt == "Y" || $prompt == "yes" || $prompt == "Yes" ]]; then

        print_info "*** check if Search Engine is running on ${es_engine_host} ... "
        response=$(curl --write-out %{http_code} --silent --output /dev/null $es_engine_url)
        if [ ! $response -eq 200 ]; then
            exit_fail "Elasticsearch Server ${es_engine_host} is not reachable !!!"
        fi

        exec_command "*** updating Wiki configuration file ... " \
            sed -i 's/^#require_once\(.*\)/require_once\1/g' ${script_path}/LocalSettings.php; \
            sed -i 's/^#$wgDisableSearchUpdate\(.*\)/$wgDisableSearchUpdate\1/g' ${script_path}/LocalSettings.php; \
            sed -i 's/^$wgSearchType\(.*\)/#$wgSearchType\1/g' ${script_path}/LocalSettings.php;

        sleep 3
        exec_command "*** generating wiki indexes in the Search Engine ..." \
            php ${script_path}/extensions/CirrusSearch/maintenance/updateSearchIndexConfig.php >> ${log_file};

        sleep 3
        exec_command "*** updating Wiki configuration file before bootstrap ... " \
            sed -i 's/^$wgDisableSearchUpdate\(.*\)/#$wgDisableSearchUpdate\1/g' ${script_path}/LocalSettings.php

        sleep 3
        exec_command "*** bootstrap indexes in the Search Engine ..." \
            php ${script_path}/extensions/CirrusSearch/maintenance/forceSearchIndex.php --skipLinks --indexOnSkip >> ${log_file}; \
            php ${script_path}/extensions/CirrusSearch/maintenance/forceSearchIndex.php --skipParse >> ${log_file};

        sleep 3
        exec_command "*** updating Wiki configurate file to enable Search Engine ..." \
            sed -i 's/^#$wgRelatedArticlesUseCirrusSearch\(.*\)/$wgRelatedArticlesUseCirrusSearch\1/g' ${script_path}/LocalSettings.php; \
            sed -i 's/^#$wgSearchType\(.*\)/$wgSearchType\1/g' ${script_path}/LocalSettings.php;

        print_info "Wiki has be configured and now will use Elasticsearch as search engine ... "
    fi
}

function do_reindex() {

    print_log "*** check if Search Engine is running on ${es_engine_host} ... "
    response=$(curl --write-out %{http_code} --silent --output /dev/null $es_engine_url)
    if [ ! $response -eq 200 ]; then
        exit_fail "Elasticsearch Server ${es_engine_host} is not reachable !!!"
    fi

    sleep 3
    exec_command "*** Force index all pages without links ..." \
        php ${script_path}/extensions/CirrusSearch/maintenance/forceSearchIndex.php --queue --maxJobs 10000 --pauseForJobs 1000 --skipLinks --indexOnSkip --buildChunks 250000 >> ${log_file};

    sleep 3
    exec_command "*** Force index all pages without links ..." \
    php ${script_path}/extensions/CirrusSearch/maintenance/forceSearchIndex.php --queue --maxJobs 10000 --pauseForJobs 1000 --skipParse --buildChunks 250000 >> ${log_file};

    print_info "Wiki have be reindexed ... "
}

## Main ----------------------------------------------------------------------
if [ ! -f "${script_path}/LocalSettings.php" ]; then
    exit_fail "Please run this script in MediaWiki root directory! "
fi

if grep -q "^\$wgSearchType = 'CirrusSearch'" "${script_path}/LocalSettings.php"; then
    do_reindex;
else
    do_configure;
fi