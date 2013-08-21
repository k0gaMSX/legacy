#* fMSX: portable MSX emulator *****************************
#*                                                         *
#*                       r800.asm                          *
#*                                                         *
#* This file contains i386 dependent Z80/R800 interpriter  *
#* inplementation. This module can be used instead of      *
#* Z80.c.                                                  *
#*                                                         *
#* fMSX   Copyright (C) Marat Fayzullin 1994,1995          *
#* fMSX98 Copyright (C) MURAKAMI Reki 1995,1996            *
#*     You are not allowed to distribute this software     *
#*     commercially. Please, notify me, if you make any    *
#*     changes to this file.                               *
#***********************************************************

	.file "r800.asm"

.alias S_FLAG $0x80
.alias Z_FLAG $0x40
.alias H_FLAG $0x10
.alias P_FLAG $0x04
.alias V_FLAG $0x04
.alias N_FLAG $0x02
.alias C_FLAG $0x01

.MACRO M_RLC Rg
	movb Rg,%al
	rolb $1,%al
	movb %al,Rg
	sbbb %bl,%bl
	andb C_FLAG,%bl
	orb %al,%al
	pushf
	popl %eax
	andb $0b11101100,%al
	orb %bl,%al
	movb %al,_F
	jmp Ret_Z80
.ENDM

.MACRO M_RRC Rg
	movb Rg,%al
	rorb $1,%al
	movb %al,Rg
	sbbb %bl,%bl
	andb C_FLAG,%bl
	orb %al,%al
	pushf
	popl %eax
	andb $0b11101100,%al
	orb %bl,%al
	movb %al,_F
	jmp Ret_Z80
.ENDM

.MACRO M_RL Rg
	movb _F,%ah
	rcrb $1,%ah
	movb Rg,%al
	rclb $1,%al
	movb %al,Rg
	sbbb %bl,%bl
	andb C_FLAG,%bl
	orb %al,%al
	pushf
	popl %eax
	andb $0b11101100,%al
	orb %bl,%al
	movb %al,_F
	jmp Ret_Z80
.ENDM

.MACRO M_RR Rg
	movb _F,%ah
	rcrb $1,%ah
	movb Rg,%al
	rcrb $1,%al
	movb %al,Rg
	sbbb %bl,%bl
	andb C_FLAG,%bl
	orb %al,%al
	pushf
	popl %eax
	andb $0b11101100,%al
	orb %bl,%al
	movb %al,_F
	jmp Ret_Z80
.ENDM

.MACRO M_SLA Rg
	movb Rg,%al
	addb %al,%al
	movb %al,Rg
	pushf
	popl %eax
	andb $0b11101101,%al
	movb %al,_F
	jmp Ret_Z80
.ENDM

.MACRO M_SRA Rg
	movb Rg,%al
	movb %al,%bl
	andb C_FLAG,%bl
	sarb $1,%al
	movb %al,Rg
	pushf
	popl %eax
	andb $0b11101100,%al
	orb %bl,%al
	movb %al,_F
	jmp Ret_Z80
.ENDM

.MACRO M_SRL Rg
	movb Rg,%al
	movb %al,%bl
	andb C_FLAG,%bl
	shrb $1,%al
	movb %al,Rg
	pushf
	popl %eax
	andb $0b11101100,%al
	orb %bl,%al
	movb %al,_F
	jmp Ret_Z80
.ENDM

.MACRO M_BIT Bit,Rg
	movzbl Rg,%eax
	btl $Bit,%eax
	sbbb %al,%al
	notb %al
	andb Z_FLAG,%al
	movb _F,%ah
	andb $0b10111101,%ah
	orb H_FLAG,%ah
	orb %ah,%al
	movb %al,_F
	jmp Ret_Z80
.ENDM

.MACRO M_SET Bit,Rg
	movb $0b00000001,%ah
	rolb $Bit,%ah
	orb %ah,Rg
	jmp Ret_Z80
.ENDM

.MACRO M_RES Bit,Rg
	movb $0b11111110,%ah
	rolb $Bit,%ah
	andb %ah,Rg
	jmp Ret_Z80
.ENDM

.MACRO M_POP Rg
	M_RD_WORD %ebp
	movw %ax,Rg
	jmp Ret_Z80
.ENDM

.MACRO M_PUSH Rg
	subl $2,%ebp
	movl %ebp,%edi
	movw Rg,%ax
	M_WRMEM
	incl %edi
	movb %ah,%al
	M_WRMEM
	jmp Ret_Z80
.ENDM

.MACRO M_CALL
	M_RD_WORD %esi
	movl %eax,%edx
	movl %esi,%eax
	subl $2,%ebp
	movl %ebp,%edi
	M_WRMEM
	incl %edi
	movb %ah,%al
	M_WRMEM
	movl %edx,%esi
	jmp Ret_Z80
.ENDM

.MACRO M_JP
	M_RD_WORD %esi
	movl %eax,%esi
	jmp Ret_Z80
.ENDM

.MACRO M_JR
	M_RD_PC
	movsbl %al,%eax
	addl %eax,%esi
	jmp Ret_Z80
.ENDM

