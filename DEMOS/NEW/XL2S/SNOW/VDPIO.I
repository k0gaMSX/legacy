; vdp i/o functies          


  module VDP


@SetWriteN         ; in: a - 16k blok, hl - adres in blok
  di
  out (99h),a
  ld a,14+128
  out (99h),a
  ld a,l
  out (99h),a
  ld a,64
  or h
  out (99h),a
  ei
  ret

@SetWriteN16        ; in: hl - adres in 16k blok
  di
  ld a,l
  out (99h),a
  ld a,64
  or h
  out (99h),a
  ei
  ret

@VDPChangeColor        ; in: ddee - RB G kleurnummer in a
  di
  out (99h),a
  ld a,16+128
  out (99h),a
  ld c,9ah
  out (c),d
  out (c),e
  ei
  ret

@VDPChangePallette        ; in: hl - pointer naar 32bytes
  di
  xor a
  out (99h),a
  ld a,16+128
  out (99h),a
  ld bc,209ah
  otir
  ei
  ret

@VDPClearColors
  ld b,16
  ld de,0
1 ld a,b
  dec a
  call VDPChangeColor
  dec b
  ret z
  jp 1b

@CopyHMMM 	          ;in: hl - Copylist
  ld bc,(128+17)*256+99h
  ld a,32
  di
  out (c),a
  out (c),b
  ld bc,12*256+9bh
  ei
1 in a,(99h)
  bit 0,a
  jr nz,1b
  otir
  di
  ld bc,(128+46)*256+99h
  ld a,11010000b
  out (c),a
  out (c),b
  ei
  ret

@CopyLMMM               ;in: hl - Copylist
  ld bc,(128+17)*256+99h
  ld a,32
  di
  out (c),a
  out (c),b
  ld bc,12*256+9bh
  ei
1 in a,(99h)
  bit 0,a
  jr nz,1b
  otir
  di
  ld bc,(128+46)*256+99h
  ld a,10011000b
  out (c),a
  out (c),b
  ei
  ret

@CopyYMMM               ;in: hl - Copylist
  ld bc,(128+17)*256+99h
  ld a,32
  di
  out (c),a
  out (c),b
  ld bc,12*256+9bh
  ei
1 in a,(99h)
  bit 0,a
  jr nz,1b
  otir
  di
  ld bc,(128+46)*256+99h
  ld a,11100000b
  out (c),a
  out (c),b
  ei
  ret

@BlockFill	;in: hl - lijst 11 bytes
  ld bc,+(128+17)*256+99h
  ld a,36
  di
  out (c),a
  out (c),b
  ld bc,11*256+9bh
  ei
1 in a,(99h)
  bit 0,a
  jr nz,1b
  otir
  ret

