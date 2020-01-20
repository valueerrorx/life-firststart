#!/bin/bash
# last updated: 08.02.2017
# Europagymnasium Only!!
#
# first locks the desktop and then configures webdavlocation in fstab for our schools owncloud service

USER=$(logname)  
HOME="/home/${USER}/"
BACKUPDIR="${HOME}.life/systemrestore"
FSTABETC="/etc/fstab"


UPDATESOURCES=$1   #paketquellen werden nicht neu eingelesen
CHANGEWEBDAVURL=$2  #owncloud.europagymnasium.at url wird verwendet
CREATESSHKEYS=$3  # create unique ssh keys
CHANGEHOSTNAME=$4  #hostname wird beibelassen "life"
LOCKDESKTOP=$5      #abfrage ob der desktop gesperrt werden soll wird angezeigt
INSTALLRESTRICTED=$6   #install licensed codecs, fonts, plugins
BLOCKPACKAGES=$7        #for live usb block upgrades and installations of gub and kernel
SHAREMOUNT=$8           #mount share partition (fat32) to /home/student/SHARE
ROOTPW=${9}            #set password for user student
SETUSER=${10}           #set user student autologin to true (life does not work with other usernames atm.)
UPDATE=${11}           #update life applications
UNTIS=${12}           #update life applications
NETZLAUFWERK=${13}      #netzlaufwerk aufforderung nach autostart verschieben 
AUTOCLEAN=${14}      #beim logout das autoclean script starten (delete * in /home - restore config !



if [ "$(id -u)" != "0" ]; then
    kdialog  --msgbox 'You need root privileges - Stopping program' --title 'LIFE' > /dev/null
    exit 1
fi



echo $UPDATESOURCES
echo $CHANGEWEBDAVURL
echo $CREATESSHKEYS
echo $CHANGEHOSTNAME
echo $LOCKDESKTOP
echo $INSTALLRESTRICTED
echo $INSTALLREADER
echo $BLOCKPACKAGES
echo $SHAREMOUNT
echo $ROOTPW
echo $SETUSER
echo $UPDATE
echo $UNTIS
echo $NETZLAUFWERK
echo $AUTOCLEAN
#exit 0
 
 

 
 
 
 
progress=$(sudo -H -u ${USER} kdialog --progressbar "Paktetlisten werden aktualisiert....                                                              ");


#remove cdrom entry from sources.list
sudo sed -i "/cdrom/c\\#" /etc/apt/sources.list



sudo -H -u ${USER} qdbus $progress Set "" maximum 18

if [[( $UPDATESOURCES = "0" )]]
then
    sleep 0 #do nothing
else
    sudo -H -u ${USER} qdbus $progress Set "" value 1
    sudo apt update
    sudo -H -u ${USER} qdbus $progress Set "" value 2
    sudo apt clean
    sudo apt-get clean
fi








sudo -H -u ${USER} qdbus $progress Set "" value 3

if [[( $UPDATESOURCES = "0" )]]
then
    sleep 0 #do nothing
else
    sudo -H -u ${USER} qdbus $progress setLabelText "APT Index wird aktualisiert.... dies kann einige Minuten dauern"
    sudo update-apt-xapian-index -f
fi









sudo -H -u ${USER} qdbus $progress Set "" value 4

if [[( $CREATESSHKEYS = "0" )]]
then
    sleep 0 #do nothing
else
    sudo -H -u ${USER} qdbus $progress setLabelText "SSH Schlüssel werden generiert...."
    cd /etc/ssh
    sudo rm -f *_key*
    sudo ssh-keygen -t dsa -f /etc/ssh/ssh_host_dsa_key -N ''
    sudo ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N ''
    sudo ssh-keygen -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -N ''
fi












sudo -H -u ${USER} qdbus $progress Set "" value 5

if [[( $CHANGEWEBDAVURL = "0" )]]
then
    sleep 0 #do nothing
    #WEBDAVLOCATION="https://owncloud.europagymnasium.at/remote.php/webdav"
