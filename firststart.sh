#!/bin/bash

# last updated: 21.05.2025
#delete yourself

USER=$(logname)   #logname seems to always deliver the current xsession user - no matter if you are using SUDO
HOME="/home/${USER}/"
EXAMLOCKFILE="${HOME}.life/EXAM/exam.lock"

#COW=$(blkid | grep casper | wc -l)
NOPERSISTENT=$(cat /proc/cmdline |grep nopersistent |wc -l)

PERSISTENT=$(cat /proc/cmdline |grep persistent |wc -l)


#test for the kernel paramter "nopersistent" (live mode)
if test $NOPERSISTENT = "1" 
then
    echo "life mode - exit"
    exit 0
fi


#neither persistent nor nopersistent - this system is installed
if test $PERSISTENT = "0"  
then
    echo "life mode - exit"
    exit 0
fi





#do not trigger this in exam mode
if [ -f "$EXAMLOCKFILE" ];then
    echo "exam mode - exit"
    exit 0
fi



kdialog --dontagain firststart:'Nicht mehr nachfragen' --title "First Start Wizard"  --yesno "Möchten Sie das System jetzt einrichten?"

if [ "$?" = 0 ]; then
    rm /home/student/.config/autostart-scripts/firststart.sh
    rm /home/student/.config/old-autostart-scripts/firststart.sh
    rm /home/student/.config/autostart/firststart.sh.desktop
    pkxexec '/home/student/.life/applications/life-firststart/firststart.py'
else
    sleep 0
fi;



