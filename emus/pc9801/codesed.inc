.data
	.align 4
Z80_Table_ED:
	.long NO_ED,NO_ED,NO_ED,NO_ED,NO_ED,NO_ED,NO_ED,NO_ED	#00
	.long NO_ED,NO_ED,NO_ED,NO_ED,NO_ED,NO_ED,NO_ED,NO_ED	#08
	.long NO_ED,NO_ED,NO_ED,NO_ED,NO_ED,NO_ED,NO_ED,NO_ED	#10
	.long NO_ED,NO_ED,NO_ED,NO_ED,NO_ED,NO_ED,NO_ED,NO_ED	#18
	.long NO_ED,NO_ED,NO_ED,NO_ED,NO_ED,NO_ED,NO_ED,NO_ED	#20
	.long NO_ED,NO_ED,NO_ED,NO_ED,NO_ED,NO_ED,NO_ED,NO_ED	#28
	.long NO_ED,NO_ED,NO_ED,NO_ED,NO_ED,NO_ED,NO_ED,NO_ED	#30
	.long NO_ED,NO_ED,NO_ED,NO_ED,NO_ED,NO_ED,NO_ED,NO_ED	#38
	.long IN_B_xC		#40
	.long OUT_xC_B
	.long SBC_HL_BC
	.long LD_xWORD_BC
	.long NEG
	.long RETN
	.long IM_0
	.long LD_I_A
	.long IN_C_xC		#48
	.long OUT_xC_C
	.long ADC_HL_BC
	.long LD_BC_xWORD
	.long NO_ED
	.long RETI
	.long NO_ED
	.long NO_ED	#LD_R_A
	.long IN_D_xC		#50
	.long OUT_xC_D
	.long SBC_HL_DE
	.long LD_xWORD_DE
	.long NO_ED
	.long NO_ED
	.long IM_1
	.long LD_A_I
	.long IN_E_xC		#58
	.long OUT_xC_E
	.long ADC_HL_DE
	.long LD_DE_xWORD
	.long NO_ED
	.long NO_ED
	.long IM_2
	.long LD_A_R
	.long IN_H_xC		#60
	.long OUT_xC_H
	.long SBC_HL_HL
	.long NO_ED
	.long NO_ED
	.long NO_ED
	.long NO_ED
	.long RRD
	.long IN_L_xC		#68
	.long OUT_xC_L
	.long ADC_HL_HL
	.long LD_HL_xWORD
	.long NO_ED
	.long NO_ED
	.long NO_ED
	.long RLD
	.long NO_ED		#70
	.long NO_ED
	.long SBC_HL_SP
	.long LD_xWORD_SP
	.long NO_ED
	.long NO_ED
	.long NO_ED
	.long NO_ED
	.long IN_A_xC		#78
	.long OUT_xC_A
	.long ADC_HL_SP
	.long LD_SP_xWORD
	.long NO_ED
	.long NO_ED
	.long NO_ED
	.long NO_ED
	.long NO_ED,NO_ED,NO_ED,NO_ED,NO_ED,NO_ED,NO_ED,NO_ED	#80
	.long NO_ED,NO_ED,NO_ED,NO_ED,NO_ED,NO_ED,NO_ED,NO_ED	#88
	.long NO_ED,NO_ED,NO_ED,NO_ED,NO_ED,NO_ED,NO_ED,NO_ED	#90
	.long NO_ED,NO_ED,NO_ED,NO_ED,NO_ED,NO_ED,NO_ED,NO_ED	#98
	.long LDI			#a0
	.long CPI
	.long INI
	.long OUTI
	.long NO_ED,NO_ED,NO_ED,NO_ED
	.long LDD			#a8
	.long CPD
	.long IND
	.long OUTD
	.long NO_ED,NO_ED,NO_ED,NO_ED
	.long LDIR			#b0
	.long CPIR
	.long INIR
	.long OTIR
	.long NO_ED,NO_ED,NO_ED,NO_ED
	.long LDDR			#b8
	.long CPDR
	.long INDR
	.long OTDR
	.long NO_ED,NO_ED,NO_ED,NO_ED
	.long NO_ED			#c0
	.long MULUB_A_B
	.long NO_ED
	.long MULUW_HL_BC
	.long NO_ED,NO_ED,NO_ED,NO_ED
	.long NO_ED			#c8
	.long MULUB_A_C
	.long NO_ED,NO_ED,NO_ED,NO_ED,NO_ED,NO_ED
	.long NO_ED			#d0
	.long MULUB_A_D
	.long NO_ED
	.long MULUW_HL_DE
	.long NO_ED,NO_ED,NO_ED,NO_ED
	.long NO_ED			#d8
	.long MULUB_A_E
	.long NO_ED,NO_ED,NO_ED,NO_ED,NO_ED,NO_ED
	.long NO_ED			#e0
	.long MULUB_A_H
	.long NO_ED
	.long MULUW_HL_HL
	.long NO_ED,NO_ED,NO_ED,NO_ED
	.long NO_ED			#e8
	.long MULUB_A_L
	.long NO_ED,NO_ED,NO_ED,NO_ED,NO_ED,NO_ED
	.long NO_ED			#f0
	.long NO_ED
	.long NO_ED
	.long MULUW_HL_SP
	.long NO_ED,NO_ED,NO_ED,NO_ED
	.long NO_ED			#f8
	.long MULUB_A_A
	.long NO_ED,NO_ED,NO_ED
	.long TRAPBIOS
	.long NO_ED
	.long NO_ED

