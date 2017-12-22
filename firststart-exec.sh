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
INSTALLREADER=$7       #install adobe reader 
BLOCKPACKAGES=$8        #for live usb block upgrades and installations of gub and kernel
SHAREMOUNT=$9           #mount share partition (fat32) to /home/student/SHARE
ROOTPW=${10}            #set password for user student
SETUSER=${11}           #set user student autologin to true (life does not work with other usernames atm.)
UPDATE=${12}           #update life applications



if [ "$(id -u)" != "0" ]; then
    kdialog  --msgbox 'You need root privileges - Stopping program' --title 'LIFE' --caption "LIFE" > /dev/null
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
#exit 0
 
progress=$(kdialog --progressbar "Paktetlisten werden aktualisiert....                                                              ");






qdbus $progress Set "" maximum 15

if [[( $UPDATESOURCES = "0" )]]
then
    sleep 0 #do nothing
else
    qdbus $progress Set "" value 1
    sudo apt update
    qdbus $progress Set "" value 2
    sudo apt clean
    sudo apt-get clean
fi








qdbus $progress Set "" value 3

if [[( $UPDATESOURCES = "0" )]]
then
    sleep 0 #do nothing
else
    qdbus $progress setLabelText "APT Index wird aktualisiert...."
    sudo update-apt-xapian-index -f
fi









qdbus $progress Set "" value 4

if [[( $CREATESSHKEYS = "0" )]]
then
    sleep 0 #do nothing
else
    qdbus $progress setLabelText "SSH Schlüssel werden generiert...."
    cd /etc/ssh
    sudo rm -f *_key*
    sudo ssh-keygen -t dsa -f /etc/ssh/ssh_host_dsa_key -N ''
    sudo ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N ''
    sudo ssh-keygen -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -N ''
fi












qdbus $progress Set "" value 5

if [[( $CHANGEWEBDAVURL = "0" )]]
then
    sleep 0 #do nothing
    #WEBDAVLOCATION="https://owncloud.europagymnasium.at/remote.php/webdav"
