
.data
	.align 4
Z80_Table:
	.long NOP		# 00h
	.long LD_BC_WORD
	.long LD_xBC_A
	.long INC_BC
	.long INC_B
	.long DEC_B
	.long LD_B_BYTE
	.long RLCA
	.long EX_AF_AF		# 08h
	.long ADD_HL_BC
	.long LD_A_xBC
	.long DEC_BC
	.long INC_C
	.long DEC_C
	.long LD_C_BYTE
	.long RRCA
	.long DJNZ		# 10h
	.long LD_DE_WORD
	.long LD_xDE_A
	.long INC_DE
	.long INC_D
	.long DEC_D
	.long LD_D_BYTE
	.long RLA
	.long JR		# 18h
	.long ADD_HL_DE
	.long LD_A_xDE
	.long DEC_DE
	.long INC_E
	.long DEC_E
	.long LD_E_BYTE
	.long RRA
	.long JR_NZ		# 20h
	.long LD_HL_WORD
	.long LD_xWORD_HL
	.long INC_HL
	.long INC_H
	.long DEC_H
	.long LD_H_BYTE
	.long DAA
	.long JR_Z		# 28h
	.long ADD_HL_HL
	.long LD_HL_xWORD
	.long DEC_HL
	.long INC_L
	.long DEC_L
	.long LD_L_BYTE
	.long CPL
	.long JR_NC		# 30h
	.long LD_SP_WORD
	.long LD_xWORD_A
	.long INC_SP
	.long INC_xHL
	.long DEC_xHL
	.long LD_xHL_BYTE
	.long SCF
	.long JR_C		# 38h
	.long ADD_HL_SP
	.long LD_A_xWORD
	.long DEC_SP
	.long INC_A
	.long DEC_A
	.long LD_A_BYTE
	.long CCF
	.long NOP	#LD_B_B	  40h
	.long LD_B_C
	.long LD_B_D
	.long LD_B_E
	.long LD_B_H
	.long LD_B_L
	.long LD_B_xHL
	.long LD_B_A
	.long LD_C_B		# 48h
	.long NOP	#LD_C_C
	.long LD_C_D
	.long LD_C_E
	.long LD_C_H
	.long LD_C_L
	.long LD_C_xHL
	.long LD_C_A
	.long LD_D_B		# 50h
	.long LD_D_C
	.long NOP	#LD_D_D
	.long LD_D_E
	.long LD_D_H
	.long LD_D_L
	.long LD_D_xHL
	.long LD_D_A
	.long LD_E_B		# 58h
	.long LD_E_C
	.long LD_E_D
	.long NOP	#LD_E_E
	.long LD_E_H
	.long LD_E_L
	.long LD_E_xHL
	.long LD_E_A
	.long LD_H_B		# 60h
	.long LD_H_C
	.long LD_H_D
	.long LD_H_E
	.long NOP	#LD_H_H
	.long LD_H_L
	.long LD_H_xHL
	.long LD_H_A
	.long LD_L_B		# 68h
	.long LD_L_C
	.long LD_L_D
	.long LD_L_E
	.long LD_L_H
	.long NOP	#LD_L_L
	.long LD_L_xHL
	.long LD_L_A
	.long LD_xHL_B		# 70h
	.long LD_xHL_C
	.long LD_xHL_D
	.long LD_xHL_E
	.long LD_xHL_H
	.long LD_xHL_L
	.long HALT
	.long LD_xHL_A
	.long LD_A_B		# 78h
	.long LD_A_C
	.long LD_A_D
	.long LD_A_E
	.long LD_A_H
	.long LD_A_L
	.long LD_A_xHL
	.long NOP	#LD_A_A
	.long ADD_B		# 80h
	.long ADD_C
	.long ADD_D
	.long ADD_E
	.long ADD_H
	.long ADD_L
	.long ADD_xHL
	.long ADD_A
	.long ADC_B		# 88h
	.long ADC_C
	.long ADC_D
	.long ADC_E
	.long ADC_H
	.long ADC_L
	.long ADC_xHL
	.long ADC_A
	.long SUB_B		# 90h
	.long SUB_C
	.long SUB_D
	.long SUB_E
	.long SUB_H
	.long SUB_L
	.long SUB_xHL
	.long SUB_A
	.long SBC_B		# 98h
	.long SBC_C
	.long SBC_D
	.long SBC_E
	.long SBC_H
	.long SBC_L
	.long SBC_xHL
	.long SBC_A
	.long AND_B		# a0h
	.long AND_C
	.long AND_D
	.long AND_E
	.long AND_H
	.long AND_L
	.long AND_xHL
	.long AND_A
	.long XOR_B		# a8h
	.long XOR_C
	.long XOR_D
	.long XOR_E
	.long XOR_H
	.long XOR_L
	.long XOR_xHL
	.long XOR_A
	.long OR_B		# b0h
	.long OR_C
	.long OR_D
	.long OR_E
	.long OR_H
	.long OR_L
	.long OR_xHL
	.long OR_A
	.long CP_B		# b8h
	.long CP_C
	.long CP_D
	.long CP_E
	.long CP_H
	.long CP_L
	.long CP_xHL
	.long CP_A
	.long RET_NZ		# c0h
	.long POP_BC
	.long JP_NZ
	.long JP
	.long CALL_NZ
	.long PUSH_BC
	.long ADD_BYTE
	.long RST00
	.long RET_Z		# c8h
	.long RET
	.long JP_Z
	.long PFX_CB
	.long CALL_Z
	.long CALL
	.long ADC_BYTE
	.long RST08
	.long RET_NC		# d0h
	.long POP_DE
	.long JP_NC
	.long OUTA
	.long CALL_NC
	.long PUSH_DE
	.long SUB_BYTE
	.long RST10
	.long RET_C		# d8h
	.long EXX
	.long JP_C
	.long INA
	.long CALL_C
	.long PFX_DD
	.long SBC_BYTE
	.long RST18
	.long RET_PO		# e0h
	.long POP_HL
	.long JP_PO
	.long EX_HL_xSP
	.long CALL_PO
	.long PUSH_HL
	.long AND_BYTE
	.long RST20
	.long RET_PE		# e8h
	.long LD_PC_HL
	.long JP_PE
	.long EX_DE_HL
	.long CALL_PE
	.long PFX_ED
	.long XOR_BYTE
	.long RST28
	.long RET_P		# f0h
	.long POP_AF
	.long JP_P
	.long DI
	.long CALL_P
	.long PUSH_AF
	.long OR_BYTE
	.long RST30
	.long RET_M		# f8h
	.long LD_SP_HL
	.long JP_M
	.long EI
	.long CALL_M
	.long PFX_FD
	.long CP_BYTE
	.long RST38

