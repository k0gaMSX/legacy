; Z80 emulation core
; Copyright (C) 1998 by Jimmy Mårdell
; Based on the Z80 core in the CPE emulator by Berndt Schmidt
;
; Should be compiled with NASMW


GLOBAL _emZ80,_resetZ80,_setZ80regs,_getZ80regs
GLOBAL _Bank01,_Bank11,_Bank21,_Bank31,_Bank02,_Bank12,_Bank22,_Bank32,_EmptyBank
GLOBAL _BankSelect,_BankROM
GLOBAL _rFA,_rBC,_rDE,_rHL,_rIX,_rIY,_rSP,_rPC
GLOBAL _rsFA,_rsBC,_rsDE,_rsHL,_rI,_rR,_rIFF
GLOBAL _cycles,_imode

EXTERN _doOut,_doIn,_debug,_interrupt
EXTERN _intrq,_frames
EXTERN _trace,_brk,_quit
EXTERN _tapeFindProg,_tapeRead,_tapeWrite

%define rPC 	si
%define ErPC	esi
%define	rBC		cx
%define rDE		dx
%define rHL		bx
%define rFA		ax
%define rA		al
%define rF		ah
%define rB		ch
%define rC		cl
%define rD		dh
%define rE		dl
%define rH		bh
%define rL		bl

fgC			EQU		0x01
fgN			EQU		0x02
fgP			EQU		0x04
fgV			EQU		0x04
fgH			EQU		0x10
fgZ			EQU		0x40
fgS			EQU		0x80

ifreq		EQU		16550

%include "z80.mac"

SECTION .text

; int emZ80(void)

_emZ80:
	push	ebp	
	RestoreZ80regs
EmZ80:	
	cmp		word [_cycles],ifreq
	jc		CheckIRQ
	sub		word [_cycles],ifreq
	BackupZ80regs
	call	_interrupt	
	RestoreZ80regs
CheckIRQ:
	cmp		byte [_intrq],0
	jz 		near NoIntReq
	cmp		byte [_rIFF],0
	jz 		near NoIntReq
	mov		byte [_rIFF],0
	push	ax
	mRDMEMB rPC,al
	cmp		al,0x76
	jnz		NotHalt
	inc		rPC
NotHalt:
	mov		ax,rPC
	mPUSH ah,al
	pop		ax
	mov		rPC,0x0038
NoIntReq:
	cmp		word [_trace],0
	jnz		CallDebug
	cmp		rPC,[_brk]
	jnz		EmInstr
	cmp		dword [_brk],-1
	jz		EmInstr
CallDebug:
	BackupZ80regs
	call	_debug
	RestoreZ80regs
EmInstr:
	mRDMEM rPC,edi	
	inc		rPC
	mov		bp,[clocks+edi*2]		
	add		[_cycles],bp
	inc		byte [_rR]
	jmp		[optable+edi*4]
Z80cont:	
	cmp		word [_quit],0
	jz		near EmZ80
	movsx	ax,[_quit]
	pop		ebp
	ret

; void resetZ80(void);

_resetZ80:
	push	ebp
	xor		eax,eax
	mov		edi,Z80_vars
	mov		ecx,Z80_vars_end-Z80_vars
	cld
	rep 	stosb
	pop		ebp
	ret

; void setZ80regs(Z80regsT*);

_setZ80regs:
	push	ebp
	mov		ebp,esp
	mov		esi,[ebp+8]
	mov		edi,Z80_vars
	mov		ecx,Z80_vars_end-Z80_vars
	cld
	rep 	movsb
	pop		ebp
	ret
	
; void getZ80regs(Z80regsT*);

_getZ80regs:
	push	ebp
	mov		ebp,esp
	mov		edi,[ebp+8]
	mov		esi,Z80_vars
	mov		ecx,Z80_vars_end-Z80_vars
	cld
	rep 	movsb
	pop		ebp
	ret

II:
	mov		word [_trace],1
	mEOI
	
iHALT:
	dec		rPC	
	mEOI
	
iCB:
	mRDMEM rPC,edi
	inc		rPC
	mov		bp,[clocksCB+edi*2]		
	add		[_cycles],bp
	inc		byte [_rR]
	jmp		[CBoptable+edi*4]
iED:	
	mRDMEM rPC,edi
	inc		rPC
	mov		bp,[clocksED+edi*2]		
	add		[_cycles],bp
	inc		byte [_rR]
	jmp		[EDoptable+edi*4]
iIX:
	mRDMEM rPC,edi
	inc		rPC
	mov		bp,[clocksXX+edi*2]		
	add		[_cycles],bp
	inc		byte [_rR]
	jmp		[DDoptable+edi*4]
iIY:
	mRDMEM rPC,edi
	inc		rPC
	mov		bp,[clocksXX+edi*2]		
	add		[_cycles],bp
	inc		byte [_rR]
	jmp		[FDoptable+edi*4]
iIXCB:
	calcind X
	push	di
	mRDMEM rPC,edi
	inc		rPC
	mov		bp,[clocksXXCB+edi*2]
	add		[_cycles],bp
	jmp		[DDCBoptable+edi*4]	
iIYCB:	
	calcind Y
	push	di
	mRDMEM rPC,edi
	inc		rPC
	mov		bp,[clocksXXCB+edi*2]
	add		[_cycles],bp
	jmp		[FDCBoptable+edi*4]	
	
tapeFindProg:
	BackupZ80regs F
	call	_tapeFindProg
	RestoreZ80regs F
	mRET
	
