OPT PREPROCESS
OPT OSVERSION=39

-> Go Fetch by Ian Chapman (c) 2002
-> Version 1.3

/*********************************************************************
TO DO LIST:                                                          *
1. Fix Error 48 problem which sometimes occurs when binding socket   *
*********************************************************************/


MODULE  'socket_pragmas',
        'amitcp/sys/socket',
        'amitcp/sys/types',
        'amitcp/sys/time',
        'amitcp/netdb',
        'amitcp/netinet/in',
        'muimaster',
        'libraries/mui',
        'dos/dos',
        'amigalib/boopsi',
        'utility/tagitem',
        'utility/hooks',
        'intuition/classusr',
        'libraries/gadtools',
        'reqtools',
        'libraries/reqtools',
        'tools/installhook',
        'rexx/storage',
        'icon',
        'logo',
        'workbench/workbench',
        'intuition/intuition',
        'gadtools',
        'graphics/text',
        'libraries/gadtools',
        'intuition/screens',
        'oomodules/softtimer_oo'

OBJECT prefs
beep:LONG
keepalive:LONG
showprofs:LONG
retain:LONG
retaintout:LONG
retainfnf:LONG
getonnoresume:LONG
ENDOBJECT


#define ibt(i)\
  ImageObject,\
    ImageButtonFrame,\
    MUIA_Background, MUII_ButtonBack,\
    MUIA_InputMode , MUIV_InputMode_RelVerify,\
    MUIA_Image_Spec, i,\
    End

#define ibu(i)\
  ImageObject,\
    ImageButtonFrame,\
    MUIA_Background, MUII_ButtonBack,\
    MUIA_InputMode , MUIV_InputMode_Toggle,\
    MUIA_Image_Spec, i,\
    End


CONST RELEASE=7, HYPHEN=45, FSLASH=47, SPACE=32, TR_ADDREQUEST=9

ENUM    ERR_NORMALEXIT=50, ERR_NOBSD, ERR_NOCONNECT, ERR_NOICON, ERR_NOLOC, ERR_NOGAD ->Main Enums
ENUM    ERR_NOMUI=1, ERR_NOAPP, ERR_NOREQ ->MUI ENUMS
ENUM    ID_ADD=1, ID_EDIT, ID_DELETE, ID_GO, ID_OK, ID_ABORT, ID_FREQ, ID_SAVELOG,
        ID_ABOUT, ID_CANCEL, ID_CHECKON, ID_CHECKOFF, ID_STOP, ID_ICONIFY,
        ID_MUISET, ID_MUIABOUT, ID_POPSITEDIR, ID_POPSITEDIROFF, ID_FILLINSITE,
        ID_MINISHOW, ID_MINIHIDE, ID_SAVEPREFS, ID_BEEPON,
        ID_BEEPOFF, ID_HTTPOK, ID_KEEPALIVEON, ID_KEEPALIVEOFF, ID_SHOWPROFSON,
        ID_SHOWPROFSOFF, ID_RETAINON, ID_RETAINOFF, ID_RETAINTOON,
        ID_RETAINTOOFF, ID_RETAINFNFON, ID_RETAINFNFOFF, ID_GETONNORESUMEON,
        ID_GETONNORESUMEOFF, PROTOCOL_FTP, PROTOCOL_HTTP, ID_PREFSFREQ,
        ID_DONOWT
ENUM CMD_FAIL=100, CMD_PASS, XFER_OK, XFER_FAIL, CMD_NOQUIT, CMD_FILENOTFOUND
ENUM ST_XFEROK=250, ST_TIMEOUT, ST_NOCONNECT

DEF sock,
    sain:PTR TO sockaddr_in,
    app,
    mui_iolist,
    mui_profilelist,
    mui_stopbutton,
    mui_addwindow,
    mui_editwindow,
    mui_mainwindow,
    mui_profilelv,
    mui_historylist,
    mui_prefsbeep,
    mui_prefskeepalive,
    mui_prefsshowprofs,
    mui_prefsretain,
    mui_prefsretaintout,
    mui_prefsretainfnf,
    mui_prefsgetonnoresume,
    mui_cpsrate,
    signal,
    sizecmdsuccess=FALSE,
    running=TRUE,
    xferport=5,
    nextprofile=NIL,
    res=NIL,
    xferfilelen=0,
    site[500]:STRING,
    port[20]:STRING,
    username[500]:STRING,
    password[500]:STRING,
    remotepath[500]:STRING,
    filename[500]:STRING,
    localpath[500]:STRING,
    freqpath[500]:STRING,
    anonpass[500]:STRING,
    deflocalpath[500]:STRING,
    defpubscr[30]:STRING,
    httpsite[500]:STRING,
    httpport[500]:STRING,
    httplocalpath[500]:STRING,
    minilogbuffer[60]:STRING,
    minilogwin=NIL:PTR TO window,
    st:PTR TO softtimer,
    dlstatus=NIL,
    p:prefs,
    alivetransfer=0,
    ref_refreshhook:hook,
    list_proflisthook:hook,
    prefsxferbuffer=100,
    prefstimeout = 20

PROC main() HANDLE
DEF mui_addbutton,
    mui_editbutton,
    mui_deletebutton,
    mui_gobutton,
    mui_iolv,
    mui_sitestring,
    mui_usernamestring,
    mui_passwordstring,
    mui_remotepathstring,
    mui_filenamestring,
    mui_localpathstring,
    mui_okbutton,
    mui_cancelbutton,
    mui_freqbutton,
    mui_savelogbutton,
    mui_clearlogbutton,
    mui_portstring,
    mui_checkmark,
    mui_quitbutton,
    mui_sitedirbutton,
    mui_sitedirlv,
    mui_sitedirlist,
    mui_addsitebutton,
    mui_delsitebutton,
    mui_pages,
    mui_historylv,
    mui_clearhistbutton,
    mui_showminilog,
    mui_prefsanonpass,
    mui_prefsdownload,
    mui_prefspubscr,
    mui_prefssavebutton,
    mui_prefsfreqbutton,
    mui_httpsitestring,
    mui_httpportstring,
    mui_httplocalpathstring,
    mui_httpfreqbutton,
    mui_httpokbutton,
    mui_httpcancelbutton,
    mui_xferslider,
    mui_prefstimeout,    
    bm,
    menu,
    profnum,
    result,
    diskobj=NIL,
    rtpath[500]:STRING,
    sitebuffer[500]:STRING,
    addtolist[1000]:STRING,
    stopres,

    -> AREXX VARIABLES
    rxcommandarr[31]:ARRAY OF mui_command,
    rexxhooks[31]:ARRAY OF hook

readprefs()
StrCopy(port,'21')
StrCopy(httpport,'80')

IF (muimasterbase:=OpenLibrary(MUIMASTER_NAME,MUIMASTER_VMIN))=NIL THEN Raise(ERR_NOMUI)
IF (reqtoolsbase:=OpenLibrary('reqtools.library',38))=NIL THEN Raise(ERR_NOREQ)
IF (iconbase:=OpenLibrary('icon.library',33))=NIL THEN Raise(ERR_NOICON)
IF (socketbase:=OpenLibrary('bsdsocket.library',NIL)) = NIL THEN Raise(ERR_NOBSD)
IF (gadtoolsbase:=OpenLibrary('gadtools.library',39)) = NIL THEN Raise(ERR_NOGAD)
NEW st.softtimer()

menu := [ NM_TITLE,0, 'Project'  , 0 ,0,0,0,
          NM_ITEM ,0, 'About...' ,'?',0,0,ID_ABOUT,
          NM_ITEM ,0, 'About MUI...',0,0,0,ID_MUIABOUT,
          NM_ITEM ,0, 'MUI Settings',0,0,0,ID_MUISET,
          NM_ITEM ,0, NM_BARLABEL, 0 ,0,0,0,
          NM_ITEM ,0, 'Iconify'  ,'I',0,0,ID_ICONIFY,
          NM_ITEM ,0, 'Quit'     ,'Q',0,0,MUIV_Application_ReturnID_Quit,
          NM_END  ,0, NIL        , 0 ,0,0,0]:newmenu

mui_pages:=['Main','Profile History','Preferences',NIL]

->#????
installhook (ref_refreshhook, {ref_refresh})
installhook (list_proflisthook, {list_proflistdisp})

installhook (rexxhooks[0], {rx_addprofile})
rxcommandarr[0].mc_name:='addprofile'
rxcommandarr[0].mc_template := 'SITE/A,PORT/A,USERNAME/A,PASSWORD/A,REMOTEPATH/A,FILENAME/A,DOWNLOADDIR/A'
rxcommandarr[0].mc_parameters:= 7
rxcommandarr[0].mc_hook:=rexxhooks[0]

installhook (rexxhooks[1], {rx_quitgofetch})
rxcommandarr[1].mc_name:='quitgofetch'
rxcommandarr[1].mc_template := NIL
rxcommandarr[1].mc_parameters:= NIL
rxcommandarr[1].mc_hook:=rexxhooks[1]

installhook (rexxhooks[2], {rx_reloadprofiles})
rxcommandarr[2].mc_name:='reloadprofiles'
rxcommandarr[2].mc_template := NIL
rxcommandarr[2].mc_parameters:= NIL
rxcommandarr[2].mc_hook:=rexxhooks[2]

installhook (rexxhooks[3], {rx_editprofile})
rxcommandarr[3].mc_name:='editprofile'
rxcommandarr[3].mc_template := 'PROFILE/N,SITE/A,PORT/A,USERNAME/A,PASSWORD/A,REMOTEPATH/A,FILENAME/A,DOWNLOADDIR/A'
rxcommandarr[3].mc_parameters:= 1
rxcommandarr[3].mc_hook:=rexxhooks[3]

installhook (rexxhooks[4], {rx_deleteprofile})
rxcommandarr[4].mc_name:='deleteprofile'
rxcommandarr[4].mc_template := 'PROFILE/N'
rxcommandarr[4].mc_parameters:= 1
rxcommandarr[4].mc_hook:=rexxhooks[4]

installhook (rexxhooks[5], {rx_profiles})
rxcommandarr[5].mc_name:='profiles'
rxcommandarr[5].mc_template := NIL
rxcommandarr[5].mc_parameters:= NIL
rxcommandarr[5].mc_hook:=rexxhooks[5]

installhook (rexxhooks[6], {rx_release})
rxcommandarr[6].mc_name:='release'
rxcommandarr[6].mc_template := NIL
rxcommandarr[6].mc_parameters:= NIL
rxcommandarr[6].mc_hook:=rexxhooks[6]

installhook (rexxhooks[7], {rx_setactiveprofile})
rxcommandarr[7].mc_name:='setactiveprofile'
rxcommandarr[7].mc_template := 'PROFILE/N'
rxcommandarr[7].mc_parameters:= 1
rxcommandarr[7].mc_hook:=rexxhooks[7]

installhook (rexxhooks[8], {rx_openaddwindow})
rxcommandarr[8].mc_name:='openaddwindow'
rxcommandarr[8].mc_template := NIL
rxcommandarr[8].mc_parameters:= NIL
rxcommandarr[8].mc_hook:=rexxhooks[8]

installhook (rexxhooks[9], {rx_openeditwindow})
rxcommandarr[9].mc_name:='openeditwindow'
rxcommandarr[9].mc_template := NIL
rxcommandarr[9].mc_parameters:= NIL
rxcommandarr[9].mc_hook:=rexxhooks[9]

installhook (rexxhooks[10], {rx_lockgui})
rxcommandarr[10].mc_name:='lockgui'
rxcommandarr[10].mc_template := NIL
rxcommandarr[10].mc_parameters:= NIL
rxcommandarr[10].mc_hook:=rexxhooks[10]

installhook (rexxhooks[11], {rx_unlockgui})
rxcommandarr[11].mc_name:='unlockgui'
rxcommandarr[11].mc_template := NIL
rxcommandarr[11].mc_parameters:= NIL
rxcommandarr[11].mc_hook:=rexxhooks[11]

installhook (rexxhooks[12], {rx_savelog})
rxcommandarr[12].mc_name:='savelog'
rxcommandarr[12].mc_template := 'PATH/A'
rxcommandarr[12].mc_parameters:= 1
rxcommandarr[12].mc_hook:=rexxhooks[12]

installhook (rexxhooks[13], {rx_clearlog})
rxcommandarr[13].mc_name:='clearlog'
rxcommandarr[13].mc_template := NIL
rxcommandarr[13].mc_parameters:= NIL
rxcommandarr[13].mc_hook:=rexxhooks[13]

installhook (rexxhooks[14], {rx_iconify})
rxcommandarr[14].mc_name:='iconify'
rxcommandarr[14].mc_template := NIL
rxcommandarr[14].mc_parameters:= NIL
rxcommandarr[14].mc_hook:=rexxhooks[14]

installhook (rexxhooks[15], {rx_uniconify})
rxcommandarr[15].mc_name:='uniconify'
rxcommandarr[15].mc_template := NIL
rxcommandarr[15].mc_parameters:= NIL
rxcommandarr[15].mc_hook:=rexxhooks[15]

installhook (rexxhooks[16], {rx_iconifystatus})
rxcommandarr[16].mc_name:='iconifystatus'
rxcommandarr[16].mc_template := NIL
rxcommandarr[16].mc_parameters:= NIL
rxcommandarr[16].mc_hook:=rexxhooks[16]

installhook (rexxhooks[17], {rx_getanon})
rxcommandarr[17].mc_name:='getanon'
rxcommandarr[17].mc_template := NIL
rxcommandarr[17].mc_parameters:= NIL
rxcommandarr[17].mc_hook:=rexxhooks[17]

installhook (rexxhooks[18], {rx_getdownloadpath})
rxcommandarr[18].mc_name:='getdownloadpath'
rxcommandarr[18].mc_template := NIL
rxcommandarr[18].mc_parameters:= NIL
rxcommandarr[18].mc_hook:=rexxhooks[18]

installhook (rexxhooks[19], {rx_go})
rxcommandarr[19].mc_name:='gofetch'
rxcommandarr[19].mc_template := NIL
rxcommandarr[19].mc_parameters:= NIL
rxcommandarr[19].mc_hook:=rexxhooks[19]

installhook (rexxhooks[20], {rx_addanonprofile})
rxcommandarr[20].mc_name:='addanonprofile'
rxcommandarr[20].mc_template := 'SITE/A,PORT/A,REMOTEPATH/A,FILENAME/A,DOWNLOADDIR/A'
rxcommandarr[20].mc_parameters:= 5
rxcommandarr[20].mc_hook:=rexxhooks[20]

installhook (rexxhooks[21], {rx_stop})
rxcommandarr[21].mc_name:='stop'
rxcommandarr[21].mc_template := NIL
rxcommandarr[21].mc_parameters:= NIL
rxcommandarr[21].mc_hook:=rexxhooks[21]

installhook (rexxhooks[22], {rx_addsite})
rxcommandarr[22].mc_name:='addsite'
rxcommandarr[22].mc_template := 'SITE/A'
rxcommandarr[22].mc_parameters:= 1
rxcommandarr[22].mc_hook:=rexxhooks[22]

installhook (rexxhooks[23], {rx_windowopen})
rxcommandarr[23].mc_name:='windowopen'
rxcommandarr[23].mc_template := NIL
rxcommandarr[23].mc_parameters:= NIL
rxcommandarr[23].mc_hook:=rexxhooks[23]

installhook (rexxhooks[24], {rx_addhttpprofile} )
rxcommandarr[24].mc_name:='addhttpprofile'
rxcommandarr[24].mc_template :='SITE/A,PORT/A,DOWNLOADDIR/A'
rxcommandarr[24].mc_parameters:= 3
rxcommandarr[24].mc_hook:=rexxhooks[24]

installhook (rexxhooks[25], {rx_setminilog} )
rxcommandarr[25].mc_name:='setminilog'
rxcommandarr[25].mc_template :='STATUS/N'
rxcommandarr[25].mc_parameters:= 1
rxcommandarr[25].mc_hook:=rexxhooks[25]

installhook (rexxhooks[26], {rx_annotate} )
rxcommandarr[26].mc_name:='annotate'
rxcommandarr[26].mc_template :='TEXT/A'
rxcommandarr[26].mc_parameters:= 1
rxcommandarr[26].mc_hook:=rexxhooks[26]

installhook (rexxhooks[27], {rx_clearhistory})
rxcommandarr[27].mc_name:='clearhistory'
rxcommandarr[27].mc_template :=NIL
rxcommandarr[27].mc_parameters:= NIL
rxcommandarr[27].mc_hook:=rexxhooks[27]

installhook (rexxhooks[28], {rx_returnproto})
rxcommandarr[28].mc_name:='returnprotocol'
rxcommandarr[28].mc_template :='PROFILE/N'
rxcommandarr[28].mc_parameters:= 1
rxcommandarr[28].mc_hook:=rexxhooks[28]

installhook (rexxhooks[29], {rx_edithttpprofile})
rxcommandarr[29].mc_name:='edithttpprofile'
rxcommandarr[29].mc_template :='PROFILE/N,SITE/A,PORT/A,DOWNLOADDIR/A'
rxcommandarr[29].mc_parameters:= 4
rxcommandarr[29].mc_hook:=rexxhooks[29]

installhook (rexxhooks[30], {rx_dlstatus})
rxcommandarr[30].mc_name:='dlstatus'
rxcommandarr[30].mc_template :=NIL
rxcommandarr[30].mc_parameters:=NIL
rxcommandarr[30].mc_hook:=rexxhooks[30]

rxcommandarr[31].mc_name:=NIL
rxcommandarr[31].mc_template := NIL
rxcommandarr[31].mc_parameters:= NIL
rxcommandarr[31].mc_hook:=NIL

/*Gadgets for the Main Window*/
    ->Front Page
mui_addbutton:=SimpleButton('_Add')
mui_editbutton:=SimpleButton('_Edit')
mui_deletebutton:=SimpleButton('_Delete')
bm:=imgLogoObject()
mui_stopbutton:=SimpleButton('_Stop')
mui_gobutton:=SimpleButton('_Go!')
mui_quitbutton:=SimpleButton('_Quit')
mui_savelogbutton:=SimpleButton('Sa_ve Log')
mui_showminilog:=ibu(MUII_PopUp)
mui_clearlogbutton:=SimpleButton('_Clear Log')
mui_profilelv:= ListviewObject,
    MUIA_Listview_Input, MUI_TRUE,
    MUIA_Listview_List, mui_profilelist:=ListObject,
                            ReadListFrame,
                                MUIA_List_ConstructHook, MUIV_List_ConstructHook_String,
                                MUIA_List_DestructHook, MUIV_List_DestructHook_String,
                                MUIA_ShortHelp, 'Profile List',
                            End, ->Readlistframe
                        End -> Listviewobject
mui_iolv:=ListviewObject,
    MUIA_Listview_Input, FALSE,
    MUIA_Listview_List, mui_iolist:=ListObject,
                            ReadListFrame,
                                MUIA_List_ConstructHook, MUIV_List_ConstructHook_String,
                                MUIA_List_DestructHook, MUIV_List_DestructHook_String,
                                MUIA_ShortHelp, 'Transfer and Error Information',
                            End, ->Readlistframe
                        End ->ListviewObject
    ->History Page
mui_historylv:= ListviewObject,
     MUIA_Listview_Input, FALSE,
     MUIA_Listview_List, mui_historylist:=ListObject,
                            ReadListFrame,
                                MUIA_List_ConstructHook, MUIV_List_ConstructHook_String,
                                MUIA_List_DestructHook, MUIV_List_DestructHook_String,
                                MUIA_ShortHelp, 'Profile History List\nA list of profiles which have been processed.',
                            End, ->Readlistframe
                        End -> Listviewobject
mui_clearhistbutton:=SimpleButton('Clear _History')
    ->Prefs Page
mui_prefsanonpass:=StringObject, StringFrame,
     MUIA_String_AdvanceOnCR, MUI_TRUE,
     MUIA_String_Contents, anonpass,
     MUIA_String_Reject, '#',
     MUIA_ShortHelp, 'Default Anonymous Password',
     End ->StringObject

mui_prefsdownload:=StringObject, StringFrame,
     MUIA_String_AdvanceOnCR, MUI_TRUE,
     MUIA_String_Contents, deflocalpath,
     MUIA_String_Reject, '?#;[]{}',
     MUIA_ShortHelp, 'Default Download Directory',
     End

mui_prefspubscr:=StringObject, StringFrame,
     MUIA_String_AdvanceOnCR, MUI_TRUE,
     MUIA_String_Contents, defpubscr,
     MUIA_ShortHelp, 'Mini Log Public Screen',
     End

mui_prefsbeep:= CheckMark(MUI_TRUE)
mui_prefskeepalive:= CheckMark(MUI_TRUE)
mui_prefsshowprofs:= CheckMark(MUI_TRUE)
mui_prefsretain:= CheckMark(MUI_TRUE)
mui_prefsretaintout:= CheckMark(MUI_TRUE)
mui_prefsretainfnf:= CheckMark(MUI_TRUE)
mui_prefsgetonnoresume:= CheckMark(MUI_TRUE)
mui_prefssavebutton:=SimpleButton('Sa_ve Prefs')
mui_prefsfreqbutton:=ibt(MUII_PopFile    )


/*Main Application Setup*/

