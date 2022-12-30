/*
** GoFetch ARexx Script
** Written By Marc Bradshaw
** for Zeus Developments
**
   v1.0 20.12.99 by Marc Bradshaw for Zeus Developments
**
** Zeus WebSite    - http://www.bleach.demon.co.uk/zeus/
** GoFetch WebSite - http://www.bleach.demon.co.uk/zeus/
** Personal Sites  - http://www.bleach.demon.co.uk/
**                   http://www.bleach.demon.co.uk/cramus/
** Zeus E-Mail     - zeus@bleach.demon.co.uk
** Personal E-Mail - dBnY@bleach.demon.co.uk
*/

/*
** Arguments are...    (see documentation for more in-depth descriptions)
**
** URL <url> - The URL of the File to be Added to GoFetch's Profile List
**
** AWEBSEL - in Which Case the Script will grab the URL from Selected Text in AWEB
**           this should be used to integrate the script with the AWEB Browser
**
** TO <download dir>
**
** PATH <path to GoFetch!> - Where is the GoFetch! EXE Located?
**
** NOREQ - Do NOT Use Requestors, for using browser.rexx in automatic scripts.
**/

Options Results

IF ~SHOW('LIBRARIES','rexxsupport.library') THEN
   Call ADDLIB('rexxsupport.library',10,-30,0)

Line=''
CommandLine = Arg(1)

/*
** Setup Some Defaults
**
** Please DONT Change These unless you Know What You Are Doing!
** The Script Gets ALL Info from the caller or from GoFetch
** You SHOULDNT NEED to alter ANY of these values.
*/

Debug       = 1 /* set to 1 when testing */
Site        = ''
Port        = 21
HTTPPort    = 80
LoginName   = 'anonymous'
Password    = 'lazy.user@didnt.configure.com'
RemotePath  = ''
LocalPath   = ''
FileName    = ''
PortName    = 'GOFETCH'
ExeName     = 'GoFetch!'
TempFile    = 'T:GoFetch_Rexx'
GoFetchPath = ''
Requestors  = 1
ReleaseNum  = 0

RequestChoicePath = WhereExe('RequestChoice')

/* Parse Command Line Arguments */

If CommandLine = '' Then CommandLine = '?'
Parse Var CommandLine CommandArg CommandLine

Do While(CommandArg~="")

    /* Does User Want Help */
    If CommandArg = '?' Then Do
        Call Output('')
        Call Output('GoFetch! browser.rexx Help')
        Call Output('')
        Call Output(Strip(SourceLine(6)))
        Call Output('')
        Call Output('rx browser.rexx [AWEBSEL | URL <url>] [TO <directory>] [PATH <path>] [?]')
        Call Output('')
        Call Output('')
        Call Output('? - Request This Help Text')
        Call Output('')
        Call Output('AWEBSEL - if run from aweb, grabs selected text as url')
        Call Output('          should not be used with the URL keyword')
        Call Output('')
        Call Output('URL <url> - the url to add as a profile')
        Call Output('            should not be used with the AWEBSEL keyword')
        Call Output('')
        Call Output('TO <directory> - direcroty to download to')
        Call Output('                 if not supplied the default as defined in')
        Call Output('                 GoFetch! will be used.')
        Call Output('')
        Call Output('PATH <path> - GoFetch! Path The Path to the GoFetch! executable')
        Call Output('              if not supplied the script will search the current')
        Call Output('              command path for GoFetch!')
        Call Output('')
        Call Output('NOREQ - Do NOT Use Requestors, (Answer YES to all things)')
        Call Output('        for using browser.rexx in automatic scripts.')
        Call Output('')
        EXIT
    End

    /* Is It An AWeb Selection Text */
    Else If Upper(CommandArg) = 'AWEBSEL' Then Do
        Ports = SHOW('P')
        PARSE VAR ports dummy 'AWEB.' portnr .
        ADDRESS VALUE 'AWEB.' || portnr
        'GET ACTIVEPORT'
        ADDRESS VALUE RESULT
        Address aweb.1
        'get selection'
        Line=RESULT
    End

    /* Is It A URL */
    Else If Upper(CommandArg) = 'URL' Then Do
        Parse Var CommandLine Line CommandLine
    End

    /* Is It A Download Directory */
    Else If Upper(CommandArg) = 'TO' Then Do
        Parse Var CommandLine LocalPath CommandLine
    End

    /* Is It the Path to GoFetch! */
    Else If Upper(CommandArg) = 'PATH' Then Do
        Parse Var CommandLine GoFetchPath CommandLine
    End

    /* Is It A NOREQ */
    Else If Upper(CommandArg) = 'NOREQ' Then Do
        Requestors = 0
    End

    /* Must Be The Legacy URL */
    Else Do
        Line=CommandArg
    End

    Parse Var CommandLine CommandArg CommandLine

