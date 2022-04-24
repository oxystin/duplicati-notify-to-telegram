#!/bin/bash

#########################################################################
# Script to receive telegram notifications about Duplicati backup results
#########################################################################

# Duplicati is able to run scripts before and after backups. This 
# functionality is available in the advanced options of any backup job (UI) or
# as option (CLI). The (advanced) options to run scripts are
# --run-script-before = your/path/notify_to_telegram.sh
# --run-script-after = your/path/notify_to_telegram.sh

# To work, you need to set two required variables:
#  TELEGRAM_TOKEN
#  TELEGRAM_CHATID
# These variables can be set directly in the script file
# or added to environment variables using other methods.
#########################################################################

#TELEGRAM_TOKEN=<your telegram token>     Еnter without quotes!!!
#TELEGRAM_CHATID=<your telegram chatid>   Еnter without quotes!!!
TELEGRAM_URL="https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage"

function getFriendlyFileSize() {
    size=$1
    if [ $size -eq "0" ]; then
        size='-'
    elif [ $size -ge 1099511627776 ]; then
        size=$(awk 'BEGIN {printf "%.1f",'$size'/1099511627776}')Tb
    elif [ $size -ge 1073741824 ]; then
        size=$(awk 'BEGIN {printf "%.1f",'$size'/1073741824}')Gb
    elif [ $size -ge 1048576 ]; then
        size=$(awk 'BEGIN {printf "%.1f",'$size'/1048576}')Mb
    elif [ $size -ge 1024 ]; then
        size=$(awk 'BEGIN {printf "%.1f",'$size'/1024}')Kb
    else
        size='-'
    fi
    echo $size
}

function getHeader () {
    CURRENT_STATUS=`echo "BEFORE=Started,AFTER=Finished" | sed "s/.*$DUPLICATI__EVENTNAME=\([^,]*\).*/\1/"`
    echo "DUPLICATI BACKUP
    ———————————————————————————
    ◉ Task:      $DUPLICATI__backup_name
    ◉ Operation: $DUPLICATI__OPERATIONNAME
    ◉ Status:    $CURRENT_STATUS" | sed 's/^[ \t]*//;s/[ \t]*$//'
}

function getResultLine () {
    RESULT_ICON=`echo "Unknown=🟣,Success=🟢,Warning=🟡,Error=🔴,Fatal=🛑" | sed "s/.*$DUPLICATI__PARSED_RESULT=\([^,]*\).*/\1/"`
    echo "${RESULT_ICON}`printf %*s 3`${MESSAGE}
    ◉ Result:    $DUPLICATI__PARSED_RESULT
    ———————————————————————————" | sed 's/^[ \t]*//;s/[ \t]*$//'
}

function getResultFatal () {
    eval `sed -n "s/^\(\w*\):\s*\([^\"]*\)$/\1=\"\2\"/p" $DUPLICATI__RESULTFILE`
    echo "
    ⦿ Error: $Failed
    ⦿ Details: $Details
    " | sed 's/^[ \t]*//;s/[ \t]*$//'
}

function getOperationRestore () {
    eval `sed -n "s/^\(\w*\):\s*\(\w*\)$/\1=\2/p" $DUPLICATI__RESULTFILE`
    echo "
    FILES:       count     size
    ⦿ Restored: `printf %*s 5 $RestoredFiles` `printf %*s 9 $(getFriendlyFileSize $SizeOfRestoredFiles)`
    ⦿ Deleted:  `printf %*s 5 $DeletedFiles` `printf %*s 9 $(getFriendlyFileSize 0)`
    ⦿ Patched:  `printf %*s 5 $PatchedFiles` `printf %*s 9 $(getFriendlyFileSize 0)`
    ———————————————————————————
    FOLDERS:
    ⦿ Restored: `printf %*s 5 $RestoredFolders` `printf %*s 9 $(getFriendlyFileSize 0)`
    ⦿ Deleted:  `printf %*s 5 $DeletedFolders` `printf %*s 9 $(getFriendlyFileSize 0)`
    " | sed 's/^[ \t]*//;s/[ \t]*$//'
}

function getOperationBackup () {
    eval `sed -n "s/^\(\w*\):\s*\(\w*\)$/\1=\2/p" $DUPLICATI__RESULTFILE`
    echo "
    FILES:       count     size
    ⦿ Added:    `printf %*s 5 $AddedFiles` `printf %*s 9 $(getFriendlyFileSize $SizeOfAddedFiles)`
    ⦿ Deleted:  `printf %*s 5 $DeletedFiles` `printf %*s 9 $(getFriendlyFileSize 0)`
    ⦿ Changed:  `printf %*s 5 $ModifiedFiles` `printf %*s 9 $(getFriendlyFileSize $SizeOfModifiedFiles)`
    ⦿ Opened:   `printf %*s 5 $OpenedFiles` `printf %*s 9 $(getFriendlyFileSize $SizeOfOpenedFiles)`
    ⦿ Examined: `printf %*s 5 $ExaminedFiles` `printf %*s 9 $(getFriendlyFileSize $SizeOfExaminedFiles)`
    ———————————————————————————
    FOLDERS:
    ⦿ Added:    `printf %*s 5 $AddedFolders` `printf %*s 9 $(getFriendlyFileSize 0)`
    ⦿ Deleted:  `printf %*s 5 $DeletedFolders` `printf %*s 9 $(getFriendlyFileSize 0)`
    ⦿ Changed:  `printf %*s 5 $ModifiedFolders` `printf %*s 9 $(getFriendlyFileSize 0)`
    " | sed 's/^[ \t]*//;s/[ \t]*$//'
}

if [ "$DUPLICATI__OPERATIONNAME" == "List" ]; then exit 0; fi

MESSAGE=$(getHeader)

if [ "$DUPLICATI__EVENTNAME" == "AFTER" ]; then
    MESSAGE=$(getResultLine)
    if [ "$DUPLICATI__OPERATIONNAME" == "Restore" ]; then
        MESSAGE+=$(getOperationRestore)
    elif [ "$DUPLICATI__PARSED_RESULT" == "Fatal" ]; then
        MESSAGE+=$(getResultFatal)
    else
        MESSAGE+=$(getOperationBackup)
    fi
else
    MESSAGE="`printf %*s 5`${MESSAGE}"
fi

MESSAGE=\`${MESSAGE}\`


curl -s $TELEGRAM_URL -d chat_id=$TELEGRAM_CHATID -d text="$MESSAGE" -d parse_mode="markdown" -k > /dev/null

exit 0