.MACRO M_RET
	M_RD_WORD %ebp
	movl %eax,%esi
	jmp Ret_Z80
.ENDM

.MACRO M_RST Ad
	subl $2,%ebp
	movl %ebp,%edi
	movl %esi,%eax
	M_WRMEM
	incl %edi
	movb %ah,%al
	M_WRMEM
	movl Ad,%esi
	jmp Ret_Z80
.ENDM

.MACRO M_LDWORD Rg
	M_RD_WORD %esi
	movw %ax,Rg
	jmp Ret_Z80
.ENDM

.MACRO M_ADD Rg
	movb Rg,%al
	addb %al,_A
	pushf
	popl %eax
	andl $0b0000100011010001,%eax
	rorb $1,%ah
	orb %ah,%al
	movb %al,_F
	jmp Ret_Z80
.ENDM

.MACRO M_SUB Rg
	movb Rg,%al
	subb %al,_A
	pushf
	popl %eax
	andl $0b0000100011010011,%eax
	rorb $1,%ah
	orb %ah,%al
	movb %al,_F
	jmp Ret_Z80
.ENDM

.MACRO M_ADC Rg
	movb _F,%ah
	rorb $1,%ah
	movb Rg,%al
	adcb %al,_A
	pushf
	popl %eax
	andl $0b0000100011010001,%eax
	rorb $1,%ah
	orb %ah,%al
	movb %al,_F
	jmp Ret_Z80
.ENDM

.MACRO M_SBC Rg
	movb _F,%ah
	rorb $1,%ah
	movb Rg,%al
	sbbb %al,_A
	pushf
	popl %eax
	andl $0b0000100011010011,%eax
	rorb $1,%ah
	orb %ah,%al
	movb %al,_F
	jmp Ret_Z80
.ENDM

.MACRO M_CP Rg
	movb Rg,%al
	cmpb %al,_A
	pushf
	popl %eax
	andl $0b0000100011010011,%eax
	rorb $1,%ah
	orb %ah,%al
	movb %al,_F
	jmp Ret_Z80
.ENDM

.MACRO M_AND Rg
	movb Rg,%al
	andb %al,_A
	pushf
	popl %eax
	andb $0b11000100,%al
	orb H_FLAG,%al
	movb %al,_F
	jmp Ret_Z80
.ENDM

.MACRO M_OR Rg
	movb Rg,%al
	orb %al,_A
	pushf
	popl %eax
	andb $0b11000100,%al
	movb %al,_F
	jmp Ret_Z80
.ENDM

.MACRO M_XOR Rg
	movb Rg,%al
	xorb %al,_A
	pushf
	popl %eax
	andb $0b11000100,%al
	movb %al,_F
	jmp Ret_Z80
.ENDM

.MACRO M_INC Rg
	incb Rg
	pushf
	popl %eax
	andl $0b0000100011010000,%eax
	rorb $1,%ah
	orb %ah,%al
	movb _F,%ah
	andb C_FLAG,%ah
	orb %ah,%al
	movb %al,_F
	jmp Ret_Z80
.ENDM

.MACRO M_DEC Rg
	decb Rg
	pushf
	popl %eax
	andl $0b0000100011010010,%eax
	rorb $1,%ah
	orb %ah,%al
	movb _F,%ah
	andb C_FLAG,%ah
	orb %ah,%al
	movb %al,_F
	jmp Ret_Z80
.ENDM

.MACRO M_ADDW Dst,Src
	movw Src,%ax
	addw %ax,Dst
	sbbb %al,%al
	andb C_FLAG,%al
	movb _F,%ah
	andb $0b11010100,%ah
	orb %ah,%al
	movb %al,_F
	jmp Ret_Z80
.ENDM

.MACRO M_ADCW Rg
	movb _F,%ah
	rorb $1,%ah
	movw Rg,%ax
	adcw %ax,_HL
	pushf
	popl %eax
	andl $0b0000100011010001,%eax
	rorb $1,%ah
	orb %ah,%al
	movb %al,_F
	jmp Ret_Z80
.ENDM

.MACRO M_SBCW Rg
	movb _F,%ah
	rorb $1,%ah
	movw Rg,%ax
	sbbw %ax,_HL
	pushf
	popl %eax
	andl $0b0000100011010011,%eax
	rorb $1,%ah
	orb %ah,%al
	movb %al,_F
	jmp Ret_Z80
.ENDM

.MACRO M_IN Rg
	movzbl _C,%eax
	pushl %eax		# port
	call _DoIn
	popl %edi		# instead of adding esp
	movb %al,Rg
	orb %al,%al
	pushf
	popl %eax
	andb $0b11101100,%al
	movb _F,%ah
	andb C_FLAG,%ah
	orb %ah,%al
	movb %al,_F
	jmp Ret_Z80
.ENDM

.MACRO M_OUT Rg
	movzbl _C,%ebx
	movzbl Rg,%eax
	pushl %eax		# data
	pushl %ebx		# port
	call _DoOut
	addl $8,%esp
	jmp Ret_Z80
.ENDM