else

    qdbus $progress setLabelText "Konfiguriere Webdav Location.... "

    # check if the location is actually close to something that would work
    SUBSTRING="http"

    askwebdavlocation(){
        if ! WEBDAVLOCATION=$(kdialog  --caption "Configure Webdav Location" --title "Configure Webdav Location"  --inputbox "Bitte bestätigen Sie die URL ihres WEBDAV Ordners!" "https://owncloud.europagymnasium.at/remote.php/webdav"); 
        then
            askwebdavlocation
        else
            if test "${WEBDAVLOCATION#$SUBSTRING}" != "$WEBDAVLOCATION"
            then
                echo "address seems legit";          # $SUBSTRING is in $WEBDAVLOCATION at the beginning of the line
            sleep 0
            else
                #echo "that is not a webdav location";  # $SUBSTRING is not in $WEBDAVLOCATION
                kdialog --error "$WEBDAVLOCATION \n\nDies ist keine gültige Webdav Adresse!" --title 'Configure Webdav Location!' --caption "Configure Webdav Location"
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
fi










qdbus $progress Set "" value 6

if [[( $CHANGEHOSTNAME = "0" )]]
then
    sleep 0 #do nothing
else
    qdbus $progress setLabelText "Ändere den Hostnamen.... "

    if ! HOST=$(kdialog  --caption "HOSTNAME" --title "HOSTNAME"  --inputbox "Bitte geben sie einen HOSTNAMEN an" "life"); 
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







qdbus $progress Set "" value 7

if [[( $INSTALLRESTRICTED = "0" )]]
then
    sleep 0 #do nothing
else
    qdbus $progress setLabelText "Installiere Schriftarten und Plugins.... "
    bar(){
        sudo apt-get -y install ttf-bitstream-vera  ttf-dejavu ttf-xfree86-nonfree kubuntu-restricted-extras
    }
    export -f bar
    exec xterm -title firststart -e bar&
fi




qdbus $progress Set "" value 8

if [[( $BLOCKPACKAGES = "0" )]]
then
    sleep 0 #do nothing
else
    qdbus $progress setLabelText "Blockiere Bootloader- und Kernelupgrades.... "
    echo -e "Package: grub*\nPin: release *\nPin-Priority: -1\n" > /etc/apt/preferences
    echo -e "Package: grub*:i386\nPin: release *\nPin-Priority: -1\n" >> /etc/apt/preferences
    echo -e "Package: linux-image*\nPin: release *\nPin-Priority: -1\n" >> /etc/apt/preferences
    echo -e "Package: linux-image*:i386\nPin: release *\nPin-Priority: -1\n" >> /etc/apt/preferences
   
fi


qdbus $progress Set "" value 9

if [[( $SHAREMOUNT = "0" )]]
then
    sleep 0 #do nothing
else
    qdbus $progress setLabelText "Making SHARE mount permanent...."
    
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
    
    sudo sed -i "/SHARE/c\\LABEL=SHARE     /home/student/SHARE     vfat    rw,nofail,x-systemd.device-timeout=1,uid=1000,gid=1000,umask=0022,codepage=437,iocharset=iso8859-1,shortname=mixed    0       0" $FSTABETC
    
    sudo chattr +i ${MOUNTPOINTCASPER}/upper/etc/fstab   #make immutable because on live devices this is overwritten on boot otherwise
 
    sudo umount $MOUNTPOINTCASPER
    

    echo "---------------------------------------------"
    echo "SHARE mount  written to fstab!"
    echo "---------------------------------------------"
    cat /etc/fstab
    echo "---------------------------------------------"
    

    
fi



qdbus $progress Set "" value 10

if [[( $INSTALLREADER = "0" )]]
then
    sleep 0 #do nothing
else
    qdbus $progress setLabelText "Installiere Adobe reader.... "
    foobar(){
        wget ftp://ftp.adobe.com/pub/adobe/reader/unix/9.x/9.5.5/enu/AdbeRdr9.5.5-1_i386linux_enu.deb
        sudo apt install libxml2:i386
        sudo apt install libgtk2.0-0:i386
        sudo dpkg -i AdbeRdr9.5.5-1_i386linux_enu.deb
        sudo apt-get -f install
        rm AdbeRdr9.5.5-1_i386linux_enu.deb
    }
    export -f foobar
    exec xterm -title firststart -e foobar&
fi


qdbus $progress Set "" value 11

if [[( $ROOTPW = "0" )]]
then
    sleep 0 #do nothing
else
    qdbus $progress setLabelText "Neues Passwort setzen.... "
    
    
    PW="empty"
    getROOT(){
        PASSWD1=$(kdialog  --caption "LIFE" --title "LIFE" --inputbox "Geben sie bitte das gwünschte Benutzer-Passwort an!");
        if [ "$?" = 0 ]; then
            PASSWD2=$(kdialog  --caption "LIFE" --title "LIFE" --inputbox 'Geben sie bitte das gewünschte Benutzer-Passwort ein zweites mal an!');
            if [ "$?" = 0 ]; then
            
                if [ "$PASSWD2" = "$PASSWD1"  ]; then
                    sudo -u ${USER} kdialog  --caption "LIFE" --title "LIFE" --passivepopup "Passwort OK!" 3
                    PW=$PASSWD1
                else
                    kdialog  --caption "LIFE" --title "LIFE" --error "Die Passwörter sind nicht ident!"
                    getROOT 
                fi
            else
                kdialog  --caption "LIFE" --title "LIFE" --error "Kein Password gesetzt!"
                sleep 0
            fi
        else
            kdialog  --caption "LIFE" --title "LIFE" --error "Kein Password gesetzt!"
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



qdbus $progress Set "" value 12

if [[( $SETUSER = "0" )]]
then
    sleep 0 #do nothing
else
    qdbus $progress setLabelText "Aktiviere Autologin für Benutzer Student.... "
    sudo cp /home/student/.life/stuff/sddm.conf /etc/
    sudo chown root: /etc/sddm.conf
fi


qdbus $progress Set "" value 13

if [[( $UPDATE = "0" )]]
then
    sleep 0 #do nothing
else
    qdbus $progress setLabelText "LiFE applications werden aktualisiert.... "
    exec sudo -H -u student python ~/.life/applications/life-update/main.py &
fi




qdbus $progress Set "" value 14

if [[( $LOCKDESKTOP = "0" )]]
then
    sleep 0 #do nothing
else
    qdbus $progress setLabelText "Sperre den Desktop.... "
    
    if [ -f "/etc/kde5rc" ];then
        kdialog  --msgbox 'Desktop is already locked - Stopping program' --title 'LIFE' --caption "LIFE" > /dev/null
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

    qdbus $progress Set "" value 15

    echo "all done..."
    echo "restarting desktop...."
    sleep 1
 
    sudo -u ${USER} -H kquitapp5 plasmashell &
    sleep 2
    exec sudo -u ${USER} -H kstart5 plasmashell &
    sleep 2
    exec sudo -u ${USER} -H kwin --replace &
fi





qdbus $progress setLabelText "LIFE Client eingerichtet"  
sleep 2
qdbus $progress close




kdialog  --msgbox 'All Done!  Please Wait for ongoing operations to finish.' --title 'First Start Wizard' --caption "First Start Wizard" > /dev/null





