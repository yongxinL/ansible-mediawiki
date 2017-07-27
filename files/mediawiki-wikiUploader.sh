#!/bin/bash
# =============================================================================
#
# - Copyright (C) 2017     George Li <yongxinl@outlook.com>
# - ver: 1.1
#
# - This is part of HomeVault imagebuilder project.
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

# define category and keyword, split by : and space between the category
category_Level0="arc:Architecture/General \
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
category_Level1="Buildings:Architecture/Buildings/General \
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
				Children:Music/Genres_&_Styles/Children \
				Classical:Music/Genres_&_Styles/Classical \
				Dance:Music/Genres_&_Styles/Dance \
				Electronic:Music/Genres_&_Styles/Electronic \
				Heavy:Music/Genres_&_Styles/Heavy_Metal \
				Jazz:Music/Genres_&_Styles/Jazz \
				Musicals:Music/Genres_&_Styles/Musicals \
				New:Music/Genres_&_Styles/New_Age \
				Opera:Music/Genres_&_Styles/Opera \
				Pop:Music/Genres_&_Styles/Pop_Vocal \
				Rap:Music/Genres_&_Styles/Rap_&_Hip_Hop \
				Rock:Music/Genres_&_Styles/Rock \
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
supported_FileType="gif|jpg|pdf|png|mov|mp3|mp4"
# define keyword for position skip
keyword_skipped="xxx|skip"
# comment will use when importing file
str_Comment="";
# temporary working directory
sourcedir="";
logfile="/var/log/wikiUploader.log"
workdir="/tmp/upload$$";
pidfile="/var/run/wikiUploader.pid";

_self_root="$( if [ "$( echo "${0%/*}" )" != "$( echo "${0}" )" ] ; then cd "$( echo "${0%/*}" )"; fi; pwd )";
_self_usage="Usage: $0 <directory>
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

