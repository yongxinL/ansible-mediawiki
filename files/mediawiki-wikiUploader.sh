#!/bin/bash
# =============================================================================
#
# - Copyright (C) 2017     George Li <yongxinl@outlook.com>
#
# - This is part of Family journal Wiki project.
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

## Function Library ----------------------------------------------------------
print_info "*** Checking for required libraries." 2> /dev/null ||
    source "functions.bash";

## Vars ----------------------------------------------------------------------
# declare version
script_version="1.0.5"

# declare Logs, simple or verbose
log_level=simple
log_file=/var/log/mediawiki.log

script_usage="Usage: $0 <directory>
This tools will load the supported media files from <directory>,  and import into MediaWiki 
with specified category and information based on the name of files. and the following media file
can be supported in MediaWiki:
    *${supported_FileType}

The filename in format:
	* timestamp-category-subcategory-author-description-extrainfo-extrainfo-000001.PNG
- timestamp can be optional but the current date will be use.
- category and subcategory will be filled up only when predefined categories be found.
- subcategory can be optional
- unkonwn category will be assign to category:${unknown_category}.
- category will be classified as category/subcategory
- author and description will be classified as article in format [author] and [author/description]
- extrainfo is optional but will be classified as article in format [extrainfo] when provided
"

# define category and keyword, split by : and space between the category
category_level0="arc:Architecture/General \
				art:Art/General \
				bio:Biography_&_Autobiography/General \
				occ:Body_&_Mind_&_Spirit/General \
				bus:Business_&_Economics/General \
				cgn:Comics_&_Graphic_Novels/General \
				com:Computers/General \
				ckb:Cooking/General \
				cra:Crafts_&_Hobbies/General \
				des:Design/General \
				edu:Education/General \
				fic:Fiction/General \
				for:Foreign_Language_Study/General \
				hea:Health_&_Fitness/General \
				his:History/General \
				hom:House_&_Home/General \
				hum:Humor/General \
				juv:Juvenile_Fiction/General \
				mat:Mathematics/General \
				med:Medical/General \
				mus:Music/General \
				nat:Nature/General \
				pho:Photography/General \
				pol:Political_Science/General \
				ref:Reference/General \
				sci:Science/General \
				soc:Social_Science/General \
				spo:Sports_&_Recreation/General \
				tec:Technology_&_Engineering/General \
				trv:Travel/General \
				";
