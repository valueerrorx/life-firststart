#!/bin/bash
# last updated: 15.01.2017
#delete yourself



kdialog --dontagain firststart:nofirststart --title "First Start Wizard"  --yesno "Möchten Sie das System jetzt einrichten?"

if [ "$?" = 0 ]; then
    rm /home/student/.config/autostart-scripts/firststart.sh
    exec /usr/bin/lifesudo '/usr/bin/python /home/student/.life/applications/life-firststart/firststart.py'
else
    sleep 0
fi;








