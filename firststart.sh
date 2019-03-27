#!/bin/bash
# last updated: 17.11.2018
#delete yourself

USER=$(logname)   #logname seems to always deliver the current xsession user - no matter if you are using SUDO
HOME="/home/${USER}/"
EXAMLOCKFILE="${HOME}.life/EXAM/exam.lock"

COW=$(blkid | grep casper | wc -l)


if test $COW = "0" 
then
    echo "life mode - exit"
    exit 0
fi



#do not trigger this in exam mode
if [ -f "$EXAMLOCKFILE" ];then
    echo "exam mode - exit"
    exit 0
fi



kdialog --dontagain firststart:nofirststart --title "First Start Wizard"  --yesno "Möchten Sie das System jetzt einrichten?"

if [ "$?" = 0 ]; then
    rm /home/student/.config/autostart-scripts/firststart.sh
    pkxexec '/home/student/.life/applications/life-firststart/firststart.py'
else
    sleep 0
fi;








