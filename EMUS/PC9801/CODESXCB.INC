.data
	.align 4
Z80_Table_YY_CB:
	.long NO_DC,NO_DC,NO_DC,NO_DC,NO_DC,NO_DC		#00
	.long RLC_xXX
	.long NO_DC
	.long NO_DC,NO_DC,NO_DC,NO_DC,NO_DC,NO_DC		#08
	.long RRC_xXX
	.long NO_DC
	.long NO_DC,NO_DC,NO_DC,NO_DC,NO_DC,NO_DC		#10
	.long RL_xXX
	.long NO_DC
	.long NO_DC,NO_DC,NO_DC,NO_DC,NO_DC,NO_DC		#18
	.long RR_xXX
	.long NO_DC
	.long NO_DC,NO_DC,NO_DC,NO_DC,NO_DC,NO_DC		#20
	.long SLA_xXX
	.long NO_DC
	.long NO_DC,NO_DC,NO_DC,NO_DC,NO_DC,NO_DC		#28
	.long SRA_xXX
	.long NO_DC
	.long NO_DC,NO_DC,NO_DC,NO_DC,NO_DC,NO_DC,NO_DC,NO_DC	#30
	.long NO_DC,NO_DC,NO_DC,NO_DC,NO_DC,NO_DC		#38
	.long SRL_xXX
	.long NO_DC
	.long NO_DC,NO_DC,NO_DC,NO_DC,NO_DC,NO_DC		#40
	.long BIT0_xXX
	.long NO_DC
	.long NO_DC,NO_DC,NO_DC,NO_DC,NO_DC,NO_DC		#48
	.long BIT1_xXX
	.long NO_DC
	.long NO_DC,NO_DC,NO_DC,NO_DC,NO_DC,NO_DC		#50
	.long BIT2_xXX
	.long NO_DC
	.long NO_DC,NO_DC,NO_DC,NO_DC,NO_DC,NO_DC		#58
	.long BIT3_xXX
	.long NO_DC
	.long NO_DC,NO_DC,NO_DC,NO_DC,NO_DC,NO_DC		#60
	.long BIT4_xXX
	.long NO_DC
	.long NO_DC,NO_DC,NO_DC,NO_DC,NO_DC,NO_DC		#68
	.long BIT5_xXX
	.long NO_DC
	.long NO_DC,NO_DC,NO_DC,NO_DC,NO_DC,NO_DC		#70
	.long BIT6_xXX
	.long NO_DC
	.long NO_DC,NO_DC,NO_DC,NO_DC,NO_DC,NO_DC		#78
	.long BIT7_xXX
	.long NO_DC
	.long NO_DC,NO_DC,NO_DC,NO_DC,NO_DC,NO_DC		#80
	.long RES0_xXX
	.long NO_DC
	.long NO_DC,NO_DC,NO_DC,NO_DC,NO_DC,NO_DC		#88
	.long RES1_xXX
	.long NO_DC
	.long NO_DC,NO_DC,NO_DC,NO_DC,NO_DC,NO_DC		#90
	.long RES2_xXX
	.long NO_DC
	.long NO_DC,NO_DC,NO_DC,NO_DC,NO_DC,NO_DC		#98
	.long RES3_xXX
	.long NO_DC
	.long NO_DC,NO_DC,NO_DC,NO_DC,NO_DC,NO_DC		#a0
	.long RES4_xXX
	.long NO_DC
	.long NO_DC,NO_DC,NO_DC,NO_DC,NO_DC,NO_DC		#a8
	.long RES5_xXX
	.long NO_DC
	.long NO_DC,NO_DC,NO_DC,NO_DC,NO_DC,NO_DC		#b0
	.long RES6_xXX
	.long NO_DC
	.long NOP ,NO_DC,NO_DC,NO_DC,NO_DC,NO_DC		#b8
	.long RES7_xXX
	.long NO_DC
	.long NO_DC,NO_DC,NO_DC,NO_DC,NO_DC,NO_DC		#c0
	.long SET0_xXX
	.long NO_DC
	.long NO_DC,NO_DC,NO_DC,NO_DC,NO_DC,NO_DC		#c8
	.long SET1_xXX
	.long NO_DC
	.long NO_DC,NO_DC,NO_DC,NO_DC,NO_DC,NO_DC		#d0
	.long SET2_xXX
	.long NO_DC
	.long NO_DC,NO_DC,NO_DC,NO_DC,NO_DC,NO_DC		#d8
	.long SET3_xXX
	.long NO_DC
	.long NO_DC,NO_DC,NO_DC,NO_DC,NO_DC,NO_DC		#e0
	.long SET4_xXX
	.long NO_DC
	.long NO_DC,NO_DC,NO_DC,NO_DC,NO_DC,NO_DC		#e8
	.long SET5_xXX
	.long NO_DC
	.long NO_DC,NO_DC,NO_DC,NO_DC,NO_DC,NO_DC		#f0
	.long SET6_xXX
	.long NO_DC
	.long NO_DC,NO_DC,NO_DC,NO_DC,NO_DC,NO_DC		#f8
	.long SET7_xXX
	.long NO_DC

