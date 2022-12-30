/* $VER:Yam2GoFetch!.rexx 0.8ß (04 Nov 99) Steve Bridges
** 
** Stephen Bridges    <steve@bh01.demon.co.uk>
**
** An Arexx script to use GoFetch! to batch download Aminet files
** from any Aminet recent file by pasting them in with Powersnap.
**
*/

OPTIONS RESULTS

/*
** INSTRUCTIONS
**
** Please alter the path to GoFetch! and Miami to suit your set-up.
** Change the Miami settings for your set-up.
** Please enter the address and path to your nearest Aminet site.
** Also enter the path/filename where you want the batchfile to be saved.
*/

gofetch_path = 'AmiTCP:GoFetch/GoFetch!'
miami_path =   'AmiTCP:Miami/Miami'
settings =     'Miami:Miami.default'

site =         'ftp.demon.co.uk'
dir_address =  '/pub/mirrors/aminet/'

batch_path =   'Yam:gofetch.batch'

/*
** DO NOT CHANGE ANYTHING BELOW HERE UNLESS YOU KNOW WHAT
** YOU ARE DOING, ALTHOUGH THAT DIDN'T STOP ME. :-)
*/

/* Initialisation */

port =     '21'

FTP_PORT = 'GOFETCH'
TCP_PORT = 'MIAMI.1'

temp_path = 'Ram:T/gofetch.batch'

title =            'yam2gofetch!.rexx 0.8ß by Steve Bridges'
path_text =        '  Please paste in a file and directory  '
save_text =        'Do you want to get those files now' ||'0a'x|| 'or save the batchfile and get them' ||'0a'x|| 'later with batch2gofetch!.rexx?'
add_text =         ''batch_path' already exists,' ||'0a'x|| 'do you want to add to it or replace it?'

f_error_text =     'ERROR:  You clipped the wrong bit,' ||'0a'x|| 'you need the the whole line up to the size'

g_error_text =     'ERROR:  Unable to launch GoFetch' ||'0a'x|| 'Did you amend the path in the script?'
m_error_text =     'ERROR:  Unable to launch Miami' ||'0a'x|| 'Did you amend the path in the script?'
m_on_error_text =  'ERROR:  Miami unable to go on-line' ||'0a'x|| 'Is your modem switched on and plugged in? :-)'
m_set_error_text = 'ERROR:  Miami unable to load settings' ||'0a'x|| 'Did you amend the settings in the script?'
t_error_text =     'ERROR:  Unable to open 'temp_path' for reading' ||'0a'x|| 'Something is badly wrong, please get in touch'
old_error_text =   'ERROR:  Unable to open 'batch_path' for writing' ||'0a'x|| 'Did you amend the settings in the script?'
d_error_text =     'ERROR:  Unable to delete 'temp_path'' ||'0a'x|| 'Something has a lock on 'temp_path''  
open_error_text =  'ERROR:  Unable to open 'temp_path' for writing' ||'0a'x|| 'Something is badly wrong, please get in touch'

exit_buttons =           '_Exit'
save_or_get_buttons =    '_Now|_Save'
add_or_replace_buttons = '_Add|_Replace|_Exit'

another_buttons =        'Another|Last One|Exit'

/* Check if rexxreqtools.library/rexxsupport.library is installed */

IF ~EXISTS('Libs:rexxreqtools.library') THEN CALL LIBRARY_ERROR()
IF ~EXISTS('Libs:rexxsupport.library') THEN CALL LIBRARY_ERROR()

/* Add rexxreqtools.library/rexxsupport.library to functions */

IF ~SHOW('L','rexxreqtools.library') THEN ADDLIB('rexxreqtools.library', 5, -30, 0)
IF ~SHOW('L','rexxsupport.library') THEN ADDLIB('rexxsupport.library', 0, -30, 0)

/* Open file for batch */

IF ~OPEN('batch_file',temp_path,'W') THEN CALL SCRIPT_ERROR(open_error_text)

/*  Get the files */