End

/* If NoREQ Then NEVER Use RequestChoice */
If Requestors=0 Then Do
    RequestChoicePath = ''
End

/* Remove Surrounding Quotes */
If Left(Line,1)='"' Then
    If Right(Line,1)='"' Then
        Line=SubStr(Line,2,Length(Line)-2)

/* First We Check That GoFetch is Running */
If ~Show('P',PortName) Then Do
    /* It Isnt Running, Can We Find It In The Path? */
    If ~Exists(GoFetchPath) Then Do
        Call Alert('The Path to GoFetch! Is Incorrect.',1,'OK','',0)
        GoFetchPath = ''
    End
    If GoFetchPath = '' Then Do
        GoFetchPath = WhereExe(ExeName)
    End
    If GoFetchPath='' Then Do
        Call Alert('GoFetch! is Not Running, and Cannot Be Located. Please Load GoFetch! and Try Again',1,'OK','',1)
        EXIT 2
    End
    Else Do
        /* We Found It, Do We Run It? */
        Ret =  Alert('GoFetch! is Not Running, Run it Now?',2,'YES','NO',1)

        If Ret='1' Then Do
            Call RunGoFetch
        End
        Else Do
            Call Alert('GoFetch! Is Not Running, Please Try Again Later',1,'OK','',0)
            EXIT 3
        End
    End
End


/* OK, GoFetch is Running, Lets Get Some Defaults From It */

Interpret 'Address 'PortName' release'
ReleaseNum = RC

Interpret 'Address 'PortName' getanon'
If RC=0 Then Password = RESULT

If LocalPath = '' Then Do
    Interpret 'Address 'PortName' getdownloadpath'
    If RC=0 Then LocalPath = RESULT
End


/* Parse the FTP URL to get the needed info */

/* Is it an FTP? */
If Upper(Left(Line,6))='FTP://' Then Do
    Type = 'FTP'
    Line=Right(Line,Length(Line)-6)
End

/* Is it an HTTP? */
If Upper(Left(Line,7))='HTTP://' Then Do
    Interpret 'Address 'PortName' registered'
    If RC=0 Then Do
        Call Alert('Sorry!  Downloads of type HTTP:// require a Registered version of GoFetch!',1,'OK','',0)
        EXIT 4
    End
    If ReleaseNum<4 Then Do
        Call Alert('Sorry!  Downloads of type HTTP:// are not supported in your version of GoFetch!',1,'OK','',0)
        EXIT 4
    End
    Type='HTTP'
    Line=Right(Line,Length(Line)-7)
    Port=HTTPPort

End

/* Is it an FILE? */
If Upper(Left(Line,7))='FILE://' Then Do
    Call Alert('Sorry!  Downloads of type FILE:// are not supported.',1,'OK','',0)
    EXIT 4
End

/* No Type Indicated */
If Type='' Then Do
    Call Alert('Sorry!  Unknown Download Type.',1,'OK','',0)
    EXIT 4
End

/* Is URL Invalid? */

/* More Checking could be Included Here if thought necessary. */

If Index(Line,'/') = 0 Then Do
    Call Alert('Invalid URL, Please Check and Try Again.',1,'OK','',0)
    EXIT 5
End

If Index(Line,'@')~=0 Then
    Parse Var Line LoginName ':' Password '@' Site '/' FilePath
Else
    Parse Var Line Site '/' FilePath

FilePath = '/'FilePath
FileBreak = LastPos('/',FilePath)
RemotePath = Left(FilePath,FileBreak)
FileName   = Right(FilePath,Length(FilePath)-FileBreak)

If Index(Site,':')~=0 Then
    Parse Var Site Site ':' Port

