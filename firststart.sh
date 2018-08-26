#!/bin/bash
# last updated: 25.08.2018
#delete yourself



kdialog --dontagain firststart:nofirststart --title "First Start Wizard"  --yesno "Möchten Sie das System jetzt einrichten?"

if [ "$?" = 0 ]; then
    rm /home/student/.config/autostart-scripts/firststart.sh
    pkxexec '/home/student/.life/applications/life-firststart/firststart.py'
else
    sleep 0
fi;








