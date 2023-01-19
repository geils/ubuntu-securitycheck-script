#!/bin/bash

HOSTNAME=`hostname`
mkdir $HOSTNAME
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
NC=$'\033[0m'

: ' 
### START - BASIC SETTINGS ###

# THIS SCRIPT IS BASED ON UBUNTU 20.04 LTS #
# PLEASE RUN WITH ROOT PRIVILEGES #
'
# LOGINABLE ID LIST
awk -F: '$2 !~ /(NP|LK)/ {print $1}' /etc/passwd > $HOSTNAME/id.$$

# GROUP LIST
awk -F: '{print $1}' /etc/group > $HOSTNAME/group.$$

# HOME DIRECTORY LIST
awk -F":" 'length($6) > 0 {print $6}' /etc/passwd | sort -u > $HOSTNAME/homedir.$$

: ' ### END - BASIC SETTINGS '

touch $HOSTNAME/$HOSTNAME.txt
chmod 600 $HOSTNAME/$HOSTNAME.txt

: ' ### START CHECK PROCESS ### '
echo "1. SYSTEM ACCOUNT MANAGEMENT CHECK"
date
echo "### CHECK A-01 ### : UID 0 IS ROOT ONLY"
UIDZERO=`awk -F: '($3 == "0") {print $1}' /etc/passwd`
if [ $UIDZERO == "root" ]
then
	printf "${GREEN} !!! CHECK SUCCESS !!! ${NC}\n"
	CHKA01="${GREEN}PASS${NC}"
else
	printf "${RED}!!! CHECK FAILED. OTHER USER HAS UID 0? CHECK LOGFILE !!!${NC}\n"
	CHKA01="${RED}FAIL${NC}"
fi

echo "### DONE A-01 ###"

echo "### CHECK A-02 ### : LIMITED SHELLS DEFINE"
if [ -f /etc/shells ]
then
	printf "${GREEN} !!! CHECK SUCCESS !!! ${NC}\n"
	CHKA02="${GREEN}PASS${NC}"
else
	printf "${RED}!!! CHECK FAILED. /etc/shells not found. CHECK LOGFILE !!!${NC}\n"
	CHKA02="${RED}FAIL${NC}"
fi
echo "### DONE A-02 ###"

echo "### CHECK A-03 ### : SESSION TIMEOUT"
TMOUTCHK=`cat /etc/profile | egrep -i "TMOUT|timeout|autologout" | grep -v "^#" | wc -l`
if [ -f /etc/profile ] && [ ${TMOUTCHK} == 1 ];
then
	printf "${GREEN} !!! CHECK SUCCESS !!! ${NC}\n"
	CHKA03="${GREEN}PASS${NC}"
else
        printf "${RED}!!! CHECK FAILED. NO TIMEOUT DEFINES FOUND. CHECK LOGFILE !!!${NC}\n"
        CHKA03="${RED}FAIL${NC}"
fi
echo "### DONE A-03 ###"

echo "2. SYSTEM ACCOUNT PASSWORD POLICY CHECK"
echo "### CHECK B-01 ### : PASSWORD POLICY SETTINGS"
MAXAGE=`sudo chage -l $USERNAME | sed -n '6p' | awk '{print $NF}'`
MINLENCOM=`grep PASS_MIN_LEN /etc/login.defs | grep '^#' | wc -l`
MINLEN=`sudo cat /etc/login.defs | grep PASS_MIN_LEN | awk '{print $NF}'`
if [ -f /etc/login.defs ] && [ ${MAXAGE} <= 60 ];
then
	echo "login.defs FILE EXISTS and MAX_DAYS under 60. do next step..."
	if [ ${MINLENCOM} >= 1 ]; then
		printf "${RED}!!! CHECK FAILED. PASS_MIN_LEN has comment.${NC}\n"
	elif [ ${MINLEN} < 8 ]; then
		printf "${RED}!!! CHECK FAILED. PASS_MIN_LEN less than 8.${NC}\n"
	else
		printf "${GREEN} !!! CHECK SUCCESS !!! ${NC}"
		CHKB01="${GREEN}PASS${NC}"
	fi
