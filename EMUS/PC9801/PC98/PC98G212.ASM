# fMSX: portable MSX emulator *****************************
#                                                         *
#                      pc98g212.asm                       *
#                                                         *
# This file contains graphic drivers for PC-9821 series   *
# SVGA 640x480x256 graphic mode implementations.          *
#                                                         *
# fMSX   Copyright (C) Marat Fayzullin 1994,1995          *
# fMSX98 Copyright (C) MURAKAMI Reki 1995-1997            *
#     You are not allowed to distribute this software     *
#     commercially. Please, notify me, if you make any    *
#     changes to this file.                               *
#**********************************************************

	.file	"pc98g212.asm"

.macro MAG a1,a2
	movb	a2,%bl
	movb	a2,%bh
	bswapl	%ebx
	movb	a1,%bl
	movb	a1,%bh
.endm

.macro PUTDXY count
        movb    $(count)/8,%cl
	.align 4,0x90
0:	lodsl
	andl	%edx,%eax
	MAG		%al,%ah
	bswapl	%eax
        movl    %ebx,%fs:(%edi)
        movl    %ebx,%fs:640(%edi)
	MAG		%ah,%al
        movl    %ebx,%fs:4(%edi)
        movl    %ebx,%fs:644(%edi)
	addl	$8,%edi
	decb	%cl
	jne		0b
.endm

.macro PUTDXY8 count
        movb    $(count)/8,%cl
	.align 4,0x90
0:	lodsl
	MAG		%al,%ah
	bswapl	%eax
        movl    %ebx,%fs:(%edi)
        movl    %ebx,%fs:640(%edi)
	MAG		%ah,%al
        movl    %ebx,%fs:4(%edi)
        movl    %ebx,%fs:644(%edi)
	addl	$8,%edi
	decb	%cl
	jne		0b
.endm

.macro PUTDY count
        movb    $(count)/8,%cl
	.align 4,0x90
0:	lodsl
	andl	%edx,%eax
        movl    %eax,%fs:(%edi)
        movl    %eax,%fs:640(%edi)
	lodsl
	andl	%edx,%eax
        movl    %eax,%fs:4(%edi)
        movl    %eax,%fs:644(%edi)
	addl	$8,%edi
	decb	%cl
	jne		0b
.endm

.macro PUTDX count
        movb    $(count)/8,%cl
	.align 4,0x90
0:	lodsl
	andl	%edx,%eax
	MAG		%al,%ah
	bswapl	%eax
        movl    %ebx,%fs:(%edi)
	MAG		%ah,%al
        movl    %ebx,%fs:4(%edi)
	addl	$8,%edi
	decb	%cl
	jne		0b
.endm

.macro PUTDX8 count
        movb    $(count)/8,%cl
	.align 4,0x90
0:	lodsl
	MAG		%al,%ah
	bswapl	%eax
        movl    %ebx,%fs:(%edi)
	MAG		%ah,%al
        movl    %ebx,%fs:4(%edi)
	addl	$8,%edi
	decb	%cl
	jne		0b
.endm

.macro PUTD count
        movb    $(count)/8,%cl
	.align 4,0x90
0:	lodsl
	andl	%edx,%eax
        movl    %eax,%fs:(%edi)
	lodsl
	andl	%edx,%eax
        movl    %eax,%fs:4(%edi)
	addl	$8,%edi
	decb	%cl
	jne		0b
.endm

.macro PUTLXY cnty
        movb    $(cnty),%ch
	.align 4,0x90
1:	PUTDXY	640
	addl	$640,%edi
	decb	%ch
	jne		1b
.endm

.macro PUTLXY8 cnty
        movb    $(cnty),%ch
	.align 4,0x90
1:	PUTDXY8	640
	addl	$640,%edi
	decb	%ch
	jne		1b
.endm

.macro PUTLY cnty
        movb    $(cnty),%ch
	.align 4,0x90
1:	PUTDY	640
	addl	$640,%edi
	decb	%ch
	jne		1b
.endm

.macro PUTLX cnty
        movb    $(cnty),%ch
	.align 4,0x90
1:	PUTDX	640
	addl	$640,%edi
	decb	%ch
	jne		1b
.endm

.macro PUTL cnty
        movb    $(cnty),%ch
	.align 4,0x90
