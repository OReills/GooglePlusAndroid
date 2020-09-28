#bin/bash
###################################################
##Google Plus Android  Evidence Collection Script##
###################################################
#Arguments Required for running script:
# input file, report file, keyword file is optional
###################################################
#Cormac O'Reilly
###################################################
#Exit Codes:
#	0: Success
#	1: Arguments not provided
#	2: Input file does not exist
#	3: Do not create output file
#	4: Keyword file is not readable
#	5: Keyword file has zero bytes
#	6: Quit Menu
#	7: Keyword has not been found in this database
#	8: Keywords in file have not been found in this database
###################################################
# This script is used in investigations to find relevant information on a Google+ Android Application.
# Google+ stores the majority of its relevant data in a SQLite database called es0.db
# This script can be used to extract the relevant information that may be required in the course of an investigation
# There is also a facility for searching using a keyword search and a keyword file for your case of interest 
###################################################
if [ -z $2 ]
then
		echo "Two (2) arguments must be provided, third argument is (keyword) is optional:"
		echo "1st argument: input file"
		echo "2nd argument: output file"
		echo "3rd argument: keyword.txt"
		exit 1
fi
INPUTFILE=$1
OUTPUTFILE=$2
KEYWORD=$3

if [ ! -e ${INPUTFILE} ] #exit if database file not selected
then
	echo "${INPUTFILE} does not exist, please check your input file and try again"
	exit 2
fi

if [ ! -f ${OUTPUTFILE} ]
then
		touch ${OUTPUTFILE}	 # create our new report file 
		echo "============================================"
		echo "New file called ${OUTPUTFILE} created"
		echo "============================================"
		else 
		echo "Report File Already exists ${OUTPUTFILE}," # if a file with that name already exists i will create a new file with todays date appended
		echo -n "Should we create a new file with todays date [y/n]"
		read YESNO
			if [[ "${YESNO}" =~ ^([yY][eE][sS]|[yY])$ ]] #allow for all versions of "Yes"
			then
					OUTPUTFILE=${OUTPUTFILE}_$(date '+%Y-%m-%d')
					touch ${OUTPUTFILE}
					echo "============================================"
					echo "New File Created called ${OUTPUTFILE}"
					echo "============================================"
			else
			exit 3
			fi
fi
if [ ! -r ${KEYWORD} ] #if Keyword file supplied is not readable
then
	echo "${KEYWORD} is not readable"
	exit 4
fi
 
if [ ! -s ${KEYWORD} ] #if Keyword file contains no data
then
	echo "${KEYWORD} does not contain any data"
	exit 5
fi

echo "==================================================" > ${OUTPUTFILE} # start creating our Output file
echo "GOOGLE+ ANDROID APPLICATION FORENSIC INVESTIGATION" >> ${OUTPUTFILE}
echo "==================================================" >> ${OUTPUTFILE}
#General information on who is running the investigation, their PC and the date report ran are printed to the report file
hostname=$(hostname)
echo "Host PC: $hostname" >> ${OUTPUTFILE}
date=$(date -R)
echo "Date Generated: $date" >> ${OUTPUTFILE}
user=$(whoami)
echo "Created by: $user" >> ${OUTPUTFILE}
echo "Database being Queried: ${INPUTFILE}"  >> ${OUTPUTFILE}
echo "Name of Report file: ${OUTPUTFILE}" >> ${OUTPUTFILE}
echo "===========================" >> ${OUTPUTFILE}