.text

PFX_ED:
	M_RD_PC
	movzbl %al,%eax
	jmp Z80_Table_ED(,%eax,4)

	.align 4,0x90
ADC_HL_BC:	M_ADCW _BC
	.align 4,0x90
ADC_HL_DE:	M_ADCW _DE
	.align 4,0x90
ADC_HL_HL:	M_ADCW _HL
	.align 4,0x90
ADC_HL_SP:	M_ADCW %bp

	.align 4,0x90
SBC_HL_BC:	M_SBCW _BC
	.align 4,0x90
SBC_HL_DE:	M_SBCW _DE
	.align 4,0x90
SBC_HL_HL:	M_SBCW _HL
	.align 4,0x90
SBC_HL_SP:	M_SBCW %bp

.MACRO M_LD_xWORD_R2 Rg
	M_RD_WORD %esi
	movl %eax,%edi
	movw Rg,%ax
	pushl %eax
	pushl %edi
	M_WRMEM
	popl %edi
	popl %eax
	incl %edi
	movb %ah,%al
	M_WRMEM
	jmp Ret_Z80
.ENDM

	.align 4,0x90
LD_xWORD_HL:	M_LD_xWORD_R2 _HL
	.align 4,0x90
LD_xWORD_BC:	M_LD_xWORD_R2 _BC
	.align 4,0x90
LD_xWORD_DE:	M_LD_xWORD_R2 _DE
	.align 4,0x90
LD_xWORD_SP:	M_LD_xWORD_R2 %bp

.MACRO M_LD_R2_xWORD Rg
	M_RD_WORD %esi
	movl %eax,%edi
	M_RD_WORD %edi
	movw %ax,Rg
	jmp Ret_Z80
.ENDM

	.align 4,0x90
LD_HL_xWORD:	M_LD_R2_xWORD _HL
	.align 4,0x90
LD_BC_xWORD:	M_LD_R2_xWORD _BC
	.align 4,0x90
LD_DE_xWORD:	M_LD_R2_xWORD _DE
	.align 4,0x90
LD_SP_xWORD:	M_LD_R2_xWORD %bp

	.align 4,0x90
RLD:
	movw _HL,%di
	M_RDMEM
	movb _A,%ah
	movb %ah,%cl
	andb $0x0f,%cl
	movl %eax,%ebx
	shll $4,%ebx
	andb $0x0f,%bh
	andb $0xf0,%ah
	orb %ah,%bh
	orb %cl,%bl
	movb %bh,_A
	movb %bl,%al
	movw _HL,%di
	orb %al,%al
	pushf
	M_WRMEM
	popl %eax
	andb $0xec,%al
	movb _F,%ah
	andb C_FLAG,%ah
	orb %ah,%al
	movb %al,_F
	jmp Ret_Z80

	.align 4,0x90
