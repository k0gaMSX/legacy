.data
	.align 4
Z80_Table_YY:
	.long NO_DD,NO_DD,NO_DD,NO_DD,NO_DD,NO_DD,NO_DD,NO_DD	#00
	.long NO_DD,ADD_XX_BC,NO_DD,NO_DD			#08
	.long NO_DD,NO_DD,NO_DD,NO_DD
	.long NO_DD,NO_DD,NO_DD,NO_DD,NO_DD,NO_DD,NO_DD,NO_DD	#10
	.long NO_DD,ADD_XX_DE,NO_DD,NO_DD			#18
	.long NO_DD,NO_DD,NO_DD,NO_DD
	.long NO_DD,LD_XX_WORD,LD_xWORD_XX,INC_XX		#20
	.long INC_XXH,DEC_XXH,LD_XXH_BYTE,NO_DD
	.long NO_DD,ADD_XX_XX,LD_XX_xWORD,DEC_XX		#28
	.long INC_XXL,DEC_XXL,LD_XXL_BYTE,NO_DD
	.long NO_DD,NO_DD,NO_DD,NO_DD				#30
	.long INC_xXX,DEC_xXX,LD_xXX_BYTE,NO_DD
	.long NO_DD,ADD_XX_SP,NO_DD,NO_DD			#38
	.long NO_DD,NO_DD,NO_DD,NO_DD
	.long NO_DD,NO_DD,NO_DD,NO_DD				#40
	.long LD_B_XXH,LD_B_XXL,LD_B_xXX,NO_DD
	.long NO_DD,NO_DD,NO_DD,NO_DD				#48
	.long LD_C_XXH,LD_C_XXL,LD_C_xXX,NO_DD
	.long NO_DD,NO_DD,NO_DD,NO_DD				#50
	.long LD_D_XXH,LD_D_XXL,LD_D_xXX,NO_DD
	.long NO_DD,NO_DD,NO_DD,NO_DD				#58
	.long LD_E_XXH,LD_E_XXL,LD_E_xXX,NO_DD
	.long LD_XXH_B,LD_XXH_C,LD_XXH_D,LD_XXH_E		#60
	.long NOP,LD_XXH_XXL,LD_H_xXX,LD_XXH_A
	.long LD_XXL_B,LD_XXL_C,LD_XXL_D,LD_XXL_E		#68
	.long LD_XXL_XXH,NOP,LD_L_xXX,LD_XXL_A
	.long LD_xXX_B,LD_xXX_C,LD_xXX_D,LD_xXX_E		#70
	.long LD_xXX_H,LD_xXX_L,NO_DD,LD_xXX_A
	.long NO_DD,NO_DD,NO_DD,NO_DD				#78
	.long LD_A_XXH,LD_A_XXL,LD_A_xXX,NO_DD
	.long NO_DD,NO_DD,NO_DD,NO_DD				#80
	.long ADD_XXH,ADD_XXL,ADD_xXX,NO_DD
	.long NO_DD,NO_DD,NO_DD,NO_DD				#88
	.long ADC_XXH,ADC_XXL,ADC_xXX,NO_DD
	.long NO_DD,NO_DD,NO_DD,NO_DD				#90
	.long SUB_XXH,SUB_XXL,SUB_xXX,NO_DD
	.long NO_DD,NO_DD,NO_DD,NO_DD				#98
	.long SBC_XXH,SBC_XXL,SBC_xXX,NO_DD
	.long NO_DD,NO_DD,NO_DD,NO_DD				#a0
	.long AND_XXH,AND_XXL,AND_xXX,NO_DD
	.long NOP ,NOP ,NO_DD,NO_DD			#a8
	.long XOR_XXH,XOR_XXL,XOR_xXX,NO_DD
	.long NO_DD,NO_DD,NO_DD,NO_DD			#b0
	.long OR_XXH,OR_XXL,OR_xXX,NO_DD
	.long NO_DD,NO_DD,NO_DD,NO_DD			#b8
	.long CP_XXH,CP_XXL,CP_xXX,NO_DD
	.long NO_DD,NO_DD,NO_DD,NO_DD,NO_DD,NO_DD,NO_DD,NO_DD	#c0
	.long NO_DD,NO_DD,NO_DD		#c8
	.long PFX_YY_CB
	.long NO_DD,NO_DD,NO_DD,NO_DD
	.long NO_DD,NO_DD,NO_DD,NO_DD,NO_DD,NO_DD,NO_DD,NO_DD	#d0
	.long NO_DD,NO_DD,NO_DD,NO_DD,NO_DD,NO_DD,NO_DD,NO_DD	#d8
	.long NO_DD		#e0
	.long POP_XX
	.long NOP
	.long EX_XX_xSP
	.long NO_DD
	.long PUSH_XX
	.long NO_DD,NO_DD
	.long NO_DD		#e8
	.long LD_PC_XX
	.long NO_DD,NO_DD,NO_DD,NO_DD,NO_DD,NO_DD
	.long NO_DD,NO_DD,NO_DD,NO_DD,NO_DD,NO_DD,NO_DD,NO_DD	#f0
	.long NO_DD		#f8
	.long LD_SP_XX
	.long NO_DD,NO_DD,NO_DD,NO_DD,NO_DD,NO_DD