else

    sudo -H -u ${USER} qdbus $progress setLabelText "Konfiguriere Webdav Location.... "

    # check if the location is actually close to something that would work
    SUBSTRING="http"

    askwebdavlocation(){
        if ! WEBDAVLOCATION=$(kdialog --title "Configure Webdav Location"  --inputbox "Bitte bestätigen Sie die URL ihres WEBDAV Ordners!" "https://owncloud.europagymnasium.at/remote.php/webdav"); 
        then
            askwebdavlocation
        else
            if test "${WEBDAVLOCATION#$SUBSTRING}" != "$WEBDAVLOCATION"
            then
                echo "address seems legit";          # $SUBSTRING is in $WEBDAVLOCATION at the beginning of the line
            sleep 0
            else
                #echo "that is not a webdav location";  # $SUBSTRING is not in $WEBDAVLOCATION
                kdialog --error "$WEBDAVLOCATION \n\nDies ist keine gültige Webdav Adresse!" --title 'Configure Webdav Location!' 
                askwebdavlocation
            fi
        fi
    }
    askwebdavlocation
    
   
    WEBDAVMOUNTPOINT="/home/student/Cloudstorage"
    FSTABCHECK=$(grep davfs /etc/fstab | wc -l)   #test if there is already a davfs entry (davfs is used by sed later)

    # replace current fstab entry with new one

    MOUNTPOINTCASPER="/media/casper"
    COW=$(cat /proc/mounts | grep /cdrom | /bin/sed -e 's/^\/dev\/*//' |cut -c 1-3)   #find cow device
    COWDEV="/dev/${COW}3"
    
    sudo mkdir ${MOUNTPOINTCASPER}
    sudo mount $COWDEV $MOUNTPOINTCASPER
    
    sudo chattr -i ${MOUNTPOINTCASPER}/upper/etc/fstab   #on an overlay FS like AUFS this must be done in the upper directory
    
    
    
    

    if test $FSTABCHECK = "1" 
    then
        echo "---------------------------------------------"
        echo "fstab ok !"
    else
        echo "davfs" >> /etc/fstab

    fi
    sudo sed -i "/davfs/c\\$WEBDAVLOCATION  $WEBDAVMOUNTPOINT	davfs	user,noauto	0	0" $FSTABETC
    
    sudo chattr +i ${MOUNTPOINTCASPER}/upper/etc/fstab   #make immutable because on live devices this is overwritten on boot otherwise
 
 
 sudo umount $MOUNTPOINTCASPER

    echo "---------------------------------------------"
    echo "Webdav location written to fstab!"
    echo "---------------------------------------------"
    cat /etc/fstab
    echo "---------------------------------------------"
    
    LOCATION=${WEBDAVLOCATION%/*/*}  #cut the webdav part
    #change url for the desktop link too
    sed -i "s#\"http.*\"#\"${LOCATION}\"#g" ${HOME}/.local/share/applications/NextCloud.desktop 
    sed -i "s#\"http.*\"#\"${LOCATION}\"#g" ${HOME}/.local/share/plasma_icons/NextCloud.desktop
    
    #network environment location  (cut https://)
    LOCATIONNET=${WEBDAVLOCATION#*//}
    LOCATIONNET="webdavs://${LOCATIONNET}"
    sed -i "s#webdavs:/.*#${LOCATIONNET}#g" "${HOME}/.local/share/remoteview/owncloud-Europagymnasium webdavs.desktop"
    
fi










sudo -H -u ${USER} qdbus $progress Set "" value 6

if [[( $CHANGEHOSTNAME = "0" )]]
then
    sleep 0 #do nothing
else
    sudo -H -u ${USER} qdbus $progress setLabelText "Ändere den Hostnamen.... "

    if ! HOST=$(kdialog --title "HOSTNAME"  --inputbox "Bitte geben sie einen HOSTNAMEN an" "life"); 
    then
        HOST="life"
    else
        echo "Der Hostname wird erst beim nächsten Neustart aktiv"
echo "
127.0.0.1       localhost
127.0.1.1       $HOST

# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
" > /etc/hosts

        echo "$HOST" > /etc/hostname
    fi


fi







sudo -H -u ${USER} qdbus $progress Set "" value 7

if [[( $INSTALLRESTRICTED = "0" )]]
then
    sleep 0 #do nothing
else
    sudo -H -u ${USER} qdbus $progress setLabelText "Installiere Schriftarten und Plugins.... "
    bar(){
        sudo apt-get -y install ttf-bitstream-vera  ttf-dejavu ttf-xfree86-nonfree kubuntu-restricted-extras kubuntu-restricted-addons
    }
    export -f bar
    exec xterm -title firststart -e bar&
fi




sudo -H -u ${USER} qdbus $progress Set "" value 8

if [[( $BLOCKPACKAGES = "0" )]]
then
    sleep 0 #do nothing
else
    sudo -H -u ${USER} qdbus $progress setLabelText "Blockiere Bootloader- und Kernelupgrades.... "
    echo -e "Package: grub*\nPin: release *\nPin-Priority: -1\n" > /etc/apt/preferences
    echo -e "Package: grub*:i386\nPin: release *\nPin-Priority: -1\n" >> /etc/apt/preferences
    echo -e "Package: linux-image*\nPin: release *\nPin-Priority: -1\n" >> /etc/apt/preferences
    echo -e "Package: linux-image*:i386\nPin: release *\nPin-Priority: -1\n" >> /etc/apt/preferences
   