app:=ApplicationObject,
    MUIA_Application_Title      , 'Go Fetch! FTP/HTTP',
    MUIA_Application_Version    , '$VER: Go Fetch! 1.3',
    MUIA_Application_Copyright  , '©2002 Ian Chapman',
    MUIA_Application_Author     , 'Ian Chapman',
    MUIA_Application_Description, 'FTP/HTTP Download Manager',
    MUIA_Application_Base       , 'GOFETCH',
    MUIA_Application_Commands   , rxcommandarr,
    MUIA_Application_SingleTask , MUI_TRUE,
    MUIA_Application_DiskObject , diskobj:=GetDiskObject('ENVARC:sys/def_gofetch'),
    MUIA_Application_Menustrip  , Mui_MakeObjectA(MUIO_MenustripNM,[menu,0]),
    MUIA_Application_HelpFile   , 'PROGDIR:GoFetch!.guide',
    MUIA_Application_Iconified  , MUI_TRUE,

    SubWindow, mui_mainwindow:=WindowObject,
        MUIA_Window_Title       , 'Go Fetch! 1.3 by Ian Chapman',
        MUIA_Window_ID          , "GOFE",
        MUIA_HelpNode           , 'Main Window',
        MUIA_Window_Activate    , FALSE,

        WindowContents, VGroup,
            Child, RegisterGroup(mui_pages),
                Child, VGroup,
                    Child, TextObject,
                        TextFrame,
                        MUIA_Text_Contents, '\ecGo Fetch! FTP/HTTP Download Manager',
                        MUIA_Background, MUII_FILLBACK,
                        End, -> TextObject

                    Child, TextObject,
                        MUIA_Text_Contents, '\ecProfile List',
                        MUIA_ShortHelp, 'Profile List',
                        End, -> TextObject

                    Child, mui_profilelv,

                    Child, HGroup,
                        Child, mui_addbutton,
                        Child, mui_editbutton,
                        Child, mui_deletebutton,
                        Child, bm,
                        Child, mui_stopbutton,
                        Child, mui_gobutton,
                        Child, mui_quitbutton,
                        End, -> HGroup

                    Child, BalanceObject,
                        MUIA_ShortHelp, 'Drag Me',
                        End, ->BalanceObject

                    Child, mui_iolv,

                    Child, HGroup,
                        Child, mui_savelogbutton,
                        Child, mui_showminilog,
                        Child, mui_clearlogbutton,
                    End, -> HGroup

                End, ->V Group

                Child, VGroup,

                     Child, TextObject,
                        MUIA_Text_Contents, '\ecProfile History List',
                        MUIA_ShortHelp,'Profile History List',
                     End, -> TextObject

                    Child, mui_historylv,
                    Child, mui_clearhistbutton,

                End, ->VGroup

                Child, VGroup,

                    Child, TextObject,
                            TextFrame,
                            MUIA_Text_Contents, '\ecGo Fetch! Preferences',
                            MUIA_Background, MUII_FILLBACK,
                            End, ->TextObject

                    Child, HGroup,
                        Child, ColGroup(2), GroupFrameT('Defaults'),
                            Child, Label('Anonymous Password'),
                            Child, mui_prefsanonpass,
                            Child, Label('Default Download Directory'),
                            Child, HGroup,
                                Child, mui_prefsdownload,
                                Child, mui_prefsfreqbutton,
                            End,
                            Child, Label('Mini Log Screen'),
                            Child, mui_prefspubscr,
                        End,
                    End,


                    Child, HGroup,
                        Child, ColGroup(4), GroupFrameT('Profiles'),
                            Child, HSpace(0),
                            Child, Label('Show Profiles When Connected'),
                            Child, mui_prefsshowprofs,
                            Child, HSpace(0),

                            Child, HSpace(0),
                            Child, Label('Retain "No Connect"'),
                            Child, mui_prefsretain,
                            Child, HSpace(0),

                            Child, HSpace(0),
                            Child, Label('Retain "Timed Out"'),
                            Child, mui_prefsretaintout,
                            Child, HSpace(0),

                            Child, HSpace(0),
                            Child, Label('Retain "File Not Found"'),
                            Child, mui_prefsretainfnf,
                            Child, HSpace(0),
                        End,
                        Child, VGroup,

                                Child, ColGroup(4), GroupFrameT('FTP'),
                                Child, HSpace(0),
                                Child, Label('Keep Connection Alive'),
                                Child, mui_prefskeepalive,
                                Child, HSpace(0),
                                End,

                                Child, ColGroup(4), GroupFrameT('HTTP'),
                                Child, HSpace(0),
                                Child, Label('No File Resuming: Download Anyway'),
                                Child, mui_prefsgetonnoresume,
                                Child, HSpace(0),
                                End,

                                Child, ColGroup(4), GroupFrameT('File Transfers'),
                                Child, HSpace(0),
                                Child, Label('Beep On Completed File Transfer'),
                                Child, mui_prefsbeep,
                                Child, HSpace(0),


                                End,
                        End,

                    End,


                    Child, ColGroup(2),
                        Child, Label('Transfer Buffer (K)'),
                        Child, mui_xferslider:=SliderObject,
                            MUIA_Slider_Min, 1,
                            MUIA_Slider_Max, 1024,
                            MUIA_Slider_Level, prefsxferbuffer,
                            End,

                        Child, Label('Timeout (Secs)'),
                        Child, mui_prefstimeout:=SliderObject,
                            MUIA_Slider_Min, 1,
                            MUIA_Slider_Max, 100,
                            MUIA_Slider_Level, prefstimeout,
                            End,
                    End,

                    Child, mui_prefssavebutton,

                End, -> VGroup

            
                
        End, -> Pages
        End, ->VGroup

     End, -> SubWindow

    SubWindow, mui_addwindow:= WindowObject,
        MUIA_Window_Title       ,'Add Profile',
        MUIA_HelpNode           , 'Add Window',
        MUIA_Window_ID          , "ADDW",
        WindowContents, VGroup,
            Child, HGroup,
                Child, ColGroup(2),
                    Child, Label('Site:'),
                    Child, HGroup,
                        Child, mui_sitestring:= StringObject, StringFrame,
                            MUIA_String_AdvanceOnCR, MUI_TRUE,
                            MUIA_String_Contents, site,
                            MUIA_String_Reject, '#',
                            MUIA_ShortHelp, 'IP Address or URL of FTP site',
                            End,
                        Child,  mui_addsitebutton:=ibt(MUII_ArrowRight),
                        Child,  mui_sitedirbutton:=ibu(MUII_PopUp),
                    End, -> HGroup,
                End, -> ColGroup,
            End, -> HGroup,
     End,
     /*
            Child,  mui_sitedirlv:=ListviewObject,
                                MUIA_Listview_Input, MUI_TRUE,
                                MUIA_Listview_List, mui_sitedirlist:=ListObject,
                                    ReadListFrame,
                                        MUIA_List_ConstructHook, MUIV_List_ConstructHook_String,
                                        MUIA_List_DestructHook, MUIV_List_DestructHook_String,
                                        MUIA_ShortHelp, 'Site Directory List',
                                    End,
                              End,
                Child, mui_delsitebutton:=SimpleButton('_Delete Site from Directory'),

            Child, HGroup,
                Child, ColGroup(2),

                    Child, Label('Port:'),
                    Child, mui_portstring:= StringObject, StringFrame,
                        MUIA_String_Accept, '0123456789',
                        MUIA_String_AdvanceOnCR, MUI_TRUE,
                        MUIA_String_Contents, port,
                        MUIA_ShortHelp, '\ecFTP port value.\n(Port 21 is default)',
                        End,

                    Child, Label('Username:'),
                    Child, HGroup,
                        Child, mui_usernamestring:= StringObject, StringFrame,
                            MUIA_String_AdvanceOnCR, MUI_TRUE,
                            MUIA_String_Contents, username,
                            MUIA_String_Reject, '#',
                            MUIA_ShortHelp, '\ecYour login name.',
                        End,
                        Child, Label('Anon Login'),
                        Child, mui_checkmark:=CheckMark(FALSE),
                    End,

                    Child, Label('Password:'),
                    Child, mui_passwordstring:= StringObject, StringFrame,
                        MUIA_String_AdvanceOnCR, MUI_TRUE,
                        MUIA_String_Secret, MUI_TRUE,
                        MUIA_String_Contents, password,
                        MUIA_String_Reject, '#',
                        MUIA_ShortHelp,'\ecYour password.',
                        End,

                    Child, Label('Remote Path:'),
                    Child, mui_remotepathstring:= StringObject, StringFrame,
                        MUIA_String_AdvanceOnCR, MUI_TRUE,
                        MUIA_String_Contents, remotepath,
                        MUIA_String_Reject, '#',
                        MUIA_ShortHelp,'Path of the file on the server',
                        End,

                    Child, Label('Filename:'),
                    Child, mui_filenamestring:= StringObject, StringFrame,
                        MUIA_String_AdvanceOnCR, MUI_TRUE,
                        MUIA_String_Contents, filename,
                        MUIA_String_Reject, '#',
                        MUIA_ShortHelp,'Enter filename',
                        End,

                    Child, Label('Download:'),
                    Child, HGroup,
                        Child, mui_localpathstring:= StringObject, StringFrame,
                            MUIA_String_AdvanceOnCR, MUI_TRUE,
                            MUIA_String_Contents, localpath,
                            MUIA_String_Reject, '#',
                            MUIA_ShortHelp, 'File download path',
                        End,
                        Child, mui_freqbutton:=ibt(MUII_PopFile    ),
                    End,
                End,
            End,

            Child, HGroup,
                Child, mui_okbutton:= SimpleButton('_OK'),
                Child, mui_cancelbutton:= SimpleButton('_Cancel'),
            End,

            End, ->VGroup

            Child, HGroup,
                Child, mui_httpokbutton:= SimpleButton('_OK'),
                Child, mui_httpcancelbutton:= SimpleButton('_Cancel'),
            End,



            End, -> VGroup



    End, -> Vgroup

    */

    End, -> WindowObject

End -> Application

IF (app=NIL) THEN Raise(ERR_NOAPP)
set(mui_sitedirlv,MUIA_ShowMe, FALSE)
set(mui_delsitebutton,MUIA_ShowMe, FALSE)
set(mui_mainwindow, MUIA_Window_ActiveObject, mui_addbutton)
set(mui_addwindow, MUIA_Window_ActiveObject, mui_okbutton)
set(mui_addbutton,MUIA_ShortHelp, 'Add Profile')
set(mui_editbutton,MUIA_ShortHelp, 'Edit Profile')
set(mui_deletebutton,MUIA_ShortHelp, 'Delete Profile')
set(mui_gobutton,MUIA_ShortHelp, 'Download Files')
set(mui_stopbutton, MUIA_ShortHelp, 'Stop Downloading Files')
set(mui_savelogbutton,MUIA_ShortHelp, 'Save contents of log view')
set(mui_clearlogbutton,MUIA_ShortHelp, 'Clear contents of log view')
set(mui_okbutton, MUIA_ShortHelp, 'Press OK to Save FTP Profile')
set(mui_cancelbutton, MUIA_ShortHelp, 'Press Cancel to Discard FTP Profile')
set(mui_freqbutton,MUIA_ShortHelp, 'Choose download directory')
set(bm ,MUIA_ShortHelp, 'Go Fetch! FTP/HTTP is the dogs bollocks!')
set(mui_checkmark, MUIA_ShortHelp,'Tick to Perform Anonymous Login')
set(mui_quitbutton, MUIA_ShortHelp, 'Quit Go Fetch!')
set(mui_addsitebutton, MUIA_ShortHelp, 'Add Site to Site Directory')
set(mui_sitedirbutton, MUIA_ShortHelp, 'Pops up/Hide Site Directory')
set(mui_delsitebutton, MUIA_ShortHelp, 'Delete Site From Directory')
set(mui_showminilog, MUIA_ShortHelp, 'Show/Hide MiniLog Window')
set(mui_httpokbutton, MUIA_ShortHelp, 'Press OK to Save HTTP Profile')
set(mui_httpcancelbutton, MUIA_ShortHelp, 'Press Cancel to Discard HTTP Profile')
set(mui_httpfreqbutton, MUIA_ShortHelp, 'Choose Download Directory')
set(mui_prefsbeep, MUIA_ShortHelp, 'Play system sound on completed\nfile transfer')
set(mui_prefsretain, MUIA_ShortHelp, 'Retain profiles which failed to connect')
set(mui_prefsretaintout, MUIA_ShortHelp, 'Retain profiles which timed out')
set(mui_prefsretainfnf, MUIA_ShortHelp, 'Retain profiles if the file is\nnot found')
set(mui_prefskeepalive, MUIA_ShortHelp, 'Keep the connection alive if the\nnext profile is on the same server')
set(mui_prefsshowprofs, MUIA_ShortHelp, 'Show profiles list when connected')
set(mui_prefssavebutton, MUIA_ShortHelp, 'Save the preferences')
set(mui_prefsgetonnoresume, MUIA_ShortHelp, 'If the server does not support\nfile resuming, dowload the full file')
set(mui_clearhistbutton, MUIA_ShortHelp, 'Clear contents of history view')
set(mui_xferslider, MUIA_ShortHelp, 'Sets the Transfer Receive Buffer\nRecommended: 100K')
set(mui_prefstimeout, MUIA_ShortHelp, 'Sets the receive timeout in seconds\nRecommended: 20 secs')

IF p.beep=TRUE
    set(mui_prefsbeep, MUIA_Pressed, MUI_TRUE)
    set(mui_prefsbeep, MUIA_Selected, MUI_TRUE)
ELSE
    set(mui_prefsbeep, MUIA_Pressed, FALSE)
    set(mui_prefsbeep, MUIA_Selected, FALSE)
ENDIF

IF p.keepalive=TRUE
    set(mui_prefskeepalive, MUIA_Pressed, MUI_TRUE)
    set(mui_prefskeepalive, MUIA_Selected, MUI_TRUE)
ELSE
    set(mui_prefskeepalive, MUIA_Pressed, FALSE)
    set(mui_prefskeepalive, MUIA_Selected, FALSE)
ENDIF

IF p.showprofs=TRUE
    set(mui_prefsshowprofs, MUIA_Pressed, MUI_TRUE)
    set(mui_prefsshowprofs, MUIA_Selected, MUI_TRUE)
ELSE
    set(mui_prefsshowprofs, MUIA_Pressed, FALSE)
    set(mui_prefsshowprofs, MUIA_Selected, FALSE)
ENDIF

IF p.retain=TRUE
    set(mui_prefsretain, MUIA_Pressed, MUI_TRUE)
    set(mui_prefsretain, MUIA_Selected, MUI_TRUE)
ELSE
    set(mui_prefsretain, MUIA_Pressed, FALSE)
    set(mui_prefsretain, MUIA_Selected, FALSE)
ENDIF

IF p.retaintout=TRUE
    set(mui_prefsretaintout, MUIA_Pressed, MUI_TRUE)
    set(mui_prefsretaintout, MUIA_Selected, MUI_TRUE)
ELSE
    set(mui_prefsretaintout, MUIA_Pressed, FALSE)
    set(mui_prefsretaintout, MUIA_Selected, FALSE)
ENDIF

IF p.retainfnf
    set(mui_prefsretainfnf, MUIA_Pressed, MUI_TRUE)
    set(mui_prefsretainfnf, MUIA_Selected, MUI_TRUE)
ELSE
    set(mui_prefsretainfnf, MUIA_Pressed, FALSE)
    set(mui_prefsretainfnf, MUIA_Selected, FALSE)
ENDIF

IF p.getonnoresume
    set(mui_prefsgetonnoresume, MUIA_Pressed, MUI_TRUE)
    set(mui_prefsgetonnoresume, MUIA_Selected, MUI_TRUE)
ELSE
    set(mui_prefsgetonnoresume, MUIA_Pressed, FALSE)
    set(mui_prefsgetonnoresume, MUIA_Selected, FALSE)
ENDIF

->Main Window
doMethodA(app, [MUIM_Application_Load, MUIV_Application_Load_ENVARC])

doMethodA(mui_mainwindow,
            [MUIM_Notify,
            MUIA_Window_CloseRequest, MUI_TRUE,
            app, 2,
            MUIM_Application_ReturnID, MUIV_Application_ReturnID_Quit])

doMethodA(mui_quitbutton,
            [MUIM_Notify,
            MUIA_Pressed, FALSE,
            app, 2,
            MUIM_Application_ReturnID, MUIV_Application_ReturnID_Quit])

doMethodA(mui_addbutton,
            [MUIM_Notify,
            MUIA_Pressed, FALSE,
            app, 2,
            MUIM_Application_ReturnID, ID_ADD])

doMethodA(mui_editbutton,
            [MUIM_Notify,
            MUIA_Pressed, FALSE,
            app, 2,
            MUIM_Application_ReturnID, ID_EDIT])

doMethodA(mui_deletebutton,
            [MUIM_Notify,
            MUIA_Pressed, FALSE,
            app, 2,
            MUIM_Application_ReturnID, ID_DELETE])

doMethodA(mui_gobutton,
            [MUIM_Notify,
            MUIA_Pressed, FALSE,
            app, 2,
            MUIM_Application_ReturnID, ID_GO])

doMethodA(mui_stopbutton,
            [MUIM_Notify,
            MUIA_Pressed, FALSE,
            app, 2,
            MUIM_Application_ReturnID, ID_STOP])

doMethodA(mui_clearlogbutton,
            [MUIM_Notify,
            MUIA_Pressed, FALSE,
            mui_iolist, 1,
            MUIM_List_Clear])

doMethodA(mui_clearhistbutton,
            [MUIM_Notify,
            MUIA_Pressed, FALSE,
            mui_historylist, 1,
            MUIM_List_Clear])

doMethodA(mui_savelogbutton,
            [MUIM_Notify,
            MUIA_Pressed, FALSE,
            app, 2,
            MUIM_Application_ReturnID, ID_SAVELOG])

doMethodA(mui_profilelv,
            [MUIM_Notify,
            MUIA_Listview_DoubleClick, MUI_TRUE,
            app, 2,
            MUIM_Application_ReturnID, ID_EDIT])

doMethodA(mui_showminilog,
            [MUIM_Notify,
            MUIA_Pressed, MUI_TRUE,
            app, 2,
            MUIM_Application_ReturnID, ID_MINISHOW])

doMethodA(mui_showminilog,
            [MUIM_Notify,
            MUIA_Pressed, FALSE,
            app, 2,
            MUIM_Application_ReturnID, ID_MINIHIDE])

doMethodA(mui_mainwindow,
            [MUIM_Window_SetCycleChain,
            mui_profilelv,
            mui_addbutton,
            mui_editbutton,
            mui_deletebutton,
            mui_stopbutton,
            mui_gobutton,
            mui_quitbutton,
            mui_iolv,
            mui_savelogbutton,
            mui_showminilog,
            mui_clearlogbutton,
            mui_historylv,
            mui_clearhistbutton,
            mui_prefsanonpass,
            mui_prefsdownload,
            mui_prefsfreqbutton,
            mui_prefspubscr,
            mui_prefsshowprofs,
            mui_prefsretain,
            mui_prefsretaintout,
            mui_prefsretainfnf,
            mui_prefskeepalive,
            mui_prefsgetonnoresume,
            mui_prefsbeep,
            mui_prefssavebutton,
            NIL])


/*Preferences*/
doMethodA(mui_prefsanonpass,
            [MUIM_Notify,
            MUIA_String_Contents, MUIV_EveryTime,
            mui_prefsanonpass, 3,
            MUIM_WriteString, MUIV_TriggerValue, anonpass])

doMethodA(mui_xferslider,
            [MUIM_Notify,
            MUIA_Slider_Level, MUIV_EveryTime,
            mui_xferslider, 3, MUIM_WriteLong, MUIV_TriggerValue, {prefsxferbuffer}])

doMethodA(mui_prefstimeout,
            [MUIM_Notify,
            MUIA_Slider_Level, MUIV_EveryTime,
            mui_prefstimeout, 3, MUIM_WriteLong, MUIV_TriggerValue, {prefstimeout}])


doMethodA(mui_prefsdownload,
            [MUIM_Notify,
            MUIA_String_Contents, MUIV_EveryTime,
            mui_prefsdownload, 3,
            MUIM_WriteString, MUIV_TriggerValue, deflocalpath])

doMethodA(mui_prefspubscr,
            [MUIM_Notify,
            MUIA_String_Contents, MUIV_EveryTime,
            mui_prefspubscr, 3,
            MUIM_WriteString, MUIV_TriggerValue, defpubscr])

doMethodA(mui_prefsbeep,
            [MUIM_Notify,
            MUIA_Pressed, MUI_TRUE,
            app, 2,
            MUIM_Application_ReturnID, ID_BEEPON])

doMethodA(mui_prefsbeep,
            [MUIM_Notify,
            MUIA_Pressed, FALSE,
            app, 2,
            MUIM_Application_ReturnID, ID_BEEPOFF])

doMethodA(mui_prefskeepalive,
            [MUIM_Notify,
            MUIA_Pressed, MUI_TRUE,
            app, 2,
            MUIM_Application_ReturnID, ID_KEEPALIVEON])

doMethodA(mui_prefskeepalive,
            [MUIM_Notify,
            MUIA_Pressed, FALSE,
            app, 2,
            MUIM_Application_ReturnID, ID_KEEPALIVEOFF])

doMethodA(mui_prefsshowprofs,
            [MUIM_Notify,
            MUIA_Pressed, MUI_TRUE,
            app, 2,
            MUIM_Application_ReturnID, ID_SHOWPROFSON])