tapeRead:
	BackupZ80regs A,F
	call	_tapeRead
	RestoreZ80regs A,F
	mRET
	
tapeWrite:
	BackupZ80regs F
	push	eax
	call	_tapeWrite
	add		esp,4
	RestoreZ80regs F
	mov		rPC,0x20ED
	mEOI

%include "instr.asm"
	
SECTION .data

; Z80 variables

Z80_vars:

_cycles:		dw 0
_imode:			dd 0

_rFA:
_rA:				db 0
_rF:				db 0
_rBC:				dw 0
_rDE:				dw 0
_rHL:				dw 0
_rIX:				dw 0
_rIY:				dw 0
_rPC:				dw 0
_rSP:				dw 0
_rsFA:			dw 0
_rsBC:			dw 0
_rsDE:			dw 0
_rsHL:			dw 0
_rI:				db 0
_rR:				db 0
_rIFF:			db 0

_rIXH				equ _rIX+1
_rIXL				equ _rIX
_rIYH				equ _rIY+1
_rIYL				equ _rIY


Z80_vars_end

; End of Z80 variables

clocks:
	dw 1,3,2,1, 1,1,2,1, 1,3,2,1, 1,1,2,1  ; 0x00
	dw 2,3,2,1, 1,1,2,1, 3,3,2,1, 1,1,2,1  ; 0x10
	dw 2,3,5,1, 1,1,2,1, 2,3,5,1, 1,1,2,1  ; 0x20
	dw 2,3,4,1, 3,3,3,1, 2,3,4,1, 1,1,2,1  ; 0x30
	dw 1,1,1,1, 1,1,2,1, 1,1,1,1, 1,1,2,1  ; 0x40
	dw 1,1,1,1, 1,1,2,1, 1,1,1,1, 1,1,2,1  ; 0x50
	dw 1,1,1,1, 1,1,2,1, 1,1,1,1, 1,1,2,1  ; 0x60
	dw 2,2,2,2, 2,2,1,2, 1,1,1,1, 1,1,2,1  ; 0x70
	dw 1,1,1,1, 1,1,2,1, 1,1,1,1, 1,1,2,1  ; 0x80
	dw 1,1,1,1, 1,1,2,1, 1,1,1,1, 1,1,2,1  ; 0x90
	dw 1,1,1,1, 1,1,2,1, 1,1,1,1, 1,1,2,1  ; 0xA0
	dw 1,1,1,1, 1,1,2,1, 1,1,1,1, 1,1,2,1  ; 0xB0
	dw 1,3,3,3, 3,3,2,3, 1,3,3,0, 3,5,2,3  ; 0xC0
	dw 1,3,3,3, 3,3,2,3, 1,1,3,3, 3,0,2,3  ; 0xD0
	dw 1,3,3,5, 3,3,2,3, 1,1,3,1, 3,0,2,3  ; 0xE0
	dw 1,3,3,1, 3,3,2,3, 1,1,3,1, 3,0,2,3  ; 0xF0

clocksXX:
	dw 0,0,0,0, 0,0,0,0, 0,4,0,0, 0,0,0,0  ; 0x00
	dw 0,0,0,0, 0,0,0,0, 0,4,0,0, 0,0,0,0  ; 0x10
	dw 0,4,6,2, 0,0,0,0, 0,4,6,2, 0,0,0,0  ; 0x20
	dw 0,0,0,0, 6,6,5,0, 0,4,0,0, 0,0,0,0  ; 0x30
	dw 0,0,0,0, 0,0,5,0, 0,0,0,0, 0,0,5,0  ; 0x40
	dw 0,0,0,0, 0,0,5,0, 0,0,0,0, 0,0,5,0  ; 0x50
	dw 0,0,0,0, 0,0,5,0, 0,0,0,0, 0,0,5,0  ; 0x60
	dw 5,5,5,5, 5,5,0,5, 0,0,0,0, 0,0,5,0  ; 0x70
	dw 0,0,0,0, 0,0,5,0, 0,0,0,0, 0,0,5,0  ; 0x80
	dw 0,0,0,0, 0,0,5,0, 0,0,0,0, 0,0,5,0  ; 0x90
	dw 0,0,0,0, 0,0,5,0, 0,0,0,0, 0,0,5,0  ; 0xA0
	dw 0,0,0,0, 0,0,5,0, 0,0,0,0, 0,0,5,0  ; 0xB0
	dw 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0  ; 0xC0
	dw 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0  ; 0xD0
	dw 0,3,0,6, 0,4,0,0, 0,2,0,0, 0,0,0,0  ; 0xE0
	dw 0,0,0,0, 0,0,0,0, 0,2,0,0, 0,0,0,0  ; 0xF0

clocksED:
	dw 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0  ; 0x00
	dw 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0  ; 0x10
	dw 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0  ; 0x20
	dw 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0  ; 0x30
	dw 3,3,4,6, 2,2,2,2, 3,3,4,6, 0,4,0,2  ; 0x40
	dw 3,3,4,6, 0,0,2,2, 3,3,4,6, 0,0,2,2  ; 0x50
	dw 3,3,4,6, 0,0,0,5, 3,3,4,6, 0,0,0,5  ; 0x60
	dw 3,0,4,6, 0,0,0,0, 3,3,4,6, 0,0,0,0  ; 0x70
	dw 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0  ; 0x80
	dw 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0  ; 0x90
	dw 4,4,4,4, 0,0,0,0, 4,4,4,4, 0,0,0,0  ; 0xA0
	dw 4,4,4,4, 0,0,0,0, 4,4,4,4, 0,0,0,0  ; 0xB0
	dw 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0  ; 0xC0
	dw 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0  ; 0xD0
	dw 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0  ; 0xE0
	dw 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0  ; 0xF0

