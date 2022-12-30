/* $VER:Batch2GoFetch.rexx 0.8ß (04 Nov 99) Steve Bridges 
** 
** Stephen Bridges    <steve@bh01.demon.co.uk>
**
** An Arexx script to use GoFetch to batch download files from
** Aminet from a created file. (For use with yam2gofetch.rexx)
**
*/

OPTIONS RESULTS

/*
** INSTRUCTIONS
**
** Alter the path to GoFetch and Miami to suit your set-up.
** Change the Miami settings for your set-up.
** Fill in the address of your nearest Aminet site.
** Also you will need to enter the path to the batchfile that was
** created with yam2gofetch.rexx.
*/

gofetch_path = 'AmiTCP:GoFetch/GoFetch!'
miami_path =   'AmiTCP:Miami/Miami'
settings =     'Miami:Miami.default'

site =         'ftp.demon.co.uk'

batch_file =   'Yam:gofetch.batch'

/*
** DO NOT CHANGE ANYTHING BELOW HERE UNLESS YOU KNOW WHAT
** YOU ARE DOING, ALTHOUGH THAT DIDN'T STOP ME. :-)
*/

/* Initialisation */

port =     '21'

FTP_PORT = 'GOFETCH'
TCP_PORT = 'MIAMI.1'

title =             'batch2gofetch.rexx 0.8ß by Steve Bridges'
g_error_text =      'ERROR:  Unable to launch GoFetch' ||'0a'x|| 'Did you amend the path in the script?' 
b_error_text =      'ERROR:  Unable to find 'batch_file'' ||'0a'x|| '  Did you amend the settings in the script?'
d_error_text =      'ERROR:  Unable to delete 'batch_file'' 
m_error_text =      'ERROR:  Unable to launch Miami' ||'0a'x|| 'Did you amend the path in the script?'
m_on_error_text =   'ERROR:  Miami unable to go on-line' ||'0a'x|| 'Is your modem switched on and plugged in? :-)'
m_set_error_text =  'ERROR:  Miami unable to load settings' ||'0a'x|| 'Did you amend the settings in the script?'

exit_buttons = '_Exit'

/* Check if rexxreqtools.library/rexxsupport.library is installed */

IF ~EXISTS('Libs:rexxreqtools.library') THEN CALL library_error()
IF ~EXISTS('Libs:rexxsupport.library') THEN CALL library_error()

/* Add rexxreqtools.library/rexxsupport.library to functions */

IF ~SHOW('L','rexxreqtools.library') THEN ADDLIB('rexxreqtools.library', 5, -30, 0)
IF ~SHOW('L','rexxsupport.library') THEN ADDLIB('rexxsupport.library', 0, -30, 0)

/* Open Batchfile */

IF ~OPEN('created_file',batch_file,'R') THEN CALL SCRIPT_ERROR(b_error_text)

/* Get Miami running */

IF ~SHOW('P',TCP_PORT) THEN DO
 ADDRESS COMMAND
 'RUN >NIL:' miami_path nogui
 'SYS:rexxc/WaitForPort' TCP_PORT
 IF RC>0 THEN CALL SCRIPT_ERROR(m_error_text)
END

/* Miami Online */

ADDRESS (TCP_PORT)
LOADSETTINGS settings
IF RC>0 THEN CALL SCRIPT_ERROR(m_set_error_text)
ISONLINE
IF RC=0 THEN DO
 ONLINE
 ISONLINE
 IF RC=0 THEN CALL SCRIPT_ERROR(m_on_error_text)
END

/* Get GoFetch Running */

IF ~SHOW('P',FTP_PORT) THEN DO
 ADDRESS COMMAND
 'RUN >NIL:' gofetch_path
 'SYS:rexxc/WaitForPort' FTP_PORT
 IF RC>0 THEN CALL SCRIPT_ERROR(g_error_text)
END

/* Get settings from GoFetch! */

ADDRESS (FTP_PORT)
GETDOWNLOADPATH
localpath = RESULT

/* Create profile list in GoFetch! */

DO UNTIL EOF('created_file')
 remotepath = READLN('created_file')
 filename = READLN('created_file')
 ADDPROFILE site port remotepath filename localpath
END

CALL CLOSE('created_file')

/* Go get the files */

GOFETCH
/*
DO UNTIL finished = 1
 DOWNLOADING?????
 finished = RESULT
 CALL DELAY(5*50)     ***This bit needs re-doing as and when you add the appropriate command***
END

/* Quit GoFetch! */

QUITGOFETCH 
*/

/* Delete Batchfile */

IF ~DELETE(batch_file) THEN CALL SCRIPT_ERROR(d_error_text)

EXIT 

/* ----------Create function() script_error---------- */

script_error:

PARSE ARG text

error = RTEZREQUEST(text,exit_buttons,title,,)
IF error=0 THEN EXIT

/* ----------Create function() library_error---------- */

library_error:

DO
 ADDRESS COMMAND
 'C:RequestChoice PUBSCREEN="Workbench" TITLE="batch2gofetch.rexx v0.8ß by Steve Bridges" BODY=" Could not execute Arexx script. *n Please check you have rexxreqtools.library *n and rexxsupport.library installed in Libs:" GADGETS="Exit" >NIL:'
 IF RC=0 THEN EXIT
END
