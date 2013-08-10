GLOBAL  _initVMode,_exitVMode,_setPalette,_updateVideo,_vscr,_palptr

EXTERN _VDP,_VRAM,_videoseg,_sprcoll,_spr5th,_spr5thno,_chkfifth,_video

SECTION .text

%define leftScr 32
%define topScr  4
%define leftScr1 leftScr/4
%define topScr1  24

_updateVideo:
	push ebp
	mov edi,_VDP
	xor eax,eax
	mov al,[edi+7]
	and al,0x0F
	mov ebx,eax
	add ebx,ebx
	add ebx,eax
	mov esi,[_palptr]
	add esi,ebx
	mov al,16
	call setColor
	mov al,[edi+1]
	test al,0x40
	jz blankScreen
	and al,0x18
	mov bl,[edi]
	and bl,0x02
	or al,bl
	cmp al,0x02
	jz scr1
	cmp al,0x08
	jz scr2
	cmp al,0x10
	jz scr0
	cmp al,0x00
	jz scr3
blankScreen:
	mov edi,_vscr
	mov ecx,0x3000
	mov eax,0x10101010
	rep stosd
	jmp flipScreen

scr0:
  call screen0 
  jmp flipScreen	
scr1:
  call screen1
  call putSprites
  jmp flipScreen
scr2:
  call screen2
  call putSprites
  jmp flipScreen  
scr3:
	call screen3
	call putSprites
	jmp flipScreen
	
flipScreen:	
	push es
	mov ax,[_videoseg]
	mov es,ax
	
	cmp word [_video],0
	jnz modeXflip	
	mov edi,topScr*320+leftScr
	mov esi,_vscr
	mov bx,192
.flipRow:
	mov ecx,64
	rep movsd
	add edi,64
	dec bx
	jnz .flipRow
	jmp flipDone
modeXflip:
	mov edi,topScr1*80+leftScr1
	add edi,[actStart]
	mov esi,_vscr
	mov dx,0x03C4
	mov cl,64
.nextNibble:
	mov ax,0x0102
	mov ch,4
.nextCol:
	out dx,ax
	mov bl,192
.flipLoop:
	movsb
	add esi,255
	add edi,79
	dec bl
	jnz .flipLoop
	sub esi,49151
	sub edi,15360
	shl ah,1
	dec ch
	jnz .nextCol
	inc edi
	dec cl
	jnz .nextNibble
	mov eax,[visPage]
	push eax
	mov eax,[actPage]	
	call setVisiblePage
	pop eax
	call setActivePage	
flipDone:
	pop es
	pop ebp
	ret

screen0:
	mov edi,_vscr
	mov bx,192
	mov eax,0x10101010
.frameLoop:
	stosd
	stosd
	add edi,240
	stosd
	stosd
	dec bx
	jnz .frameLoop

	mov edi,_VDP
	mov al,[edi+7]
	mov bl,al
	and bl,0x0F
	shr al,4
	jnz .notTransparent
	mov al,bl
.notTransparent:	
 	mov [fg],al
 	mov [bg],bl	
	xor eax,eax	
	mov al,[edi+4]
	and al,0x07
	shl eax,11
	xor ebx,ebx
	mov bl,[edi+2]
	and bl,0x0F
	shl ebx,10	
 	; eax = Pattern Generator
 	; ebx = Name Table
 	mov edi,_vscr+8
 	mov esi,_VRAM
 	mov edx,esi
 	add esi,ebx
 	add edx,eax
 	; edi -> _vscr
 	; esi -> NameTable
 	; edx -> Pattern Generator 	
	mov cl,24
.newLine:
	mov ch,40
.nextChar:
	push cx
	xor eax,eax
	lodsb
	shl eax,3
	add eax,edx
	mov ebx,eax
	mov ch,8
.nextCharLine:
	mov al,[ebx]
	inc ebx
	mov cl,6
.nextCharPxl:
	mov ah,[fg]
	rcl al,1
	jc .putPixel
	mov ah,[bg]
