#! /usr/bin/env python
# -*- coding: utf-8 -*-
import sys, os
import socket
from PyQt5 import QtCore, uic, QtWidgets
from PyQt5.QtGui import *

import threading
import time


class InetChecker(threading.Thread):
    """ in order to provide a NONBLocking loop that 
    periodically checks the internet connection 
    this is done it a separate thread
    """
    def __init__(self, mainui):
        threading.Thread.__init__(self)
        self.mainui= mainui

    def run(self):
        while self._checkOnline() == False:
            time.sleep(5)
            self._checkOnline()

    def _checkOnline(self):
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            s.connect(("gmail.com",80))
            s.close()
            print "online"
            self.mainui.onsignal.emit()
            return True
        except:
            print "offline"
            self.mainui.offsignal.emit()
            return False






class MeinDialog(QtWidgets.QDialog):
    onsignal = QtCore.pyqtSignal()   # use signals and slots to talk between the UI dialog and the python thread otherwise it will throw warnings all over the place
    offsignal = QtCore.pyqtSignal()
        
    def __init__(self):
        QtWidgets.QDialog.__init__(self)
        scriptdir=os.path.dirname(os.path.abspath(__file__))
        uifile=os.path.join(scriptdir,'firststart.ui')
        winicon=os.path.join(scriptdir,'drive.png')
        
        self.ui = uic.loadUi(uifile)        # load UI
        self.ui.setWindowIcon(QIcon(winicon))
        self.ui.exit.clicked.connect(self.onAbbrechen)        # setup Slots
        self.ui.start.clicked.connect(self._startConfig)
        #self.onsignal.connect(lambda: self.uienable())    #setup custom slots
        #self.offsignal.connect(lambda: self.uidisable())

    
    def uienable(self):  # activates all internet related options
        self.ui.infolabel.setText("Wählen Sie aus nachfolgenden Aktionen!")
        self.ui.sources.setEnabled(True)
        self.ui.sources.setChecked(True)
        self.ui.sources.setStyleSheet('color: #000;')
        self.ui.sources.setStyleSheet("""QToolTIP {color: #fff;}""")
        self.ui.restricted.setEnabled(True)
        self.ui.restricted.setChecked(True)
        self.ui.restricted.setStyleSheet('color: #000;')
        self.ui.restricted.setStyleSheet("""QToolTIP {color: #fff;}""")
        self.ui.areader.setEnabled(True)
        self.ui.areader.setStyleSheet('color: #000;')
        self.ui.areader.setStyleSheet("""QToolTIP {color: #fff;}""")
        return


    def uidisable(self):   #deactivates all internet related options
        self.ui.infolabel.setText("<b>Bitte überprüfen sie die Internetanbindung!</b>")
        self.ui.sources.setEnabled(False)
        self.ui.sources.setChecked(False)
        self.ui.restricted.setEnabled(False)
        self.ui.restricted.setChecked(False)
        self.ui.areader.setEnabled(False)
        self.ui.areader.setChecked(False)
        return


    def _startConfig(self):
            scriptdirectory=os.path.dirname(os.path.realpath(__file__))
            command = "%s/firststart-exec.sh %s %s %s %s %s %s %s %s %s %s %s" %(scriptdirectory,
                                                                              self.ui.sources.checkState(),
                                                                              self.ui.webdav.checkState(),
                                                                              self.ui.ssh.checkState(),
                                                                              self.ui.hostname.checkState(),
                                                                              self.ui.lock.checkState(),
                                                                              self.ui.restricted.checkState(),
                                                                              self.ui.areader.checkState(),
                                                                              self.ui.block.checkState(),
                                                                              self.ui.share.checkState(),
                                                                              self.ui.rootpw.checkState(), 
                                                                              self.ui.setuser.checkState() 
                                                                              )
            print command
            self.ui.close()
            os.system(command)
            os._exit(0)

    
    def onAbbrechen(self):    # Exit button
        self.ui.close()
        os._exit(0)




app = QtWidgets.QApplication(sys.argv)
dialog = MeinDialog()
dialog.ui.show()   #show user interface
inet = InetChecker(dialog)
inet.start()   #start inet checking thread
sys.exit(app.exec_())