.text
.macro M_JR_CC flag,cc
	testb flag,_F
	cc 0f
	incl %si
	jmp Ret_Z80
	.align 4,0x90
0:	M_JR
	jmp Ret_Z80
.endm

	.align 4,0x90
JR_NZ:	M_JR_CC Z_FLAG,jz
	.align 4,0x90
JR_NC:	M_JR_CC C_FLAG,jz
	.align 4,0x90
JR_Z:	M_JR_CC Z_FLAG,jnz
	.align 4,0x90
JR_C:	M_JR_CC C_FLAG,jnz

.macro M_JP_CC flag,cc
	testb flag,_F
	cc 0f
	incl %si
	incl %si
	jmp Ret_Z80
0:	M_JP
.endm

	.align 4,0x90
JP_NZ:	M_JP_CC Z_FLAG,jz
	.align 4,0x90
JP_NC:	M_JP_CC C_FLAG,jz
	.align 4,0x90
JP_PO:	M_JP_CC P_FLAG,jz
	.align 4,0x90
JP_P:	M_JP_CC S_FLAG,jz
	.align 4,0x90
JP_Z:	M_JP_CC Z_FLAG,jnz
	.align 4,0x90
JP_C:	M_JP_CC C_FLAG,jnz
	.align 4,0x90
JP_PE:	M_JP_CC P_FLAG,jnz
	.align 4,0x90
JP_M:	M_JP_CC S_FLAG,jnz

.macro M_RET_CC flag,cc
	testb flag,_F
	cc 0f
	jmp Ret_Z80
0:	M_RET
.endm

	.align 4,0x90
RET_NZ:	M_RET_CC Z_FLAG,jz
	.align 4,0x90
RET_NC:	M_RET_CC C_FLAG,jz
	.align 4,0x90
RET_PO:	M_RET_CC P_FLAG,jz
	.align 4,0x90
RET_P:	M_RET_CC S_FLAG,jz
	.align 4,0x90
RET_Z:	M_RET_CC Z_FLAG,jnz
	.align 4,0x90
RET_C:	M_RET_CC C_FLAG,jnz
	.align 4,0x90
