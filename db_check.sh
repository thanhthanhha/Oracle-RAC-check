#!/bin/bash

#to do list
#missing show_title (func to create title)
#do a checklist function


#params check
[[ -z $1 ]] && [[ -z $2 ]] && echo "Version needed" && exit 1

#general var
declare -A CHECKLIST=()
declare -a RESULT_TXT
case "$1" in
    -v) DEBUG="true";;
    *) VERSION=$1;;
esac

declare -A CFILE

#format var
RED=`tput setaf 1`
GREEN=`tput setaf 2`
RESET=`tput sgr0`

#directory check
WORK_DIR="/tmp/dir"
PKG_DIR="./checklist/list.txt"
SYSCTL_DIR="/etc/sysctl.conf"
LIMITD_DIR="/etc/security/limits.d/oracle-database-preinstall-19c.conf"
CONFTEMP_DIR="./checklist/conf.json"
SELINUX_DIR="/etc/selinux/config"



#initialize logging
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3 15 9
exec 1>/tmp/log.out 2>&1
# Everything below will go to the file 'log.out':

input_cheat() {
    exec 2>&4 1>&3
    $*
    echo "wait........"
    exec 3>&1 4>&2
}

dir_check() {
declare -a DIR_ARR=( 'WORK_DIR' 'PKG_DIR' 'SYSCTL_DIR' 'CONFTEMP_DIR' 'SELINUX_DIR' )
for n in "${DIR_ARR[@]}"
do
    echo "check $n"
    if [[ -d ${!n} || -f ${!n} ]]; then
        continue   
    else
        echo "Directory or File ${!n} does not exist.."
        usr_input \"$n\" \"${!n}\"
        echo "Creating directory ${!n}..."
        [[ ! -d ${!n} ]] && mkdir ${!n} || touch ${!n}
    fi
done
}
#check executables
lib_check() {
    local return_txt
    local usr="/usr/bin"
    local bin="/bin"
    declare -a lib=( 'jq' )
    for i in "${lib[@]}"
    do
        eval $i
        [[ $? == 0 || -f "$usr/$i" || -f "$bin/$i" ]] || return_txt="failed" && echo "Please install $i first"
    done
    [[ ${return_txt} == failed ]] && exit 1
}