doMethodA(mui_prefsshowprofs,
            [MUIM_Notify,
            MUIA_Pressed, FALSE,
            app, 2,
            MUIM_Application_ReturnID, ID_SHOWPROFSOFF])

doMethodA(mui_prefsretain,
            [MUIM_Notify,
            MUIA_Pressed, MUI_TRUE,
            app, 2,
            MUIM_Application_ReturnID, ID_RETAINON])

doMethodA(mui_prefsretain,
            [MUIM_Notify,
            MUIA_Pressed, FALSE,
            app, 2,
            MUIM_Application_ReturnID, ID_RETAINOFF])

doMethodA(mui_prefsretaintout,
            [MUIM_Notify,
            MUIA_Pressed, MUI_TRUE,
            app, 2,
            MUIM_Application_ReturnID, ID_RETAINTOON])

doMethodA(mui_prefsretaintout,
            [MUIM_Notify,
            MUIA_Pressed, FALSE,
            app, 2,
            MUIM_Application_ReturnID, ID_RETAINTOOFF])

doMethodA(mui_prefsretainfnf,
            [MUIM_Notify,
            MUIA_Pressed, MUI_TRUE,
            app, 2,
            MUIM_Application_ReturnID, ID_RETAINFNFON])

doMethodA(mui_prefsretainfnf,
            [MUIM_Notify,
            MUIA_Pressed, FALSE,
            app, 2,
            MUIM_Application_ReturnID, ID_RETAINFNFOFF])

doMethodA(mui_prefsgetonnoresume,
            [MUIM_Notify,
            MUIA_Pressed, MUI_TRUE,
            app, 2,
            MUIM_Application_ReturnID, ID_GETONNORESUMEON])

doMethodA(mui_prefsgetonnoresume,
            [MUIM_Notify,
            MUIA_Pressed, FALSE,
            app, 2,
            MUIM_Application_ReturnID, ID_GETONNORESUMEOFF])

doMethodA(mui_prefssavebutton,
            [MUIM_Notify,
            MUIA_Pressed, FALSE,
            app, 2,
            MUIM_Application_ReturnID, ID_SAVEPREFS])

doMethodA(mui_prefsfreqbutton,
            [MUIM_Notify,
            MUIA_Pressed, FALSE,
            app, 2,
            MUIM_Application_ReturnID, ID_PREFSFREQ])

/* ADD WINDOW NOTIFYS */
doMethodA(mui_addwindow,
            [MUIM_Notify,
            MUIA_Window_CloseRequest, MUI_TRUE,
            app, 2,
            MUIM_Application_ReturnID, ID_CANCEL])

doMethodA(mui_checkmark,
            [MUIM_Notify,
            MUIA_Pressed, MUI_TRUE,
            app, 2,
            MUIM_Application_ReturnID, ID_CHECKON])

doMethodA(mui_checkmark,
            [MUIM_Notify,
            MUIA_Pressed, FALSE,
            app, 2,
            MUIM_Application_ReturnID, ID_CHECKOFF])

doMethodA(mui_okbutton,
            [MUIM_Notify,
            MUIA_Pressed, FALSE,
            app, 2,
            MUIM_Application_ReturnID, ID_OK])

doMethodA(mui_cancelbutton,
            [MUIM_Notify,
            MUIA_Pressed, FALSE,
            app, 2,
            MUIM_Application_ReturnID, ID_CANCEL])

doMethodA(mui_sitestring,
            [MUIM_Notify,
            MUIA_String_Contents, MUIV_EveryTime,
            mui_sitestring, 3,
            MUIM_WriteString, MUIV_TriggerValue,site])

doMethodA(mui_portstring,
            [MUIM_Notify,
            MUIA_String_Contents, MUIV_EveryTime,
            mui_portstring, 3,
            MUIM_WriteString, MUIV_TriggerValue,port])

doMethodA(mui_usernamestring,
            [MUIM_Notify,
            MUIA_String_Contents, MUIV_EveryTime,
            mui_usernamestring, 3,
            MUIM_WriteString, MUIV_TriggerValue,username])

doMethodA(mui_passwordstring,
            [MUIM_Notify,
            MUIA_String_Contents, MUIV_EveryTime,
            mui_passwordstring, 3,
            MUIM_WriteString, MUIV_TriggerValue,password])

doMethodA(mui_remotepathstring,
            [MUIM_Notify,
            MUIA_String_Contents, MUIV_EveryTime,
            mui_remotepathstring, 3,
            MUIM_WriteString, MUIV_TriggerValue,remotepath])

doMethodA(mui_filenamestring,
            [MUIM_Notify,
            MUIA_String_Contents, MUIV_EveryTime,
            mui_filenamestring, 3,
            MUIM_WriteString, MUIV_TriggerValue,filename])

doMethodA(mui_localpathstring,
            [MUIM_Notify,
            MUIA_String_Contents, MUIV_EveryTime,
            mui_localpathstring, 3,
            MUIM_WriteString, MUIV_TriggerValue,localpath])

doMethodA(mui_freqbutton,
            [MUIM_Notify,
            MUIA_Pressed, FALSE,
            app, 2,
            MUIM_Application_ReturnID, ID_FREQ])

doMethodA(mui_sitedirbutton,
            [MUIM_Notify,
            MUIA_Pressed, MUI_TRUE,
            app, 2,
            MUIM_Application_ReturnID, ID_POPSITEDIR])

doMethodA(mui_sitedirbutton,
            [MUIM_Notify,
            MUIA_Pressed, FALSE,
            app, 2,
            MUIM_Application_ReturnID, ID_POPSITEDIROFF])

doMethodA(mui_addsitebutton,
            [MUIM_Notify,
            MUIA_Pressed, FALSE,
            mui_sitedirlist,
            3, MUIM_List_InsertSingle, site, MUIV_List_Insert_Bottom])

doMethodA(mui_addsitebutton,
            [MUIM_Notify,
            MUIA_Pressed, FALSE,
            mui_sitedirlist, 1,
            MUIM_List_Sort])

doMethodA(mui_delsitebutton,
            [MUIM_Notify,
            MUIA_Pressed, FALSE,
            mui_sitedirlist, 2,
            MUIM_List_Remove, MUIV_List_Remove_Active])

doMethodA(mui_sitedirlv,
            [MUIM_Notify,
            MUIA_Listview_DoubleClick, MUI_TRUE,
            app, 2,
            MUIM_Application_ReturnID, ID_FILLINSITE])

doMethodA(mui_httpokbutton,
            [MUIM_Notify,
            MUIA_Pressed, FALSE,
            app, 2,
            MUIM_Application_ReturnID, ID_HTTPOK])

doMethodA(mui_httpcancelbutton,
            [MUIM_Notify,
            MUIA_Pressed, FALSE,
            app, 2,
            MUIM_Application_ReturnID, ID_CANCEL])

doMethodA(mui_httpsitestring,
            [MUIM_Notify,
            MUIA_String_Contents, MUIV_EveryTime,
            mui_httpsitestring, 3,
            MUIM_WriteString, MUIV_TriggerValue,httpsite])

doMethodA(mui_httpportstring,
            [MUIM_Notify,
            MUIA_String_Contents, MUIV_EveryTime,
            mui_httpportstring, 3,
            MUIM_WriteString, MUIV_TriggerValue,httpport])

doMethodA(mui_httplocalpathstring,
            [MUIM_Notify,
            MUIA_String_Contents, MUIV_EveryTime,
            mui_localpathstring, 3,
            MUIM_WriteString, MUIV_TriggerValue,httplocalpath])

doMethodA(mui_httpfreqbutton,
            [MUIM_Notify,
            MUIA_Pressed, FALSE,
            app, 2,
            MUIM_Application_ReturnID, ID_FREQ])

doMethodA(mui_addwindow,
            [MUIM_Window_SetCycleChain,
            mui_sitestring,
            mui_addsitebutton,
            mui_sitedirbutton,
            mui_portstring,
            mui_sitedirlv,
            mui_delsitebutton,
            mui_usernamestring,
            mui_checkmark,
            mui_passwordstring,
            mui_remotepathstring,
            mui_filenamestring,
            mui_localpathstring,
            mui_freqbutton,
            mui_okbutton,
            mui_cancelbutton,
            mui_httpsitestring,
            mui_httpportstring,
            mui_httplocalpathstring,
            mui_httpfreqbutton,
            mui_httpokbutton,
            mui_httpcancelbutton,
            NIL])


set(mui_mainwindow,MUIA_Window_Open,MUI_TRUE)
set(mui_stopbutton, MUIA_Disabled, MUI_TRUE)
setupprofiles()

WHILE running
result:= doMethodA(app, [MUIM_Application_Input,{signal}])

    SELECT result
        /*General Application Messages*/
        CASE MUIV_Application_ReturnID_Quit -> Application Quit received
            running:=FALSE

        /*Menu Related Messages*/
        CASE ID_ABOUT -> About menu option
            Mui_RequestA(app, mui_mainwindow, 0, 'About Go Fetch!','*_OK','\ecGo Fetch! Download Manager by Ian Chapman.\n Version 1.3 (RELEASE 7)\n\nThanks to:\nMarc Bradshaw & Contributors for AREXX Scripts\nNeil Williams for Beta Testing\nAREXX PORT: GOFETCH',NIL)

        CASE ID_ICONIFY -> Iconify menu option
            set(app, MUIA_Application_Iconified, MUI_TRUE)

        CASE ID_MUISET -> Mui Settings Menu Option
            doMethodA(app, [MUIM_Application_OpenConfigWindow,0])

        CASE ID_MUIABOUT -> About Settings Menu Option
            doMethodA(app, [MUIM_Application_AboutMUI, mui_mainwindow])

        /*Main Window Related Messages*/
        CASE ID_ADD -> Add button on main window
            set(mui_sitestring, MUIA_String_Contents, site)
            set(mui_portstring, MUIA_String_Contents, port)
            set(mui_usernamestring, MUIA_String_Contents, username)
            set(mui_passwordstring, MUIA_String_Contents, password)
            set(mui_filenamestring, MUIA_String_Contents, filename)
            set(mui_localpathstring, MUIA_String_Contents, localpath)
            set(mui_remotepathstring, MUIA_String_Contents, remotepath)
            set(mui_httpsitestring, MUIA_String_Contents, httpsite)
            IF StrCmp('anonymous',username)=TRUE
                set(mui_checkmark, MUIA_Pressed, MUI_TRUE)
                set(mui_checkmark, MUIA_Selected, MUI_TRUE)
            ENDIF
            set(mui_mainwindow, MUIA_Window_Sleep, MUI_TRUE)
            loadsites(mui_sitedirlist)
            doMethodA(mui_sitedirlist, [MUIM_List_Sort])

            set(mui_addwindow, MUIA_Window_Open, MUI_TRUE)

        CASE ID_BEEPON
            set(mui_prefsbeep, MUIA_Pressed, MUI_TRUE)
            set(mui_prefsbeep, MUIA_Selected, MUI_TRUE)
            p.beep:=TRUE

        CASE ID_BEEPOFF
            set(mui_prefsbeep, MUIA_Pressed, FALSE)
            set(mui_prefsbeep, MUIA_Selected, FALSE)
            p.beep:=FALSE

        CASE ID_KEEPALIVEON
            set(mui_prefskeepalive, MUIA_Pressed, MUI_TRUE)
            set(mui_prefskeepalive, MUIA_Selected, MUI_TRUE)
            p.keepalive:=TRUE

        CASE ID_KEEPALIVEOFF
            set(mui_prefskeepalive, MUIA_Pressed, FALSE)
            set(mui_prefskeepalive, MUIA_Selected, FALSE)
            p.keepalive:=FALSE

        CASE ID_SHOWPROFSON
            set(mui_prefsshowprofs, MUIA_Pressed, MUI_TRUE)
            set(mui_prefsshowprofs, MUIA_Selected, MUI_TRUE)
            p.showprofs:=TRUE

        CASE ID_SHOWPROFSOFF
            set(mui_prefsshowprofs, MUIA_Pressed, FALSE)
            set(mui_prefsshowprofs, MUIA_Selected, FALSE)
            p.showprofs:=FALSE

        CASE ID_RETAINON
            set(mui_prefsretain, MUIA_Pressed, MUI_TRUE)
            set(mui_prefsretain, MUIA_Selected, MUI_TRUE)
            p.retain:=TRUE

        CASE ID_RETAINOFF
            set(mui_prefsretain, MUIA_Pressed, FALSE)
            set(mui_prefsretain, MUIA_Selected, FALSE)
            p.retain:=FALSE

        CASE ID_RETAINTOON
            set(mui_prefsretaintout, MUIA_Pressed, MUI_TRUE)
            set(mui_prefsretaintout, MUIA_Selected, MUI_TRUE)
            p.retaintout:=TRUE

        CASE ID_RETAINTOOFF
            set(mui_prefsretaintout, MUIA_Pressed, FALSE)
            set(mui_prefsretaintout, MUIA_Selected, FALSE)
            p.retaintout:=FALSE

        CASE ID_RETAINFNFON
            set(mui_prefsretainfnf, MUIA_Pressed, MUI_TRUE)
            set(mui_prefsretainfnf, MUIA_Selected, MUI_TRUE)
            p.retainfnf:=TRUE

        CASE ID_RETAINFNFOFF
            set(mui_prefsretainfnf, MUIA_Pressed, FALSE)
            set(mui_prefsretainfnf, MUIA_Selected, FALSE)
            p.retainfnf:=FALSE

        CASE ID_GETONNORESUMEON
            set(mui_prefsgetonnoresume, MUIA_Pressed, MUI_TRUE)
            set(mui_prefsgetonnoresume, MUIA_Selected, MUI_TRUE)
            p.getonnoresume:=TRUE

        CASE ID_GETONNORESUMEOFF
            set(mui_prefsgetonnoresume, MUIA_Pressed, FALSE)
            set(mui_prefsgetonnoresume, MUIA_Selected, FALSE)
            p.getonnoresume:=FALSE

        CASE ID_EDIT -> edit button on main window
            set(mui_mainwindow, MUIA_Window_Sleep, MUI_TRUE)
            edit()
            set(mui_mainwindow, MUIA_Window_Sleep, FALSE)

        CASE ID_DELETE -> Delete profile button on main window
            get(mui_profilelist,MUIA_List_Active,{profnum})
            deleteprofile(profnum)

        CASE ID_GO  -> Go Button on main window
            set(mui_addbutton, MUIA_Disabled, MUI_TRUE)
            set(mui_editbutton, MUIA_Disabled, MUI_TRUE)
            set(mui_gobutton, MUIA_Disabled, MUI_TRUE)
            set(mui_deletebutton, MUIA_Disabled, MUI_TRUE)
            set(mui_savelogbutton, MUIA_Disabled, MUI_TRUE)
            set(mui_clearlogbutton, MUIA_Disabled, MUI_TRUE)
            set(mui_quitbutton, MUIA_Disabled, MUI_TRUE)
            set(mui_stopbutton, MUIA_Disabled, FALSE)
            IF p.showprofs=FALSE THEN set(mui_profilelv,MUIA_ShowMe, FALSE)

            WHILE result=ID_GO
                dlstatus:=1
                stopres:= doMethodA(app, [MUIM_Application_Input,{signal}])
                IF stopres<>ID_STOP
                    result:=go()
                ELSE
                    result:=stopres
                ENDIF
            ENDWHILE
                dlstatus:=0
            set(mui_profilelv,MUIA_ShowMe, MUI_TRUE)
            set(mui_addbutton, MUIA_Disabled, FALSE)
            set(mui_editbutton, MUIA_Disabled, FALSE)
            set(mui_gobutton, MUIA_Disabled, FALSE)
            set(mui_deletebutton, MUIA_Disabled, FALSE)
            set(mui_savelogbutton, MUIA_Disabled, FALSE)
            set(mui_clearlogbutton, MUIA_Disabled, FALSE)
            set(mui_quitbutton, MUIA_Disabled, FALSE)
            set(mui_stopbutton, MUIA_Disabled, MUI_TRUE)
            doMethodA(mui_iolist, [MUIM_List_Jump, MUIV_List_Jump_Bottom])

        CASE ID_SAVELOG -> Savelog button on main window
            savelog()

        CASE ID_MINISHOW
            openminilog()

        CASE ID_MINIHIDE
            closeminilog()

        CASE ID_SAVEPREFS
            saveprefs()

        /*Add Window Related Messages*/
        CASE ID_POPSITEDIR -> Popup site dir button on add window
            set(mui_sitedirlv,MUIA_ShowMe, MUI_TRUE)
            set(mui_delsitebutton,MUIA_ShowMe, MUI_TRUE)

        CASE ID_POPSITEDIROFF -> Popup site dir button on add window
            set(mui_sitedirlv,MUIA_ShowMe, FALSE)
            set(mui_delsitebutton,MUIA_ShowMe, FALSE)

        CASE ID_FILLINSITE -> Double click in site dir listview
            doMethodA(mui_sitedirlist,[MUIM_List_GetEntry,MUIV_List_GetEntry_Active,{sitebuffer}])
            StrCopy(site,sitebuffer)
            SetAttrsA(mui_sitestring,[Eval(`(MUIA_String_Contents)),site,TAG_DONE])

        CASE ID_CHECKON -> Anon checkmark button on add window
            StrCopy(username,'anonymous')
            StrCopy(password,anonpass)
            set(mui_usernamestring,MUIA_String_Contents,username)
            set(mui_passwordstring,MUIA_String_Contents,password)
            set(mui_usernamestring,MUIA_Disabled, MUI_TRUE)
            set(mui_passwordstring,MUIA_Disabled, MUI_TRUE)
            set(mui_checkmark, MUIA_ShortHelp,'Untick to Perform Named Login')

        CASE ID_CHECKOFF -> Anon checkmark button on add window
            set(mui_usernamestring,MUIA_Disabled, FALSE)
            set(mui_passwordstring,MUIA_Disabled, FALSE)
            set(mui_checkmark, MUIA_ShortHelp,'Tick to Perform Anonymous Login')

        CASE ID_FREQ -> File Requestor button on Add Window.
            IF freq(TRUE)<>0
                StrCopy(rtpath,freqpath)
                StrCopy(localpath,rtpath)
                StrCopy(httplocalpath, rtpath)
                SetAttrsA(mui_localpathstring,[Eval(`(MUIA_String_Contents)),localpath,TAG_DONE])
                SetAttrsA(mui_httplocalpathstring,[Eval(`(MUIA_String_Contents)),httplocalpath, TAG_DONE])
            ENDIF

        CASE ID_PREFSFREQ
            IF freq(TRUE)<>0
                StrCopy(rtpath, freqpath)
                StrCopy(deflocalpath, freqpath)
                StrCopy(localpath, freqpath)
                StrCopy(httplocalpath, freqpath)
                SetAttrsA(mui_prefsdownload, [Eval(`(MUIA_String_Contents)),deflocalpath,TAG_DONE])
            ENDIF

        CASE ID_OK  -> OK button on add Window Pressed.
            IF StrCmp(site, 'ftp://', 6)=TRUE
                MidStr(site, site, 6, ALL)
            ENDIF
            StringF(addtolist,'\ei(FTP)  :  \en\ebSite:\en \s:\s   \ebLogin:\en \s   \ebFile:\en \s',site,port,username,filename)
            doMethodA(mui_profilelist, [MUIM_List_InsertSingle, addtolist, MUIV_List_Insert_Bottom ])
            saveprofiles()
            set(mui_addwindow, MUIA_Window_Open, FALSE)
            savesites(mui_sitedirlist)
            doMethodA(mui_sitedirlist, [MUIM_List_Clear])
            set(mui_mainwindow, MUIA_Window_Sleep, FALSE)

        CASE ID_HTTPOK
            IF StrCmp(httpsite, 'http://', 7)=TRUE
                MidStr(httpsite, httpsite, 7, ALL)
            ENDIF
            StringF(addtolist,'\ei(HTTP):  \en\ebSite:\en \s:\s',httpsite,httpport)
            doMethodA(mui_profilelist, [MUIM_List_InsertSingle, addtolist, MUIV_List_Insert_Bottom ])
            savehttpprofiles()
            set(mui_addwindow, MUIA_Window_Open, FALSE)
            savesites(mui_sitedirlist)
            doMethodA(mui_sitedirlist, [MUIM_List_Clear])
            set(mui_mainwindow, MUIA_Window_Sleep, FALSE)

        CASE ID_CANCEL -> Cancel button on Add window
            set(mui_addwindow, MUIA_Window_Open, FALSE)
            savesites(mui_sitedirlist)
            doMethodA(mui_sitedirlist, [MUIM_List_Clear])
            set(mui_mainwindow, MUIA_Window_Sleep, FALSE)

    ENDSELECT
    IF (running AND signal) THEN Wait(signal)
ENDWHILE

EXCEPT DO
    END st

    IF app THEN Mui_DisposeObject(app)
    IF muimasterbase THEN CloseLibrary(muimasterbase)
    IF reqtoolsbase THEN CloseLibrary(reqtoolsbase)
    IF diskobj THEN FreeDiskObject(diskobj)
    IF iconbase THEN CloseLibrary(iconbase)
    IF socketbase THEN CloseLibrary(socketbase)
    IF gadtoolsbase THEN CloseLibrary(gadtoolsbase)
    closeminilog()

