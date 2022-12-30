
/*$VER: Yam-GoFetch v1.0 by Mike Cardwell <mickeyc@ukonline.co.uk> (04/11/99)

**
To integrate with YAM.
1.) Go to Configuration in the Settings menu.
2.) Select "ARexx"
3.) Scroll to the bottom, and click on "When double-clicking an url"
4.) Select Arexx from the pull down menu.
5.) Type in the full path of Yam-GoFetch (Including the filename)
6.) Both tick boxes want to be unselected
7.) Fill in requested information below

Now. When double clicking an ftp:// url, the download information will
be sent to GoFetch. It will only work with URL's ending with a filename.

** ENTER USER INFORMATION BELOW **
**

********************************/
 userid="anonymous"                /* Username to log in  */
 pass  ="usually@email.address"    /* Password to log in  */
 local ="Ram:"                     /* Path to download to */
 path  ="DH1:GoFetch!/GoFetch!"    /* Path of GoFetch     */
/*******************************

 LEAVE THE SCRIPT BELOW ALONE UNLESS YOU KNOW WHAT YOU'RE DOING */

/* Check to see if correct url */

OPTIONS RESULTS
PARSE ARG url
url=STRIP(url)
IF INDEX(url,"ftp://")=0 THEN EXIT

/* Loads GoFetch if not already open */

IF SHOW(P,GOFETCH)=0 THEN DO
 ADDRESS COMMAND'Run >nil: 'path
 DO UNTIL SHOW(P,GOFETCH)=1
  ADDRESS COMMAND"Wait 1"
 END
END

/* Seperates site, directory, and filename */

url=RIGHT(url,LENGTH(url)-7)
a=POS("/",url)
site=LEFT(url,a-1)
a=LASTPOS("/",url)
file=RIGHT(url,LENGTH(url)-a)
file=LEFT(file,LENGTH(file)-1)
dir=LEFT(url,LENGTH(url)-LENGTH(file)-1)
dir=RIGHT(dir,LENGTH(dir)-LENGTH(site))

/* Sends information to GoFetch */

ADDRESS GOFETCH
'ADDPROFILE 'site' 21 'userid' 'pass' 'dir' 'file' 'local



