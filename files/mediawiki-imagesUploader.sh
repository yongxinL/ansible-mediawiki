#!/bin/bash
# =============================================================================
#
# - Copyright (C) 2016     George Li <yongxinl@outlook.com>
# - ver: 1.0
#
# - This is part of HomeVault imagebuilder project.
# - this batch will import file (jpg,png,gif) into MediaWiki base on filename
#   filename in format:
#   1.  timestamp-article-category-extrainfo-000xxx.jpg
#   2.  timestamp-photo-landscape-place-city-000xxx.jpg
#   3.  timestamp-phtot-family-place-city-person-person-000xxx.jpg
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
tmp_root="/tmp/tmp_upload"
ext_list="gif|GIF|jpg|JPG|pdf|PDF|png|PNG|mov|MOV|mp4|MP4"
offset=0

# enable debug
debug_mode=${DEBUG:-off};

## Functions -----------------------------------------------------------------
info_block "checking for required libraries." 2> /dev/null ||
    source "${_self_root}/scripts_library.sh";

## Main ----------------------------------------------------------------------
if [ ! -f "${_self_root}/LocalSettings.php" ]; then
    exit_fail "WARNING: Please run this script from MediaWiki root directory!"
fi

# check source directory.
log_info "Checking directory: ${1}..."
if [ -z "${1}" ]; then
    exit_fail "WARNING: Please provide full directory contain media files!"
fi
if [ ! -d "${1}" ]; then
    exit_fail "WARNING: The directory ${1} does not exists!"
fi

if [ ! -f "${_self_root}/maintenance/importImages.php" ]; then
    exit_fail "WARNING: Please put this script into MediaWiki root directory!"
fi

