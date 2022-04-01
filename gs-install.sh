# GRAVITY SYNC BY VMSTAN #####################
# gs-install.sh ##############################

# For documentation or downloading updates visit https://github.com/vmstan/gravity-sync
# This code will be called from a curl call via installation instructions

# Run this script on your primary Pi-hole to aid in preparing for Gravity Sync installation.

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
echo -e "${YELLOW}Gravity Sync by ${BLUE}@vmstan${NC}"
echo -e "${CYAN}https://github.com/vmstan/gravity-sync${NC}"
echo -e "========================================================"
echo -e "${INFO} ${YELLOW}Validating user permissions${NC}"
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
    
    # if [ "$LOCALADMIN" != "sudo" ]; then
    #    echo -e "${FAIL} ${CURRENTUSER} cannot use sudo"
    #    CROSSCOUNT=$((CROSSCOUNT+1))
    #    LOCALADMIN="nosudo"
    # fi
fi

echo -e "${INFO} ${YELLOW}Scanning for Required Components${NC}"
# Check OpenSSH
if hash ssh 2>/dev/null
then
    echo -e "${GOOD} OpenSSH Binaries Detected"
else
    echo -e "${FAIL} OpenSSH Binaries Not Installed"
    CROSSCOUNT=$((CROSSCOUNT+1))
fi

# Check Rsync
if hash rsync 2>/dev/null
then
    echo -e "${GOOD} RSYNC Binaries Detected"
else
    echo -e "${FAIL} RSYNC Binaries Not Installed"
    CROSSCOUNT=$((CROSSCOUNT+1))
fi

# Check Sudo
if hash sudo 2>/dev/null
then
    echo -e "${GOOD} SUDO Binaries Detected"
else
    echo -e "${FAIL} SUDO Binaries Not Installed"
    CROSSCOUNT=$((CROSSCOUNT+1))
fi

# Check for Systemctl
if hash systemctl 2>/dev/null
then
    echo -e "${GOOD} Systemctl Binaries Detected"
else
    echo -e "${FAIL} Systemctl Binaries Not Installed"
    CROSSCOUNT=$((CROSSCOUNT+1))
fi

# Check GIT
if hash git 2>/dev/null
then
    echo -e "${GOOD} GIT Binaries Detected"
else
    echo -e "${FAIL} GIT Binaries Not Installed"
    CROSSCOUNT=$((CROSSCOUNT+1))
fi

echo -e "${INFO} ${YELLOW}Performing Warp Core Diagnostics${NC}"
# Check Pihole
if hash pihole 2>/dev/null
then
    echo -e "${GOOD} Local Pi-hole Install Detected"