SELECT exception
    CASE ERR_NOMUI
        WriteF('Unable to open \s \d+\n',MUIMASTER_NAME,MUIMASTER_VMIN)
    CASE ERR_NOREQ
        WriteF('Unable to open reqtools.library V38+\n')
    CASE ERR_NOAPP
        WriteF('Unable to create application. Is GoFetch already running?\n')
    CASE ERR_NOICON
        WriteF('Unable to open icon.library V33+\n')
    CASE ERR_NOBSD
        WriteF('Unable to open bsdsocket.library.\nPlease make sure your TCP/IP stack is running.\n')
    CASE ERR_NOGAD
        WriteF('Unable to open gadtools.library V39+\n')
ENDSELECT

ENDPROC 0


/***********************************************************
                                                           *
NAME: sendcommand                                          *
FUNCTION: Sends command to the FTP server through socket   *
INPUTS:                                                    *
    cmd - PTR to the command string, <CR/LF> is appended   *
                                                           *
***********************************************************/

PROC sendcommand(cmd:PTR TO CHAR)

DEF len=0,
    cmdstring[200]:STRING

StrCopy(cmdstring,cmd) -> Converts the string to an E String
StrAdd(cmdstring,'\b\n') -> Appends <CR/LF>
len:=EstrLen(cmdstring) -> Returns the string length inc <CR/LF>
Send(sock,cmdstring,len,MSG_WAITALL) -> Sends string through socket

ENDPROC


/***********************************************************
                                                           *
NAME:  reccommand                                           *
FUNCTION: Receives reply from server through control socket*
OUTPUTS:                                                   *
    buf - Message received from server                     *
                                                           *
***********************************************************/


PROC reccommand()
DEF buf[4096]:STRING,
    len,
    x[1]:STRING,
    readfds:fd_set,
    tv:timeval

fd_zero(readfds)
fd_set(sock,readfds)
tv.sec:=prefstimeout
tv.usec:=5

IF WaitSelect(sock+1,readfds, NIL, NIL, tv, NIL)>0

    WHILE StrCmp(x,'\n')=FALSE
        len:=Recv(sock,x,1,0)
        StrAdd(buf,x)
    ENDWHILE

    StrCopy(buf,buf,EstrLen(buf)-2)
ELSE
    StrCopy(buf,'000 Reply from server Timed Out')
ENDIF

ENDPROC buf -> Pass back as a parameter


/***********************************************************
                                                           *
NAME: controlconnection                                    *
FUNCTION: Implements command sending sequence and also     *
requests the local IP address *                            *
                                                           *
***********************************************************/
PROC controlconnect()
DEF myip,
    myipstr[50]:STRING,
    portstr[3]:STRING,
    quitflag=NIL

myip:=Gethostid()
StringF(myipstr,'\s',Inet_NtoA(myip))
StrCopy(myipstr,converttocomma(myipstr))
xferport:=xferport+1
StringF(portstr,'\d',xferport)
StrAdd(myipstr,',4,')
StrAdd(myipstr,portstr)
IF EstrLen(remotepath)=0 THEN StrCopy(remotepath,'.')


IF ((quitflag:=sendusername())=CMD_PASS) AND ((res:= doMethodA(app, [MUIM_Application_Input,{signal}]))<>ID_STOP)
    IF (sendpassword()=CMD_PASS) AND ((res:= doMethodA(app, [MUIM_Application_Input,{signal}]))<>ID_STOP)
        IF (commandtypea('CWD ',remotepath)=CMD_PASS) AND ((res:= doMethodA(app, [MUIM_Application_Input,{signal}]))<>ID_STOP)
            IF (commandtypea('TYPE ','I')=CMD_PASS) AND ((res:= doMethodA(app, [MUIM_Application_Input,{signal}]))<>ID_STOP)
                IF (commandtypea('PORT ',myipstr)=CMD_PASS) AND ((res:= doMethodA(app, [MUIM_Application_Input,{signal}]))<>ID_STOP)
                    sendsizecommand()
                    filetransfer()
                    ->commandtypea('QUIT','NOPAR')
                    ftplogout()
                ELSE
                    ->commandtypea('QUIT','NOPAR')
                    ftplogout()
                ENDIF
            ELSE
                commandtypea('QUIT','NOPAR')
                ftplogout()
            ENDIF
        ELSE
            ->commandtypea('QUIT','NOPAR')
            ftplogout()
        ENDIF
    ELSE
        ->commandtypea('QUIT','NOPAR')
        ftplogout()
    ENDIF
ELSE
        IF quitflag<>CMD_NOQUIT
            ->commandtypea('QUIT','NOPAR')
            ftplogout()
        ENDIF
ENDIF


ENDPROC



/***********************************************************
                                                           *
NAME: controlconnection1                                    *
FUNCTION: Implements command sending sequence and also     *
requests the local IP address *                            *
                                                           *
***********************************************************/
PROC controlconnect1()
DEF myip,
    myipstr[50]:STRING,
    portstr[3]:STRING

myip:=Gethostid()
StringF(myipstr,'\s',Inet_NtoA(myip))
StrCopy(myipstr,converttocomma(myipstr))
xferport:=xferport+1
StringF(portstr,'\d',xferport)
StrAdd(myipstr,',4,')
StrAdd(myipstr,portstr)
IF EstrLen(remotepath)=0 THEN StrCopy(remotepath,'.')


        IF (commandtypea('CWD ',remotepath)=CMD_PASS) AND ((res:= doMethodA(app, [MUIM_Application_Input,{signal}]))<>ID_STOP)
            IF (commandtypea('TYPE ','I')=CMD_PASS) AND ((res:= doMethodA(app, [MUIM_Application_Input,{signal}]))<>ID_STOP)
                IF (commandtypea('PORT ',myipstr)=CMD_PASS) AND ((res:= doMethodA(app, [MUIM_Application_Input,{signal}]))<>ID_STOP)
                    sendsizecommand()
                    filetransfer()
                    ->commandtypea('QUIT','NOPAR')
                ELSE
                    ->commandtypea('QUIT','NOPAR')
                    ftplogout()
                ENDIF
            ELSE
                commandtypea('QUIT','NOPAR')
                ftplogout()
            ENDIF
        ELSE
            ->commandtypea('QUIT','NOPAR')
            ftplogout()
        ENDIF
ENDPROC

/***********************************************************
                                                           *
NAME: controlconnection2                                    *
FUNCTION: Implements command sending sequence and also     *
requests the local IP address *                            *
                                                           *
***********************************************************/
PROC controlconnect2()
DEF myip,
    myipstr[50]:STRING,
    portstr[3]:STRING

myip:=Gethostid()
StringF(myipstr,'\s',Inet_NtoA(myip))
StrCopy(myipstr,converttocomma(myipstr))
xferport:=xferport+1
StringF(portstr,'\d',xferport)
StrAdd(myipstr,',4,')
StrAdd(myipstr,portstr)
IF EstrLen(remotepath)=0 THEN StrCopy(remotepath,'.')


    IF (commandtypea('CWD ',remotepath)=CMD_PASS) AND ((res:= doMethodA(app, [MUIM_Application_Input,{signal}]))<>ID_STOP)
            IF (commandtypea('TYPE ','I')=CMD_PASS) AND ((res:= doMethodA(app, [MUIM_Application_Input,{signal}]))<>ID_STOP)
                IF (commandtypea('PORT ',myipstr)=CMD_PASS) AND ((res:= doMethodA(app, [MUIM_Application_Input,{signal}]))<>ID_STOP)
                    sendsizecommand()
                    filetransfer()
                    ->commandtypea('QUIT','NOPAR')
                    ftplogout()
                ELSE
                    ->commandtypea('QUIT','NOPAR')
                    ftplogout()
                ENDIF
            ELSE
                commandtypea('QUIT','NOPAR')
                ftplogout()
            ENDIF
        ELSE
            ->commandtypea('QUIT','NOPAR')
            ftplogout()
        ENDIF


ENDPROC



/***********************************************************
                                                           *
NAME: controlconnection3                                    *
FUNCTION: Implements command sending sequence and also     *
requests the local IP address *                            *
                                                           *
***********************************************************/
PROC controlconnect3()
DEF myip,
    myipstr[50]:STRING,
    portstr[3]:STRING,
    quitflag=NIL

myip:=Gethostid()
StringF(myipstr,'\s',Inet_NtoA(myip))
StrCopy(myipstr,converttocomma(myipstr))
xferport:=xferport+1
StringF(portstr,'\d',xferport)
StrAdd(myipstr,',4,')
StrAdd(myipstr,portstr)
IF EstrLen(remotepath)=0 THEN StrCopy(remotepath,'.')


IF ((quitflag:=sendusername())=CMD_PASS) AND ((res:= doMethodA(app, [MUIM_Application_Input,{signal}]))<>ID_STOP)
    IF (sendpassword()=CMD_PASS) AND ((res:= doMethodA(app, [MUIM_Application_Input,{signal}]))<>ID_STOP)
        IF (commandtypea('CWD ',remotepath)=CMD_PASS) AND ((res:= doMethodA(app, [MUIM_Application_Input,{signal}]))<>ID_STOP)
            IF (commandtypea('TYPE ','I')=CMD_PASS) AND ((res:= doMethodA(app, [MUIM_Application_Input,{signal}]))<>ID_STOP)
                IF (commandtypea('PORT ',myipstr)=CMD_PASS) AND ((res:= doMethodA(app, [MUIM_Application_Input,{signal}]))<>ID_STOP)
                    sendsizecommand()
                    filetransfer()
                    ->commandtypea('QUIT','NOPAR')
                ELSE
                    ->commandtypea('QUIT','NOPAR')
                    ftplogout()
                ENDIF
            ELSE
                commandtypea('QUIT','NOPAR')
                ftplogout()
            ENDIF
        ELSE
            ->commandtypea('QUIT','NOPAR')
            ftplogout()
        ENDIF
    ELSE
        ->commandtypea('QUIT','NOPAR')
        ftplogout()
    ENDIF
ELSE
        IF quitflag<>CMD_NOQUIT
            ->commandtypea('QUIT','NOPAR')
            ftplogout()
        ENDIF
ENDIF


ENDPROC




/***********************************************************
                                                           *
NAME: sendusername                                         *
FUNCTION: Sends username through control socket            *
OUTPUTS:                                                   *
    success - =CMD_FAIL if failure returncode received     *
    success - =CMD_PASS if success returncode received     *
                                                           *
***********************************************************/
PROC sendusername()
DEF str[4096]:STRING,
    rc[4]:STRING,
    un[500]:STRING,
    rec220=FALSE,
    rcnum,
    success

outlist('\eb#Sending username')
outmini('Loggin In...')
StringF(un,'USER \s',username)
sendcommand(un)
outlist(un)
str:=reccommand()
outlist(str)
StrCopy(rc,str,4)
rcnum:=Val(rc)

SELECT 999 OF rcnum
    CASE 220
        rec220:=TRUE
        success:=CMD_PASS
    CASE 230, 332, 331
        success:=CMD_PASS
    CASE 421
        success:=CMD_NOQUIT
    DEFAULT
        success:=CMD_FAIL
ENDSELECT

IF success=CMD_PASS
    WHILE InStr(rc,'-',0) > FALSE -> Indicates more text
        str:=reccommand()
        outlist(str)
        StrCopy(rc,str,4)
    ENDWHILE

    IF rec220=TRUE
        str:=reccommand()
        outlist(str)
        StrCopy(rc,str,4)
        rcnum:=Val(rc)

        SELECT 999 OF rcnum
            CASE 220
                rec220:=TRUE
                success:=CMD_PASS
            CASE 230, 332, 331
                success:=CMD_PASS
            CASE 421
                success:=CMD_NOQUIT
            DEFAULT
                success:=CMD_FAIL
        ENDSELECT

        WHILE InStr(rc,'-',0) > FALSE -> Indicates more text
            str:=reccommand()
            outlist(str)
            StrCopy(rc,str,4)
        ENDWHILE
    ENDIF
ENDIF

ENDPROC success



/***********************************************************
                                                           *
NAME: sendpassword                                         *
FUNCTION: Sends password command+param through conrol sock.*
OUTPUTS:                                                   *
    success - =CMD_FAIL if failure returncode received     *
              =CMD_PASS if success returncode received     *
***********************************************************/
PROC sendpassword()
DEF str[4096]:STRING,
    rc[4]:STRING,
    pw[500]:STRING,
    success

outlist('\eb#Sending Password')
StringF(pw,'PASS \s',password)
sendcommand(pw)
outlist('PASS ****')
str:=reccommand()
outlist(str)
StrCopy(rc,str,4)

IF StrCmp(rc,'230',3)=TRUE
    success:=CMD_PASS
ELSE
    success:=CMD_FAIL
ENDIF

IF success=CMD_PASS
    WHILE StrCmp(rc,'230 ',4) = FALSE -> Indicates more text
        str:=reccommand()
        outlist(str)
        StrCopy(rc,str,4)
    ENDWHILE
ENDIF

ENDPROC success


PROC commandtypea(cmd:PTR TO CHAR, param:PTR TO CHAR)
DEF str[4096]:STRING,
    rc[4]:STRING,
    command[500]:STRING,
    success

StrCopy(command,cmd)

IF StrCmp(param,'NOPAR',5)=TRUE
    sendcommand(command)
ELSE
    StrAdd(command,param)
    sendcommand(command)
ENDIF

outlist(command)
StrCopy(str,reccommand())
outlist(str)
StrCopy(rc, str, 4)

IF rc[3]=HYPHEN
    rc[3]:=SPACE
    REPEAT 
        StrCopy(str, reccommand())
        outlist(str)
    UNTIL StrCmp(str,rc, 4)=TRUE
ENDIF



IF StrCmp(rc,'200',1)=TRUE
    success:=CMD_PASS
ELSE
    success:=CMD_FAIL
ENDIF

ENDPROC success


PROC commandtypeb(cmd:PTR TO CHAR, param:PTR TO CHAR)
DEF str[4096]:STRING,
    rc[4]:STRING,
    command[500]:STRING,
    success

StrCopy(command,cmd)

IF StrCmp(param,'NOPAR',5)=TRUE
    sendcommand(command)
ELSE
    StrAdd(command,param)
    sendcommand(command)
ENDIF

outlist(command)
StrCopy(str,reccommand())
outlist(str)
StrCopy(rc,str,4)

IF rc[3]=HYPHEN
    rc[3]:=SPACE
    REPEAT
        StrCopy(str, reccommand())
        outlist(str)
    UNTIL StrCmp(str, rc, 4)=TRUE
ENDIF

IF StrCmp(rc,'2',1)=TRUE
    success:=CMD_PASS
ELSE
    success:=CMD_FAIL
ENDIF

IF StrCmp(rc,'501',3)= TRUE THEN success:=CMD_FILENOTFOUND
IF StrCmp(rc,'1',1)=TRUE THEN success:=CMD_PASS


ENDPROC success


PROC commandtypec(cmd:PTR TO CHAR, param:PTR TO CHAR)
DEF str[4096]:STRING,
    rc[4]:STRING,
    command[500]:STRING,
    success

StrCopy(command,cmd)

IF StrCmp(param,'NOPAR',5)=TRUE
    sendcommand(command)
ELSE
    StrAdd(command,param)
    sendcommand(command)
ENDIF

outlist(command)
StrCopy(str,reccommand())
outlist(str)
StrCopy(rc,str,4)

IF rc[3]=HYPHEN
    rc[3]:=SPACE
    REPEAT
        StrCopy(str, reccommand())
        outlist(str)
    UNTIL StrCmp(str, rc, 4)=TRUE
ENDIF

IF StrCmp(rc,'200',1)=TRUE
    success:=CMD_PASS
ELSE
    success:=CMD_FAIL
ENDIF

IF StrCmp(rc,'3',1)=TRUE THEN success:=CMD_PASS


ENDPROC success
/***********************************************************
                                                           *
NAME: filetransfer                                         *
FUNCTION: Creates a new socket for receiving the file xfer *
socket and receives a file                                 *
OUTPUTS:                                                   *
    None, but alters several global variables              *
                                                           *
***********************************************************/
PROC filetransfer()
DEF my_addr:PTR TO sockaddr_in,
    sockfd,
    new_fd,
    fh,
    path_filename[500]:STRING,
    cpsstr[50]:STRING,
    cpsrecv=0,
    buffer,
    lenreceived,
    mui_xferwindow,
    mui_xfergauge,
    readfds:fd_set,
    tv:timeval,
    appresult,
    timerec=1


res:=NIL
xferfilelen:=xferfilelen/1024 -> Set filelength to K
StringF(path_filename,'\s\s',localpath,filename) -> Setup local path

mui_xferwindow, mui_xfergauge:=setupxferwin()

-> Set up file xfersocket
my_addr:=New(SIZEOF sockaddr_in)
my_addr.family:=AF_INET
my_addr.addr.addr:=INADDR_ANY
my_addr.port:=xferport+1024