category_level1="Buildings:Architecture/Buildings/General \
				Design:Architecture/Design \
				Interior:Architecture/Interior_Design/General \
				Landscape:Architecture/Landscape \
				Reference:Architecture/Reference \
				Study:Architecture/Study_&_Teaching \
				History:Art/History/General \
				Performance:Art/Performance \
				Reference:Art/Reference \
				Techniques:Art/Techniques/General \
				Adventurers:Biography_&_Autobiography/Adventurers_&_Explorers \
				Business:Biography_&_Autobiography/Business \
				Reference:Biography_&_Autobiography/Reference \
				Reference:Body_&_Mind_&_Spirit/Reference \
				Science:Biography_&_Autobiography/Science_&_Technology \
				Accounting:Business_&_Economics/Accounting/General \
				Budgeting:Business_&_Economics/Budgeting \
				Writing:Business_&_Economics/Business_Writing \
				Finance:Business_&_Economics/Finance/General \
				Forecasting:Business_&_Economics/Forecasting \
				Foreign:Business_&_Economics/Foreign_Exchange \
				Investments:Business_&_Economics/Investments_&_Securities/General \
				Leadership:Business_&_Economics/Leadership \
				Personal:Business_&_Economics/Personal_Finance/General \
				Reference:Business_&_Economics/Reference \
				Statistics:Business_&_Economics/Statistics \
				Training:Business_&_Economics/Training \
				Reference:Comics_&_Graphic_Novels/Reference
				Certification:Computers/Certification_Guides/General \
				Cloud:Computers/Cloud_Computing \
				Engineering:Computers/Computer_Engineering \
				Science:Computers/Computer_Science \
				Data:Computers/Data_Modeling_&_Design \
				Databases:Computers/Databases/General \
				Mining:Computers/Databases/Data_Mining \
				Warehousing:Computers/Databases/Data_Warehousing \
				Desktop:Computers/Desktop_Applications/General \
				Hardware:Computers/Hardware/General \
				History:Computers/History \
				Information:Computers/Information_Technology \
				Networking:Computers/Networking/General \
				Android:Computers/Operating_Systems/Android \
				Linux:Computers/Operating_Systems/Linux \
				Virtualization:Computers/Operating_Systems/Virtualization \
				Server:Computers/Operating_Systems/Windows_Server \
				Programming:Computers/Programming/General \
				HTML:Computers/Programming_Languages/HTML \
				JavaScript:Computers/Programming_Languages/JavaScript \
				PHP:Computers/Programming_Languages/PHP \
				Python:Computers/Programming_Languages/Python \
				SQL:Computers/Programming_Languages/SQL \
				VBScript:Computers/Programming_Languages/VBScript \
				Reference:Computers/Reference \
				Security:Computers/Security/General \
				Web:Computers/Security/Web \
				Reference:Cooking/Reference \
				Reference:Crafts_&_Hobbies/Reference \
				Reference:Design/Reference \
				Early:Education/Early_Childhood \
				Elementary:Education/Elementary \
				Higher:Education/Higher \
				Learning:Education/Learning_Styles \
				Reference:Education/Reference \
				Teaching:Education/Teaching_Methods/General \
				Mathematics:Education/Teaching_Methods/Mathematics \
				Math:Education/Teaching_Methods/Mathematics \
				Reading:Education/Teaching_Methods/Reading_&_Phonics \
				Read:Education/Teaching_Methods/Reading_&_Phonics \
				Science:Education/Teaching_Methods/Science_&_Technology \
				Social:Education/Teaching_Methods/Social_Science \
				Action:Fiction/Action_&_Adventure \
				Biographical:Fiction/Biographical \
				Classics:Fiction/Classics \
				Fantasy:Fiction/Fantasy/General \
				Reference:Fiction/Reference \
				Romance:Fiction/Romance/General \
				Science:Fiction/Science_Fiction/General \
				Chinese:Foreign_Language_Study/Chinese \
				English:Foreign_Language_Study/English \
				Reference:Foreign_Language_Study/Reference \
				Reference:Health_&_Fitness/Reference \
				Reference:History/Reference \
				Reference:House_&_Home/Reference \
				Reference:Humor/Reference \
				Reference:Juvenile_Fiction/Reference \
				Algebra:Mathematics/Algebra/General \
				Geometry:Mathematics/Geometry/General \
				Reference:Mathematics/Reference \
				Acupuncture:Medical/Acupuncture \
				Allied:Medical/Allied_Health_Services/General \
				Emergency:Medical/Allied_Health_Services/Emergency_Medical_Services \
				Records:Medical/Medical_History_&_Records \
				Pharmacy:Medical/Pharmacy \
				Reference:Medical/Reference \
				Lyrics:Music/Lyrics \
				Piano:Music/Musical_Instruments/Piano_&_Keyboard \
				Keyboard:Music/Musical_Instruments/Piano_&_Keyboard \
				Reference:Music/Reference \
				Animals:Nature/Animals/General \
				Birds:Nature/Animals/Birds \
				Fish:Nature/Animals/Fish \
				Wildlife:Nature/Animals/Wildlife \
				Plants:Nature/Plants/General \
				Aquatic:Nature/Plants/Aquatic \
				Flowers:Nature/Plants/Flowers \
				Mushrooms:Nature/Plants/Mushrooms \
				Trees:Nature/Plants/Trees \
				Reference:Nature/Reference \
				Reference:Photography/Reference \
				General:Photography/Subjects_&_Themes/General \
				Aerial:Photography/Subjects_&_Themes/Aerial \
				Architectural:Photography/Subjects_&_Themes/Architectural_&_Industrial \
				Celebration:Photography/Subjects_&_Themes/Celebrations_&_Events \
				Events:Photography/Subjects_&_Themes/Celebrations_&_Events \
				Children:Photography/Subjects_&_Themes/Children \
				Erotica:Photography/Subjects_&_Themes/Erotica \
				Family:Photography/Subjects_&_Themes/Family \
				Home:Photography/Subjects_&_Themes/Family \
				Fashion:Photography/Subjects_&_Themes/Fashion \
				Food:Photography/Subjects_&_Themes/Food \
				Historical:Photography/Subjects_&_Themes/Historical \
				Landscapes:Photography/Subjects_&_Themes/Landscapes \
				Lifestyles:Photography/Subjects_&_Themes/Lifestyles \
				Nudes:Photography/Subjects_&_Themes/Nudes \
				Plants:Photography/Subjects_&_Themes/Plants_&_Animals \
				Animals:Photography/Subjects_&_Themes/Plants_&_Animals \
				Portraits:Photography/Subjects_&_Themes/Portraits_&_Selfies \
				Selfies:Photography/Subjects_&_Themes/Portraits_&_Selfies \
				Regional:Photography/Subjects_&_Themes/Regional \
				Sports:Photography/Subjects_&_Themes/Sports \
				Street:Photography/Subjects_&_Themes/Street_Photography \
				Techniques:Photography/Techniques/General \
				Color:Photography/Techniques/Color \
				Darkroom:Photography/Techniques/Darkroom \
				Digital:Photography/Techniques/Digital \
				Equipment:Photography/Techniques/Equipment \
				Lighting:Photography/Techniques/Lighting \
				Reference:Political_Science/Reference \
				Reference:Reference/Reference \
				System:Reference/System_Media \
				Reference:Science/Reference \
				Reference:Social_Science/Reference \
				Camping:Sports_&_Recreation/Camping \
				Cycling:Sports_&_Recreation/Cycling \
				Fishing:Sports_&_Recreation/Fishing \
				Outdoor:Sports_&_Recreation/Outdoor_Skills \
				Reference:Sports_&_Recreation/Reference \
				Soccer:Sports_&_Recreation/Soccer \
				Automotive:Technology_&_Engineering/Automotive \
				Construction:Technology_&_Engineering/Construction/General \
				Electrical:Technology_&_Engineering/Electrical \
				Engineering:Technology_&_Engineering/Engineering \
				Robotics:Technology_&_Engineering/Robotics \
				Sensors:Technology_&_Engineering/Sensors \
				Reference:Technology_&_Engineering/Reference \
				Asia:Travel/Asia/General \
				China:Travel/Asia/China \
				Japan:Travel/Asia/Japan \
				Australia:Travel/Travel/Australia_&_Oceania \
				Reference:Travel/Reference \
				";