fi


sudo -H -u ${USER} qdbus $progress Set "" value 9

if [[( $SHAREMOUNT = "0" )]]
then
    sleep 0 #do nothing
else
    sudo -H -u ${USER} qdbus $progress setLabelText "Making SHARE mount permanent...."
    
    FSTABCHECK=$(grep SHARE /etc/fstab | wc -l)   #test if there is already a SHARE entry (SHARE is used by sed later)

    # replace current fstab entry with new one

    MOUNTPOINTCASPER="/media/casper"
    COW=$(cat /proc/mounts | grep /cdrom | /bin/sed -e 's/^\/dev\/*//' |cut -c 1-3)   #find cow device
    COWDEV="/dev/${COW}3"
    
    sudo mkdir ${MOUNTPOINTCASPER}
    sudo mount $COWDEV $MOUNTPOINTCASPER
    
    sudo chattr -i ${MOUNTPOINTCASPER}/upper/etc/fstab   #on an overlay FS like AUFS this must be done in the upper directory
    
    
    
    

    if test $FSTABCHECK = "1" 
    then
        echo "---------------------------------------------"
        echo "fstab ok !"
    else
        echo "SHARE" >> /etc/fstab
        #append the keyword to fstab in the last line
    fi
    
    #replace the line with the keyword with the whole entry
    CURRENTUID=$(id -u ${USER})
    
    sudo sed -i "/SHARE/c\\LABEL=SHARE     /home/student/SHARE     vfat    rw,nofail,x-systemd.device-timeout=1,uid=${CURRENTUID},gid=${CURRENTUID},umask=0022,codepage=437,iocharset=iso8859-1,shortname=mixed    0       0" $FSTABETC
    
    sudo chattr +i ${MOUNTPOINTCASPER}/upper/etc/fstab   #make immutable because on live devices this is overwritten on boot otherwise
 
    sudo umount $MOUNTPOINTCASPER
    

    echo "---------------------------------------------"
    echo "SHARE mount  written to fstab!"
    echo "---------------------------------------------"
    cat /etc/fstab
    echo "---------------------------------------------"
    

    
fi




sudo -H -u ${USER} qdbus $progress Set "" value 11

if [[( $ROOTPW = "0" )]]
then
    sleep 0 #do nothing
else
    sudo -H -u ${USER} qdbus $progress setLabelText "Neues Passwort setzen.... "
    
    
    PW="empty"
    getROOT(){
        PASSWD1=$(kdialog --title "LIFE" --inputbox "Geben sie bitte das gwünschte Benutzer-Passwort an!");
        if [ "$?" = 0 ]; then
            PASSWD2=$(kdialog --title "LIFE" --inputbox 'Geben sie bitte das gewünschte Benutzer-Passwort ein zweites mal an!');
            if [ "$?" = 0 ]; then
            
                if [ "$PASSWD2" = "$PASSWD1"  ]; then
                    sudo -u ${USER} kdialog --title "LIFE" --passivepopup "Passwort OK!" 3
                    PW=$PASSWD1
                else
                    kdialog --title "LIFE" --error "Die Passwörter sind nicht ident!"
                    getROOT 
                fi
            else
                kdialog   --title "LIFE" --error "Kein Password gesetzt!"
                sleep 0
            fi
        else
            kdialog  --title "LIFE" --error "Kein Password gesetzt!"
            sleep 0
        fi
    }
    getROOT
    
    if [ "$PW" != "empty" ]; then
        #setze root passwort
        echo "setze root passwort"
        echo -e "$PW\n$PW"|sudo passwd $USER
        #sudo sed -i "/student/c\student:U6aMy0wojraho:16233:0:99999:7:::" /etc/shadow
    fi
fi



sudo -H -u ${USER} qdbus $progress Set "" value 12

if [[( $SETUSER = "0" )]]
then
    sleep 0 #do nothing
else
    sudo -H -u ${USER} qdbus $progress setLabelText "Aktiviere Autologin für Benutzer Student.... "
    sudo cp /home/student/.life/stuff/sddm.conf /etc/
    sudo chown root: /etc/sddm.conf
fi


sudo -H -u ${USER} qdbus $progress Set "" value 13

if [[( $UPDATE = "0" )]]
then
    sleep 0 #do nothing
else
    sudo -H -u ${USER} qdbus $progress setLabelText "LiFE applications werden aktualisiert.... "
    exec sudo -H -u student python ~/.life/applications/life-update/main.py &