.text
	.align 4,0x90
PFX_YY:
	M_RD_WORD %esi
	movsbl %ah,%edi
	addw _XX,%di
	movzbl %al,%eax
	jmp Z80_Table_YY(,%eax,4)

	.align 4,0x90
ADD_XX_BC:
	decl %esi
	M_ADDW _XX,_BC
	.align 4,0x90
ADD_XX_DE:
	decl %esi
	M_ADDW _XX,_DE
	.align 4,0x90
ADD_XX_XX:
	decl %esi
	M_ADDW _XX,_XX
	.align 4,0x90
ADD_XX_SP:
	decl %esi
	M_ADDW _XX,%bp

	.align 4,0x90
LD_XX_WORD:
	decl %esi
	M_LDWORD _XX
	.align 4,0x90
LD_xWORD_XX:
	decl %esi
	M_LD_xWORD_R2 _XX
	.align 4,0x90
LD_XX_xWORD:
	decl %esi
	M_LD_R2_xWORD _XX

	.align 4,0x90
INC_XX:
	decl %esi
	incw _XX
	jmp Ret_Z80
	.align 4,0x90
DEC_XX:
	decl %esi
	decw _XX
	jmp Ret_Z80

	.align 4,0x90
PUSH_XX:
	decl %esi
	M_PUSH _XX
	.align 4,0x90
POP_XX:
	decl %esi
	M_POP _XX
	.align 4,0x90
EX_XX_xSP:
	decl %esi
	movl %ebp,%edi
	M_RD_WORD %edi
	xchgw %ax,_XX
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
LD_PC_XX:
	movw _XX,%si
	jmp Ret_Z80
	.align 4,0x90
LD_SP_XX:
	decl %esi
	movw _XX,%bp
	jmp Ret_Z80

	.align 4,0x90
LD_xXX_BYTE:
	M_RD_PC
	M_WRMEM
	jmp Ret_Z80
	.align 4,0x90
LD_XXH_BYTE:
	decl %esi
	M_RD_PC
	movb %al,_XXH
	jmp Ret_Z80
	.align 4,0x90
LD_XXL_BYTE:
	decl %esi
	M_RD_PC
	movb %al,_XXL
	jmp Ret_Z80

.macro M_LD_R_HL rg
	.align 4,0x90
LDrg_xXX:
	M_RDMEM
	movb %al,rg
	jmp Ret_Z80
	.align 4,0x90
LDrg_XXH:
	decl %esi
	movb _XXH,%al
	movb %al,rg
	jmp Ret_Z80
	.align 4,0x90
LDrg_XXL:
	decl %esi
	movb _XXL,%al
	movb %al,rg
	jmp Ret_Z80
.endm

.macro M_LD_HL_R rg
	.align 4,0x90
LD_xXXrg:
	movb rg,%al
	M_WRMEM
	jmp Ret_Z80
	.align 4,0x90
LD_XXHrg:
	decl %esi
	movb rg,%al
	movb %al,_XXH
	jmp Ret_Z80
	.align 4,0x90
LD_XXLrg:
	decl %esi
	movb rg,%al
	movb %al,_XXL
	jmp Ret_Z80
.endm

	M_LD_R_HL _B
	M_LD_R_HL _C
	M_LD_R_HL _D
	M_LD_R_HL _E
	M_LD_R_HL _H
	M_LD_R_HL _L
	M_LD_R_HL _A

	M_LD_HL_R _B
	M_LD_HL_R _C
	M_LD_HL_R _D
	M_LD_HL_R _E
	M_LD_HL_R _H
	M_LD_HL_R _L
	M_LD_HL_R _A

	.align 4,0x90
LD_XXH_XXL:
	decl %esi
	movb _XXL,%al
	movb %al,_XXH
	jmp Ret_Z80
	.align 4,0x90
LD_XXL_XXH:
	decl %esi
	movb _XXH,%al
	movb %al,_XXL
	jmp Ret_Z80

.macro M_X3 op
	.align 4,0x90
op_xXX:
	M_ADDR
	M_op (%edi)
	.align 4,0x90
op_XXH:
	decl %esi
	M_op _XXH
	.align 4,0x90
op_XXL:
	decl %esi
	M_op _XXL
.endm

	M_X3 ADD
	M_X3 ADC
	M_X3 SUB
	M_X3 SBC
	M_X3 AND
	M_X3 OR
	M_X3 XOR
	M_X3 CP

	.align 4,0x90
INC_XXH:
	decl %esi
	M_INC _XXH
	.align 4,0x90
INC_XXL:
	decl %esi
	M_INC _XXL
	.align 4,0x90
DEC_XXH:
	decl %esi
	M_DEC _XXH
	.align 4,0x90
DEC_XXL:
	decl %esi
	M_DEC _XXL

	.align 4,0x90
INC_xXX:
	pushl %edi
	M_RDMEM
	popl %edi
	incb %al
	pushf
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
DEC_xXX:
	pushl %edi
	M_RDMEM
	popl %edi
	decb %al
	pushf
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
PFX_YY_CB:
	M_RD_PC
	movzbl %al,%eax
	jmp Z80_Table_YY_CB(,%eax,4)
.include "codesxcb.inc"

