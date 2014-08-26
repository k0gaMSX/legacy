; Stick control and Display routines

  module control

Stick
  call GetStick

  bit 1,b		
  jr nz,.exit

  bit 7,b
  jr nz,.right
  bit 4,b
  jr nz,.left
  ret
.right
  ld a,(WindDir)
  inc a
  and 31
  ld (WindDir),a
  ret  
.left
  ld a,(WindDir)
  dec a
  and 31
  ld (WindDir),a
  ret  
.exit
  ld a,1
  ld (STOP),a
  ret

SetSprites
  ld hl,2800h+512
  call SetWriteN16
  ld b,32
  ld de,12
  ld ix,VlokjesTabel
1 ld a,(ix+3)
  out (98h),a
  ld a,(ix+1)
  out (98h),a
  ld a,(ix+10)
  out (98h),a
  add ix,de
  out (98h),a
  djnz 1b
  ret

windIndicator		;Copy Wind Indicator
  ld hl,WindIndTabel
  call CopyHMMM
  ld a,(WindDir)
  ld b,a
  and 15
  add a,a
  add a,a
  add a,a
  add a,a
  ld (WindIndTabel+12),a
  ld a,b
  and 16
  add a,144
  ld (WindIndTabel+14),a
  call CopyLMMM
  ret

SetWind
  ld a,(WindDir)
  add a,a
  ld hl,WindTab
  add a,l
  jr nc,1f
  inc h
1 ld l,a
  ld a,(hl)
  inc hl
  ld (motion.FxWind+1),a
  ld a,(hl)
  ld (motion.FyWind+1),a
  ret

WindIndTabel
  byte 232,0,120,1,232,0,136,0,16,0,16,0
  byte 0,0,144,1,232,0,136,0,16,0,16,0

WindDir
  byte 0

WindTab
  byte 0,-18
  byte 12,-17
  byte 26,-17
  byte 30,-15
  byte 43,-13
  byte 45,-10
  byte 57,-6
  byte 57,-2

  byte 68,0
  byte 57,2
  byte 57,6
  byte 45,10
  byte 43,13
  byte 30,15
  byte 26,17
  byte 12,17

  byte 0,18
  byte -12,17
  byte -26,17
  byte -30,15
  byte -43,13
  byte -45,10
  byte -57,6
  byte -57,2

  byte -68,0
  byte -57,-2
  byte -57,-6
  byte -45,-10
  byte -43,-13
  byte -30,-15
  byte -26,-17
  byte -12,-17