clocksCB:
	dw 2,2,2,2, 2,2,4,2, 2,2,2,2, 2,2,4,2  ; 0x00
	dw 2,2,2,2, 2,2,4,2, 2,2,2,2, 2,2,4,2  ; 0x10
	dw 2,2,2,2, 2,2,4,2, 2,2,2,2, 2,2,4,2  ; 0x20
	dw 2,2,2,2, 2,2,4,2, 2,2,2,2, 2,2,4,2  ; 0x30
	dw 2,2,2,2, 2,2,3,2, 2,2,2,2, 2,2,3,2  ; 0x40
	dw 2,2,2,2, 2,2,3,2, 2,2,2,2, 2,2,3,2  ; 0x50
	dw 2,2,2,2, 2,2,3,2, 2,2,2,2, 2,2,3,2  ; 0x60
	dw 2,2,2,2, 2,2,3,2, 2,2,2,2, 2,2,3,2  ; 0x70
	dw 2,2,2,2, 2,2,4,2, 2,2,2,2, 2,2,4,2  ; 0x80
	dw 2,2,2,2, 2,2,4,2, 2,2,2,2, 2,2,4,2  ; 0x90
	dw 2,2,2,2, 2,2,4,2, 2,2,2,2, 2,2,4,2  ; 0xA0
	dw 2,2,2,2, 2,2,4,2, 2,2,2,2, 2,2,4,2  ; 0xB0
	dw 2,2,2,2, 2,2,4,2, 2,2,2,2, 2,2,4,2  ; 0xC0
	dw 2,2,2,2, 2,2,4,2, 2,2,2,2, 2,2,4,2  ; 0xD0
	dw 2,2,2,2, 2,2,4,2, 2,2,2,2, 2,2,4,2  ; 0xE0
	dw 2,2,2,2, 2,2,4,2, 2,2,2,2, 2,2,4,2  ; 0xF0

clocksXXCB:
	dw 0,0,0,0, 0,0,6,0, 0,0,0,0, 0,0,6,0  ; 0x00
	dw 0,0,0,0, 0,0,6,0, 0,0,0,0, 0,0,6,0  ; 0x10
	dw 0,0,0,0, 0,0,6,0, 0,0,0,0, 0,0,6,0  ; 0x20
	dw 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,6,0  ; 0x30
	dw 0,0,0,0, 0,0,5,0, 0,0,0,0, 0,0,5,0  ; 0x40
	dw 0,0,0,0, 0,0,5,0, 0,0,0,0, 0,0,5,0  ; 0x50
	dw 0,0,0,0, 0,0,5,0, 0,0,0,0, 0,0,5,0  ; 0x60
	dw 0,0,0,0, 0,0,5,0, 0,0,0,0, 0,0,5,0  ; 0x70
	dw 0,0,0,0, 0,0,6,0, 0,0,0,0, 0,0,6,0  ; 0x80
	dw 0,0,0,0, 0,0,6,0, 0,0,0,0, 0,0,6,0  ; 0x90
	dw 0,0,0,0, 0,0,6,0, 0,0,0,0, 0,0,6,0  ; 0xA0
	dw 0,0,0,0, 0,0,6,0, 0,0,0,0, 0,0,6,0  ; 0xB0
	dw 0,0,0,0, 0,0,6,0, 0,0,0,0, 0,0,6,0  ; 0xC0
	dw 0,0,0,0, 0,0,6,0, 0,0,0,0, 0,0,6,0  ; 0xD0
	dw 0,0,0,0, 0,0,6,0, 0,0,0,0, 0,0,6,0  ; 0xE0
	dw 0,0,0,0, 0,0,6,0, 0,0,0,0, 0,0,6,0  ; 0xF0