IF (sockfd:=Socket(AF_INET, SOCK_STREAM,0))<>-1
    IF (Bind(sockfd, my_addr, SIZEOF sockaddr_in))=-1
        outlist('\eb#Error associated with bind command')
        outmini('Bind Associated Error')
        closexferwinnotopen(mui_xferwindow)
    ELSE
        IF (Listen(sockfd,5))=-1
            outlist('\eb#Error with listen command')
            outmini('Listen Associated Error')
        ELSE
            cpsrecv:=resume(path_filename)
            IF (commandtypeb('RETR ', filename))=CMD_PASS
                IF (new_fd:=Accept(sockfd,NIL,NIL))=-1
                    outlist('\eb#Error associated with accept command')
                    outmini('Accept Associated Error')
                ELSE
                    IF (fh:=Open(path_filename,MODE_READWRITE))=NIL
                        outlist('\eb#WARNING: Unable to save file')
                        outmini('Unable to save file')
                    ELSE
                        Seek(fh,NIL,OFFSET_END)
                        buffer:=New(prefsxferbuffer*1024) -> Set up receive buffer
                        IF sizecmdsuccess=TRUE
                            set(mui_xferwindow,MUIA_Window_Open,MUI_TRUE)
                            set(mui_xfergauge, MUIA_Gauge_Current, cpsrecv)
                        ENDIF
                        outlist('\eb#Please Wait... Receiving File')
                        outmini('Receiving File...')
                        fd_zero(readfds)
                        fd_set(new_fd,readfds)
                        tv.sec:=prefstimeout
                        tv.usec:=5

                        ->Start Timer off for 5 seconds
                        st.startTimer(5)
                        dlstatus:=2
                        WHILE res<1
                            appresult:= doMethodA(app, [MUIM_Application_Input,{signal}])
                            SELECT appresult
                                CASE ID_STOP
                                    res:=ID_STOP
                                CASE ID_ABORT
                                    res:=ID_ABORT
                                CASE ID_MINISHOW
                                    openminilog()
                                CASE ID_MINIHIDE
                                    closeminilog()
                            ENDSELECT

                            IF (WaitSelect(new_fd+1,readfds, NIL, NIL, tv, NIL))=0
                                res:=ST_TIMEOUT
                            ELSE
                                IF (lenreceived:=Recv(new_fd,buffer,prefsxferbuffer*1024,0))>0

                                    timerec:=timerec+lenreceived

                                    ->When time request run out,
                                    ->calculate CPS then send another
                                    IF st.getTimerMsg()=TRUE
                                        timerec:=Div(timerec, 5)
                                        StringF(cpsstr, '\ecCPS Transfer Rate: \d', timerec)
                                         SetAttrsA(mui_cpsrate,[Eval(`(MUIA_Text_Contents)), cpsstr, TAG_DONE])
                                        timerec:=1
                                        st.waitAndRestart(5)
                                    ENDIF

                                    Write(fh,buffer,lenreceived)
                                    cpsrecv:=(cpsrecv+lenreceived)

                                    set(mui_xfergauge,MUIA_Gauge_Current, cpsrecv)
                                    fd_zero(readfds)
                                    fd_set(new_fd,readfds)
                                    tv.sec:=prefstimeout
                                    tv.usec:=5
                                ELSE
                                    res:=ST_XFEROK
                                ENDIF
                            ENDIF
                           
                        ENDWHILE
                        dlstatus:=1
                        st.stopTimer()

                          ->IF (CheckIO(ioreq)=0)
                          ->      AbortIO(ioreq)
                          ->>      WaitIO(ioreq)
                          ->  ENDIF
                        SELECT res
                            CASE ID_ABORT
                                outlist('\eb#Transfer Aborted')
                                outmini('Transfer Aborted')
                                commandtypea('ABOR','NOPAR')
                            CASE ST_TIMEOUT
                                outlist('\eb#File Transfer Timed Out')
                                outmini('Timed Out')
                            CASE ST_XFEROK
                                outlist('\eb#File Transfer OK')
                                outmini('Transfer OK')
                            CASE ID_STOP
                                outlist('\eb#Stopping All File Transfers. Please wait...')
                                outmini('Stopping All Transfers')
                        ENDSELECT

                        closexferwin(mui_xferwindow)
                        Close(fh)

                        /*Add File Comment*/

                        addcomment(path_filename, PROTOCOL_FTP)
 

                        IF FileLength(path_filename)<(xferfilelen*1024)
                            outlist('\eb#Note: File received is shorter than expected length, file may be corrupt!')
                        ELSE
                            outlist(reccommand())
                        ENDIF
                    ENDIF
                ENDIF
            ELSE -> Jump here if file not found
                closexferwinnotopen(mui_xferwindow)
                outlist('\eb#WARNING: Error starting file transfer. (File might not be on server)')
                outmini('File Transfer Error')
                res:=CMD_FILENOTFOUND
            ENDIF
        ENDIF -> Jump here if listen fails
    ENDIF -> Jump here if Bind fails
        CloseSocket(sockfd)
        CloseSocket(new_fd)
ELSE -> Jump here if socket opening fails
    outlist('\eb#Error: unable to create file transfer socket')
    outmini('Socket Error')
ENDIF
Dispose(buffer)
ENDPROC


/***********************************************************
                                                           *
NAME: sendsizecommand                                      *
FUNCTION: Sends SIZE command through control socket        *
OUTPUTS:                                                   *
    None, but alters the integer xferfilelen to file size  *
                                                           *
***********************************************************/
PROC sendsizecommand()
DEF sizexfer[500]:STRING,
    str[500]:STRING

StringF(sizexfer,'SIZE \s\b\n',filename)
Send(sock,sizexfer,EstrLen(sizexfer),0)
StrCopy(sizexfer,sizexfer,EstrLen(sizexfer)-2)
outlist(sizexfer)
outlist(str:=reccommand())

IF StrCmp(str,'2',1)=TRUE
    MidStr(str,str,4,ALL)
    xferfilelen:=Val(str)
    sizecmdsuccess:=TRUE
ELSE
    sizecmdsuccess:=FALSE
    xferfilelen:=0
ENDIF

ENDPROC


/***********************************************************
                                                           *
NAME: converttocomma                                       *
FUNCTION: Converts . in IP to , which is used for PORT cmd *
INPUTS:                                                    *
    ip - PTR to ip string of the form 'XXX.XXX.XXX.XXX'    *
OUTPUTS:                                                   *
    ipstr - PTR to ip string of the form 'XXX,XXX,XXX,XXX' *
                                                           *
***********************************************************/
PROC converttocomma(ip:PTR TO CHAR)
DEF ipstr[50]:STRING,
    x

StrCopy(ipstr, ip)
FOR x:=0 TO (EstrLen(ipstr)-1)
    IF ipstr[x]=46 THEN ipstr[x]:=44
ENDFOR
ENDPROC ipstr


/***********************************************************
                                                           *
NAME: freq                                                 *
FUNCTION: Opens a filerequestor to request a directory     *
OUTPUTS:                                                   *
    filepath - The chosen filepath                         *
                                                           *
***********************************************************/
PROC freq(defdir)
DEF req:PTR TO rtfilerequester,
    ret,
    filepath[500]:STRING,
    w
set(mui_mainwindow, MUIA_Window_Sleep, MUI_TRUE)
req:=RtAllocRequestA(RT_FILEREQ,NIL)
GetAttr(MUIA_Window_Window,mui_mainwindow,{w})
IF defdir=TRUE
    RtChangeReqAttrA(req,[RTFI_DIR,localpath,NIL,NIL])
ELSE
    RtChangeReqAttrA(req,[RTFI_DIR,'ram:',NIL,NIL])
ENDIF
ret:=RtFileRequestA(req,NIL,'Choose Directory',[RT_WINDOW,w,RTFI_FLAGS,FREQF_NOFILES,RT_INTUIMSGFUNC, ref_refreshhook, RT_SHAREIDCMP, TRUE, NIL,NIL])

IF ret<>FALSE
    StrCopy(filepath,req.dir, ALL)
    IF (filepath[(EstrLen(filepath)-1)])<>58 THEN StrAdd(filepath,'/')
    StrCopy(freqpath,filepath)
ENDIF

IF req THEN RtFreeRequest(req)
set(mui_mainwindow, MUIA_Window_Sleep, FALSE)
ENDPROC ret


/***********************************************************
                                                           *
NAME: outlist                                              *
FUNCTION: Outputs to the io listview then jumps to the     *
bottom                                                     *
                                                           *
***********************************************************/
PROC outlist(str:PTR TO CHAR)

doMethodA(mui_iolist, [MUIM_List_InsertSingle,str,MUIV_List_Insert_Bottom ])
doMethodA(mui_iolist, [MUIM_List_Jump, MUIV_List_Jump_Bottom])
ENDPROC



PROC outhist(str:PTR TO CHAR, protocol)
DEF text[500]:STRING

IF protocol=PROTOCOL_FTP
    StringF(text,'\ei(FTP) :  \en\ebSite:\en \s:\s   \ebLogin:\en \s   \ebFile:\en \s   \ebStatus:\en \s',site, port, username, filename, str)
ELSE
    StringF(text,'\ei(HTTP):  \en\ebSite:\en \s:\s   \ebStatus:\en \s',httpsite,httpport,str)
ENDIF

doMethodA(mui_historylist, [MUIM_List_InsertSingle,text,MUIV_List_Insert_Bottom ])
ENDPROC
/***********************************************************
                                                           *
NAME: savelog                                              *
FUNCTION: Saves the text in the io listview                *
                                                           *
***********************************************************/
PROC savelog()
DEF filepath[500]:STRING,
    entries,
    ent,
    entry[500]:STRING,
    fh,
    i

IF freq(FALSE)<>0
    StringF(filepath,'\s\s',freqpath,'gofetch.log')
    GetAttr(MUIA_List_Entries,mui_iolist,{entries})
    IF (fh:=Open(filepath,MODE_NEWFILE))<>NIL
        outlist('\eb#Saving Log, Please wait...')
        outmini('Saving Log')
        FOR i:=0 TO (entries-1)
            doMethodA(mui_iolist,[MUIM_List_GetEntry,i,{ent}])
            StringF(entry,'\s\n',ent)
            Write(fh,entry,EstrLen(entry))
        ENDFOR
        Close(fh)
        outlist('\eb#Log saved successfully')
    ELSE
        outlist('\eb#Unable to create logfile')
        outmini('Unable to save log')
    ENDIF
ELSE
    outlist('\eb#Save Log Cancelled')
ENDIF

ENDPROC


/***********************************************************
                                                           *
NAME: saveprofiles                                         *
FUNCTION: Saves the currently added profile.               *
Structure of the prefs file is as follows:-                *
{} Are Comments. All lines are followed by <LF>            *
#{Separates profiles*                                      *
site{String, MaxLen 500}                                   *
port{String, MaxLen 20}                                    *
username{String, MaxLen 500}                               *
password{String, MaxLen 500}                               *
remotepath{String, MaxLen 500}                             *
filename{String, MaxLen 500}                               *
localpath{String, MaxLen 500}                              *
                                                           *
***********************************************************/
PROC saveprofiles()
DEF fh,
    sepchar[3]:STRING

StrCopy(sepchar,'#\n')

IF (fh:=Open('PROGDIR:gofetch.profs',MODE_READWRITE))=NIL
    outlist('\eb#Warning: Unable to save profiles')
    outmini('Cant Save Profiles')
ELSE
    Seek(fh,NIL,OFFSET_END)
    Write(fh,sepchar,EstrLen(sepchar))
    Write(fh,site,StrLen(site))
    Write(fh,'\n',1)
    Write(fh,port,StrLen(port))
    Write(fh,'\n',1)
    Write(fh,username,StrLen(username))
    Write(fh,'\n',1)
    Write(fh,password,StrLen(password))
    Write(fh,'\n',1)
    Write(fh,remotepath,StrLen(remotepath))
    Write(fh,'\n',1)
    Write(fh,filename,StrLen(filename))
    Write(fh,'\n',1)
    Write(fh,localpath,StrLen(localpath))
    Write(fh,'\n',1)
    Close(fh)
ENDIF

ENDPROC


/***********************/


PROC savehttpprofiles()
DEF fh,
    sepchar[3]:STRING

StrCopy(sepchar,'*\n')

IF (fh:=Open('PROGDIR:gofetch.profs',MODE_READWRITE))=NIL
    outlist('\eb#Warning: Unable to save profiles')
    outmini('Cant Save Profiles')
ELSE
    Seek(fh,NIL,OFFSET_END)
    Write(fh,sepchar,EstrLen(sepchar))
    Write(fh,httpsite,StrLen(httpsite))
    Write(fh,'\n',1)
    Write(fh,httpport,StrLen(httpport))
    Write(fh,'\n',1)
    ->Write(fh,username,StrLen(username))
    Write(fh,'\n',1)
    ->Write(fh,password,StrLen(password))
    Write(fh,'\n',1)
    ->Write(fh,remotepath,StrLen(remotepath))
    Write(fh,'\n',1)
    ->Write(fh,filename,StrLen(filename))
    Write(fh,'\n',1)
    Write(fh,httplocalpath,StrLen(httplocalpath))
    Write(fh,'\n',1)
    Close(fh)
ENDIF
ENDPROC



/***********************************************************
                                                           *
NAME: returnprofile                                        *
FUNCTION: Files the appropriate strings with the selected  *
profile number, from the profiles file.                    *
                                                           *
***********************************************************/
PROC returnprofile(num)
DEF fh,
    instr[500]:STRING,
    teststr[500]:STRING,
    count=-1,
    protocol=NIL

IF (fh:=Open('PROGDIR:gofetch.profs',MODE_OLDFILE))=NIL
    outlist('No Preferences File Found')
ELSE
    WHILE count<num
        Fgets(fh,instr,500)
        StrCopy(teststr,instr)
        IF StrCmp(teststr,'#',1)=TRUE THEN count:=count+1
        IF StrCmp(teststr,'*',1)=TRUE THEN count:=count+1
    ENDWHILE

    IF StrCmp(teststr,'#',1)= TRUE
        protocol:=PROTOCOL_FTP
        Fgets(fh,instr,500)
        StrCopy(site,instr,StrLen(instr)-1)
        Fgets(fh,instr,500)
        StrCopy(port,instr,StrLen(instr)-1)
        Fgets(fh,instr,500)
        StrCopy(username,instr,StrLen(instr)-1)
        Fgets(fh,instr,500)
        StrCopy(password,instr,StrLen(instr)-1)
        Fgets(fh,instr,500)
        StrCopy(remotepath,instr,StrLen(instr)-1)
        Fgets(fh,instr,500)
        StrCopy(filename,instr,StrLen(instr)-1)
        Fgets(fh,instr,500)
        StrCopy(localpath,instr,StrLen(instr)-1)
        Close(fh)
    ELSE
        protocol:=PROTOCOL_HTTP
            Fgets(fh,instr,500)
            StrCopy(httpsite,instr,StrLen(instr)-1)
            Fgets(fh,instr,500)
            StrCopy(httpport,instr,StrLen(instr)-1)
            Fgets(fh,instr,500)
            ->StrCopy(username,instr,StrLen(instr)-1)
            Fgets(fh,instr,500)
            ->StrCopy(password,instr,StrLen(instr)-1)
            Fgets(fh,instr,500)
            ->StrCopy(remotepath,instr,StrLen(instr)-1)
            Fgets(fh,instr,500)
            ->StrCopy(filename,instr,StrLen(instr)-1)
            Fgets(fh,instr,500)
            StrCopy(httplocalpath,instr,StrLen(instr)-1)
            Close(fh)
    ENDIF



ENDIF

ENDPROC protocol

/***********************************************************
                                                           *
NAME: settupprofiles                                       *
FUNCTION: Simply reads the profiles file and adds them to  *
the profile list view                                      *
                                                           *
***********************************************************/
PROC setupprofiles()
DEF fh,
    instr[500]:STRING,
    teststr[500]:STRING,
    err=100,
    addtolist[500]:STRING


IF (fh:=Open('PROGDIR:gofetch.profs',MODE_OLDFILE))=NIL
    outlist('\eb#No Profiles Found')
    outmini('No Profiles Found')
ELSE
    IF FileLength('PROGDIR:gofetch.profs')>0
        outlist('\eb#Loading Profiles...')
        outmini('Loading Profiles')
        WHILE err<>0
            err:=Fgets(fh,instr,500)
            StrCopy(teststr,instr)
            IF StrCmp(teststr,'#',1)=TRUE
                Fgets(fh,instr,500)
                StrCopy(site,instr,StrLen(instr)-1)

                Fgets(fh,instr,500)
                StrCopy(port,instr,StrLen(instr)-1)

                Fgets(fh,instr,500)
                StrCopy(username,instr,StrLen(instr)-1)

                Fgets(fh,instr,500)
                Fgets(fh,instr,500)
                Fgets(fh,instr,500)
                StrCopy(filename,instr,StrLen(instr)-1)
                Fgets(fh,instr,500)
                StringF(addtolist,'\ei(FTP)  :  \en\ebSite:\en \s:\s   \ebLogin:\en \s   \ebFile:\en \s',site,port,username,filename)
                doMethodA(mui_profilelist, [MUIM_List_InsertSingle, addtolist, MUIV_List_Insert_Bottom ])
            ENDIF
            IF StrCmp(teststr,'*',1)=TRUE
                    Fgets(fh,instr,500)
                    StrCopy(httpsite,instr,StrLen(instr)-1)

                    Fgets(fh,instr,500)
                    StrCopy(httpport,instr,StrLen(instr)-1)

                    Fgets(fh,instr,500)

                    Fgets(fh,instr,500)
                    Fgets(fh,instr,500)
                    Fgets(fh,instr,500)

                    Fgets(fh,instr,500)
                    StringF(addtolist,'\ei(HTTP):  \en\ebSite:\en \s:\s',httpsite, httpport)
                    doMethodA(mui_profilelist, [MUIM_List_InsertSingle, addtolist, MUIV_List_Insert_Bottom ])
            ENDIF

        ENDWHILE
        Close(fh)
        outlist('\eb#Profiles Loaded Successfully')
    ELSE
        Close(fh)
        outlist('\eb#No Profiles Found')
        outmini('No Profiles Found')
    ENDIF

ENDIF

ENDPROC


/***********************************************************
                                                           *
NAME: deleteprofile                                        *
                                                           *
***********************************************************/
PROC deleteprofile(profnum)
DEF fhin,
    fhout,
    count=-1,
    instr[500]:STRING,
    teststr[500]:STRING


IF profnum<0
    outlist('\eb#Please select a profile to delete')
ELSE
    doMethodA(mui_profilelist, [MUIM_List_Remove, profnum])
    outlist('\eb#Deleting Profile...')
    IF (fhin:=Open('PROGDIR:gofetch.profs',MODE_OLDFILE))=NIL
        outlist('\eb#Unable to open profiles')
    ELSE
        IF (fhout:=Open('PROGDIR:gofetch.temp',MODE_NEWFILE))=NIL
            outlist('\eb#Unable to create temporary file for deleting profiles')
        ELSE
            WHILE (Fgets(fhin,instr,500))<>0
                StrCopy(teststr,instr)
                IF StrCmp(teststr,'#',1)=TRUE THEN count:=count+1
                IF StrCmp(teststr,'*',1)=TRUE THEN count:=count+1
                IF count=profnum
                    Fgets(fhin,instr,500)
                    Fgets(fhin,instr,500)
                    Fgets(fhin,instr,500)
                    Fgets(fhin,instr,500)
                    Fgets(fhin,instr,500)
                    Fgets(fhin,instr,500)
                    Fgets(fhin,instr,500)
                ELSE
                    Write(fhout,teststr,EstrLen(teststr))
                ENDIF
            ENDWHILE
            Close(fhout)
        ENDIF

        Close(fhin)
    ENDIF
    IF DeleteFile('PROGDIR:gofetch.profs')<>TRUE
        outlist('\eb#Delete operation failed')
    ELSE
        Rename('PROGDIR:gofetch.temp','PROGDIR:gofetch.profs')
        outlist('\eb#Profile Deleted Successfully')
    ENDIF
ENDIF
ENDPROC

/***********************************************************
                                                           *
NAME: editprofile                                          *
                                                           *
***********************************************************/
PROC editprofile(profnum)
DEF fhin,
    fhout,
    count=-1,
    instr[500]:STRING,
    teststr[500]:STRING,
    sepchar[3]:STRING

StrCopy(sepchar,'#\n')

IF profnum<0
    outlist('\eb#Please select a profile to edit')
ELSE
    
    outlist('\eb#Editing Profile...')
    outmini('Editing Profile')
    IF (fhin:=Open('PROGDIR:gofetch.profs',MODE_OLDFILE))=NIL
        outlist('\eb#Unable to open profiles')
    ELSE
        IF (fhout:=Open('PROGDIR:gofetch.temp',MODE_NEWFILE))=NIL
            outlist('\eb#Unable to create temporary file for editing profiles')
        ELSE
            WHILE (Fgets(fhin,instr,500))<>0
                StrCopy(teststr,instr)
                IF StrCmp(teststr,'#',1)=TRUE THEN count:=count+1
                IF StrCmp(teststr,'*',1)=TRUE THEN count:=count+1
                IF count=profnum
                    Fgets(fhin,instr,500)
                    Fgets(fhin,instr,500)
                    Fgets(fhin,instr,500)
                    Fgets(fhin,instr,500)
                    Fgets(fhin,instr,500)
                    Fgets(fhin,instr,500)
                    Fgets(fhin,instr,500)
                    -> this is where we add the new stuff
                    Write(fhout,sepchar,EstrLen(sepchar))
                    IF StrCmp(site, 'ftp://', 6)=TRUE
                        MidStr(site, site, 6, ALL)
                    ENDIF
                    Write(fhout,site,StrLen(site))
                    Write(fhout,'\n',1)
                    Write(fhout,port,StrLen(port))
                    Write(fhout,'\n',1)
                    Write(fhout,username,StrLen(username))
                    Write(fhout,'\n',1)
                    Write(fhout,password,StrLen(password))
                    Write(fhout,'\n',1)
                    Write(fhout,remotepath,StrLen(remotepath))
                    Write(fhout,'\n',1)
                    Write(fhout,filename,StrLen(filename))
                    Write(fhout,'\n',1)
                    Write(fhout,localpath,StrLen(localpath))
                    Write(fhout,'\n',1)
                ELSE
                    Write(fhout,teststr,EstrLen(teststr))
                ENDIF
            ENDWHILE
            Close(fhout)
        ENDIF

        Close(fhin)
    ENDIF
    IF DeleteFile('PROGDIR:gofetch.profs')<>TRUE
        outlist('\eb#Edit operation failed')
    ELSE
        doMethodA(mui_profilelist, [MUIM_List_Clear])
        Rename('PROGDIR:gofetch.temp','PROGDIR:gofetch.profs')
        setupprofiles()
        outlist('\eb#Profile Edited Successfully')
        ENDIF
ENDIF
ENDPROC

PROC edithttpprofile(profnum)
DEF fhin,
    fhout,
    count=-1,
    instr[500]:STRING,
    teststr[500]:STRING,
    sepchar[3]:STRING

StrCopy(sepchar,'*\n')

IF profnum<0
    outlist('\eb#Please select a profile to edit')
ELSE

    outlist('\eb#Editing Profile...')
    IF (fhin:=Open('PROGDIR:gofetch.profs',MODE_OLDFILE))=NIL
        outlist('\eb#Unable to open profiles')
    ELSE
        IF (fhout:=Open('PROGDIR:gofetch.temp',MODE_NEWFILE))=NIL
            outlist('\eb#Unable to create temporary file for editing profiles')
        ELSE
            WHILE (Fgets(fhin,instr,500))<>0
                StrCopy(teststr,instr)
                IF StrCmp(teststr,'#',1)=TRUE THEN count:=count+1
                IF StrCmp(teststr,'*',1)=TRUE THEN count:=count+1
                IF count=profnum
                    Fgets(fhin,instr,500)
                    Fgets(fhin,instr,500)
                    Fgets(fhin,instr,500)
                    Fgets(fhin,instr,500)
                    Fgets(fhin,instr,500)
                    Fgets(fhin,instr,500)
                    Fgets(fhin,instr,500)
                    -> this is where we add the new stuff
                    Write(fhout,sepchar,EstrLen(sepchar))
                    IF StrCmp(httpsite, 'http://', 7)=TRUE
                        MidStr(httpsite, httpsite, 7, ALL)
                    ENDIF
                    Write(fhout,httpsite,StrLen(httpsite))
                    Write(fhout,'\n',1)
                    Write(fhout,httpport,StrLen(httpport))
                    Write(fhout,'\n',1)
                    ->Write(fhout,username,StrLen(username))
                    Write(fhout,'\n',1)
                    ->Write(fhout,password,StrLen(password))
                    Write(fhout,'\n',1)
                    ->Write(fhout,remotepath,StrLen(remotepath))
                    Write(fhout,'\n',1)
                    ->Write(fhout,filename,StrLen(filename))
                    Write(fhout,'\n',1)
                    Write(fhout,httplocalpath,StrLen(httplocalpath))
                    Write(fhout,'\n',1)
                ELSE
                    Write(fhout,teststr,EstrLen(teststr))
                ENDIF
            ENDWHILE
            Close(fhout)
        ENDIF

        Close(fhin)
    ENDIF
    IF DeleteFile('PROGDIR:gofetch.profs')<>TRUE
        outlist('\eb#Edit operation failed')
    ELSE
        doMethodA(mui_profilelist, [MUIM_List_Clear])
        Rename('PROGDIR:gofetch.temp','PROGDIR:gofetch.profs')
        setupprofiles()
        outlist('\eb#Profile Edited Successfully')
        ENDIF
ENDIF
ENDPROC


/**************************************/


PROC edit()
DEF mui_sitestring,
    mui_portstring,
    mui_filenamestring,
    mui_passwordstring,
    mui_usernamestring,
    mui_remotepathstring,
    mui_localpathstring,
    mui_okbutton,
    mui_cancelbutton,
    mui_freqbutton,
    mui_checkmark,
    mui_addsitebutton,
    mui_sitedirbutton,
    mui_sitedirlv,
    mui_sitedirlist,
    mui_delsitebutton,
    mui_httpsitestring,
    mui_httpportstring,
    mui_httplocalpathstring,
    mui_httpfreqbutton,
    mui_httpokbutton,
    mui_httpcancelbutton,
    mui_addpages,
    mui_page,
    sitebuffer[500]:STRING,
    running=TRUE,
    result,
    signal,
    profnum,
    rtpath[500]:STRING,
    protocol=NIL
    

mui_addpages:=['FTP','HTTP',NIL]

get(mui_profilelist,MUIA_List_Active,{profnum})

IF profnum<0
    outlist('\eb#Please select a profile to edit')
ELSE
    protocol:=returnprofile(profnum)

    set(app,MUIA_Application_Sleep,MUI_TRUE)

    mui_editwindow:= WindowObject,
        MUIA_Window_Title       ,'Edit Profile',
        MUIA_HelpNode           ,'Edit Window',
        MUIA_Window_ID          , "EDIT",
        WindowContents, VGroup,
            Child, mui_page:=RegisterGroup(mui_addpages),
            Child, VGroup,
            Child, HGroup,
                Child, Label('Site:'),
                Child, mui_sitestring:= StringObject, StringFrame,
                        MUIA_String_AdvanceOnCR, MUI_TRUE,
                        MUIA_String_Contents, site,
                        MUIA_String_Reject, '#',
                        MUIA_ShortHelp, 'IP Address of FTP site',
                        End,
                Child,  mui_addsitebutton:=ibt(MUII_ArrowRight),
                Child,  mui_sitedirbutton:=ibu(MUII_PopUp),
            End,


                Child,  mui_sitedirlv:=ListviewObject,
                                MUIA_Listview_Input, MUI_TRUE,
                                MUIA_Listview_List, mui_sitedirlist:=ListObject,
                                    ReadListFrame,
                                        MUIA_List_ConstructHook, MUIV_List_ConstructHook_String,
                                        MUIA_List_DestructHook, MUIV_List_DestructHook_String,
                                        MUIA_ShortHelp, 'Site Directory List',
                                    End,
                              End,

                Child, mui_delsitebutton:=SimpleButton('_Delete Site from Directory'),


            Child, HGroup,
                Child, ColGroup(2),

                    Child, Label('Port:'),
                    Child, mui_portstring:= StringObject, StringFrame,
                        MUIA_String_Accept, '0123456789',
                        MUIA_String_AdvanceOnCR, MUI_TRUE,
                        MUIA_String_Contents, port,
                        MUIA_ShortHelp, '\ecFTP port value.\n(Port 21 is default)',
                        End,

                    Child, Label('Username:'),
                    Child, HGroup,
                        Child, mui_usernamestring:= StringObject, StringFrame,
                            MUIA_String_AdvanceOnCR, MUI_TRUE,
                            MUIA_String_Contents, username,
                            MUIA_String_Reject, '#',
                            MUIA_ShortHelp, '\ecYour login name.',
                            End,
                        Child, Label('Anon Login'),
                        Child, mui_checkmark:=CheckMark(FALSE),
                    End,

                    Child, Label('Password:'),
                    Child, mui_passwordstring:= StringObject, StringFrame,
                        MUIA_String_AdvanceOnCR, MUI_TRUE,
                        MUIA_String_Secret, MUI_TRUE,
                        MUIA_String_Contents, password,
                        MUIA_String_Reject, '#',
                        MUIA_ShortHelp,'\ecYour password.\nFor anonymous login, use E-Mail address',
                        End,

                    Child, Label('Remote Path:'),
                    Child, mui_remotepathstring:= StringObject, StringFrame,
                        MUIA_String_AdvanceOnCR, MUI_TRUE,
                        MUIA_String_Contents, remotepath,
                        MUIA_String_Reject, '#',
                        MUIA_ShortHelp,'Path of the file on the server',
                        End,

                    Child, Label('Filename:'),
                    Child, mui_filenamestring:= StringObject, StringFrame,
                        MUIA_String_AdvanceOnCR, MUI_TRUE,
                        MUIA_String_Contents, filename,
                        MUIA_String_Reject, '#',
                        MUIA_ShortHelp,'Enter filename',
                        End,

                    Child, Label('Download:'),
                    Child, HGroup,
                        Child, mui_localpathstring:= StringObject, StringFrame,
                            MUIA_String_AdvanceOnCR, MUI_TRUE,
                            MUIA_String_Contents, localpath,
                            MUIA_String_Reject, '#',
                            MUIA_ShortHelp, 'File download path',
                            MUIA_Draggable, MUI_TRUE,
                            End,
                        Child, mui_freqbutton:=ibt(MUII_PopFile    ),
                    End,
                End,

            End,



            Child, HGroup,
                Child, mui_okbutton:= SimpleButton('_OK'),
                Child, mui_cancelbutton:= SimpleButton('_Cancel'),
            End,

            End, -> VGroup

            Child, VGroup,
                Child, HGroup,
                    Child, ColGroup(2),

                        Child, Label('Site:'),
                        Child, mui_httpsitestring:= StringObject, StringFrame,
                            MUIA_String_AdvanceOnCR, MUI_TRUE,
                            MUIA_String_Contents, httpsite,
                            MUIA_String_Reject, '#',
                            MUIA_ShortHelp, 'Complete URL or IP Address of HTTP site',
                            End,

                        Child, Label('Port:'),
                        Child, mui_httpportstring:= StringObject, StringFrame,
                            MUIA_String_Accept, '0123456789',
                            MUIA_String_AdvanceOnCR, MUI_TRUE,
                            MUIA_String_Contents, httpport,
                            MUIA_ShortHelp, '\ecHTTP port value.\n(Port 80 is default)',
                            End,

                    Child, Label('Download:'),
                    Child, HGroup,
                        Child, mui_httplocalpathstring:= StringObject, StringFrame,
                            MUIA_String_AdvanceOnCR, MUI_TRUE,
                            MUIA_String_Contents, httplocalpath,
                            MUIA_String_Reject, '#',
                            MUIA_ShortHelp, 'File download path',
                            End,
                    Child, mui_httpfreqbutton:=ibt(MUII_PopFile    ),
                    End,

                End,
            End,


            Child, HGroup,
                Child, mui_httpokbutton:= SimpleButton('_OK'),
                Child, mui_httpcancelbutton:= SimpleButton('_Cancel'),
            End,


            End, -> VGroup



            End, -> Pages

            End, -> VGroup
    End -> WindowObject

    doMethodA(app, [OM_ADDMEMBER,mui_editwindow])

    set(mui_sitedirlv,MUIA_ShowMe, FALSE)
    set(mui_delsitebutton,MUIA_ShowMe, FALSE)
    set(mui_editwindow, MUIA_Window_ActiveObject, mui_okbutton)
    set(mui_okbutton,MUIA_ShortHelp, 'Press OK to Save FTP Profile')
    set(mui_cancelbutton,MUIA_ShortHelp, 'Press Cancel to Discard FTP Profile')
    set(mui_freqbutton,MUIA_ShortHelp, 'Choose download directory')
    set(mui_checkmark, MUIA_ShortHelp, 'Tick to perform anonymous login')
    set(mui_addsitebutton, MUIA_ShortHelp, 'Add Site to Site Directory')
    set(mui_sitedirbutton, MUIA_ShortHelp, 'Pop up/Hide Site Directory')
    set(mui_delsitebutton, MUIA_ShortHelp, 'Delete Site From Directory')
    set(mui_httpokbutton, MUIA_ShortHelp, 'Press OK to Save HTTP Profile')
    set(mui_httpcancelbutton, MUIA_ShortHelp, 'Press Cancel to Discard HTTP Profile')
    set(mui_httpfreqbutton, MUIA_ShortHelp, 'Choose Download Directory')

    IF protocol=PROTOCOL_FTP
        set(mui_httpokbutton,MUIA_Disabled, MUI_TRUE)
        set(mui_httpfreqbutton, MUIA_Disabled, MUI_TRUE)
        set(mui_httpcancelbutton, MUIA_Disabled, MUI_TRUE)
        set(mui_httpportstring, MUIA_Disabled, MUI_TRUE)
        set(mui_httpsitestring, MUIA_Disabled, MUI_TRUE)
        set(mui_httplocalpathstring, MUIA_Disabled, MUI_TRUE)
    ELSE
        set(mui_page, MUIA_Group_ActivePage, MUIV_Group_ActivePage_Last)
        set(mui_okbutton, MUIA_Disabled, MUI_TRUE)
        set(mui_freqbutton, MUIA_Disabled, MUI_TRUE)
        set(mui_cancelbutton, MUIA_Disabled, MUI_TRUE)
        set(mui_sitedirbutton, MUIA_Disabled, MUI_TRUE)
        set(mui_checkmark, MUIA_Disabled, MUI_TRUE)
        set(mui_sitedirlv, MUIA_Disabled, MUI_TRUE)
        set(mui_sitestring, MUIA_Disabled, MUI_TRUE)
        set(mui_portstring, MUIA_Disabled, MUI_TRUE)
        set(mui_remotepathstring, MUIA_Disabled, MUI_TRUE)
        set(mui_localpathstring, MUIA_Disabled, MUI_TRUE)
        set(mui_filenamestring, MUIA_Disabled, MUI_TRUE)
        set(mui_usernamestring, MUIA_Disabled, MUI_TRUE)
        set(mui_passwordstring, MUIA_Disabled, MUI_TRUE)
        set(mui_sitedirbutton, MUIA_Disabled, MUI_TRUE)
    ENDIF


    doMethodA(mui_httpsitestring,
                [MUIM_Notify,
                MUIA_String_Contents, MUIV_EveryTime,
                mui_sitestring, 3,
                MUIM_WriteString, MUIV_TriggerValue,httpsite])

    doMethodA(mui_httpportstring,
                [MUIM_Notify,
                MUIA_String_Contents, MUIV_EveryTime,
                mui_portstring, 3,
                MUIM_WriteString, MUIV_TriggerValue,httpport])

    doMethodA(mui_httplocalpathstring,
                [MUIM_Notify,
                MUIA_String_Contents, MUIV_EveryTime,
                mui_localpathstring, 3,
                MUIM_WriteString, MUIV_TriggerValue,httplocalpath])

    doMethodA(mui_httpfreqbutton,
                [MUIM_Notify,
                MUIA_Pressed, FALSE,
                app, 2,
                MUIM_Application_ReturnID, ID_FREQ])

    doMethodA(mui_httpokbutton,
                [MUIM_Notify,
                MUIA_Pressed, FALSE,
                app, 2,
                MUIM_Application_ReturnID, ID_HTTPOK])

    doMethodA(mui_httpcancelbutton,
                [MUIM_Notify,
                MUIA_Pressed, FALSE,
                app, 2,
                MUIM_Application_ReturnID, ID_CANCEL])

    doMethodA(mui_editwindow,
                [MUIM_Notify,
                MUIA_Window_CloseRequest, MUI_TRUE,
                app, 2,
                MUIM_Application_ReturnID, ID_CANCEL])

    doMethodA(mui_okbutton,
                [MUIM_Notify,
                MUIA_Pressed, FALSE,
                app, 2,
                MUIM_Application_ReturnID, ID_OK])

    doMethodA(mui_cancelbutton,
                [MUIM_Notify,
                MUIA_Pressed, FALSE,
                app, 2,
                MUIM_Application_ReturnID, ID_CANCEL])

    doMethodA(mui_sitestring,
                [MUIM_Notify,
                MUIA_String_Contents, MUIV_EveryTime,
                mui_sitestring, 3,
                MUIM_WriteString, MUIV_TriggerValue,site])

    doMethodA(mui_portstring,
                [MUIM_Notify,
                MUIA_String_Contents, MUIV_EveryTime,
                mui_portstring, 3,
                MUIM_WriteString, MUIV_TriggerValue,port])

    doMethodA(mui_usernamestring,   [MUIM_Notify,
                MUIA_String_Contents, MUIV_EveryTime,
                mui_usernamestring, 3,
                MUIM_WriteString, MUIV_TriggerValue,username])

    doMethodA(mui_passwordstring,
                [MUIM_Notify,
                MUIA_String_Contents, MUIV_EveryTime,
                mui_passwordstring, 3,
                MUIM_WriteString, MUIV_TriggerValue,password])

    doMethodA(mui_remotepathstring,
                [MUIM_Notify,
                MUIA_String_Contents, MUIV_EveryTime,
                mui_remotepathstring, 3,
                MUIM_WriteString, MUIV_TriggerValue,remotepath])

    doMethodA(mui_filenamestring,
                [MUIM_Notify,
                MUIA_String_Contents, MUIV_EveryTime,
                mui_filenamestring, 3,
                MUIM_WriteString, MUIV_TriggerValue,filename])

    doMethodA(mui_localpathstring,
                [MUIM_Notify,
                MUIA_String_Contents, MUIV_EveryTime,
                mui_localpathstring, 3,
                MUIM_WriteString, MUIV_TriggerValue,localpath])

    doMethodA(mui_freqbutton,
                [MUIM_Notify,
                MUIA_Pressed, FALSE,
                app, 2,
                MUIM_Application_ReturnID, ID_FREQ])

    doMethodA(mui_editwindow,
                [MUIM_Window_SetCycleChain,
                mui_sitestring,
                mui_addsitebutton,
                mui_sitedirbutton,
                mui_portstring,
                mui_sitedirlv,
                mui_delsitebutton,
                mui_usernamestring,
                mui_checkmark,
                mui_passwordstring,
                mui_remotepathstring,
                mui_filenamestring,
                mui_localpathstring,
                mui_freqbutton,
                mui_okbutton,
                mui_cancelbutton,
                mui_httpsitestring,
                mui_httpportstring,
                mui_httpfreqbutton,
                mui_httpokbutton,
                NIL])

    doMethodA(mui_checkmark,
                [MUIM_Notify,
                MUIA_Pressed, MUI_TRUE,
                app, 2,
                MUIM_Application_ReturnID, ID_CHECKON])

    doMethodA(mui_checkmark,
                [MUIM_Notify,
                MUIA_Pressed, FALSE,
                app, 2,
                MUIM_Application_ReturnID, ID_CHECKOFF])

    doMethodA(mui_sitedirbutton,
                [MUIM_Notify,
                MUIA_Pressed, MUI_TRUE,
                app, 2,
                MUIM_Application_ReturnID, ID_POPSITEDIR])

    doMethodA(mui_sitedirbutton,
                [MUIM_Notify,
                MUIA_Pressed, FALSE,
                app, 2,
                MUIM_Application_ReturnID, ID_POPSITEDIROFF])

    doMethodA(mui_addsitebutton,
                [MUIM_Notify,
                MUIA_Pressed, FALSE,
                mui_sitedirlist, 3,
                MUIM_List_InsertSingle, site, MUIV_List_Insert_Bottom])

    doMethodA(mui_addsitebutton,
                [MUIM_Notify,
                MUIA_Pressed, FALSE,
                mui_sitedirlist, 1,
                MUIM_List_Sort])

    doMethodA(mui_delsitebutton,
                [MUIM_Notify,
                MUIA_Pressed, FALSE,
                mui_sitedirlist, 2,
                MUIM_List_Remove, MUIV_List_Remove_Active])

    doMethodA(mui_sitedirlv,
                [MUIM_Notify,
                MUIA_Listview_DoubleClick, MUI_TRUE,
                app, 2,
                MUIM_Application_ReturnID, ID_FILLINSITE])


    IF StrCmp('anonymous',username)=TRUE
        set(mui_checkmark, MUIA_Pressed, MUI_TRUE)
        set(mui_checkmark, MUIA_Selected, MUI_TRUE)
    ENDIF

    loadsites(mui_sitedirlist)

    set(mui_editwindow,MUIA_Window_Open,MUI_TRUE)

    WHILE running=TRUE
        result:= doMethodA(app, [MUIM_Application_Input,{signal}])

        SELECT result
            CASE ID_OK
                editprofile(profnum)
                set(mui_editwindow,MUIA_Window_Open,FALSE)
                savesites(mui_sitedirlist)
                doMethodA(mui_sitedirlist, [MUIM_List_Clear])
                doMethodA(app,[OM_REMMEMBER,mui_editwindow])
                Mui_DisposeObject(mui_editwindow)
                set(app,MUIA_Application_Sleep,FALSE)
                running:=FALSE

            CASE ID_HTTPOK
                edithttpprofile(profnum)
                set(mui_editwindow,MUIA_Window_Open,FALSE)
                savesites(mui_sitedirlist)
                doMethodA(mui_sitedirlist, [MUIM_List_Clear])
                doMethodA(app,[OM_REMMEMBER,mui_editwindow])
                Mui_DisposeObject(mui_editwindow)
                set(app,MUIA_Application_Sleep,FALSE)
                running:=FALSE

            CASE ID_CANCEL
                set(mui_editwindow,MUIA_Window_Open,FALSE)
                savesites(mui_sitedirlist)
                doMethodA(mui_sitedirlist, [MUIM_List_Clear])
                doMethodA(app,[OM_REMMEMBER,mui_editwindow])
                Mui_DisposeObject(mui_editwindow)
                set(app,MUIA_Application_Sleep,FALSE)
                running:=FALSE

            CASE ID_FREQ
                IF freq(TRUE)<>0
                    StrCopy(rtpath,freqpath)
                    StrCopy(localpath,rtpath)
                    StrCopy(httplocalpath, rtpath)
                    SetAttrsA(mui_localpathstring,[Eval(`(MUIA_String_Contents)),localpath,TAG_DONE])
                    SetAttrsA(mui_httplocalpathstring,[Eval(`(MUIA_String_Contents)),httplocalpath,TAG_DONE])
                ENDIF

            CASE ID_CHECKON
                StrCopy(username,'anonymous')
                StrCopy(password,anonpass)
                set(mui_usernamestring,MUIA_String_Contents,username)
                set(mui_passwordstring,MUIA_String_Contents,password)
                set(mui_usernamestring,MUIA_Disabled, MUI_TRUE)
                set(mui_passwordstring,MUIA_Disabled, MUI_TRUE)
                set(mui_checkmark, MUIA_ShortHelp,'Untick to Perform Named Login')

            CASE ID_CHECKOFF
                set(mui_usernamestring,MUIA_Disabled, FALSE)
                set(mui_passwordstring,MUIA_Disabled, FALSE)
                set(mui_checkmark, MUIA_ShortHelp,'Tick to Perform Anonymous Login')

            CASE ID_POPSITEDIR
                set(mui_sitedirlv,MUIA_ShowMe, MUI_TRUE)
                set(mui_delsitebutton,MUIA_ShowMe, MUI_TRUE)

            CASE ID_POPSITEDIROFF
                set(mui_sitedirlv,MUIA_ShowMe, FALSE)
                set(mui_delsitebutton,MUIA_ShowMe, FALSE)

            CASE ID_FILLINSITE
                doMethodA(mui_sitedirlist,[MUIM_List_GetEntry,MUIV_List_GetEntry_Active,{sitebuffer}])
                StrCopy(site,sitebuffer)
                SetAttrsA(mui_sitestring,[Eval(`(MUIA_String_Contents)),site,TAG_DONE])
        ENDSELECT
        IF (running AND signal) THEN Wait(signal)
    ENDWHILE
