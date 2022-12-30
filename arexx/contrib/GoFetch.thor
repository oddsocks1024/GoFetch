/*
	$VER: GoFetch.thor 1.0 (11.12.99)
	by Neil Bothwick

	Runs GoFetch.br for the current system
	Can be called from the Arexx menu or as a system exit event
*/

/* Initialise */
options results
thorport = address()
if left(thorport,5) ~= 'THOR.' then do
	say 'GoFetch.thor must be run from within Thor.'
	exit
	end

if ~show('p', 'BBSREAD') then do
	address command
	'run >nil: `GetEnv THOR/THORPath`bin/LoadBBSRead'
	'WaitForPort BBSREAD'
	end

/* Get current system name and arexx directory */
address(thorport)
drop TMP.
'CURRENTSYSTEM stem TMP'
System = TMP.BBSNAME

/* Run GoFetch.br */
address command 'rx rexx/GoFetch.br' System

