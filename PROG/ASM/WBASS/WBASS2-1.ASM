
;Programma:WB-ASS2            versie 1.0
;door:     Wilbert Berendsen  begin 1988

;WB-ASS2 is een Z-80 Assembler voor MSX-2 Computers (liefst met een Memory-
;Mapper), werkt ook op MSX-1. De ingebouwde monitor geeft toegang tot alle slots
;en subslots en MM-blokken en de video-RAM die in de computer zitten. Totaal:
;EDITOR, DISASSEMBLER, ASSEMBLER, DISK-ROUTINES (ook sector), LOADER
;De tekst blijft in het geheugen en de ML kan ook in het geheugen gezet worden
;zonder tekstverlies.
;De assembler kent de pseudo instructies: ORG, EQU, END, DB, DW, DS.

DEFKEY MACR
 DB %1
 DW %2
 ENDM

;Constanten:
tekstbuf: EQU &HF55E+18
addrbuf: EQU &HF55E
filebuf2: EQU &HF523
filebuf: EQU &HF60C
filebuf1: EQU &HF635

pos0: EQU &HF3DD
csrlin: EQU &HF3DC
msxdos: EQU &HF37D
chput: EQU &HA2
lptout: EQU &HA5
key?: EQU &H9C
msx?: EQU &H2D
chget: EQU &H9F
lpttst: EQU &HA8
enaslt: EQU &H24
exptbl: EQU &HFCC1
porta: EQU &HA8
expslt: EQU &HFFFF
;routines voor mijn Assembler/Monitor

 ORG &H4000
 DW 0
 DW 0
 DW starta
 DW 0,0,0,0,0
variab: EQU $
;IX-variabelen:
mode: EQU 0    ;bit 0: csr op 17h, 1 csr op 11h, 2 1="Label bn",3 asmmode
width: EQU 1
prtwidth: EQU 2
stflag: EQU 3  ;stuurvlag
kolommen: EQU 4
kolbre: EQU 5
dirkol: EQU 6
ab: EQU 7
drives: EQU 8
defdrive: EQU 9
begx: EQU 10
xpos: EQU 11
lenlin: EQU 12
flag: EQU 13

insm: EQU 0
linsc: EQU 2
printf: EQU 7

;      EQU 14
ctrl: EQU 15
lin: EQU 16
keyget: EQU 17
prt: EQU 18
setflag: EQU 19
backup: EQU 0
graph: EQU 1

const: EQU 22
optie: EQU 23
mon: EQU 24         ;1b
dechex: EQU 25       ;1b 1=dec, 0=hex
indflg: EQU 26       ;voor index-register bij disass.
disflg: EQU 27       ;voor de d in (XY+d)
groep: EQU 28       ;instructie-plaats
rstflag: EQU 29        ;voor DB en DW bij RST 8 en RST 30H
restart: EQU 30        ;1b 1=wel DB's 0=niet




 DS 40          ;ruimte voor IX-variabelen

;hier komen de variabelen voor de tekstbuffer en dergelijke !!!!
;VARIABELEN VARIABELEN VARIABELEN VARIABELEN VARIABELEN

beginbuf: DW &H8800     ;begin van de tekstbuffer
beglabel: DS 2          ;begin actuele labeltabel
eindtxt: DS 2           ;eerste vrije byte n  tekst
diskbuf: DS 2           ;adres eerste file I/O buffer
eindbuf: DW &HBF00      ;eind buffer
begin: DS 2
doel: DS 2
lengte: DS 2
rest: DS 2
lastadr: DS 2
stack: DS 2

linadr: DS 2            ;adres v.e. regel
aantr: DS 2             ;aantal regels blok.

aantal: DS 2            ;aantal regels
filin: DS 2             ;regelnummer van regel bovenaan scherm.
regel: DS 2             ;regel die op dit moment geassembleerd wordt

MP: DS 2                ;machine pointer tijdens assembleren.
begadr: DS 2
varbuff: DS 20   ;ruimte voor meer variabelen

opbuf: DS 8
;----------------------


tbak: DM "BAK"
asmname: DM "ASSEMBLER"+0

regbuf: DS 20
regbuf1: DS 20


buffer1: DS &H4180-$

memrout: EQU &HF420
byte: LD A,H
 RLCA
 RLCA    ;A=page-nummer
 AND 3
 PUSH HL
 LD HL,instr
 LD (HL),E
 LD HL,pagetabl   ;tabel met attr-bytes voor slot-indeling
 LD E,A  ;E=page-nummer
 RLCA    ;A maal 2
 ADD A,L
 LD L,A
 LD A,(HL)        ;primair slot (b0,1) en secundair slot (b2,3)
 INC HL
 LD C,(HL)        ;memory-mapper blok.
 POP HL
 DEC E       ;E=255  :page 2
 DEC E       ;E=254  :page 1
 DEC E       ;E=253  :page 0
 RET NZ      ;terug als het geen page3 is.
 EXX
 RRCA        ;slot in b6,7
 RRCA
 LD E,A
 AND &HC0
 LD B,A      ;slot in B
 IN A,(porta)
 LD D,A
 AND &H3F
 OR B
 DI
 OUT (porta),A
 BIT 5,E
 SCF
 JR Z,ok   ;zet expanded slot alleen als het werkelijk een expanded is.
 LD A,E
 RRCA
 RRCA
 AND &HC0
 LD E,A
 LD A,(expslt)
 CPL
 LD C,A
 AND &H3F
 OR E
 LD (expslt),A
ok: EX AF,AF
 IN A,(&HFF)
 EXX
 LD E,A
 LD A,C
 OUT (&HFF),A
instr: LD B,(HL)  ;of LD (HL),B
 LD A,E
 OUT (&HFF),A
 EXX
 EX AF,AF
 JR C,ok1
 LD A,C
 LD (expslt),A
ok1: LD A,D
 OUT (porta),A
 EI
 EXX
 LD A,B
 CP A
 RET
;lees/schrijf expslt met B in slotnummer C
lees3: LD A,&H46
 JR get3
schrijf3: LD A,&H70
get3: LD (instr1),A
 LD A,C
 PUSH HL
 RLCA
 RLCA
 AND &HC0
 LD L,A
 IN A,(porta)
 LD D,A
 AND &H3F
 OR L
 OUT (porta),A
 LD HL,expslt
instr1: LD B,(HL)  ;waarde expanded slot
 LD A,D
 OUT (porta),A
 LD A,B
 POP HL
 RET
getbyte:
 PUSH DE
 PUSH BC
 LD E,&H46   ;LD B,(HL)
 CALL byte
 SCF
 CALL NZ,byt3
 POP BC
 POP DE
 RET
brebyte:
 PUSH DE
 PUSH BC
 LD B,A
 LD E,&H70    ;LD (HL),B
 CALL byte
 CALL NZ,byt3
 POP BC
 POP DE
 RET


;deze routines moeten in page 3 gezet worden!!!!!!!!!!!
begmem:
byt3: EQU memrout
;lees/schrijf byte in slot
 PUSH AF
 LD A,B
 DEC E
 LD B,E
 LD E,C
 LD C,B
 IN B,(C)
 OUT (C),E
 LD E,A
 POP AF
 PUSH BC
 JR NC,write
 CALL &HC
 DB 1
write: CALL &H14
 POP BC
 OUT (C),B
 RET
pagetabl: EQU memrout+$-begmem
pt: DS 8
comtabl: EQU memrout+$-begmem
ct: DS 8

goto: EQU memrout+$-begmem ;roep machinetaal programma aan in de juiste slots.
 DI
 CALL pageon
 DB &HCD
calladr: EQU memrout+$-begmem
 DW 0
 PUSH AF
 PUSH HL
 PUSH DE
 PUSH BC
 LD HL,comtabl+6
 CALL setport
 OUT (porta),A
 CALL memmap
 LD A,&B110110   ;0,3,1,2
 CALL expanded
 EI
 JR endpage
pageon: EQU memrout+$-begmem
 PUSH AF
 PUSH HL
 PUSH DE
 PUSH BC
 LD HL,pagetabl+6
 CALL setport  ;zet de gewenste slot indeling in E
 LD A,&B100111   ;=0,2,1,3
 CALL expanded
 CALL memmap
 LD A,E
 OUT (porta),A
endpage:
 POP BC
 POP DE
 POP HL
popafret: POP AF
 RET
setport: EQU memrout+$-begmem
 XOR A
 LD B,3
begl: RLCA
 RLCA
 LD E,A
 DEC L
 DEC L
 LD A,(HL)
 AND 3
 OR E
 DJNZ begl
 LD E,A
 IN A,(porta)
 AND &HC0
 OR E
 LD E,A   ;de waarde die naar de output-poort moet
 RET

memmap: EQU memrout+$-begmem
 LD BC,&H3FC
 PUSH HL
outmlus: INC L
 LD A,(HL)
 OUT (C),A
 INC L
 INC C
 DJNZ outmlus
 POP HL
 RET

expanded: EQU memrout+$-begmem
expd1: PUSH AF
 AND 3
 JR Z,popafret
 LD B,A
 DEC A
 ADD A,A
 PUSH HL     ;HL=pagetabl of comtabl
 ADD A,L
 LD L,A      ;+page*2
 LD A,(HL)   ;haal slot
 POP HL
 AND A
 CALL M,expand
 POP AF
 RRCA
 RRCA
 JR expd1

expand: EQU memrout+$-begmem
 LD C,A
 PUSH HL
 LD L,&HFC
 AND &HC
 DEC B
 JR Z,deel4
 LD L,&HF3
 DEC B
 JR Z,okzo
 LD L,&HCF
 RLCA
 RLCA
 JR okzo
deel4: RRCA
 RRCA
okzo:
 LD H,A
 LD A,(comtabl+6)  ;huidig slot page 3.
 SUB C
 AND 3
 PUSH AF
 LD A,(expslt)
 CALL NZ,lees3     ;lees expslt C als we er al niet inzitten
 CPL
 AND L
 OR H
 LD B,A
 POP AF
 POP HL
 JP NZ,schrijf3
 LD A,B
 LD (expslt),A
 RET
endmemrt: EQU memrout+$-begmem
endmem:


getcom: LD DE,ct+7
 LD HL,&HF344
 LD BC,&H4FF
 DEC (IX+ab)
 PUSH DE
ld1lus: IN A,(C)
 AND (IX+ab)
 LD (DE),A
 DEC E
 LDD
 DJNZ ld1lus
 INC (IX+ab)
 LD A,(exptbl)
 LD (ct),A
 POP HL
 LD C,8
 LDDR
 RET

initprog: LD C,&HE
 LD E,&HFF
 CALL system
 INC A
 LD (IX+drives),A     ;aantal logische drives+1.
 LD C,&H19
 CALL system
 INC A
 LD (IX+defdrive),A  ;def. drive 1=A, 2=B
 LD A,(msx?)
 AND A
 LD HL,msx1
 JR Z,m1
 LD HL,msx2
m1: LD DE,vpeek
 LD BC,&H3FF
copyadr: INC DE
 LDI
 LDI
 DJNZ copyadr
COPYSEL: LD DE,memrout  ;kopieer routines in systeem-ram
 LD HL,begmem
 LD BC,endmem-begmem
 LDIR              ;zet subroutines in page 3
 RET

msx1: DW &H4A
 DW &H4D
 DW &H56
msx2: DW &H174
 DW &H177
 DW &H16B

vpeek: JP &H4A
vpoke: JP &H4D
fillvram: JP &H56

;*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+
;geheugen routines!!!!

berlenb: PUSH HL
 LD HL,(eindtxt)
 AND A
 SBC HL,DE
 LD B,H
 LD C,L
 POP HL
 RET


INSERT: ;voeg ruimte in op HL, verschuiven tot DE
 EX DE,HL
 CALL berlenb
 ADD HL,BC       ;in HL nu doel+lengte blok
 LD DE,(diskbuf)
 RST &H20        ;als HL>=DE is dan error
 JP NC,memvol
 EX DE,HL
 LD HL,(eindtxt)
 DEC HL
 DEC DE
 LDDR       ;HL<DE
 JR .2

DELETE: ;wis ruimte tussen HL en DE
 CALL berlenb
 EX DE,HL   ;in HL bron, in DE doel.
 LDIR       ;HL>DE
.2: AND A
 EX DE,HL
 SBC HL,DE
 EX DE,HL
 LD HL,(eindtxt)
 ADD HL,DE
 LD (eindtxt),HL
 LD HL,(beglabel)
 ADD HL,DE
 LD (beglabel),HL
 RET


COPY:                 ;kopieert HL naar DE lengte BC met tussenvoegen.
;Deze routine werkt zowel voor MSX1 (tekstbuffer=&H8000 tot TOPMEM)
;als voor MSX2 (tekstbuffer in memory-mapper).
 PUSH HL
 PUSH DE
 PUSH BC
 EX DE,HL
 PUSH HL
 ADD HL,BC
 EX DE,HL
 POP HL
 CALL INSERT   ;ruimte maken
 POP BC
 POP DE
 POP HL
 RST &H20    ;als doel (DE) lager is dan bij bron lengte optellen.
 JR C,doelh   ;nee, doel is hoger.
 ADD HL,BC
doelh: LDIR  ;overbrengen blok.
 RET


MOVE:       ;functie verplaats blok (ook voor computers zonder mapper!)
 ;Verplaats blok van HL naar DE, lengte BC zowel achteruit als vooruit

 ;eerst kijken of doel en bron (DE en HL) ook gelijk zijn.
 RST &H20
 RET Z
 PUSH DE
 LD (begin),HL
;nu de lengte delen door de vrije ruimte HL=HL/DE, DE=rest
 LD HL,(diskbuf)
 LD DE,(eindtxt)
 XOR A
 SBC HL,DE     ;vrije ruimte in HL
 LD (lengte),HL  ;begin bufferruimte in DE
 EX DE,HL
;DE=vrije ruimte
 LD H,B
 LD L,C
mlus1: SBC HL,DE    ;trek vrije ruimte van lengte blok af.
 INC A
 JP Z,memvol
 JR NC,mlus1
 ADD HL,DE
 DEC A
 LD (rest),HL
 POP DE     ;in DE het doel

movelus: PUSH AF
 AND A
 LD BC,(lengte)  ;maximale lengte buffer als we nog niet aan het eind zijn
 JR NZ,move1
 LD BC,(rest)
 LD A,B
 OR C
 JR Z,endmove
move1:          ;begin buffer op stack
 PUSH BC
 PUSH DE        ;doel
 LD DE,(eindtxt)
 LD HL,(begin)  ;begin van het blok in HL
 LDIR           ;breng zo groot mogelijk stuk naar de buffer
 POP DE         ;doel.
                ;POP BC lengte blok
;nu moet het doel DE met het begin worden vergeleken, om te kijken
;in welke richting de tussenliggende tekst moet worden verschoven
;(er wordt dus inderdaad geen letter teveel verschoven!!)
 PUSH HL
 LD HL,(begin)
 RST &H20
;als het doel lager is, dan moet de tussenliggende tekst omhoog
;                       dan moet gelden:doel=doel+lengte,begin=begin+lengte
;als het doel hoger is, dan moet de tussenliggende tekst omlaag
;                       dan moet gelden:doel=doel-lengte,begin=begin
 JP NC,doellaag
 EX (SP),HL   ;in HL begin+lengte, in (SP) staat begin
 EX DE,HL     ;begin+lengte=begin nu te verplaatsen blok.
;lengte tussenliggende tekst=doel-begin+lengte
 AND A
 SBC HL,DE    ;HL=doel-(begin+lengte)
 LD B,H
 LD C,L       ;in BC
 EX DE,HL     ;in HL begin+lengte
;nu moet in DE nog het begin
 POP DE       ;begin van stack
 JR Z,verder
 LDIR
              ;DE=doel-lengte
 JR verder