for str_file in "${1}"/*; do
    if [[ ${str_file##*.} =~ ^(${ext_list}) ]]; then
        offset=+
    fi
done

if [ ${offset} == 0 ]; then
    exit_fail "WARNING: The directory ${1} does not contain supported media files!"
fi

# create / cleanup temporary directory
if [ ! -d "${tmp_root}" ]; then
    log_info "Creating temporary uploading directory ..."
    mkdir -p "${tmp_root}"
else
    log_info "Cleanup temporary uploading directory ..."
    rm -f "${tmp_root}/*"
fi

for str_file in ${1}/*; do

    # only work for supported file extension
    if [[ ! ${str_file##*.} =~ ^(${ext_list}) ]]; then
        continue
    fi

    log_info "processing file - ${str_file##*/}"
    touch /var/run/imagesUploader.pid

    # initial variable for v_comment
    str_comment=\'

    # analyzing filename
    IFS='-' read -ra arrayZ <<< ${str_file##*/}

    # arrayZ[0] - date
    if [[ ! ${arrayZ[0]} =~ ^[^0-9]+ ]]; then
        offset=0
        # retrieve year and month
        str_year=$(date --date="${arrayZ[0]}" +'%Y');
        str_date=$(date --date="${arrayZ[0]}" +'%Y0%m');
        str_comment+='[[Category:'${str_year}'/'${str_date}']]'
    else
        offset=1
        # use current year and month
        str_year=$(date +'%Y');
        str_date=$(date +'%Y0%m')
        str_comment+='[[Category:'${str_year}'/'${str_date}']]'
    fi

    log_debug "processing [date]: ${str_comment}"

    # arrayZ[1] - article
    if [[ ${arrayZ[1-${offset}],,} == 'article' ]]; then
        # arrayZ[2] - category

        log_debug "processing [category] in: article ..."
        case ${arrayZ[2-${offset}],,} in
            arc)
                str_comment+='[[Category:Architecture/General]]'
                ;;
            art)
                str_comment+='[[Category:Art/General]]'
                ;;
            bio)
                str_comment+='[[Category:Biography_&_Autobiography/General]]'
                ;;
            occ)
                str_comment+='[[Category:Body_&_Mind_&_Spirit/General]]'
                ;;
            bus)
                str_comment+='[[Category:Business_&_Economics/General]]'
                ;;
            cgn)
                str_comment+='[[Category:Comics_&_Graphic_Novels/General]]'
                ;;
            com)
                case ${arrayZ[3-${offset}],,} in
                    cloud)
                        str_comment+='[[Category:Computers/Cloud_Computing]]'
                        ;;
                    computer)
                        str_comment+='[[Category:Computers/Computer_Science]]'
                        ;;
                    databases)
                        str_comment+='[[Category:Computers/Computers/Databases/General]]'
                        ;;
                    info)
                        str_comment+='[[Category:Computers/Information_Technology]]'
                        ;;
                    linux)
                        str_comment+='[[Category:Computers/Operating_Systems/Linux]]'
                        ;;
                    windows)
                        str_comment+='[[Category:Computers/Operating_Systems/Windows_Server]]'
                        ;;
                    program)
                        str_comment+='[[Category:Computers/Programming/General]]'
                        ;;
                    html)
                        str_comment+='[[Computers/Programming_Languages/HTML]]'
                        ;;
                    php)
                        str_comment+='[[Computers/Programming_Languages/PHP]]'
                        ;;
                    python)
                        str_comment+='[[Computers/Programming_Languages/Python]]'
                        ;;
                    sql)
                        str_comment+='[[Computers/Programming_Languages/SQL]]'
                        ;;
                    xml)
                        str_comment+='[[Computers/Programming_Languages/XML]]'
                        ;;
                    web)
                        str_comment+='[[Computers/Web/General]]'
                        ;;
                    *)
                        str_comment+='[[Category:Computers/General]]'
                        ;;
                esac
                ;;
            ckb)
                str_comment+='[[Category:Cooking/General]]'
                ;;
            cra)
                str_comment+='[[Category:Crafts_&_Hobbies/General]]'
                ;;
            des)
                str_comment+='[[Category:Design/General]]'
                ;;
            edu)
                str_comment+='[[Category:Education/General]]'
                ;;
            fic)
                str_comment+='[[Category:Fiction/General]]'
                ;;
            for)
                str_comment+='[[Category:Foreign_Language_Study/General]]'
                ;;
            hea)
                str_comment+='[[Category:Health_&_Fitness/General]]'
                ;;
            his)
                str_comment+='[[Category:History/General]]'
                ;;
            hom)
                str_comment+='[[Category:House_&_Home/General]]'
                ;;
            hum)
                str_comment+='[[Category:Humor/General]]'
                ;;
            juv)
                str_comment+='[[Category:Juvenile_Fiction/General]]'
                ;;
            mat)
                str_comment+='[[Category:Mathematics/General]]'
                ;;
            med)
                str_comment+='[[Category:Medical/General]]'
                ;;
            mus)
                str_comment+='[[Category:Music/General]]'
                ;;
            nat)
                str_comment+='[[Category:Nature/General]]'
                ;;
            pho)
                str_comment+='[[Category:Photography/General]]'
                ;;
            pol)
                str_comment+='[[Category:Political_Science/General]]'
                ;;
            ref)
                str_comment+='[[Category:Reference/General]]'
                ;;
            sci)
                str_comment+='[[Category:Science/General]]'
                ;;
            soc)
                str_comment+='[[Category:Social_Science/General]]'
                ;;
            spo)
                str_comment+='[[Category:Sports_&_Recreation/General]]'
                ;;
            tec)
                str_comment+='[[Category:Technology_&_Engineering/General]]'
                ;;
            trv)
                str_comment+='[[Category:Travel/General]]'
                ;;
            *)
                str_comment+='[[Category:Photography/Reference]]'
                ;;
        esac
        log_debug "processing category in article: ${str_comment}"

    elif [[ ${arrayZ[1-${offset}],,} == 'photo' ]]; then
        # arrayZ[2] - category
        log_debug "processing [category] in: photo ..."
        case ${arrayZ[2-${offset}],,} in
            event)
                str_comment+='[[Category:Photography/Subjects_&_Themes/Celebrations_&_Events]]'
                ;;
            children)
                str_comment+='[[Category:Photography/Subjects_&_Themes/Children]]'
                ;;
            family)
                str_comment+='[[Category:Photography/Subjects_&_Themes/Family]]'
                ;;
            home)
                str_comment+='[[Category:Photography/Subjects_&_Themes/Family]]'
                ;;
            food)
                str_comment+='[[Category:Photography/Subjects_&_Themes/Food]]'
                ;;
            landscape)
                str_comment+='[[Category:Photography/Subjects_&_Themes/Landscapes]]'
                ;;
            plant)
                str_comment+='[[Category:Photography/Subjects_&_Themes/Plants_&_Animals]]'
                ;;
            animal)
                str_comment+='[[Category:Photography/Subjects_&_Themes/Plants_&_Animals]]'
                ;;
            sport)
                str_comment+='[[Category:Photography/Subjects_&_Themes/Sports]]'
                ;;
            street)
                str_comment+='[[Category:Photography/Subjects_&_Themes/Street_Photography]]'
                ;;
            *)
                str_comment+='[[Category:Photography/Subjects_&_Themes/General]]'
                ;;
        esac
        log_debug "processing category in photo: ${str_comment}"

        # arrayZ[3] - place
        if [[ ${arrayZ[3-${offset}]} =~ ^[^0-9]+ ]] && [ ${arrayZ[3-${offset}],,} != 'city' ]; then
            # uppercase for first characters after _, / remove _ from string / add space before uppercase / remove space in the beginning / replace space with _
            str_place1=$(echo ${arrayZ[3-${offset}]^} | sed -e 's/_./\U&/g' | sed 's/_//g' | sed 's/\([A-Z][^ ]\)/ \1/g' | sed 's/^[ \t]*//g' | sed 's/ /_/g' )
            str_comment+='[['${str_place1}']]'
        fi
        log_debug "processing location [1]: ${str_place1}"

        # arrayZ[4] - place
        if [[ ${arrayZ[4-${offset}]} =~ ^[^0-9]+ ]] && [ ${arrayZ[4-${offset}],,} != 'city' ]; then
            str_place2=$(echo ${arrayZ[4-${offset}]^} | sed -e 's/_./\U&/g' | sed 's/_//g' | sed 's/\([A-Z][^ ]\)/ \1/g' | sed 's/^[ \t]*//g' | sed 's/ /_/g' )
            str_comment+='[['${str_place2}']]'
        fi
        log_debug "processing location [2]: ${str_place2}"

        # arrayZ[3/4] - category
        if [[ "$str_place1" != "" && "$str_place2" != "" ]]; then
            str_comment+='[[Category:'$str_place2'/'$str_place1']]'
        elif [[ "$str_place1" != "" && "$str_place2" == "" ]]; then
            str_comment+='[[Category:'$str_place1']]'
        fi
        log_debug "processing location category: ${str_comment}"

        # arrayZ[5] - family member
        if [[ ${arrayZ[5-${offset}]} =~ ^[^0-9]+ ]]; then
            str_convert=$(echo ${arrayZ[5-${offset}]^} | sed -e 's/_./\U&/g' | sed 's/_//g' | sed 's/\([A-Z][^ ]\)/ \1/g' | sed 's/^[ \t]*//g' | sed 's/ /_/g' )
            str_comment+='[[Category:Family/'${str_convert}']]'
        fi
        log_debug "processing family member: ${str_convert}"

        # arrayZ[6] - family member
        if [[ ${arrayZ[6-${offset}]} =~ ^[^0-9]+ ]]; then
            str_convert=$(echo ${arrayZ[6-${offset}]^} | sed -e 's/_./\U&/g' | sed 's/_//g' | sed 's/\([A-Z][^ ]\)/ \1/g' | sed 's/^[ \t]*//g' | sed 's/ /_/g' )
            str_comment+='[[Category:Family/'${str_convert}']]'
        fi
        log_debug "processing family member: ${str_convert}"

    else
        str_comment+='[[Category:Photography/Reference]]'
    fi

    # end of variable
    str_comment+=\'

    # preparing the import file
    str_dest=$(echo ${str_file##*/} | sed -r "s/([^.]*)\$/\L\1/")
    mv "${1}/${str_file##*/}" "${tmp_root}/${str_dest}" > /dev/null
    php ${_self_root}/maintenance/importImages.php ${tmp_root} --comment=${str_comment} >> /var/log/syslog
    if [ "$?" = "0" ]; then
        rm -f "${tmp_root}/${str_file##*/}"
    else
        mv "${tmp_root}/${str_file##*/}" "${1}"
    fi

    rm /var/run/imagesUploader.pid

done

# Rebuilding Meta information for media files
php ${_self_root}/maintenance/rebuildImages.php > /dev/null
php ${_self_root}/maintenance/rebuildFileCache.php > /dev/null

echo "All files in ${1} have be imported successfully!"