else
    echo -e "${WARN} ${PURPLE}No Local Pi-hole Install Detected${NC}"
    # echo -e "${WARN} ${PURPLE}Attempting To Compensate${NC}"
    if hash docker 2>/dev/null
    then
        echo -e "${GOOD} Docker Binaries Detected"
        
        if [ "$LOCALADMIN" == "sudo" ]
        then
            FTLCHECK=$(sudo docker container ls | grep 'pihole/pihole')
        elif [ "$LOCALADMIN" == "nosudo" ]
        then
            echo -e "${WARN} ${PURPLE}No Docker Pi-hole Container Detected (unable to scan)${NC}"
            # CROSSCOUNT=$((CROSSCOUNT+1))
            PHFAILCOUNT=$((PHFAILCOUNT+1))
        else
            FTLCHECK=$(docker container ls | grep 'pihole/pihole')
        fi
        
        if [ "$LOCALADMIN" != "nosudo" ]
        then
            if [ "$FTLCHECK" != "" ]
            then
                echo -e "${GOOD} Pi-Hole Docker Container Detected"
            else
                echo -e "${WARN} ${PURPLE}No Docker Pi-hole Container Detected${NC}"
                # CROSSCOUNT=$((CROSSCOUNT+1))
                PHFAILCOUNT=$((PHFAILCOUNT+1))
            fi
        fi
    elif hash podman 2>/dev/null
    then
        echo -e "${GOOD} Podman Binaries Detected"
        
        if [ "$LOCALADMIN" == "sudo" ]
        then
            FTLCHECK=$(sudo podman container ls | grep 'pihole/pihole')
        elif [ "$LOCALADMIN" == "nosudo" ]
        then
            echo -e "${WARN} ${PURPLE}No Podman Pi-hole Container Detected (unable to scan)${NC}"
            # CROSSCOUNT=$((CROSSCOUNT+1))
            PHFAILCOUNT=$((PHFAILCOUNT+1))
        else
            FTLCHECK=$(podman container ls | grep 'pihole/pihole')
        fi
        
        if [ "$LOCALADMIN" != "nosudo" ]
        then
            if [ "$FTLCHECK" != "" ]
            then
                echo -e "${GOOD} Pi-Hole Podman Container Detected"
    else
                echo -e "${WARN} ${PURPLE}No Podman Pi-hole Container Detected${NC}"
                # CROSSCOUNT=$((CROSSCOUNT+1))
                PHFAILCOUNT=$((PHFAILCOUNT+1))
            fi
        fi
    else
        # echo -e "${FAIL} No Local Pi-hole Install Detected"
        echo -e "${WARN} ${PURPLE}No Docker Pi-hole Alternative Detected${NC}"
        # CROSSCOUNT=$((CROSSCOUNT+1))
        PHFAILCOUNT=$((PHFAILCOUNT+1))
    fi
fi

if [ "$PHFAILCOUNT" != "0" ]
then
    echo -e "${FAIL} No Usable Pi-hole Install Detected"
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
    echo -e "${INFO} ${YELLOW}Status Report${NC}"
    echo -e "${FAIL} ${RED}${CROSSCOUNT} Critical Issue(s) Detected${NC}"
    echo -e "${WARN} ${PURPLE}Please Correct Failures and Re-Execute${NC}"
    echo -e "${INFO} ${YELLOW}Installation Exiting (without changes)${NC}"
else
    echo -e "${INFO} ${YELLOW}Executing Gravity Sync Deployment${NC}"
    
    if [ "$LOCALADMIN" == "sudo" ]
    then
        echo -e "${STAT} Creating Sudoers.d File"
        touch /tmp/gs-nopasswd.sudo
        echo -e "${CURRENTUSER} ALL=(ALL) NOPASSWD: ALL" > /tmp/gs-nopasswd.sudo
        sudo install -m 0440 /tmp/gs-nopasswd.sudo /etc/sudoers.d/gs-nopasswd
    fi
    
    if [ "$GS" != "engage" ]
    then
        echo -e "${INFO} Gravity Sync Preperation Complete"
        echo -e "${INFO} Execute on Installer on Secondary"
        echo -e "${INFO} Check Documentation for Instructions"
        echo -e "${INFO} Installation Exiting (without changes)"
    else
        echo -e "${STAT} Creating Gravity Sync Directories"
            if [ -d /etc/gravity-sync/.gs ]; then
                sudo rm -fr /etc/gravity-sync/.gs
            fi

            if [ ! -d /etc/gravity-sync ]; then
                sudo mkdir /etc/gravity-sync
            fi

            if [ -f /usr/local/bin/gravity-sync ]; then
                sudo rm -f /usr/local/bin/gravity-sync
            fi

            if [ "$GS_DEV" != "" ]; then
                sudo git clone -b ${GS_DEV} https://github.com/vmstan/gravity-sync.git /etc/gravity-sync/.gs
                touch /etc/gravity-sync/.gs/dev
                echo -e "origin/$GS_DEV" >> /etc/gravity-sync/.gs/dev
            else
                sudo git clone https://github.com/vmstan/gravity-sync.git /etc/gravity-sync/.gs
            fi
            sudo cp /etc/gravity-sync/.gs/gravity-sync /usr/local/bin
        echo -e "${STAT} Starting Gravity Sync Configuration"
        gravity-sync configure <&1
    fi
fi
exit