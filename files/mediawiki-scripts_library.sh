#!/bin/sh
# =============================================================================
#
# - Copyright (C) 2017     George Li <yongxinl@outlook.com>
#
# - This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
# =============================================================================

## Vars ----------------------------------------------------------------------
services_init_root=/etc/services.d;
package_install_command="apk add --no-cache"

vLine='----------------------------------------------------------------------';
vStart="${vStart:-$(date +%s)}";
_color_red=$'\e[1;31m'
_color_grn=$'\e[1;32m'
_color_yel=$'\e[1;33m'
_color_blu=$'\e[1;34m'
_color_mag=$'\e[1;35m'
_color_cyn=$'\e[1;36m'
_color_std=$'\e[0m'

## Functions -----------------------------------------------------------------
#
# output exit state information
#
function exit_state {
    set +x
    v_Total="$(( $(date +%s) - vStart ))";
    if [ ${v_Total} -ge 60 ]; then
        info_block "Run time = ${v_Total} seconds || $(${v_Total} / 60 )) minutes!"
    else
        info_block "Run time = ${v_Total} seconds!"
    fi
    if [ "${1}" == 0 ]; then
        info_block "Status: Success"
    else
        info_block "Status: Failure"
    fi
    exit ${1}
}
#
# exit success
#
function exit_success {
    set +x
    exit_state 0
}
#
# exit failure
#
function exit_fail {
    set +x
    info_block "Error info - $@";
    exit_state 1
}
#
# print information
#
function print_info {
    PROC_NAME="- [ $@ ] -"
    printf "\n${_color_mag}%s%s${_color_std}\n" "$PROC_NAME" "${vLine:${#PROC_NAME}}";
}
#
# print block information
#
function info_block {
    echo "${vLine}";
    print_info "$@";
    echo "${vLine}";
}
#
# print log information
#
#
function print_log () {
    local _text="$1";
    local _level="$2";
    local _color="$3";

    [ -z ${_level} ] && _level="INFO";
    [ -z ${_color} ] && _color="${_color_yel}";

    printf "${_color}%s%s%s${_color_std}\n" "[$(date +"%Y-%m-%d %H:%M:%S %Z")]"   "[${_level}]"   "${_text}"
}
#
# info log message
#
function log_info () {
    print_log "$1";
}
#
# success log message
#
function log_success () {
    print_log "$1" "SUCS" "${_color_grn}";
}
#
# error log message
#
function log_error () {
    print_log "$1" "ERR" "${_color_red}";
}
#
# warning log message
#
function log_warning () {
    print_log "$1" "WARN" "${_color_yel}";
}
#
# debug log message
#
function log_debug () {
    if [ ${debug_mode} == "on" ]; then
        print_log "$1" "DEBG" "${_color_blu}";
    fi
}
## Signal traps --------------------------------------------------------------
# Trap all Death Signals and Errors
trap "exit_fail ${LINENO} $? 'Received STOP Signal'" SIGHUP SIGINT SIGTERM

## Pre-flight check ----------------------------------------------------------
# Make sure only root can run our script
if [ "$(id -u)" != "0" ]; then
    info_block "This script must be run as root";
    exit_state 1;
fi

## Exports -------------------------------------------------------------------
# Export known paths
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${PATH}"

# Export Language and perform unattended installation of a Debian package
export LANG=C.UTF-8
export LC_ALL=C
export DEBIAN_FRONTEND=${DEBIAN_FRONTEND:-"noninteractive"}

# ServicesVariables
