#!/bin/bash
# =============================================================================
# - bash function Library
# 
# - Copyright (C) 2017 George Li <yongxinl@outlook.com>
#
# - Author: George Li (yongxinL@outlook.com)
# - http://github.com/yongxinL/docker
# - This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
# =============================================================================

## Shell Opts ----------------------------------------------------------------
set -e

## Vars ----------------------------------------------------------------------
# declare version
lib_version="1.0.5"

# reload script with bash
if [ ! -n "${BASH_VERSION}" ]; then
	if [ ! -f "/bin/bash" ]; then

		# determine the distribution and install bash
		source /etc/os-release 2> /dev/null
		if [ "${ID}" == "alpine" ]; then
			printf "\e[1;34m%s %s%s\e[0m\n" "$(date -u +"%Y-%m-%d %T")" "[INFO]" "*** Installing base shell packages ..."
			apk add --no-cache bash >> /dev/null
		fi
	fi
	# reload script with bash
	printf "\e[1;33m%s %s%s\e[0m\n" "$(date -u +"%Y-%m-%d %T")" "[INFO}" "*** Reload ${script_name} with bash shell ..."
	/bin/bash ${0} && exit
fi

## Functions -----------------------------------------------------------------
# this function will load all the variables defined here.
# they might be overridden by the scripts.
function init_variables() {

	# export known paths
	export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${PATH}"

	# export Language and perform unattended installation of a Debian package
	export LANG=C.UTF-8
	export LC_ALL=C
	export DEBIAN_FRONTEND=noninteractive

	# declare Logs, simple or verbose
	log_level="${log_level:-simple}"
	log_file="${log_file:-/var/log/${script_name%%.*}.log}"

	# declare script name
	script_name="${script_name:-$(basename $0)}"
	script_path="$( if [ "$( echo "${0%/*}" )" != "$( echo "${0}" )" ] ; then cd "$( echo "${0%/*}" )"; fi; pwd )"

	# start time in order to calculate total running time.
	__libs_start_time="${start_time:-$(date +%s)}"

	# declare commonly colors
	__lib_color_red="\e[1;31m"
	__lib_color_green="\e[1;32m"
	__lib_color_yellow="\e[1;33m"
	__lib_color_blue="\e[1;34m"
	__lib_color_magenta="\e[1;35m"
	__lib_color_cyan="\e[1;36m"
	__lib_color_standard="\e[0m"

	# declare message colors
	__lib_color_failure="${__lib_color_red}"
	__lib_color_info="${__lib_color_blue}"
	__lib_color_normal="${__lib_color_standard}"
	__lib_color_success="${__lib_color_green}"
	__lib_color_warning="${__lib_color_yellow}"
	__lib_max_column_line="${COLUMNS:-120}"
	__lib_move_column_end="echo -en \\033[$(( ${__lib_max_column_line} - 6 ))G"

	# declare date, use date -u to get UTC timestamp
	__lib_format_date_full="%a, %d %b %Y %H:%M:%S %Z"
	__lib_format_date_short="%Y-%m-%d %T"
	__lib_format_timestamp="%Y-%m-%dT%T.%3N%Z"

	# determine the distribution
	__lib_determine_distro

	case ${__lib_distro_id} in
		centos|rhel|fedora)
			package_cmd_delete="yum install "
			package_cmd_install="yum remove "
			package_cmd_query="rpm -qa "
			;;
		ubuntu|debian)
			package_cmd_delete="apt-get remove "
			package_cmd_install="apt-get install "
			package_cmd_query="dpkg -l "
			package_cmd_update="apt-get update "
			package_cmd_upgrade="apt-get upgrade "
			;;
		alpine)
			package_cmd_delete="apk del --no-cache "
			package_cmd_install="apk add --no-cache "
			package_cmd_query="apk info "
			package_repository="http://dl-4.alpinelinux.org/alpine/edge/community"
			package_repository_file="/etc/apk/repositories"
			package_cmd_update="apk update "
			package_cmd_upgrade="apk upgrade "
			;;
	esac
}
# determine the distribution we are running on, so we can
# configure it appropriately
function __lib_determine_distro() {
	source /etc/os-release 2>/dev/null
	__lib_distro_id="${ID}"
	__lib_distro_name="${NAME}"
	__lib_distro_version_id="${VERSION_ID}"
}