doellaag:
;de tussenliggende tekst moet omhoog, doel=doel+lengte, begin=begin+lengte
;in DE staat doel, in HL begin
;lengte (tussenliggende tekst)=doel-begin

;in DE moet begin+lengte, in HL begin
 SBC HL,DE
 LD B,H
 LD C,L
 ADD HL,DE
 POP DE   ;begin+lengte
 LD (begin),DE
 DEC DE
 DEC HL   ;HL is lager dan DE
 LDDR
 EX DE,HL
 INC DE   ;DE=doel+lengte
verder:     ;nu moet de buffer nog naar doel gebracht worden
 POP BC
 LD HL,(eindtxt)
 LDIR       ;dat is ook gebeurd.
endmove: POP AF
 DEC A      ;nog een blok?
 JP P,movelus
 RET        ;klaar

killtext: LD HL,(beginbuf)
 LD (HL),253  ;kopbyte
 INC HL
 LD (HL),&HFF ;laatste regel
 INC HL
 LD (HL),&HFF ;laatste label
 LD (beglabel),HL
 INC HL
 LD (eindtxt),HL
 LD HL,1
 LD (filin),HL
 LD (IX+lin),L
 DEC L
 LD (aantal),HL  ;=0
 RET

finlin: LD HL,(beginbuf)
 INC HL
 LD B,0
finlus: LD C,(HL)
 INC C
 SCF
 RET Z
 RES 7,C
 DEC DE
 LD A,D
 OR E
 RET Z
 ADD HL,BC
 JR finlus

getlin: PUSH HL       ;haal regel DE op in token naar HL
 LD HL,(lastadr)
 CALL C,finlin
 XOR A
 LD B,A
 LD C,(HL)
 INC C
 RES 7,C
 SCF
 POP DE
 JR Z,nldir
 CCF
 LDIR
nldir: LD (DE),A
 INC DE
 LD (DE),A
 LD (lastadr),HL
 RET

getasc:                       ;haal regel DE op naar &HF55E in ASCII
 PUSH HL
 LD HL,buffer1
 CALL getlin
 PUSH AF      ;CF=1, laatste regel gehad.
 LD IY,buffer1
 CALL DETOK
 LD DE,tekstbuf
 POP AF
 POP HL
 RET

getbeg: LD E,"<"
 DB 1
getend: LD E,">"
 LD B,0
 LD HL,(beginbuf)
 INC HL
getbelus: LD A,(HL)
 LD C,A
 RES 7,C
 ADD A,1
 RET C
 INC HL
 SUB 2
 JR  NZ,nofnd1
 LD A,(HL)
 CP E
 RET Z
nofnd1: ADD HL,BC
 JR getbelus

getblk: CALL getbeg
 JR C,blkerr
 DEC HL
 PUSH HL
 CALL getend
 JR C,blkerr
 INC HL
 POP DE
 AND A
 SBC HL,DE
 LD B,H
 LD C,L   ;lengte in BC, begin in DE
 RET NC
blkerr: LD B,12
 JP error

chekdoel: CALL finlin
 PUSH HL
 CALL getblk
 POP HL    ;HL<=DE  ok
 EX DE,HL
 RST &H20
 RET NC    ;ok, terug als HL>=DE
 PUSH HL   ;HL=begin
 ADD HL,BC ;+lengte
 DEC HL
 RST &H20
 POP HL
 RET C
 LD B,13
 JP error

clrblk: CALL getbeg   ;wis markers.
 CALL wis
 CALL getend
wis: RET C
 DEC HL
dellin: LD C,(HL) ;wis regel op HL
 LD B,0
 INC C
 RES 7,C
 PUSH HL
 ADD HL,BC
 EX DE,HL
 LD HL,(aantal)
 DEC HL
 LD (aantal),HL
 POP HL
 JP DELETE

inslin: LD D,H
 LD E,L
 INC DE
 PUSH HL
 CALL INSERT ;verschuiven
 LD HL,(aantal)
 INC HL
 LD (aantal),HL
 POP HL
 LD (HL),0
 RET

bepaant: LD DE,-1
 LD HL,(beginbuf)
 INC HL
 LD B,0
beplus: LD C,(HL)
 INC C
 RES 7,C
 ADD HL,BC
 INC DE
 DEC C
 JP P,beplus
 INC HL
 LD (aantal),DE  ;aantal regels bekend.
 LD (beglabel),HL ;adres labeltabel ook.
 LD C,8
lablus: LD A,(HL)
 INC A
 JR Z,ready
 ADD HL,BC
 JR lablus
ready: INC HL
 LD (eindtxt),HL
 RET

prscr: LD DE,(filin)      ;print scherm
 SCF
 LD HL,&H101
prscrlus:
 CALL getasc  ;haalt regel DE naar &HF55E, zet DE op &HF55E
              ;als CF=0 dan wordt de volgende regel opgehaald
 CALL lintoscr ;regel naar scherm
 INC L
 LD A,23
 CP L
 JR NZ,prscrlus
 RET                     ;regels staan op scherm.

invlin:
 PUSH DE     ;DE=regelnummer
 LD HL,tekstbuf+1
 LD DE,buffer1
 CALL TOKEN  ;regel staat getokenized in buffer1
 POP DE
 PUSH DE     ;Haal regelnummer weer op.
 CALL finlin ;vind regelnummer DE, zet geheugenplaats waar regel begint in HL.
 POP DE      ;regelnummer
 CALL C,invoeg0  ;als we n  de laatste regel zaten, nieuwe regels invoegen.
 PUSH HL     ;HL wijst op begin regel
 LD C,(IY+0) ;lengte nieuwe regel
 RES 7,C
 LD A,(HL)   ;lengte oude regel
 RES 7,A
 SUB C       ;doe oud-nieuw
 LD C,A
 LD B,0
 JR Z,nochange ;even lang? dan niet schuiven.
 JR NC,delstuk
 NEG
 LD C,A
 DB &H3E
delstuk: XOR A
 ADD HL,BC
 EX DE,HL
 POP HL
 PUSH HL
 AND A
 CALL Z,DELETE
 AND A
 CALL NZ,INSERT
nochange: POP DE
 LD HL,buffer1
 LD C,(HL)
 INC C
 RES 7,C
 LD B,0
 LDIR
 RET

invoeg0: PUSH DE     ;als de cursor op verboden gebied was
 PUSH HL             ;aantal regels achter laatste tellen
 LD HL,(aantal)      ;en tussenliggende regel op 0 zetten.
 AND A
 EX DE,HL
 SBC HL,DE   ;HL is het aantal regels na de laatste
 LD B,H
 LD C,L      ;aantal regels dat we te ver zaten.
 POP HL
 PUSH HL     ;HL= geheugenadres waar laatste (dummy)-regel begint (255)
 ADD HL,BC   ;tel hier het aantal regels bij op.
 EX DE,HL
 POP HL      ;HL=adres dummy-regel, DE=doeladres dr. BC=aantal niewe regels
 PUSH HL
 PUSH BC
 CALL INSERT  ;maak ruimte gelijk aan aantal regels te ver.
 POP BC
 POP HL
nullus: LD (HL),0 ;opvullen met nullen
 INC HL
 DEC BC
 LD A,B
 OR C
 JR NZ,nullus
 POP DE
 DEC HL
 LD (aantal),DE
 RET


;-------------------------------------------
;label-routines

left$: SUB C
 JR NC,left$ok
 ADD A,C
 LD C,A
 XOR A
left$ok:
 LD B,0
 LDIR
 LD C,A
 XOR A
llus: DEC C
 RET M
 LD (DE),A
 INC DE
 JR llus

berplace:  ;bereken plaats en zet in HL
 ADD HL,HL
 ADD HL,HL
 ADD HL,HL  ;maal 8
 PUSH DE
 LD DE,(beglabel)
 ADD HL,DE
 POP DE
 RET

zoeklab:            ;zoek label op HL lengte C op, zet nummer in HL
 LD DE,opbuf
 LD A,6
 CALL left$         ;zet in opbuf
 LD HL,0
labelz:
 PUSH HL
 CALL berplace
 SCF
 LD DE,opbuf
 LD B,6
 LD A,(HL)
 INC A
 CALL NZ,lhunt
 POP HL
 RET Z
 INC HL
 JR labelz


zoekl: PUSH DE
 CALL zoeklab
 JR NC,leinde ;nummer in HL
 BIT 2,(IX+mode)
 JP Z,undefi    ;geen nieuwe labels toevoegen als de editmode niet aanstaat.
nospace:   ;HL bevat nummer waar het label moet komen.
 PUSH HL
 LD DE,(eindtxt)
 DEC DE
 LD HL,(diskbuf)
 SBC HL,DE
 LD BC,8
 SBC HL,BC
 JP C,memvol
 LD HL,opbuf
 LDIR
 EX DE,HL
 LD (HL),255
 INC HL
 LD (eindtxt),HL
 POP HL
leinde: POP DE       ;nummer in HL
 RET

getlabel:          ;haal labelnummer HL op en zet op DE
 CALL berplace     ;bereken plaats
 LD B,6
lblus: LD A,(HL)
 AND &H7F
 RET Z
 LD (DE),A
 INC HL
 INC DE
 DJNZ lblus
 RET

getvlab:   ;haal waarde label DE op, zet in DE.
 PUSH HL
 EX DE,HL
 CALL berplace
 BIT 7,(HL)
 JR Z,nodef ;geen geldige waarde
 INC HL
 LD A,(HL)  ;bit 7=1 betekent: label is NIET CONSTANT !
 ADD A,A
 SBC A,A    ;255 = niet constant
 LD DE,5
 ADD HL,DE
 LD E,(HL)
 INC HL
 LD D,(HL)
 POP HL
 RET
nodef:
 PUSH BC
 CALL print$
 DM "Label "+0
 LD B,6
beglbl1: LD A,(HL)
 AND &H7F
 JR Z,endlbl1
 INC HL
 CALL chrout
 DJNZ beglbl1
endlbl1: CALL print$
 DM " niet gedef."+0
 CALL inline
 BIT 3,(IX+mode)
 JR Z,noprlin
 CALL print$
 DM " adr."+0
 LD HL,(MP)
 CALL printadr
noprlin: CALL linefeed
 BIT 3,(IX+mode)  ;1=we zijn in de assemblemode
 JP Z,naarmain
 XOR A
 LD E,A
 LD D,A
 POP BC
 POP HL
 RET

;reeks 16 bit bewerkings-routines, HL en DE, uitkomst komt in HL

;+ - * / < > = ^ OR XOR AND MOD

plus: ADD HL,DE    ;HL=HL+DE
 ;const + niet = niet
 ;niet  + const= niet
 ;niet  + niet = const
 ;const + const= const
 LD A,(IX+const)
 AND A
 JP PE,constant
nietcon: SET 1,(IX+const)
 RET

min: AND A         ;HL=HL-DE
 SBC HL,DE
;const - niet = const
;niet  - const= niet
;niet  - niet = const
;const - const= const
 LD A,(IX+const)
 CP 1
 JR Z,nietcon
 JR constant

bor: LD A,L        ;HL=HL OR DE
 OR E
 LD L,A
 LD A,H
 OR D
 LD H,A
 JR constant

bxor: LD A,L       ;HL=HL XOR DE
 XOR E
 LD L,A
 LD A,H
 XOR D
 LD H,A
 JR constant

band: LD A,L       ;HL=HL AND DE
 AND E
 LD L,A
 LD A,H
 AND D
 LD H,A
 JR constant

maal:               ;HL=HL*DE
 PUSH BC
 LD B,H
 LD C,L
 LD HL,0
 LD A,16            ;bitteller
vlus: SRL D
 RR E
 JR NC,veind
 ADD HL,BC
veind: SLA C
 RL B
 DEC A
 JR NZ,vlus
 POP BC
 JR constant

deel: LD A,D         ;HL=HL/DE
 OR E
 LD B,19
 JP Z,error          ;"Deling door 0"
 PUSH IY
 PUSH HL
 POP IY
 LD HL,0               ;HL=0
 LD B,16
deellus: ADD IY,IY
 ADC HL,HL
 RST &H20
 JR C,deind
 SBC HL,DE
 INC IY
deind: DJNZ deellus
 EX DE,HL  ;rest in DE
 PUSH IY
 POP HL
 POP IY
constant: RES 1,(IX+const)
 RET

macht: LD C,E           ;HL=HL^DE
 LD B,D    ;BC=n
 LD DE,1   ;DE=Z
           ;HL=K
maclus: SRL B
 RR C
 JR NC,even
           ;nu moet Z=Z*K
 PUSH HL
 CALL maal
 EX DE,HL      ;dan is BC even...
 POP HL
even: PUSH DE   ;nu moet K=K*K
 LD D,H
 LD E,L
 CALL maal
 POP DE
 LD A,B
 OR C
 JR NZ,maclus
con1: EX DE,HL
 JR constant

modulo: CALL deel
 JR con1

bertabel: DW plus,min,maal,deel,macht,band,bxor,bor,modulo

getval: LD DE,0
 RES 1,(IX+const)
 LD A,(HL)
 CP 34
 JR Z,asccod
 CP 128+24     ;$
 JR Z,hier$
 CP &HC0
 RET C
 INC HL
 LD E,(HL)
 INC HL
 LD D,(HL)
 INC HL
 JR NZ,readyval
 CALL getvlab
 AND A     ;255=niet constant
 JR Z,readyval
 SET 1,(IX+const)
readyval: LD A,(HL)
 CP &HC0
 RET C
operr: LD B,14
 JP error
asccod: INC HL
 LD E,(HL)
 INC HL
 LD A,(HL)
 CP 34
 JR NZ,operr
reahie$: INC HL
 JR readyval
hier$: LD DE,(MP)
 JR reahie$

;*+*+*+*+*+*+*+*+*+*+* 16 Bits Rekenkundige Evaluator *+*+*+*+*+*+*+*+*
evalua:
 LD A,(HL)
 CP 2
 RET C
 INC HL
 CP 6
 RET C   ;CF=1:missing operand.
 JR Z,nodec1
 DEC HL
nodec1: PUSH BC
 CALL eva1
 POP BC
 CP 2   ;komma
 RET Z
 DEC HL
 AND A
 RET
