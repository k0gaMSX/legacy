; Interrupt routine en stick uitlezer

  module interrupt

@Interrupt
  push af
  xor a
  out (99h),a
  ld a,15+128
  out (99h),a

  in a,(99h)

  ld a,2
  out (99h),a
  ld a,15+128
  out (99h),a

  ld (INT),a

  pop af
  ei
  ret

@INT
  byte 0

@ppInit
  di
  ld hl,(39h)
  ld (_oudeinterrupt),hl
  ld hl,Interrupt
  ld (39h),hl
  ei
  ret

@ppExit
  di
  ld hl,(_oudeinterrupt)
  ld (39h),hl
  ei
  ret

_oudeinterrupt
  .word 0

@GetStick	; uit: b- |r|d|u|l|-|-|1|0|
  ld hl,Row7
  in a,(0aah)
  ld c,a
  and 240
  or 7
  ld b,a
  out (0aah),a
  in a,(0a9h)
  cpl
  ld (hl),a
  inc b
  ld a,b
  out (0aah),a
  in a,(0a9h)
  cpl
  inc hl
  ld (hl),a
  ld a,c
  out (0aah),a

  in a,(0a2h)
  cpl
  bit 4,a
  jp z,1f
  set 0,(hl)
1 ld b,(hl)
  dec hl
  bit 5,a
  jp z,2f
  set 7,(hl)
2 and 15
  ld de,_gihtab
  ld h,0
  ld l,a
  add hl,de
  ld a,(hl)
  or b
  ld (Row8),a

  ld bc,(Row7)
  res 1,b
  bit 7,c
  jr nz,1f
  bit 2,c
  ret z
1 set 1,b
  ret

Row7
  byte 0
Row8
  byte 0

_gihtab
  byte 0
  byte 32
  byte 64
  byte 0
  byte 16
  byte 0
  byte 0
  byte 0
  byte 128
  byte 0
  byte 0
  byte 0
  byte 0
  byte 0
  byte 0
  byte 0
  byte 0
  byte 0
