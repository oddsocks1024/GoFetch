/*
** $VER: AminetFetch.rexx 1.1 (10.12.1999) by Olivier Fabre <off@free.fr>
**
** Insert all files listed in an Aminet INDEX or RECENT file
** into GoFetch! profiles list.
** GoFetch! will be run if necessary.
**
** Template :
**   FILE=F,GETREADMES=GR/T,LOCALDIRS=LDS/T,AMINETSERVER=AS/K,AMINETPATH=AP/K,
**    LOCALDIR=LD/K,GOFETCH=GF/K
**
**   FILE
**       Name of the file containing the list of files to be
**       downloaded from Aminet (default : "AMINET_EXTRACTED").
**
**       Format of this file :
**         <filename> <dir/subdir> <whatever>
**         ...
**
**   GETREADMES/T
**       YES/ON : Download readme files (default).
**       NO/OFF : Download only the main file.
**
**   LOCALDIRS/T
**       YES/ON : Recreate the Aminet tree locally (default).
**       NO/OFF : Put all files in the same directory (LocalDir).
**
**   AMINETSERVER/K
**       Your favourite Aminet server (default : "de.aminet.net").
**
**   AMINETPATH/K
**       Path to Aminet on the server (default : "/pub/aminet/").
**       This shouldn't need to be changed.
**
**   LOCALDIR/K
**       Where to put the downloaded files (default : "DOWNLOAD:").
**
**   GOFETCH/K
**       GoFetch! location (default : "NET:GoFetch!/GoFetch!").
**
**
** Required :
**   RexxDOSSupport.library (Copyright (C) 1994-1997 by hartmut Goebel)
**   (Aminet:util/rexx/rexxdossupport.lha)
*/

/**************************************************************************/
/* Edit the following lines to suit your tastes                           */
/* These are the default options; they are overridden by the command line */
/**************************************************************************/

File         = "AMINET_EXTRACTED"		/* The Aminet filename list filename :) */
AminetServer = "de.aminet.net"			/* Your favourite Aminet server */
AminetPath   = "/pub/aminet/"				/* Path to Aminet on the server */
LocalDir     = "DOWNLOAD:"					/* Where to put the downloaded files */
LocalDirs    = 1			/* Set to 1 to recreate the Aminet tree locally, 0 otherwise */
GetReadmes   = 1			/* Set to 1 to download the readme files, 0 otherwise */
GoFetch      = "NET:GoFetch!/GoFetch!"	/* GoFetch! location */

/********************************/
/* Do not change anything below */
/********************************/


SAY "AminetFetch.rexx 1.1 (10.12.1999) by Olivier Fabre <off@free.fr>"

IF ~SHOW('L', 'rexxdossupport.library') THEN DO
	IF ~ADDLIB('rexxdossupport.library', 0, -30, 2) THEN DO
		SAY "RexxDOSSupport.library not available, go to hell :->"
		EXIT 20
	END
END

PARSE ARG args

template = "FILE=F,GETREADMES=GR/T,LOCALDIRS=LDS/T,AMINETSERVER=AS/K,AMINETPATH=AP/K,LOCALDIR=LD/K,GOFETCH=GF/K"

IF ~ReadArgs(args,template) THEN DO
	SAY "Error parsing arguments."
	SAY "Template :" template
	EXIT 20
END

IF ~EXISTS( LocalDir ) THEN DO
	SAY 'Error : The download directory "'LocalDir'" does not exist !'
	EXIT 20
END

IF ~OPEN("f",file,"R") THEN DO
	SAY 'Error : Could not open file "'file'" for reading.'
	EXIT 20
END

IF ~SHOW( "P", "GOFETCH" ) THEN DO
	SHELL COMMAND "Run" GoFetch
	SHELL COMMAND "WaitForPort GOFETCH"
	IF rc = 5 THEN DO
		SAY "Unable to run GoFetch!"
		EXIT 20
	END
END

IF LocalDirs = 0 THEN DO
	localpath = LocalDir
	IF (RIGHT( LocalDir, 1 ) ~= ":") & (RIGHT( LocalDir, 1 ) ~= "/") THEN DO
		localpath = localpath"/"
	END
END

ADDRESS GOFETCH

DO WHILE ~EOF("f")

	l = READLN( "f" )
	IF l ~= "" THEN DO

		p = POS( " ", l )
		filename = LEFT( l, p-1 )

		l = STRIP( SUBSTR( l, p ) )
		p = POS( " ", l )
		filepath = LEFT( l, p-1 )

		IF LocalDirs = 1 THEN DO
			localpath = AddPart( LocalDir, filepath )
			IF ~EXISTS( localpath ) THEN DO
				SAY "Creating the directory :" localpath
				p = LASTPOS( "/", localpath )
				IF p>1 THEN DO
					IF ~EXISTS( LEFT( localpath, p-1 ) ) THEN DO
						MakeDir( LEFT( localpath, p-1 ) )
					END
				END
				MakeDir( localpath )
			END
			localpath = localpath"/"
		END	/* IF LocalDirs */

		"ADDANONPROFILE" AminetServer 21 AddPart( AminetPath, filepath ) filename localpath

		IF GetReadmes = 1 THEN DO

			p = LASTPOS( ".", filename )
			filename = LEFT( filename, p-1 ) || ".readme"
			"ADDANONPROFILE" AminetServer 21 AddPart( AminetPath, filepath ) filename localpath

		END	/* IF GetReadmes */

	END	/* IF ~"" */

END	/* WHILE ~EOF */

SAY "Done."
