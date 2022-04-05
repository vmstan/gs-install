#!/usr/bin/env bash

# GRAVITY SYNC BY VMSTAN #####################
# gs-install.sh ##############################

# For documentation or downloading updates visit https://github.com/vmstan/gravity-sync
# This code will be called from a curl call via installation instructions

set -e

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
echo -e "${LOGO} ${BOLD}Gravity Sync by @vmstan - Installation Script${NC}"
echo -e "${INFO} Validating user permissions"
if [ ! "$EUID" -ne 0 ]; then
    echo -e "${GOOD} ${CURRENTUSER} is root"
    LOCALADMIN="root"
else
    if hash sudo 2>/dev/null; then
        echo -e "${GOOD} Sudo utility detected"
        sudo --validate
        if [ "$?" != "0" ]; then
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

echo -e "${INFO} Scanning for Required Components"
# Check OpenSSH
if hash ssh 2>/dev/null
then
    echo -e "${GOOD} SSH has been detected"
else
    echo -e "${FAIL} OpenSSH not detected on this system"
    echo -e "${WARN} This is required to run commands to your remote Pi-hole"
    CROSSCOUNT=$((CROSSCOUNT+1))
fi

# Check Rsync
if hash rsync 2>/dev/null
then
    echo -e "${GOOD} RSYNC has been detected"
else
    echo -e "${FAIL} RSYNC not detected on this system"
    echo -e "${WARN} This is required to transfer data to/from your remote Pi-hole"
    CROSSCOUNT=$((CROSSCOUNT+1))
fi

# Check Sudo
if hash sudo 2>/dev/null
then
    echo -e "${GOOD} SUDO has been detected"
else
    echo -e "${FAIL} SUDO not detected on this system"
    echo -e "${WARN} This is required to properly set permissions on your Pi-hole(s)"
    CROSSCOUNT=$((CROSSCOUNT+1))
fi

# Check for Systemctl
if hash systemctl 2>/dev/null
then
    echo -e "${GOOD} Systemctl has been detected"
else
    echo -e "${FAIL} Systemctl not detected on this system"
    echo -e "${WARN} This is required to automate and monitor Pi-hole replication"
    CROSSCOUNT=$((CROSSCOUNT+1))
fi

# Check GIT
if hash git 2>/dev/null
then
    echo -e "${GOOD} GIT has been detected"
else
    echo -e "${FAIL} GIT has not been detected"
    echo -e "${WARN} This is required to download and update Gravity Sync"
    CROSSCOUNT=$((CROSSCOUNT+1))
fi

echo -e "${INFO} Performing Warp Core Diagnostics"
# Check Pihole
if hash pihole 2>/dev/null
then
    echo -e "${GOOD} Local installation of Pi-hole has been detected"
else
    echo -e "${WARN} Standard Pi-hole installation is not detected"
    echo -e "${INF1} Attempting To Compensate"
    if hash docker 2>/dev/null
    then
        echo -e "${GOOD} Docker installation has been detected"
        
        if [ "$LOCALADMIN" == "sudo" ]
        then
            FTLCHECK=$(sudo docker container ls | grep 'pihole/pihole')
        elif [ "$LOCALADMIN" == "nosudo" ]
        then
            echo -e "${WARN} Unable to detect running Docker containers"
            # CROSSCOUNT=$((CROSSCOUNT+1))
            PHFAILCOUNT=$((PHFAILCOUNT+1))
        else
            FTLCHECK=$(docker container ls | grep 'pihole/pihole')
        fi
        
        if [ "$LOCALADMIN" != "nosudo" ]
        then
            if [ "$FTLCHECK" != "" ]
            then
                echo -e "${GOOD} Running Docker container of Pi-hole has been detected"
            else
                echo -e "${WARN} There is no Docker container of Pi-hole running"
                # CROSSCOUNT=$((CROSSCOUNT+1))
                PHFAILCOUNT=$((PHFAILCOUNT+1))
            fi
        fi
    elif hash podman 2>/dev/null
    then
        echo -e "${GOOD} Podman installation has been detected"
        
        if [ "$LOCALADMIN" == "sudo" ]
        then
            FTLCHECK=$(sudo podman container ls | grep 'pihole/pihole')
        elif [ "$LOCALADMIN" == "nosudo" ]
        then
            echo -e "${WARN} Unable to detect running Podman containers"
            # CROSSCOUNT=$((CROSSCOUNT+1))
            PHFAILCOUNT=$((PHFAILCOUNT+1))
        else
            FTLCHECK=$(podman container ls | grep 'pihole/pihole')
        fi
        
        if [ "$LOCALADMIN" != "nosudo" ]
        then
            if [ "$FTLCHECK" != "" ]
            then
                echo -e "${GOOD} Running Podman container of Pi-hole has been detected"
    else
                echo -e "${WARN} There is no Podman container of Pi-hole running"
                # CROSSCOUNT=$((CROSSCOUNT+1))
                PHFAILCOUNT=$((PHFAILCOUNT+1))
            fi
        fi
    else
        # echo -e "${FAIL} No Local Pi-hole Install Detected"
        echo -e "${WARN} No containerized Pi-hole alternatives are detected"
        # CROSSCOUNT=$((CROSSCOUNT+1))
        PHFAILCOUNT=$((PHFAILCOUNT+1))
    fi