RRD:
	movw _HL,%di
	M_RDMEM
	movb _A,%ah
	movb %al,%cl
	andb $0x0f,%cl
	movl %eax,%ebx
	shrl $4,%ebx
	andb $0x0f,%bh
	andb $0xf0,%ah
	orb %cl,%ah
	movb %ah,_A
	movb %bl,%al
	movw _HL,%di
	orb %al,%al
	pushf
	M_WRMEM
	popl %eax
	andb $0xec,%al
	movb _F,%ah
	andb C_FLAG,%ah
	orb %ah,%al
	movb %al,_F
	jmp Ret_Z80

	.align 4,0x90
LD_A_I:
	movb _I,%al
	movb %al,_A
	orb %al,%al
	pushf
	popl %eax
	andb $0b11000000,%al
	movb _F,%ah
	andb $0b00101001,%ah
	orb %ah,%al
	movb _IFF,%ah
	andb C_FLAG,%ah
	shlb $2,%ah
	orb %ah,%al
	movb %al,_F
	jmp Ret_Z80

	.align 4,0x90
LD_A_R:
	movb _Cnt,%al
	movb %al,_A
	orb %al,%al
	pushf
	popl %eax
	andb $0b11000000,%al
	movb _F,%ah
	andb $0b00101001,%ah
	orb %ah,%al
	movb _IFF,%ah
	andb C_FLAG,%ah
	shlb $2,%ah
	orb %ah,%al
	movb %al,_F
	jmp Ret_Z80

	.align 4,0x90
LD_I_A:
	movb _A,%al
	movb %al,_I
	jmp Ret_Z80

	.align 4,0x90
IM_0:
	movb $0xf9,_IFF
	jmp Ret_Z80

	.align 4,0x09
IM_1:
	movb _IFF,%al
	andb $0xf9,%al
	orb $0x02,%al
	movb %al,_IFF
	jmp Ret_Z80

	.align 4,0x90
IM_2:
	movb _IFF,%al
	andb $0xf9,%al
	orb $0x04,%al
	movb %al,_IFF
	jmp Ret_Z80

	.align 4,0x09
RETI:
RETN:
	orb $0x01,_IFF
	M_RET

	.align 4,0x90
NEG:
	negb _A
	pushf
	popl %eax
	andl $0b0000100011010011,%eax
	rorb $1,%ah
	orb %ah,%al
	movb %al,_F
	jmp Ret_Z80

	.align 4,0x90
IN_B_xC: M_IN _B
	.align 4,0x90
IN_C_xC: M_IN _C
	.align 4,0x90
IN_D_xC: M_IN _D
	.align 4,0x90
IN_E_xC: M_IN _E
	.align 4,0x90
IN_H_xC: M_IN _H
	.align 4,0x90
IN_L_xC: M_IN _L
	.align 4,0x90
IN_A_xC: M_IN _A

	.align 4,0x90
OUT_xC_B: M_OUT _B
	.align 4,0x90
OUT_xC_C: M_OUT _C
	.align 4,0x90
OUT_xC_D: M_OUT _D
	.align 4,0x90
OUT_xC_E: M_OUT _E
	.align 4,0x90
OUT_xC_H: M_OUT _H
	.align 4,0x90
OUT_xC_L: M_OUT _L
	.align 4,0x90
OUT_xC_A: M_OUT _A

	.align 4,0x90
CPI:
	movw _HL,%di
	M_RDMEM
	incw _HL
	cmpb _A,%al
	pushf
	popl %eax
	movb _F,%ah
	andb C_FLAG,%ah
	andb $0b11010010,%al
	orb %ah,%al
	decw _BC
	jz 0f
	orb P_FLAG,%al
0:	movb %al,_F
	jmp Ret_Z80

	.align 4,0x09
CPIR:
	pushl %esi
	movw _HL,%si
	xorl %edx,%edx
	movw _BC,%dx
	subl %edx,_Cnt
	jnc 0f
	movl $0,_Cnt
0:	M_RD_PC
	decw %dx
	jz 1f
	cmpb %al,_A
	jne 0b