RET_PE:	M_RET_CC P_FLAG,jnz
	.align 4,0x90
RET_M:	M_RET_CC S_FLAG,jnz

.macro M_CALL_CC flag,cc
	testb flag,_F
	cc 0f
	incl %esi
	incl %esi
	jmp Ret_Z80
0:	M_CALL
.endm

	.align 4,0x90
CALL_NZ:	M_CALL_CC Z_FLAG,jz
	.align 4,0x90
CALL_NC:	M_CALL_CC C_FLAG,jz
	.align 4,0x90
CALL_PO:	M_CALL_CC P_FLAG,jz
	.align 4,0x90
CALL_P:		M_CALL_CC S_FLAG,jz
	.align 4,0x90
CALL_Z:		M_CALL_CC Z_FLAG,jnz
	.align 4,0x90
CALL_C:		M_CALL_CC C_FLAG,jnz
	.align 4,0x90
CALL_PE:	M_CALL_CC P_FLAG,jnz
	.align 4,0x90
CALL_M:		M_CALL_CC S_FLAG,jnz

.macro M_X0 op,rg
	.align 4,0x90
oprg:	M_op rg
.endm

.macro M_X1 op
	M_X0 op,_B
	M_X0 op,_C
	M_X0 op,_D
	M_X0 op,_E
	M_X0 op,_H
	M_X0 op,_L
	M_X0 op,_A
	.align 4,0x90
op_xHL:
	movw _HL,%di
	M_ADDR
	M_op (%edi)
	.align 4,0x90
op_BYTE:
	M_RD_PC
	M_op %al
.endm

	M_X1 ADD
	M_X1 ADC
	M_X1 SUB
	M_X1 SBC
	M_X1 AND
	M_X1 OR
	M_X1 XOR
	M_X1 CP

.macro M_X1 op
	M_X0 op,_B
	M_X0 op,_C
	M_X0 op,_D
	M_X0 op,_E
	M_X0 op,_H
	M_X0 op,_L
	M_X0 op,_A
.endm

	M_X1 INC
	M_X1 DEC

	.align 4,0x90
INC_xHL:
	movw _HL,%di
	M_RDMEM
	incb %al
	pushf
	movw _HL,%di
	M_WRMEM
	popl %eax
	andl $0b0000100011010000,%eax
	rorb $1,%ah
	orb %ah,%al
	movb _F,%ah
	andb C_FLAG,%ah
	orb %ah,%al
	movb %al,_F
	jmp Ret_Z80

	.align 4,0x90
DEC_xHL:
	movw _HL,%di
	M_RDMEM
	decb %al
	pushf
	movw _HL,%di
	M_WRMEM
	popl %eax
	andl $0b0000100011010010,%eax
	rorb $1,%ah
	orb %ah,%al
	movb _F,%ah
	andb C_FLAG,%ah
	orb %ah,%al
	movb %al,_F
	jmp Ret_Z80

	.align 4,0x90
LD_BC_WORD:	M_LDWORD _BC
	.align 4,0x90
LD_DE_WORD:	M_LDWORD _DE
	.align 4,0x90
LD_HL_WORD:	M_LDWORD _HL
	.align 4,0x90
LD_SP_WORD:	M_LDWORD %bp

	.align 4,0x90
LD_PC_HL:
	movw _HL,%si
	jmp Ret_Z80
	.align 4,0x90
LD_SP_HL:
	movw _HL,%bp
	jmp Ret_Z80
	.align 4,0x90
LD_A_xBC:
	movw _BC,%di
	M_RDMEM
	movb %al,_A
	jmp Ret_Z80
	.align 4,0x90
LD_A_xDE:
	movw _DE,%di
	M_RDMEM
	movb %al,_A
	jmp Ret_Z80
	.align 4,0x90
LD_xBC_A:
	movw _BC,%di
	movb _A,%al
	M_WRMEM
	jmp Ret_Z80
	.align 4,0x90
LD_xDE_A:
	movw _DE,%di
	movb _A,%al
	M_WRMEM
	jmp Ret_Z80


	.align 4,0x90
ADD_HL_BC:	M_ADDW _HL,_BC
	.align 4,0x90
ADD_HL_DE:	M_ADDW _HL,_DE
	.align 4,0x90
ADD_HL_HL:	M_ADDW _HL,_HL
	.align 4,0x90
ADD_HL_SP:	M_ADDW _HL,%bp

	.align 4,0x90
