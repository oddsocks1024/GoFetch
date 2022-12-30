->MODULE  ->'exec/memory',
->  MODULE      'timer',
MODULE        'devices/timer',
        'exec/io',
        'amigalib/io'

DEF ioreq:timerequest,
    ttv:timeval,
    po:io

PROC main()

WriteF('Timer Test\n')

IF (OpenDevice('timer.device',0,ioreq,0))=NIL

po.command:=TR_ADDREQUEST
po.flags:=0
ttv.secs:=10
ttv.micro:=0
ioreq.io:=po
ioreq.time:ttv

WriteF('Boo\n')
SendIO(ioreq)

WHILE(CheckIO(ioreq)=FALSE)
ENDWHILE

WriteF('30 Seconds Up\n')


IF (CheckIO(ioreq)=0) THEN AbortIO(ioreq)
WaitIO(ioreq)
CloseDevice(ioreq)
ELSE
    WriteF('Unable to Get Timer Device')
ENDIF


ENDPROC