If Debug Then Do
    Say 'Profile Type : 'Type
    Say 'Login Name   : 'LoginName
    Say 'Password     : 'Password
    Say 'Site Name    : 'Site
    Say 'Port         : 'Port
    Say 'Remote Pat h : 'RemotePath
    Say 'File Name    : 'FileName
End


If Type='FTP' Then Do
    Interpret 'Address 'PortName' '"'addprofile 'Site' 'Port' 'LoginName' 'Password' 'RemotePath' 'FileName' 'LocalPath''"''
    RetCode = RC
End
Else If Type='HTTP' Then Do
    URL = Site''RemotePath''Filename
    Interpret 'Address 'PortName' '"'addhttpprofile 'URL' 'Port' 'LocalPath''"''
    RetCode = RC
End

If RetCode~=0 Then Do
    Error = 'Undefined Internal Error, Type 'RetCode'  Please Report to Authors.'
    If RetCode = -5 then
        Error = 'You Must Register Go Fetch! To Use This Feature.'
    If RetCode = -4 then
        Error = 'Internal Error. Wrong Number of Parameters.  Please Report to Authors.'
    If RetCode = -3 then
        Error = 'Internal Error. Parameter of Wrong Type.  Please Report to Authors.'

    Call Alert(Error,1,'OK','',0)
    EXIT RetCode
End


/*
** Start Download Right Now?
*/

If ReleaseNum>3 Then Do
    Interpret 'Address 'PortName' dlstatus'
    DLStatus = RC
End
Else
    DLStatus=0

If DLStatus < 2 Then Do

    Ret=Alert('Start Download Right Now?',2,'Yes','No',1)
    If Ret='1' Then Do
        Call Output('Starting Download.')
        Interpret 'Address 'Portname' gofetch'
    End

End

Return = 0
EXIT Return





Output:
    Output_Line=Arg(1)
    Say Output_Line
    If Show('P',PortName) Then
        If ReleaseNum>3 Then
            Interpret "Address "PortName" annotate '"""Output_Line"""'"
Return





Alert:
    Alert_Title=Arg(1)
    Alert_NumArgs=Arg(2)
    Alert_First=Arg(3)
    Alert_Second=Arg(4)
    Alert_Default=Arg(5)

    Alert_Ret=Alert_Default

    Call Output(Alert_Title)
    If RequestChoicePath ~= '' Then Do
        If Alert_NumArgs=1 Then
            CommandLine = RequestChoicePath" "'"GoFetch"'" "'"'Alert_Title'"'" "'"'Alert_First'"'" >"TempFile
        Else
            CommandLine = RequestChoicePath" "'"GoFetch"'" "'"'Alert_Title'"'" "'"'Alert_First'|'Alert_Second'"'" >"TempFile
        Address Command CommandLine
        Call Open(Alert_InF,TempFile,'R')
        Alert_Ret=ReadLn(Alert_InF)
        Call Close(Alert_InF)
        Call DeleteFile(TempFile)
    End

Return Alert_Ret





WhereExe: PROCEDURE Expose TempFile
/*
** Locate A Particular Exe File
** Return The Full Path If Found
** Or Null String If Not Located.
*/
    ExeName = Arg(1)
    Options Failat 11
    Address Command
    'Which 'ExeName' >'TempFile
    Ret=RC
    Address
    If Ret=0 Then Do
        Call Open(InF,TempFile,'R')
        ReturnPath=ReadLn(InF)
        Call Close(InF)
        Call DeleteFile(TempFile)
    End
    Else Do
        ReturnPath = ''
    End
Return ReturnPath



RunGoFetch: PROCEDURE Expose GoFetchPath PortName RequestChoicePath
/*
** Runs GoFetch
*/
    /* Run GoFetch */
    Address Command 'RUN <>NIL: 'GoFetchPath
    /* Wait For Port */
    Do I=1 to 15
        Call Delay(100)
        If Show('P',PortName) Then Return
        Say 'Waiting...'
    End
    Call Alert('GoFetch! Could Not Be Started, Please Investigate and Try Again.',1,'OK','',0)
    EXIT 1
Return



DeleteFile: PROCEDURE
/*
** Deletes a File
*/
    FileName=Arg(1)

    IF SHOW('LIBRARIES','rexxsupport.library') THEN Do
        Delete FileName
    End

Return


/* The End */