optable:
	dd iNOP,iLD_BC_nn,iLD_mBC_A,iINC_BC,iINC_B,iDEC_B,iLD_B_n,iRLCA
	dd iEX_AF_AFp,iADD_HL_BC,iLD_A_mBC,iDEC_BC,iINC_C,iDEC_C,iLD_C_n,iRRCA
	dd iDJNZ,iLD_DE_nn,iLD_mDE_A,iINC_DE,iINC_D,iDEC_D,iLD_D_n,iRLA
	dd iJR,iADD_HL_DE,iLD_A_mDE,iDEC_DE,iINC_E,iDEC_E,iLD_E_n,iRRA
	dd iJR_NZ,iLD_HL_nn,iLD_mnn_HL,iINC_HL,iINC_H,iDEC_H,iLD_H_n,iDAA
	dd iJR_Z,iADD_HL_HL,iLD_HL_mnn,iDEC_HL,iINC_L,iDEC_L,iLD_L_n,iCPL
	dd iJR_NC,iLD_SP_nn,iLD_mnn_A,iINC_SP,iINC_mHL,iDEC_mHL,iLD_mHL_n,iSCF
	dd iJR_C,iADD_HL_SP,iLD_A_mnn,iDEC_SP,iINC_A,iDEC_A,iLD_A_n,iCCF
	dd iLD_B_B,iLD_B_C,iLD_B_D,iLD_B_E,iLD_B_H,iLD_B_L,iLD_B_mHL,iLD_B_A
	dd iLD_C_B,iLD_C_C,iLD_C_D,iLD_C_E,iLD_C_H,iLD_C_L,iLD_C_mHL,iLD_C_A	
	dd iLD_D_B,iLD_D_C,iLD_D_D,iLD_D_E,iLD_D_H,iLD_D_L,iLD_D_mHL,iLD_D_A	
	dd iLD_E_B,iLD_E_C,iLD_E_D,iLD_E_E,iLD_E_H,iLD_E_L,iLD_E_mHL,iLD_E_A	
	dd iLD_H_B,iLD_H_C,iLD_H_D,iLD_H_E,iLD_H_H,iLD_H_L,iLD_H_mHL,iLD_H_A	
	dd iLD_L_B,iLD_L_C,iLD_L_D,iLD_L_E,iLD_L_H,iLD_L_L,iLD_L_mHL,iLD_L_A	
	dd iLD_mHL_B,iLD_mHL_C,iLD_mHL_D,iLD_mHL_E,iLD_mHL_H,iLD_mHL_L,iHALT,iLD_mHL_A	
	dd iLD_A_B,iLD_A_C,iLD_A_D,iLD_A_E,iLD_A_H,iLD_A_L,iLD_A_mHL,iLD_A_A	
	dd iADD_A_B,iADD_A_C,iADD_A_D,iADD_A_E,iADD_A_H,iADD_A_L,iADD_A_mHL,iADD_A_A
	dd iADC_A_B,iADC_A_C,iADC_A_D,iADC_A_E,iADC_A_H,iADC_A_L,iADC_A_mHL,iADC_A_A
	dd iSUB_B,iSUB_C,iSUB_D,iSUB_E,iSUB_H,iSUB_L,iSUB_mHL,iSUB_A
	dd iSBC_A_B,iSBC_A_C,iSBC_A_D,iSBC_A_E,iSBC_A_H,iSBC_A_L,iSBC_A_mHL,iSBC_A_A
	dd iAND_B,iAND_C,iAND_D,iAND_E,iAND_H,iAND_L,iAND_mHL,iAND_A
	dd iXOR_B,iXOR_C,iXOR_D,iXOR_E,iXOR_H,iXOR_L,iXOR_mHL,iXOR_A
	dd iOR_B,iOR_C,iOR_D,iOR_E,iOR_H,iOR_L,iOR_mHL,iOR_A
	dd iCP_B,iCP_C,iCP_D,iCP_E,iCP_H,iCP_L,iCP_mHL,iCP_A
	dd iRET_NZ,iPOP_BC,iJP_NZ,iJP,iCALL_NZ,iPUSH_BC,iADD_A_n,iRST_00H
	dd iRET_Z,iRET_,iJP_Z,iCB,iCALL_Z,iCALL,iADC_A_n,iRST_08H
	dd iRET_NC,iPOP_DE,iJP_NC,iOUT_n_A,iCALL_NC,iPUSH_DE,iSUB_n,iRST_10H
	dd iRET_C,iEXX,iJP_C,iIN_A_n,iCALL_C,iIX,iSBC_A_n,iRST_18H
	dd iRET_PO,iPOP_HL,iJP_PO,iEX_mSP_HL,iCALL_PO,iPUSH_HL,iAND_n,iRST_20H
	dd iRET_PE,iJP_mHL,iJP_PE,iEX_DE_HL,iCALL_PE,iED,iXOR_n,iRST_28H
	dd iRET_P,iPOP_AF,iJP_P,iDI,iCALL_P,iPUSH_AF,iOR_n,iRST_30H
	dd iRET_M,iLD_SP_HL,iJP_M,iEI,iCALL_M,iIY,iCP_n,iRST_38H