.putPixel:
	mov [edi],ah
	inc edi	
	dec cl
	jnz .nextCharPxl
	add edi,250
	dec ch
	jnz .nextCharLine
	add edi,-2042
	pop cx
	dec ch
	jnz .nextChar
	add edi,1808
	dec cl
	jnz .newLine
	ret

screen1:
	movzx ax,byte [edi+2]
	and al,0x0F
	shl ax,10
	mov [nameTbl],ax
	movzx ax,byte [edi+3]
	and al,0x80
	shl ax,6
	mov [colTbl],ax
	movzx ax,byte [edi+4]
	and al,0x04
	shl ax,11
	mov [patGen],ax
	
	mov edi,_vscr
	mov esi,_VRAM
	xor edx,edx
	mov cl,24
.nextBlockLine:
	mov ch,32
.nextBlock:
	mov ebx,edx
	add bx,[nameTbl]
	mov eax,0x1800
	mov al,[esi+ebx]
	inc edx
	push edx
	push esi
	sub ah,cl
	shr ah,3
	shl ax,3
	add esi,eax
	mov dl,8
.nextPattern:
	movzx ebx,word [patGen]
	mov al,[esi+ebx]
	movzx ebx,word [colTbl]
	mov bl,[esi+ebx]
	inc esi
	mov dh,8
	mov bh,bl
	and bl,0x0F
	jnz .checkOther
	mov bl,16
.checkOther:
	shr bh,4
	jnz .nextBit
	mov bh,16
.nextBit:
	mov ah,bh
	rcl al,1	
	jc .putPixel
	mov ah,bl
.putPixel:
	mov [edi],ah
	inc edi
	dec dh
	jnz .nextBit
	add edi,248
	dec dl
	jnz .nextPattern
	add edi,-2040
	pop esi
	pop edx
	dec ch
	jnz .nextBlock
	add edi,1792
	dec cl
	jnz .nextBlockLine
	ret
	
screen2:
	mov edi,_vscr
	mov esi,_VRAM
	mov cl,6
.nextBlockLine:
	mov ch,32
.nextBlock:
	mov dl,8
.nextPixel:
	lodsb
	mov bl,al
	shr al,4
	jnz .notTransparent
	mov al,16
.notTransparent:
	and bl,0x0F
	jnz .putPixels
	mov bl,16
.putPixels:
	mov ah,al
	mov bh,bl
	push ax
	push bx
	shl eax,16
	shl ebx,16
	pop bx
	pop ax
	mov [edi+0x000],eax
	mov [edi+0x004],ebx
	mov [edi+0x100],eax
	mov [edi+0x104],ebx
	mov [edi+0x200],eax
	mov [edi+0x204],ebx
	mov [edi+0x300],eax
	mov [edi+0x304],ebx
	add edi,0x400
	dec dl
	jnz .nextPixel
	add edi,-8184
	dec ch
	jnz .nextBlock
	add edi,0x1F00
	dec cl
	jnz .nextBlockLine
	ret
	
screen3:
	mov al,[edi+7]
	and al,0x0F
	mov [bg],al
	mov esi,_VRAM
	movzx ebp,byte [edi+3]	
	shl ebp,6
	add ebp,esi
	movzx edx,byte [edi+4]
	and dl,0x07	
	shl dx,11
	add edx,esi
	movzx eax,byte [edi+2]
	and al,0x0F
	shl ax,10
	add esi,eax
	mov edi,_vscr

	; edi -> _vscr		
	; esi -> Name Table
	; ebp -> Color Table
	; edx -> Pattern Generator
	
	mov cl,24
.newLine:
	mov ch,32
.nextChar:
	push ecx	
	xor eax,eax
	lodsb
	push esi
	mov ebx,eax
	shr ebx,3
	mov cl,[ebp+ebx]
	add ebx,ebp
	shl eax,3
	add eax,edx
	mov esi,eax
	mov al,cl
	and al,0x0F
	jnz .bgnottp
	mov al,[bg]

.bgnottp:
	mov bl,al
  shr cl,4
  jnz .fgnottp
  mov cl,[bg]