DEC_BC:
	decw _BC
	jmp Ret_Z80
	.align 4,0x90
DEC_DE:
	decw _DE
	jmp Ret_Z80
	.align 4,0x90
DEC_HL:
	decw _HL
	jmp Ret_Z80
	.align 4,0x90
DEC_SP:
	decw %bp
	jmp Ret_Z80

	.align 4,0x90
INC_BC:
	incw _BC
	jmp Ret_Z80
	.align 4,0x90
INC_DE:
	incw _DE
	jmp Ret_Z80
	.align 4,0x90
INC_HL:
	incw _HL
	jmp Ret_Z80
	.align 4,0x90
INC_SP:
	incw %bp
	jmp Ret_Z80


	.align 4,0x90
RLCA:
	rolb $1,_A
	sbbb %al,%al
	andb C_FLAG,%al
	movb _F,%ah
	andb $0b11101100,%ah
	orb %al,%ah
	movb %ah,_F
	jmp Ret_Z80
	.align 4,0x90
RLA:
	movb _F,%al
	rorb $1,%al
	rclb $1,_A
	sbbb %al,%al
	andb C_FLAG,%al
	movb _F,%ah
	andb $0b11101100,%ah
	orb %al,%ah
	movb %ah,_F
	jmp Ret_Z80
	.align 4,0x90
RRCA:
	rorb $1,_A
	sbbb %al,%al
	andb C_FLAG,%al
	movb _F,%ah
	andb $0b11101100,%ah
	orb %al,%ah
	movb %ah,_F
	jmp Ret_Z80
	.align 4,0x90
RRA:
	movb _F,%al
	rorb $1,%al
	rcrb $1,_A
	sbbb %al,%al
	andb C_FLAG,%al
	movb _F,%ah
	andb $0b11101100,%ah
	orb %al,%ah
	movb %ah,_F
	jmp Ret_Z80


	.align 4,0x90
RST00: M_RST $0x00
	.align 4,0x90
RST08: M_RST $0x08
	.align 4,0x90
RST10: M_RST $0x10
	.align 4,0x90
RST18: M_RST $0x18
	.align 4,0x90
RST20: M_RST $0x20
	.align 4,0x90
RST28: M_RST $0x28
	.align 4,0x90
RST30: M_RST $0x30
	.align 4,0x90
RST38: M_RST $0x38

	.align 4,0x90
PUSH_BC: M_PUSH _BC
	.align 4,0x90
PUSH_DE: M_PUSH _DE
	.align 4,0x90
PUSH_HL: M_PUSH _HL
	.align 4,0x90
PUSH_AF: M_PUSH _AF

	.align 4,0x90
POP_BC: M_POP _BC
	.align 4,0x90
POP_DE: M_POP _DE
	.align 4,0x90
POP_HL: M_POP _HL
	.align 4,0x90
POP_AF: M_POP _AF

	.align 4,0x90
DJNZ:
	decb _B
	jz 0f
	M_JR
0:	incl %esi
	jmp Ret_Z80
	.align 4,0x90
JP:	M_JP
	.align 4,0x90
JR:	M_JR
	.align 4,0x90
CALL:	M_CALL
	.align 4,0x90
RET:	M_RET
	.align 4,0x90
SCF:
	orb C_FLAG,_F
	andb $0xed,_F
	jmp Ret_Z80
	.align 4,0x90
CPL:
	notb _A
	orb $0x12,_F
	jmp Ret_Z80
	.align 4,0x90
CCF:
	xorb C_FLAG,_F
	andb $0xfd,_F
	jmp Ret_Z80
	.align 4,0x90
NOP:
	jmp Ret_Z80
	.align 4,0x90
EI:
	orb $0x01,_IFF
	jmp Ret_Z80
	.align 4,0x90
DI:
	andb $0xfe,_IFF
	jmp Ret_Z80
	.align 4,0x90
OUTA:
	movzbl _A,%eax
	pushl %eax		# data
	M_RD_PC
	pushl %eax		# port
	call _DoOut
	addl $8,%esp
	jmp Ret_Z80
	.align 4,0x90
INA:
	M_RD_PC
	pushl %eax
	call _DoIn
	addl $4,%esp
	movb %al,_A
	jmp Ret_Z80

	.align 4,0x90
EXX:
	movw _BC,%ax
	xchgw %ax,_BC1
	movw %ax,_BC
	movl _DE,%eax
	xchgl %eax,_DE1
	movl %eax,_DE
	jmp Ret_Z80
	.align 4,0x90