CBoptable:
	dd iRLC_B,iRLC_C,iRLC_D,iRLC_E,iRLC_H,iRLC_L,iRLC_mHL,iRLC_A
	dd iRRC_B,iRRC_C,iRRC_D,iRRC_E,iRRC_H,iRRC_L,iRRC_mHL,iRRC_A
	dd iRL_B,iRL_C,iRL_D,iRL_E,iRL_H,iRL_L,iRL_mHL,iRL_A
	dd iRR_B,iRR_C,iRR_D,iRR_E,iRR_H,iRR_L,iRR_mHL,iRR_A
	dd iSLA_B,iSLA_C,iSLA_D,iSLA_E,iSLA_H,iSLA_L,iSLA_mHL,iSLA_A
	dd iSRA_B,iSRA_C,iSRA_D,iSRA_E,iSRA_H,iSRA_L,iSRA_mHL,iSRA_A
	dd iSLL_B,iSLL_C,iSLL_D,iSLL_E,iSLL_H,iSLL_L,iSLL_mHL,iSLL_A
	dd iSRL_B,iSRL_C,iSRL_D,iSRL_E,iSRL_H,iSRL_L,iSRL_mHL,iSRL_A
	dd iBIT_0_B,iBIT_0_C,iBIT_0_D,iBIT_0_E,iBIT_0_H,iBIT_0_L,iBIT_0_mHL,iBIT_0_A
	dd iBIT_1_B,iBIT_1_C,iBIT_1_D,iBIT_1_E,iBIT_1_H,iBIT_1_L,iBIT_1_mHL,iBIT_1_A
	dd iBIT_2_B,iBIT_2_C,iBIT_2_D,iBIT_2_E,iBIT_2_H,iBIT_2_L,iBIT_2_mHL,iBIT_2_A
	dd iBIT_3_B,iBIT_3_C,iBIT_3_D,iBIT_3_E,iBIT_3_H,iBIT_3_L,iBIT_3_mHL,iBIT_3_A
	dd iBIT_4_B,iBIT_4_C,iBIT_4_D,iBIT_4_E,iBIT_4_H,iBIT_4_L,iBIT_4_mHL,iBIT_4_A
	dd iBIT_5_B,iBIT_5_C,iBIT_5_D,iBIT_5_E,iBIT_5_H,iBIT_5_L,iBIT_5_mHL,iBIT_5_A
	dd iBIT_6_B,iBIT_6_C,iBIT_6_D,iBIT_6_E,iBIT_6_H,iBIT_6_L,iBIT_6_mHL,iBIT_6_A
	dd iBIT_7_B,iBIT_7_C,iBIT_7_D,iBIT_7_E,iBIT_7_H,iBIT_7_L,iBIT_7_mHL,iBIT_7_A
	dd iRES_0_B,iRES_0_C,iRES_0_D,iRES_0_E,iRES_0_H,iRES_0_L,iRES_0_mHL,iRES_0_A
	dd iRES_1_B,iRES_1_C,iRES_1_D,iRES_1_E,iRES_1_H,iRES_1_L,iRES_1_mHL,iRES_1_A
	dd iRES_2_B,iRES_2_C,iRES_2_D,iRES_2_E,iRES_2_H,iRES_2_L,iRES_2_mHL,iRES_2_A
	dd iRES_3_B,iRES_3_C,iRES_3_D,iRES_3_E,iRES_3_H,iRES_3_L,iRES_3_mHL,iRES_3_A
	dd iRES_4_B,iRES_4_C,iRES_4_D,iRES_4_E,iRES_4_H,iRES_4_L,iRES_4_mHL,iRES_4_A
	dd iRES_5_B,iRES_5_C,iRES_5_D,iRES_5_E,iRES_5_H,iRES_5_L,iRES_5_mHL,iRES_5_A
	dd iRES_6_B,iRES_6_C,iRES_6_D,iRES_6_E,iRES_6_H,iRES_6_L,iRES_6_mHL,iRES_6_A
	dd iRES_7_B,iRES_7_C,iRES_7_D,iRES_7_E,iRES_7_H,iRES_7_L,iRES_7_mHL,iRES_7_A
	dd iSET_0_B,iSET_0_C,iSET_0_D,iSET_0_E,iSET_0_H,iSET_0_L,iSET_0_mHL,iSET_0_A
	dd iSET_1_B,iSET_1_C,iSET_1_D,iSET_1_E,iSET_1_H,iSET_1_L,iSET_1_mHL,iSET_1_A
	dd iSET_2_B,iSET_2_C,iSET_2_D,iSET_2_E,iSET_2_H,iSET_2_L,iSET_2_mHL,iSET_2_A
	dd iSET_3_B,iSET_3_C,iSET_3_D,iSET_3_E,iSET_3_H,iSET_3_L,iSET_3_mHL,iSET_3_A
	dd iSET_4_B,iSET_4_C,iSET_4_D,iSET_4_E,iSET_4_H,iSET_4_L,iSET_4_mHL,iSET_4_A
	dd iSET_5_B,iSET_5_C,iSET_5_D,iSET_5_E,iSET_5_H,iSET_5_L,iSET_5_mHL,iSET_5_A
	dd iSET_6_B,iSET_6_C,iSET_6_D,iSET_6_E,iSET_6_H,iSET_6_L,iSET_6_mHL,iSET_6_A
	dd iSET_7_B,iSET_7_C,iSET_7_D,iSET_7_E,iSET_7_H,iSET_7_L,iSET_7_mHL,iSET_7_A