1:	cmpb %al,_A
	pushf
	popl %eax
	movb _F,%ah
	andb C_FLAG,%ah
	andb $0b11010010,%al
	orb %ah,%al
	orw %dx,%dx
	jz 2f
	orb P_FLAG,%al
2:	movb %al,_F
	movw %si,_HL
	movw %dx,_BC
	popl %esi
	jmp Ret_Z80

	.align 4,0x90
CPD:
	movw _HL,%di
	M_RDMEM
	decw _HL
	cmpb _A,%al
	pushf
	popl %eax
	movb _F,%ah
	andb C_FLAG,%ah
	andb $0b11010010,%al
	orb %ah,%al
	decw _BC
	jz 0f
	orb P_FLAG,%al
0:	movb %al,_F
	jmp Ret_Z80

	.align 4,0x09
CPDR:
	pushl %esi
	movw _HL,%si
	xorl %edx,%edx
	movw _BC,%dx
	subl %edx,_Cnt
	jnc 0f
	movl $0,_Cnt
0:	M_RD_PC
	decl %esi
	decl %esi
	decw %dx
	jz 1f
	cmpb %al,_A
	jne 0b
1:	cmpb %al,_A
	pushf
	popl %eax
	movb _F,%ah
	andb C_FLAG,%ah
	andb $0b11010010,%al
	orb %ah,%al
	orw %dx,%dx
	jz 2f
	orb P_FLAG,%al
2:	movb %al,_F
	movw %si,_HL
	movw %dx,_BC
	popl %esi
	jmp Ret_Z80

	.align 4,0x90
LDI:
	movw _HL,%di
	M_RDMEM
	movw _DE,%di
	M_WRMEM
	incw _HL
	incw _DE
	movb _F,%al
	andb $0b11000001,%al
	decw _BC
	jz 0f
	orb P_FLAG,%al
0:	movb %al,_F
	jmp Ret_Z80

	.align 4,0x90
LDIR:
	pushl %esi
	movw _HL,%si
	movw _DE,%di
	xorl %edx,%edx
	movw _BC,%dx
	subl %edx,_Cnt
	jnc 0f
	movl $0,_Cnt
0:	M_RD_PC
	pushl %edx
	pushl %edi
	M_WRMEM
	popl %edi
	popl %edx
	incl %edi
	decw %dx
	jnz 0b
	movw %si,_HL
	movw %di,_DE
	movw %dx,_BC
	andb $0b11000001,_F
	popl %esi
	jmp Ret_Z80


	.align 4,0x90
LDD:
	movw _HL,%di
	M_RDMEM
	movw _DE,%di
	M_WRMEM
	decw _HL
	decw _DE
	movb _F,%al
	andb $0b11000001,%al
	decw _BC
	jz 0f
	orb P_FLAG,%al
0:	movb %al,_F
	jmp Ret_Z80

	.align 4,0x90
LDDR:
	pushl %esi
	movw _HL,%si
	movw _DE,%di
	xorl %edx,%edx
	movw _BC,%dx
	subl %edx,_Cnt
	jnc 0f
	movl $0,_Cnt
0:	M_RD_PC
	decl %esi
	decl %esi
	pushl %edx
	pushl %edi
	M_WRMEM
	popl %edi
	popl %edx
	decl %edi
	decw %dx
	jnz 0b
	movw %si,_HL
	movw %di,_DE
	movw %dx,_BC
	andb $0b11000001,_F
	popl %esi
	jmp Ret_Z80

	.align 4,0x90
INI:
	movb _C,%al
	pushl %eax
	call _DoIn
	popl %edi		# instead of adding sp
	movw _HL,%di
	M_WRMEM
	incw _HL
	movb _F,%al
	orb $0b01000010,%al
	decb _B
	jz 0f
	andb $0b10111111,%al
0:	movb %al,_F
	jmp Ret_Z80

	.align 4,0x90
INIR:
	movw _HL,%di
	movb _C,%dl
	movb _B,%dh