# update repository and upgrade Linux distribution
function update_repository() {
	# update repository file
	if [ ! -z "${package_repository}" ] && [ ! -z "${package_repository_file}" ]; then
		echo "${package_repository}" >> "${package_repository_file}"
	fi
	exec_command "*** Updating Linux repository ..." \
		${package_cmd_update};
	exec_command "*** Upgrading Linux Distribution ..." \
		${package_cmd_upgrade};
	return 0
}

## text processing utilities ------------------------
# return the lowercase string
function lowercase() {
	args_or_stdin "$@" | tr 'A-Z' 'a-z';
}

# return the uppercase string
function uppercase() {
	args_or_stdin "$@" | tr 'a-z' 'A-Z';
}

# trim left-side blanks from string
function ltrim() {
	args_or_stdin "$@" | sed -Ee 's/^[[:space:]]*//';
	# or use variable
	#var="${var#"${var%%[![:space:]]*}"}"   # remove leading whitespace characters
}

# trim right-side blanks from string
function rtrim() {
	args_or_stdin "$@" | sed -Ee 's/[[:space:]]*$//';
	# or use variable
	#var="${var%"${var##*[![:space:]]}"}"   # remove trailing whitespace characters
}

# trim blanks surrounding string
function trim() {
	args_or_stdin "$@" | sed -Ee 's/^[[:space:]]*//' -e 's/[[:space:]]*$//';
}

# squeeze multiple blanks in string
function squeeze() {
	args_or_stdin "$@" | tr '\t' ' ' | tr -s ' '
}