.fgnottp:	
	mov bh,cl
	
	; esi -> font for current letter
		
	mov ch,8
.nextCharLine:
	lodsb
	mov cl,8
.nextCharPxl:
	mov ah,bh
	rcl al,1
	jc .putPixel
	mov ah,bl
.putPixel:
	mov [edi],ah
	inc edi	
	dec cl
	jnz .nextCharPxl
	add edi,248
	dec ch
	jnz .nextCharLine	
	add edi,-2040
	pop esi
	pop ecx
	dec ch
	jnz .nextChar
	add edi,1792
	dec cl
	jnz .newLine
	ret

; Sprite Attribute Table
;
;
; 0 y-position (D0 = end of sprites)
; 1 x-position
; 2 nummer
; 3 color (bit 0-3)
;   x flag (bit 7) (-32 if set)

putSprites:
	mov edi,sprscr
	mov ecx,0x3030
	xor eax,eax
	rep stosd	
	mov [curspr],al
	mov [_sprcoll],al
	mov	[_spr5th],al
	mov esi,_VRAM
	mov edi,_VDP
	xor ebx,ebx
	mov bl,[edi+5]	
	and bl,0x7F
	shl ebx,7
	mov ebp,ebx
	mov cx,32
.psLoop:
	mov	edi,_VDP
	push ebp
	push ecx
	xor eax,eax	
	xor ebx,ebx
	xor ecx,ecx
	movzx edx,byte [esi+ebp]
	cmp dl,0xD0
	jz near .endofsprites
	inc edx
	cmp edx,192
	jc .posY
	movsx edx,dl
.posY:
	movzx ecx,byte [esi+ebp+1]
	mov al,[esi+ebp+3]	
	and al,0x80
	shr al,2
	sub ecx,eax
	mov al,[esi+ebp+3]
	and al,0x0F
	mov bl,[esi+ebp+2]
	mov ah,[edi+1]
	bt ax,9
	jnc .noBigSpr
	and bl,0xFC
.noBigSpr:
	shl bx,3
	push eax
	xor ax,ax
	mov al,[edi+6]
	and al,7
	shl ax,11
	add bx,ax
	pop eax	
	bt ax,8
	jc .magnify
	bt ax,9
	jc .nmBigSpr		
	mov ah,8
	call putSprite
	jmp .nextSprite
.nmBigSpr:
	mov ah,16
	push eax
	push ebx
	push ecx
	push edx
	call putSprite
	pop edx
	pop ecx
	pop ebx
	pop eax
	add ecx,8
	add bx,16
	call putSprite
	jmp .nextSprite
.magnify:
	bt ax,9
	jc .nmBigMagSpr
	mov ah,16
	call putMagSprite
	jmp .nextSprite
.nmBigMagSpr:
	mov ah,32
	push eax
	push ebx
	push ecx
	push edx
	call putMagSprite
	pop edx
	pop ecx
	pop ebx
	pop eax
	add ecx,16
	add bx,16
	call putMagSprite
.nextSprite:
	pop	ecx
	pop ebp
	add ebp,4
	inc byte [curspr]
	dec cx
	jnz near .psLoop
	ret
.endofsprites:
	add	esp,8
	ret

putSprite:
	; al=col, ah=lines, ebx=sprVRAMOfs, ecx=x, edx=y, esi->VRAM, edi->_vscr
	mov [color],al
	mov ebp,edx
	shl ebp,8
	add ebp,ecx
	mov al,ah
	shr al,1
	or al,[_chkfifth]
	mov [maxline],al
.putLine:
	push ebx	
	cmp edx,192
	jnc near .nextLine	
	mov edi,linecnt
	mov al,[maxline]
	cmp byte [edi+edx],al
	jnz .not5th
	mov byte [_spr5th],1
	mov al,[curspr]
	mov [_spr5thno],al
	jmp .nextLine
.not5th:
	inc byte [edi+edx]	
	mov bl,[esi+ebx]
	or bl,bl
	jz .nextLine	
	push ebp
	push ecx
