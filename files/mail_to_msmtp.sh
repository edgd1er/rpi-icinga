#!/usr/bin/env bash

#Variables
MYSQL_DATABASE="nconfdb"
MYSQL_HOST="holdom3"
MYSQL_PASSWORD="changeIt"
MYSQL_PORT="3326"
MYSQL_USER="nconf-user"

cmd_notify_host_by_email=''
cmd_notify_service_by_email=''
cmdori='/usr/bin/printf "%b" "***** Nagios *****\n\nNotification Type: $NOTIFICATIONTYPE$\nHost: $HOSTNAME$\nState: $HOSTSTATE$\nAddress: $HOSTADDRESS$\nInfo: $HOSTOUTPUT$\n\nDate/Time: $LONGDATETIME$\n" | /usr/bin/sendmail -s "** $NOTIFICATIONTYPE$ Host Alert: $HOSTNAME$ is $HOSTSTATE$ **" $CONTACTEMAIL$'

#Functions
usage() {
  printf "$0: [-f,-h]\n"
  printf "\tChange notify-host-by-email and notify-service-by-email command lines to send mail through msmtp;\n"
  printf "\t-h\t\t: this help;\n"
  printf "\t-f\t\t: force database update, even if sendmail is not detected as a send command ;\n"
}

getCmd() {
  QUERY="select cv.fk_id_item, cv.attr_value
from ConfigAttrs ca , ConfigValues cv
where ca.fk_id_class = 13 # misccommands
and cv.fk_id_attr = ca.id_attr
and cv.fk_id_attr =99 #command_line
and cv.fk_id_item in (select cv2.fk_id_item from ConfigValues cv2 where
cv2.attr_value like 'notify%')
order by cv.fk_id_item ;"
  mysql -Bs -h ${MYSQL_HOST} -P ${MYSQL_PORT} -u ${MYSQL_USER} -p${MYSQL_PASSWORD} -D ${MYSQL_DATABASE} -e "${QUERY}"
}

replaceCommand() {
  if [[ $cmd =~ mail ]]; then
    #echo mail found, adjustements to msmtp needed
    subject=$(echo $cmd | grep -oP "\-s \"[^\"]+\"")
    subject=${subject:3}
    #echo
    #echo sujet:${subject}
    message="$(echo $cmd | grep -oP "\" \"[^|]+" | head -1)"
    message=${message:2}
    #echo message:$message
    [[ ${cmd} =~ \$[^\$]+\$$ ]] && dest=${BASH_REMATCH[0]} || dest="NOT FOUND"
    #echo dest: ${dest}
    newcmd="/usr/bin/printf \"%b\" \"subject:${subject:1:-1}\n\n${message:1:-1} | /usr/bin/msmtp ${dest}"
    #echo
    echo "$newcmd"
  else
    #echo "No sendmail command found, no adjustmeent required"
    echo ''
  fi
}

#Main
FORCE=0

while getopts "hf" option; do
  case $option in
  h)
    usage
    ;;
  f)
    FORCE=1
    ;;
  esac
done

cmd=$(getCmd)
cmd=${cmdori}

while read -a l; do
  fk_id_item=${l[0]}
  cmd=${l[@]:1}
  #[[ ! -e ${fk_id_item}.txt ]] && echo "$cmd">${fk_id_item}.txt
  newCmd=$(replaceCommand)
  echo ${fk_id_item} // ${newCmd}
  if [[ -n ${newCmd} ]] || [[ 1 -eq ${FORCE} ]]; then
    echo updating command: sendmail or mail command found
    query="update ConfigValues cv set cv.attr_value='${newCmd}' where cv.fk_id_item ='${fk_id_item} and cv.fk_id_attr =99';"
    echo $query
    mysql -Br -h ${MYSQL_HOST} -P ${MYSQL_PORT} -u ${MYSQL_USER} -p${MYSQL_PASSWORD} -D ${MYSQL_DATABASE} <<<"${query}"
  else
    echo "No Command to update for item ${fk_id_item}"
  fi

done <<<${cmd}