else
	printf "${RED}!!! CHECK FAILED. Password policy not matching. CHECK LOGFILE !!!${NC}"
	CHKB01="${RED}FAIL${NC}"
fi
echo "### DONE B-01 ###"

echo "### CHECK B-02 ### : USE SHADOW"
GREPPWFILE=`awk -F: '{print $1, $2}' /etc/passwd | grep -v -e "^x$" | wc -l`
WCPWFILE=`cat /etc/passwd | wc -l`
if [ -f /etc/shadow ] && [ ${WCPWFILE} == ${GREPPWFILE} ];
then
	printf "${GREEN} !!! CHECK SUCCESS !!! ${NC}"
	CHKB02="${GREEN}PASS${NC}"
else
	printf "${RED}!!! CHECK FAILED. /etc/shadow not found. CHECK LOGFILE !!!${NC}"
	CHKB02="${RED}FAIL${NC}"
fi
echo "### DONE B-02 ###"

echo "3. SYSTEM FILE MANAGEMENT CHECK"
C01CP=0
echo "### CHECK C-01-1 ### : /etc/shadow FILE PERMISSION CHECK"
if [ `stat -c "%a" /etc/shadow` == 400 ]; then
	echo "/etc/shadow permission checked."
	C01CP=${C01CP}+1
else
	echo "/etc/shadow permission check failed."
fi
echo "### CHECK C-01-2 ### : /etc/passwd FILE PERMISSION CHECK"
if [ `stat -c "%a" /etc/passwd` == 444 ]; then
	echo "/etc/passwd permission checked."
	C01CP=${C01CP}+1
else
	echo "/etc/passwd permission check failed."
fi
echo "### CHECK C-01-3 ### : /etc/netplan/* FILE PERMISSION CHECK"
if [ `stat -c "%a" /etc/netplan/*` == 600 ]; then
	echo "/etc/netplan permission checked."
	C01CP=${C01CP}+1
else
	echo "/etc/netplan permission check failed."
fi
echo "### CHECK C-01-4 ### : USER PROFILE PERMISSION CHECK"
if [ `stat -c "%a" /home/${USERNAME}/.profile` == 644 ]; then
	echo "home .profile permission checked."
	C01CP=${C01CP}+1
else
	echo "home .profile permission check failed."
fi
echo "### CHECK C-01-5 ### : /etc/hosts FILE PERMISSION CHECK"
if [ `stat -c "%a" /etc/hosts` == 644 ]; then
	echo "/etc/hosts permission checked."
	C01CP=${C01CP}+1
else
	echo "/etc/hosts permission check failed."
fi

if [ ${C01CP} == 5 ]; then
	printf "${GREEN} !!! CHECK SUCCESS !!! ${NC}\n"
	CHKC01="${GREEN}PASS${NC}"
else
	printf "${RED}!!! CHECK FAILED. /etc/shadow not found. CHECK LOGFILE !!!${NC}\n"
	CHKC01="${RED}FAIL${NC}"
fi
echo "### DONE C-01 ###"

echo "### CHECK C-02 ### : HOME DIRECTORY PERMISSION CHECK"
HOMEPERM=`ls -ld /home/${USERNAME} | cut -c 5-10 | grep w | wc -l`
if [ ${HOMEPERM} == 0 ]; then
	printf "${GREEN} !!! CHECK SUCCESS !!! ${NC}\n"
	CHKC02="${GREEN}PASS${NC}"
else
	printf "${RED}!!! CHECK FAILED. HOME DIR MUST UNDER 755. CHECK LOGFILE !!!${NC}\n"
	CHKC02="${RED}FAIL${NC}"
fi
echo "### DONE C-02 ###"

echo "### CHECK C-03 ### : UMASK VALUE CHECK"
if [ `umask` == 0022 ]; then
	printf "${GREEN} !!! CHECK SUCCESS !!! ${NC}\n"
	CHKC03="${GREEN}PASS${NC}"
else
	printf "${RED}!!! CHECK FAILED. UMASK VALUE MUST 0022. CHECK LOGFILE !!!${NC}\n"
        CHKC03="${RED}FAIL${NC}"
fi
echo "### DONE C-03 ###"