DDoptable:
	dd iNOP,iLD_BC_nn,iLD_mBC_A,iINC_BC,iINC_B,iDEC_B,iLD_B_n,iRLCA
	dd iEX_AF_AFp,iADD_IX_BC,iLD_A_mBC,iDEC_BC,iINC_C,iDEC_C,iLD_C_n,iRRCA
	dd iDJNZ,iLD_DE_nn,iLD_mDE_A,iINC_DE,iINC_D,iDEC_D,iLD_D_n,iRLA
	dd iJR,iADD_IX_DE,iLD_A_mDE,iDEC_DE,iINC_E,iDEC_E,iLD_E_n,iRRA
	dd iJR_NZ,iLD_IX_nn,iLD_mnn_IX,iINC_IX,iINC_IXH,iDEC_IXH,iLD_IXH_n,iDAA
	dd iJR_Z,iADD_IX_IX,iLD_IX_mnn,iDEC_IX,iINC_IXL,iDEC_IXL,iLD_IXL_n,iCPL
	dd iJR_NC,iLD_SP_nn,iLD_mnn_A,iINC_SP,iINC_mIX,iDEC_mIX,iLD_mIX_n,iSCF
	dd iJR_C,iADD_IX_SP,iLD_A_mnn,iDEC_SP,iINC_A,iDEC_A,iLD_A_n,iCCF
	dd iLD_B_B,iLD_B_C,iLD_B_D,iLD_B_E,iLD_B_IXH,iLD_B_IXL,iLD_B_mIX,iLD_B_A
	dd iLD_C_B,iLD_C_C,iLD_C_D,iLD_C_E,iLD_C_IXH,iLD_C_IXL,iLD_C_mIX,iLD_C_A	
	dd iLD_D_B,iLD_D_C,iLD_D_D,iLD_D_E,iLD_D_IXH,iLD_D_IXL,iLD_D_mIX,iLD_D_A	
	dd iLD_E_B,iLD_E_C,iLD_E_D,iLD_E_E,iLD_E_IXH,iLD_E_IXL,iLD_E_mIX,iLD_E_A	
	dd iLD_IXH_B,iLD_IXH_C,iLD_IXH_D,iLD_IXH_E,iLD_IXH_IXH,iLD_IXH_IXL,iLD_H_mIX,iLD_IXH_A	
	dd iLD_IXL_B,iLD_IXL_C,iLD_IXL_D,iLD_IXL_E,iLD_IXL_IXH,iLD_IXL_IXL,iLD_L_mIX,iLD_IXL_A	
	dd iLD_mIX_B,iLD_mIX_C,iLD_mIX_D,iLD_mIX_E,iLD_mIX_H,iLD_mIX_L,iHALT,iLD_mIX_A	
	dd iLD_A_B,iLD_A_C,iLD_A_D,iLD_A_E,iLD_A_IXH,iLD_A_IXL,iLD_A_mIX,iLD_A_A	
	dd iADD_A_B,iADD_A_C,iADD_A_D,iADD_A_E,iADD_A_IXH,iADD_A_IXL,iADD_A_mIX,iADD_A_A
	dd iADC_A_B,iADC_A_C,iADC_A_D,iADC_A_E,iADC_A_IXH,iADC_A_IXL,iADC_A_mIX,iADC_A_A
	dd iSUB_B,iSUB_C,iSUB_D,iSUB_E,iSUB_IXH,iSUB_IXL,iSUB_mIX,iSUB_A
	dd iSBC_A_B,iSBC_A_C,iSBC_A_D,iSBC_A_E,iSBC_A_IXH,iSBC_A_IXL,iSBC_A_mIX,iSBC_A_A
	dd iAND_B,iAND_C,iAND_D,iAND_E,iAND_IXH,iAND_IXL,iAND_mIX,iAND_A
	dd iXOR_B,iXOR_C,iXOR_D,iXOR_E,iXOR_IXH,iXOR_IXL,iXOR_mIX,iXOR_A
	dd iOR_B,iOR_C,iOR_D,iOR_E,iOR_IXH,iOR_IXL,iOR_mIX,iOR_A
	dd iCP_B,iCP_C,iCP_D,iCP_E,iCP_IXH,iCP_IXL,iCP_mIX,iCP_A
	dd iRET_NZ,iPOP_BC,iJP_NZ,iJP,iCALL_NZ,iPUSH_BC,iADD_A_n,iRST_00H
	dd iRET_Z,iRET_,iJP_Z,iIXCB,iCALL_Z,iCALL,iADC_A_n,iRST_08H
	dd iRET_NC,iPOP_DE,iJP_NC,iOUT_n_A,iCALL_NC,iPUSH_DE,iSUB_n,iRST_10H
	dd iRET_C,iEXX,iJP_C,iIN_A_n,iCALL_C,iIX,iSBC_A_n,iRST_18H
	dd iRET_PO,iPOP_IX,iJP_PO,iEX_mSP_IX,iCALL_PO,iPUSH_IX,iAND_n,iRST_20H
	dd iRET_PE,iJP_mIX,iJP_PE,iEX_DE_HL,iCALL_PE,iED,iXOR_n,iRST_28H
	dd iRET_P,iPOP_AF,iJP_P,iDI,iCALL_P,iPUSH_AF,iOR_n,iRST_30H
	dd iRET_M,iLD_SP_IX,iJP_M,iEI,iCALL_M,iIY,iCP_n,iRST_38H

