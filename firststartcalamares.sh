#!/bin/bash





sudo cp /home/student/.life/stuff/sddm.conf /etc/
sudo chown root: /etc/sddm.conf








kdialog  --msgbox 'All Done!  Restarting Desktop now!' --title 'First Start Wizard' --caption "First Start Wizard" > /dev/null
sleep 1

sudo killall ksmserver