ENDIF

ENDPROC

PROC setupxferwin()
DEF mui_xferwindow,
    mui_xfergauge,
    mui_abortbutton


IF sizecmdsuccess=TRUE
    mui_xferwindow:=WindowObject,
        MUIA_Window_Title   ,'Transfer Window',
        MUIA_Window_ID      , "TRAN",
        MUIA_HelpNode       , 'Trans Win',
        MUIA_Window_CloseGadget, FALSE,
        MUIA_Window_Activate, FALSE,
        WindowContents, VGroup,
            Child, Label('\ecTransfer Progress'),
                Child, mui_xfergauge:=GaugeObject, GaugeFrame,
                            MUIA_Gauge_Current, 0,
                            MUIA_Gauge_Horiz, MUI_TRUE,
                            MUIA_Gauge_Max, xferfilelen,
                            MUIA_Gauge_InfoText, '       Received %ldK       ',
                            MUIA_Gauge_Divide    ,1024,
                            MUIA_ShortHelp, 'File Received',
                        End,
                   Child, ScaleObject,
                            End,
                        Child, mui_cpsrate:=TextObject,
                        MUIA_Text_Contents, '\ecCPS Transfer Rate: 0',
                        MUIA_ShortHelp,'Go Fetch! FTP/HTTP Client © 1999 Ian Chapman',
                        End, -> TextObject
                   Child, mui_abortbutton:=SimpleButton('_Abort'),
                End,
            End
    doMethodA(app, [OM_ADDMEMBER,mui_xferwindow]) -> Add window to list
    set(mui_abortbutton,MUIA_ShortHelp, 'Abort Current File Transfer')
    set(mui_xfergauge, MUIA_ShortHelp, 'File received so far')
    doMethodA(mui_abortbutton,      [MUIM_Notify, MUIA_Pressed, FALSE, app, 2, MUIM_Application_ReturnID, ID_ABORT])
ENDIF

ENDPROC mui_xferwindow, mui_xfergauge

PROC closexferwin(mui_xferwindow)

IF sizecmdsuccess=TRUE
    set(mui_xferwindow,MUIA_Window_Open,FALSE)
    doMethodA(app,[OM_REMMEMBER,mui_xferwindow])
    Mui_DisposeObject(mui_xferwindow)
    ->set(app,MUIA_Application_Sleep,FALSE)