FDoptable:
	dd iNOP,iLD_BC_nn,iLD_mBC_A,iINC_BC,iINC_B,iDEC_B,iLD_B_n,iRLCA
	dd iEX_AF_AFp,iADD_IY_BC,iLD_A_mBC,iDEC_BC,iINC_C,iDEC_C,iLD_C_n,iRRCA
	dd iDJNZ,iLD_DE_nn,iLD_mDE_A,iINC_DE,iINC_D,iDEC_D,iLD_D_n,iRLA
	dd iJR,iADD_IY_DE,iLD_A_mDE,iDEC_DE,iINC_E,iDEC_E,iLD_E_n,iRRA
	dd iJR_NZ,iLD_IY_nn,iLD_mnn_IY,iINC_IY,iINC_IYH,iDEC_IYH,iLD_IYH_n,iDAA
	dd iJR_Z,iADD_IY_IY,iLD_IY_mnn,iDEC_IY,iINC_IYL,iDEC_IYL,iLD_IYL_n,iCPL
	dd iJR_NC,iLD_SP_nn,iLD_mnn_A,iINC_SP,iINC_mIY,iDEC_mIY,iLD_mIY_n,iSCF
	dd iJR_C,iADD_IY_SP,iLD_A_mnn,iDEC_SP,iINC_A,iDEC_A,iLD_A_n,iCCF
	dd iLD_B_B,iLD_B_C,iLD_B_D,iLD_B_E,iLD_B_IYH,iLD_B_IYL,iLD_B_mIY,iLD_B_A
	dd iLD_C_B,iLD_C_C,iLD_C_D,iLD_C_E,iLD_C_IYH,iLD_C_IYL,iLD_C_mIY,iLD_C_A	
	dd iLD_D_B,iLD_D_C,iLD_D_D,iLD_D_E,iLD_D_IYH,iLD_D_IYL,iLD_D_mIY,iLD_D_A	
	dd iLD_E_B,iLD_E_C,iLD_E_D,iLD_E_E,iLD_E_IYH,iLD_E_IYL,iLD_E_mIY,iLD_E_A	
	dd iLD_IYH_B,iLD_IYH_C,iLD_IYH_D,iLD_IYH_E,iLD_IYH_IYH,iLD_IYH_IYL,iLD_H_mIY,iLD_IYH_A	
	dd iLD_IYL_B,iLD_IYL_C,iLD_IYL_D,iLD_IYL_E,iLD_IYL_IYH,iLD_IYL_IYL,iLD_L_mIY,iLD_IYL_A	
	dd iLD_mIY_B,iLD_mIY_C,iLD_mIY_D,iLD_mIY_E,iLD_mIY_H,iLD_mIY_L,iHALT,iLD_mIY_A	
	dd iLD_A_B,iLD_A_C,iLD_A_D,iLD_A_E,iLD_A_IYH,iLD_A_IYL,iLD_A_mIY,iLD_A_A	
	dd iADD_A_B,iADD_A_C,iADD_A_D,iADD_A_E,iADD_A_IYH,iADD_A_IYL,iADD_A_mIY,iADD_A_A
	dd iADC_A_B,iADC_A_C,iADC_A_D,iADC_A_E,iADC_A_IYH,iADC_A_IYL,iADC_A_mIY,iADC_A_A
	dd iSUB_B,iSUB_C,iSUB_D,iSUB_E,iSUB_IYH,iSUB_IYL,iSUB_mIY,iSUB_A
	dd iSBC_A_B,iSBC_A_C,iSBC_A_D,iSBC_A_E,iSBC_A_IYH,iSBC_A_IYL,iSBC_A_mIY,iSBC_A_A
	dd iAND_B,iAND_C,iAND_D,iAND_E,iAND_IYH,iAND_IYL,iAND_mIY,iAND_A
	dd iXOR_B,iXOR_C,iXOR_D,iXOR_E,iXOR_IYH,iXOR_IYL,iXOR_mIY,iXOR_A
	dd iOR_B,iOR_C,iOR_D,iOR_E,iOR_IYH,iOR_IYL,iOR_mIY,iOR_A
	dd iCP_B,iCP_C,iCP_D,iCP_E,iCP_IYH,iCP_IYL,iCP_mIY,iCP_A
	dd iRET_NZ,iPOP_BC,iJP_NZ,iJP,iCALL_NZ,iPUSH_BC,iADD_A_n,iRST_00H
	dd iRET_Z,iRET_,iJP_Z,iIYCB,iCALL_Z,iCALL,iADC_A_n,iRST_08H
	dd iRET_NC,iPOP_DE,iJP_NC,iOUT_n_A,iCALL_NC,iPUSH_DE,iSUB_n,iRST_10H
	dd iRET_C,iEXX,iJP_C,iIN_A_n,iCALL_C,iIY,iSBC_A_n,iRST_18H
	dd iRET_PO,iPOP_IY,iJP_PO,iEX_mSP_IY,iCALL_PO,iPUSH_IY,iAND_n,iRST_20H
	dd iRET_PE,iJP_mIY,iJP_PE,iEX_DE_HL,iCALL_PE,iED,iXOR_n,iRST_28H
	dd iRET_P,iPOP_AF,iJP_P,iDI,iCALL_P,iPUSH_AF,iOR_n,iRST_30H
	dd iRET_M,iLD_SP_IY,iJP_M,iEI,iCALL_M,iIY,iCP_n,iRST_38H

DDCBoptable:
	dd II,II,II,II,II,II,iRLC_mIX,II
	dd II,II,II,II,II,II,iRRC_mIX,II
	dd II,II,II,II,II,II,iRL_mIX,II
	dd II,II,II,II,II,II,iRR_mIX,II
	dd II,II,II,II,II,II,iSLA_mIX,II
	dd II,II,II,II,II,II,iSRA_mIX,II
	dd II,II,II,II,II,II,iSLL_mIX,II
	dd II,II,II,II,II,II,iSRL_mIX,II
	dd II,II,II,II,II,II,iBIT_0_mIX,II
	dd II,II,II,II,II,II,iBIT_1_mIX,II
	dd II,II,II,II,II,II,iBIT_2_mIX,II
	dd II,II,II,II,II,II,iBIT_3_mIX,II
	dd II,II,II,II,II,II,iBIT_4_mIX,II
	dd II,II,II,II,II,II,iBIT_5_mIX,II
	dd II,II,II,II,II,II,iBIT_6_mIX,II
	dd II,II,II,II,II,II,iBIT_7_mIX,II
	dd II,II,II,II,II,II,iRES_0_mIX,II
	dd II,II,II,II,II,II,iRES_1_mIX,II
	dd II,II,II,II,II,II,iRES_2_mIX,II
	dd II,II,II,II,II,II,iRES_3_mIX,II
	dd II,II,II,II,II,II,iRES_4_mIX,II
	dd II,II,II,II,II,II,iRES_5_mIX,II
	dd II,II,II,II,II,II,iRES_6_mIX,II
	dd II,II,II,II,II,II,iRES_7_mIX,II
	dd II,II,II,II,II,II,iSET_0_mIX,II
	dd II,II,II,II,II,II,iSET_1_mIX,II
	dd II,II,II,II,II,II,iSET_2_mIX,II
	dd II,II,II,II,II,II,iSET_3_mIX,II
	dd II,II,II,II,II,II,iSET_4_mIX,II
	dd II,II,II,II,II,II,iSET_5_mIX,II
	dd II,II,II,II,II,II,iSET_6_mIX,II
	dd II,II,II,II,II,II,iSET_7_mIX,II