echo "### CHECK C-04 ### : PATH CHECK"
INCPATH=`echo ${PATH} | cut -c 1`
if [ ${INCPATH} == "/" ]; then
	printf "${GREEN} !!! CHECK SUCCESS !!! ${NC}\n"
	CHKC04="${GREEN}PASS${NC}"
else
	printf "${RED}!!! CHECK FAILED. PATH MUST NOT INCLUDE '.' !!!${NC}\n"
	CHKC04="${RED}FAIL${NC}"
fi
echo "### DONE C-04 ###"

echo "### CHECK C-05 ### : GLOBAL DIRECTORY WITH STICKY BITS CHECK"
if [ `stat -c "%a" /tmp` == 1777 ] && [ `stat -c "%a" /var/tmp` == 1777 ]; then
	printf "${GREEN} !!! CHECK SUCCESS !!! ${NC}\n"
	CHKC05="${GREEN}PASS${NC}"
else
	printf "${RED}!!! CHECK FAILED. STICKY BITS NOT FOUND !!!${NC}\n"
	CHKC05="${RED}FAIL${NC}"
fi
echo "### DONE C-05 ###"

echo "### CHECK C-06 ###"
GCCPMS=`stat -c "%a" /usr/bin/gcc`
if [ ${GCCPMS} == 777 ]; then
	printf "${GREEN} !!! CHECK SUCCESS !!! ${NC}\n"
	CHKC06="${GREEN}PASS${NC}"
else
	CHKC06="${GREEN}PASS${NC}"
	printf "compiler rule is need audit\n"
fi
echo "### DONE C-06 ###"

echo "4. SYSTEM OPERATION SERVICE MANAGEMENT CHECK"
echo "### CHECK D-01 ### : DATE SYNCHRONIZE CHECK"
TIMECHK=`sudo timedatectl status | sed -n '5p' | awk '{print $NF}'`
if [ ${TIMECHK} == "yes" ]; then
	printf "${GREEN} !!! CHECK SUCCESS !!! ${NC}\n"
	CHKD01="${GREEN}PASS${NC}"
else
	printf "${RED}!!! CHECK FAILED. TIME SYNC IS NOT ACTIVE !!!${NC}\n"
	CHKD01="${RED}FAIL${NC}"
fi
echo "### DONE D-01 ###"

echo "### CHECK D-02 ### : REMOTE ACCESS PROGRAM CHECK"
RMPORT1=`netstat -an | grep 177 | wc -l`
RMPORT2=`netstat -an | grep 6000 | wc -l`
if [ ${RMPORT1} == 0 ] && [ ${RMPORT2} == 0 ]; then
	printf "${GREEN} !!! CHECK SUCCESS !!! ${NC}\n"
	CHKD02="${GREEN}PASS${NC}"
else
	printf "${RED}!!! CHECK FAILED. REMOTE PORT  !!!${NC}\n"
	CHKD02="${RED}FAIL${NC}"
fi
echo "### DONE D-02 ###"

echo "### CHECK D-03 ### : UNUSED SERVICE CHECK"
CHKSVC=`sudo service --status-all | egrep 'echo|daytime|time|finger|printer|ntalk|discard|chargen|tftp|sftp|talk|uucpd'`
if [ -z ${CHKSVC} ]; then
	printf "${GREEN} !!! CHECK SUCCESS !!! ${NC}\n"
	CHKD03="${GREEN}PASS${NC}"
else
	printf "${RED}!!! CHECK FAILED. UMASK VALUE MUST 0002. CHECK LOGFILE !!!${NC}\n"
	CHKD03="${RED}FAIL${NC}"
fi
echo "### DONE D-03 ###"

echo "### CHECK D-04 ### : REMOTE ACCESS CHECK"
GREPALW=`grep '^[[:blank:]]*[^[:blank:]#;]' /etc/hosts.allow | wc -l`
GREPDEN=`grep '^[[:blank:]]*[^[:blank:]#;]' /etc/hosts.deny | wc -l`
if [ ! -f /etc/hosts.equiv ]; then
	printf "/etc/hosts.equiv not found. check next...\n"
	if [ ${GREPALW} == 0 ] && [ ${GREPDEN} == 0 ]; then
		printf "${GREEN} !!! CHECK SUCCESS !!! ${NC}\n"
		CHKD04="${GREEN}PASS${NC}"
	else
		printf "/etc/hosts.allow or /etc/hosts.deny has added configuration. check again.\n"
		CHKD04="${RED}FAIL${NC}"
	fi