1:	PUTD	640
	addl	$640,%edi
	decb	%ch
	jne		1b
.endm

.macro CHGBANK bank
	movl	$(bank),%eax
	addl	%eax,%eax
        .byte   0x64                            #fs prefix
        movw    %ax,(0xe0004)
	incl	%eax
        .byte   0x64                            #fs prefix
        movw    %ax,(0xe0006)
	movl	$0x0f0f0f0f,%edx
.endm

.text

.globl	_PutImage21
	.align 4,0x90
_PutImage21:
	pushl	%ebp
	pushl	%esi
	pushl	%ebx
        movl    16(%esp),%esi
	movw	_wConvMemSelector, %ax
        movw    %ax,%fs

        cmpb    $8, _ScrMode
	je		PutXY8
        cmpb    $6, _ScrMode
	jb		1f
        cmpb    $1, _InterLaceMode
	je		Put
	jmp		PutY

1:      cmpb    $1, _InterLaceMode
	je		PutX
	jmp		PutXY

#
# screen 0(80),6,7 interlaced
#
	.align 4,0x90
Put:
        xorb    $1, _InterLacePage
	jnz		PutOdd

	.align 4,0x90
PutEven:
#0-101
	CHGBANK 0
	movl	$0xa8000,%edi
	PUTL	51
#102-103
	PUTD	256
	CHGBANK	1
	movl	$0xa8000,%edi
	PUTD	640-256
	addl	$640,%edi
#104-203
	PUTL	50
#204-205
	PUTD	512
	CHGBANK	2
	movl	$0xa8000,%edi
	PUTD	640-512
	addl	$640,%edi
#206-305
	PUTL	51
#306-307
	CHGBANK	3
	movl	$0xa8000+640-128,%edi
#308-407
	PUTL	51
#408-409
	CHGBANK	4
	movl	$0xa8000+640-384,%edi
#410-479
	PUTL	35

	jmp ExitPutImage

	.align 4,0x90
PutOdd:
#0-101
	CHGBANK 0
	movl	$0xa8000+640,%edi
	PUTL	51
#102-203
	CHGBANK	1
	movl	$0xa8000+640-256,%edi
	PUTL	51
#204-305
	CHGBANK	2
	movl	$0xa8000+640-512,%edi
	PUTL	51
#306-307
	PUTD	128
	CHGBANK	3
	movl	$0xa8000,%edi
	PUTD	640-128
	addl	$640,%edi
#308-407
	PUTL	50
#408-409
	PUTD	384
	CHGBANK	4
	movl	$0xa8000,%edi
	PUTD	640-384
	addl	$640,%edi
#410-479
	PUTL	35

	jmp ExitPutImage



#
# screen 0(40),1,2,3,4,5 interlaced
#
PutX:
        xorb    $1, _InterLacePage
	jnz		PutXOdd

	.align 4,0x90
PutXEven:
#0-101
	CHGBANK 0
        movl    $0xa8000,%edi
	PUTLX	51
#102-103
	PUTDX	256
	CHGBANK	1
        movl    $0xa8000,%edi
	PUTDX	640-256
	addl	$640,%edi
#104-203
	PUTLX	50
#204-205
	PUTDX	512
	CHGBANK	2
        movl    $0xa8000,%edi
	PUTDX	640-512
	addl	$640,%edi
#206-305
	PUTLX	51
#306-307
	CHGBANK	3
        movl    $0xa8000+640-128,%edi
#308-407
	PUTLX	51
#408-409
	CHGBANK	4
        movl    $0xa8000+640-384,%edi
#410-479
	PUTLX	35

	jmp ExitPutImage

	.align 4,0x90
PutXOdd:
#0-101
	CHGBANK 0
        movl    $0xa8000+640,%edi
	PUTLX	51
#102-203
	CHGBANK	1
        movl    $0xa8000+640-256,%edi
	PUTLX	51
#204-305
	CHGBANK	2
        movl    $0xa8000+640-512,%edi
	PUTLX	51
#306-307
	PUTDX	128
	CHGBANK	3
        movl    $0xa8000,%edi
	PUTDX	640-128
	addl	$640,%edi
#308-407
	PUTLX	50
#408-409
	PUTDX	384
	CHGBANK	4
        movl    $0xa8000,%edi
	PUTDX	640-384
	addl	$640,%edi