FDCBoptable:
	dd II,II,II,II,II,II,iRLC_mIY,II
	dd II,II,II,II,II,II,iRRC_mIY,II
	dd II,II,II,II,II,II,iRL_mIY,II
	dd II,II,II,II,II,II,iRR_mIY,II
	dd II,II,II,II,II,II,iSLA_mIY,II
	dd II,II,II,II,II,II,iSRA_mIY,II
	dd II,II,II,II,II,II,iSLL_mIY,II
	dd II,II,II,II,II,II,iSRL_mIY,II
	dd II,II,II,II,II,II,iBIT_0_mIY,II
	dd II,II,II,II,II,II,iBIT_1_mIY,II
	dd II,II,II,II,II,II,iBIT_2_mIY,II
	dd II,II,II,II,II,II,iBIT_3_mIY,II
	dd II,II,II,II,II,II,iBIT_4_mIY,II
	dd II,II,II,II,II,II,iBIT_5_mIY,II
	dd II,II,II,II,II,II,iBIT_6_mIY,II
	dd II,II,II,II,II,II,iBIT_7_mIY,II
	dd II,II,II,II,II,II,iRES_0_mIY,II
	dd II,II,II,II,II,II,iRES_1_mIY,II
	dd II,II,II,II,II,II,iRES_2_mIY,II
	dd II,II,II,II,II,II,iRES_3_mIY,II
	dd II,II,II,II,II,II,iRES_4_mIY,II
	dd II,II,II,II,II,II,iRES_5_mIY,II
	dd II,II,II,II,II,II,iRES_6_mIY,II
	dd II,II,II,II,II,II,iRES_7_mIY,II
	dd II,II,II,II,II,II,iSET_0_mIY,II
	dd II,II,II,II,II,II,iSET_1_mIY,II
	dd II,II,II,II,II,II,iSET_2_mIY,II
	dd II,II,II,II,II,II,iSET_3_mIY,II
	dd II,II,II,II,II,II,iSET_4_mIY,II
	dd II,II,II,II,II,II,iSET_5_mIY,II
	dd II,II,II,II,II,II,iSET_6_mIY,II
	dd II,II,II,II,II,II,iSET_7_mIY,II

EDoptable:
	dd II,II,II,II,II,II,II,II
	dd II,II,II,II,II,II,II,II
	dd II,II,II,II,II,II,II,II
	dd II,II,II,II,II,II,II,II
	dd II,II,II,II,II,II,II,II
	dd II,II,II,II,II,II,II,II
	dd II,II,II,II,II,II,II,II
	dd II,II,II,II,II,II,II,II
	dd iIN_B_mC,iOUT_mC_B,iSBC_HL_BC,iLD_mnn_BC,iNEG,iRETN,iIM_0,iLD_I_A
	dd iIN_C_mC,iOUT_mC_C,iADC_HL_BC,iLD_BC_mnn,iNEG,iRETI,II,iLD_R_A
	dd iIN_D_mC,iOUT_mC_D,iSBC_HL_DE,iLD_mnn_DE,iNEG,II,iIM_1,iLD_A_I
	dd iIN_E_mC,iOUT_mC_E,iADC_HL_DE,iLD_DE_mnn,iNEG,II,iIM_2,iLD_A_R
	dd iIN_H_mC,iOUT_mC_H,iSBC_HL_HL,iLD_mnn_HL,iNEG,II,II,iRRD
	dd iIN_L_mC,iOUT_mC_L,iADC_HL_HL,iLD_HL_mnn,iNEG,II,II,iRLD
	dd iIN_0_mC,iOUT_mC_0,iSBC_HL_SP,iLD_mnn_SP,iNEG,II,II,II
	dd iIN_A_mC,iOUT_mC_A,iADC_HL_SP,iLD_SP_mnn,iNEG,II,II,II
	dd II,II,II,II,II,II,II,II
	dd II,II,II,II,II,II,II,II
	dd II,II,II,II,II,II,II,II
	dd II,II,II,II,II,II,II,II
	dd iLDI,iCPI,iINI,iOUTI,II,II,II,II
	dd iLDD,iCPD,iIND,iOUTD,II,II,II,II
	dd iLDIR,iCPIR,iINIR,iOTIR,II,II,II,II
	dd iLDDR,iCPDR,iINDR,iOTDR,II,II,II,II
	dd II,II,II,II,II,II,II,II
	dd II,II,II,II,II,II,II,II
	dd II,II,II,II,II,II,II,II
	dd II,II,II,II,II,II,II,II
	dd II,II,II,II,II,II,II,II
	dd II,II,II,II,II,II,II,II
	dd II,II,II,II,II,II,II,II
	dd II,II,II,II,II,tapeFindProg,tapeRead,tapeWrite

SECTION .bss

_BankSelect:	resd 4
_BankROM:			resb 4

_Bank01: resb 0x8000
_Bank11: resb 0x8000
_Bank21: resb 0x8000
_Bank31: resb 0x8000

_Bank02: resb 0x8000
_Bank12: resb 0x8000
_Bank22: resb 0x8000
_Bank32: resb 0x8000

_EmptyBank:  resb 0x4000