else
	printf "/etc/hosts.equiv found. it must be removed.\n"
	CHKD04="${RED}FAIL${NC}"
fi
echo "### DONE D-04 ###"

echo "### CHECK D-05 ### : SSH ROOT LOGIN CHECK"
SSHGRP=`grep 'PermitRootLogin' testgrep  | grep -v '#' | wc -l`
if [ ! -f /etc/ftpusers ] && [ ${SSHGRP} == 0 ]; then
	printf "${GREEN} !!! CHECK SUCCESS !!! ${NC}\n"
	CHKD05="${GREEN}PASS${NC}"
else
	printf "ftp user exists or ssh configuration failed.\n"
	CHKD05="${RED}FAIL${NC}"
fi
echo "### DONE D-05 ###"

echo "### CHECK D-06 ### : FTP PRCOESS/USER CHECK"
FTPPS=`ps -ef | grep ftp | grep -v "grep" | wc -l`
FTPUSR=`grep 'ftp' /etc/passwd | wc -l`
if [ ${FTPPS} == 0 ] && [ ${FTPUSR} == 0] && [ ! -f /etc/vsftpd.conf ]; then
	printf "${GREEN} !!! CHECK SUCCESS !!! ${NC}\n"
	CHKD06="${GREEN}PASS${NC}"
else
	printf "ftp process found or ftp user in passwd or vsftpd.conf found.\n"
	CHKD06="${RED}FAIL${NC}"
fi
echo "### DONE D-06 ###"

echo "### CHECK D-07 ### : SNMP CHECK"
SNMPPS=`netstat -an | grep 161 | egrep -v "[0-9]{4,}" | wc -l`
if [ ${SNMPPS} == 0 ]; then
	printf "${GREEN} !!! CHECK SUCCESS !!! ${NC}\n"
	CHKD07="${GREEN}PASS${NC}"
else
	printf "is SNMP process running?\n"
	CHKD07="${RED}FAIL${NC}"
fi
echo "### DONE D-07 ###"

echo "### CHECK D-08 ### : SYSTEM WARNING MESSAGE WHEN LOGIN CHECK"
ISSUEGRP=`grep 'Ubuntu' /etc/issue | wc -l`
if [ ${ISSUEGRP} == 0 ] && [ -f /etc/motd ]; then
	printf "${GREEN} !!! CHECK SUCCESS !!! ${NC}\n"
	CHKD08="${GREEN}PASS${NC}"
elif [ ${ISSUEGRP} != 0 ] || [ ! -f /etc/issue.net ] || [ ! -f /etc/motd ]; then
	printf "/etc/issue.net or /etc/motd missing or /etc/issue is default\n"
	CHKD08="${RED}FAIL${NC}"
fi
echo "### DONE D-08 ###"

echo "### SYSTEM AUDITING AND LOGGING ###"
echo "### CHECK E-01 ### : LOG CONFIGURATION CHECK" 
BTMPWGRP=`grep 'weekly' /etc/logrotate.d/btmp | wc -l`
BTMPRGRP=`grep 'rotate 12' /etc/logrotate.d/btmp | grep -v '#' | wc -l`
WTMPWGRP=`grep 'weekly' /etc/logrotate.d/wtmp | wc -l`
WTMPRGRP=`grep 'rotate 12' /etc/logrotate.d/wtmp | grep -v '#' | wc -l`
if [ ${BTMPWGRP} == 1 ] && [ ${BTMPRGRP} == 1 ]; then
	if [ ${WTMPWGRP} == 1 ] && [ ${WTMPRGRP} == 1 ]; then
		printf "${GREEN} !!! CHECK SUCCESS !!! ${NC}\n"
		CHKE01="${GREEN}PASS${NC}"
	else
		printf "WTMP log configuration failed. \n"
		CHKE01="${RED}FAIL${NC}"
	fi
else
	printf "BTMP log configuration failed. \n"
	CHKE01="${RED}FAIL${NC}"
