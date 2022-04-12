#!/usr/bin/env bash

# GRAVITY SYNC BY VMSTAN #####################
# gs-install.sh ##############################

# For documentation or downloading updates visit https://github.com/vmstan/gravity-sync
# This code will be called from a curl call via installation instructions

# set -e
export PATH+=':/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'

if hash apt-get 2>/dev/null; then
    OS_PKG="debian"
    OS_UPDATE="apt-get update"
    OS_INSTALL="apt-get install -y"
elif hash dnf 2>/dev/null; then
    OS_PKG="redhat"
    OS_UPDATE="dnf check-update"
    OS_INSTALL="dnf install -y"
elif hash tdnf 2>/dev/null; then
    OS_PKG="photon"
    OS_UPDATE="tdnf update"
    OS_INSTALL="tdnf install -y"
#elif hash yum 2>/dev/null; then
#    OS_PKG="oldhat"
#    OS_UPDATE="yum update"
#    OS_INSTALL="yum install -y"
#elif hash apk 2>/dev/null; then
#    OS_PKG="alpine"
#    OS_UPDATE="apk update"
#    OS_INSTALL="apk add"
else
    OS_PKG="unknown"
fi

# Script Colors
RED='\033[0;91m'
GREEN='\033[0;92m'
CYAN='\033[0;96m'
YELLOW='\033[0;93m'
PURPLE='\033[0;95m'
BLUE='\033[0;94m'
BOLD='\033[1m'
NC='\033[0m'

## Message Codes
FAIL="${RED}✗${NC}"
WARN="${PURPLE}!${NC}"
GOOD="${GREEN}✓${NC}"
STAT="${CYAN}∞${NC}"
INFO="${YELLOW}»${NC}"
INF1="${CYAN}›${NC}"
NEED="${BLUE}?${NC}"
LOGO="${PURPLE}∞${NC}"

# Variables
CROSSCOUNT="0"
PHFAILCOUNT="0"
CURRENTUSER=$(whoami)


# Header
echo -e "${LOGO} ${BOLD}Gravity Sync Installation Script${NC}"
echo -e "${INFO} Validating User Permissions"

if [ ! "$EUID" -ne 0 ]; then
    echo -e "${GOOD} ${CURRENTUSER} is root"
    LOCALADMIN="root"

    if ! hash sudo 2>/dev/null; then
        if [ "${OS_PKG}" = "unknown" ]; then
            echo -e "${FAIL} Sudo utility not detected"
            CROSSCOUNT=$((CROSSCOUNT+1))
        else
            echo -e "${INFO} Installing Sudo"
            ${OS_INSTALL} sudo
        fi
    else
        echo -e "${GOOD} Sudo utility detected"
    fi
else
    if hash sudo 2>/dev/null; then
        echo -e "${GOOD} Sudo utility detected"
        
        if ! sudo --validate; then
            echo -e "${FAIL} ${CURRENTUSER} cannot use sudo"
            CROSSCOUNT=$((CROSSCOUNT+1))
            LOCALADMIN="nosudo"
        else
            echo -e "${GOOD} ${CURRENTUSER} has sudo powers"
            LOCALADMIN="sudo"
        fi
    else
        echo -e "${FAIL} Sudo utility not detected"
        CROSSCOUNT=$((CROSSCOUNT+1))
        LOCALADMIN="nosudo"
    fi
    
    if [ "$LOCALADMIN" != "sudo" ]; then
        echo -e "${FAIL} ${CURRENTUSER} cannot use sudo"
        CROSSCOUNT=$((CROSSCOUNT+1))
        LOCALADMIN="nosudo"
     fi
fi

if [ "${LOCALADMIN}" == "nosudo" ]; then
    echo -e "${FAIL} Sudo utility cannot be used by the current user."
    echo -e "  You will need to manually compensate for this error."
    echo -e "  Installation cannot continue at this time."
    echo -e "${INFO} Exiting Gravity Sync Installer"
    exit
fi

echo -e "${INFO} Validating Install of Required Components"
# Check OpenSSH
if hash ssh 2>/dev/null; then
    echo -e "${GOOD} SSH has been detected"
else
    echo -e "${FAIL} OpenSSH cannot be detected on this system."
    echo -e "  You will need to manually compensate for this error."
    echo -e "  Installation cannot continue at this time."
    echo -e "${INFO} Exiting Gravity Sync Installer"
    exit
fi

# Check GIT
if hash git 2>/dev/null; then
    echo -e "${GOOD} GIT has been detected"
else
    if [ ! "${OS_PKG}" = "unknown" ]; then
        echo -e "${INFO} Attempting Install of Git"
        sudo ${OS_INSTALL} git
    else
        echo -e "${FAIL} GIT has not been detected"
        echo -e "${WARN} This is required to download and update Gravity Sync"
        CROSSCOUNT=$((CROSSCOUNT+1))
    fi
fi


# Check Rsync
if hash rsync 2>/dev/null; then
    echo -e "${GOOD} RSYNC has been detected"
else
    if [ ! "${OS_PKG}" = "unknown" ]; then
        echo -e "${INFO} Attempting Install of Rsync"
        sudo ${OS_INSTALL} rsync
    else
        echo -e "${FAIL} RSYNC not detected on this system"
        echo -e "${WARN} This is required to transfer data to/from your remote Pi-hole"
        CROSSCOUNT=$((CROSSCOUNT+1))
    fi
fi

if [ "$GS_DOCKER" != "1" ]; then
    # Check for Systemctl
    if hash systemctl 2>/dev/null
    then
        echo -e "${GOOD} Systemctl has been detected"
    else
        echo -e "${FAIL} Systemctl not detected on this system"
        echo -e "${WARN} This is required to automate and monitor Pi-hole replication"
        CROSSCOUNT=$((CROSSCOUNT+1))
    fi
