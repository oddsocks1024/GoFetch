/*
   This script reads in a batch file from amFTP and adds each
   entry from it into GoFetch! Profiles so that GoFetch!
   can be used to download the files.

Usage: 
				
    You must have a profile in Amftp for the site you
    want to download all the files from.

    Logon to that site from amftp and save a batch list
    of all the files you want to download.

    Name the Batch list the EXACT name as the Profile used
    in amftp's default batch directory.

    Then Run this script using the batch list filename as the
    argument.

		Example:  

		Save a batch of files from aminet into a file name AMINET
			in amftp's batches/ directory.  Then run the script
		Batch->GoFetch AMINET

Program:

    The program Uses the argument to load the file from amftp's batch directory.  It
    always uses the batch directory.  Then it starts reading files from
    batch list.  It finds the profile in amftp that matches the
    filename to get all the conenction information from.

    Then it creates a directory structure for the files in your download
    location that matches the deepest directory name from the site.
    This keeps everything organised.

    Then it adds all the files as profiles into GoFetch!


NOTE:   
    You will need to alter the paths in this file if you want it to 
    automatically startup GoFetch! and amftp when needed.


That's it.

Created Entirely by: 
 
    Michael King
    3D graphics modeller and animator
    mike@ethereal3d.com
    http://www.ethereal3d.com

*/


OPTIONS RESULTS
parse arg batchlist


IF ~SHOW('P', 'GOFETCH') then
DO
  address COMMAND "wbrun work:com/net/GoFetch!"
  address COMMAND "rexx:rexxc/waitforport GOFETCH"
END


IF ~SHOW('P', 'AMFTP.1') then
DO
  address COMMAND "wbrun work:com/net/amftp/amftp"
  address COMMAND "rexx:rexxc/waitforport AMFTP.1"
END

/* Open rexxsupport.library, and AMFTP Rexx-Port */
ADDLIB("rexxsupport.library",0,-30,0)
RXLIB "AMFTP.1"
ADDRESS 'AMFTP.1'

/* Create MessagePort */
CALL OPENPORT("AMFTP-RESULT.1")

/* Read the batchlist file */
OPEN('Batchfile', '/batches/'batchlist, 'R')

/* Find the matching number of the profile in amftp*/
profile_number = 0
DO while (COMPARE(MYPRF.LABEL,batchlist)>0) 
 GETPROFILE profile_number "MYPRF"
 profile_number = profile_number + 1
END
profile_number = profile_number - 1

DO WHILE( EOF('Batchfile') == 0 )
	/* Determine remote directory */
  FullFileName = READLN('Batchfile')

	if words(FullFIleName) = 0 Then break

  charstored = LASTPOS('/', FullFileName)
  OPEN('TempFILE', 'TempFILE', 'W')
  WRITECH('TempFILE', FullFileName)
  CLOSE('TempFILE')
  OPEN('TempFILE', TempFILE)
  directory = READCH('TempFILE', LASTPOS('/', FullFileName))

  /* Make a directory to match the file list */
  OPEN('TempFILE2', 'TempFILE2', 'W')
  WRITECH('TempFILE2', FullFileName)
  CLOSE('TempFILE2')
  OPEN('TempFILE2', TempFILE2)
  rootdir = READCH('TempFILE2', (LASTPOS('/', directory) -1) )
  CLOSE('TempFILE2')

  temp = LENGTH(rootdir) - LASTPOS('/', rootdir)
  mkdir = right(rootdir, temp )
	say "Found this: "MYPRF.LOCALDIR"/"mkdir
  if ~EXISTS(MYPRF.LOCALDIR'/'mkdir) THEN
    address command 'makedir >NIL: <NIL: 'MYPRF.LOCALDIR'/'mkdir
  endif

  /* Determine the file */
  DLfilename = READCH('TempFILE', (LASTPOS('|', FullFileName) - LASTPOS('/', FUllFileName) - 1) )
  CLOSE('TempFILE')
	
	localdirectory = MYPRF.LOCALDIR'/'mkdir'/'
	address 'GOFETCH'
	ADDPROFILE MYPRF.HOST MYPRF.PORT MYPRF.USERNAME MYPRF.PASSWORD directory DLfilename localdirectory

END
CLOSE('Batchfile')

/* Close our MessagePort */
CALL CLOSEPORT "AMFTP-RESULT.1"
