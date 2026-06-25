#!/bin/bash

#Progress bar
function progressbar {
	local progress=$1
	local total=$2
	local width=50
	local ratio=$(($progress *$width  / $total))
	local remainder=$((width - ratio))
	local str="Provisioning users: ["
	for i in $(seq $ratio); do
		str+="\e[32m\u25ae\e[0m"
	done
	for i in $(seq $remainder); do
		str+="\e[31m\u25af\e[0m"
	done
	str+="]"
	echo -ne "$str\r"
	
 }


#Check permission level
if ((EUID -nz)); then
	echo -e "\e[31m+==============================================+"
	echo -e "\nThis script must be ran with elevated privileges.\nPlease append \e[32m\e[1msudo\e[31m\e[22m to the front of your command.\n"
	echo -e "+==============================================+\e[0m\n"
	exit 1
fi

echo -e "Checking for files...\n"
USERS="users.txt"
LOG_FILE="/var/log/userprovision"

#Create log file if it doesn't exist
if [ ! -f "$LOG_FILE/uplog.log" ]; then
	mkdir -p "$LOG_FILE" && chmod 700 "LOG_FILE"
	touch "$LOG_FILE/uplog.log"
	echo "Log file created."
fi

#Check for the users file if it doesn't exist
if [ ! -f $USERS ]; then
	echo -e "\e[31m+==============================================+"
	echo -e "\n\t Missing user.txt file.\n"
	echo -e "+==============================================+\e[0m\n"
	echo -e "$(date +%Y-%m-%d) $(date +%H:%M:%S)\tFAILED: Failed to Locate user file." 1>> "$LOG_FILE/uplog.log"
	exit 1
fi

echo -e "$(date +%Y-%m-%d) $(date +%H:%M:%S)\tSUCCESS: Located user file." 1>> "$LOG_FILE/uplog.log"

#sets the temporary password for this batch of users
read -p "Temporary password: " TEMP_PASSWD
echo -e "\n"

len=$(wc -l < "$USERS")
processed=0
ACCNTS=0
GRPS=0
while IFS=";" read -r username groups; do
	((processed++))
	if id "$username" &>/dev/null; then
		echo -e "$(date +%Y-%m-%d) $(date +%H:%M:%S)\tSKIP: User: $username already exists." 1>> "$LOG_FILE/uplog.log"
	else
		useradd -m -s /bin/none "$username" 2>/dev/null
		echo $TEMP_PASSWD | passwd -e --stdin "$username" &>/dev/null
		echo -e "$(date +%Y-%m-%d) $(date +%H:%M:%S)\tSUCCESS: User: $username has been created." 1>> "$LOG_FILE/uplog.log"
		((ACCNTS+=1))
	fi
	IFS=, read -r -a USR_GRPS <<< "$groups"
	for grp in ${USR_GRPS[@]}; do
		if $(getent group $grp &>/dev/null); then
			echo -e "$(date +%Y-%m-%d) $(date +%H:%M:%S)\tSKIP: Group: $grp already exists." 1>> "$LOG_FILE/uplog.log"
			usermod -aG $grp "$username"
		else
			groupadd "$grp"
			echo -e "$(date +%Y-%m-%d) $(date +%H:%M:%S)\tSUCCESS: Group: $grp has been created." 1>> "$LOG_FILE/uplog.log"
	                ((GRPS+=1))
			usermod -aG $grp "$username"
		fi
	done
	progressbar $processed $len
done < $USERS

echo -e "\n\t\t\tCreated: $ACCNTS Account(s)\t$GRPS Group(s)"

