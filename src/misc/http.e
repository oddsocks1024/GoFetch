MODULE  'socket_pragmas',
        'amitcp/sys/socket',
        'amitcp/sys/types',
        'amitcp/sys/time',
        'amitcp/netdb',
        'amitcp/netinet/in',
        'dos/dos'

DEF sock

PROC main()
DEF hst: PTR TO hostent,
    sain:PTR TO sockaddr_in,
    command[500]:STRING,
    rep[500]:STRING,
    len=0,
    lenrec=0,
    fh,
    filelength

StrCopy(command,'GET /a.lha HTTP/1.0\b\nUser-Agent: GoFetch!/0.97b\b\n\b\n')

IF (socketbase:=OpenLibrary('bsdsocket.library',NIL))<>NIL
    IF (sock:=Socket(AF_INET, SOCK_STREAM, 0))<>-1

        IF sain:=New(SIZEOF sockaddr_in)
            sain.family:=AF_INET
            IF hst:=Gethostbyname('100.0.0.1')
                CopyMem(Long(hst.addr_list), sain.addr, hst.length)
            ENDIF
        sain.port:=80
        ENDIF

        IF Connect(sock, sain, SIZEOF sockaddr_in)<>-1
            Send(sock,command,EstrLen(command),MSG_WAITALL)
            WHILE StrCmp(rep,'\b\n')=FALSE
                StrCopy(rep,httpreccommand())
                WriteF('\s',rep)
                IF StrCmp(rep,'Content-Length:',15)=TRUE
                    filelength:=decodehttplen(rep)
                    WriteF('File Length is \d\n',filelength)
                ENDIF
            ENDWHILE

            IF (fh:=Open('RAM:a.lha',MODE_NEWFILE))<>NIL
                WHILE lenrec<filelength
                    len:=Recv(sock,rep,500,0)
                    Write(fh,rep,len)
                    lenrec:=lenrec+len
                ENDWHILE
                Close(fh)
            ELSE
                WriteF('Unable to open file')
            ENDIF
        ELSE
            WriteF('Cant connect\n')
        ENDIF
        CloseSocket(sock)
    ELSE
        WriteF('sock problem\n')
    ENDIF

        

    CloseLibrary(socketbase)
ELSE
    WriteF('Unable to open bsdsocket.library\n')
ENDIF



ENDPROC

PROC httpreccommand()
DEF buf[4086]:STRING,
    len,
    x[1]:STRING

WHILE StrCmp(x, '\n')=FALSE
    len:=Recv(sock,x,1,0)
    StrAdd(buf, x)
ENDWHILE


ENDPROC buf

PROC decodehttplen(text)
DEF mystr[500]:STRING
MidStr(mystr,text, 15, ALL)
ENDPROC Val(mystr)