#basic clean up function
function cleanup() {
    #revert changed files
    echo "CODE $?"
    local row_num=$(( ${#CFILE[@]} / 2 ))
    local col_num=2
    local lo_arr=($(get_arr ${row_num} ${col_num} "CFILE"))
    for ((i=0;i<=row_num;i+=2)) do
        [[ -z ${lo_arr[i]} && -z ${lo_arr[i]} ]] && continue
        mv ${lo_arr[i]} ${lo_arr[i+1]} 
    done
    echo "files changed reverted"
    #remove files
    rm -r ${WORK_DIR}
    echo "remove working files"
}

#general functions
function get_arr () {
    #convert 2 dimentional array to 1D array - each 2 consecutive index is a 2d's record
    #usage get_arr row_num col_num array_name
    local num_rows=$1
    local num_columns=$2
    local arr=$3
    local tmp_arr=()
    local accu=0
    for ((i=1;i<=num_rows;i++)) do
        for ((j=1;j<=num_columns;j++)) do
            local var1=${arr[$i,$j]}
            tmp_arr[((accu++))]=${!var1}
        done
    done
}
eval() {
    if [ $? != 0 ]; then
                echo "There is a problem with $1 : $2"
                exit 1
    fi
}
usr_input() {
    dir=$2
    name=$1
    echo "$name not found please select the correct input [$dir]: "
    read inpt
    eval $name=${inpt:-$dir}
}
push() {
    local str=$1[@]
    arr=("${!str}")
    [[ "$(declare -p $arr)" =~ "declare -a" ]] || echo "$1 is not an array" && exit 1
    len=${#arr[@]}
    arr[$len + 1]=$2
}

#initialize traps
trap_add() {
    trap_add_cmd=$1; shift || echo "${FUNCNAME} usage error"
    for trap_add_name in "$@"; do
        trap -- "$(
            # helper fn to get existing trap command from output
            # of trap -p
            extract_trap_cmd() { printf '%s\n' "$3"; }
            # print existing trap command with newline
            eval "extract_trap_cmd $(trap -p "${trap_add_name}")"
            # print the new trap command
            printf '%s\n' "${trap_add_cmd}"
        )" "${trap_add_name}" \
            || fatal "unable to add to trap ${trap_add_name}"
    done
}

#logging functions
log() { printf '%s\n' "$*"; }
error() { log "ERROR: $*" >&2; }
fatal() { error "$@"; exit 1; }

#presiquite

pre_check() {
    local pre_list=( "${BASH_VERSION} < 4" )
    for i in "${pre_list[@]}" ; do
        eval "[[ $i ]]" || fatal "Precheck failed with $i"
    done
}

#begin checking networking use main_menu to initialized

sub_menu() {
    if_net=$1
    if_rec=$(ip addr show | awk 'BEGIN { RS="(^|\n)[[:digit:]]:[[:space:]]"; } /'$if_net'/ { print $0;}')
    if_num=$(echo $if_rec | egrep -c "inet[[:space:]]")
    local opt_arr=()
    for ((i=0;i<if_num;i++)) do
        opt_arr[$i]=$(ip addr show | awk -v ifnet="$if_net" 'BEGIN { RS="(^|\n)[[:digit:]]:[[:space:]]"; } /'$if_net'/ { print $0;}' | egrep "inet[[:space:]]" | awk '{print $2}' | head $((i+1)))
    done
    PS3='Please enter your choice: ' 
    select opt in "${opt_arr[@]}" 
    do
        if [ "$REPLY" -eq "$if_num" ];
        then
        echo "Exiting..."
        break;
        elif [ 1 -le "$REPLY" ] && [ "$REPLY" -le $((if_num-1)) ];
        then
        net_result=$(sed 's|\/[[:digit:]]*||' <<< ${opt_arr[$REPLY]})
        break 2;
        else
        echo "Incorrect Input: Select a number 1-$if_num"
        fi
    done
}
main_menu() {
local l_beg=$(netstat -i | grep -n Iface | sed 's/:.*//')
let net_rec="$(netstat -i | wc -l) - $l_beg"
local net_arr=()
for ((i=0;i<net_rec;i++)) do
    net_arr[$i]=$(netstat -i | sed -n "$((i+1+l_beg))p" | awk '{print $1}')
done
PS3='Please enter your choice: '
echo "Select I/F: " 
select opt in "${net_arr[@]}"
do 
    if [ "$REPLY" -eq "$net_rec" ];
    then
      echo "Exiting..."
      break;
    elif [ 1 -le "$REPLY" ] && [ "$REPLY" -le $((net_rec-1)) ];
    then
      sub_menu ${net_arr[$((REPLY+1))]}
      break;
    else
      echo "Incorrect Input: Select a number 1-$net_rec"
    fi
done
}
# 1st main
net_check () {
    local net_result
    #call menu
    main_menu
    ping -c 4 ${net_result}
    [[ $? =  0 ]] && CHECKLIST["NETWORK CHECK..."]="OK" && CHECKLIST["NETWORK CHECK..."]="NOT OK"
    push RESULT_TXT "Ping failed with: \n${net_result}"
}
#check packages
pkg_check () {
    #pre install
    yum list --installed | grep "oracle-database-preinstall-${VERSION}"
    if [[ $? == 0 ]]
    then
        CHECKLIST["ORACLE PREINSTALL CHECK..."]="OK"
        return 0
    else
        readarray -t pkg_list < $PKG_DIR
        for i in "pkg_list[@]}" ; do
            yum list --installed | grep ${pkg_list[$i]}
            [[ $? == 0 ]] || CHECKLIST["ORACLE PREINSTALL PKG CHECK..."]="NOT OK"
            return 0
        done
        CHECKLIST["ORACLE PREINSTALL PKG CHECK..."]="OK"
        return 0
    fi
    CHECKLIST["ORACLE PREINSTALL CHECK..."]="NOT OK"
    return 0
}

conf_check() {
    #sysctl check

    params=$(xargs -n 1 -I{} sh -c '[[ -z $(egrep -o {} ${SYSCTL_DIR}) ]] && echo {}' < <(jq -r '.sysctl[]' ${CONFTEMP_DIR}))
    [[ ! -z ${params} ]] && CHECKLIST["ORACLE CONF SYSCTL CHECK..."]="NOT OK" || CHECKLIST["ORACLE CONF SYSCTL CHECK..."]="OK"
    [[ ! -z ${params} ]] && push RESULT_TXT "SYSCTL failed with file ${SYSCTL_DIR}): \n${params}"

    #preinstall check

    miss_params=$(xargs -n 1 -I{} sh -c 'awk -v var={} '"'"'{ if ($3 !~ var) print $3}'"'"' ${LIMITD_DIR}' < <(jq -r '.preinstall[1][]' ${CONFTEMP_DIR}))
    [[ ! -z ${miss_params} ]] && CHECKLIST["ORACLE CONF PREINSTALL CHECK..."]="NOT OK" || CHECKLIST["ORACLE CONF PREINSTALL CHECK..."]="OK"
    [[ ! -z ${miss_params} ]] && push RESULT_TXT "PREINSTALL CONF failed with file ${LIMITD_DIR}: \n${miss_params}"
}

selinux_check() {
    [[ -z $(grep "SELINUX=permissive" ${SELINUX_DIR} || grep "SELINUX=disabled" ${SELINUX_DIR}) ]] && CHECKLIST["ORACLE CONF SELINUX CHECK..."]="NOT OK" || CHECKLIST["ORACLE CONF PREINSTALL CHECK..."]="OK"
    [[ CHECKLIST["ORACLE CONF PREINSTALL CHECK..."] == "NOT OK" ]] && push RESULT_TXT "SELINUX CONF failed with file ${SELINUX_DIR}: \n$(grep "SELINUX" ${SELINUX_DIR})"
}

user_check() {
    users=( "oracle" )
    groups=( "oinstall" "dba" "oper" )
    user_str="Users:"
    grp_str="Groups:"
    stt="true"
    for i in "${user[@]}"; do
    id $i
    [[ $? != 0 ]] && user_str="${user_str} $i" && stt="false"
    done
    for j in "${group[@]}"; do
    [[ -z $(getent groups $j) ]] && grp_str="${grp_str} $j" && stt="false"
    done
    [[ $stt == "false" ]] && push RESULT_TXT "USER check failed with: \n${grp_str}\n${user_str}"
}

display_result() {
    local str=$1[@]
    arr=("${!str}")
    for i in "${!arr[@]}"; do
    local fmt
    local status
    [[ ${arr[$i]} == "OK" ]] && fmt=${GREEN} || fmt=${RED} && status="failed"
    echo "$i\t${fmt}${arr[$i]}${RESET}"
    done
    if [ ${status} == "failed" ]
    then
    for j in "${RESULT_TXT[@]}"; do
    echo -e "\n${RED}$j}"
    done
    fi
}


main() {
    trap_add cleanup SIGINT SIGTERM ERR
    trap_add 'exit 1' SIGINT
    dir_check
    echo "wrong........................"
    lib_check
    pre_check
    net_check
    pkg_check
    conf_check
    selinux_check
    user_check
    display_result CHECKLIST
}

main