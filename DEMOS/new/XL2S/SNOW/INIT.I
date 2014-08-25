;Initialisatie

  module init

all
  call VDPClearColors

  ld bc,12*256+99h                ;Video instellen
  ld hl,vdpregtabscr5
  xor a
  ld d,17+128
  di
  out (c),a
  out (c),d
  ld c,9bh
  otir
  ei

  ld a,2
  ld hl,0
  call SetWriteN

  ld hl,snow.sc5GFX		; plaatje naar vram
  ld bc,98h
  ld a,88
1 otir
  dec a
  jr nz,1b

  ld a,1
  ld hl,2000h
  call SetWriteN

  ld hl,SnowSprPat	; sprites definieren
  ld bc,(24*256)+98h
  otir

  ld hl,2800h
  call SetWriteN16
  ld a,0dh		; sprites kleuren 
  ld bc,2
1 out (98h),a
  djnz 1b
  dec c
  jr nz,1b

  ld b,120
1 halt		; Wait 2 seconds until drive stopped spinning!
  djnz 1b
  call ppInit	; innitiate own routine

  halt
 
  ld hl,ClearPage0	; scherm opbouwen
  call BlockFill
  call CopyYMMM

  call RandomSnow
  call control.SetSprites

  halt
  ld hl,KleurTabel		; kleuren instellen
  call VDPChangePallette

  ret

RandomSnow
  ld b,32			; "random" positie vlokjes 
  ld de,12
  ld ix,VlokjesTabel
2 call random
  ld (ix+1),a
  call random
  cp 144
  jr c,1f
  sub 144
1 add a,15
  ld (ix+3),a
  add ix,de
  djnz 2b
  ret

random
  ld a,r
  add a,h
  ld l,a
  add (hl)
  ret

ClearPage0
  byte 0,0,0,0,0,1,192,0,0ffh,0,11000000b 

; LogoToPage0
  byte 0,0,0,1,0,0,16,0,0,1,144,0

vdpregtabscr5
  byte 00000110B  ; 0                                 screen 5
  byte 01100000B  ; 1
  byte 00011111B  ; 2  pattern name
  byte 0          ; 3  color table low
  byte 00000000B  ; 4  pattern generator
  byte 11010111B  ; 5  sprite attribute low
  byte 00001100B  ; 6  sprite generator
  byte 0fh        ; 7  txt color & bck clr
  byte 00101000B  ; 8  vrs?? (bit2,3) bit1-spd
  byte 00000000B  ; 9  dot clock direction?? (bit0)
  byte 0          ; 10 color table high     
  byte 0          ; 11 sprite attribute high

KleurTabel
  ;    r    b g
  byte 0*16+2,0
  byte 4*16+6,4
  byte 3*16+5,3
  byte 2*16+4,2
  byte 1*16+3,1
  byte 0*16+3,0
  byte 4*16+7,7
  byte 2*16+4,4
  byte 0*16+1,1
  byte 1*16+2,2
  byte 2*16+3,3
  byte 3*16+4,4
  byte 5*16+6,6
  byte 7*16+7,7
  byte 5*16+7,5
  byte 0*16+0,0

SnowSprPat
  byte 11100000b
  byte 11100000b
  byte 11100000b
  byte 00000000b
  byte 00000000b
  byte 00000000b
  byte 00000000b
  byte 00000000b

  byte 11000000b
  byte 11000000b
  byte 00000000b
  byte 00000000b
  byte 00000000b
  byte 00000000b
  byte 00000000b
  byte 00000000b

  byte 10000000b
  byte 00000000b
  byte 00000000b
  byte 00000000b
  byte 00000000b
  byte 00000000b
  byte 00000000b
  byte 00000000b