eva1:        ;evalueert een rekenkundige uitdrukking
;        ;=1
;        ,=2
;        )=4
;        (=6
;        +=8
;        -=10
;        *=12
;        /=14
;        ^=16
;      AND=128+25
;      XOR=128+26
;      OR =128+27
;      MOD=128+28

 EXX
 LD HL,0
 EXX
 LD C,0    ;+  start bewerking
 LD (IX+const),C
ev1:
 CALL getval
;in C staat welke bewerking moet.
 PUSH HL    ;adres met string
 PUSH DE
 LD B,0
 LD HL,bertabel
 ADD HL,BC
 LD E,(HL)
 INC HL
 LD D,(HL)
 LD C,A
 EXX
 POP DE     ;zojuist opgehaalde waarde.
 CALL jpdea
 SRL (IX+const)   ;naar vorige getal, BIT 0,(IX+const)=1: relocatable
 PUSH HL
 EXX     ;waarde=HL'
 POP DE  ;nieuwe waarde in DE
 POP HL  ;adres
 INC HL
 LD A,C  ;bewerking die nu moet
 CP 6    ;, of )
 RET C
 JR Z,operr ;(
 CP 18
 JR C,oktab ;+ - * / ^
 SUB 128+25
 JR C,operr
 CP 4       ;AND XOR OR MOD
 JR NC,operr
 ADD A,A
 ADD A,18
oktab: SUB 8
 LD C,A
 JR ev1
jpdea: EXX
 PUSH DE
 EXX
 RET
;*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*
getsin:   ;single byte
 CALL evalua
 LD A,E
 RET C  ;missing operand
 CALL twocompl
 RET NC
 JP overf

twocompl: INC D
 LD A,E
 JR Z,twocpl
 AND A
 DEC D
 RET Z
 SCF
 RET
twocpl: AND A
 RET M
 SCF
 RET

getmembk: CALL getmem1
 JR getok1
getdat: CALL getsin
 JR getok1
getadr: CALL evalua
getok1:
 RET NC
misoper: LD B,15
 JP error

getmem1:      ;haal memory-blok (beginadres, eindadres, [doeladres])
 CALL getadr  ;haal beginadres
 PUSH DE      ;in DE
 LD A,(HL)
 CP 134       ;L xx = met lengte xx  (register L)
 PUSH AF
 JR NZ,noinc
 INC HL
noinc: CALL getadr   ;HAAL eindadres in DE
 POP AF
 EX (SP),HL      ;HL=begin, DE=einde
 EX DE,HL     ;DE=begin
 JR NZ,noinc1  ;naar noinc1 als er geen "L" was
 ADD HL,DE       ;Begin+lengte=einde in HL
 DEC HL          ;HL=einde
noinc1:
 AND A
 SBC HL,DE
 LD B,10
 JP C,error
 LD B,H
 LD C,L
 EX DE,HL   ;HL=begin, BC=lengte
 INC BC     ;tot en met
 EX (SP),HL ;HL= weer plaats in commando regel
 LD DE,0
 CALL evalua ;haal derde waarde op.
 POP HL
 RET
 DW 0
;---------------------------------

;Deze subroutine codeert een operand-tekst van HL ev. naar DE.
;getallen (hex, dec, en ascii) worden ge‹nterpreteerd, bewerkingen:
;+ - * / ^ AND OR XOR MOD
;en Z80 registers/condities krijgen een code.
;Labels worden in de TABLE gezet als de EDIT-mode aktief is.
;Als een label al voorkwam is het natuurlijk o.k.

;getallen: &HE0 = decimaal 2 bytes
;          &HE1 = hexadecimaal 2 bytes
;          &HE2 = binair 2 bytes

;labels:   &HC0 = label 2 bytes
;registers:0-15, condities:16-23, $:24, logies:25-27   (+128)

TOKEN: DB &HE6    ;AND opcode  ;tokenize editor-regel
TOKENIZE: SCF     ;tokenize operandregel
 PUSH DE
 POP IY
 LD (IY+0),0      ;lengte
 INC DE
 CALL NC,TOKENINS
beg1: LD A,(HL)
 LD (DE),A
 INC HL
 CP " "
 JR Z,beg1
 CP ":"
 JR Z,beg1
 AND A
 RET Z
 JP M,beg1   ;grafiese tekens overslaan.
 CP ";"  ;commentaar
 JP Z,commen
 CP 34   ;quote ""
 JR Z,text  ;er is tekst
 CALL specikar    ;is het een speciaal karakter?
 JR NZ,nee
 LD A,B
 ADD A,A
 LD (DE),A
beg3: INC DE
beg2: INC (IY+0)
 JR beg1

text:
 INC DE
 INC (IY+0)
 LD A,(HL)
 LD (DE),A
 INC HL
 AND A
 RET Z
 CP 34
 JR NZ,text
 JR beg3

nee: DEC HL      ;nu begint er een woord
 PUSH HL         ;op adres HL
 CALL readword   ;lees het woord, len in C, zet in Hoofdletters
 EX (SP),HL
;met POP HL komt het eind van het woord weer in HL
;het woord, dat op HL begint, kan een register, een label of een getal zijn.
;Of een logische bewerking, of een conditie
 LD A,(HL) ;eerste teken.
 CP "0"
 JR C,nogetal
 CP "9"+1
 JR C,getal    ;het is in ieder geval een getal
nogetal:
 PUSH DE
 LD DE,hexlen  ;nu kijken of er een HEX-prefix is.
 CALL chekpf
 JR Z,hexgetal
 LD DE,binlen  ;BIN-prefix
 CALL chekpf
 JR Z,bingetal
 ;HL=begin_woord, C=lengte
;nu kijken of het een register/conditie/logiese bewerking is.
 LD DE,register
 CALL testword
 POP DE
 SET 7,A
 JR Z,wordok
 LD A,C
 DEC A     ;is het maar 1 letter?
 LD A,(HL)
 JR Z,wordok  ;ja, dan geen label.
 CALL zoekl   ;zoek label, voeg nieuw in als we in de edit mode zijn.
;nummer in HL
 LD A,&HC0
enddoub: EX DE,HL
 LD (HL),A
 LD A,(IY+0)
 OR 128
 ADD A,3
 JR C,lintelan
 INC (IY+0)
 INC HL
 LD (HL),E
 INC HL
 INC (IY+0)
 LD A,D
 EX DE,HL
wordok:
 LD (DE),A
 POP HL
 JR beg3
lintelan: LD (HL),0
 EX DE,HL
 POP HL
 RET

getal:    ;op HL begint een getal (decimaal of hex-met post-fix)

;eerst kijken of er een post-fix kan zijn, en zo ja, of die er is.
 PUSH DE  ;DE=adres voor doelstring
 LD DE,hexlen
 CALL chekof
 JR Z,hexgetal
 LD DE,binlen
 CALL chekof
 JR Z,bingetal
;het is een decimaal getal dat op HL begint.
 EX DE,HL
 CALL decinter
 LD A,&HE0
end1: POP DE
 JR enddoub
hexgetal: EX DE,HL
 CALL hexinter    ;zet waarde op DE, in HL
 LD A,&HE1
 JR end1
bingetal: EX DE,HL
 CALL bininter
 LD A,&HE2
 JR end1

TOKENINS:             ;tokenize instructie en evt. voorafgaand label.
;van HL naar DE
tbeg1: LD A,(HL)
 LD (DE),A
 AND A
 RET Z
 CP ";"
 RET Z      ;terug bij commentaar, wordt door andere routine gedaan.
 INC HL
 CP " "
 JR Z,tbeg1
 CP ":"
 JR Z,tbeg1
 AND A
 JP M,tbeg1   ;grafiese tekens overslaan.
 CALL specikar
 JR Z,tbeg1
 DEC HL
;op HL begint een woord.
 PUSH HL
 CALL readword   ;"lees" het woord, tot speciaal symbool (HL)=sp. symb.
 EX (SP),HL      ;HL=begin, (SP)=einde woord
 PUSH DE
 LD DE,instruc
 CALL testword   ;zoek of dit woord in de tabel instruc voorkomt
 POP DE
 JR NZ,islabel
 OR &H80
karkte: LD (DE),A    ;instructie
 INC DE
 INC (IY+0)
nolm: POP HL
 RET          ;als het inderdaad een instructie is.
;het is een label
islabel: LD A,C
 DEC A
 LD A,(HL)
 JR Z,karkte
 BIT 7,(IY+0)  ;128=label gehad
 JR NZ,restcom ;de rest beschouwen als commentaar
 LD (IY+0),&H82
 CALL zoekl    ;zoek label op HL,zet nummer in HL
 EX DE,HL
 LD (HL),E
 INC HL
 LD (HL),D
 INC HL
 EX DE,HL
 POP HL
 JR tbeg1

restcom: POP AF
commen: LD A,1
comlus: LD (DE),A
 AND A
 DEC HL
 RET Z
 INC HL
 INC DE
 INC (IY+0)
 LD A,(HL)
 INC HL
 JR comlus

specikar:
 PUSH HL
 LD HL,kartab+lenkt-1
 LD B,lenkt
nextk1: CP (HL)
 JR Z,fnd
 DEC HL
 DJNZ nextk1
fnd: POP HL
 RET

readword: LD C,0
readw1: CALL head
 CALL specikar
 RET Z
 CP ":"
 RET Z
 AND A          ;grafies teken
 RET M
 RET Z
 CP " "         ;spatie of null
 RET Z          ;als het een spatie of een speciaal karakter is, dan klaar
 INC HL
 INC C
 JR readw1

testword:
 XOR A
testlus: EX AF,AF
 LD A,(DE)   ;zoek woord in tabel op DE, lengte in C, in A komt nummer.
 SUB 1
 RET C
 LD B,C
 PUSH HL
glus: LD A,(DE)
 INC DE
 BIT 7,A
 JR NZ,endwd
 CP (HL)
 INC HL
 JR NZ,notfnd
 DJNZ glus
notfnd: LD A,(DE)     ;einde woord in tabel opzoeken
 INC DE
 RLCA
 JR NC,notfnd
notf1: POP HL
 EX AF,AF
 INC A
 JR testlus
endwd: DJNZ notf1  ;als er meer dan 1 teken rest dan niet gevonden
 SUB (HL)     ;laatste teken vergelijken.
 ADD A,A
 JR NZ,notf1
 POP HL
 EX AF,AF
 CP A
 RET

chekpf: LD A,(DE)
 AND A
 RET NZ
 INC DE
 LD A,(DE)
 INC DE
 PUSH HL
 LD B,A
 CALL hunt
 JR Z,fdpf
 POP HL
 RET
fdpf: INC SP
 INC SP
 RET
chekof: LD A,(DE)
 DEC A
 RET NZ   ;als het geen postfix kan zijn is het een getal
 INC DE
 LD A,(DE)
 LD B,A  ;lengte
 SUB C   ;trek lengte woord vanaf
 NEG     ;draai dat weer om
 RET M
 INC DE
 PUSH HL
 CALL addhl
 CALL hunt
 POP HL
 RET
hexinter:
 LD HL,0
gethtek: LD A,(DE)
 SUB "0"
 RET C
 CP 10
 JR C,getal1
 SUB 7
 CP 10
 RET C
 CP 16
 RET NC
getal1: INC DE
 ADD HL,HL
 ADD HL,HL
 ADD HL,HL
 ADD HL,HL
 OR L
 LD L,A
 JR gethtek
decinter:
 LD HL,0
getdtek: LD A,(DE)
 SUB "0"
 RET C
 CP 10
 RET NC
 INC DE
 PUSH DE
 LD D,H
 LD E,L
 ADD HL,HL
 ADD HL,HL
 ADD HL,DE
 ADD HL,HL
 LD D,0
 LD E,A
 ADD HL,DE
 POP DE
 JR getdtek

bininter: LD HL,0
getbtek: LD A,(DE)
 SUB "0"
 RET C
 SRL A    ;0 of 1
 RET NZ
 ADC HL,HL
 INC DE
 JR getbtek


;--------------------------------------------
DETOK:
 LD HL,tekstbuf
 CALL DETOKINS
DETOKEN:
;Deze routine DECODEERT de tekst op IY naar &HF55E in ascii
dbeg1: LD A,(IY+0)
 INC IY
 LD (HL),A
 AND A
 RET Z
 JP M,detok
 CP 34
 JR Z,dtext
 CP 1
 JP Z,dcommen  ;wat hierna komt is commentaar.
 SRL A
 JR C,dbeg2
 CP 14
 JR NC,dbeg2
 LD DE,kartab-1
 CALL addde
 LD A,(DE)
 LD (HL),A
dbeg2: INC HL
 JR dbeg1

dtext: INC HL
 INC C
 LD A,(IY+0)
 INC IY
 LD (HL),A
 AND A
 RET Z
 CP 34
 JR NZ,dtext
 JR dbeg2

detok:             ;detokenizen kopbytes >=128
 LD DE,dbeg1
 PUSH DE
 ADD A,A
 ADD A,A
 JR C,val
 LD DE,register
 RRCA
 RRCA
 CP 25
 JP C,getword
 LD (HL)," "
 INC HL
 CALL getword
 LD (HL)," "
 INC HL
 RET

getlab1: XOR A
val: LD E,(IY+0)
 LD D,(IY+1)
 INC IY
 INC IY
valtohl: EX DE,HL
 CALL valint
 EX DE,HL
 RET
valint: ADD A,A
 JP NC,getlabel  ;haal label HL naar DE
 JR Z,dectode
 CP 8
 JR Z,hexa

bina: LD A,(binlen)
 AND A
 PUSH AF
 CALL Z,binadd
 LD A,H
 AND A
 CALL NZ,binbyt
 LD A,L
 CALL binbyt
 POP AF
 CALL NZ,binadd
 RET

hexa: LD A,(hexlen)
 AND A
 PUSH AF
 CALL Z,hexadd
 JR Z,nonul
 LD A,H
 AND A
 JR NZ,hignul
 LD A,L
hignul: CP &HA0
 JR C,nonul
nul:
 LD A,"0"
 LD (DE),A
 INC DE
nonul: LD A,H
 AND A
 CALL NZ,hexbyt
 LD A,L
 CALL hexbyt
 POP AF
 CALL NZ,hexadd
 RET

dectode: XOR A
 LD B,16
 LD C,A
deel10: ADD HL,HL
 RL C
 LD A,C
 SUB 10
 JR C,.1
 LD C,A
 INC HL
.1: DJNZ deel10
 LD A,C
 ADD A,"0"
 PUSH AF
 LD A,H
 OR L
 CALL NZ,dectode
 POP AF
 LD (DE),A
 INC DE
 RET


dcommen: LD A,30
 CALL tabula
dcom2: LD (HL),";"
clus: INC HL
 LD A,(IY+0)
 LD (HL),A
 AND A
 RET Z
 INC IY
 JR clus


DETOKINS:       ;detokenize tot en met instructie
;van IY naar HL
 BIT 7,(IY+0)
 INC IY
 LD B,0
 JR Z,nolabel
 CALL getlab1   ;HAAL label
 LD (HL),":"
 INC HL         ;dubbele punt erachter
 LD B,1
nolabel:
 LD A,(IY+0)
 AND A
 RET Z
 DEC A
 JR Z,dcom3
 SUB &H7F     ;ascii teken
 RET C        ;als het er al een was, dan terug
 INC IY
 PUSH AF
 LD A,8
 CALL tabula
 POP AF
 LD DE,instruc
 CALL getword
 LD A,(IY+0)
 AND A
 RET Z
 LD A,14
 JP tabula

dcom3: DEC B
 LD A,8
 INC IY
 CALL Z,tabula
 JR dcom2


binadd: PUSH HL
 LD HL,binlen+1
 JR hbad
hexadd: PUSH HL
 LD HL,hexlen+1 ;maak toevoegsel
hbad: LD C,(HL)
 LD B,0
 INC HL
 LDIR
 POP HL
 RET

getword: LD B,A
 AND A
 JR Z,okf
zlus: LD A,(DE)     ;haal woord uit tabel op DE
 INC DE
 RLCA
 JR NC,zlus
 DJNZ zlus
okf: LD A,(DE)
 BIT 7,A
 RES 7,A
 INC DE
 LD (HL),A
 INC HL
 JR Z,okf
 RET
;*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*

bigvaout: LD BC,0
 LD (opbuf),BC
 LD (opbuf+2),BC
 LD C,32
daalus2: ADD HL,HL
 RL E
 RL D
 PUSH DE
 LD DE,opbuf
 LD B,4
daalus: LD A,(DE)
 ADC A,A
 DAA
 LD (DE),A
 INC DE
 DJNZ daalus
 POP DE
 DEC C
 JR NZ,daalus2

 LD HL,opbuf+3
 LD BC,&H4F0
rldlus: RLD
 CALL prtcijf
 LD A,B
 DEC A
 JR NZ,nolast
 LD C,A
nolast: RLD
 CALL prtcijf
 DEC HL
 DJNZ rldlus
 RET
prtcijf: AND 15
 JR Z,isnul
 LD C,0
isnul: ADD A,"0"
 ADD A,C
 JP chrout

getfilwc: LD C,9
 JR gtflnm
getfilnm: LD C,11
gtflnm:
 LD A,(HL)
 CP 34
 LD B,20
 JP NZ,error  ;"Filenaam mist"
 INC HL
 LD DE,filebuf
 JR filesyn+2
filesyn: LD C,11 ;zet de filenaam op HL tot aan " of 0 naar DE in de goede vorm.
 PUSH DE
 INC HL
 LD A,(HL)
 CP ":"
 DEC HL
 LD A,(IX+defdrive)  ;default 1=A, 2=B, 3=C
 JR NZ,nodrive
 LD A,(HL)
 AND &H1F
 INC HL
 INC HL
nodrive: LD (DE),A  ;drive
 CP (IX+drives)     ;aantal drives ?
 JP NC,baddrive
 INC DE
 LD B,8
 CALL setname
 LD B,3
 CALL setname
 POP DE
 LD A,(HL)
 CP 34
 JR NZ,clearfcb
 INC HL
 LD A,(HL)
 CP 2   ;komma
 JR NZ,clearfcb
 INC HL
clearfcb: PUSH HL
 LD HL,12
 ADD HL,DE
 LD B,24
filus: LD (HL),0
 INC HL
 DJNZ filus
 POP HL
 RET
setname: LD A,(HL)
 AND A
 JR Z,endname
 CP 34
 JR Z,endname
 INC HL
 CP "."
 JR Z,endname
 CALL cpchar
 CP "*"
 JR Z,endnfill
 LD (DE),A
 INC DE
 DJNZ setname
point?: LD A,(HL)
 CP "."
 RET NZ
 INC HL
 RET
endname: LD A," "
 JR fillfcb
endnfill:
 LD A,"?"
fillfcb: LD (DE),A  ;vullen tot einde
 INC DE
 DJNZ fillfcb
 JR point?
cpchar: PUSH HL   ;kijk of in de filenaam geen foute tekens voorkomen.
 PUSH BC
 LD B,0
 LD HL,chartabl
 CPIR            ;C=11: geen wildcards, C=9 mag wel
 POP BC
 POP HL
 JP Z,badfile     ;bad file name error
 RET

chartabl: DM "[]+=\;:,/?*"

;-----------------
hunt: LD A,(DE)
 CP (HL)
 RET NZ
 INC HL
 INC DE
 DJNZ hunt
 RET
lhunt: LD A,(DE)
 AND &H7F
 LD C,(HL)
 RES 7,C
 CP C
 RET NZ
 INC HL
 INC DE
 DJNZ lhunt
 RET

swap: LD C,(HL)
 LD A,(DE)
 LD (HL),A
 LD A,C
 LD (DE),A
 INC HL
 INC DE
 DJNZ swap
 RET

head: LD A,(HL)
head1: CP "a"
 RET C
 CP "z"+1
 RET NC
 SUB 32
 LD (HL),A
 RET

addde: ADD A,E
 LD E,A
 RET NC
 INC D
 RET
addhl: ADD A,L
 LD L,A
 RET NC
 INC H
 RET

tabula: ADD A,&H5E+18
tab1: LD (HL)," "
 INC HL
 CP L
 RET C
 RET Z
 JR tab1


decbyt: LD C,A
 XOR A
 LD B,8
slalus: SLA C
 ADC A,A
 DAA
 DJNZ slalus
hexbyt: PUSH AF
 RRCA
 RRCA
 RRCA
 RRCA
 CALL hconv
 POP AF
hconv: AND &HF
 ADD A,"0"
 CP "9"+1
 JR C,hc1
 ADD A,7
hc1: LD (DE),A
 INC DE
 RET

binbyt: LD B,8
 LD C,A
bc1: XOR A
 SLA C
 ADC A,"0"
 LD (DE),A
 INC DE
 DJNZ bc1
 RET

symbol:
 BIT graph,(IX+setflag)
 JR NZ,grp
 AND &H7F
grp: CP " "
 JR C,punt
 CP &H7F
 RET NZ
punt: LD A,"."
 RET


kartab: DB "," ;einde reken-uitdrukking
 DB ")"        ;idem
 DB "("
 DB "+"
 DB "-"
 DB "*"
 DB "/"
 DB "^"

lenkt: EQU lenkt-kartab

register: DB "A"+128,"B"+128,"C"+128,"D"+128,"E"+128,"H"+128,"L"+128
 DB "I"+128,"R"+128
 DB "B","C"+128,"D","E"+128,"H","L"+128,"S","P"+128,"I","X"+128,"I","Y"+128
 DB "A","F"+128

condic: DB "N","Z"+128,"Z"+128,"N","C"+128,"C"+128,"P","O"+128,"P","E"+128
 DB "P"+128,"M"+128
 DB "$"+128
logiins: DB "A","N","D"+128,"X","O","R"+128,"O","R"+128,"M","O","D"+128,0

hexlen: DB 0    ;hex-fix voor=0, achter=1
 DM 2+"&H"+0
binlen: DB 0    ;bin-fix
 DM 2+"&B"+0

instruc: DM "LÄJÒDJNÚCALÌREÔJÐINÃDEÃPUSÈPOÐRSÔIÎOUÔIÍEØADÄADÃSUÂSBÃANÄXOÒ"
 DM "OÒCÐRLÃRRÃRÌRÒSLÁSRÁ??¿SRÌBIÔREÓSEÔCPÄCPDÒCPÉCPIÒINÄINDÒINÉ"
 DM "INIÒLDÄLDDÒLDÉLDIÒOUTÄOTDÒOUTÉOTIÒNEÇRETÉRETÎRLÄRRÄCCÆCPÌDAÁ"
 DM "DÉEÉEXØHALÔNOÐRLÁRLCÁRRÁRRCÁSCÆORÇEQÕENÄDÂD×DÓDÍ"
 DM "DEFÂDEF×DEFÓDEFÍGLOBAÌINCLUDÅ"+0
 DS 13
;DEFM is hetzelfde als DEFB en er zijn ook DB,DW,DS,DM's
;------------------------------------------------------------------------

prtitle: CALL print$
 DM 12+"WB-ASS2 Assembler/Monitor"
 DM 13+"Copyright (c) 1988 by W.B.Software"
 DB 13
 DM 13+"Door Wilbert Berendsen"+13
 DB 0
 RET
starta: PUSH HL
 LD HL,&HFD89
 LD DE,asmname
 LD B,10
 CALL hunt
 POP HL
 SCF
 RET NZ
 JR sta
MEMINIT: LD IX,variab   ;hier moet de monitor het eerst worden aangeroepen.
 CALL getcom            ;haal slotselect op
 CALL printoff
 CALL prtitle           ;print titel
;tekstbuffer nog wissen
 CALL killtext
sta: LD IX,variab
 CALL initprog          ;zet enkele routines in page 3.
 LD A,(&HFCAF)
 AND A
 CALL NZ,&H6C
 LD A,(&HF3B0)
 CP 38
 JR NC,widok
 LD A,38
 LD (&HF3B0),A
 LD (&HF3AE),A
widok: LD (IX+width),A
 LD (stack),SP
 JP tofiles
EXIT: LD IX,&H409B      ;zet page 2 eventueel weer in RAM-uibreiding
 LD SP,(stack)
 JP &H159

outchr: BIT 0,(IX+prt)
 JP Z,chput
 JP lptout

outlin: PUSH HL
 CALL bufout
 POP HL
linefeed: PUSH AF
 LD A,&B11111000                      ;13 XOR &HF5
 DB &HEE      ;opcode XOR n, draait &B11111000 om naar 13
chrout:
 PUSH AF
nchp: CALL outchr
 CP 13
 LD A,10
 JR Z,nchp
 POP AF
 RET

bufout: LD HL,tekstbuf
strout: LD A,(HL)      ;string output
 INC HL
 AND A
 RET Z
 INC A                 ;255+adres is: naar andere string
 JR Z,otherstr
 DEC A
 CALL chrout
 JR strout
otherstr: LD A,(HL)
 INC HL
 PUSH HL
 LD H,(HL)
 LD L,A
 CALL strout
 POP HL
 INC HL
 JR strout

print$: EX (SP),HL       ;print tekst van terugsprongadres
 CALL strout
 EX (SP),HL
 RET

spcout: LD A," "
string$: CALL chrout
 DJNZ string$
 RET

fileout: LD B,8
 CALL dirout1
 LD B,3
 LD A,(HL)
 CP " "
 JR Z,nopunta
 LD A,"."
nopunta: CALL chrout
dirout1: LD A,(HL)
 INC HL
 CALL chrout
 DJNZ dirout1
 RET

nextkol: LD A,(IX+kolommen)
 SUB (IX+dirkol)
;in A staat aantal resterende kolommen
 JR Z,nolf
 CP (IX+kolbre)        ;kolom breedte
 RET NC
 CALL linefeed
nolf: LD (IX+dirkol),0
 CALL keywait
 RET

nextkol1: LD A,(IX+dirkol)
 ADD A,(IX+kolbre)       ;kolombreedte
 LD (IX+dirkol),A
 CP (IX+kolommen)
 RET Z
 LD A," "
 CALL chrout
 INC (IX+dirkol)
 RET

printoff: RES 0,(IX+prt)
 LD A,(IX+width)
 LD (IX+kolommen),A    ;schermbreedte
 LD (IX+keyget),20
 RET
printon: CALL lpttst
 JP Z,printerr
 SET 0,(IX+prt)
 LD A,(IX+prtwidth)    ;printerbreedte
 LD (IX+kolommen),A
 LD (IX+keyget),0
 RET

inkey$: CALL key?
 AND A
 RET Z
 CALL csronoff    ;cursor uit.
 CALL chget
 CP 3
 RET NZ
 JP naarmain

keywait:       ;wacht op een toets als er de vorige keer op return gedr. was
 CALL inkey$
kwt1: LD B,1
 CP 13          ;RETURN=1 regel verder
 JR Z,retkey
 DEC B
 CP 31          ;DOWN = steeds door
 JR Z,retkey
 LD B,20
 CP 32          ;SPACE = 22 regels verder
 JR Z,retkey
 LD B,(IX+keyget)
 DEC B
 RET M
 LD (IX+keyget),B
 RET NZ
 CALL getkey
 JR kwt1
retkey: LD (IX+keyget),B
 RET

;de (regel) editor van mijn superluxe assembler

;eerst de toetsenbord routine. (ook voor de monitor)

csronoff: LD A,27
 CALL chput
 LD A,"x"
 ADC A,0
 CALL chput
 LD A,"5"
 JP chput

getk1:
 LD B,&H55
nexttime: RRC B
 CALL csronoff
 LD A,13
 LD (&HFCA2),A
wait: LD A,(&HFCA2)
 DEC A
 JR Z,nexttime
 CALL inkey$
 JR Z,wait
 LD B,A
 LD A,(&HFBEB)
 LD (IX+ctrl),A
 LD A,B
 RET
getkey: CALL getk1
 CP 27
 RET NZ
 BIT 1,(IX+ctrl)
 RET NZ
 CALL getk1
 ADD A,129
 JR C,getkey
 DEC A
 LD B,A
 RET

keytabel: LD C,(HL)
 INC HL
 DEC C
 JP M,klaarkt
 INC C
 CP C
 LD C,(HL)
 INC HL
 LD B,(HL)
 INC HL
 JR NZ,keytabel
 LD HL,(beglin)
 CALL jpbc
 XOR A
 RET
jpbc: PUSH BC
 RET
klaarkt: LD HL,(beglin)
 RET

lintoscr: PUSH HL
 LD H,1
 CALL regelmal
 LD C,(IX+width)
 LD DE,tekstbuf
 DB &H3E
scrlin:       ;zet regel op DE op scherm op HL
;maximale lengte in C, indien korter aanvullen met spaties
 PUSH HL
 LD B,C
 CALL &H53
 LD A,(7)
 LD C,A
lussl: LD A,(DE)
 INC DE
 AND A
 JR Z,endsl
 OUT (C),A
 INC HL
 DJNZ lussl
 POP HL
 RET
endsl: LD A," "
ends1: OUT (C),A
 DJNZ ends1
 POP HL
 RET
scrbuf: EXX
 LD HL,(beglin)
 LD C,(IX+lenlin)
 LD B,0
 LD DE,(schermpo)
 CALL &H5C
 EXX
 RET

clrlin: ;wis schermregel L (bovenste=1)
 PUSH HL
 LD H,1
 CALL regelmal
 LD BC,(&HF3B0)
 LD B,0
 LD A," "
 CALL &H56  ;vul
 POP HL
 RET

ber_end: LD HL,(beglin)
 DEC HL
 LD E,(HL)
 LD D,0
 ADD HL,DE
 DEC E
find1: LD A,(HL)
 CP " "
 RET NZ
 DEC HL
 DEC E
 RET M
 JR find1
findend: CALL ber_end
 INC E
 INC HL
 RET

regelmal: PUSH DE  ;bereken vpoke-pos.
 PUSH BC
 DEC L     ;L=Y
 DEC H     ;H=X
 LD E,H
 LD H,0
 LD D,H
 ADD HL,HL
 ADD HL,HL  ;maal 8
 ADD HL,HL
 LD B,H
 LD C,L
 ADD HL,HL
 ADD HL,HL   ;*32
 LD A,(&HFCAF)
 AND A
 LD A,(&HF3B0)
 JR NZ,screen1
 ADD HL,BC   ;*40
 SUB 41
 JR C,width40
 SUB 40
 ADD HL,HL
width40: DB 1       ;overslaan SUB 33
screen1: SUB 33
 ADD HL,DE         ;X-coordinaat
 DEC A
 CPL
 RRA
 LD E,A
 ADD HL,DE
 LD DE,(&HF922)   ;adres scherm
 ADD HL,DE
 POP BC
 POP DE
 RET


schermpo: DS 2
beglin: DS 2

keytab: DEFKEY 127,del
 DEFKEY 8,bs
 DEFKEY 9,tab
 DEFKEY 24,select
 DEFKEY 18,ins
 DEFKEY 29,csleft
 DEFKEY 28,csright
 DEFKEY 13,return
 DEFKEY 27,return
 DEFKEY 0,0
ctrlkt: DEFKEY "B"-64,ctrlb
 DEFKEY "F"-64,ctrlf
 DEFKEY "E"-64,ctrle
 DEFKEY "U"-64,ctrlu
 DEFKEY "N"-64,ctrln
 DEFKEY "M"-64,return
 DEFKEY "C"-64,return
 DEFKEY 0,0


input: PUSH DE        ;als B=0, dan regel editor en default inhoud buffer
 PUSH HL              ;als B=1, dan terug bij onbekende toetsen en default
 LD C,(HL)
 LD (IX+lenlin),C
 LD (IX+flag),0       ;insm=0, ctrl=0, linsc=0, print=0
 INC HL
 PUSH HL
 LD (beglin),HL
 EX DE,HL
 LD HL,(&HF3DC)
 LD (IX+begx),H
 CALL regelmal
 LD (schermpo),HL
 LD A,B
 AND A
 JR NZ,noscli
 PUSH HL
 PUSH BC
 LD (IX+xpos),A
 SET linsc,(IX+flag)
 CALL scrlin       ;buffer naar scherm
 POP BC
 POP HL
noscli: POP DE
 LD B,0
 CALL &H59
 LD E,(IX+xpos)    ;X-coordinaat
 LD D,0

keylus: LD A,(IX+begx)
 ADD A,E
 LD (&HF3DD),A
 LD A,(IX+flag)
 AND 1
 LD (&HFCAA),A
 CALL getkey
 LD HL,keytab
 BIT 1,(IX+ctrl)
 JR NZ,nocont
 LD HL,ctrlkt
nocont: CALL keytabel
 CALL NZ,andere
 JR keylus
andere: CP 32
 JR NC,karak
 BIT linsc,(IX+flag)
 RET NZ
 JR endedit
return: POP BC   ;van CALL jpbc
 CALL linefeed
endedit: POP BC          ;van CALL keytabel
 LD B,A
 LD (IX+xpos),E
 CALL findend
 LD (HL),0
 POP HL
 LD (HL),E
 LD A,B
 POP DE
 CP 27
 SCF
 RET Z
 CCF
 RET


karak: LD HL,(beglin)
 ADD HL,DE
 BIT insm,(IX+flag)
 CALL NZ,inst
 LD (HL),A
 CALL scrbuf          ;zet buffer op scherm
csright: LD A,E
 INC A
 CP (IX+lenlin)
 RET NC
 LD E,A
 RET

csleft: DEC E
 RET P
 INC E
 RET

ins: LD A,(IX+flag)
 XOR 1
 LD (IX+flag),A
 RET

inst: LD HL,(beglin)
 PUSH AF
 LD C,(IX+lenlin)
 LD B,D
 ADD HL,BC   ;HL op byte n  einde
 LD A,C
 SUB E
 LD B,A
inbl1: DEC HL
 LD A,(HL)
 INC HL
 LD (HL),A
 DEC HL
 DJNZ inbl1
 POP AF
 RET

bs: CALL csleft
del:
 ADD HL,DE
 LD A,(IX+lenlin)
 SUB E
 LD B,A
bl2: INC HL
 LD A,(HL)
 DEC HL
 LD (HL),A
 INC HL
 DJNZ bl2
 DEC HL
 LD (HL)," "
 JP scrbuf

select: CALL getkey
 ADD HL,DE
 LD C,E
nof1: INC C
 LD A,(IX+lenlin)
 CP C
 RET Z
 INC HL
 LD A,(HL)
 CP B
 JR NZ,nof1
 LD E,C
 RET

tab:
 LD B,(IX+lenlin)
 DEC B
no7: LD A,E
 CP B
 RET Z
 INC A
 LD E,A
 AND 7
 JR NZ,no7
 RET

ctrlu: LD E,0
ctrle:
 ADD HL,DE
 LD A,E
wlus: LD (HL)," "
 INC HL
 INC A
 CP (IX+lenlin)
 JR NZ,wlus
 JP scrbuf

ctrln: CALL findend
 LD A,E
 CP (IX+lenlin)
 RET C
 DEC E
 RET

ctrlb: LD A,E
 AND A
 RET Z
 DEC E
 CALL cmpar
 JR C,ctrlb   ;nog geen woord
nspac: CALL cmpar
 INC E
 RET C
 DEC E
 RET Z
 DEC E
 JR nspac

ctrlf: LD B,(IX+lenlin)
 DEC B
cflus: LD A,E
 CP B
 RET Z
 CALL cmpar
 INC E
 JR NC,cflus
 DEC E
nsp1: CALL cmpar
 RET NC
 LD A,E
 CP B
 RET Z
 INC E
 JR nsp1

cmpar: LD HL,(beglin)
 ADD HL,DE
 LD A,(HL)
 CP 48
 RET C
 CP 91
 JR C,cok
 SUB 32
cok: CP 65
 RET NC
 CP 59
 CCF
 RET

;Volledige (full-) screen-editor voor MONITOR!
scrinput:                  ;screen-editor voor Hoofdprogramma
 LD HL,tekstbuf
 LD DE,&HF3DD
 LD A,(DE)
 DEC A
 CALL NZ,linefeed          ;als de cursor niet aan het begin staat linefeed.
 LD A,">"
inplus: CALL &HA2
 LD A,(DE)
 DEC A
 LD (IX+xpos),A
 LD A,(IX+width)
 LD (HL),A
 LD B,1
 LD A,B
 LD (DE),A
 CALL input
 RET C
 CP 13
 JR NZ,inplus
 RET

printadr: BIT 0,(IX+dechex)
 JR Z,printhex
printdec: LD A,&H80
 JR prtval
printhex: LD A,&H84
 JR prtval
printbin: LD A,&H88
prtval: PUSH HL
 PUSH DE
 PUSH BC
 LD DE,filebuf-20
 CALL valint
 XOR A
 LD (DE),A
 LD HL,filebuf-21
 LD (HL)," "
 CALL strout
 POP BC
 POP DE
 POP HL
 RET

inpadr: BIT 0,(IX+dechex)
 JR Z,inphex
inpdec: LD A,&H80
 JR inpd1
inphex: LD A,&H84
inpd1: PUSH BC   ;verander HL
 PUSH DE
 PUSH HL
 PUSH AF
 LD A,(IX+width)
 LD BC,(&HF3DD)
 SUB C
 LD DE,tekstbuf
 LD (DE),A
 POP AF
 PUSH DE
 INC DE
 CALL valint
 XOR A
 LD (DE),A
 LD B,A
 POP HL
 CALL input
 LD DE,buffer1
 INC HL
 CALL TOKENIZE  ;tokenize operand
 LD HL,buffer1+1
 POP DE
 CALL evalua
 EX DE,HL
 POP DE
 POP BC
 RET

decorhex: LD A,&HE1
 SUB (IX+dechex)
 RET

tokadr: CALL decorhex
 ;waarde in DE, adres in HL
 ADD A,A
 ADD A,A
 CALL valtohl
 RET

space?: PUSH AF
 LD HL,(diskbuf)
 ADD HL,DE
 LD DE,(eindtxt)
 RST &H20
 JP C,memvol
 LD (diskbuf),HL
 POP AF
 RET

system: PUSH HL
 PUSH DE
 PUSH BC
 PUSH IX
 PUSH IY
 CALL msxdos
 POP IY
 POP IX
 POP BC
 POP DE
 POP HL
 RET

closeall: LD DE,filebuf ;file sluiten als hij nog open is.
 CALL clsf
 LD DE,filebuf1
 CALL clsf
 LD DE,filebuf2
clsf: PUSH DE
 POP IY
 LD A,(IY+39)
 AND A
 RET Z
closef:
 PUSH DE
 POP IY
 LD A,(IY+40)   ;0=SAVE
 AND A
 JR NZ,nsave1   ;niet saven laatste blok als het een lees-file was.
 PUSH DE
 LD E,(IY+38)
 LD D,(IY+39)
 LD C,&H1A
 CALL system
 LD A,(IY+37)
 AND A
 LD C,&H15
 POP DE
 CALL NZ,system
nsave1: LD HL,(diskbuf)
 LD BC,128
 ADD HL,BC
 LD (diskbuf),HL  ;buffer verwijderen.
close: LD C,&H10
 CALL system   ;sluiten
 LD (IY+39),0
 RET
closefb1: LD DE,filebuf
closeasc: LD A,26
 CALL bretek
 JR closef


openf: PUSH BC
 LD BC,&H80F
 LD A,&H7F
 JR .ocr
creafil: PUSH BC
 LD BC,&H716
 XOR A
.ocr: PUSH DE
 POP IY
 EXX
 LD DE,-128
 CALL space?
 LD (IY+37),A
 LD (IY+38),L
 LD (IY+39),H
 LD (IY+40),A   ;0=save,>0=load
 EXX
 CALL system
 AND A
 JP NZ,error
 POP BC
 RET

brereg: PUSH HL
 LD HL,tekstbuf
 CALL brereg1
 POP HL
 RET
brereg1: LD A,(HL)
 INC HL
 AND A
 JR Z,eol
 CALL bretek
 JR brereg1
eol: LD A,13
 CALL bretek
 LD A,10
bretek: PUSH BC
 PUSH HL
 PUSH DE
 PUSH DE
 POP IY
 LD H,0
 LD L,(IY+37)
 LD E,(IY+38)
 LD D,(IY+39)
 ADD HL,DE
 LD (HL),A
 INC (IY+37)
 JP P,okbretek
 LD C,&H1A
 CALL system
 LD C,&H15
 POP DE
 CALL system
 AND A
 LD B,4
 JP NZ,error
 LD (IY+37),0
 DB &H26
okbretek: POP DE
 POP HL
 POP BC
 RET

gettek: PUSH BC
 PUSH HL
 PUSH DE
 PUSH DE
 POP IY
 INC (IY+37)
 JP P,okgettek
 LD C,&H1A
 LD E,(IY+38)
 LD D,(IY+39)
 CALL system ;set DMA
 POP DE
 LD C,&H14   ;nieuw blok binnenhalen.
 CALL system
 LD B,7
 AND A
 JP NZ,error
 LD (IY+37),0
 PUSH DE
okgettek: LD E,(IY+38)
 LD D,(IY+39)
 LD L,(IY+37)
 LD H,0
 ADD HL,DE
 LD A,(HL)
 POP DE
 POP HL
 POP BC
 RET

iload: CALL getfilnm
 CALL openf
 CALL gettek
 CP 254
 LD B,9
 JP NC,error
 CP 253
 JR NZ,loadasc
 CALL closef
 LD DE,(beginbuf)
 LD C,&H1A
 CALL system
 LD A,(IY+18)
 OR (IY+19)
 JP NZ,memvol
 LD L,(IY+16)
 LD H,(IY+17) ;filegrootte
 PUSH HL      ;lengte
 ADD HL,DE    ;tel op bij beginbuffer
 JP C,memvol
 LD DE,(diskbuf)  ;groter/gelijk eindbuffer?
 RST &H20
 JP NC,memvol   ;ja, dan geheugen vol
 LD DE,filebuf
 CALL clearfcb
 LD C,&HF
 CALL system
 CALL killtext
 LD (IY+14),1 ;recordlengte
 LD (IY+15),0
 LD C,&H27
 POP HL   ;lengte
 CALL system  ;listing inladen
endload: CALL close
 CALL bepaant
 RET

loadasc: CALL killtext
 JR loada

imerge: CALL getfilnm
 CALL openf
 CALL gettek
 CP 253
 LD B,9
 JP NC,error ;"Bad file mode"
loada: SET 2,(IX+mode)
 LD HL,tekstbuf
 JR tekhad
getreg:
 LD HL,tekstbuf
getreg1:
 CALL gettek
tekhad: CP 26
 JP Z,closef
 INC L
 JR NZ,nottool
 DEC L   ;voorkom te lange regels
nottool: LD (HL),A
 SUB &HD
 JR NZ,getreg1
 LD (HL),A
 CALL gettek   ;pass linefeed
 PUSH DE
 LD DE,(aantal)
 INC DE
 CALL invlin
 POP DE
 JR getreg

isave: CALL getfilnm
 LD A,(IX+optie)
 CP "A"
 JR Z,saveasc
 CP "B"
 JR Z,saveblok
 LD HL,filebuf+16
 BIT backup,(IX+setflag)
 JR Z,nobak
 EX DE,HL
 PUSH DE
 LD BC,9
 LDIR
 LD HL,tbak
 LD C,3
 LDIR
 POP DE
 LD C,&H13
 CALL system   ;wis de BAK file
 LD DE,filebuf
 LD C,&H17
 CALL system   ;voer een rename uit.
nobak:
 CALL clearfcb  ;maak FCB schoon
 LD C,&H16
 CALL system   ;create file
 LD DE,(beginbuf)
 LD C,&H1A
 CALL system
 LD HL,1
 LD (filebuf+14),HL
 LD HL,(eindtxt)
 AND A
 SBC HL,DE
 LD DE,filebuf
 LD C,&H26
 CALL system ;schrijf dat blok weg.
 PUSH AF
 LD C,&H10
 CALL system ;en sluit
 POP BC
 OR B
 LD B,4
 JP NZ,error
 RET

saveasc:
 LD DE,(beginbuf)
 LD HL,(beglabel)
 INC DE
 DEC HL
 JR savea1
saveblok: CALL getblk
 ADD HL,DE
savea1: LD (lastadr),DE
 LD DE,filebuf
 CALL creafil
savelus:
 LD DE,(lastadr)
 RST &H20
 JP Z,closefb1   ;file sluiten.
 CALL getasc     ;haal de regel op naar tekstbuf
 LD DE,filebuf   ;breng de regel naar disk
 CALL brereg
 JR savelus

fileadr: CALL getfilnm ;haal filenaam
 CALL openf    ;file openen
 CALL gettek
 CP &HFE
 LD B,9
 JP NZ,error
 PUSH DE       ;FCB
 LD DE,0
 CALL evalua   ;haal een 16 bit waarde op.
 LD B,D        ;=verschuiving in BC
 LD C,E
 POP DE
 PUSH DE         ;FCB
 CALL gethladr   ;beginadres
 PUSH HL         ;beginadres
 CALL gethladr   ;eindadres
 POP DE          ;begin
 AND A
 SBC HL,DE       ;lengte..
 EX (SP),HL      ;naar (SP), FCB in HL
 EX DE,HL        ;DE=adres FCB
 PUSH HL         ;HL= begin
 CALL gethladr
 LD (calladr),HL    ;machinetaal aanroep
 POP HL
 POP BC
 RET

gethladr: CALL gettek
 LD L,A
 CALL gettek
 LD H,A
 ADD HL,BC
 RET

iaddr: CALL fileadr
 CALL print$
 DM "Beginadres:"+0
 CALL printadr
 CALL print$
 DM 13+"Eindadres:"+0
 ADD HL,BC
 CALL printadr
 CALL print$
 DM 13+"Startadres:"+0
 LD HL,(calladr)
 CALL printadr
 CALL linefeed
 CALL closef
 RET

ibload: CALL fileadr ;haal adressen file op.
 JR loadml           ;begin in HL
                     ;lengte in BC
                     ;DE=adres FCB
idload: CALL getfilnm ;haal filenaam op
 CALL openf          ;openen
 PUSH DE             ;FCB bewaren
 CALL getadr         ;haal beginadres op
 PUSH DE
 LD (calladr),DE
 CALL evalua         ;haal eventueel eindadres op
 EX DE,HL
 POP DE
 JR NC,endfnd
 LD HL,(filebuf+16)  ;filegrootte
 ADD HL,DE
 CALL print$
 DM "Laad tot adres: "+0
 DEC HL
 CALL inpadr
endfnd: AND A         ;eindadres in HL
 SBC HL,DE
 LD B,10
 JP C,error
 PUSH DE       ;begin
 EX DE,HL
 LD HL,(filebuf+16)  ;file grootte
 DEC HL
 RST &H20
 JR NC,lengthok
 EX DE,HL
lengthok: LD B,D     ;lengte in BC
 LD C,E
 POP HL
 POP DE       ;adres filebuf
loadml: INC BC
loadlu: CALL gettek
 CALL brebyte
 INC HL
 DEC BC
 LD A,B
 OR C
 JR NZ,loadlu
 DEC HL
 CALL print$
 DM "Geladen tot:"+0
 CALL printadr
 CALL closef
 LD A,(IX+optie)
 CP "R"
 RET NZ
 JP callml     ;runnen!!!!!!!

ibsave: CALL getfilnm ;haal filenaam op
 PUSH DE
 CALL getmem1 ;haal adressen op
;begin in HL, lengte+1 in BC, eventueel startaddr in DE
 JR NC,stfn
 LD D,H
 LD E,L ;geen startadres vermeld
stfn: POP IY
 CALL makebsav    ;maakt een bsave-header in file IY, begin HL lengte BC, st DE
 JR saveml
idsave: CALL getfilnm
 PUSH DE
 CALL getmem1
 POP DE
 CALL creafil
saveml: CALL getbyte
 CALL bretek
 INC HL
 DEC BC
 LD A,B
 OR C
 JR NZ,saveml
 CALL closef
 RET

makebsav: PUSH HL
 PUSH DE
 PUSH IY
 POP DE
 CALL creafil   ;maak file aan
 LD A,&HFE
 CALL bretek
 CALL brehladr  ;breng startadres ernaar toe
 ADD HL,BC
 DEC HL
 CALL brehladr  ;eindadres
 POP HL
 CALL brehladr  ;executieadres
 POP HL
 RET

brehladr: LD A,L
 CALL bretek
 LD A,H
 JP bretek

itype: CALL getfilnm  ;toon ascii files
 CALL openf
teklus: CALL gettek
 CP &H1A
 JP Z,closef
 CALL outchr
 CP 10
 CALL Z,keywait
 JR teklus

secb:
 CALL getdat    ;drivenummer: 0=A,1=B
 INC A
 CP (IX+drives)
 JP NC,baddrive
 PUSH DE
 CALL getadr    ;sector nummer
 PUSH DE
 CALL getdat    ;aantal sectoren.
 AND A
 JP Z,overf
 LD (IX+lenlin),A
 CALL getadr    ;adres in geheugen
 PUSH DE
 LD DE,-512
 CALL space?
 EX DE,HL
 LD C,&H1A
 CALL system
 POP BC     ;adres waar de sector naar toe moet
 POP DE     ;sector nummer
 POP HL     ;drive nummer
 LD H,1
 RET

iget: CALL secb
 PUSH BC
seclus: LD BC,&H72F
 CALL system
 AND A
 JP NZ,error
 EX (SP),HL  ;HL=geheugenadres
 PUSH DE
 LD DE,(diskbuf)
 LD BC,2
sectomem: LD A,(DE)
 INC DE
 CALL brebyte
 INC HL
 DJNZ sectomem
 DEC C
 JR NZ,sectomem
 POP DE
 EX (SP),HL   ;H=1, L=drive nummer
 INC DE       ;volgende sector.
 DEC (IX+lenlin)
 JR NZ,seclus
 POP BC
 RET

iput: CALL secb
 PUSH BC
seclus1: EX (SP),HL
 PUSH DE
 LD DE,(diskbuf)
 LD BC,2
sectodsk: CALL getbyte
 INC HL
 LD (DE),A
 INC DE
 DJNZ sectodsk
 DEC C
 JR NZ,sectodsk
 POP DE
 EX (SP),HL
 LD BC,&H730
 CALL system
 AND A
 JP NZ,error
 INC DE
 DEC (IX+lenlin)
 JR NZ,seclus1
 POP BC
 RET

iedit: JR C,EDIT   ;geen operand.
 LD A,(HL)
 CP 34
 JR NZ,edline
 CALL iload   ;laad ander bestand in.
 JR EDIT
edline: CALL getadr   ;operand moet een regelnummer zijn.
 LD HL,(aantal)
 RST &H20
 JR C,filinib
 EX DE,HL
filinib: LD A,H
 OR L
 JR NZ,edok1
 INC HL
edok1: LD (IX+lin),1
 LD (filin),HL
EDIT:
 LD (IX+mode),&B101 ;cursor op 23 y en geen error bij nd. labels
 LD (IX+xpos),0
 CALL printoff
 LD A,12
 CALL chrout   ;CLS
edit0: CALL bepaant  ;bepaal aantal regels.
edit1: CALL prscr
 LD SP,(stack)
edit2: LD HL,&H117 ;6,23
 LD (&HF3DC),HL    ;locate
 CALL print$
 DM ">EDIT"+0
 LD HL,(filin)
 LD E,(IX+lin)
 LD D,0
 ADD HL,DE
 DEC HL
 CALL printdec     ;print daar het regelnummer
 LD B,4
 CALL spcout       ;en 4 spaties
 INC D
 LD (&HF3DC),DE
 EX DE,HL          ;regelnummer in DE
 LD HL,tekstbuf
 LD A,(IX+width)
 LD (HL),A
 LD B,1
 CALL input
            ;DE=regelnummer
 LD HL,scrinkey
 BIT 1,(IX+ctrl)
 JR NZ,nocont1
 LD HL,scrinkct
nocont1: CALL keytabel
 JR edit2

invoer: CALL invlin
 LD (IX+xpos),0
down:
 LD A,(IX+lin)
 INC A
 CP 23
 JR NZ,okdwn
 LD HL,(filin)
 INC HL
okup: LD A,L
 OR H
 RET Z
ed1: LD (filin),HL
 JP edit1
okdwn: LD (IX+lin),A
 RET

up: DEC (IX+lin)
 RET NZ
 INC (IX+lin)
 LD HL,(filin)
 DEC HL
 JR okup

home: DEC DE
 LD A,D
 OR E
 LD HL,1
 LD (IX+lin),L
 JR NZ,ed1
 LD (IX+lin),22
 LD HL,(aantal)
 INC HL
 JR scrup1

scrup: LD HL,(filin)
scrup1: LD DE,23
 AND A
 SBC HL,DE
 INC HL
 JR NC,ed1
 LD HL,1
 JR ed1

scrdown: LD HL,(filin)
 LD DE,21
 ADD HL,DE
 LD DE,(aantal)
 RST &H20
 RET NC
 INC HL
 JR ed1

mbegin: LD A,"<"
 DB 1
meinde: LD A,">"+128
 PUSH DE
 PUSH AF
 CALL finlin
 POP BC
 POP DE
 RET C
 PUSH DE
 PUSH BC
 BIT 7,B
 JR Z,nomeind
 LD C,(HL)
 INC C
 RES 7,C
 LD B,0
 ADD HL,BC
nomeind: LD D,H
 LD E,L
 INC DE
 INC DE
 PUSH HL
 CALL INSERT
 LD HL,(aantal)
 INC HL
 LD (aantal),HL
 POP HL
 POP AF
 PUSH AF
 LD (HL),1
 INC HL
 AND &H7F
 LD (HL),A
 CALL prscr
 POP AF
 POP DE
 AND A
 RET M
 JP down

delline: CALL finlin
 CALL NC,dellin
 JP edit1
insline: CALL finlin
 CALL NC,inslin
 JP edit1

clrblok: CALL clrblk
 JP edit1
wisblk: CALL getblk
 ADD HL,DE
 EX DE,HL
;DE=eind, HL=begin
 CALL DELETE
 JP edit0
verpblk: CALL chekdoel
;verplaats van HL met lengte BC naar DE
 CALL MOVE
 JP edit1
copyblk: CALL chekdoel
 CALL COPY
 JP edit0

printblk: CALL getblk
 ADD HL,DE ;HL=eind
 INC DE
 INC DE
 DEC HL
 DEC HL
 LD (lastadr),DE
 CALL printon
plus1: LD DE,(lastadr)
 RST &H20
 JP Z,printoff
 CALL getasc
 CALL outlin
 JR plus1

scrinkey: DEFKEY 13,invoer
 DEFKEY 31,down
 DEFKEY 30,up
 DEFKEY 11,home
 DB 0
scrinkct: DEFKEY 13,invoer
 DEFKEY 31,scrdown
 DEFKEY 30,scrup
 DEFKEY "A"-64,mbegin
 DEFKEY "Z"-64,meinde
 DEFKEY "I"-64,insline
 DEFKEY "D"-64,delline
 DEFKEY "P"-64,printblk
 DEFKEY "K"-64,copyblk
 DEFKEY "V"-64,verpblk
 DEFKEY "W"-64,wisblk
 DEFKEY "T"-64,clrblok ;wis markers.
 DB 0
ipoke: CALL getadr
 PUSH DE
 LD A,(IX+optie)
 CP "D"
 JR Z,dpoke
 CALL getdat
 LD A,(IX+optie)
 CP "V"
 LD A,E
 POP HL
 JP Z,vpoke
breb.: JP brebyte
dpoke: CALL getadr
 POP HL
 LD A,E
 CALL brebyte
 LD A,D
 INC HL
 JR breb.

iout: CALL getadr
 PUSH DE
 CALL getdat
 POP BC
 OUT (C),A
 RET

ipeek: CALL getadr
 EX DE,HL
 LD A,(IX+optie)
 CP "V"
 JR Z,vpk
 LD B,A
 CALL getbyte
 LD E,A
 LD A,B
 CP "D"
 JR NZ,pkend
 INC HL
 CALL getbyte
 LD D,A
 JR conversi
vpk: CALL vpeek
prtsin: LD E,A
pkend: LD D,0
 JR conversi

iin: CALL getadr
 LD C,E
 IN E,(C)
 JR pkend

i?: CALL getadr
conversi: EX DE,HL
 LD A,"="
 CALL chrout
 LD A,L
 CALL symbol    ;<32 en 7FH weg laten
 CALL chrout    ;en zet op scherm
 CALL printhex
 CALL printdec
 CALL printbin
 CALL linefeed
 RET

ifill: CALL getmembk
 LD A,(IX+optie)
 CP "V"
 LD A,E
 JP Z,fillvram
pkelus: LD A,E
 CALL brebyte
 INC HL
 DEC BC
 LD A,B
 OR C
 JR NZ,pkelus
 RET

icompare: CALL getmembk   ;vergelijken 2 geheugenblokken.
complus: PUSH BC
 CALL getbyte
 LD C,A
 EX DE,HL
 CALL getbyte
 EX DE,HL
 CP C            ;vergelijk de beide bytes.
 POP BC
 JR NZ,differ
 INC HL
 INC DE
 DEC BC
 LD A,B
 OR C
 JR NZ,complus
 RET
differ: CALL print$
 DM "Verschil op:"+0
 CALL printadr
 CALL linefeed
 RET

imove: LD A,(IX+optie)
 PUSH HL
 LD HL,vpeek
 LD DE,brebyte
 CP "M"
 JR Z,moveprog
 LD HL,getbyte
 CP "V"
 JR NZ,moveprog
 LD DE,vpoke
moveprog: LD (haalbyt+1),HL
 LD (brengbt+2),DE
 POP HL
 CALL getmembk
 RST &H20
 JR C,naardown
mvls: CALL haalbyt
 CALL brengbt
 INC HL
 INC DE
 DEC BC
 LD A,B
 OR C
 JR NZ,mvls
 RET
naardown: DEC BC
 ADD HL,BC
 EX DE,HL
 ADD HL,BC
 EX DE,HL
 INC BC
mvls1: CALL haalbyt
 CALL brengbt
 DEC HL
 DEC DE
 DEC BC
 LD A,B
 OR C
 JR NZ,mvls1
 RET
haalbyt: JP getbyte
brengbt: EX DE,HL
 CALL brebyte
 EX DE,HL
 RET

get4: CALL getsin
 RET C
 CP 4
 CCF
 RET NC
 JP overf

ipage:
 LD A,(IX+optie)
 CP "I"
 JR Z,initpage
 LD A,(HL)
 AND A
 JR Z,toonpage
 CALL get4    ;pagenummer
 JP C,misoper
 LD IY,pt
 ADD IY,DE
 ADD IY,DE
 LD A,(IY+0)
 AND 3       ;slotnummer
 LD E,A
 CALL get4   ;slotnummer
 ;als er geen nieuw slotnummer wordt gegeven, oude houden.
 PUSH HL
 LD HL,exptbl
 ADD HL,DE
 OR (HL)
 POP HL
 LD B,A
 LD A,(IY+0)
 RRCA
 RRCA
 AND 3
 LD E,A
 CALL get4
 ADD A,A
 ADD A,A
 OR B
 PUSH AF
 LD A,(IX+ab)
 AND A
 JR Z,nomemmp
 LD B,A
 CALL getsin
 JR C,nomemmp
 DEC B
 AND B
 LD (IY+1),A
nomemmp:
 POP AF
 LD (IY+0),A
 JR endpg

initpage: CALL getcom
endpg: JP COPYSEL
toonpage: CALL print$
 DM "Page Slot"+0
 LD A,(IX+ab)
 AND A
 JR Z,nonm2
 CALL print$
 DM " Mem"+0
nonm2: CALL linefeed
 LD DE,pt
 LD C,0
ptolus: LD HL,tekstbuf
 LD (HL)," "
 INC HL
 LD A,C
 ADD A,"0"
 LD (HL),A
 INC HL
 LD A,6
 CALL tabula
 LD A,(DE)
 AND 3
 ADD A,"0"
 LD (HL),A
 INC HL
 LD A,(DE)
 AND A
 JP P,noexpto
 LD (HL),"-"
 INC HL
 RRCA
 RRCA
 AND 3
 ADD A,"0"
 LD (HL),A
 INC HL
noexpto: LD A,10
 CALL tabula
 XOR A
 LD (HL),A
 CALL bufout
 INC DE
 LD A,(DE)
 INC DE
 LD L,A
 LD H,0
 LD A,(IX+ab)
 AND A
 CALL NZ,printdec
 CALL linefeed
 INC C
 BIT 2,C
 JR Z,ptolus
 RET

igo: CALL getadr
 LD (calladr),DE
callml: DI
 LD SP,regbuf
 POP BC
 POP DE
 POP HL
 POP AF
 EXX
 EX AF,AF
 POP BC
 POP DE
 POP HL
 POP AF
 POP IX
 POP IY
 EXX
 EX AF,AF
 LD SP,(stack)
 CALL goto        ;in page 3
 DI
 LD SP,regbuf+20
 EX AF,AF
 EXX
 PUSH IY
 PUSH IX
 PUSH AF
 PUSH HL
 PUSH DE
 PUSH BC
 EX AF,AF
 EXX
 PUSH AF
 PUSH HL
 PUSH DE
 PUSH BC
 LD IX,variab
 LD SP,(stack)
 EI
 JP MAIN

regget: LD DE,regbuf
 LD HL,regbuf1
 JR reg.1
regstore: LD HL,regbuf
 LD DE,regbuf1
reg.1: LD BC,20
 LDIR
 RET
regexx: LD B,8
 LD HL,regbuf
 LD DE,regbuf+8
 JP swap

ireg: LD A,(IX+optie)
 CP "S"
 JR Z,regstore
 CP "G"
 JR Z,regget
 CP "X"
 JR Z,regexx
 LD A,(HL)
 AND A
 JR Z,toonreg
 INC HL
 LD DE,regbuf+6
 CP "F"  ;flags
 JR Z,devlag
 SUB &H80
 JP C,operr
 CP 16
 JP NC,operr
 LD DE,stack
 SUB 12         ;12=SP
 JR Z,regfnd
 LD DE,regbuf+16
 DEC A          ;13=IX
 JR Z,regfnd
 INC DE
 INC DE
 DEC A          ;14=IY
 JR Z,regfnd
 LD DE,regbuf+6
 DEC A          ;15=AF
 JR Z,regfnd
 ADD A,15-9     ;BC=0, DE=1, HL=2
 JP M,sinregi
 LD DE,regbuf
 ADD A,A
 CALL addde
regfnd:
 PUSH DE
 EX DE,HL
 LD A,(HL)
 INC HL
 LD H,(HL)
 LD L,A
 EX DE,HL
 CALL bepaval
 POP HL
 LD (HL),E
 INC HL
 LD (HL),D
 RET

sinregi: ADD A,9   ;registers, C,B,E,D,L,H,F,A
 CP 7
 JP NC,operr
 DEC A
 AND 7
 CP 6
 JR NC,noxor1
 XOR 1
noxor1: LD DE,regbuf
 CALL addde
devlag: PUSH DE
 LD A,(DE)
 LD E,A
 LD D,0
 CALL bepaval
 POP HL
 CALL twocompl
 JP C,overf
 LD (HL),A
 RET

bepaval: LD A,(HL)
 CP 2
 JR NZ,noinc2
 INC HL
noinc2: CALL evalua
 RET NC
 EX DE,HL
 CALL inpadr
 EX DE,HL
 RET

toonreg: LD A,13+128
 LD DE,regbuf+16  ;IX
 CALL prreg
 INC A
 CALL prreg
 CALL linefeed
 LD B,3
 LD A,128+9
 LD DE,regbuf
prregex: PUSH BC
 CALL prreg
 PUSH DE
 LD HL,6
 ADD HL,DE
 EX DE,HL
 CALL prreg
 CALL linefeed
 INC A
 POP DE
 POP BC
 DJNZ prregex
 LD DE,stack
 CALL prreg       ;SP
 LD A,15+128
 LD DE,regbuf+14  ;AF'
 CALL prreg
 CALL print$
 DM 13+"flags: SZ H PNC"+13+0
 LD B,7
 CALL spcout
 LD A,(regbuf+6) ;F
 LD DE,tekstbuf
 CALL binbyt
 XOR A
 LD (DE),A
 CALL bufout
 CALL print$
 DM 13+"reg.A: "+0
 LD A,(regbuf+7)
 JP prtsin

prreg: LD HL,buffer1
 PUSH AF
 PUSH HL
 LD (HL),A
 INC HL
 LD (HL)," "
 LD A,(DE)
 LD C,A
 INC DE
 LD A,(DE)
 INC DE
 PUSH DE
 LD D,A
 LD E,C
 CALL setgetal
 INC HL
 LD (HL),0
 POP DE
 POP IY
 LD HL,tekstbuf
 PUSH DE
 CALL DETOKEN
 POP DE
 LD A,12
 CALL tabula
 LD (HL),0
 CALL bufout
 POP AF
 RET

iinfo: CALL print$
 DM "Tekstbuffer: van"+0
 LD HL,(beginbuf)
 CALL printadr
 CALL print$
 DM " tot"+0
 LD HL,(eindbuf)
 DEC HL
 CALL printadr
 CALL print$
 DM 13+"Tekst einde:"+0
 LD HL,(eindtxt)
 CALL printadr
 EX DE,HL
 LD HL,(diskbuf)
 AND A
 SBC HL,DE
 CALL print$
 DM 13+"Tekens vrij:"+0
 CALL printdec
 CALL print$
 DM 13+"Aantal regels:"+0
 LD HL,(aantal)
 CALL printdec
 CALL linefeed
 RET

idir: ;de routine DIR
;DIR/W   plaatst de files naast elkaar.
 LD DE,filebuf1
 LD C,&H1A
 CALL system
 LD (IX+dirkol),0  ;cursor kolom
 LD (IX+kolbre),12 ;breedte kolom
 LD (IX+lenlin),0  ;aantal files
 LD A,(HL)
 CP 34
 JR NZ,nofnam
 CALL getfilwc   ;haal filenaam met eventuele wild cards
 JR dirfar
nofnam: PUSH HL
 LD DE,filebuf  ;maak andere velden schoon
 CALL clearfcb
 PUSH DE
 LD A,(IX+defdrive)  ;1=A, 2=B
 LD (DE),A
 LD A,"?"
 LD B,11
vralus: INC DE
 LD (DE),A
 DJNZ vralus
 POP DE
 POP HL
dirfar:
 LD A,(IX+optie)
 CP "W"
 JP Z,dirnext     ;naast elkaar
dirlus3: CALL getnextf
 CALL keywait
 CALL fileout
 LD HL,(filebuf1+29)
 LD DE,(filebuf1+31)
 CALL bigvaout   ;grote waarde op scherm
 LD B,2
 CALL spcout
 LD DE,tekstbuf
 LD HL,(filebuf1+25)  ;datum
 LD A,H
 OR L
 JR Z,unknown
 LD A,L
 AND &B11111
 CALL decbyt   ;dag
 LD A,"/"
 LD (DE),A
 INC DE
 PUSH HL  ;laagste bit H en bovenste 3 bits L: maand
 ADD HL,HL
 ADD HL,HL
 ADD HL,HL
 LD A,H
 AND &HF
 CALL decbyt ;maand
 LD A,"/"
 LD (DE),A
 INC DE
 POP AF
 SRL A
 ADD A,80    ;jaar
 CALL decbyt
unknown: EX DE,HL
 LD A,10
 CALL tabula
 EX DE,HL
 LD HL,(filebuf1+23)  ;tijd
 LD A,H
 OR L
 JR Z,tunknown
 LD A,H
 RRA
 RRA
 RRA
 AND 31
 CALL decbyt  ;uur
 LD A,":"
 LD (DE),A
 INC DE
 ADD HL,HL
 ADD HL,HL
 ADD HL,HL
 LD A,H
 AND &H3F
 CALL decbyt
tunknown: XOR A
 LD (DE),A
 CALL outlin   ;en zet op scherm
 JR dirlus3

dirnext: CALL nextkol    ;volgende kolom
 CALL getnextf           ;volgende file in DMA ,HL op filebuf1
 CALL fileout
 CALL nextkol1
 JR dirnext


getnextf: LD DE,filebuf
 LD A,(IX+lenlin)
 AND A
 LD C,&H11
 JR Z,sfrst
 INC C
sfrst: CALL system
 INC (IX+lenlin)
 AND A
 LD HL,filebuf1+1
 RET Z
 POP AF    ;terugsprong adres
 CALL linefeed
 LD H,0
 LD L,(IX+lenlin)
 DEC L
 CALL printdec  ;aantal files
 CALL print$
 DM " file"+0
 DEC L
 LD A,"s"      ;alleen s als er geen 1 files zijn
 CALL NZ,chrout
 LD DE,(filebuf)
 LD C,&H1B  ;"Get Allocation"
 PUSH IX
 CALL msxdos
 POP IX
             ;nu moet worden gedaan DEHL=A * HL * 512
 DEC A
 JR Z,onlyone
 ADD HL,HL   ;HL=vrije sectoren
onlyone: ADD HL,HL

 LD D,0
 LD E,H
 LD H,L
 LD L,D
 CALL bigvaout
 CALL print$
 DM " tekens vrij"+13+0
 RET

iwidth: CALL getdat
 LD B,0
 CP 38
 JP C,overf
 CP 81
 JP NC,overf
 CP 41
 RL B
 JR NZ,small
 LD A,(msx?)
 AND A
 JP Z,overf
small: LD A,(IX+width)
 CP 41
 RL B   ;1=40 kol
 LD A,E
 LD (IX+width),A
 LD (&HF3B0),A
 LD (&HF3AE),A
 CALL PO,&H6C  ;alleen aanroepen als er van 40 naar 80 of van 80 naar 40 ging.
 LD A,12
 CALL chput
 RET

mon40:
 DB 8         ;aantal hex-kolommen
 DB 30        ;X-coordinaat ascii-kolom
mon80:
 DB 16
 DB 46
monkol: EQU 0
asckol: EQU 1

monreg: PUSH DE
 PUSH HL
 LD DE,(MP)
 RST &H20
 JR C,klaarmon
 EX DE,HL
 CALL monreg1
 LD (MP),HL
 XOR A
klaarmon: POP HL
 POP DE
 RET

monreg1: PUSH BC
 PUSH DE
 LD DE,tekstbuf
 LD A,H
 CALL hexbyt
 LD A,L
 CALL hexbyt
 LD A," "
 LD (DE),A
 XOR A
 LD B,A
monreglu: LD C,A
 CALL getbyte    ;haal byte uit geheugen
 LD E,A
 LD A,C
 PUSH HL
 PUSH AF
 LD HL,tekstbuf+5
 CALL monpl
 ADD HL,BC
 EX DE,HL
 LD A,L
 CALL hexbyt
 LD A," "
 LD (DE),A
 POP AF
 PUSH AF
 LD C,A
 LD A,L
 LD HL,tekstbuf-1
 ADD HL,BC
 LD C,(IY+asckol)
 ADD HL,BC
 CALL symbol
 LD (HL),A
 INC HL
 LD (HL),B
 POP AF
 POP HL
 INC HL
 INC A
 CP (IY+monkol)
 JR NZ,monreglu
 POP DE
 POP BC
 RET

monpl: LD C,A
 ADD A,A
 BIT 4,(IY+monkol)  ;1=80 kol, 0=40 kol
 JR Z,nosrl
 SRL C
nosrl: ADD A,C
 LD C,A
 RET

maal?: ADD A,A
 ADD A,A
 ADD A,A
 BIT 4,(IY+monkol)
 RET Z
 ADD A,A
 RET

getoper: CALL evalua
 RET C
 LD (MP),DE
 RET

diskmon: CALL getfilnm
 PUSH IY
 PUSH DE
 CALL getmem1
 LD (MP),HL
 ADD HL,BC
 DEC HL
 POP DE
 CALL creafil
dskmnlus:
 POP IY
 CALL monreg
 JP C,closeasc
 PUSH IY
 CALL brereg
 JR dskmnlus

prtmon: CALL getmem1
 LD (MP),HL
 ADD HL,BC
 DEC HL
nextlin:
 CALL monreg
 RET C
 CALL outlin
 CALL keywait
 JR nextlin

imon:
 BIT 0,(IX+mon)
 LD IY,mon40
 JR Z,kol40
 LD IY,mon80
kol40:
 LD A,(IX+optie)
 CP "D"
 JR Z,diskmon
 BIT 0,(IX+prt)    ;printer aan?
 JR NZ,prtmon
     ;monitor op scherm
 CALL getoper ;haal eventuele waarde voor MP
 LD A,(IX+width)
 CP 61
 JR NC,okwidth
 LD IY,mon40
okwidth: SET 1,(IX+mode) ;cursor op 17 y
flus2: LD HL,0        ;cursor positie
 RES 1,(IX+mon)  ;in hex-kolom

flus1: LD SP,(stack)
 PUSH HL
 LD HL,&H100
scrmolus: INC L
 CALL monscrl
 BIT 4,L
 JR Z,scrmolus
 POP HL
flus4: RES 2,(IX+mon)
flus:
 PUSH HL
 LD A,L      ;Y (0-15)
 CALL maal?  ;maal 16 of 8
 ADD A,H     ;+X
 LD E,A      ;in DE
 LD D,0
 LD HL,&H111
 LD (&HF3DC),HL
 LD HL,(MP)  ;adres linksboven
 ADD HL,DE
 CALL print$
 DM ">MON"+0
 CALL printadr
 EX DE,HL  ;adres in DE
 LD B,4
 CALL spcout
 POP HL
 PUSH HL
 INC L
 LD A,H
 BIT 1,(IX+mon)  ;1=ascii-kolom, 0=hex kolom
 JR NZ,asciikol
 CALL monpl
 ADD A,6
 LD H,A
 BIT 2,(IX+mon)  ;1=tweede nibble hexgetal
 JR Z,tomon
 INC H
 JR tomon
asciikol: ADD A,(IY+asckol)
 LD H,A
tomon: LD (&HF3DC),HL
 POP HL  ;coordinaten
 LD (beglin),HL
 CALL getkey  ;toets ophalen
 LD HL,monkey
 BIT 1,(IX+ctrl)
 JR NZ,noctrl1
 LD HL,cmonkey
noctrl1: CALL keytabel
 JR Z,flus4
 CALL andere1
 JR flus

andere1: BIT 1,(IX+mon)  ;1=ascii-kolom
 JR Z,noasckol
 EX DE,HL
 CALL brebyte
 EX DE,HL
 INC L
 CALL monscrl
 DEC L
rightmon: INC H     ;volgende teken
 LD A,H
 CP (IY+monkol)
 RET C
 LD H,0
downmon: INC L
 BIT 4,L
 RET Z
 DEC L
 LD E,(IY+monkol)
 LD D,0
adrscr: PUSH HL
 LD HL,(MP)
 ADD HL,DE
 LD (MP),HL
 POP HL
 JP flus1
leftmon: DEC H
 RET P
 LD H,(IY+monkol)
 DEC H
upmon: DEC L
 RET P
 INC L
 LD A,(IY+monkol)
 NEG
 LD E,A
 LD D,255
 JR adrscr

monscup: LD DE,-128
 BIT 4,(IY+monkol)
 JR Z,adrscr
 LD DE,-256
 JR adrscr
monscdow: LD DE,128
 BIT 4,(IY+monkol)
 JR Z,adrscr
 LD DE,256
 JR adrscr

noasckol:   ;er werd een hex-nibble ingetypt
 SUB "0"
 RET C
 CP 10
 JR C,getal2
 AND &HDF
 SUB 7
 CP 10
 RET C
 CP 16
 RET NC
getal2: LD C,&HF0
 BIT 2,(IX+mon)   ;0=eerste nibble
 JR NZ,nofrst
 ADD A,A
 ADD A,A
 ADD A,A
 ADD A,A
 LD C,&HF
nofrst: LD B,A
 EX DE,HL
 CALL getbyte
 AND C
 OR B
 CALL brebyte
 EX DE,HL
 INC L
 CALL monscrl
 DEC L
 LD A,(IX+mon)
 XOR 4
 LD (IX+mon),A
 BIT 2,A
 JP Z,rightmon
 RET

gomon: EX DE,HL
 CALL getbyte
 LD E,A
 INC HL
 CALL getbyte
 LD L,E
 LD H,A
flus11: LD (MP),HL
 JP flus2

offset: EX DE,HL
 CALL getbyte
 LD E,A
 ADD A,A
 SBC A,A
 LD D,A
 INC DE
 ADD HL,DE
 JR flus11

switch: LD A,(IX+mon)
 XOR 2
 LD (IX+mon),A
 RET

monscrl:
 LD A,L
 DEC A
 CALL maal?
 LD E,A
 LD D,0
 PUSH HL
 LD HL,(MP)
 ADD HL,DE
 CALL monreg1
 POP HL
 CALL lintoscr
 RET

monkey:
 DEFKEY 29,leftmon
 DEFKEY 28,rightmon
 DEFKEY 30,upmon
 DEFKEY 31,downmon
 DEFKEY 24,switch
 DB 0
cmonkey:
 DEFKEY 30,monscup
 DEFKEY 31,monscdow
 DEFKEY "O"-64,offset
 DEFKEY "G"-64,gomon
 DB 0
;----
idis:   ;de disassembler
 LD (IX+rstflag),0
 LD A,(IX+optie)
 CP "D"
 JR Z,diskdis
 CALL getoper ;zet MP
 LD DE,-1
 CALL evalua  ;haal eventueel eindadres
 EX DE,HL     ;in HL
dislus1: CALL disreg
 RET C
 CALL outlin
 CALL keywait ;speciale routine om op een toets te wachten
 JR dislus1
diskdis: CALL getfilnm
 PUSH DE
 CALL getmem1
 LD (MP),HL
 ADD HL,BC
 DEC HL
 POP DE
 CALL creafil   ;maak file aan
dislus: CALL disreg
 JP C,closeasc
 CALL brereg
 JR dislus

disreg: PUSH DE
 PUSH HL
 LD DE,(MP)
 RST &H20
 JR C,enddis
 CALL maakadr
 LD HL,buffer1
 PUSH HL
 LD (IX+indflg),0
 CALL beginstr
 INC HL
 LD (HL),0
 CALL mendadr
 POP IY
 LD A,(IY+0)
 LD DE,instruc
 CALL getword
 INC IY
 LD A,(IY+0)
 LD (HL),A
 AND A
 JR Z,enddis
 LD A,6
 CALL tabula
 CALL DETOKEN ;DE-tokenize
 XOR A
enddis: POP HL
 POP DE
 RET
beginstr: LD A,(IX+rstflag)
 DEC A
 JP M,begins1
 JR Z,dbyte
 CP 1
 JR Z,dbyte
 LD (HL),76 ;DEFW
 CALL dgetdou           ;haal adres
 XOR A
 JR beg22
dbyte: LD (IX+rstflag),A
 PUSH AF
 LD (HL),75   ;DEFB
 CALL dgetsin           ;haal byte
 POP AF
 AND A
 RET Z
 LD A,3
beg22: LD (IX+rstflag),A
 RET
begins1: CALL getincad   ;haal byte en verhoog adres
 LD (IX+groep),A
 CP &HCB
 JR Z,bitres     ;CB=bit- en roteer- en schuifinstructies
 CP &HED
 JP Z,anderins   ;andere instructies
 CP &HDD
 JR Z,indexed
 CP &HFD
 JR Z,indexed
 CALL splcode
 AND A
 JR Z,itabel1
 DEC A
 JR Z,loadins
 DEC A
 JR Z,rekenins
 LD DE,ttable1
jptabel: LD A,C
 ADD A,A
 CALL addde
 PUSH HL
 LD A,(DE)
 INC DE
 LD L,A
 LD A,(DE)
 LD H,A
 EX (SP),HL
 LD A,B
 RET
itabel1: LD DE,ttable2
 JR jptabel

bitres: CALL getincad
 BIT 0,(IX+indflg)
 JR Z,.42
 LD (IX+disflg),A  ;afstand
 CALL getincad  ;volgende byte
.42: CALL splcode
 AND A
 JR Z,rotate
 ADD A,30
 LD (HL),A    ;BIT=31, RES=32, SET=33
 INC HL
 LD A,B       ;c2
 ADD A,"0"
 LD (HL),A
 INC HL
 LD (HL),","
endregp: LD A,C
 JP addsinre
rotate: LD A,B
 ADD A,23
 LD (HL),A
 CP 29
 JR NZ,endregp
 RET
indexed: BIT 0,(IX+indflg)  ;was het al indexed?
 JP NZ,diserror
 LD (IX+indflg),A
 JP beginstr
loadins: LD A,(IX+groep)
 CP &H76     ;HALT
 LD (HL),61  ;interne code voor HALT
 RET Z
nohalt: LD (HL),0  ;interne code voor instructie LD
 LD A,B
 CALL addsinre
 INC HL
 LD (HL),","
 LD A,C
 JP addsinre
rekenins: CALL accujn
 LD A,C
 JP addsinre
accujn: LD A,B
 ADD A,15  ;ADD=15, ADC=16 enz.
 LD (HL),A
 CP 2+15
 RET Z
 CP 4+15
 RET NC
 INC HL
 LD (HL),"A"
 INC HL
 LD (HL),","
 RET
ttable1: DW cret
 DW cpopspec
 DW cjp
 DW coutspec
 DW ccall
 DW cpushspe
 DW rekinst
 DW crst
crst: LD (HL),10  ;RST
 ADD A,A  ;c2
 ADD A,A
 ADD A,A
 PUSH AF
 CALL setsin  ;plaats getal
 POP AF
 BIT 0,(IX+restart) ;restart
 RET Z
 LD (IX+rstflag),1
 CP 8
 RET Z
 INC (IX+rstflag)
 CP &H30
 RET Z
 LD (IX+rstflag),0
 RET

rekinst: CALL accujn
 JP dgetsin
;conditionele sprongen
cjp: LD (HL),5  ;JP
 JR .40
cret: LD (HL),4  ;RET
 JR .40
ccall: LD (HL),3 ;CALL
.40:
 ADD A,16+128
 LD B,(HL)
 INC HL
 LD (HL),A
 LD A,B
 CP 4
 RET Z
 INC HL
 LD (HL),","
 JP dgetdou   ;haal adres
cpopspec:    ;interpreteert POP,RET,EXX,JP (HL),LD SP,HL
 SRL A
 LD (HL),9    ;POP
 JP NC,addspreg

 LD (HL),4   ;RET
 RET Z
 LD (HL),60  ;EXX
 DEC A
 RET Z
 DEC A
 JR Z,jphl
 LD (HL),0       ;LD SP,HL
 LD A,3
 CALL adddoure
 INC HL
 LD (HL),","
 LD A,2
 JP adddoure
jphl: LD (HL),5
 INC HL
 LD (HL),"("
 LD A,2
 CALL adddoure ;HL of IY of IX
 INC HL
 LD (HL),")"
 RET
cpushspe:
 SRL A
 LD (HL),8
 JP NC,addspreg
 LD (HL),3       ;CALL
 JP dgetdou         ;nn ophalen
coutspec:            ;JP nn, OUT,IN,EI,DI,EX (SP),HL,EX DE,HL
 AND A
 LD (HL),5
 JP Z,dgetdou        ;JP nn
 SUB 2
 LD (HL),12 ;OUT
 JR Z,outins         ;out, in
 DEC (HL)
 DEC A
 JR Z,outins
 LD (HL),14   ;EX
 DEC A
 JR Z,exsphl
 DEC A
 JR Z,dehl
 ADD A,57    ;DI en EI
 LD (HL),A
 RET
dehl:
 BIT 0,(IX+indflg)
 JP NZ,diserror    ;EX DE,XY niet ok
 INC A   ;DE=1
 CALL adddoure
 INC HL
 LD (HL),","
adhl: LD A,2
 JP adddoure
exsphl: INC HL
 LD (HL),"("
 INC HL
 LD (HL),12+128   ;SP
 INC HL     ;(SP)
 LD (HL),")"
 INC HL
 LD (HL),","
 JR adhl
outins: BIT 0,(HL)    ;1=IN
 JR NZ,inde
 CALL dgetsinh  ;haal single tussen haakjes
kommaa: INC HL
 LD (HL),","
 INC HL
 LD (HL),128
 RET
inde: INC HL
 LD (HL),128
 INC HL
 LD (HL),","
 JP dgetsinh
;*+**+*+*+*+*+
ttable2: DW crelati   ;tabel met adressen routines bovenste kwart
 DW zestienb
 DW loadspec
 DW incdec16
 DW inc1
 DW dec1
 DW load8
 DW contri
inc1: LD (HL),6    ;INC
 JP addsinre
dec1: LD (HL),7
 JP addsinre
incdec16:
 SRL A
 LD C,A
 LD A,6
 ADC A,0
 LD (HL),A  ;INC of DEC
 LD A,C
 JP adddoure
load8: LD (HL),0  ;LD
 CALL addsinre
 INC HL
 LD (HL),","
 JP dgetsin    ;waarde
zestienb:
 SRL A
 JR NC,loadi
;ADD-instructies
 LD (HL),15 ;ADD
 LD C,A
regadd: LD A,2
 CALL adddoure
 INC HL
 LD (HL),","
 LD A,C
 JP adddoure
loadi: LD (HL),0  ;LD
 CALL adddoure
 INC HL
 LD (HL),","
 JP dgetdou   ;haal waarde op
contri: LD DE,tabsp    ;instr. als RRA, SCF
 CALL addde
 LD A,(DE)
 LD (HL),A
 RET
tabsp: DB 64,66,63,65,57,56,67,55 ;RLCA,RRCA,RLA,RRA,DAA,CPL,SCF,CCF
loadspec: LD (HL),0
 CP 4
 JR NC,metnn   ;LD A,(nn), LD HL,(nn), LD (nn),A, LD (nn),HL
 SRL A
 JR C,avoorop
 CALL adbcde
 JP kommaa
avoorop: INC HL
 LD (HL),128
 INC HL
 LD (HL),","
adbcde: INC HL
 LD (HL),"("
 CALL adddoure
 INC HL
 LD (HL),")"
 RET
metnn:
 RRA
 JR C,regvoor
 PUSH AF
 CALL dgetdouh ;haal adres tussen haakjes
 POP AF
 RRA
 INC HL
 LD (HL),","
 LD A,2       ;HL
 JP NC,adddoure
 INC HL
 LD (HL),128  ;A
 RET
regvoor: RRA
 JR C,areg
 LD A,2
 CALL adddoure
 JR areg1
areg: INC HL
 LD (HL),128
areg1: INC HL
 LD (HL),","
 JP dgetdouh ;adres tussen haakjens

crelati: LD (HL),62    ;NOP! EX AF,AF en relatieve sprongen
 AND A
 RET Z
 DEC A
 JR Z,exafaf
 LD (HL),2
 DEC A
 JR Z,jroffset
 DEC (HL)
 DEC A
 JR Z,jroffset
 ADD A,15+128
 INC HL
 LD (HL),A       ;conditie
 INC HL
 LD (HL),","
jroffset: CALL getincad
 LD E,A
 ADD A,A
 SBC A,A
 LD D,A
nonegate: PUSH HL
 LD HL,(MP)
 ADD HL,DE
 EX DE,HL
 POP HL
 JP setgetal
exafaf: LD (HL),14 ;EX
 CALL addaf
 INC HL
 LD (HL),","
addaf: LD A,3
 JP addspreg ;AF

anderins:  ;disassembleer instructies met &HED
 BIT 0,(IX+indflg)
 JP NZ,diserror
 CALL getincad  ;haal opdrachtcode 2
 CALL splcode
 AND A
 JP PE,diserror
 DEC A
 JR NZ,noutco
 LD DE,ttable3
 JP jptabel  ;spring naar tabel
ttable3: DW cin
 DW cout
 DW arith16
 DW load16
 DW onlyneg
 DW retiretn
 DW imodi
 DW ir
noutco: BIT 2,C      ;instructies als LDIR, enz
 JR NZ,diserror
 LD A,B
 SLA C
 SLA C
 SUB 4
 JR C,diserror
 OR C
 LD DE,ldirac
 CALL addde
 LD A,(DE)
 LD (HL),A
 RET
;DB ldi,ldd,ldir,lddr,cpi,cpd,cpir,cpdr,ini,ind,inir,indr,outi,outd,otir,otdr
ldirac: DB 44,42,45,43,36,34,37,35,40,38,41,39,48,46,49,47
;-
cin: LD (HL),11
 CALL addsinre
 INC HL
 LD (HL),","
adcc: INC HL
 LD (HL),"("
 INC HL
 LD (HL),130   ;"C"
 INC HL
 LD (HL),")"
 RET
cout: LD (HL),12
 CALL adcc
 INC HL
 LD (HL),","
 JP addsinre
load16: LD (HL),0
 SRL A
 JR C,rvoorop
 PUSH AF
 CALL dgetdouh
 INC HL
 LD (HL),","
 POP AF
 JP adddoure
rvoorop: CALL adddoure
 INC HL
 LD (HL),","
 JP dgetdouh  ;adres tussen haakjens
retiretn: LD (HL),52 ;c2=0 >retn, c2=1 >reti
 AND A
 RET Z
 DEC (HL)
 DEC A
 RET Z
diserror: LD (HL),29   ;????
 RET
onlyneg: LD (HL),50  ;NEG
 AND A
 RET Z
 JR diserror
arith16:
 SRL A
 LD C,A
 LD (HL),18
 JP NC,regadd
 LD (HL),16
 JP regadd
imodi: LD (HL),13
 CP 1
 ADC A,0
 CP 4
 JR NC,diserror
 ADD A,"0"-1
 INC HL
 LD (HL),A
 RET
ir:
 CP 4
 JR NC,rrdrld
 LD (HL),0      ;LD
 SRL B
 LD A,3
 ADC A,A  ;6 als het I moet zijn, 7 als het R moet zijn
 ADD A,129
 SRL B
 LD C,128  ;A
 JR NC,anvp
 LD C,A
 LD A,128
anvp: INC HL
 LD (HL),A
 INC HL
 LD (HL),","
 INC HL
 LD (HL),C
 RET
rrdrld: CP 6
 JR NC,diserror
 LD (HL),54     ;RRD
 RRA      ;ok?
 RET NC
 DEC (HL)       ;RLD
 RET
;-------------------------------------------------

dgetsinh: INC HL
 LD (HL),"("
 CALL dgetsin
 JR endhaak
dgetsin: CALL getincad
setsin: LD E,A
 LD D,0
 JR setgetal
dgetdouh: INC HL
 LD (HL),"("
 CALL dgetdou
endhaak: INC HL
 LD (HL),")"
 RET
dgetdou: CALL getincad
 LD E,A
 CALL getincad
 LD D,A
setgetal:
 CALL decorhex
 INC HL
 LD (HL),A
 INC HL
 LD (HL),E
 INC HL
 LD (HL),D
 RET

addspreg: CALL adddoure
 CP 128+12
 RET NZ
 LD (HL),15+128
 RET

adddoure: CP 2
 INC HL
 CALL Z,ind??
 ADD A,9+128
 LD (HL),A
 RET
ind??: BIT 0,(IX+indflg)
 RET Z
 LD A,(IX+indflg)
 CP &HFD
 LD A,5
 SBC A,0
 RET

addsinre: CP 6     ;voeg single register in A toe op (DE),verhoog DE
 INC HL
 JR Z,hlin
 INC A
 AND 7
 ADD A,128
 LD (HL),A
 RET
hlin: LD (HL),"("
 LD A,2
 CALL adddoure ;zet er HL of XY neer
 BIT 0,(IX+indflg)
 JR Z,noindex
 LD A,(IX+groep)
 CP &HCB
 LD A,(IX+disflg)
 CALL NZ,getincad    ;haal distance
 INC HL
 BIT 7,A        ;negatief?
 LD (HL),"+"
 JR Z,.nen
 LD (HL),"-"
 NEG
.nen: CALL setsin
noindex: INC HL
 LD (HL),")"
 RET
getincad:    ;haal byte, verhoog machinepointer HL
 PUSH HL
 LD HL,(MP)
 CALL getbyte
 INC HL
 LD (MP),HL
 POP HL
 PUSH AF
 CALL hextobuf
 POP AF
 RET

maakadr: LD HL,addrbuf
 LD DE,(MP)
 CALL tokadr
 LD A,256-10
 CALL tabula
 LD (lengte),HL
 RET
mendadr: LD HL,(lengte)
 XOR A
 JP tabula
hextobuf: PUSH DE
 LD DE,(lengte)
 CALL hexbyt
 LD (lengte),DE
 POP DE
 RET

splcode: LD B,A
 AND 7
 LD C,A  ;c3=C
 LD A,B
 RRCA
 RRCA
 RRCA
 LD B,A
 AND 7
 LD D,A
 LD A,B
 RRCA
 RRCA
 RRCA
 AND 3
 LD B,D  ;c2=B
 RET

;---

gpos:
 LD HL,&H117    ;23
 LD A,(IX+mode)
 RRCA
 JR C,nmok
 RRCA
 RET NC         ;ED text cursor op onderste 2 regels.
 LD L,&H11      ;17
nmok: LD (&HF3DC),HL
 RET

inline:
 LD A,7
 CALL chput
 BIT 3,(IX+mode)
 RET Z
 PUSH HL    ;werkt alleen in assemblemode
 CALL print$
 DM " in"+0
 LD HL,(regel)
 CALL printdec
 POP HL
 RET

printerr: LD B,3
 DB &H11
badfile: LD B,5
 DB &H11
baddrive: LD B,6
 DB &H11
memvol: LD B,11
 DB &H11
overf: LD B,1
 DB &H11
undefi:
 LD B,2
error:
 CALL printoff
 CALL gpos ;cursor plaatsten
 LD HL,errors
 XOR A
skl: CP (HL)
 INC HL
 JR NZ,skl       ;zoek de juiste foutmelding!
 DJNZ skl
 CALL strout
 CALL inline  ;zet op scherm " in "file/regel, mag DE niet veranderen.
 CALL linefeed
 JR MAIN      ;naar MAIN

naarmain:
 CALL gpos
MAIN:
 CALL closeall  ;files die eventueel nog open staan sluiten.
 LD HL,(eindbuf)
 LD (diskbuf),HL
 LD SP,(stack)  ;zet de SP op dezelfde plaats als onder BASIC
 CALL printoff
 LD (IX+mode),0              ;zet mode op 0 (0=Head,1=Assemble mode,2=Edit)
 LD HL,MAIN
 PUSH HL
 CALL scrinput
 RET C
nextkar: INC HL
 LD A,(HL)
 AND A
 RET Z
 CP " "
 JR Z,nextkar
 CP ">"
 JR Z,nextkar
;in HL adres van opdracht....... hier moet de verdere hoofdlus volgen!!
 PUSH HL
 CALL readword
 EX (SP),HL
 LD DE,command
 CALL testword
 LD B,18     ;"Syntax fout"
 JP NZ,error
 ADD A,A
 LD C,A
 LD B,0
 LD (IX+optie),B
 LD HL,headtab
 ADD HL,BC
 LD B,(HL)
 INC HL
 LD H,(HL)
 LD L,B
 EX (SP),HL   ;sprong-adres op stack, text-adres in HL.

toop: LD A,(HL)  ;naar operand
 CP 2
 RET C
 CP " "
 INC HL
 JR Z,toop
 CP "/"
 JR Z,opt
 DEC HL
 LD DE,buffer1
 CALL TOKENIZE
 LD HL,buffer1+1
 AND A
 RET
opt: LD A,(HL)
 AND &HDF
 JR Z,toop
 INC HL
 CP "P"
 JR Z,prton
 LD (IX+optie),A
 JR toop
prton: CALL printon  ;printer aan
 JR toop

tofiles: XOR A
 LD (filebuf+39),A
 LD (filebuf1+39),A
 LD (filebuf2+39),A
 JP MAIN