fi
echo "### DONE E-01 ###"

echo "### CHECK E-02 ### : QRader LOGGING CONFIGURATION CHECK"
QRALOG=`cat /etc/rsyslog.conf | egrep -i "info|<LoggingServerIP1>|<LoggingServerIP2>" | grep -v '#' | wc -l`
if [ ${QRALOG} == 1 ]; then
	printf "${GREEN} !!! CHECK SUCCESS !!! ${NC}\n"
	CHKE02="${GREEN}PASS${NC}"
else
	printf "QRader log configuration failed.\n"
	CHKE02="${RED}FAIL${NC}"
fi
echo "### DONE E-02 ###"

echo "### SYSTEM SECURITY PATCH CHECK ###"
echo "### CHECK F-01 : LATEST PATCH VERSION OF KERNEL CHECK ###"
OSVER=`cat /etc/lsb-release | grep 20.04.5 | wc -l`
if [ ${OSVER} == 1 ]; then
	printf "${GREEN} !!! CHECK SUCCESS !!! ${NC}\n"
	CHKF01="${GREEN}PASS${NC}"
else
	printf "NEED UPDATE OS KERNEL VERSION.\n"
	CHKF01="${RED}FAIL${NC}"
fi
echo "### DONE F-01 ###"

echo "### OTHER MANAGEMENT THINGS CHECK ###"
echo "### CHECK G-01 ### : OUTBOUND INTERNET CONNECTION CHECK"
GETCURL=`curl -s -o /dev/null -w "%{http_code}" http://www.google.com`
if [ ${GETCURL} == 200 ]; then
	printf "THIS MACHINE CAN REACH OUTBOUND ANY\n"
	CHKG01="${RED}FAIL${NC}"
else
	printf "${GREEN} !!! CHECK SUCCESS !!! ${NC}\n"
	CHKG01="${GREEN}PASS${NC}"
fi
echo "### DONE G-01 ###"

echo "### CHECK G-02 ### : CYBEREASON EDR PROCESS CHECK"
EDRPS=`ps -ef | grep cybereason | grep -v grep | wc -l`
if [ ${EDRPS} == 2 ]; then
	printf "${GREEN} !!! CHECK SUCCESS !!! ${NC}\n"
	CHKG02="${GREEN}PASS${NC}"
else
	printf "cybereason process not working normally.\n"
	CHKG02="${RED}FAIL${NC}"
fi
echo "### DONE G-02 ###"

seperator=+---------------------------------------------------------------------+
seperator=$seperator$seperator
rows="| %-10s| %-20s| %-10s| %-20s| %-10s| %-20s |\n"
TableWidth=71

printf "\n\n"
printf "${GREEN}### RESULT SUMMARY ###${NC}\n"
printf "%.${TableWidth}s\n" "$seperator"
printf "| %-10s| %-9s| %-10s| %-9s| %-10s| %-9s |\n" CHECKER RESULT CHECKER RESULT CHECKER RESULT
printf "%.${TableWidth}s\n" "$seperator"
printf "$rows" "A-01" ${CHKA01} "C-04" ${CHKC04} "D-06" ${CHKD06}
printf "$rows" "A-02" ${CHKA02} "C-05" ${CHKC05} "D-07" ${CHKD07}
printf "$rows" "A-03" ${CHKA03} "C-06" ${CHKC06} "D-08" ${CHKD08}
printf "$rows" "B-01" ${CHKB01} "D-01" ${CHKD01} "E-01" ${CHKE01}
printf "$rows" "B-02" ${CHKB02} "D-02" ${CHKD02} "E-02" ${CHKE02}
printf "$rows" "C-01" ${CHKC01} "D-03" ${CHKD03} "F-01" ${CHKF01}
printf "$rows" "C-02" ${CHKC02} "D-04" ${CHKD04} "G-01" ${CHKG01}
printf "$rows" "C-03" ${CHKC03} "D-05" ${CHKD05} "G-02" ${CHKG02}
printf "%.${TableWidth}s\n" "$seperator"

: ' ### ARCHIVE RESULTS ### '
tar -cvzf $HOSTNAME.tar.gz $HOSTNAME