echo "Would you like to perform general analysis or specific keyword analysis?"
#Select and case command to choose General Analysis of Google+ or something more targeted
select option in "General Analysis" "Keyword Search" "Keyword File Search" "Quit" ; 
do
case $REPLY in
#general analysis 
1)  
#locale of the suspect
suspectlocale=$(sqlite3 ${INPUTFILE} 'SELECT * FROM android_metadata')
echo
echo "Suspect Locale" >> ${OUTPUTFILE}
echo "---------------------------" >> ${OUTPUTFILE}
echo "This suspect Locale setting is:" >> ${OUTPUTFILE}
echo "$suspectlocale" >> ${OUTPUTFILE} 
echo "This can indicate the language that the suspect may converse in and may give us and indicataion of the geographic location of our target." >>${OUTPUTFILE}
echo "===========================" >> ${OUTPUTFILE}
#contacts - this query pulls all of the contacts in the google+ database
contacts=$(sqlite3 ${INPUTFILE} '.headers on' 'SELECT * FROM contacts' | awk -F "|"  '{ print $4"\t""\t"$10 }')
echo "Contacts" >> ${OUTPUTFILE}
echo "---------------------------" >> ${OUTPUTFILE}
echo "A list of all contacts in the user's circles (name,circlesin)." >> ${OUTPUTFILE}
echo "${contacts} " >> ${OUTPUTFILE}
echo 
#cirlces - this query pulls the details of the circles that the suspect has created
circles=$(sqlite3 ${INPUTFILE} '.headers on' 'SELECT * FROM circles' | awk -F "|" '{ print $2"\t"$5 }')
echo "==========================" >> ${OUTPUTFILE}
echo "Circles" >> ${OUTPUTFILE}
echo "--------------------------" >> ${OUTPUTFILE}
echo "Has all Google+ Circles the user has created, as well as a count of the number of users in each one.">> ${OUTPUTFILE}
echo "${circles}" >> ${OUTPUTFILE}
echo 
#squares - this query pulls the details the groups that the user has joined
squares=$(sqlite3 ${INPUTFILE} '.headers on' 'SELECT * FROM squares' | awk -F "|" '{ print $1"\t"$2"\t"$3"\t"$6 }')
echo "==========================" >> ${OUTPUTFILE}
echo "Squares" >> ${OUTPUTFILE}
echo "--------------------------" >> ${OUTPUTFILE}
echo "Has all Google+ squares (groups)that the user has joined ">> ${OUTPUTFILE}
echo "${squares}" >> ${OUTPUTFILE}
echo 
#Events - this query pulls information on all of the events scheduled on the suspects google+ account
events=$(sqlite3 "${INPUTFILE}" "SELECT _id, event_id, name, datetime(start_time/1000, 'unixepoch', 'localtime') FROM events" )
echo "==========================" >> ${OUTPUTFILE}
echo "Events" >> ${OUTPUTFILE}
echo "--------------------------" >> ${OUTPUTFILE}
echo "All events the user has been invited to, whether they attended or not">> ${OUTPUTFILE}
echo >>  ${OUTPUTFILE}
echo "${events}" >> ${OUTPUTFILE}
echo "-------------------------" >> ${OUTPUTFILE}
#photos - this query pulls information on all of the photos in the suspects google+ account and performs some analysis on these photos
photos=$(sqlite3 "${INPUTFILE}" "SELECT _id, photo_id, image_url, datetime(timestamp/1000, 'unixepoch', 'localtime') FROM all_photos" )
echo "==========================" >> ${OUTPUTFILE}
echo "Photos" >> ${OUTPUTFILE}
echo "--------------------------" >> ${OUTPUTFILE}
echo "Contains a URL to download images shared by and with the user,  as well as the creation date/time in Unix epoch format, whichs has been converted">> ${OUTPUTFILE}
echo >>  ${OUTPUTFILE}
echo "${photos}" >> ${OUTPUTFILE}
echo "-------------------------" >> ${OUTPUTFILE}
#get the urls of the pictures that my suspect has saved in his photos
urls=$(echo "${photos}" | awk -F "|" '{print $3}' )
echo "URLs From Photos: " >> ${OUTPUTFILE}
echo "$urls" >> ${OUTPUTFILE}
wget -q -i -r $urls #downloads the urls which have been extracted from the database above -i input, -r recursive -q quiet  
echo "Image Files from all_photos have been downloaded" >> ${OUTPUTFILE}
echo "------------------------- " >> ${OUTPUTFILE}
echo "General Analysis selected.......  analysis has completed - Report is named:" 
echo "${OUTPUTFILE}" # display on screen where report file has been written to 
echo 

break
;; 

#keyword search analysis - this will pull all info from all tables in es0.db 
2) 
echo "Keyword Search"
echo "Please enter a keyword to search:"
echo "-------------------------" >> ${OUTPUTFILE}
read keyword1
#user input i.e. keyword requested
keysearch=$(echo "$keyword1")
results=$(for key in $(sqlite3 ${INPUTFILE} .tables) ; 
do 
sqlite3 ${INPUTFILE} "SELECT * FROM $key;" | egrep -i ${keysearch} && echo "Details above found in table: $key" && echo "=========================="; 
done) 
if [ -z "${results}" ] # if keyword that the user has requested is not in the database
then
	echo "${keysearch} has not been found in this database"
	exit 7
else 
echo "${results}" >> ${OUTPUTFILE}
echo "Keyword Search selected.......  analysis has completed - report is named:"
echo "${OUTPUTFILE}"
echo
fi
break
;;

#keyword file search - this will pull all info on the keywords supplied in $3 from es0.db"
3) 
if [ ! -e ${KEYWORD} ] 
then 
		echo "Keyword file does not exist, please provide file as argument #3"
		exit 7
else
echo "Keyword File Search is being performed on file ${KEYWORD} "
echo "...."
results2=$(while read -r line; 
		do
		for key in $(sqlite3 ${INPUTFILE} .tables) ; 
		do 
		sqlite3 ${INPUTFILE} "SELECT * FROM $key;" | egrep -i ${line} && echo && echo "Details above found in table: $key" && echo "=========================="; 
		done
	done < ${KEYWORD} ) #this variable contains the results of the search performed in es0.db 
if [ -z "${results2}" ]; # if keyword file does not return anything from the database
then
	echo "Keywords in \"${KEYWORD}\" file have not been found in this database" #if the keyword does not contain any hits
	exit 8
else 
echo "Keyword file Search - analysis has completed - report is named:"
echo "${OUTPUTFILE}"
echo "${results2}" >> ${OUTPUTFILE} #write results to output file
fi
fi
break 
;;
#exit if Quit selected
4) exit 6;;
#any other input will exit
*) echo "Please select 1 (General Analysis), 2 (Keyword), 3 (Keyword File) or 4 to exit" >&2
esac
done
exit 0