.text
	.align 4,0x90
RLC_xXX:
	pushl %edi
	M_RDMEM
	popl %edi
	rolb $1,%al
	sbbb %bl,%bl
	andb C_FLAG,%bl
	orb %al,%al
	pushf
	pushl %ebx
	M_WRMEM
	popl %ebx
	popl %eax
	andb $0b11101100,%al
	orb %bl,%al
	movb %al,_F
	jmp Ret_Z80

	.align 4,0x90
RRC_xXX:
	pushl %edi
	M_RDMEM
	popl %edi
	rorb $1,%al
	sbbb %bl,%bl
	andb C_FLAG,%bl
	orb %al,%al
	pushf
	pushl %ebx
	M_WRMEM
	popl %ebx
	popl %eax
	andb $0b11101100,%al
	orb %bl,%al
	movb %al,_F
	jmp Ret_Z80

	.align 4,0x90
RL_xXX:
	pushl %edi
	M_RDMEM
	popl %edi
	movb _F,%ah
	rcrb $1,%ah
	rclb $1,%al
	sbbb %bl,%bl
	andb C_FLAG,%bl
	orb %al,%al
	pushf
	pushl %ebx
	M_WRMEM
	popl %ebx
	popl %eax
	andb $0b11101100,%al
	orb %bl,%al
	movb %al,_F
	jmp Ret_Z80

	.align 4,0x90
RR_xXX:
	pushl %edi
	M_RDMEM
	popl %edi
	movb _F,%ah
	rcrb $1,%ah
	rcrb $1,%al
	sbbb %bl,%bl
	andb C_FLAG,%bl
	orb %al,%al
	pushf
	pushl %ebx
	M_WRMEM
	popl %ebx
	popl %eax
	andb $0b11101100,%al
	orb %bl,%al
	movb %al,_F
	jmp Ret_Z80

	.align 4,0x90
SLA_xXX:
	pushl %edi
	M_RDMEM
	popl %edi
	addb %al,%al
	pushf
	M_WRMEM
	popl %eax
	andb $0b11101101,%al
	movb %al,_F
	jmp Ret_Z80

	.align 4,0x90
SRA_xXX:
	pushl %edi
	M_RDMEM
	popl %edi
	movb %al,%bl
	andb C_FLAG,%bl
	sarb $1,%al
	pushf
	pushl %ebx
	M_WRMEM
	popl %ebx
	popl %eax
	andb $0b11101100,%al
	orb %bl,%al
	movb %al,_F
	jmp Ret_Z80

	.align 4,0x90
SRL_xXX:
	pushl %edi
	M_RDMEM
	popl %edi
	movb %al,%bl
	andb C_FLAG,%bl
	shrb $1,%al
	pushf
	pushl %ebx
	M_WRMEM
	popl %ebx
	popl %eax
	andb $0b11101100,%al
	orb %bl,%al
	movb %al,_F
	jmp Ret_Z80

.macro M_BIT_xX bit
	.align 4,0x90
BITbit_xXX:
	M_ADDR
	M_BIT bit,(%edi)
	.align 4,0x90
SETbit_xXX:
	pushl %edi
	M_RDMEM
	popl %edi
	movb $0b00000001,%ah
	rolb $bit,%ah
	orb %ah,%al
	M_WRMEM
	jmp Ret_Z80
	.align 4,0x90
RESbit_xXX:
	pushl %edi
	M_RDMEM
	popl %edi
	movb $0b11111110,%ah
	rolb $bit,%ah
	andb %ah,%al
	M_WRMEM
	jmp Ret_Z80
.ENDM

	M_BIT_xX 0
	M_BIT_xX 1
	M_BIT_xX 2
	M_BIT_xX 3
	M_BIT_xX 4
	M_BIT_xX 5
	M_BIT_xX 6
	M_BIT_xX 7