ENDIF
ENDPROC

PROC closexferwinnotopen(mui_xferwindow)

IF sizecmdsuccess=TRUE
    doMethodA(app,[OM_REMMEMBER,mui_xferwindow])
    Mui_DisposeObject(mui_xferwindow)
    set(app,MUIA_Application_Sleep,FALSE)
ENDIF
ENDPROC

PROC resume(fileandpath:PTR TO CHAR)
DEF filelen,
    filelenstr[50]:STRING

IF (filelen:=FileLength(fileandpath))<0
ELSE
    StringF(filelenstr,'\d',filelen)
    commandtypec('REST ',filelenstr)
ENDIF

IF filelen=-1 THEN filelen:=0

ENDPROC filelen



/***************AREXX HOOKS BEGIN*************/

PROC rx_dlstatus()
ENDPROC dlstatus

PROC rx_edithttpprofile()
DEF profile[4]:ARRAY OF LONG,
    totalprofiles,
    success=0

    MOVE.L A1, profile
    get( mui_profilelist, MUIA_List_Entries, {totalprofiles})
    totalprofiles:=totalprofiles-1

    IF Long(profile[0])>totalprofiles
        success:=-1
    ELSE
        StrCopy(httpsite,profile[1])
        StrCopy(httpport,profile[2])
        StrCopy(httplocalpath,profile[3])
        edithttpprofile(Long(profile[0]))
    ENDIF

ENDPROC success

PROC rx_returnproto()
DEF a[1]:ARRAY OF LONG,
    totalprofiles,
    success=0

MOVE.L A1, a
get( mui_profilelist, MUIA_List_Entries, {totalprofiles})
totalprofiles:=totalprofiles-1

IF Long(a[0])>totalprofiles
    success:=-1
ELSE
    success:=returnprofile(Long(a[0]))
    IF success=PROTOCOL_FTP THEN success:=0
    IF success=PROTOCOL_HTTP THEN success:=1
ENDIF

ENDPROC success



PROC rx_clearhistory()

doMethodA(mui_historylist, [MUIM_List_Clear])
ENDPROC 0

PROC rx_annotate()
DEF a[1]:ARRAY OF LONG,
    text[80]:STRING

MOVE.L A1, a
StrCopy(text, '\eb#RX:')
StrAdd(text,a[0])
outlist(text)

ENDPROC 0

PROC rx_setminilog()
DEF a[1]:ARRAY OF LONG,
    status=NIL

MOVE.L A1, a
IF Long(a[0])>0
    IF minilogwin=NIL
        openminilog()
        status:=0
    ELSE
        status:=-1
    ENDIF
ELSE
    IF minilogwin<>NIL
        closeminilog()
        status:=0
    ELSE
        status:=-1
    ENDIF
ENDIF


ENDPROC status


PROC rx_addprofile()
DEF a[6]:ARRAY OF LONG,
    addtolist[500]:STRING
    

MOVE.L A1, a
StrCopy(site,a[0])
StrCopy(port,a[1])
StrCopy(username,a[2])
StrCopy(password,a[3])
StrCopy(remotepath,a[4])
StrCopy(filename,a[5])
StrCopy(localpath,a[6])
IF StrCmp(site, 'ftp://', 6)=TRUE
    MidStr(site, site, 6, ALL)
ENDIF
StringF(addtolist,'\ei(FTP)  :  \en\ebSite:\en \s:\s   \ebLogin:\en \s   \ebFile:\en \s',site,port,username,filename)
doMethodA(mui_profilelist, [MUIM_List_InsertSingle, addtolist, MUIV_List_Insert_Bottom ])
saveprofiles()
ENDPROC 0

PROC rx_addhttpprofile()
DEF a[2]:ARRAY OF LONG,
    addtolist[500]:STRING,
    status=0

    MOVE.L A1, a
    StrCopy(httpsite,a[0])
    IF StrCmp(httpsite, 'http://', 7)=TRUE
        MidStr(httpsite, httpsite, 7, ALL)
    ENDIF
    StrCopy(httpport,a[1])
    StrCopy(httplocalpath,a[2])
    StringF(addtolist,'\ei(HTTP) :  \en\ebSite:\en \s:\s',httpsite,httpport)
    doMethodA(mui_profilelist, [MUIM_List_InsertSingle, addtolist, MUIV_List_Insert_Bottom ])
    savehttpprofiles()

ENDPROC status



PROC rx_quitgofetch()
doMethodA(app, [MUIM_Application_ReturnID, MUIV_Application_ReturnID_Quit])
ENDPROC 0

PROC rx_reloadprofiles()
doMethodA(mui_profilelist, [MUIM_List_Clear])
setupprofiles()
ENDPROC 0

PROC rx_editprofile()
DEF profile[7]:ARRAY OF LONG,
    totalprofiles,
    success=0

MOVE.L A1, profile
get( mui_profilelist, MUIA_List_Entries, {totalprofiles})
totalprofiles:=totalprofiles-1

IF Long(profile[0])>totalprofiles
    success:=-1
ELSE
    StrCopy(site,profile[1])
    StrCopy(port,profile[2])
    StrCopy(username,profile[3])
    StrCopy(password,profile[4])
    StrCopy(remotepath,profile[5])
    StrCopy(filename,profile[6])
    StrCopy(localpath,profile[7])
    editprofile(Long(profile[0]))
ENDIF

ENDPROC success

PROC rx_deleteprofile()
DEF success=0,
    totalprofiles,
    profile:PTR TO LONG

MOVE.L A1, profile
get( mui_profilelist, MUIA_List_Entries, {totalprofiles})
totalprofiles:=totalprofiles-1

IF Long(profile[0])>totalprofiles
    success:=-1
ELSE
    deleteprofile(Long(profile[0]))
ENDIF

ENDPROC success

PROC rx_profiles()
DEF totalprofiles=0

get( mui_profilelist, MUIA_List_Entries, {totalprofiles})

ENDPROC totalprofiles

PROC rx_release()
ENDPROC RELEASE

PROC rx_setactiveprofile()
DEF success=0,
    totalprofiles,
    profile:PTR TO LONG

MOVE.L A1, profile

get( mui_profilelist, MUIA_List_Entries, {totalprofiles})
totalprofiles:=totalprofiles-1

IF Long(profile[0])>totalprofiles
    success:=-1
ELSE
set(mui_profilelist,MUIA_List_Active, Long(profile[0]))
ENDIF

ENDPROC success

PROC rx_openaddwindow()
doMethodA(app, [MUIM_Application_ReturnID, ID_ADD])
ENDPROC 0

PROC rx_openeditwindow()
doMethodA(app, [MUIM_Application_ReturnID, ID_EDIT])
ENDPROC 0

PROC rx_lockgui()
set(mui_mainwindow, MUIA_Window_Sleep, MUI_TRUE)
ENDPROC 0

PROC rx_unlockgui()
set(mui_mainwindow, MUIA_Window_Sleep, FALSE)
ENDPROC 0

PROC rx_savelog()
DEF param:PTR TO LONG,
    filepath[500]:STRING,
    entries,
    success=0,
    ent,
    entry[500]:STRING,
    fh,
    i

MOVE.L A1,param

StringF(filepath,'\s\s',param[0],'gofetch.log')
GetAttr(MUIA_List_Entries,mui_iolist,{entries})

IF (fh:=Open(filepath,MODE_NEWFILE))<>NIL
    outlist('\eb#Saving Log, Please wait...')
    FOR i:=0 TO (entries-1)
        doMethodA(mui_iolist,[MUIM_List_GetEntry,i,{ent}])
        StringF(entry,'\s\n',ent)
        Write(fh,entry,EstrLen(entry))
    ENDFOR
    Close(fh)
    outlist('\eb#Log saved successfully')
    success:=0
ELSE
    outlist('\eb#Unable to create logfile')
    success:=-1
ENDIF
ENDPROC success

PROC rx_clearlog()
doMethodA(mui_iolist, [MUIM_List_Clear])
ENDPROC 0

PROC rx_iconify()
doMethodA(app, [MUIM_Application_ReturnID, ID_ICONIFY])
ENDPROC 0

PROC rx_uniconify()
set(app, MUIA_Application_Iconified, FALSE)
ENDPROC 0

PROC rx_iconifystatus()
DEF status
get(app, MUIA_Application_Iconified, {status})
ENDPROC status

PROC rx_getanon()
set(app, MUIA_Application_RexxString, anonpass)
ENDPROC 0

PROC rx_getdownloadpath()
set(app, MUIA_Application_RexxString, localpath)
ENDPROC 0

PROC rx_go()
doMethodA(app, [MUIM_Application_ReturnID, ID_GO])
ENDPROC 0

PROC rx_addanonprofile()
DEF a[4]:ARRAY OF LONG,
    addtolist[500]:STRING

MOVE.L A1, a
StrCopy(site,a[0])
StrCopy(port,a[1])
StrCopy(remotepath,a[2])
StrCopy(filename,a[3])
StrCopy(localpath,a[4])
StrCopy(username, 'anonymous')
StrCopy(password, anonpass)
StringF(addtolist,'\ei(FTP)  :  \en\ebSite:\en \s:\s   \ebLogin:\en anonymous   \ebFile:\en \s',site,port,filename)
doMethodA(mui_profilelist, [MUIM_List_InsertSingle, addtolist, MUIV_List_Insert_Bottom ])
saveprofiles()
ENDPROC 0

PROC rx_stop()
doMethodA(app, [MUIM_Application_ReturnID, ID_STOP])
ENDPROC 0

PROC rx_addsite()
DEF a[1]:ARRAY OF LONG,
    sitelistfh,
    sitebuffer[500]:STRING,
    success=0

MOVE.L A1,a
sitebuffer:=a[0]

IF rx_windowopen()>0
    success:=-2
ELSE

    IF (sitelistfh:=Open('PROGDIR:sitelist.gofetch',MODE_READWRITE))<>NIL
        Seek(sitelistfh,NIL,OFFSET_END)
        Write(sitelistfh,sitebuffer,StrLen(sitebuffer))
        Write(sitelistfh,'\n',1)
        Close(sitelistfh)
    ELSE
        success:=-1
    ENDIF

ENDIF

ENDPROC success

PROC rx_windowopen()
DEF status,
    success=0

get(mui_addwindow, MUIA_Window_Open, {status})

IF status=1
    success:=1
ELSE
    get(mui_editwindow, MUIA_Window_Open, {status})
    IF status=1 THEN success:=2 ELSE success:=0
ENDIF

ENDPROC success

/***************AREXX HOOKS END*************/

-> Otherhooks

PROC ref_refresh()

ENDPROC

PROC list_proflistdisp()
DEF a[5]:ARRAY OF LONG
MOVE A2, a
a[0]:= 'Cheese'
a[1]:= 'HAM'
a[2]:= 'BING'
a[3]:= 'FUCK'
MOVE a, A2
ENDPROC



PROC go()
DEF totalprofiles,
    result=NIL,
    connectionstr[200]:STRING,
    hst: PTR TO hostent,
    protocol=NIL,
    tempsite[500]:STRING,
    tempusername[500]:STRING,
    match=FALSE


->Get the number of profiles in the profile list view
get( mui_profilelist, MUIA_List_Entries, {totalprofiles})

->Minus 1 from the number of profiles because they are labelled 0 onwards
totalprofiles:=totalprofiles-1

->If there are more than 0 profiles.
IF totalprofiles>-1

    ->If the next profile is greater than total profile, loop back to profile 0
    IF nextprofile>totalprofiles
        result:=ID_GO
        nextprofile:=0
    ELSE
        protocol:=returnprofile(nextprofile)

        SELECT protocol
            CASE PROTOCOL_FTP

                IF p.keepalive = TRUE

                    IF totalprofiles>0
                        StrCopy(tempsite, site, ALL)
                        StrCopy(tempusername, username, ALL)

                        protocol:=returnprofile(nextprofile+1)

                        IF protocol = PROTOCOL_FTP

                            IF StrCmp(tempsite, site, ALL)=TRUE
                                IF StrCmp(tempusername, username, ALL)=TRUE
                                    match:=TRUE
                                ELSE
                                    match:=FALSE
                                ENDIF
                            ELSE
                                match:=FALSE
                            ENDIF
                        ENDIF

                        protocol:=returnprofile(nextprofile)

                    ENDIF

                    SELECT alivetransfer
                        CASE 0
                            IF match=TRUE THEN alivetransfer:=3
                        CASE 1
                            IF match=FALSE THEN alivetransfer:=2
                        CASE 2
                            IF match=TRUE THEN alivetransfer:=3
                            IF match=FALSE THEN alivetransfer:=0
                        CASE 3
                            IF match=TRUE THEN alivetransfer:=1
                            IF match=FALSE THEN alivetransfer:=0
                    ENDSELECT
                ELSE
                    alivetransfer:=0
                ENDIF


                IF alivetransfer=0

                    outlist('\eb')
                    outlist('\eb#Go Fetch! FTP © 1999 Ian Chapman')
                    outlist('\eb#DNS Lookup... Please Wait...')
                    outmini('DNS FTP Lookup...')
                    IF (sock:=Socket(AF_INET, SOCK_STREAM,0))<>-1

                        IF sain:=New(SIZEOF sockaddr_in)
                            sain.family:=AF_INET
                            IF hst:=Gethostbyname(site)
                                CopyMem(Long(hst.addr_list), sain.addr, hst.length)
                            ENDIF
                        sain.port:=Val(port)
                        ENDIF

                        StringF(connectionstr,'\eb#Attempting to connect to: \s (\s)',site, Inet_NtoA(sain.addr.addr))
                        outlist(connectionstr)
                        StringF(connectionstr,'Connecting: \s (\s)', site, Inet_NtoA(sain.addr.addr))
                        outmini(connectionstr)
                        outlist('\eb#Please wait...')

                        IF Connect(sock, sain, SIZEOF sockaddr_in)<>-1
                            controlconnect()
                        ELSE
                            outlist('\eb#Warning: Unable to connect to FTP Server')
                            outmini('Unable to Connect')
                            res:=ST_NOCONNECT
                        ENDIF

                        CloseSocket(sock)
                    ENDIF
                ENDIF

                IF alivetransfer=1
                    outlist('\eb')
                    outlist('\eb#Keeping Connection Alive...')
                    controlconnect1()
                ENDIF

                IF alivetransfer=2
                    outlist('\eb')
                    outlist('\eb#Keeping Connection Alive...')
                    controlconnect2()
                    CloseSocket(sock)
                ENDIF

                IF alivetransfer=3

                    outlist('\eb')
                    outlist('\eb#Go Fetch! FTP © 1999 Ian Chapman')
                    outlist('\eb#DNS Lookup... Please Wait...')
                    outmini('DNS FTP Lookup...')
                    IF (sock:=Socket(AF_INET, SOCK_STREAM,0))<>-1

                        IF sain:=New(SIZEOF sockaddr_in)
                            sain.family:=AF_INET
                            IF hst:=Gethostbyname(site)
                                CopyMem(Long(hst.addr_list), sain.addr, hst.length)
                            ENDIF
                        sain.port:=Val(port)
                        ENDIF

                        StringF(connectionstr,'\eb#Attempting to connect to: \s (\s)',site, Inet_NtoA(sain.addr.addr))
                        outlist(connectionstr)
                        StringF(connectionstr,'Connecting: \s (\s)', site, Inet_NtoA(sain.addr.addr))
                        outmini(connectionstr)
                        outlist('\eb#Please wait...')

                        IF Connect(sock, sain, SIZEOF sockaddr_in)<>-1
                            controlconnect3()
                        ELSE
                            outlist('\eb#Warning: Unable to connect to FTP Server')
                            outmini('Unable to Connect')
                            res:=ST_NOCONNECT
                            alivetransfer:=0
                            CloseSocket(sock)
                        ENDIF
                    ENDIF
                ENDIF


            CASE PROTOCOL_HTTP
                outlist('\eb')
                outlist('\eb#Go Fetch! HTTP © 1999 Ian Chapman')
                outlist('\eb#DNS Lookup... Please Wait...')
                outmini('DNS HTTP Lookup...')
                httptransfer()
        ENDSELECT


        SELECT res
            CASE ST_XFEROK
                result:=ID_GO
                outhist('Transfer OK',protocol)
                deleteprofile(nextprofile)
            CASE ID_ABORT
                result:=ID_GO
                nextprofile:=nextprofile+1
            CASE ST_TIMEOUT
                result:=ID_GO
                outhist('Timed Out',protocol)
                IF p.retaintout=FALSE
                    deleteprofile(nextprofile)
                ELSE
                    nextprofile:=nextprofile+1
                ENDIF
            CASE ST_NOCONNECT
                result:=ID_GO
                outhist('Unable to Connect', protocol)
                IF p.retain=FALSE
                    deleteprofile(nextprofile)
                ELSE
                    nextprofile:=nextprofile+1
                ENDIF
            CASE ID_STOP
                result:=NIL
                nextprofile:=0
            CASE CMD_FILENOTFOUND
                result:=ID_GO
                outhist('File Not Found', protocol)
                IF p.retainfnf=FALSE
                    deleteprofile(nextprofile)
                ELSE
                    nextprofile:=nextprofile+1
                ENDIF
        ENDSELECT
        set(mui_profilelist,MUIA_List_Active, nextprofile)
    ENDIF

ELSE
    nextprofile:=0
    IF p.beep=TRUE THEN DisplayBeep(NIL)
    outlist('\eb#Profile List Empty')
    outmini('Profile List Empty')
ENDIF
ENDPROC result


/************************************/



PROC loadsites(mui_sdlist)
DEF sitelistfh,
    sitebuffer[500]:STRING,
    buffer,
    i,
    len

IF (sitelistfh:=Open('PROGDIR:sitelist.gofetch',MODE_OLDFILE))<>NIL

buffer:=Fgets(sitelistfh,sitebuffer,500)

    IF buffer<>NIL
        REPEAT
            len:=StrLen(sitebuffer)
            sitebuffer[len-1]:=NIL
            doMethodA(mui_sdlist, [MUIM_List_InsertSingle, sitebuffer, MUIV_List_Insert_Bottom])
            i++
            buffer:=Fgets(sitelistfh, sitebuffer, 500)
        UNTIL buffer=NIL
    ENDIF
    Close(sitelistfh)

ENDIF

ENDPROC


/***********************************/



PROC savesites(mui_sdlist)
DEF i=0,
    sitelistfh,
    sitebuffer[500]:STRING

IF (sitelistfh:=Open('PROGDIR:sitelist.gofetch',MODE_NEWFILE))<>NIL
    doMethodA(mui_sdlist, [MUIM_List_GetEntry, i, {sitebuffer}])
    IF sitebuffer<>NIL
        REPEAT
            Write(sitelistfh,sitebuffer,StrLen(sitebuffer))
            Write(sitelistfh,'\n',1)
            i++
            doMethodA(mui_sdlist, [MUIM_List_GetEntry, i, {sitebuffer}])
        UNTIL sitebuffer=NIL
    ENDIF
    Close(sitelistfh)
ELSE
    outlist('\eb#Unable to Save Site Directory')
ENDIF

ENDPROC


/********************************/



PROC addcomment(file, proto)
DEF comment[80]:STRING

IF proto=PROTOCOL_FTP

    StringF(comment,'ftp://\s',site)
    IF remotepath[0]=47
        StrAdd(comment,remotepath)
    ELSE
        StrAdd(comment,'/')
        StrAdd(comment,remotepath)
    ENDIF
    SetComment(file,comment)

ELSE

    StringF(comment,'http://\s',httpsite)
    SetComment(file,comment)
ENDIF

ENDPROC


/******************************/



PROC openminilog()
DEF textat:PTR TO textattr,
    font,
    tempscr[200]:STRING,
    scr=NIL

StrCopy(tempscr, defpubscr)

scr:=LockPubScreen(tempscr)
IF scr=NIL THEN GetDefaultPubScreen(tempscr)
UnlockPubScreen(tempscr,scr)

textat:=['topaz.font',8,0,0]:textattr

IF (font:=OpenFont(textat))=NIL
    outlist('\eb#Font Problem with minilog window!')
    minilogwin:=NIL
ELSE
    IF (minilogwin:=OpenWindowTagList(NIL,
                                    [WA_LEFT,0,
                                    WA_TOP,0,
                                    WA_WIDTH,315,
                                    WA_HEIGHT,35,
                                    WA_IDCMP,$200,
                                    WA_FLAGS,$2+$400+WFLG_DEPTHGADGET,
                                    WA_TITLE,'Go Fetch Mini Log',
                                    ->WA_CUSTOMSCREEN, scr,
                                    WA_PUBSCREENNAME, tempscr,
                                    TAG_DONE]))=NIL

        Mui_RequestA(app, mui_mainwindow, 0, 'MiniLog Error','*_OK','\ecUnable to Open MiniLog Window!',NIL)
        minilogwin:=NIL
    ELSE
        SetFont(minilogwin.rport,font)
        SetAPen(minilogwin.rport,1)
        outmini(minilogbuffer)
    ENDIF
ENDIF


ENDPROC


/******************************/



PROC closeminilog()
IF minilogwin<>NIL
    CloseWindow(minilogwin)
    minilogwin:=NIL
ENDIF
ENDPROC



/*****************************/



PROC outmini(text)

StrCopy(minilogbuffer,text)

IF minilogwin<>NIL
    Move(minilogwin.rport,5,10)
    Text(minilogwin.rport,'                                        ',40)
    Move(minilogwin.rport,5,10)
    Text(minilogwin.rport,text,StrLen(text))