DO UNTIL go_on = 2
 go_on = get_address()
END

CALL CLOSE('batch_file')
  
/* Ask if the user wants to get them now? */

save_or_get = RTEZREQUEST(save_text,save_or_get_buttons,title,,)
IF save_or_get = 0 THEN DO

/* Add new additions to batchfile */

 IF EXISTS(batch_path) THEN DO
  add_or_replace = RTEZREQUEST(add_text,add_or_replace_buttons,title,,)
  IF add_or_replace = 0 THEN EXIT
  IF add_or_replace = 1 THEN DO
   IF ~OPEN('old_file',batch_path,'A') THEN CALL SCRIPT_ERROR(old_error_text)
   IF ~OPEN('batch_file',temp_path,'R') THEN CALL SCRIPT_ERROR(open_error_text)
   file = READCH('batch_file',65535)
   CALL WRITECH('old_file',file)
   CALL CLOSE('batch_file')
   CALL CLOSE('old_file')
  END
 END
 
/* Save batchfile */

 IF ~EXISTS(batch_path) | add_or_replace = 2 THEN DO 
  ADDRESS COMMAND
  'SYS:C/COPY 'temp_path' to 'batch_path''
  IF ~DELETE(temp_path) THEN CALL SCRIPT_ERROR(d_error_text)
 END
 EXIT
END
 
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

/* Open file in T: */

IF ~OPEN('created_file',temp_path,'R') THEN CALL SCRIPT_ERROR(t_error_text)

/* Get settings from GoFetch! */

ADDRESS (FTP_PORT)
GETDOWNLOADPATH
localpath = RESULT

/* Create profile list in GoFetch! */

DO UNTIL EOF('created_file')
 remotepath = READLN('created_file')
 filename = READLN('created_file')
 ADDANONPROFILE site port remotepath filename localpath
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
/* Delete file in T: */

IF ~DELETE(temp_path) THEN CALL SCRIPT_ERROR(d_error_text)

EXIT

/* ----------Create function() script_error---------- */

script_error:

PARSE ARG text

error = RTEZREQUEST(text,exit_buttons,title,,)
IF error=0 THEN EXIT

/* ----------Create get_address function()---------- */

get_address:

/* Put up string requester */

site_address = RTGETSTRING(,path_text,title,another_buttons,,)
last_one = RTRESULT
IF last_one = 0 THEN EXIT

/* Check string for correct clip */

IF ~CHECK_ERROR(site_address) THEN CALL SCRIPT_ERROR(f_error_text)

/* Pull apart the string and rearrange */

site_address = LEFT(site_address,30)
site_address = COMPRESS(site_address)

lha_pos = POS('.lha',site_address)

file_name = LEFT(site_address,lha_pos+3)
path_name = SUBSTR(site_address,lha_pos+4)
path_name = dir_address||path_name||'/'
full_name = path_name||file_name

/* Build up the batch file */

CALL WRITELN('batch_file' ,path_name)
CALL WRITELN('batch_file' ,file_name)

RETURN last_one

/*  ---------Create error_checking function()----------*/

check_error: PROCEDURE
 
ARG next_line

/*Check string for correct clip */

gap_pos1 = SUBSTR(next_line,19,1)
IF gap_pos1 ~= ' ' THEN c = 0
ELSE c = 1

slash_pos = POS("/",next_line)
IF slash_pos~=23 & slash_pos~=24 THEN d = 0
ELSE d = 1

IF c = 1 & d = 1 THEN RETURN 1
ELSE RETURN 0

/* ----------Create library_error function()---------- */

library_error:

DO
 ADDRESS COMMAND
 'C:RequestChoice PUBSCREEN="Workbench" TITLE="yam2gofetch!.rexx v0.8ß by Steve Bridges" BODY=" Could not execute Arexx script. *n Please check you have rexxreqtools.library *n and rexxsupport.library installed in Libs:" GADGETS="Exit" >NIL:'
 IF RC=0 THEN EXIT
END