0:	pushl %edi
	pushl %edx
	call _DoIn
	popl %edx		# instead of 'addl $4,%esp'
	popl %edi
	pushl %edi
	M_WRMEM
	popl %edi
	incl %edi
	decb %dh
	jnz 0b
	movw %di,_HL
	movb $0,_B
	orb $0b01000010,_F
	jmp Ret_Z80

	.align 4,0x90
IND:
	movb _C,%al
	pushl %eax
	call _DoIn
	popl %edi		# instead of adding esp
	movw _HL,%di
	M_WRMEM
	decw _HL
	movb _F,%al
	orb $0b01000010,%al
	decb _B
	jz 0f
	andb $0b10111111,%al
0:	movb %al,_F
	jmp Ret_Z80

	.align 4,0x90
INDR:
	movw _HL,%di
	movb _C,%dl
	movb _B,%dh
0:	pushl %edi
	pushl %edx
	call _DoIn
	popl %edx		# instead of 'addl $4,%esp'
	popl %edi
	pushl %edi
	M_WRMEM
	popl %edi
	decl %edi
	decb %dh
	jnz 0b
	movw %di,_HL
	movb $0,_B
	orb $0b01000010,_F
	jmp Ret_Z80

	.align 4,0x90
OUTI:
	movw _HL,%di
	M_RDMEM
	pushl %eax		# data
	movb _C,%dl
	pushl %edx		# port
	call _DoOut
	addl $8,%esp
	incw _HL
	movb _F,%al
	orb $0b01000010,%al
	decb _B
	jz 0f
	andb $0b10111111,%al
0:	movb %al,_F
	jmp Ret_Z80

	.align 4,0x90
OTIR:
	pushl %esi
	movw _HL,%si
	movb _C,%dl
	movb _B,%dh
0:	M_RD_PC
	pushl %eax		# data
	pushl %edx		# port
	call _DoOut
	popl %edx
	popl %eax		# instead of adding esp
	decb %dh
	jnz 0b
	movw %si,_HL
	movb $0,_B
	orb $0b01000010,_F
	popl %esi
	jmp Ret_Z80

	.align 4,0x90
OUTD:
	movw _HL,%di
	M_RDMEM
	pushl %eax		# data
	movb _C,%dl
	pushl %edx		# port
	call _DoOut
	addl $8,%esp
	decw _HL
	movb _F,%al
	orb $0b01000010,%al
	decb _B
	jz 0f
	andb $0b10111111,%al
0:	movb %al,_F
	jmp Ret_Z80

	.align 4,0x90
OTDR:
	pushl %esi
	movw _HL,%si
	movb _C,%dl
	movb _B,%dh
0:	M_RD_PC
	pushl %eax		# data
	pushl %edx		# port
	call _DoOut
	popl %edx
	popl %eax		# instead of adding esp
	decb %dh
	jnz 0b
	movw %si,_HL
	movb $0,_B
	orb $0b01000010,_F
	popl %esi
	jmp Ret_Z80

	.align 4,0x90
MULUB_A_B:	M_MULUB _B
	.align 4,0x90
MULUB_A_C:	M_MULUB _C
	.align 4,0x90
MULUB_A_D:	M_MULUB _D
	.align 4,0x90
MULUB_A_E:	M_MULUB _E
	.align 4,0x90
MULUB_A_H:	M_MULUB _H
	.align 4,0x90
MULUB_A_L:	M_MULUB _L
	.align 4,0x90
MULUB_A_A:	M_MULUB _A
	.align 4,0x90
MULUW_HL_BC:	M_MULUW _BC
	.align 4,0x90
MULUW_HL_DE:	M_MULUW _DE
	.align 4,0x90
MULUW_HL_HL:	M_MULUW _HL
	.align 4,0x90
MULUW_HL_SP:	M_MULUW %bp

	.align 4,0x90
TRAPBIOS:
	movw %si,_PC
	movw %bp,_SP
	pushl $regZ80
	call _BIOSEmulate
	addl $4,%esp
	jmp Ret_Z80

	.align 4,0x90
NO_ED:
	decl %esi
	movl %esi,%edi
	decl %edi
	movw %di,_PC
	movw %bp,_SP
	pushl $regZ80
	call _undefTrap
	addl $4,%esp
	jmp Ret_Z80