EX_DE_HL:
	movw _HL,%ax
	xchgw %ax,_DE
	movw %ax,_HL
	jmp Ret_Z80
	.align 4,0x90
EX_AF_AF:
	movw _AF,%ax
	xchgw %ax,_AF1
	movw %ax,_AF
	jmp Ret_Z80

.macro M_X0 dst,src
	.align 4,0x90
LDdstsrc:
	movb src,%al
	movb %al,dst
	jmp Ret_Z80
.endm

.macro M_X1 rg
	M_X0 _B,rg
	M_X0 _C,rg
	M_X0 _D,rg
	M_X0 _E,rg
	M_X0 _H,rg
	M_X0 _L,rg
	M_X0 _A,rg
	.align 4,0x90
LD_xHLrg:
	movw _HL,%di
	movb rg,%al
	M_WRMEM
	jmp Ret_Z80
	.align 4,0x90
LDrg_xHL:
	movw _HL,%di
	M_RDMEM
	movb %al,rg
	jmp Ret_Z80
	.align 4,0x90
LDrg_BYTE:
	M_RD_PC
	movb %al,rg
	jmp Ret_Z80
.endm

	M_X1 _B
	M_X1 _C
	M_X1 _D
	M_X1 _E
	M_X1 _H
	M_X1 _L
	M_X1 _A


	.align 4,0x90
LD_xHL_BYTE:
	M_RD_PC
	movw _HL,%di
	M_WRMEM
	jmp Ret_Z80

	.align 4,0x90
LD_A_xWORD:
	M_RD_WORD %esi
	movl %eax,%edi
	M_RDMEM
	movb %al,_A
	jmp Ret_Z80
	.align 4,0x90
LD_xWORD_A:
	M_RD_WORD %esi
	movl %eax,%edi
	movb _A,%al
	M_WRMEM
	jmp Ret_Z80

	.align 4,0x90
EX_HL_xSP:
	movl %ebp,%edi
	M_RD_WORD %edi
	xchgw %ax,_HL
	movl %ebp,%edi
	pushl %eax
	pushl %edi
	M_WRMEM
	popl %edi
	popl %eax
	incl %edi
	movb %ah,%al
	M_WRMEM
	jmp Ret_Z80

	.align 4,0x90
DAA:
	movb _A,%al
	testb N_FLAG,_F
	jnz 4f
	testb H_FLAG,_F
	jnz 1f
	movb %al,%ah
	andb $0x0f,%ah
	cmpb $9,%ah
	jbe 2f
1:	addb $6,%al
	sbbb %ah,%ah
	andb C_FLAG,%ah
	orb H_FLAG,%ah
	orb %ah,_F
2:	testb C_FLAG,_F
	jnz 3f
	cmpb $0x9f,%al
	jbe 8f
3:	addb $0x60,%al
	orb C_FLAG,_F
	jmp 8f

4:	testb H_FLAG,_F
	jnz 5f
	movb %al,%ah
	andb $0x0f,%ah
	cmpb $9,%ah
	ja 5f
	jmp 6f
5:	subb $6,%al
	sbbb %ah,%ah
	andb C_FLAG,%ah
	orb H_FLAG,%ah
	orb %ah,_F
6:	testb C_FLAG,_F
	jnz 7f
	cmpb $0x9f,%al
	jbe 8f
7:	subb $0x60,%al
	orb C_FLAG,_F
8:	movb %al,_A
	orb %al,%al
	pushf
	popl %eax
	andb $0xc4,%al
	movb _F,%ah
	andb $0x3b,%ah
	orb %al,%ah
	movb %ah,_F
	jmp Ret_Z80

	.align 4,0x90
HALT:
	cmpl $0,_Cnt
	je 0f
	decl %esi
0:	jmp Ret_Z80

	.align 4,0x90
NO_DD:
	decl %esi
	decl %esi
	movl %esi,%edi
	decl %edi
	movw %di,_PC
	movw %bp,_SP
	pushl $regZ80
	call _undefTrap
	addl $4,%esp
	jmp Ret_Z80

	.align 4,0x90
NO_DC:
	subl $3,%esi
	movl %esi,%edi
	decl %edi
	movw %di,_PC
	movw %bp,_SP
	pushl $regZ80
	call _undefTrap
	addl $4,%esp
	jmp Ret_Z80

