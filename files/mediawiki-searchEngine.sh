#!/bin/bash
# =============================================================================
#
# - Copyright (C) 2016     George Li <yongxinl@outlook.com>
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
searchEngine="localhost"
searchEngine_url="http://${searchEngine}:9200"

# enable debug
debug_mode=${DEBUG:-off};

## Functions -----------------------------------------------------------------
info_block "checking for required libraries." 2> /dev/null ||
    source "${_self_root}/scripts_library.sh";

function do_configure {

    log_warning "Please verify the Elasticsearch version before continue ... "
    log_info " - Mediawiki 1.27 require Elasticsearch 1.x ! "
    log_info " - Mediawiki 1.28 require Elasticsearch 2.x ! "
    log_info " - Mediawiki 1.29 and higher require Elasticsearch 5.x ! "

    read -p "Are you sure you want to continue? <y/N> " prompt
    if [[ $prompt == "y" || $prompt == "Y" || $prompt == "yes" || $prompt == "Yes" ]]; then

        log_debug "[Mediawiki] check if Elasticsearch is running on local host... "
        response=$(curl --write-out %{http_code} --silent --output /dev/null $searchEngine_url)
        if [ ! $response -eq 200 ]; then
            exit_fail "Elasticsearch Server ${searchEngine} is not reachable !!!"
        fi

        log_debug "[Mediawiki] updating Mediawiki configuration file ... "
        sed -i 's/^#require_once\(.*\)/require_once\1/g' ${_self_root}/LocalSettings.php > /devnull
        sed -i 's/^#$wgDisableSearchUpdate\(.*\)/$wgDisableSearchUpdate\1/g' ${_self_root}/LocalSettings.php > /devnull
        sed -i 's/^$wgSearchType\(.*\)/#$wgSearchType\1/g' ${_self_root}/LocalSettings.php > /devnull

        log_debug "[Mediawiki] generating Mediawiki in Elasticsearch Server ... "
        sleep 5
        php ${_self_root}/extensions/CirrusSearch/maintenance/updateSearchIndexConfig.php

        log_debug "[Mediawiki] updating Mediawiki configuration file before bootstrap ... "
        sed -i 's/^$wgDisableSearchUpdate\(.*\)/#$wgDisableSearchUpdate\1/g' ${_self_root}/LocalSettings.php > /devnull

        log_debug "[Mediawiki] bootstrap indexes in Elasticsearch Server ... "
        sleep 5
        php ${_self_root}/extensions/CirrusSearch/maintenance/forceSearchIndex.php --skipLinks --indexOnSkip
        sleep 5
        php ${_self_root}/extensions/CirrusSearch/maintenance/forceSearchIndex.php --skipParse

        log_debug "[Mediawiki] updating Mediawiki configuration file to enable Elasticsearch ... "
        sed -i 's/^#$wgRelatedArticlesUseCirrusSearch\(.*\)/$wgRelatedArticlesUseCirrusSearch\1/g' ${_self_root}/LocalSettings.php
        sed -i 's/^#$wgSearchType\(.*\)/$wgSearchType\1/g' ${_self_root}/LocalSettings.php

        log_success "[Mediawiki] Mediawiki now will use Elasticsearch for searching ... "

    fi
}

function do_reindex() {

    log_debug "[Mediawiki] check if Elasticsearch is running on local host... "
    response=$(curl --write-out %{http_code} --silent --output /dev/null $searchEngine_url)
    if [ ! $response -eq 200 ]; then
        exit_fail "Elasticsearch Server ${searchEngine} is not reachable !!!"
    fi

    log_debug "[Mediawiki] Force index all pages without links ... "
    sleep 5
    php ${_self_root}/extensions/CirrusSearch/maintenance/forceSearchIndex.php --queue --maxJobs 10000 --pauseForJobs 1000 \
    --skipLinks --indexOnSkip --buildChunks 250000

    log_debug "[Mediawiki] Force index links ... "
    sleep 5
    php ${_self_root}/extensions/CirrusSearch/maintenance/forceSearchIndex.php --queue --maxJobs 10000 --pauseForJobs 1000 \
    --skipParse --buildChunks 250000

    log_success "[Mediawiki] process is done ... "
}

## Main ----------------------------------------------------------------------

if [ ! -f "${_self_root}/LocalSettings.php" ]; then
    exit_fail "WARNING: Please run this script from MediaWiki root directory!"
fi

if grep -q "^\$wgSearchType = 'CirrusSearch'" "${_self_root}/LocalSettings.php"; then
    do_reindex;
else
    do_configure;
fi