fi

if [ "$GS_DOCKER" != "1" ]; then
    echo -e "${INFO} Performing Warp Core Diagnostics"
    # Check Pihole
    if hash pihole 2>/dev/null; then
        echo -e "${GOOD} Local installation of Pi-hole has been detected"
    else
        if hash docker 2>/dev/null; then
            echo -e "${GOOD} Docker installation has been detected"
            FTLCHECK=$(sudo docker container ls | grep 'pihole/pihole')
                if [ "$FTLCHECK" != "" ]
                then
                    echo -e "${GOOD} Docker container of Pi-hole has been detected"
                else
                    echo -e "${WARN} There is no Docker container of Pi-hole running"
                    PHFAILCOUNT=$((PHFAILCOUNT+1))
                fi
        elif hash podman 2>/dev/null; then
            echo -e "${GOOD} Podman installation has been detected"
            FTLCHECK=$(sudo podman container ls | grep 'pihole/pihole')
                if [ "$FTLCHECK" != "" ]
                then
                    echo -e "${GOOD} Podman container of Pi-hole has been detected"
                else
                    echo -e "${WARN} There is no Podman container of Pi-hole running"
                    PHFAILCOUNT=$((PHFAILCOUNT+1))
                fi
        else
            echo -e "${FAIL} No local Pi-hole install detected"
            PHFAILCOUNT=$((PHFAILCOUNT+1))
        fi
    fi


    if [ "$PHFAILCOUNT" != "0" ]
    then
        echo -e "${FAIL} Pi-hole was not found on this system"
        CROSSCOUNT=$((CROSSCOUNT+1))
    fi
fi

# Combine Outputs
if [ "$CROSSCOUNT" != "0" ]; then
    echo -e "${INFO} Status Report"
    echo -e "${FAIL} ${RED}${CROSSCOUNT} critical issue(s) prevent successful deployment${NC}"
    echo -e "  Please manually compensate for the failures and re-execute"
    echo -e "${INFO} Exiting Gravity Sync Installer"
    exit
else
    echo -e "${INFO} Executing Gravity Sync Deployment"
    
    if [ "$LOCALADMIN" == "sudo" ]; then
        if [ ! -f /etc/sudoers.d/gs-nopasswd ]; then
            echo -e "${STAT} Creating sudoers.d permissions file"
            touch /tmp/gs-nopasswd.sudo
            echo -e "${CURRENTUSER} ALL=(ALL) NOPASSWD: ALL" > /tmp/gs-nopasswd.sudo
            sudo install -m 0440 /tmp/gs-nopasswd.sudo /etc/sudoers.d/gs-nopasswd
        fi
    fi

    if [ -f /etc/bash.bashrc ]; then
         echo -e "${STAT} Cleaning up bash.bashrc"
         sudo sed -i "/gravity-sync.sh/d" /etc/bash.bashrc
         echo -e "  You may need to exit your terminal or reboot before running 'gravity-sync' commands"
    fi

   # echo -e "Get here?"

    GS_ALIAS_DETECT=$(alias | grep 'gravity-sync.sh')
    if [ "${GS_ALIAS_DETECT}" != "" ]; then
        echo -e "${WARN} Bash alias for a previous version of Gravity Sync was detected."
        echo -e "  You may need to manually remove this from your system and/or log out of"
        echo -e "  this session before your new Gravity Sync installation will function"
        echo -e "  as expected."
    fi
    
    if [ "$GS" == "prep" ]; then
        echo -e "${GOOD} This system has been validated as ready to run Gravity Sync"
        echo -e "  Execute again here or on another system without 'GS=prep'"
        echo -e "  https://github.com/vmstan/gravity-sync/wiki for questions"
        echo -e "${INFO} Gravity Sync Preperation Complete"
        exit
    else
        echo -e "${STAT} Creating Gravity Sync Directories"
            if [ -d /etc/gravity-sync/.gs ]; then
                sudo rm -fr /etc/gravity-sync/.gs
            fi

            if [ ! -d /etc/gravity-sync ]; then
                sudo mkdir /etc/gravity-sync
                sudo chmod 775 /etc/gravity-sync
            fi

            if [ -f /usr/local/bin/gravity-sync ]; then
                sudo rm -f /usr/local/bin/gravity-sync
            fi
            
            if [ "$GS_DEV" != "" ]; then
                sudo git clone -b "${GS_DEV}" https://github.com/vmstan/gravity-sync.git /etc/gravity-sync/.gs
                sudo touch /etc/gravity-sync/.gs/dev
                echo -e "BRANCH='origin/$GS_DEV'" | sudo tee /etc/gravity-sync/.gs/dev
            else
                sudo git clone https://github.com/vmstan/gravity-sync.git /etc/gravity-sync/.gs
            fi
            sudo cp /etc/gravity-sync/.gs/gravity-sync /usr/local/bin
            
        if [ "$GS_DOCKER" == "1" ]; then
            exit
        fi    
            echo -e "${STAT} Starting Gravity Sync Configuration"

        if [ ! -f /etc/gravity-sync/gravity-sync.conf ]; then 
            /usr/local/bin/gravity-sync configure <&1
        else
            echo -e "${WARN} Existing gravity-sync.conf has been detected"
            echo -e "  Execute ${YELLOW}gravity-sync config${NC} to replace it"
            echo -e "  Use ${YELLOW}gravity-sync update${NC} in the future as an alternative"
            echo -e "${GOOD} Upgrade Complete"
            echo -e "${INFO} Installation Exiting"
            exit
        fi
    fi
fi
exit