ENDIF
ENDPROC


/*****************************/



PROC readprefs()
DEF prefsfh,
    intext[500]:STRING

IF (prefsfh:=Open('PROGDIR:gofetch2.prefs',MODE_OLDFILE))<>NIL

    Fgets(prefsfh, intext, 500) ->Anon pass
    StrCopy(anonpass, intext, StrLen(intext)-1)

    Fgets(prefsfh, intext, 500) ->Def Local Path
    StrCopy(deflocalpath, intext, StrLen(intext)-1)
    StrCopy(localpath, deflocalpath)
    StrCopy(httplocalpath, deflocalpath)

    Fgets(prefsfh, intext, 500) ->Def Pub Screen
    StrCopy(defpubscr, intext, StrLen(intext)-1)

    Fgets(prefsfh, intext, 500) -> Beep
    IF StrCmp(intext,'1\n')=TRUE
        p.beep:=TRUE
    ELSE
        p.beep:=FALSE
    ENDIF

    Fgets(prefsfh, intext, 500) ->Keepalive
    IF StrCmp(intext,'1\n')=TRUE
        p.keepalive:=TRUE
    ELSE
        p.keepalive:=FALSE
    ENDIF

    Fgets(prefsfh, intext, 500) -> Showprofs
    IF StrCmp(intext,'1\n')=TRUE
        p.showprofs:=TRUE
    ELSE
        p.showprofs:=FALSE
    ENDIF

    Fgets(prefsfh, intext, 500) -> retain no connect
    IF StrCmp(intext, '1\n')=TRUE
        p.retain:=TRUE
    ELSE
        p.retain:=FALSE
    ENDIF

    Fgets(prefsfh, intext, 500) -> retain timeout
    IF StrCmp(intext, '1\n')=TRUE
        p.retaintout:=TRUE
    ELSE
        p.retaintout:=FALSE
    ENDIF

    Fgets(prefsfh, intext, 500) -> retain file not found
    IF StrCmp(intext, '1\n')=TRUE
        p.retainfnf:=TRUE
    ELSE
        p.retainfnf:=FALSE
    ENDIF

    Fgets(prefsfh, intext, 500) -> get HTTP file if server does not support file resuming
    IF StrCmp(intext, '1\n')=TRUE
        p.getonnoresume:=TRUE
    ELSE
        p.getonnoresume:=FALSE
    ENDIF

    Fgets(prefsfh, intext, 500) -> Get TCP/IP Buffer
    prefsxferbuffer:= Val(intext)

    Fgets(prefsfh, intext, 500) -> Timeout
    prefstimeout:= Val(intext)

    Close(prefsfh)

ELSE
    ->Setup up the defaults if prefs not found.
    StrCopy(anonpass,'nobody@nobody.com')
    StrCopy(deflocalpath,'ram:')
    StrCopy(localpath, deflocalpath)
    StrCopy(defpubscr, 'WORKBENCH')
    p.beep:=FALSE
    p.keepalive:=TRUE
    p.showprofs:=FALSE
    p.retain:=TRUE
    p.retaintout:=FALSE
    p.retainfnf:=FALSE
    p.getonnoresume:=TRUE

ENDIF

ENDPROC



/*************************/


PROC saveprefs()
DEF prefsfh,
    outstr[20]:STRING

IF (prefsfh:=Open('PROGDIR:gofetch2.prefs',MODE_NEWFILE))<>NIL
    Write(prefsfh, anonpass, StrLen(anonpass))
    Write(prefsfh, '\n', 1)
    Write(prefsfh, deflocalpath, StrLen(deflocalpath))
    Write(prefsfh, '\n', 1)
    Write(prefsfh, defpubscr, StrLen(defpubscr))
    Write(prefsfh, '\n', 1)
    IF p.beep=TRUE
        Write(prefsfh, '1', 1)
    ELSE
        Write(prefsfh, '0', 1)
    ENDIF
    Write(prefsfh, '\n', 1)

    IF p.keepalive=TRUE
        Write(prefsfh, '1', 1)
    ELSE
        Write(prefsfh, '0', 1)
    ENDIF
    Write(prefsfh, '\n', 1)

    IF p.showprofs=TRUE
        Write(prefsfh, '1', 1)
    ELSE
        Write(prefsfh, '0', 1)
    ENDIF
    Write(prefsfh, '\n', 1)

    IF p.retain=TRUE
        Write(prefsfh, '1', 1)
    ELSE
        Write(prefsfh, '0', 1)
    ENDIF
    Write(prefsfh, '\n', 1)

    IF p.retaintout=TRUE
        Write(prefsfh, '1', 1)
    ELSE
        Write(prefsfh, '0', 1)
    ENDIF
    Write(prefsfh, '\n', 1)

    IF p.retainfnf=TRUE
        Write(prefsfh, '1', 1)
    ELSE
        Write(prefsfh, '0', 1)
    ENDIF
    Write(prefsfh, '\n', 1)

    IF p.getonnoresume=TRUE
        Write(prefsfh, '1', 1)
    ELSE
        Write(prefsfh, '0', 1)
    ENDIF
    Write(prefsfh, '\n', 1)

    StringF(outstr,'\d\n', prefsxferbuffer)
    Write(prefsfh, outstr, EstrLen(outstr))

    StringF(outstr,  '\d\n', prefstimeout)
    Write(prefsfh, outstr, EstrLen(outstr))

    Close(prefsfh)
ELSE
    Mui_RequestA(app, mui_mainwindow, 0, 'Save Prefs Error','*_OK','\ecUnable to Save Preferences!',NIL)
ENDIF

ENDPROC


/**************************/


PROC httptransfer()
DEF dom[500]:STRING,
    hfile[500]:STRING,
    hpath[500]:STRING,
    command[500]:STRING,
    reply[500]:STRING,
    filepath[500]:STRING,
    cpsstr[50]:STRING,
    connectionstr[500]:STRING,
    httpsock,
    httphst: PTR TO hostent,
    httpsain: PTR TO sockaddr_in,
    recvlen=NIL,
    returncode=NIL,
    fh,
    lenrec=NIL,
    len,
    blankline=FALSE,
    readfds:fd_set,
    appresult,
    tv:timeval,
    mui_xferwindow,
    mui_xfergauge,
    timerec=1,
    tryingtoresume=FALSE

res:=NIL

    
StrCopy(dom, returndomain(httpsite))
StrCopy(hpath, returnhttppath(httpsite))
StrCopy(hfile, returnhttpfile(httpsite))

IF (httpsock:=Socket(AF_INET, SOCK_STREAM, 0))<>-1

    IF httpsain:=New(SIZEOF sockaddr_in)
        httpsain.family:=AF_INET
        IF httphst:=Gethostbyname(dom)
            CopyMem(Long(httphst.addr_list), httpsain.addr, httphst.length)
        ENDIF
    httpsain.port:=Val(httpport)
    ENDIF
    outmini('Connecting...')

    StringF(connectionstr,'\eb#Attempting to connect to: \s (\s)',httpsite, Inet_NtoA(httpsain.addr.addr))
    outlist(connectionstr)
    StringF(connectionstr,'Connecting: \s (\s)', httpsite, Inet_NtoA(httpsain.addr.addr))
    outmini(connectionstr)
    outlist('\eb#Please wait...')
    outmini('Please wait...')

    fd_zero(readfds)
    fd_set(httpsock, readfds)
    tv.sec:=prefstimeout
    tv.usec:=5

    IF Connect(httpsock, httpsain, SIZEOF sockaddr_in)<>-1


        StrCopy(filepath, httplocalpath)
        StrAdd(filepath, hfile)

        IF FileLength(filepath)>0
            tryingtoresume:=TRUE
            outlist('\eb#Attempting HTTP Resume...')
            outmini('Attempting HTTP Resume')
            StringF(command,'GET \s\s HTTP/1.0\b\nUser-Agent: GoFetch!/1.3\b\nAccept-Ranges: BYTES\b\nRange: BYTES=\d-\b\n\b\n', hpath, hfile, FileLength(filepath))
        ELSE
            StrCopy(command,'GET ')
            StrAdd(command,hpath)
            StrAdd(command,hfile)
            StrAdd(command,' HTTP/1.0\b\nUser-Agent: GoFetch!/1.3\b\nAccept-Ranges: BYTES\b\n\b\n')
            WriteF(command)
        ENDIF

        Send(httpsock, command, EstrLen(command), MSG_WAITALL)
        WHILE blankline=FALSE
            
            StrCopy(reply, httpreccommand(httpsock))
            UpperStr(reply)

            IF StrCmp(reply, 'TIMEOUT', 7)=TRUE THEN returncode:=0

            IF StrCmp(reply, 'SERVER: ', 8)=TRUE
                outlist(decodehttpserver(reply))
            ENDIF
            IF StrCmp(reply, 'CONTENT-LENGTH:', 15)=TRUE
                recvlen:=decodehttplen(reply)
            ENDIF
            IF StrCmp(reply, 'HTTP/', 5)=TRUE
                returncode:=decodehttpreturn(reply)
            ENDIF
            ->outlist(reply)
            IF StrCmp(reply, '\b\n')=TRUE THEN blankline:=TRUE
            IF StrCmp(reply, '\n')=TRUE THEN blankline:=TRUE
        ENDWHILE

            IF tryingtoresume=TRUE
                IF returncode = 200
                    outlist('\eb#HTTP Server does not support file resuming or resume denied.')
                    outmini('No Resume Support on Server')
                    IF p.getonnoresume=FALSE THEN returncode:=1
                ENDIF
            ENDIF

            SELECT returncode
                CASE 0
                    res:=ST_TIMEOUT
                CASE 1
                    res:=CMD_FILENOTFOUND
                CASE 200 ->OK

                    IF recvlen=NIL
                        outlist('\eb#Unable to obtain size of request. Size not reported by server')
                        res:=ST_NOCONNECT
                    ELSE
                        sizecmdsuccess:=TRUE
                        fd_zero(readfds)
                        fd_set(httpsock, readfds)
                        tv.sec:=prefstimeout
                        tv.usec:=5
                        outlist('\eb#200: OK')
                        outmini('200: OK')
                        IF (fh:=Open(filepath, MODE_NEWFILE))<>NIL
                            outlist('\eb#Receiving File...')
                            outmini('Receiving File...')

                            xferfilelen:=recvlen/1024
                            mui_xferwindow, mui_xfergauge:=setupxferwin()
                            set(mui_xferwindow, MUIA_Window_Open, MUI_TRUE)
                            set(mui_xfergauge, MUIA_Gauge_Current, lenrec)

                            st.startTimer(5)
                            dlstatus:=3
                            WHILE lenrec<recvlen
                                appresult:= doMethodA(app, [MUIM_Application_Input, {signal}])
                                SELECT appresult
                                    CASE ID_STOP
                                        res:=ID_STOP
                                        lenrec:=recvlen
                                    CASE ID_ABORT
                                        res:=ID_ABORT
                                        lenrec:=recvlen
                                    CASE ID_MINISHOW
                                        openminilog()
                                    CASE ID_MINIHIDE
                                        closeminilog()
                                ENDSELECT

                                IF (WaitSelect(httpsock+1, readfds, NIL, NIL, tv, NIL))=0
                                    res:=ST_TIMEOUT
                                    lenrec:=recvlen
                                ELSE
                                    len:=Recv(httpsock, reply, 500, 0)
                                    Write(fh, reply, len)
                                    lenrec:=lenrec+len
                                    timerec:=timerec+len
                                    IF st.getTimerMsg()=TRUE
                                        timerec:=Div(timerec, 5)
                                        StringF(cpsstr, '\ecCPS Transfer Rate: \d', timerec)
                                        SetAttrsA(mui_cpsrate, [Eval(`(MUIA_Text_Contents)), cpsstr, TAG_DONE])
                                        timerec:=1
                                        st.waitAndRestart(5)
                                    ENDIF
                                    set(mui_xfergauge, MUIA_Gauge_Current, lenrec)

                                ENDIF

                            ENDWHILE
                            dlstatus:=1
                            closexferwin(mui_xferwindow)
                            Close(fh)
                            addcomment(filepath, PROTOCOL_HTTP)
                            outlist('\eb#File Received')
                            outmini('File Received')
                            SELECT res
                                CASE ID_ABORT
                                    outlist('\eb#Transfer Aborted')
                                    outmini('Transfer Aborted')
                                CASE ST_TIMEOUT
                                    outlist('\eb#File Transfer Timed Out')
                                    outmini('Timed Out')
                                    res:=ST_TIMEOUT
                                CASE ID_STOP
                                    outlist('\eb#Stopping All File Transfers. Please Wait...')
                                    outmini('Stopping All Transfers')
                                DEFAULT
                                    res:=ST_XFEROK
                            ENDSELECT

                        ELSE
                            outlist('\eb#Unable to save file')
                            outmini('Unable to save file')
                            res:=CMD_FILENOTFOUND
                        ENDIF
                    ENDIF
                CASE 201
                    outlist('\eb#201: Abnormal Return Code Received')
                    outmini('201 Received: See Main Log')
                    res:=ST_NOCONNECT
                CASE 202
                    outlist('\eb#202: Server Busy. Retry Later.')
                    outmini('202 Received: See Main Log')
                    res:=ST_NOCONNECT
                CASE 204
                    outlist('\eb#204: Document has no content.')
                    outmini('204 Received: See Main Log')
                    res:=ST_NOCONNECT
                CASE 206 -> RESUME OK
                    IF tryingtoresume=FALSE
                        outlist('\eb#Error: 206 received when no resume request made')
                        res:=CMD_FILENOTFOUND
                    ELSE
                        IF recvlen=NIL
                            outlist('\eb#Unable to obtain size of request')
                            res:=ST_NOCONNECT
                        ELSE
                            sizecmdsuccess:=TRUE
                            fd_zero(readfds)
                            fd_set(httpsock, readfds)
                            tv.sec:=prefstimeout
                            tv.usec:=5
                            outlist('\eb#206: File Resume OK')
                            outmini('206: Resume OK')
                            IF (fh:=Open(filepath, MODE_OLDFILE))<>NIL
                                Seek(fh,NIL,OFFSET_END)
                                outlist('\eb#Receiving File...')
                                outmini('Receiving File...')

                                xferfilelen:=recvlen/1024
                                mui_xferwindow, mui_xfergauge:=setupxferwin()
                                set(mui_xferwindow, MUIA_Window_Open, MUI_TRUE)
                                set(mui_xfergauge, MUIA_Gauge_Current, lenrec)

                                st.startTimer(5)
                                dlstatus:=3
                                WHILE lenrec<recvlen
                                    appresult:= doMethodA(app, [MUIM_Application_Input, {signal}])
                                    SELECT appresult
                                        CASE ID_STOP
                                            res:=ID_STOP
                                            lenrec:=recvlen
                                        CASE ID_ABORT
                                            res:=ID_ABORT
                                            lenrec:=recvlen
                                        CASE ID_MINISHOW
                                            openminilog()
                                        CASE ID_MINIHIDE
                                            closeminilog()
                                    ENDSELECT

                                    IF (WaitSelect(httpsock+1, readfds, NIL, NIL, tv, NIL))=0
                                        res:=ST_TIMEOUT
                                        lenrec:=recvlen
                                    ELSE
                                        len:=Recv(httpsock, reply, 500, 0)
                                        Write(fh, reply, len)
                                        lenrec:=lenrec+len
                                        timerec:=timerec+len
                                        IF st.getTimerMsg()=TRUE
                                            timerec:=Div(timerec, 5)
                                            StringF(cpsstr, '\ecCPS Transfer Rate: \d', timerec)
                                            SetAttrsA(mui_cpsrate, [Eval(`(MUIA_Text_Contents)), cpsstr, TAG_DONE])
                                            timerec:=1
                                            st.waitAndRestart(5)
                                        ENDIF
                                        set(mui_xfergauge, MUIA_Gauge_Current, lenrec)

                                    ENDIF

                                ENDWHILE
                                dlstatus:=1
                                closexferwin(mui_xferwindow)
                                Close(fh)
                                addcomment(filepath, PROTOCOL_HTTP)
                                outlist('\eb#File Received')
                                outmini('File Received')
                                SELECT res
                                    CASE ID_ABORT
                                        outlist('\eb#Transfer Aborted')
                                        outmini('Transfer Aborted')
                                    CASE ST_TIMEOUT
                                        outlist('\eb#File Transfer Timed Out')
                                        outmini('Timed Out')
                                        res:=ST_TIMEOUT
                                    CASE ID_STOP
                                        outlist('\eb#Stopping All File Transfers. Please Wait...')
                                        outmini('Stopping All Transfers')
                                    DEFAULT
                                        res:=ST_XFEROK
                                ENDSELECT

                            ELSE
                                outlist('\eb#Unable to save file')
                                outmini('Unable to save file')
                                res:=CMD_FILENOTFOUND
                            ENDIF
                        ENDIF
                    ENDIF
                CASE 301
                    outlist('\eb#301: File permanently moved to new location')
                    outmini('301 Received: See Main Log')
                    res:=CMD_FILENOTFOUND
                CASE 302
                    outlist('\eb#302: File temporarily moved to new location')
                    outmini('302 Received: See Main Log')
                    res:=CMD_FILENOTFOUND
                CASE 304
                    outlist('\eb#304: Abnormal Return Code Received')
                    outmini('304 Received: See Main Log')
                    res:=ST_NOCONNECT
                CASE 400
                    outlist('\eb#400: Bad Request - Check URL')
                    outmini('400 Received: See Main Log')
                    res:=ST_NOCONNECT
                CASE 401
                    outlist('\eb#401: Document Requires Authorisation. Unsupported in this version.')
                    outmini('401 Received: See Main Log')
                    res:=CMD_FILENOTFOUND
                CASE 403
                    outlist('\eb#403: You are forbidden to access this file.')
                    outmini('403 Received: See Main Log')
                    res:=CMD_FILENOTFOUND
                CASE 404
                    outlist('\eb#404: File Not Found.')
                    outmini('404 Received: See Main Log')
                    res:=CMD_FILENOTFOUND
                CASE 500
                    outlist('\eb#500: Internal Error Occured at server.')
                    outmini('500 Received: See Main Log')
                    res:=ST_NOCONNECT
                CASE 501
                    outlist('\eb#501: Request Method unsupported by server.')
                    outmini('501 Received: See Main Log')
                    res:=ST_NOCONNECT
                CASE 502
                    outlist('\eb#502: Abnormal Return Code. Gateway use is unsupported.')
                    outmini('502 Received: See Main Log')
                    res:=ST_NOCONNECT
                CASE 503
                    outlist('\eb#503: Service Unavailable. Please try later.')
                    outmini('503 Received: See Main Log')
                    res:=ST_NOCONNECT
                DEFAULT
                    outlist('\eb#XXX: Unknown Return Code Received.')
                    outmini('XXX Received: See Main Log')
                    res:=ST_NOCONNECT
        ENDSELECT

    ELSE
        outlist('\eb#Unable to connect')
        outmini('Unable to connect')
        res:=ST_NOCONNECT
    ENDIF
    CloseSocket(httpsock)

ELSE
    outlist('Unable to create socket')
    outmini('Socket Error')
    res:=ST_NOCONNECT
ENDIF

ENDPROC

PROC returndomain(text)
DEF domain[500]:STRING
StrCopy(domain, text)
MidStr(domain, domain, 0, InStr(domain,'/'))
ENDPROC domain

PROC returnhttpfile(text)
DEF httpfile[500]:STRING,
    x,
    first,
    last

StrCopy(httpfile, text)
first:=InStr(httpfile,'/')
FOR x:=0 TO EstrLen(httpfile)-1
    IF httpfile[x]=47 THEN last:=x
ENDFOR

MidStr(httpfile, httpfile, last+1, ALL)

ENDPROC httpfile

PROC returnhttppath(text)
DEF httppath[500]:STRING,
    last,
    first,
    x=0

StrCopy(httppath,text)
first:=InStr(httppath,'/')
FOR x:=0 TO EstrLen(httppath)-1
    IF httppath[x]=47 THEN last:=x
ENDFOR
MidStr(httppath, httppath, first, (last-first)+1)

ENDPROC httppath

PROC httpreccommand(httpsock)
DEF buf[4096]:STRING,
    len,
    x[1]:STRING,
    readfds:fd_set,
    tv:timeval

fd_zero(readfds)
fd_set(httpsock, readfds)
tv.sec:=prefstimeout
tv.usec:=5

IF WaitSelect(httpsock+1, readfds, NIL, NIL, tv, NIL)>0

    WHILE StrCmp(x, '\n')=FALSE
        len:=Recv(httpsock, x, 1, 0)
        StrAdd(buf, x)
    ENDWHILE

ELSE
    StrCopy(buf, 'TIMEOUT')
ENDIF

ENDPROC buf



PROC decodehttplen(text)
DEF mystr[500]:STRING
MidStr(mystr, text, 15, ALL)
ENDPROC Val(mystr)



PROC decodehttpserver(text)
DEF mystr[500]:STRING

StrCopy(mystr, text)
StrCopy(mystr, mystr, EstrLen(mystr)-2)

ENDPROC mystr

PROC decodehttpreturn(text)
DEF mystr[500]:STRING
StrCopy(mystr, text)
MidStr(mystr, mystr, 9, ALL)
ENDPROC Val(mystr)


PROC ftplogout()
    commandtypea('QUIT','NOPAR')
    alivetransfer:=0
ENDPROC