fi

if [ "$PHFAILCOUNT" != "0" ]
then
    echo -e "${FAIL} Pi-hole was not found on this system"
    CROSSCOUNT=$((CROSSCOUNT+1))
fi

# echo -e "${INFO} ${YELLOW}Target Folder Analysis${NC}"
# if [ "$GS_INSTALL" == "secondary" ]
# then
#    if [ "$LOCALADMIN" == "sudo" ]
#    then
#        THISDIR=$(pwd)
#        if [ "$THISDIR" != "$HOME" ]
#        then
#            echo -e "${FAIL} ${CURRENTUSER} Must Install to $HOME"
#            echo -e "${WARN} ${PURPLE}Use 'root' Account to Install in $THISDIR${NC}"
#            CROSSCOUNT=$((CROSSCOUNT+1))
#        fi
#    fi
# fi

# Combine Outputs
if [ "$CROSSCOUNT" != "0" ]
then
    echo -e "${INFO} Status Report"
    echo -e "${FAIL} ${RED}${CROSSCOUNT} critical issue(s) prevent successful deployment${NC}"
    echo -e "${WARN} Please compensate for the failures and re-execute"
    echo -e "${INF1} Installation is now exiting making without changes"
else
    echo -e "${INFO} Executing Gravity Sync Deployment"
    
    if [ "$LOCALADMIN" == "sudo" ]
    then
        echo -e "${STAT} Creating sudoers.d permissions file"
        touch /tmp/gs-nopasswd.sudo
        echo -e "${CURRENTUSER} ALL=(ALL) NOPASSWD: ALL" > /tmp/gs-nopasswd.sudo
        sudo install -m 0440 /tmp/gs-nopasswd.sudo /etc/sudoers.d/gs-nopasswd
    fi
    
    if [ "$GS" == "prep" ]
    then
        echo -e "${GOOD} This system has been validated as ready to run Gravity Sync"
        echo -e "${WARN} Execute again here or on another system without 'GS=prep'"
        echo -e "${NEED} https://github.com/vmstan/gravity-sync/wiki for questions"
        echo -e "${INFO} Preperation Complete"
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
            echo -e "∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞"
            if [ "$GS_DEV" != "" ]; then
                sudo git clone -b ${GS_DEV} https://github.com/vmstan/gravity-sync.git /etc/gravity-sync/.gs
                sudo touch /etc/gravity-sync/.gs/dev
                echo -e "BRANCH='origin/$GS_DEV'" | sudo tee /etc/gravity-sync/.gs/dev
            else
                sudo git clone https://github.com/vmstan/gravity-sync.git /etc/gravity-sync/.gs
            fi
            sudo cp /etc/gravity-sync/.gs/gravity-sync /usr/local/bin
            
        if [ "$GS_DOCKER" == "1" ]; then
            exit
        fi    
            
            
            echo -e "∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞"
            echo -e "${STAT} Starting Gravity Sync Configuration"

        if [ ! -f /etc/gravity-sync/gravity-sync.conf ]; then 
            gravity-sync configure <&1
        else
            echo -e "${GOOD} Existing gravity-sync.conf has been detected"
            echo -e "${WARN} Execute 'gravity-sync configure' to replace it"
            echo -e "${WARN} Use 'gravity-sync update' in the future as an alternative"
            echo -e "${GOOD} Upgrade Complete"
            echo -e "${INFO} Installation Exiting"
        fi
    fi
fi
exit