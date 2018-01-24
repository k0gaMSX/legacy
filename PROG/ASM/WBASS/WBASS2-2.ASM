
;Programma:WB-ASS2            versie 1.0
;door:     Wilbert Berendsen  begin 1988


DEFKEY MACR
 DB %1
 DW %2
 ENDM

;Constanten:
filebuf: EQU &HF60C
filebuf1: EQU &HF635
filebuf2: EQU &HF523
tekstbuf: EQU &HF55E+18
addrbuf: EQU &HF55E

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


variab: EQU &H4010
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
asmflag: EQU 31


fase: EQU rstflag
;variabele variabelen
binlen: EQU &H4CD3
hexlen: EQU &H4CCE
baddrive: EQU &H64EB
beglin: EQU &H507A

;VARIABELEN VARIABELEN VARIABELEN VARIABELEN VARIABELEN

beginbuf: EQU &H4038    ;begin van de tekstbuffer
beglabel: EQU &H403A    ;begin actuele labeltabel
eindtxt: EQU &H403C     ;eerste vrije byte n  tekst
diskbuf: EQU &H403E     ;adres eerste file I/O buffer
eindbuf: EQU &H4040     ;eind buffer
begin: EQU &H4042
doel: EQU &H4044
lengte: EQU &H4046
rest: EQU &H4048
lastadr: EQU &H404A
stack: EQU &H404C

linadr: EQU &H404E      ;adres v.e. regel
aantr: EQU &H4050       ;aantal regels blok.

aantal: EQU &H4052      ;aantal regels
filin: EQU &H4054       ;regelnummer van regel bovenaan scherm.
regel: EQU &H4056       ;regel die op dit moment geassembleerd wordt

MP: EQU &H4058          ;machine pointer tijdens assembleren.
begadr: EQU &H405A
varbuff: EQU &H405C ;ruimte voor meer variabelen
start: EQU &H405E     ;vorig label
pagadr: EQU &H4062
OLDMP: EQU &H4064
opbuf: EQU &H4070