category_unknown="uncategory"

# define supported file type
supported_filetype="gif|jpg|pdf|png|mov|mp4"

# define keyword for position skip
keyword_skipped="xxx|skip"

# working directory
work_dir="/tmp/upload$$"

# pid file
pid_file="/var/run/${script_name}.pid"

## Functions -----------------------------------------------------------------
# return category name
# arc:Architecture/General to Architecture/General
function get_category_name() {
	local name
	name="$(trim $1)"
	echo -n "${name##*:}"
}

# return category keycode
function get_category_keycode() {
	local name
	name="$(trim $1)"
	echo -n "${name%%:*}"
}

# return category root name
# Buildings:Architecture/Buildings/General to Architecture
function get_category_root() {
	local name
	name=$(get_category_name $1)
	echo -n ${name%%/*}
}

# return sub category in given category
function get_subcategory_array() {
	local category_key category subcategory

	category_key="$(get_category_root $1)"

	for category in ${category_level1[@]};
	do
		if [ "$(get_category_root ${category})" == "${category_key}" ]; then
			subcategory=("${subcategory[@]}" "${category}")
		fi
	done
	echo -n "${subcategory[@]}"
}

# return text in specify format
function reformat() {
	local text="$(trim $1)"
	# the text will be convert as
	# 1. caption
	# 2. uppercase the first characters after _
	# 3. remove _ from string
	# 4. add space before uppercase, [sed 's/\([A-Z][^ ]\)/ \1/g'] will result to [DrawAPicture => Draw APicture]
	#    change [sed 's/\([A-Z]\)/ \1/g'] will result to [DrawAPicture => Draw A Picture]
	# 5. remove space in the beginner
	# 6. replace the space with _
	echo $(echo ${text^} | sed -e 's/_./\U&/g' | sed 's/_//g' | sed 's/\([A-Z][^ ]\)/ \1/g' | sed 's/^[ \t]*//g' | sed 's/ /_/g' )
}

# return wiki comment in given filename
function wiki_comment() {
	local file filename category level0 level1 keycode name offset comment
	file="$(get_filename $1)"
	comment=\'
	offset=0

	# analyze file
	IFS='-' read -ra filename <<< "${file}"

	# retrieve date from filename[0]
	if [[ ! ${filename[0]} =~ ^[^0-9]+ ]]; then
		# check if date can be convert
		if date --date="${filename[0]}" +"%Y" > /dev/null; then
			comment+="[[Category:"$(date --date="${filename[0]}" +"%Y")"/"$(date --date="${filename[0]}" +"%Y0%m")"]]"
		else
			comment+="[[Category:"$(date +"%Y")"/"$(date +"%Y0%m")"]]"
		fi
	else
		comment+="[[Category:"$(date +"%Y")"/"$(date +"%Y0%m")"]]"
		filename=("xxxx" "${filename[@]}")
	fi

	# retrieve category and subcategory from filename[1,2]
	for level0 in ${category_level0};
	do
		keycode=$(lowercase $(get_category_keycode ${level0}))
		name=$(lowercase $(get_category_root ${level0}))

		# analyze filename[1] and get root category
		if [ ${filename[1],,} == ${keycode} ] || [ ${filename[1],,} == ${name} ]; then

			# assign to root category
			category=$(get_category_name ${level0})
			# analyze filename[2] and get subcategory
			for level1 in $(get_subcategory_array ${category});
			do
				keycode=$(lowercase $(get_category_keycode ${level1}))

				if [ ${filename[2],,} == ${keycode} ]; then
					category=$(get_category_name ${level1})
				fi
			done
			# update offset when subcategory is not identified
			if [ ${category} == $(get_category_name ${level0}) ]; then
				offset=1
			fi
		fi
	done

	if [ ${#category[@]} -gt 0 ]; then
		comment+="[[Category:"${category}"]]"
	else
		comment+="[[Category:"${category_unknown}"]]"
	fi

	# retrieve author/location from filename[3]
	if [[ ${filename[3-${offset}]} =~ ^[^0-9]+ ]] && [[ ! ${filename[3-${offset}]} =~ ^(${keyword_skipped}) ]]; then
		level0=$(reformat ${filename[3-${offset}]})
		comment+="[["${level0}"]]"
	else
		level0="";
	fi

	# retrieve description/sublocation from filename[4]
	if [[ ${filename[4-${offset}]} =~ ^[^0-9]+ ]] && [[ ! ${filename[4-${offset}]} =~ ^(${keyword_skipped}) ]]; then
		level1=$(reformat ${filename[4-${offset}]})
		if [ ${level0} != "" ]; then
			comment+="[["${level0}"/"${level1}"]]"
		else
			comment+="[["${level1}"]]"
		fi
	fi

	# retrieve additional from the rest
	start=$(( 5 - ${offset} ))
	end=${#filename[@]}

	if [ $end -gt $start ]; then
		for i in $(eval echo "{$start..$end}");
		do
			if [[ ${filename[${i}]} =~ ^[^0-9]+ ]] && [[ ! ${filename[${i}]} =~ ^(${keyword_skipped}) ]]; then
				comment+="[["$(reformat ${filename[${i}]})"]]"
			fi
		done
	fi

	# end of comment
	comment+=\'
	echo -n ${comment}
}

## Main ----------------------------------------------------------------------
media_dir="${1%/}"

if [ -z "$media_dir" ] || [ ! -d "${media_dir}" ]; then
	exit_fail "Please provide directory that contains supported media file! "
fi

if [ ! -f "${script_path}/LocalSettings.php" ] || [ ! -f "${script_path}/maintenance/importImages.php" ]; then
	exit_fail "Please run this script in MediaWiki root directory! "
fi

if [ -f "${pid_file}" ]; then
	exit_fail "Please wait as other user is importing the media files!"
fi

# checking files in given directory
array_files_all=$(find ${media_dir}/ -maxdepth 2 -type f -not -path '*/\.*')
for file in ${array_files_all[@]};
do
	if [[ $(get_filetype ${file,,}) =~ ^(${supported_filetype}) ]]; then
		array_files=("${file}" "${array_files[@]}")
	fi
done

unset array_files_all;

if [ -${#array_files[@]} -eq 0 ]; then
	exit_fail "The directory ${media_dir} does not contains supported file!"
fi

exec_command "*** Creating temporary directory and pid_file ..." \
	mkdir -p "${work_dir}"; \
	touch ${pid_file};

# process the file and upload into mediaWiki.
for file in ${array_files[@]};
do
	exec_command "*** process and upload file $(basename ${file}) ..." \
		cp "${file}" "${work_dir}/$(get_filename ${file}).$(get_filetype ${file,,})"; \
		php ${script_path}/maintenance/importImages.php ${work_dir} --comment=$(wiki_comment ${file}) >> ${log_file};

	if [ $? -ne 0 ]; then
		rm -f ${pid_file}
		exit_fail "error when importing file ${file}!"
	else
		# remove file from both of media and work directory
		rm -f ${file}
		rm -f ${work_dir}/*
	fi
done

# rebuildfileCache.php will use when FileCache option is enable.
# enable read permission for anonymous user and then disable
exec_command "*** rebuild wiki media meta data ..." \
	php ${script_path}/maintenance/rebuildImages.php >> ${log_file}; \
	sed -i -r 's/^\$wgGroup(.*)read/\#$wgGroup\1read/' ${script_path}/LocalSettings.php; \
	php ${script_path}/maintenance/rebuildFileCache.php >> ${log_file}; \
	sed -i -r 's/^#\$wgGroup(.*)read/\$wgGroup\1read/' ${script_path}/LocalSettings.php;

# remove pid_file and work_dir before closing
rm -f ${pid_file}
rm -rf ${work_dir}
exit_success