## argument utilities -------------------------------------------
# return the given arguments, or read & return stdin until EOF
function args_or_stdin() {
	__lib_args_or_stdin "$@"
}
function __lib_args_or_stdin() {
	if [[ $# -gt 0 ]]; then
		echo "$*"
	else
		cat
	fi
}

## filename utilities -------------------------------------------
# return the given full filename.
function __lib_filename() {
	echo -n $(basename "$1")
}
# return the given filename
function get_filename() {
	local filename
	filename=$(__lib_filename $1)
	echo -n ${filename%%.*}
}
# return the given file extension
function get_filetype() {
	local filename
	filename=$(__lib_filename $1)
	echo -n ${filename##*.}
}

## info and log utilities ----------------------------------------
# display a info message
function print_info() {
	printf "${__lib_color_info}%s:%s${__lib_color_normal}\n"  "[${2:-INFO}]" "${1}"
}
# display a success message
function print_succ() {
	printf "${__lib_color_success}%s:%s${__lib_color_normal}\n"  "[${2:-INFO}]" "${1}"
}
# display a warn message
function print_warn() {
	printf "${__lib_color_warning}%s:%s${__lib_color_normal}\n"  "[${2:-WARN}]" "${1}"
}
# display a fail message
function print_fail() {
	printf "${__lib_color_failure}%s:%s${__lib_color_normal}\n"  "[${2:-FAIL}]" "${1}"
}

# function to print log to the screen
function print_log() {
	if [ ${#1} -gt 60 ]; then
		printf "${__lib_color_info}%s %s-%s:%s${__lib_color_normal}"  "$(date -u +"${__lib_format_date_short}")" "$(get_filename ${script_name})"  "[INFO]"  "${1:0:60}..."
	else
		printf "${__lib_color_info}%s %s-%s:%s${__lib_color_normal}"  "$(date -u +"${__lib_format_date_short}")" "$(get_filename ${script_name})"  "[INFO]"  "${1}"
	fi
}
# function to write log to the screen or file
function write_log() {
	if [ ! -f "${log_file}" ]; then
		# create Log file if not exist
		mkdir -p ${log_file%/*}
		touch ${log_file}
	fi

	# open a new line
	echo >> ${log_file}

	if [ "${log_level}" == "verbose" ]; then
		# output to both of console and Log file
		while IFS= read -r line;
		do
			printf "%s-%s:%s\n" "$(date -u +"${__lib_format_timestamp}")" "$(get_filename ${script_name}) [DEBG]" "${line}" 2>&1 |  tee -a ${log_file}
		done
	else
		# output process to the Log file
		while IFS= read -r line;
		do
			printf "%s-%s:%s\n" "$(date -u +"${__lib_format_timestamp}")" "$(get_filename ${script_name}) [DEBG]" "${line}" >> ${log_file}
		done
	fi
}

# log that something successed
function success() {
	local res=$?
	[ "${log_level}" != "verbose" ] && __lib_echo_message success
	return $res
}
# log that something failed
function failure() {
	local res=$?
	[ "${log_level}" != "verbose" ] && __lib_echo_message failed
	return $res
}
# log that something passed, but may had errors
function passed() {
	local res=$?
	[ "${log_level}" != "verbose" ] && __lib_echo_message passed
	return $res
}
# log that something warning
function warning() {
	local res=$?
	[ "${log_level}" != "verbose" ] && __lib_echo_message warning
	return $res
}
# exit success
function exit_success() {
	set +x
	__lib_exit_state 0
}
# exit failure
function exit_fail() {
	set +x
	print_fail "$@" "FAILURE"
	__lib_exit_state 1
}

# display status message at the end of line
function __lib_echo_message() {
	local status color res

	case $(trim $1) in
		FAILURE | failure | FAILED | failed | ERROR | error )
			status="FAIL"
			color="${__lib_color_failure}"
			res=1
			;;
		INFO | info | NOTICE | notice )
			status=" OK "
			color="${__lib_color_info}"
			res=0
			;;
		PASSED | passed | PASS | pass )
			status="PASS"
			color="${__lib_color_success}"
			res=0
			;;
		SUCCESS | success | SUCC | succ )
			status=" OK "
			color="${__lib_color_success}"
			res=0
			;;
		WARNING | warning | WARN | warn )
			status="WARN"
			color="${__lib_color_warning}"
			res=1
			;;
		* )
			status="PASS"
			color="${__lib_color_info}"
			res=0
			;;
	esac

	# move cursor
	$__lib_move_column_end
	echo -n "["
	echo -en "${color}"
	echo -n "${status}"
	echo -en "${__lib_color_normal}"
	echo -n "]"
	echo -ne "\r"
	return $res
}

# display exit state and information
function __lib_exit_state() {
	local run_total
	run_total=$(( $(date +%s) - ${__libs_start_time} ))
	if [ ${run_total} -ge 60 ]; then
		print_info "Run time = ${run_total} seconds || $(( ${run_total} / 60 )) minutes!"
	else
		print_info "run time = ${run_total} seconds!"
	fi

	if [ ${1} == 0 ]; then
		print_succ "status: SUCCESS"
	else
		print_info "status: FAILURE"
	fi
	exit ${1}
}

## command utilities ----------------------------------------------
# execute some commands, and log its output
# exec_command "message" command; command;
# todo: command is not work when quotation and ; exist
function exec_command() {
	local message

	message=$1
	if [ "$message" != "NA" ] && [ "$message" != "none" ]; then
		print_log "$message"
	fi
	shift

	local prompt_command_array
	IFS=';' read -ra prompt_command_array <<< "$@"

	# reset IFS
	unset IFS

	local command trimmed_command
	for command in "${prompt_command_array[@]}";
	do
		trimmed_command="${command//&&/}"	# remove character &&
		trimmed_command=$(trim "${trimmed_command}")	# remove space

		# only execute the command if it actually exists
		if type -t $(__lib_invoke_command "${command}") 1>/dev/null; then
			${command} 2>&1 | write_log && success $"$message" || failure $"$message"
			res=$?
		fi
	done
	echo
	return $res
}
# return invoke command name, normally the first word in the command
function __lib_invoke_command() {
	local var=$@
	var=${var%% *}
	var=$(trim ${var})
	echo -n "$var"
}

## Pre-flight check ----------------------------------------------------------
# make sure only root can run our script
if [ "$(id -u)" != "0" ]; then
	exit_fail "This script must be run as root"
fi

## Signal traps --------------------------------------------------------------
# Trap all death signals and errors
trap "exit_fail ${LINENO} $? 'Received STOP Signal'" SIGHUP SIGINT SIGTERM
if [ "${__lib_distro_id}" != "alpine" ]; then
	trap "exit_fail ${LINENO} $?" ERR
fi

## Main ----------------------------------------------------------------------
# initialize global variables
init_variables
