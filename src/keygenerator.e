->Go Fetch! Key Generatorl
->Trivially simple and basically just obfuscation
MODULE 'dos/dos'
-> Structure
-> 4 Byte CheckSum = First Char of Name, First Char Address, First Char
-> Keynum+7
-> 4 Byte Name Rotation Value
-> 4 Byte Name Lengh
-> Name
-> 4 Byte Address Rotation Value
-> 4 Byte Address Length
-> Address
-> 4 Byte Key Rotation
-> 4 Byte Key Length
-> Key
-> Load of Shit


DEF name[500]:STRING,
    name2[500]:STRING,
    address[500]:STRING,
    keynum[500]:STRING

-> Rotation must NOT exceed 125
-> For security make rotation at least 26
PROC main()
DEF checksum=0,
    namerotation=103,
    addressrotation=98,
    keyrotation=37,
    lenname,
    lenaddress,
    lenkeynum,
    x,
    keyfh

StrCopy(name,'Joe Blogs')
StrCopy(address,'95 Blah Blah Avenue')
StrCopy(keynum,'JB2000')
StrCopy(name2,name)
lenname:=EstrLen(name)
lenaddress:=EstrLen(address)
lenkeynum:=EstrLen(keynum)

IF (keyfh:=Open('PROGDIR:gofetch.key',MODE_NEWFILE))<>NIL

    FOR x:=0 TO lenname-1
        checksum:=checksum+name[x]
    ENDFOR

    FOR x:=0 TO lenaddress-1
        checksum:=checksum+address[x]
    ENDFOR

    FOR x:=0 TO lenkeynum-1
        checksum:=checksum+keynum[x]
    ENDFOR

    Write(keyfh,{checksum},4)

    Write(keyfh,{namerotation},4)
    Write(keyfh,{lenname},4)
    FOR x:=0 TO lenname-1
        name[x]:=name[x]+namerotation
    ENDFOR
    Write(keyfh,name,lenname)

    Write(keyfh,{addressrotation},4)
    Write(keyfh,{lenaddress},4)
    FOR x:=0 TO lenaddress-1
        address[x]:=address[x]+addressrotation
    ENDFOR
    Write(keyfh,address,lenaddress)

    Write(keyfh,{keyrotation},4)
    Write(keyfh,{lenkeynum},4)
    FOR x:=0 TO lenkeynum-1
        keynum[x]:=keynum[x]+keyrotation
    ENDFOR    
    Write(keyfh,keynum,lenkeynum)

    FOR x:=0 TO 25*keyrotation
        Write(keyfh,Rnd(255),1)
    ENDFOR

    Write(keyfh,'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX',83)
    Write(keyfh,'ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ',41)


    FOR x:=0 TO 25*keyrotation
        Write(keyfh,Rnd(255),1)
    ENDFOR

    Write(keyfh,name2,lenname)

    WriteF('Generated\n\n')
    Close(keyfh)
ELSE
    WriteF('Unable to Save Keyfile')
ENDIF



ENDPROC