fi



sudo -H -u ${USER} qdbus $progress Set "" value 14

if [[( $UNTIS = "0" )]]
then
    sleep 0 #do nothing
else
    sudo -H -u ${USER} qdbus $progress setLabelText "WebUntis URL anpassen.... "
    
    # check if the location is actually close to something that would work
    SUBSTRING="http"
  
    askuntislocation(){
        if ! UNTISLOCATION=$(kdialog   --title "Configure WebUntis Location"  --inputbox "Bitte geben Sie ihre WebUntis URL ein !" "https://erato.webuntis.com/WebUntis/?school=bg-klu-voelkring"); 
        then
            askuntislocation
        else
            if test "${UNTISLOCATION#$SUBSTRING}" != "$UNTISLOCATION"
            then
                echo "address seems legit";          # $SUBSTRING is in $UNTISLOCATION at the beginning of the line
            sleep 0
            else
                #echo "that is not a webdav location";  # $SUBSTRING is not in $UNTISLOCATION
                kdialog --error "$UNTISLOCATION \n\nDies ist keine gültige Adresse!" --title 'Configure WebUntis Location!' 
                askuntislocation
            fi
        fi
    }
    askuntislocation
  
    if [[( $UNTISLOCATION = "" )]]
    then
        $UNTISLOCATION = "https://erato.webuntis.com/WebUntis/?school=bg-klu-voelkring"
    fi
    
    sed -i "s#\"http.*\"#\"${UNTISLOCATION}\"#g" ${HOME}/.local/share/applications/WebUntis.desktop 
    sed -i "s#\"http.*\"#\"${UNTISLOCATION}\"#g" ${HOME}/.local/share/plasma_icons/WebUntis.desktop
fi



sudo -H -u ${USER} qdbus $progress Set "" value 15

if [[( $NETZLAUFWERK = "0" )]]
then
    sleep 0 #do nothing
else
    #copy remotshare script to autostart
    cp -p  ${HOME}/.life/applications/sambamount/remoteshare  ${HOME}/.config/autostart-scripts/remoteshare
fi



sudo -H -u ${USER} qdbus $progress Set "" value 16

if [[( $AUTOCLEAN = "0" )]]
then
    sleep 0 #do nothing
else
    #copy autoclean script to plasmaworkspace/shutdown
    cp -p  ${HOME}/.life/applications/helperscripts/auto-cleanup-home.sh  ${HOME}/.config/plasma-workspace/shutdown/
fi






sudo -H -u ${USER} qdbus $progress Set "" value 17

if [[( $LOCKDESKTOP = "0" )]]
then
    sleep 0 #do nothing
else
    sudo -H -u ${USER} qdbus $progress setLabelText "Sperre den Desktop.... "
    
    if [ -f "/etc/kde5rc" ];then
        kdialog  --msgbox 'Desktop is already locked - Stopping program' --title 'LIFE' > /dev/null
        sleep 2
        exit 0
    fi

    echo "backup original files...."
    echo "backup unlocked desktop configuration.... "
    cp -a ${HOME}.config/plasmarc ${BACKUPDIR}/lockdown/
    cp -a ${HOME}.config/plasmashellrc ${BACKUPDIR}/lockdown/
    cp -a ${HOME}.config/plasma-org.kde.plasma.desktop-appletsrc ${BACKUPDIR}/lockdown/
    cp -a ${HOME}.kde/share/config/kdeglobals ${BACKUPDIR}/lockdown/
    cp -a ${HOME}.config/kwinrc ${BACKUPDIR}/lockdown/
    cp -a ${HOME}.config/kglobalshortcutsrc ${BACKUPDIR}/lockdown/

    echo "locking desktop...."
    #some preconfigured config files needed for a complete lockdown
    sudo cp ${BACKUPDIR}/lockdown/kde5rc-LOCK /etc/kde5rc
    cp -a ${BACKUPDIR}/lockdown/kglobalshortcutsrc-LOCK ${HOME}.config/kglobalshortcutsrc

    
     echo "locking systemsettings..."
    sudo chmod -x /usr/bin/systemsettings5
    
    sudo -H -u ${USER} qdbus $progress Set "" value 18

    echo "all done..."
    echo "restarting desktop...."
    sleep 1
 

    sudo killall Xorg
fi





sudo -H -u ${USER} qdbus $progress setLabelText "LIFE Client eingerichtet"  
sleep 2
sudo -H -u ${USER} qdbus $progress close




kdialog  --msgbox 'All Done!  Please Wait for ongoing operations to finish.' --title 'First Start Wizard' > /dev/null