## Functions -----------------------------------------------------------------
function get_FileType() {

	local strText="$(remove_whitespace $1)";

	# remove last slash if exist
	strText=${strText##*/};
	# get text after splitter [.]
	 strText=${strText##*.};
	 # return text in lowercase
	echo ${strText,,};
}

function get_FileName() {

	local strText="$(remove_whitespace $1)";

	# remove last slash if exist
	strText=${strText##*/};
	# get text before splitter [.]
	strText=${strText%%.*};
	# return
	echo ${strText};
}

function get_categoryCode() {

	local strText="$(remove_whitespace $1)";

	# get category code
	strText=${strText%%:*};
	# return text in lowercase
	echo ${strText,,};
}

function get_categoryKeyName() {

	local strText="$(remove_whitespace $1)";

	# get category keyword (first name)
	strText=${strText##*:};
	strText=${strText%%/*};
	strText=${strText%%_*};
	# return text in lowercase
	echo ${strText,,};
}

function get_categoryName() {

	local strText="$(remove_whitespace $1)";

	# get category keyword (first name)
	strText=${strText##*:};
	strText=${strText%%/*};
	# return text
	echo ${strText};
}

function get_subCategoryHash() {

	local strCategoryKey="$(remove_whitespace $1)";
	local strText="";
	local arrayT="";

	for strText in ${category_Level1[@]}
	do
		if [[ $(get_categoryName ${strText}) == ${strCategoryKey} ]]; then
			arrayT=("${strText}" "${arrayT[@]}");
		fi
	done

	# return array
	echo "${arrayT[@]}";
}

function remove_whitespace() {

	local strText="$1";

	# remove leading whitespace characters
	strText=${strText#${strText%%[![:space:]]*}};
	# remove trailing whitespace characters
	strText=${strText%${strText##*[![:space:]]}};	
	# return
	echo ${strText}
}

function get_reformat() {

	local strText="$(remove_whitespace $1)";

	# the text will be:
	# 1. caption
	# 2. uppercase the first characters after _
	# 3. remove _ from string
	# 4. add space before uppercase, [sed 's/\([A-Z][^ ]\)/ \1/g'] will result to [DrawAPicture => Draw APicture]
	#    change [sed 's/\([A-Z]\)/ \1/g'] will result to [DrawAPicture => Draw A Picture]
	# 5. remove space in the beginner
	# 6. replace the space with _
	strText=$(echo ${strText^} | sed -e 's/_./\U&/g' | sed 's/_//g' | sed 's/\([A-Z][^ ]\)/ \1/g' | sed 's/^[ \t]*//g' | sed 's/ /_/g' );
	# return text
	echo ${strText};
}

function get_comment() {

	local strFileName="$(get_FileName $1)";
	local strFiletype="$(get_FileType $1)";

	local strCategory="";
	local strComment=\';
	local strLevel0="";
	local strLevel1="";
	local offset=0;

	# check if the media is support type.
	if [[ ${strFiletype} =~ ^(${supported_FileType}) ]]; then

		# analyze FileName
		IFS='-' read -ra arrayX <<< "${strFileName}"

		# analyze date info from arrayX [0]
		if [[ ! ${arrayX[0]} =~ ^[^0-9]+ ]]; then
			# use date from the FileName
			strLevel0=$(date --date="${arrayX[0]}" +'%Y');
			strLevel1=$(date --date="${arrayX[0]}" +'%Y0%m');
			strComment+="[[Category:"${strLevel0}"/"${strLevel1}"]]";
		else
			# use current date as date
			strLevel0=$(date +'%Y');
			strLevel1=$(date +'%Y0%m');
			strComment+="[[Category:"${strLevel0}"/"${strLevel1}"]]";
			# add dummy date into to arrayX[0]
			arrayX=("dummy" "${arrayX[@]}");
		fi

		# analyze category info from arrayX [1,2]
		for strLevel0 in ${category_Level0}
		do

			if [[ ${arrayX[1],,} == $(get_categoryCode ${strLevel0}) || ${arrayX[1],,} == $(get_categoryKeyName ${strLevel0}) ]]; then

				# assign level 0 category
				strCategory=$(get_categoryName ${strLevel0});

				# analyze 2nd level of category with arrayX [2]
				for strLevel1 in $(get_subCategoryHash ${strCategory})
				do
					if [[ ${arrayX[2],,} == $(get_categoryCode ${strLevel1}) ]]; then
						strCategory=${strLevel1##*:};
					fi
				done

				# check if category has be set to subcategory
				if [[ ${strCategory} == $(get_categoryName ${strLevel0}) ]]; then
					offset=1;
				fi
			fi
		done

		# assign category
		if [[ ${strCategory} != "" ]]; then
			strComment+="[[Category:"${strCategory}"]]";
		else
			strComment+="[[Category:"${category_unknown}"]]";
			offset=2;
		fi

		# analyze author/location info from arrayX [3]
		if [[ ${arrayX[3-${offset}]} =~ ^[^0-9]+ ]] && [[ ! ${arrayX[3-${offset}]} =~ ^(${keyword_skipped}) ]]; then
			strLevel0=$(get_reformat ${arrayX[3-${offset}]});
			strComment+="[["${strLevel0}"]]";
		else
			strLevel0="";
		fi

		# analyze description/sublocation info from arrayX [4]
		if [[ ${arrayX[4-${offset}]} =~ ^[^0-9]+ ]] && [[ ! ${arrayX[4-${offset}]} =~ ^(${keyword_skipped}) ]]; then
			strLevel1=$(get_reformat ${arrayX[4-${offset}]});

			if [[ ${strLevel0} != "" ]]; then
				strComment+="[["${strLevel0}"/"${strLevel1}"]]";
			else
				strComment+="[["${strLevel1}"]]";
			fi
		fi

		# analyze extra info from arrayX [5-end]
		int_start=$(expr 5 - ${offset});
		int_end=${#arrayX[@]};

		if [ ${int_end} -gt ${int_start} ]; then
			for iCount in $(eval echo "{$int_start..$int_end}");
			do
				if [[ ${arrayX[${iCount}]} =~ ^[^0-9]+ ]] && [[ ! ${arrayX[${iCount}]} =~ ^(${keyword_skipped}) ]]; then
					#strLevel0=$(get_reformat ${arrayX[${iCount}]});
					strComment+="[["$(get_reformat ${arrayX[${iCount}]})"]]";
				fi
			done
		fi
	else
		echo "${1} will skipped due to unsupported media type!"
	fi

	# end of comment
	strComment+=\';
	# return comment
	echo ${strComment}
}

## Main ----------------------------------------------------------------------
# directory check and script usage
if [[ -z "${1}" ]] || [[ ! -d "${1}" ]]; then
	echo "WARNING: please provide full directory name that contains media files!"
	echo ""
	echo "${_self_usage}";
	exit 0
fi

# environment check
if [[ ! -f "${_self_root}/LocalSettings.php" ]] || [[ ! -f "${_self_root}/maintenance/importImages.php" ]]; then
	echo "WARNING: Please put this script in root of MediaWiki directory!";
	exit 0;
fi
if [[ -f "${pidfile}" ]]; then
	echo "WARNING: it's running by other user, please check the process or delete the ${pidfile} file!";
	exit 0;
fi

# media file check
sourcedir="${1%/}"
arrayP=$(find ${sourcedir}/ -maxdepth 2 -type f -not -path '*/\.*')

for str_File in ${arrayP[@]};
do
	if [[ $(get_FileType ${str_File}) =~ ^(${supported_FileType}) ]]; then
		arrayF=("${str_File}" "${arrayF[@]}");
	fi
done

# release arrayP
unset arrayP;

if [[ -z ${arrayF} ]]; then
	echo "WARNING: the directory ${1} does not contain supported media files!"
	echo ""
	echo "${_self_usage}";
	exit 0
fi

# create temporary directory and pidfile
mkdir -p "${workdir}";
touch "${pidfile}";
if [ ! -f "${logfile}" ]; then
	touch "${logfile}"
fi

# processing media file in directory
for str_File in ${arrayF[@]};
do
	echo -n "[$(date +"%Y-%m-%d %H:%M:%S %Z")] Starting process file: $(get_FileName ${str_File}).$(get_FileType ${str_File}) ... "

	# copy file to $workdir with lowercase of file extension
	cp "${str_File}" "${workdir}/$(get_FileName ${str_File}).$(get_FileType ${str_File})"
	# retrive the file comment
	str_Comment=$(get_comment ${str_File})
	# output debug information
	echo "[$(date +"%Y-%m-%d %H:%M:%S %Z")] processing file:-${str_File}" >> ${logfile};
	echo "                           description:${str_Comment}" >> ${logfile};
	# use wiki command to load file
	php ${_self_root}/maintenance/importImages.php ${workdir} --comment=${str_Comment} >> ${logfile};
	# verify command result
	if [ $? -ne 0 ]; then
		echo "failed";
		echo "WARNING: error when loading file ${str_File}";
		rm -f ${pidfile};
		exit $?
	else
		# remove file from sourcedir and clear up the workdir
		rm -f "${str_File}";
		rm -f ${workdir}/*;
		echo "OK"
	fi
done

# remove pidfile and workdir once the script is finish
rm -f ${pidfile};
rm -rf ${workdir};

# rebuild wiki meta information
php ${_self_root}/maintenance/rebuildImages.php >> ${logfile};

# uncommit below if wiki FileCache is enabled
php ${_self_root}/maintenance/rebuildFileCache.php >> ${logfile};

echo "All files in ${sourcedir} have be imported successfully!"