buffer1: EQU &H40AD
getbyte: EQU &H41FD
brebyte: EQU &H420B
INSERT: EQU &H4367 ;voeg ruimte in op HL, verschuiven tot DE
DELETE: EQU &H437E ;wis ruimte tussen HL en DE
COPY: EQU &H4398   ;kopieert HL naar DE lengte BC met tussenvoegen.
MOVE: EQU &H43AD  ;functie verplaats blok (ook voor computers zonder mapper!
 ;Verplaats blok van HL naar DE, lengte BC zowel achteruit als vooruit
killtext: EQU &H4420
finlin: EQU &H4440
getlin: EQU &H4453    ;haal regel DE op in token naar HL
getasc: EQU &H446E            ;haal regel DE op naar &HF55E in ASCII
getblk: EQU &H44A0
invlin: EQU &H453E
;-------------------------------------------
;label-routines

left$: EQU &H45A6
berplace: EQU &H45B8 ;bereken plaats en zet in HL
zoeklab: EQU &H45C3     ;zoek label op HL lengte C op, zet nummer in HL
zoekl: EQU &H45E2
getlabel: EQU &H4611         ;haal labelnummer HL op en zet op DE
getvlab: EQU &H4620  ;haal waarde label DE op, zet in DE.


maal: EQU &H46B7    ;HL=HL*DE
deel: EQU &H46D0     ;HL=HL/DE
operr: EQU &H4757

;*+*+*+*+*+*+*+*+*+*+* 16 Bits Rekenkundige Evaluator *+*+*+*+*+*+*+*+*
evalua: EQU &H476D
twocompl: EQU &H47D4
getmembk: EQU &H47E1
getdat: EQU &H47E6
getadr: EQU &H47EB
misoper: EQU &H47EF
getmem1: EQU &H47F4     ;haal memory-blok (beginadres, eindadres, [doeladres])
TOKEN: EQU &H4820     ;tokenize editor-regel
TOKENIZE: EQU &H4821  ;tokenize operandregel
readword: EQU &H494C
testword: EQU &H4962
;--------------------------------------------
DETOK: EQU &H49F4 ;detokenize regel naar &HF55E
DETOKEN: EQU &H49FA
valtohl: EQU &H4A58
getword: EQU &H4B24
;*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*

getfilwc: EQU &H4B82
getfilnm: EQU &H4B86
filesyn: EQU &H4B96 ;filenaam op HL tot aan " of 0 naar DE in de goede vorm.
clearfcb: EQU &H4BC7
;-----------------
hunt: EQU &H4C19
lhunt: EQU &H4C21
swap: EQU &H4C2E
head: EQU &H4C38
addde: EQU &H4C43
addhl: EQU &H4C48
tabula: EQU &H4C4D
decbyt: EQU &H4C57
hexbyt: EQU &H4C61
binbyt: EQU &H4C77
symbol: EQU &H4C84

EXIT: EQU &H4E89
outchr: EQU &H4E94
outlin: EQU &H4E9E
linefeed: EQU &H4EA3
chrout: EQU &H4EA7
bufout: EQU &H4EB3
strout: EQU &H4EB6     ;string output
print$: EQU &H4ECF       ;print tekst van terugsprongadres
spcout: EQU &H4ED5
string$: EQU &H4ED7
printoff: EQU &H4F23
printon: EQU &H4F32
inkey$: EQU &H4F47
keywait: EQU &H4F58 ;wacht op een toets als er de vorige keer op return gedr. w
getkey: EQU &H4FAF
keytabel: EQU &H4FC4
lintoscr: EQU &H4FE0
scrlin: EQU &H4FED      ;zet regel op DE op scherm op HL
;maximale lengte in C, indien korter aanvullen met spaties
input: EQU &H50B2     ;als B=0, dan regel editor en default inhoud buffer
                      ;als B=1, dan terug bij onbekende toetsen en default
printadr: EQU &H5223
printdec: EQU &H5229
printhex: EQU &H522D
printbin: EQU &H5231
inpadr: EQU &H524A
inpdec: EQU &H5250
inphex: EQU &H5254
decorhex: EQU &H5285
tokadr: EQU &H528B
space?: EQU &H5294
system: EQU &H52A6
closef: EQU &H52CF
close: EQU &H52F8
closefb1: EQU &H5302
closeasc: EQU &H5305
openf: EQU &H530C
creafil: EQU &H5314
brereg: EQU &H5339
brereg1: EQU &H5342
bretek: EQU &H5353
gettek: EQU &H5386
iload: EQU &H53BF
fileadr: EQU &H54F2
gethladr: EQU &H5524
makebsav: EQU &H5616
brehladr: EQU &H5635
EDIT: EQU &H56FE
conversi: EQU &H58E2
nextkol: EQU &H4EF6
nextkol1: EQU &H4F0D
fileout: EQU &H4EE4
bigvaout: EQU &H4B3B
bepaant: EQU &H4500

maakadr: EQU &H647E
mendadr: EQU &H6491
hextobuf: EQU &H6498

memvol: EQU &H64EE
overf: EQU &H64F1
undefi: EQU &H64F4
error: EQU &H64F6
naarmain: EQU &H6511
MAIN: EQU &H6514

;routines voor commandoos

i?: EQU &H58DF
iaddr: EQU &H552E
ibload: EQU &H5573
ibsave: EQU &H55ED
icompare: EQU &H5913
idir: EQU &H5C68
idis: EQU &H6004
idload: EQU &H5578
idsave: EQU &H55FF
iedit: EQU &H56DC
ifill: EQU &H58FC
iget: EQU &H5684
igo: EQU &H5A5F
iin: EQU &H58D7
iinfo: EQU &H5BF0
imerge: EQU &H5423
imon: EQU &H5E68
imove: EQU &H5943
iout: EQU &H58A8
ipage: EQU &H599F
ipeek: EQU &H58B3
ipoke: EQU &H5881
iput: EQU &H56B0
ireg: EQU &H5AC0
isave: EQU &H5460
itype: EQU &H563D
iwidth: EQU &H5D7E

;2e helft programma

 ORG &H6598
headtab:
 DW isave,iload,imerge,ibsave,ibload,idsave,idload,iput,iget
 DW idir,iset,iedit,iasm,idis,imon,ipoke,ipeek,i?,ipage
 DW iinfo,ihunt,icompare,imove,ifill,EXIT,iprt,igo,ireg
 DW iout,iin,ifind,ilab,iaddr
 DW killtext,iwidth,itype
 DW 0,0,0,0
command:     ;instructie tabel hoofdprogramma
 DM "SAV"    ;save 1
  DB "E"+128
 DM "LOA"    ;load 2
  DB "D"+128
 DM "MERG"   ;merge 3
  DB "E"+128
 DM "BSAV"   ;bsave 4
  DB "E"+128
 DM "BLOA"   ;bload 5
  DB "D"+128
 DM "DSAV"   ;dsave 6
  DB "E"+128
 DM "DLOA"   ;dload 7
  DB "D"+128
 DM "PU"     ;put 8
  DB "T"+128
 DM "GE"     ;get 9
  DB "T"+128
 DM "DI"     ;dir 10
  DB "R"+128
 DM "SE"     ;set 11
  DB "T"+128
 DM "EDI"    ;edit 12
  DB "T"+128
 DM "AS"     ;asm 13
  DB "M"+128
 DM "DI"     ;dis 14
  DB "S"+128
 DM "MO"     ;mon 15
  DB "N"+128
 DM "POK"    ;poke 16
  DB "E"+128
 DM "PEE"    ;peek 17
  DB "K"+128
  DB "?"+128 ;? 18
 DM "PAG"    ;page 19
  DB "E"+128
 DM "INF"    ;info 20
  DB "O"+128
 DM "HUN"    ;hunt 21
  DB "T"+128
 DM "COMPAR" ;compare 22
  DB "E"+128
 DM "MOV"    ;move 23
  DB "E"+128
 DM "FIL"    ;fill 24
  DB "L"+128
 DM "BASI"   ;basic 25
  DB "C"+128
 DM "PR"     ;prt 26
  DB "T"+128
 DM "G"      ;go 27
  DB "O"+128
 DM "RE"     ;reg 28
  DB "G"+128
 DM "OU"     ;out 29
  DB "T"+128
 DM "I"      ;in 30
  DB "N"+128
 DM "FIN"    ;find 31
  DB "D"+128
 DM "LA"     ;lab 32
  DB "B"+128
 DM "ADD"    ;addr 33
  DB "R"+128
 DM "SC"     ;scr 34
  DB "R"+128
 DM "WIDT"   ;width 35
  DB "H"+128
 DM "TYP"    ;type 36
  DB "E"+128
 DB 0
 DS 27

errors:

 DM 0+"Waarde te groot of te klein"
 DM 0+"Label bestaat niet"

 DM 0+"Printer niet klaar"
 DM 0+"Disk vol"
 DM 0+"Foute filenaam"
 DM 0+"Foute drive naam"
 DM 0+"Disk I/O fout"
 DM 0+"Bestand niet gevonden"
 DM 0+"Foute file mode"
 DM 0+"Beginadres hoger dan eindadres"

 DM 0+"Geheugen vol"
 DM 0+"Blok niet goed gemarkeerd"
 DM 0+"Doel-regel in blok"

 DM 0+"Operand fout"
 DM 0+"Operand mist"
 DM 0+"Label al gedef."  ;16
 DM 0+"Label mist"       ;17
 DM 0+"Instructie fout"  ;18
 DM 0+"Deling door nul"  ;19
 DM 0+"Filenaam mist"    ;20
 DM 0+"Relatieve sprong buiten bereik"  ;21
 DM 0+"Indexregister fout" ;22
 DM 0+"Register fout" ;23

 DB 0

ifind: LD B,17
 LD A,(HL)
 CP &HC0
 JP NZ,error
 INC HL
 LD A,(HL)
 INC HL
 LD H,(HL)  ;label
 LD L,A
 LD A,(IX+optie)
 CP "D"
 JR NZ,findlab
finddef: LD DE,1
 LD B,0
 LD IY,(beginbuf)
 INC IY
deflus: LD C,(IY+0)
 INC C
 RET Z
 BIT 7,C
 RES 7,C
 JR Z,nodef
 LD A,(IY+1)
 SUB L
 JR NZ,nodef
 LD A,(IY+2)
 SUB H
 JR Z,deffnd
nodef: ADD IY,BC
 INC DE   ;volgende regel
 JR deflus

findlab: LD DE,(filin)
 LD A,(IX+lin)
 DEC A
 CALL addde
 SCF
nextlin: INC DE
 PUSH HL
 PUSH DE
 LD HL,buffer1
 CALL getlin
 POP DE
 POP HL   ;DE is regelnummer
 RET C    ;einde
 LD B,&H55
 LD IY,buffer1
 BIT 7,(IY+0) ;lengte
 INC IY
 JR Z,nodefl
 INC IY
 INC IY
nodefl: BIT 7,(IY+0)     ;instructie?
 JR Z,nomnem
nodefl2: INC IY
nomnem: LD A,(IY+0)
 INC IY
 CP 2
 CCF
 JR NC,nextlin
 RRC B        ;Superslimme manier!!!!!
 CP 34
 JR Z,nomnem
 RRC B
 JR C,nomnem  ;in string
 CP &HC0
 JR C,nomnem
 JR NZ,nodefl1
 LD A,(IY+0)
 SUB L
 JR NZ,nodefl1
 LD A,(IY+1)
 SUB H
 JR NZ,nodefl1
 ;label gevonden
deffnd: LD (filin),DE
 LD (IX+lin),1
 JP EDIT
nodefl1: INC IY
 JR nodefl2

zerolab:        ;zet vlaggen uit
 LD HL,(beglabel)
zero1: LD A,(HL)
 INC A
 RET Z
 LD B,6
cl_lus: RES 7,(HL)
 INC HL
 DJNZ cl_lus
 INC HL
 INC HL
 JR zero1

getdbstr: LD C,0      ;haal DB-string naar DE
 LD A,(HL)
 CP 2
 JP C,misoper
getdb1: LD A,(HL)
 CP 2
 RET C
 INC HL
 CP 34
 JR Z,text
value: DEC HL
 PUSH BC
 PUSH DE
 CALL getdat   ;haal single byte
 POP DE
 POP BC
 CALL outkar
 JR getdb1
text: INC HL
 LD A,(HL)
 DEC HL
 CP 34
 JR Z,value
nextlet: LD A,(HL)
 INC HL
 CP 2
 RET C
 CP 34
 JR Z,endtxt
 CALL outkar
 JR nextlet
endtxt: LD A,(HL)
 CP 2
 RET C
 JP NZ,operr
 INC HL
 JR getdb1
outkar:
 BIT 3,(IX+mode)
 JP NZ,outincad   ;byte naar achtergrondgeheugen
 LD (DE),A
 INC DE
 INC C
 RET

ihunt: LD A,(IX+optie)
 CP "B"
 LD DE,0
 CALL Z,getadr   ;beginadres
 PUSH DE
 LD DE,addrbuf
 CALL getdbstr
 POP HL

nextzk: CALL zoek
 CALL Z,found
 INC HL
 LD A,L
 OR H
 JR NZ,nextzk
 RET
found: CALL print$
 DM "Gevonden op:"+0
 CALL printadr
 CALL linefeed
 CALL getkey
 RET
zoek: PUSH HL
 LD DE,addrbuf
 LD B,C
zoek1: CALL getbyte
 EX DE,HL
 CP (HL)
 EX DE,HL
 JR NZ,notfnd
 INC HL
 INC DE
 DJNZ zoek1
notfnd: POP HL
 RET

iprt: LD DE,addrbuf
 PUSH DE
 CALL getdbstr
 POP HL
prtlus: LD A,(HL)
 CALL outchr
 INC HL
 DEC C
 JR NZ,prtlus
 RET

getstr: LD A,(HL)
 AND A
 JP Z,misoper
 CP 34
 JP NZ,operr
 INC HL
 LD C,0
strlus: CALL head
 CP 2
 RET C
 INC HL
 CP 34
 RET Z
 INC C
 JR strlus

iset:         ;instel opdracht
 ;P printer breedte
 ;Hex fix
 ;Bin fix
 ;Eindadres tekst buffer
 ;Default drive
 ;Automatiese backup
 ;Grafiese karakters
 ;R Speciale DB's bij RST-opdr.
 ;A Voorkeur adres uitvoer (Deci-hexa)

 LD A,(IX+optie)
 AND A
 JR Z,toonset
 LD C,A
 LD A,(HL)
 CP 2
 JP C,misoper
 LD A,C
 LD (beglin),HL
 LD HL,settb
 CALL keytabel
 RET Z ;ok
toonset: CALL print$
 DM "W Printerbreedte:"+0
 LD H,0
 LD L,(IX+prtwidth)
 CALL printdec
 CALL print$
 DM 13+"K Kolommen monitor:"+0
 LD L,16
 BIT 0,(IX+mon)
 JR NZ,prtbr
 LD L,8
prtbr: CALL printdec
 CALL print$
 DM 13+"H Hex-getallen: "+0
 LD HL,hexlen
 CALL hexbinps
 CALL print$
 DM 13+"B Bin-getallen: "+0
 LD HL,binlen
 CALL hexbinps
 CALL print$
 DM 13+"E Eindadres buffer:"+0
 LD HL,(eindbuf)
 CALL printadr
 CALL print$
 DM 13+"D Default diskdrive: "+0
 LD C,&H19
 CALL system
 ADD A,"A"
 CALL chrout
 CALL print$
 DM 13+"S Saven met backup:"+0
 BIT backup,(IX+setflag)
 CALL prtjn
 CALL print$
 DM 13+"G Grafische tekens:"+0
 BIT graph,(IX+setflag)
 CALL prtjn
 CALL print$
 DM 13+"R DEFB en DEFW bij RST:"+0
 BIT 0,(IX+restart)
 CALL prtjn
 CALL print$
 DM 13+"A Adresuitvoer: "+0
 LD HL,dhtxt
 LD A,4
 BIT 0,(IX+dechex)
 CALL NZ,addhl
 CALL strout
 JP linefeed
prtjn: LD HL,dja
 LD A,4
 CALL Z,addhl
 JP strout
hexbinps: LD C,(HL)
 INC HL
 LD B,(HL)
nextl1: INC HL
 LD A,(HL)
 CALL chrout
 DJNZ nextl1
 LD HL,dvoor
 DEC C
 LD A,6
 CALL Z,addhl
 JP strout
dhtxt: DM "hexadecimaal"+0
dja: DM " ja"+0+" nee"+0
dvoor: DM " voor"+0+" achter"+0

settb: DEFKEY "W",printbrt
 DEFKEY "K",kolmon
 DEFKEY "H",hexfx
 DEFKEY "B",binfx
 DEFKEY "E",endadres
 DEFKEY "D",default
 DEFKEY "S",savbak
 DEFKEY "G",grafies
 DEFKEY "R",rstdb
 DEFKEY "A",addrout
 DB 0

printbrt: CALL getdat
 CP 38
 JP C,overf
 LD (IX+prtwidth),A
 RET
endadres: CALL getadr
 LD HL,(eindtxt)
 DEC HL
 RST &H20
 JP NC,memvol
 LD (eindbuf),DE
 RET
savbak: CALL get01
 RES backup,(IX+setflag)
 RET Z
 SET backup,(IX+setflag)
 RET
rstdb: CALL get01
 LD (IX+restart),C
 RET
grafies: CALL get01
 RES graph,(IX+setflag)
 RET Z
 SET graph,(IX+setflag)
 RET
default: LD A,(HL)
 SUB 127      ;A B C
 CP (IX+drives)
 JP NC,baddrive
 LD (IX+defdrive),A
 LD C,&HE
 LD E,A
 DEC E
 JP system
addrout: LD A,(HL)
 LD C,0
 CP 133 ;H
 JR Z,oka
 INC C
 CP 131 ;D
 JP NZ,operr
oka: LD (IX+dechex),C
 RET
kolmon: CALL getdat
 LD C,0
 CP 8
 JR Z,okkm
 INC C
 CP 16
 JP NZ,operr
okkm: LD (IX+mon),C
 RET

hexfx: LD DE,hexlen
 JR fxint
binfx: LD DE,binlen
fxint: LD A,(HL)
 INC HL
 LD C,0
 CP "V"  ;voor
 JR Z,fvoor
 INC C
 CP 128  ;A
 JP NZ,operr
fvoor: LD A,C
 LD (DE),A
 INC DE
 LD A,(HL)
 CP 2
 JP C,misoper
 JP NZ,operr
 INC HL
 PUSH HL
 CALL getstr
 POP HL
 INC HL
 LD A,C
 AND A
 JP Z,operr
 CP 4
 JP NC,operr
 LD B,0
 LD (DE),A
 INC DE
 LDIR
 RET

get01: LD A,(HL)
 INC HL
 CP "N"
 LD C,0
 RET Z
 CP "J"
 JP NZ,operr
 INC C
 RET




byttab: ;DB ccf,cpl,daa,di,ei,exx,halt,nop,rla,rlca,rra,rrca,scf
 DB &H3F,&H2F,&H27,&HF3,&HFB,&HD9,&H76,0,&H17,7,&H1F,&HF,&H37
byt2tab: DB &HA9,&HB9,&HA1,&HB1,&HAA,&HBA,&HA2,&HB2,&HA8,&HB8,&HA0,&HB0
 DB &HAB,&HBB,&HA3,&HB3,&H44,&H4D,&H45,&H6F,&H67


asmreg: LD HL,buffer1    ;assembleer regel in buffer1
 LD (IX+lenlin),0   ;lenlin is variabele voor assm. processen
;bit 0 :1=er stond een label voor de instructie
;bit 1 :in de operand zit een XY met een distance
 LD (IX+indflg),0

 BIT 7,(HL)
 INC HL
 JR Z,nolabel
 BIT 0,(IX+fase)   ;0=fase 1, 1=fase 2
 JR NZ,f2r
 LD HL,(buffer1+1)
 CALL berplace
 PUSH HL
 POP IY
 BIT 7,(HL)
 LD B,16         ;"Label is al gedefinieerd"
 JP NZ,error
 SET 7,(HL)      ;gedefinieerd
 INC HL
 SET 7,(HL)      ;relocatable
 LD HL,(MP)
 LD (IY+6),L
 LD (IY+7),H
f2r: SET 0,(IX+lenlin)
 LD HL,buffer1+3
nolabel: LD A,(HL)
 CP 2       ;nul of REM
 RET C
 INC HL
 SUB 128
 RET C
;instructie 0 t/m 33 :variabele instructies
;           34 -  54 :2 byters zonder operand
;           55 -  67 :1 byters zonder operand
;           68 - veel :pseudo instructies
 CP 34
 JP C,varins
 CP 55
 JR C,byte2
 CP 68
 JP NC,pseudo
;1 byters
 LD DE,byttab-55
tobyte: CALL addde
 LD A,(DE)
 JP outincad
byte2: CALL edout
 LD DE,byt2tab-34
 JR tobyte



spreg: LD A,(HL)
 CP 128+12 ;SP
 SCF
 RET Z
 CP 128+15
 JR NZ,doureg
 LD (HL),128+12
doureg:        ;haal dubbel register BC DE HL SP IX,IY
 LD A,(HL)
 SUB 128+9
 RET C         ;CF=1 error
 CP 6
 CCF
 RET C
 CP 2  ;HL
 LD B,1
 JR Z,hlreg
 CP 4
 JR C,komma1
;4=IX, 5=IY
 LD B,&HDD
 JR Z,ddok
 LD B,&HFD
ddok: CALL ddok2
 CALL NC,outib
toreg: LD A,2
 JR komma1
hlreg: CALL ddok2
 JR toreg
ddok2: LD A,(IX+indflg)
 AND A
 JR Z,ddok1
 CP B
 SCF
ddok1: LD (IX+indflg),B
 RET Z ;CF=1: al eerder gehad.
;error HL met XY of IX met IY
ixiyerr: LD B,22
 JP error

;...
sinreg: LD A,(HL) ;haal single register.
 CP 6   ;"("
 JR Z,hlhaak
 SUB 128
 RET C
 CP 7
 CCF
 RET C
 DEC A
 AND 7
komma1: INC HL
komma: PUSH AF
 LD A,(HL)
 CP 2
 JR NZ,nof
 INC HL
nof: POP AF
 AND A
 RET
hlhaak: PUSH HL ;het moet (HL) tussen haakjes zijn.
 INC HL
 CALL doureg
 JR C,pophl
 CP 2
 JR NZ,pophl
 POP AF
 BIT 7,(IX+indflg)
 JR Z,noindx
 LD A,(HL)
 CP 4
 LD A,0
 CALL NZ,getsbyt
 LD (IX+disflg),A
 SET 1,(IX+lenlin)
noindx: CALL sluithk
 LD A,6   ;A=2 CF=0
 JR komma
pophl: POP HL
 SCF
 RET
indout: BIT 1,(IX+lenlin)
 RET Z
 PUSH AF
 LD A,(IX+disflg)
 CALL outincad
 POP AF
 RET

gdoureg: CALL doureg
 RET NC
 JR getok1
gsinreg: CALL sinreg
 RET NC
 JR getok1
gspreg: CALL spreg
 RET NC
regierr:
getok1: LD B,23   ;"Register fout"
 JP error

getcon: LD A,(HL)       ;haal conditie
 SUB 130
 RET C
 JR NZ,ccon
 LD A,17
ccon: SUB 14
 RET C
 CP 8
 CCF
 RET C
 ADD A,A
 ADD A,A
 ADD A,A
 JR komma1

edout: PUSH AF
 BIT 7,(IX+indflg)
 JP NZ,ixiyerr
 LD A,&HED
 CALL outincad
 POP AF
 RET

getadres: BIT 0,(IX+fase)
 JP NZ,getadr
 LD DE,0
 LD (IX+const),E
passval: LD B,&H55
pasv1: LD A,(HL)
 CP 6
 JP C,komma
 INC HL
 RET Z
 RRC B
 CP 34
 JR Z,pasv1
 RRC B
 JR C,pasv1
 CP &HC0
 JR C,pasv1
 INC HL
 INC HL
 JR pasv1

getsbyt: CALL getadres
 CALL twocompl
 RET NC
 JP overf

getrela: CALL getadres
relaval: BIT 0,(IX+const)
 JR Z,norel
 BIT reloca,(IX+asmflag) ;1=geen rel. tabel
 JR Z,norel
 PUSH DE    ;het label is niet constant (=relocatable)
 PUSH HL
 LD DE,(MP)
 LD HL,(pagadr)
 LD A,E
 CALL brebyte
 INC HL
 LD A,D
 CALL brebyte
 INC HL
 LD (pagadr),HL
 POP HL
 POP DE
norel: LD A,E
 CALL outincad
 LD A,D
 JP outincad

pseudo: PUSH HL
 LD HL,itable2
 SUB 68
 JR totabel
varins:       ;kijken of er in de operand index-registers voor komen.
 CP 31
 JR NC,bitres
 CP 23
 JR NC,rotate
 CP 15
 JR NC,rekinst
 PUSH HL
 LD HL,itable
totabel: LD C,A
 LD B,0
 ADD HL,BC
 ADD HL,BC
 LD B,(HL)
 INC HL
 LD H,(HL)
 LD L,B
 EX (SP),HL
 RET
bitres: SUB 30
 RRCA
 RRCA
 PUSH AF
 CALL getsbyt   ;bit
 CALL komma
 CP 8
 JP NC,overf
 ADD A,A
 ADD A,A
 ADD A,A
endrotb: LD C,A
 CALL gsinreg   ;register
 PUSH AF
 LD A,&HCB
 CALL outincad
 POP AF
 ADD A,C
 POP BC
 ADD A,B
 CALL indout
 JP outincad

rotate: SUB 23
 CP 6
 LD B,18
 JP Z,error
 ADD A,A
 ADD A,A
 ADD A,A
 PUSH AF
 XOR A
 JR endrotb

rekinst:  ;ADD ADC enz.
 SUB 15
 CP 4
 PUSH AF
 CALL C,add16
 LD A,(HL)    ;A ?
 CP 128
 JR NZ,noa
 INC HL
 LD A,(HL)
 CP 2
 DEC HL
 LD A,128
 JR C,noa
 INC HL
 CALL komma
noa: CALL sinreg
 JR C,metn
 OR &H80
 LD C,A
 POP AF
maal8: ADD A,A
 ADD A,A
 ADD A,A
 ADD A,C
 CALL outincad
 JP indout
metn: POP AF        ;haal enkele waarde
 LD C,&HC6
 CALL maal8
 CALL getsbyt
 JP outincad

add16: CALL doureg
 RET C
 CP 2
 JP NZ,regierr
 POP AF
 POP AF
 CP 2
 JP Z,operr
 AND A
 CALL NZ,edout
 LD C,9
 JR Z,okok1
 DEC A
 LD C,&H4A
 JR Z,okok1
 LD C,&H42
okok1: CALL gdoureg
mal16: ADD A,A
 ADD A,A
 ADD A,A
 ADD A,A
 ADD A,C
 JP outincad

itable: DW aload
 DW ajr
 DW adjnz
 DW acall
 DW aret
 DW ajp
 DW ainc
 DW adec
 DW apush
 DW apop
 DW arst
 DW ain
 DW aout
 DW aim
 DW aex

adjnz: LD A,16
 JR dnz1
ajr: CALL getcon
 JR NC,welcon
 LD A,&H38
welcon: XOR 32
dnz1: CALL outincad
 CALL getadres
 XOR A
 BIT 0,(IX+fase)
 JR Z,outia1
 PUSH HL
 LD HL,(MP)
 EX DE,HL
 ;DE=MP, HL=adres
 SBC HL,DE
 DEC HL
 EX DE,HL
 CALL twocompl
 POP HL
 LD B,21
 JP C,error
 JR outia1

ajp: LD BC,&HC3C2  ;interpreteer JP
 LD A,(HL)
 CP 6   ;(
 JR NZ,acjp
 INC HL
 CALL doureg
 JP C,operr
 CP 2
 JP NZ,regierr
 CALL sluithk
 LD A,&HE9
 JR outia1

acall: LD BC,&HCDC4 ;CALL :B=opcode zonder conditie, C=met
acjp: CALL getcon
 JR NC,cond
 LD A,B
cond: OR C
 CALL outincad
 JP getrela

aret: CALL getcon
 JR NC,okaret
 LD A,&HC9
okaret: OR &HC0
outia1: JP outincad

aim: CALL getsbyt
 CP 3
 JP NC,overf
 CP 1
 CCF
 ADC A,0  ;als A>0 dan A=A+1
 ;0,2,3
 ADD A,A
 ADD A,A
 ADD A,A
 ADD A,&H46
 CALL edout
 JR outia1

aex: LD A,(HL)
 CP 6
 JR NZ,nosp
 INC HL
 CALL doureg
 CP 3
 JP NZ,operr
 CALL sluithk
 CALL komma
 LD C,&H80
 JR nosp1
nosp: CALL gspreg
 LD C,A
nosp1: CALL gspreg
 ADD A,A
 ADD A,A
 OR C
 LD B,&H8
 CP &B1111   ;AF,AF
 JR Z,outib
 LD B,&HE3   ;(SP),HL
 CP &H88
 JR Z,outib
 LD B,&HEB
 CP &B1001
 JP NZ,operr
 BIT 7,(IX+indflg)
 JP NZ,ixiyerr
outib: LD A,B
outia: JP outincad

arst: CALL getsbyt
 LD B,A
 AND &H38
 CP B
 JP NZ,overf
 OR &HC7
 JR outia

apush: LD C,&HC5
 DB &H11
apop: LD C,&HC1
 CALL gspreg
 JP mal16

ainc: LD C,0
 DB &H11
adec: LD C,1
 CALL doureg
 JR NC,doublei
 CALL gsinreg
 ADD A,A
 ADD A,A
 ADD A,A
 ADD A,C
 ADD A,4
 CALL outincad
 JP indout
doublei: ADD A,A
 ADD A,C
 ADD A,A
 ADD A,A
 ADD A,A
 ADD A,3
 JR outia

ain: CALL gsinreg
 LD C,A
 LD A,(HL)
 INC HL
 CP 6
 JP NZ,operr
 LD A,(HL)
 CP 130 ;C
 LD A,C
 JR NZ,nietc
 INC HL
 CALL edout
 ADD A,A
 ADD A,A
 ADD A,A
 ADD A,&H40
 JR endin
nietc:
 CP 7
 JP NZ,regierr
 LD A,&HDB
 CALL outincad
 CALL getsbyt
endin: CALL outincad
sluithk: LD A,(HL)
 INC HL
 CP 4
 RET Z
 JP operr

aout: LD A,(HL)
 INC HL
 CP 6
 JP NZ,error
 LD A,(HL)
 CP 130
 JR NZ,nietc1
 INC HL
 CALL sluithk
 CALL komma
 CALL gsinreg
 ADD A,A
 ADD A,A
 ADD A,A
 ADD A,&H41
 CALL edout
 JP outincad
nietc1: LD A,&HD3
 CALL outincad
 CALL getsbyt  ;haal byte in A
 CALL outincad ;breng
 CALL sluithk  ;haakje sluiten
 CALL komma    ;komma
 LD A,(HL)     ;,A
 CP 128
 JP NZ,regierr
 INC HL
 RET

aload:                  ;Interpreteer laadinstructies
 CALL sinreg    ;8bit register?
 JR C,nosr
 ADD A,A
 ADD A,A
 ADD A,A
 LD C,A
 CALL sinreg
 JR C,metn1
 ADD A,C
 ADD A,&H40
 CP &H76    ;(HL),(HL) = HALT
 JP Z,operr
 CALL outincad
 JP indout
metn1: LD A,C
 CP 8*7    ;A
 JR NZ,noaccu
 LD A,(HL)
 LD B,&H57
 SUB 128+7   ;I
 JR Z,regri
 DEC A
 JR NZ,noirr
 LD B,&H5F
regri: CALL edout
 INC HL
 JP outib
noirr: LD A,(HL)
 CP 6           ;Haakje openen?
 JR NZ,noaccu
 INC HL
 LD B,10
 LD A,(HL)
 SUB 128+9
 JR Z,bcdere
 DEC A
 JR NZ,metnn2
 LD B,26
bcdere: CALL outib
 INC HL
 JP sluithk
metnn2: LD A,&H3A
 CALL outincad
 CALL getrela
 JP sluithk
noaccu: LD A,6
 ADD A,C
 CALL outincad
 CALL indout
 CALL getsbyt
 JP outincad
nosr:         ;de operand begon niet met een single register.
 CALL doureg ;Dubbel register
 JR C,nodr
;Het is een dubbel register.
 ADD A,A
 ADD A,A
 ADD A,A
 ADD A,A
 LD C,A
 CP 16*3   ;SP
 JR NZ,nosp3
 CALL doureg ;SP,HL ?
 JR C,nosp3
 CP 2
 JP NZ,regierr
 LD A,&HF9
 JP outincad
nosp3: LD A,(HL)
 CP 6
 LD A,C
 JR NZ,metnn3
 INC HL
 ADD A,10
 CP 16*2+10  ;HL
 JR Z,hetishl
 CALL edout
 ADD A,&H4B-10
hetishl: CALL outincad
 CALL getrela
 JP sluithk
metnn3:  ;Het is LD rr,nn
 INC A
 CALL outincad
 JP getrela
nodr:     ;eerste operand was geen gewoon register.
 LD A,(HL)
 LD B,&H47
 SUB 128+7
 JR Z,regir2
 DEC A
 JR NZ,noimod
 LD B,&H4F
regir2: CALL edout
 CALL outib
 CALL komma1
endaccu: LD A,(HL) ;,A
 INC HL
 CP 128
 RET Z
 JP operr
noimod: LD A,(HL)
 CP 6 ;(
 JP NZ,operr
 INC HL
 LD B,2
 LD A,(HL)
 SUB 128+9
 JR Z,bcdere1
 DEC A
 JR NZ,nobcde
 LD B,18
bcdere1: CALL outib
 INC HL
 CALL sluithk
 CALL komma
 JR endaccu
nobcde:
 CALL getadres
 CALL sluithk
 CALL komma
 LD A,(HL)
 CP 128
 JR NZ,noaccu2
 INC HL
 LD A,&H32
 CALL outincad
 JP relaval
noaccu2: CALL doureg
 JP C,operr
 ADD A,A
 ADD A,A
 ADD A,A
 ADD A,A
 ADD A,2
 CP 34
 JR Z,nnhl
 CALL edout
 ADD A,&H43-2
nnhl: CALL outincad
 JP relaval


itable2: DW aorg
 DW aequ
 DW aend
 DW getdbstr
 DW adefw
 DW adefs
 DW getdbstr
 DW getdbstr
 DW adefw
 DW adefs
 DW getdbstr
 DW aglobal
 DW ainclude
 DW 0
 DW 0

adefw:
 CALL getrela
 LD A,(HL)
 CP 2
 JR NC,adefw
 RET

adefs: CALL getadr
 PUSH HL
 LD HL,(MP)
 ADD HL,DE     ;Store ruimte
 LD (MP),HL
 POP HL
 BIT 0,(IX+fase)
 RET Z
nexttek: LD A,D
 OR E
 RET Z
 DEC DE
 XOR A        ;nul byte naar achtergrond geheugen
 CALL diskbyt ;deze subroutine wordt ook door outincad aangeroepen
 JR nexttek

aequ: CALL getadr
 BIT 0,(IX+fase)
 RET NZ  ;fase 2, terug
 BIT 0,(IX+lenlin) ;label?
 LD B,17
 JP Z,error   ;"Label mist"
 BIT 0,(IX+const)   ;1=relocatable
 JR NZ,okok2
 RES 7,(IY+1) ;constante labels zijn ook global
 SET 7,(IY+2)
okok2: LD (IY+6),E   ;verander waarde
 LD (IY+7),D
 RET

aorg: CALL getadr
 LD (MP),DE
 BIT 7,(IX+mode)
 RET NZ
 SET 7,(IX+mode)
 LD (start),DE
 RET

aglobal:
 LD B,17
aglobal1: LD A,(HL)
 CP &HC0
 JP NZ,error
 INC HL
 LD E,(HL)
 INC HL
 LD D,(HL)
 INC HL
 EX DE,HL
 CALL berplace
 INC HL
 INC HL
 SET 7,(HL)    ;3e letter+128 = label is global
 EX DE,HL
 LD A,(HL)
 CP 2
 RET C
 JP NZ,operr
 INC HL
 JR aglobal1

ainclude: POP AF    ;INCLUDE "FILENAAM"
 BIT 0,(IX+fase)
;Bij een include moeten de PRN en de BIN file open blijven.
;eerst de 2e fase doen, daarna de andere file lezen.
 JR Z,tofase2
 PUSH HL
 LD HL,(diskbuf)
 DEC HL
 LD (HL),255
 LD (diskbuf),HL
 LD DE,(beglabel)
 LD HL,(eindtxt) ;labeltabel zo hoogmogelijk verschuiven.
 DEC HL
glolus:
 RST &H20
 JR Z,klaarglo
 LD BC,6
 AND A
 SBC HL,BC
 BIT 7,(HL)
 DEC HL
 DEC HL
 JR Z,glolus
 INC C
 ADD HL,BC
 INC C     ;C=8
 PUSH DE
 LD DE,(diskbuf)
 DEC DE
 LDDR
 INC DE
 LD (diskbuf),DE
 POP DE
 INC HL
 JR glolus
klaarglo: POP HL
 CALL iload   ;laad programma in
 CALL zerolab ;wis labels
 LD HL,(diskbuf)
lablus: LD A,(HL)
 INC A
 JR Z,klglo1
 LD C,6
 PUSH HL
 CALL zoeklab     ;zoek label op HL, lengte C, nummer in HL
 PUSH AF
 CALL berplace
 EX DE,HL
 POP AF
 POP HL
 LD BC,8
 LDIR
 JR NC,lablus
 LD A,255
 LD (DE),A
 INC DE
 LD (eindtxt),DE
 JR lablus
klglo1:
 INC HL
 LD (diskbuf),HL
 LD HL,(MP)
 JP nextass    ;regel op nul enz. MP en start niet

aend: POP AF             ;assembleer instructie END
aend1: BIT 0,(IX+fase)
 JR NZ,klaarass
;fase = 1
tofase2: INC (IX+fase)
 JP beginass     ;weer naar begin
klaarass:
 CALL linefeed
 BIT reloca,(IX+asmflag)
 JR Z,norel2
 LD HL,(pagadr)
 LD A,&HFF
 CALL brebyte
 INC HL
 LD A,&HFF
 CALL brebyte
 CALL print$
 DM "Relocatie-tabel eindigt op:"+0
 CALL printalf
norel2:
 BIT savml,(IX+asmflag)
 LD DE,filebuf2
 CALL NZ,closef
 BIT prnf,(IX+asmflag)
 LD DE,filebuf1
 CALL NZ,closeasc
 CALL print$
 DM "Begin:"+0
 LD HL,(start)
 CALL printadr
 CALL print$
 DM "  Einde:"+0
 LD HL,(MP)
 DEC HL
;Assembleren is klaar!!!
printalf: CALL printadr
 CALL linefeed
 RET

janee: PUSH AF
 CALL print$
 DM "? (J/N) "+0
 POP AF
 LD A,"J"
 JR C,okjn
 LD A,"N"
okjn: LD D,A
 CALL symbol
 CALL chput
 LD A,8
 CALL chput
othkey: CALL getkey
 CP 13
 JR NZ,okjn
 LD A,D
 AND &HDF
 CP "J"
 SCF
 JR Z,linf
 CP "N"
 JR NZ,othkey
linf: JP linefeed

setasm: LD HL,jnques   ;stel vragen aan de gebruiker
 BIT 0,(IX+prt)
 PUSH AF
 CALL printoff
 LD E,(IX+asmflag)
 LD C,5   ;5 vragen
nextque: CALL strout
 RR E
 CALL janee
 RL E
 RRC E
 DEC C
 JR NZ,nextque
 RRC E
 RRC E
 RRC E
 LD (IX+asmflag),E
;de bits van deze flag:
listf: EQU 0      ;listing uitdraaien?
prnf:  EQU 1      ;prn-file naar disk?
memof: EQU 2      ;ML naar geheugen?
savml: EQU 3      ;ML naar disk?
reloca: EQU 4     ;relocatie tabel in geheugen zetten?
 BIT prnf,E
 JR Z,noprn
 CALL print$
 DM "Geef ascii filenaam: "+0
 LD DE,filebuf1
 CALL inpfile
 CALL creafil
noprn: BIT savml,(IX+asmflag)
 JR Z,nosave
 CALL print$
 DM "Geef mcode filenaam: "+0
 LD DE,filebuf2
 CALL inpfile
 CALL creafil
nosave: POP AF
 CALL NZ,printon
 RET

jnques: DM "Listing afdrukken"+0
 DM "Ascii listing naar disk"+0
 DM "Mcode in geheugen zetten"+0
 DM "Mcode programma naar disk"+0
 DM "Relocatie-tabel in geheugen"+0

inpfile: LD BC,(&HF3DD)
 LD A,(IX+width)
 SUB C
 LD HL,tekstbuf+1
 LD B,0
 LD (HL),B
 DEC HL
 LD (HL),A
 CALL input
 INC HL
 JP filesyn

iasm: LD A,(HL)
 CP &H22
 CALL Z,iload ;inladen
ASSEMBLE:
 CALL setasm
 LD (IX+mode),8
 CALL zerolab
 LD HL,0
 LD (start),HL
 LD (pagadr),HL
nextass:
 LD (OLDMP),HL
 LD (IX+fase),0
beginass: LD HL,(OLDMP)
 LD (MP),HL
 LD HL,0
 LD (regel),HL
 LD HL,(beginbuf)
 INC HL
 LD (lastadr),HL
begasm:                   ;assembleer regel tekst
 LD HL,(regel)
 INC HL
 LD (regel),HL
 AND A
 BIT 0,(IX+fase)
 JR Z,nogf1
 CALL addrmake  ;maak adres klaar in geheugen.
 LD A,(IX+asmflag)
 AND 3
 JR Z,nogf1
 CALL getasc
 JR nonogf1
nogf1: LD HL,buffer1
 CALL getlin
; op &HF55E+18 staat de regel indien nodig.
nonogf1: JP C,aend1 ;klaar
 CALL asmreg
 LD A,(HL)
 CP 2
 JP NC,operr
 BIT 0,(IX+fase)
 CALL NZ,outpreg  ;regel uitvoeren
 JR begasm

addrmake: LD A,(IX+asmflag)
 AND 3
 RET Z
 PUSH DE
 PUSH HL
 LD (IX+dirkol),4
 CALL maakadr
 POP HL
 POP DE
 RET
hexbad: LD B,A
 LD A,(IX+asmflag)
 AND 3
 RET Z
 PUSH DE
 LD A,(IX+dirkol)
 AND A
 JR NZ,okhexbad
 PUSH BC
 CALL outpreg   ;voer regel uit
 CALL addrmake
 POP BC
okhexbad: DEC (IX+dirkol)
 LD A,B
 CALL hextobuf
 POP DE
 RET
outpreg: LD A,(IX+asmflag)
 AND 3
 RET Z
 PUSH HL
 CALL mendadr
 LD HL,addrbuf
 PUSH HL
 LD DE,filebuf1
 BIT 1,(IX+asmflag)
 CALL NZ,brereg1
 POP HL
 BIT 0,(IX+asmflag)
 JR Z,noouts
 CALL strout
 CALL linefeed
 CALL keywait
noouts: XOR A
 LD (tekstbuf),A  ;vernietig regel in buffer.
 POP HL
 RET

diskbyt: BIT savml,(IX+asmflag)  ;schrijf byte naar disk
 RET Z
 PUSH DE
 PUSH AF
 LD DE,filebuf2
 CALL bretek
 POP AF
 POP DE
 RET

outincad:
;Deze routine stuurt een byte naar het achtergrond geheugen.
 PUSH HL
 LD HL,(MP)
 BIT 0,(IX+fase)
 JR Z,incmplen
 PUSH BC
 BIT 2,(IX+asmflag)
 PUSH AF
 CALL NZ,brebyte  ;byte naar geheugen.
 POP AF
 CALL diskbyt     ;byte naar disk
 CALL hexbad      ;hex. byte voor regel
 POP BC
incmplen: INC HL
 LD (MP),HL     ;machine pointer
 POP HL
 RET

ilab:             ;label-routine
 LD A,12
 BIT 0,(IX+dechex)
 JR NZ,okdec
 LD BC,(hexlen)
 ADD A,B
 ADD A,C
 DEC A
okdec: LD (IX+kolbre),A
 LD (IX+dirkol),0
 LD A,(HL)
 CP 34
 LD A,"*"
 LD DE,opbuf
 JR NZ,nolabd
 PUSH HL
 CALL getstr
 POP HL
 LD A,C
 AND A
 JR Z,nolabd
 CP 7
 JP NC,operr
 XOR A
 LD B,A
 INC HL
 LDIR
nolabd:
 LD (DE),A
 LD HL,(beglabel)
labellus: CALL nextkol
 CALL getlab
 JP C,linefeed
 CALL nextkol1
 JR labellus

getlab: LD A,(HL) ;haal label
 ADD A,1
 RET C
 LD B,6
 LD DE,opbuf
 PUSH HL
labzklus: LD A,(DE)
 CP "*"       ;rest altijd ok?
 JR Z,rightlab
 CP "?"
 JR Z,skip    ;teken overslaan
 AND A
 JR Z,hlend
 SUB (HL)
 ADD A,A
 JR NZ,nextnok
skip: INC HL
 INC DE
 DJNZ labzklus
hlend: DEC B
 JP M,rightlab
 LD A,(HL)
 AND &H7F
 JR Z,rightlab
nextnok: POP HL
 LD BC,8
 ADD HL,BC
 JR getlab
rightlab: POP DE
 PUSH DE
 PUSH DE
 POP IY
 LD A,(IX+optie)
 CP "G"
 JR NZ,noglob1
 BIT 7,(IY+2)
 JR Z,nextnok
noglob1: CP "C"
 JR NZ,labok
 BIT 7,(IY+1)
 JR NZ,nextnok
labok:
 LD HL,tekstbuf
 LD B,6
nkr: LD A,(DE)
 INC DE
 AND &H7F
 JR Z,labhad
 LD (HL),A
 INC HL
 DJNZ nkr
labhad:
 LD A,7
 CALL tabula
 BIT 7,(IY+0)
 JR Z,labnodef
 LD E,(IY+6)
 LD D,(IY+7)
 CALL tokadr
labnodef: LD A,(IX+kolbre)
 INC A
 CALL tabula
 DEC HL
 LD (HL),0
 CALL bufout
 POP HL
 LD BC,8
 ADD HL,BC
 RET