.chkPixel:
	cmp ecx,256
	jge .lineDone
	shl bl,1
	jnc .nextPixel
	bt ecx,31
	jc .nextPixel
	mov edi,sprscr
	cmp byte [edi+ebp],0
	jz .noColl
	mov byte [_sprcoll],1
	cmp byte [edi+ebp],1
	jnz .nextPixel
.noColl:
	mov al,[color]
	inc al
	mov [edi+ebp],al
	dec al 
	jz .nextPixel	
	mov edi,_vscr
	mov [edi+ebp],al
.nextPixel:
	inc ecx
	inc ebp
	jmp .chkPixel
.lineDone
	pop ecx
	pop ebp
.nextLine:
	add ebp,0x100
	inc edx
	pop ebx
	inc ebx
	dec ah
	jnz near .putLine
	ret

putMagSprite:
	; al=col, ah=lines, ebx=sprVRAMOfs, ecx=x, edx=y, esi->VRAM, edi->_vscr
	mov [color],al
	mov ebp,edx
	shl ebp,8
	add ebp,ecx
	mov al,ah
	shr al,2
	or al,[_chkfifth]
	mov [maxline],al
.putLine:
	push ebx	
	cmp edx,192
	jnc near .nextLine	
	mov edi,linecnt
	mov al,[maxline]
	cmp byte [edi+edx],al
	jnz .not5th
	mov byte [_spr5th],1
	mov al,[curspr]
	mov [_spr5thno],al
	jmp .nextLine
.not5th:
	inc byte [edi+edx]	
	movzx ebx,byte [esi+ebx]
	or ebx,ebx
	jz .nextLine	
	
	push eax
	mov eax,ebx
	and bl,0x0F
	shr eax,4
	mov edi,duptable
	mov bl,[edi+ebx]
	mov bh,[edi+eax]
	pop eax
	
	push ebp
	push ecx
.chkPixel:
	cmp ecx,256
	jge .lineDone
	shl bx,1
	jnc .nextPixel
	bt ecx,31
	jc .nextPixel
	mov edi,sprscr
	cmp byte [edi+ebp],0
	jz .noColl
	mov byte [_sprcoll],1
	cmp byte [edi+ebp],1
	jnz .nextPixel
.noColl:
	mov al,[color]
	inc al
	mov [edi+ebp],al
	dec al 
	jz .nextPixel	
	mov edi,_vscr
	mov [edi+ebp],al
.nextPixel:
	inc ecx
	inc ebp
	jmp .chkPixel
.lineDone
	pop ecx
	pop ebp
.nextLine:
	add ebp,0x100
	inc edx
	pop ebx	
	bt ax,8
	adc ebx,0
	dec ah
	jnz near .putLine
	ret

setColor:
	mov dx,0x03C8
	out dx,al	
	inc dx	
	lodsb
	shr al,2
	out dx,al
	lodsb
	shr al,2
	out dx,al
	lodsb
	shr al,2
	out dx,al
	ret	

_initVMode:
	mov ax,0x0013
	int 0x10

	mov esi,[_palptr]
	mov cx,16
	xor bx,bx
.setColors:
	mov ax,bx
	push esi
	call setColor
	pop esi
	mov ax,bx
	add ax,32
	call setColor
	inc bx
	dec cx
	jnz .setColors

	cmp word [_video],0
	jnz modeX

	push es
	mov ax,word [_videoseg]
	mov es,ax
	xor edi,edi
	mov ecx,64000
	xor al,al	
	rep stosb
	
	mov edi,(topScr-4)*320+leftScr-16
	mov bx,200
.scrLoop:
	mov al,16
	mov ecx,288
	rep stosb
	add edi,32
	dec bx
	jnz .scrLoop
	pop es
	ret
	