#410-479
	PUTLX	35

	jmp ExitPutImage


#
# screen 0(80),6,7 non-interlaced
#
	.align 4,0x90
PutY:
#0-101
	CHGBANK 0
	movl	$0xa8000,%edi
	PUTLY	51

#102-103
	PUTD	256
	CHGBANK	1
	sbbl	$256,%esi
	movl	$0xa8000+640-256,%edi
	PUTD	256
	movl	$0xa8000,%edi
	PUTDY	640-256
	addl	$640,%edi

#104-203
	PUTLY	50

#204-205
	PUTD	512
	CHGBANK	2
	sbbl	$512,%esi
	movl	$0xa8000+640-512,%edi
	PUTD	512
	movl	$0xa8000,%edi
	PUTDY	640-512
	addl	$640,%edi

#206-305
	PUTLY	50

#306-307
	PUTDY	128
	PUTD	640-128
	CHGBANK	3
	sbbl	$(640-128),%esi
	movl	$0xa8000,%edi
	PUTD	640-128

#308-407
	PUTLY	50

#408-409
	PUTDY	384
	PUTD	640-384
	CHGBANK	4
	sbbl	$(640-384),%esi
	movl	$0xa8000,%edi
	PUTD	640-384

#410-479
	PUTLY	35

	jmp ExitPutImage


#
# screen 0(40),1,2,3,4,5 non-interlaced
#
	.align 4,0x90
PutXY:
#0-101
	CHGBANK 0
	movl	$0xa8000,%edi
	PUTLXY	51

#102-103
	PUTDX	256
	CHGBANK	1
	sbbl	$256/2,%esi
	movl	$0xa8000+640-256,%edi
	PUTDX	256
	movl	$0xa8000,%edi
	PUTDXY	640-256
	addl	$640,%edi

#104-203
	PUTLXY	50

#204-205
	PUTDX	512
	CHGBANK	2
	sbbl	$512/2,%esi
	movl	$0xa8000+640-512,%edi
	PUTDX	512
	movl	$0xa8000,%edi
	PUTDXY	640-512
	addl	$640,%edi

#206-305
	PUTLXY	50

#306-307
	PUTDXY	128
	PUTDX	640-128
	CHGBANK	3
	sbbl	$(640-128)/2,%esi
	movl	$0xa8000,%edi
	PUTDX	640-128

#308-407
	PUTLXY	50

#408-409
	PUTDXY	384
	PUTDX	640-384
	CHGBANK	4
	sbbl	$(640-384)/2,%esi
	movl	$0xa8000,%edi
	PUTDX	640-384

#410-479
	PUTLXY	35

	jmp ExitPutImage

#
# screen 8 non-interlaced
#
	.align 4,0x90
PutXY8:
#0-101
	CHGBANK 0
	movl	$0xa8000,%edi
	PUTLXY8	51

#102-103
	PUTDX8	256
	CHGBANK	1
	sbbl	$256/2,%esi
	movl	$0xa8000+640-256,%edi
	PUTDX8	256
	movl	$0xa8000,%edi
	PUTDXY8	640-256
	addl	$640,%edi

#104-203
	PUTLXY8	50

#204-205
	PUTDX8	512
	CHGBANK	2
	sbbl	$512/2,%esi
	movl	$0xa8000+640-512,%edi
	PUTDX8	512
	movl	$0xa8000,%edi
	PUTDXY8	640-512
	addl	$640,%edi

#206-305
	PUTLXY8	50

#306-307
	PUTDXY8	128
	PUTDX8	640-128
	CHGBANK	3
	sbbl	$(640-128)/2,%esi
	movl	$0xa8000,%edi
	PUTDX8	640-128

#308-407
	PUTLXY8	50

#408-409
	PUTDXY8	384
	PUTDX8	640-384
	CHGBANK	4
	sbbl	$(640-384)/2,%esi
	movl	$0xa8000,%edi
	PUTDX8	640-384

#410-479
	PUTLXY8	35

	jmp		ExitPutImage

ExitPutImage:
        popl    %ebx
	popl	%esi
	popl	%ebp
	ret

.data

_r:
	.long	0	#ax
	.long	0	#bx
	.long	0	#cx
	.long	0	#dx
	.long	0	#si
	.long	0	#di
	.long	0	#cflags
	.long	0	#flags

.end
