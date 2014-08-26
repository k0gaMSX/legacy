;Snowfall   use sjasm to assemble

  org 100h

  jp start

  include interrup.i
  include vdpio.i
  include init.i
  include motions.i
  include control.i

  module snow

@start
  call init.all
  ld a,16
  ld (control.WindDir),a
  
main
  call motion.snowfall
  call control.Stick
  call control.SetWind

  ld a,(STOP)
  or a
  jr nz,exit

  xor a
  ld (INT),a
1 ld a,(INT)
  or a
  jr z,1b

  call control.SetSprites
  call control.windIndicator

  jr main

exit
  call ppExit
  xor a
  ld ix,0d1h
  ld iy,(0faf7h)
  call 1ch
  ld ix,141h
  ld iy,(0faf7h)
  call 1ch
  ld ix,156h
  ld iy,(0fcc0h)
  call 1ch
  ld de,Txthoi
  ld c,9
  call 5
  ret

Txthoi
  byte "Snowfall challenge XL2S Entertainment$"

@STOP
  byte 0

sc5GFX
  incbin "snowfall.ge5",7,176*128

  end