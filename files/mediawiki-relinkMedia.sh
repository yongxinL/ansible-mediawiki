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
# - author George Li <yongxinL@outlook.com>
# - version 1.0.0
# - updated 2021.10.21
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
script_version="1.0.0"

# declare Logs, simple or verbose
log_file=/var/log/maintMediaDir.log

# declare shared (target) storages
shared_root="/website"

# declare directories need to link to shared storage
relink_dirs="/var/lib/w/wiklibrary \
"

## Functions -----------------------------------------------------------------
# create / rebuild symbolic links
function create_link() {
   local str_source="$(trim $1)"
   local str_target="$2"

   if [ ! -z ${str_source} ] && [ -z ${str_target} ]; then
      # generate target location if not provided
      str_target=${shared_root}/$(basename ${str_source})
   fi

   # remove if source exists but it's file
   [ -f ${str_source} ] && rm -f ${str_source}

   # check if source exist but not symbolic link
   if [ -d ${str_source} ] && [ ! -L ${str_source} ] && [ ! -d ${str_target} ]; then
      mkdir -p ${str_target}
      rsync -a ${str_source}/ ${str_target}
      rm -rf ${str_source}
   elif [ -d ${str_source} ] && [ ! -L ${str_source} ] && [ -d ${str_target} ]; then
      rsync -a ${str_source}/ ${str_target}
      rm -rf ${str_source}
   elif [ ! -L ${str_source} ] && [ ! -d ${str_target} ]; then
      mkdir -p ${str_target}
   fi
   if [ ! -L ${str_source} ]; then
      ln -s ${str_target} ${str_source}
      echo "Directory $(basename ${str_source}) point to $(readlink -f ${str_source})" >> ${log_file};
   fi

}

## Main ----------------------------------------------------------------------
for source in ${relink_dirs};
do
   exec_command "*** creating symbolic link for $(basename ${source}) ..." \
      $(create_link ${source});

done
