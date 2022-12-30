/*
** $VER: AminetExtract.rexx 1.0 (10.12.1999) by Olivier Fabre <off@free.fr>
**
** Extract selected lines out of an Aminet INDEX based on date and/or type
**
** Template :
**   IF=INDEXFILE,EF=EXTRACTFILE,FW=FIRSTWEEK/N,LW=LASTWEEK/N,NT=NOTYPE/S,T=TYPE/M
**
**   INDEXFILE
**       INDEX file name.
**       Default : "INDEX".
**
**   EXTRACTFILE
**       Destination file name.
**       Default : "AMINET_EXTRACTED".
**
**   FIRSTWEEK/N
**       Oldest week, numbered from 0 (current week) to x (x weeks old).
**       Default : 52
**
**   LASTWEEK/N
**       More recent week, numbered from 0 (current week) to x (x weeks old).
**       Default : 0
**
**     NB : "current week" means "the week the INDEX file was created" of course...
**
**   TYPE/M
**       The type of files to extract, in the form "dir/subdir" or "dir".
**       Default : all types.
**
**   NOTYPE/S
**       If set, the files of the given type will NOT be included in the list.
**
** Requires :
**   RexxDOSSupport.library (Copyright (C) 1994-1997 by hartmut Goebel)
**   (Aminet:util/rexx/rexxdossupport.lha)
*/

/**************************************************************************/
/* Edit the following lines to suit your taste                            */
/* These are the default options; they are overridden by the command line */
/**************************************************************************/

IndexFile   = "INDEX"
ExtractFile = "AMINET_EXTRACTED"
FirstWeek   = 52
LastWeek    = 0
NoType      = 0				/* Set to 1 to NOT include files of the given Type */
Type.count  = 0				/* Set to the number of types */
/* Type.0      = "comm"			*/	/* List types from Type.0 to Type.x */
/* Type.1      = "biz/dopus"	*/

/********************************/
/* Do not change anything below */
/********************************/


SAY "AminetExtract.rexx 1.0 (10.12.1999) by Olivier Fabre <off@free.fr>"

IF ~SHOW('L', 'rexxdossupport.library') THEN DO
	IF ~ADDLIB('rexxdossupport.library', 0, -30, 2) THEN DO
		SAY "RexxDOSSupport.library not available, go to hell :->"
		EXIT 20
	END
END

PARSE ARG args

template = "INDEXFILE=IF,EXTRACTFILE=EF,FIRSTWEEK=FW/N,LASTWEEK=LW/N,NOTYPE=NT/S,TYPE=T/M"

IF ~ReadArgs(args,template) THEN DO
	SAY "Error parsing arguments."
	SAY "Template :" template
	EXIT 20
END

IF ~OPEN( "idx", IndexFile, "R" ) THEN DO
	SAY 'Error opening "'IndexFile'" for reading.'
	EXIT 20
END

IF ~OPEN( "rec", ExtractFile, "W" ) THEN DO
	SAY 'Error opening "'ExtractFile'" for writing.'
	EXIT 20
END


/* Skip the headers */

DO WHILE ~EOF( "idx" )
	l = READLN( "idx" )
	IF SUBSTR( l, 2, 5 ) = "-----" THEN BREAK
END


/* Scan file */

DO WHILE ~EOF( "idx" )

	l = READLN( "idx" )
	week = SUBSTR( l, 36, 3 )
	IF (week <= FirstWeek) & (week >= LastWeek) THEN DO

		flag = 1
		IF Type.count > 0 THEN DO
			flag = NoType
			type2 = SUBSTR( l, 20, 10 )
			type1 = LEFT( type2, POS( "/", type2 )-1 )
			DO i=0 TO Type.count-1
				IF Type.i = type1 | Type.i = type2 THEN DO
					flag = 1-NoType
					BREAK
				END
			END
		END	/* IF Type.count */

		IF flag=1 THEN WRITELN( "rec", l )

	END	/* IF week */

END	/* WHILE ~EOF */

SAY "Done."
