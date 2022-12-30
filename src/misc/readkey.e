-> Read Key Routine

MODULE 'dos/dos'

PROC main()
DEF keyfh,
    namerotation,
    lenname,
    name[500]:STRING,
    addressrotation,
    lenaddress,
    address[500]:STRING,
    keyrotation,
    lenkey,
    keynum[500]:STRING,
    x,
    checksum=NIL,
    checktest=NIL

IF (keyfh:=Open('ram:gofetch.key',MODE_OLDFILE))<>NIL

    Read(keyfh,{checksum},4)
->    WriteF('Checksum is \d\n\n',checksum)


    Read(keyfh,{namerotation},4)
->    WriteF('Name Rotation is \d\n',namerotation)

    Read(keyfh,{lenname},4)
->    WriteF('Name len is \d\n',lenname)

    Read(keyfh,name,lenname)
->    WriteF('Coded Name is \s\n\n',name)


    Read(keyfh,{addressrotation},4)
->    WriteF('Address Rotation is \d\n',addressrotation)

    Read(keyfh,{lenaddress},4)
->    WriteF('Address len is \d\n',lenaddress)

    Read(keyfh,address,lenaddress)
->    WriteF('Coded Address is \s\n\n',address)


    Read(keyfh,{keyrotation},4)
->    WriteF('Key rotation is \d\n',keyrotation)

    Read(keyfh,{lenkey},4)
->    WriteF('Key Length is \d\n',lenkey)

    Read(keyfh,keynum,lenkey)
->    WriteF('Coded Key is \s\n\n',keynum)


    FOR x:=0 TO lenname-1
        name[x]:=name[x]-namerotation
        checktest:=checktest+name[x]
    ENDFOR
    WriteF('Decoded Name is \s\n',name)


    FOR x:=0 TO lenaddress-1
        address[x]:=address[x]-addressrotation
        checktest:=checktest+address[x]
    ENDFOR
    WriteF('Decoded Address is \s\n',address)


    FOR x:=0 TO lenkey-1
        keynum[x]:=keynum[x]-keyrotation
        checktest:=checktest+keynum[x]
    ENDFOR
    WriteF('Decoded Key Num is \s\n',keynum)
 
    IF checksum=checktest
        WriteF('\nYou are registered\n\n')
    ELSE
        WriteF('\nKeyfile Has been Hacked\n\n')
    ENDIF

    Close(keyfh)
ELSE
    WriteF('Unable to lock Key: Unregistered.\n')
ENDIF



ENDPROC