.MACRO M_MULUB Rg
	movb _A,%al
	mulb Rg
	movw %ax,_HL
	sbbb %bl,%bl
	andb C_FLAG,%bl
	decw %ax
	sbbb %bh,%bh
	andb Z_FLAG,%bh
	orb %bh,%bl
	movb _F,%al
	andb $0b01111110,%al
	orb %bl,%al
	movb %al,_F
	jmp Ret_Z80
.ENDM

.MACRO M_MULUW Rg
	movw _HL,%ax
	mulw Rg
	movw %dx,_DE
	movw %ax,_HL
	sbbb %bl,%bl
	andb C_FLAG,%bl
	decw %ax
	sbbb %bh,%bh
	andb Z_FLAG,%bh
	orb %bh,%bl
	movb _F,%al
	andb $0b01111110,%al
	orb %bl,%al
	movb %al,_F
	jmp Ret_Z80
.ENDM

# following macros(M_WRMEM,M_RDMEM,M_RD_PC) broke ebx,ecx

.MACRO M_WRMEM
	cmpw $0xffff,%di
	je 8f			# slot change ?
	movl %edi,%ebx
	andl $0xe000,%ebx
	shrl $11,%ebx
	movl _RAM(%ebx),%ecx
	shrl $3,%ebx
	cmpb $0,_EnWrite(%ebx)
	je 9f			# not RAM ?
	movl %edi,%ebx
	andl $0x1fff,%ebx
	movb %al,(%ecx,%ebx)
	jmp 7f
9:	pushl %eax		# value
	pushl %edi		# address
	call _MapROM
	popl %edi
	popl %eax
	jmp 7f
8:	pushl %edi
	pushl %eax		# SSL
	call _SSlot
	popl %eax
	popl %edi
7:
.ENDM

.MACRO M_RDMEM
	movl %edi,%ebx
	andl $0xe000,%ebx
	andl $0x1fff,%edi
	shrl $11,%ebx
	addl _RAM(%ebx),%edi
	movb (%edi),%al
.ENDM

.MACRO M_RD_PC
	movl %esi,%ecx
	movl %esi,%ebx
	andl $0xe000,%ecx
	andl $0x1fff,%ebx
	shrl $11,%ecx
	addl _RAM(%ecx),%ebx
	incl %esi
	movb (%ebx),%al
.ENDM

.MACRO M_RD_WORD src
	movl src,%ecx
	movl src,%ebx
	andl $0xe000,%ecx
	andl $0x1fff,%ebx
	shrl $11,%ecx
	addl _RAM(%ecx),%ebx
	incl src
	movb (%ebx),%al
	movl src,%ecx
	movl src,%ebx
	andl $0xe000,%ecx
	andl $0x1fff,%ebx
	shrl $11,%ecx
	addl _RAM(%ecx),%ebx
	incl src
	movb (%ebx),%ah
.ENDM

.MACRO M_ADDR
	movl %edi,%eax
	andl $0xe000,%eax
	andl $0x1fff,%edi
	shrl $11,%eax
	addl _RAM(%eax),%edi
.ENDM

.data
	.align 4
regZ80:
_AF:
_F:	.byte 0
_A:	.byte 0
_BC:
_C:	.byte 0
_B:	.byte 0
_DE:
_E:	.byte 0
_D:	.byte 0
_HL:
_L:	.byte 0
_H:	.byte 0
_IX:
_IXL:	.byte 0
_IXH:	.byte 0
_IY:
_IYL:	.byte 0
_IYH:	.byte 0
_PC:	.short 0
_SP:	.short 0
_AF1:	.short 0
_BC1:	.short 0
_DE1:	.short 0
_HL1:	.short 0
_IFF:	.byte 0
_I:	.byte 0

.text
	.align 4
.globl _Z80
_Z80:
	pushl %ebp
	movl %esp,%ebp
	pushl %edi
	pushl %esi
	movl $regZ80,%edi
	leal 8(%ebp),%esi
	cld
	movl $6,%ecx
	rep
	movsl
	movsw
	xorl %edi,%edi
	xorl %esi,%esi
	movw _PC,%si
	movw _SP,%bp

	.align 4,0x90
Z80_0:	cmpb $0,_Trace
	jne Z80_5

Z80_1:	M_RD_PC
	movzbl %al,%eax
	jmp Z80_Table(,%eax,4)

	.align 4,0x90
Ret_Z80:
	decl _Cnt
	jns Z80_0
Z80_2:	call _Interrupt
	movl %eax,%edx
	orb %al,%al
	jz Z80_0
	testb $0x01,_IFF
	jz Z80_0
	testb $0x04,_IFF
	jz Z80_3
	movzbl _I,%edx
	shll $8,%edx
	addl $0xff,%edx
Z80_3:	M_RST %edx

Z80_5:	movw %si,_PC
	movw %bp,_SP
	pushl $regZ80
	call _Debug
	addl $4,%esp
	jmp Z80_1

EndZ80:
	movl %esi,%eax
	popl %esi
	popl %edi
	leave
	ret

.include "codes.inc"
.include "codescb.inc"
.include "codesed.inc"

.alias XX IX
.alias YY DD
.include "codesxx.inc"

.alias XX IY
.alias YY FD
.include "codesxx.inc"

