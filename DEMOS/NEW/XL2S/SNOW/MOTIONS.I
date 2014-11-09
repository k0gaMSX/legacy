; Motion calculations

  module motion

snowfall		; main snowfall routine
  ld b,32		; 32 sprites
  ld ix,VlokjesTabel
  ld de,12
1 exx
  call lowWindTurb
  call accelerations
  call velocities
  call move
  exx
  add ix,de
  djnz 1b
  ret

lowWindTurb	; creates small turbulances
  ld a,r
  ld (FxWind),a
  ld a,r
  xor (ix+0)
  ld (FyWind),a
  ret

accelerations	; F  = m * a
		; fw = c * v * v ; c-correction factor
		; (F ± fw)/m = a     ; m = 1

  ld l,(ix+4)	; velocity x component
  ld h,(ix+5)
  ld e,l	; de = hl
  ld d,h

  bit 7,h	; negative direction?
  jr z,.Fxsubfw
  
  call verm16	; v*v

  sra l		; Hmmm?
  rr h
  rr h
  rr l
  sra h		; c factor 
 
  ld de,(FxWind)  ; Wind Forche x
  add hl,de	  ; a = Sum F 

  ld (ix+8),h	; store ax
  jp .accelyComp

.Fxsubfw
  call verm16	; v*v

  sra l		; Hmmm?
  rr h
  rr h
  rr l
  sra h		; c factor

  ld de,(FxWind)  ; Wind Forche x
  ex de,hl
  sbc hl,de	  ; Sum F 

  ld (ix+8),h	; store ax

.accelyComp	; 
		; m g + F ± fw = a     ; m = 1
  ld hl,(FyWind)
  ld de,10*256+127	; Forche of gravity
  add hl,de
  push hl	; g + F

  ld l,(ix+6)	; velocity y component
  ld h,(ix+7)
  ld e,l	; de = hl
  ld d,h

  bit 7,h	; negative direction?
  jr z,.Fysubfw

  call verm16	; v*v

  sra l		; Hmmm?
  rr h
  sra h		; c factor
  rr l

  pop de	; g + F
  add hl,de	; Sum F

  ld (ix+9),h	; Store ay
  ret

.Fysubfw
  call verm16	; v*v

  sra l		; Hmmm?
  rr h
  sra h		; c factor
  rr l

  pop de	; g + F
  ex de,hl
  sbc hl,de	; Sum F

  ld (ix+9),h	; Store ay
  ret

velocities	; V = V0 + a
  ld l,(ix+4)	; Vx
  ld h,(ix+5)
  ld e,(ix+8)	; ax
  ld d,0
  rl e
  jr nc,1f	; negative?
  dec d		; true: d -> -1
1 add hl,de
  ld a,h

  or a		; Max velocity restriction x
  jp s,1f
  cp 5
  jr c,2f
  ld a,4
  jp 2f
1 cp -5
  jr nc,2f	; nc instead of c!
  ld a,-4
2
  ld (ix+4),l	; Store new velocity x
  ld (ix+5),a

  ld l,(ix+6)	; Vy
  ld h,(ix+7)
  ld e,(ix+9)	; ay
  ld d,0
  bit 7,e	; negatief?
  jr z,1f
  dec d		; true: d -> -1
1 add hl,de
  ld a,h

  or a		; Max velocity restriction y
  jp s,1f
  cp 4
  jr c,2f
  ld a,3
  jp 2f
1 cp -4
  jr nc,2f	; nc instead of c! 
  ld a,-3
2
  ld (ix+6),l	; Store new velocity y
  ld (ix+7),a

  ret

move
  ld l,(ix+0)	; px in hl
  ld h,(ix+1)
  ld e,(ix+4)	; Vx in de
  ld d,(ix+5)
  add hl,de
  ld (ix+0),l
  ld (ix+1),h

  ld l,(ix+2)	; py in hl
  ld h,(ix+3)
  ld e,(ix+6)	; Vy in de
  ld d,(ix+7)
  add hl,de

  ld a,h	; warp around!
  cp 15
  jr nc,1f  
  ld h,144+14
1 cp 144+15
  jr c,1f
  ld h,15
1 ld (ix+2),l
  ld (ix+3),h
  ret

verm16		;in: hl,de  uit: hl = hl*de
  ld b,8
1 add a,a
  sla h
  jr nc,2f
  add a,e
2 djnz 1b
  ld h,a
  ld a,l
  ld l,h
  ld b,8
1 add hl,hl
  add a,a
  jr nc,2f
  add hl,de
2 djnz 1b
  ret

@VlokjesTabel		;(32*12)
;      			; p- position (x,y) | V -velocities (x,y) 
;      -p- -V- a  s	; a- accelarations (l-x h-y) | s- size
  word 0,0,0,0,0,0
  word 0,0,0,0,0,0
  word 0,0,0,0,0,0
  word 0,0,0,0,0,0
  word 0,0,0,0,0,0
  word 0,0,0,0,0,0
  word 0,0,0,0,0,0
  word 0,0,0,0,0,0
  word 0,0,0,0,0,0
  word 0,0,0,0,0,0

  word 0,0,0,0,0,1
  word 0,0,0,0,0,1
  word 0,0,0,0,0,1
  word 0,0,0,0,0,1
  word 0,0,0,0,0,1
  word 0,0,0,0,0,1
  word 0,0,0,0,0,1
  word 0,0,0,0,0,1
  word 0,0,0,0,0,1
  word 0,0,0,0,0,1

  word 0,0,0,0,0,2
  word 0,0,0,0,0,2
  word 0,0,0,0,0,2
  word 0,0,0,0,0,2
  word 0,0,0,0,0,2
  word 0,0,0,0,0,2
  word 0,0,0,0,0,2
  word 0,0,0,0,0,2
  word 0,0,0,0,0,2
  word 0,0,0,0,0,2
  word 0,0,0,0,0,2
  word 0,0,0,0,0,2

FxWind
  word 0

FyWind
  word 0