modeX:	
	mov dx,0x3C4
	mov ax,0x0604
	out dx,ax
	mov dx,0x3D4
	mov ax,0xE317
	out dx,ax
	mov ax,0x0014
	out dx,ax
	mov ax,0x0F02
	out dx,ax
	mov al,0xE3
	out dx,al
	mov ax,0x2C11
	out dx,ax
	mov ax,0x0D06
	out dx,ax
	mov ax,0x3E07
	out dx,ax
	mov ax,0xEA10
	out dx,ax
	mov ax,0xAC11
	out dx,ax
	mov ax,0xDF12
	out dx,ax
	mov ax,0xE715
	out dx,ax
	mov ax,0x0616
	out dx,ax
	
	push es
	mov ax,word [_videoseg]
	mov es,ax
	xor edi,edi
	mov ecx,65536
	xor al,al	
	rep stosb
	
	mov edi,(topScr1-12)*80+leftScr1-4	
	mov esi,(topScr1-12)*80+leftScr1-4+19200
	mov bx,216
.scrLoop:
	mov al,16
	mov ecx,72	
	rep stosb
	mov ecx,72
	xchg edi,esi
	rep stosb
	add edi,8
	add esi,8
	dec bx
	jnz .scrLoop
	pop es
	
	mov ax,0x0F02
	out dx,ax
	mov eax,1
	call setActivePage
	mov eax,0
	call setVisiblePage
	ret
	
setActivePage:
	mov [actPage],eax	
	mov edx,19200
	mul edx
	mov [actStart],eax
	ret

setVisiblePage:
	mov [visPage],eax
	mov edx,19200
	mul edx
	mov [visStart],eax
	mov bx,ax
	mov dx,0x3D4
	mov al,0x0C
	out dx,ax
	mov ah,bl
	mov al,0x0D
	out dx,ax
	ret
	
_exitVMode:
	mov ax,0003
	int 0x10
	ret
	
_setPalette:
	mov eax,[esp+4]
	mov ebx,48
	mul ebx
	add eax,SVIpal0
	mov [_palptr],eax
	ret	

SECTION .data

SVIpal0: ; default
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x20,0xC0,0x20,0x60,0xE0,0x60
	db 0x20,0x20,0xE0,0x40,0x60,0xE0,0xA0,0x20,0x20,0x40,0xC0,0xE0
	db 0xE0,0x20,0x20,0xE0,0x60,0x60,0xC0,0xC0,0x20,0xC0,0xC0,0x80
	db 0x20,0x80,0x20,0xC0,0x40,0xA0,0xA0,0xA0,0xA0,0xE0,0xE0,0xE0

SVIpal1:
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x02,0xC6,0x0C,0x24,0xFD,0x5A
	db 0x35,0x01,0xD1,0x80,0x80,0xFF,0xA8,0x37,0x0D,0x00,0xFF,0xFF
	db 0xD7,0x43,0x0B,0xFF,0x80,0x80,0xCE,0xCE,0x00,0xFF,0xE9,0x48
	db 0x01,0xA0,0x11,0xC0,0x00,0xC0,0xE0,0xE0,0xE0,0xFF,0xFF,0xFF
	
SVIpal2: ; black & white
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x55,0x55,0x55,0x8A,0x8A,0x8A
	db 0x60,0x60,0x60,0x80,0x80,0x80,0x4A,0x4A,0x4A,0xA0,0xA0,0xA0
	db 0x60,0x60,0x60,0x8A,0x8A,0x8A,0x8A,0x8A,0x8A,0xAA,0xAA,0xAA
	db 0x40,0x40,0x40,0x8A,0x8A,0x8A,0xA0,0xA0,0xA0,0xE0,0xE0,0xE0

duptable:
	db 0x00,0x03,0x0C,0x0F,0x30,0x33,0x3C,0x3F
	db 0xC0,0xC3,0xCC,0xCF,0xF0,0xF3,0xFC,0xFF

SECTION .bss

_vscr: 		resb 0xC000
sprscr:		resb 0xC000
linecnt:	resb 192
_palptr:	resd 1
curspr:   resb 1
maxline:  resb 1
color:		resb 1

fg:				resb 1
bg: 			resb 1
nameTbl:	resw 1
colTbl:		resw 1
patGen:		resw 1

actPage:  resd 1
actStart: resd 1
visPage:  resd 1
visStart: resd 1
