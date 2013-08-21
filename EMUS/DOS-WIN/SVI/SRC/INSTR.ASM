;
; Z80 INSTRUCTIONS  (xx)
;

iJR_NZ:		mJR_CC Z,nz
iJR_NC:		mJR_CC C,nz
iJR_Z:		mJR_CC Z,z
iJR_C:		mJR_CC C,z

iJP_NZ:		mJP_CC Z,nz
iJP_NC:		mJP_CC C,nz
iJP_PO:		mJP_CC P,nz
iJP_P:		mJP_CC S,nz
iJP_Z:		mJP_CC Z,z
iJP_C:		mJP_CC C,z
iJP_PE:		mJP_CC P,z
iJP_M:		mJP_CC S,z

iRET_NZ:	mRET_CC Z,nz
iRET_NC:	mRET_CC C,nz
iRET_PO:	mRET_CC P,nz
iRET_P:		mRET_CC S,nz
iRET_Z:		mRET_CC Z,z
iRET_C:		mRET_CC C,z
iRET_PE:	mRET_CC P,z
iRET_M:		mRET_CC S,z

iCALL_NZ:	mCALL_CC Z,nz
iCALL_NC:	mCALL_CC C,nz
iCALL_PO:	mCALL_CC P,nz
iCALL_P:	mCALL_CC S,nz
iCALL_Z:	mCALL_CC Z,z
iCALL_C:	mCALL_CC C,z
iCALL_PE:	mCALL_CC P,z
iCALL_M:	mCALL_CC S,z

iADD_A_B: do add,rB
iADD_A_C: do add,rC
iADD_A_D: do add,rD
iADD_A_E: do add,rE
iADD_A_H: do add,rH
iADD_A_L: do add,rL
iADD_A_A: do add,rA
iADD_A_mHL:
	mRDMEMB rHL,ah
	do add,ah
iADD_A_n:
	mRDMEMB rPC,ah
	inc			rPC
	do add,ah
	
iSUB_B: do sub,rB
iSUB_C: do sub,rC
iSUB_D: do sub,rD
iSUB_E: do sub,rE
iSUB_H: do sub,rH
iSUB_L: do sub,rL
iSUB_A: do sub,rA
iSUB_mHL:
	mRDMEMB rHL,ah
	do sub,ah
iSUB_n:
	mRDMEMB rPC,ah
	inc		rPC
	do sub,ah
	
iAND_B: do and,rB
iAND_C: do and,rC
iAND_D: do and,rD
iAND_E: do and,rE
iAND_H: do and,rH
iAND_L: do and,rL
iAND_A: do and,rA
iAND_mHL:
	mRDMEMB rHL,ah
	do and,ah
iAND_n:
	mRDMEMB rPC,ah
	inc		rPC
	do and,ah

iOR_B: do or,rB
iOR_C: do or,rC
iOR_D: do or,rD
iOR_E: do or,rE
iOR_H: do or,rH
iOR_L: do or,rL
iOR_A: do or,rA
iOR_mHL:
	mRDMEMB rHL,ah
	do or,ah
iOR_n:
	mRDMEMB rPC,ah
	inc		rPC
	do or,ah

iXOR_B: do xor,rB
iXOR_C: do xor,rC
iXOR_D: do xor,rD
iXOR_E: do xor,rE
iXOR_H: do xor,rH
iXOR_L: do xor,rL
iXOR_A: do xor,rA
iXOR_mHL:
	mRDMEMB rHL,ah
	do xor,ah
iXOR_n:
	mRDMEMB rPC,ah
	inc		rPC
	do xor,ah

iADC_A_B: doS adc,rB
iADC_A_C: doS adc,rC
iADC_A_D: doS adc,rD
iADC_A_E: doS adc,rE
iADC_A_H: doS adc,rH
iADC_A_L: doS adc,rL
iADC_A_A: doS adc,rA
iADC_A_mHL:
	push 	rBC
	mRDMEMB rHL,rB
	sahf
	adc		rA,rB
	pop		rBC
	sf_add	
iADC_A_n:
	push rBC
	mRDMEMB rPC,rB
	inc		rPC
	sahf	
	adc		rA,rB
	pop		rBC
	sf_add
	
iSBC_A_B: doS sbb,rB
iSBC_A_C: doS sbb,rC
iSBC_A_D: doS sbb,rD
iSBC_A_E: doS sbb,rE
iSBC_A_H: doS sbb,rH
iSBC_A_L: doS sbb,rL
iSBC_A_A: doS sbb,rA
iSBC_A_mHL:
	push 	rBC
	mRDMEMB rHL,rB
	sahf
	sbb		rA,rB
	pop		rBC
	sf_sub
iSBC_A_n:
	push rBC
	mRDMEMB rPC,rB
	inc		rPC
	sahf
	sbb		rA,rB
	pop		rBC
	sf_sub

iCP_B: do cmp,rB
iCP_C: do cmp,rC
iCP_D: do cmp,rD
iCP_E: do cmp,rE
iCP_H: do cmp,rH
iCP_L: do cmp,rL
iCP_A: do cmp,rA
iCP_mHL:
	mRDMEMB rHL,ah
	do cmp,ah
iCP_n:
	mRDMEMB rPC,ah
	inc		rPC
	do cmp,ah

iLD_BC_nn:
	mLDWORD rBC
iLD_DE_nn:
	mLDWORD rDE
iLD_HL_nn:
	mLDWORD rHL
iLD_SP_nn:
	mLDWORD word [_rSP]

iJP_mHL:
	mov		rPC,rHL
	mEOI
iLD_SP_HL:
	mov		[_rSP],rHL
	mEOI
iLD_A_mBC:
	mRDMEMB rBC,rA
	mEOI
iLD_A_mDE:
	mRDMEMB rDE,rA
	mEOI
	
iADD_HL_BC:	mADDW rHL,rBC
iADD_HL_DE: mADDW rHL,rDE
iADD_HL_HL: mADDW rHL,rHL
iADD_HL_SP: mADDW rHL,word [_rSP]

iINC_BC: mINCW rBC
iINC_DE: mINCW rDE
iINC_HL: mINCW rHL
iINC_SP: mINCW word [_rSP]

iDEC_BC: mDECW rBC
iDEC_DE: mDECW rDE
iDEC_HL: mDECW rHL
iDEC_SP: mDECW word [_rSP]

iINC_B: mINC rB
iINC_C: mINC rC
iINC_D: mINC rD
iINC_E: mINC rE
iINC_H: mINC rH
iINC_L: mINC rL
iINC_A: mINC rA
iINC_mHL:
	push	rBC
	mRDMEMB rHL,rB
	mINCO rB
	mWRMEM rHL,rB
	pop rBC
	mEOI
	
iDEC_B: mDEC rB
iDEC_C: mDEC rC
iDEC_D: mDEC rD
iDEC_E: mDEC rE
iDEC_H: mDEC rH
iDEC_L: mDEC rL
iDEC_A: mDEC rA
iDEC_mHL:
	push	rBC
	mRDMEMB rHL,rB
	mDECO rB
	mWRMEM rHL,rB
	pop		rBC
	mEOI
	
iRLCA:
	rol		rA,1
	mCopyCF
iRLA:
	sahf
	rcl		rA,1
	mCopyCF
iRRCA:
	ror		rA,1
	mCopyCF
iRRA:
	sahf
	rcr		rA,1
	mCopyCF

iRST_00H: mRST 0x0000
iRST_08H: mRST 0x0008
iRST_10H: mRST 0x0010
iRST_18H: mRST 0x0018
iRST_20H: mRST 0x0020
iRST_28H: mRST 0x0028
iRST_30H: mRST 0x0030
iRST_38H: mRST 0x0038

iPUSH_BC: mIPUSH rB,rC
iPUSH_DE: mIPUSH rD,rE
iPUSH_HL: mIPUSH rH,rL
iPUSH_AF: mIPUSH rA,rF

iPOP_BC:
	mIPOP rBC
iPOP_DE:
	mIPOP rDE
iPOP_HL:	
	mIPOP rHL
iPOP_AF:	
	mPOP rFA
	xchg	rA,rF
	mEOI

iDJNZ:
	mRDMEM_SIGN rPC,edi
	inc		rPC
	dec		rB
	jnz		iDJNZ_nz
	mEOI
iDJNZ_nz:
	add		rPC,di
	inc		word [_cycles]
	mEOI

iJP:	
	mJP
iJR:
	mJR
iCALL:
	mCALL
iRET_:
	mRET

iSCF:
	or		rF,fgC
	and		rF,0xED
	mEOI
iCPL:
	not		rA
	mEOI
iCCF:
	and		rF,0xFD
	xor		rF,0x11
	mEOI
iNOP:
	mEOI
	
iEI:
	mov		byte [_rIFF],1
	mEOI
iDI:
	mov		byte [_rIFF],0
	mEOI

iOUT_n_A:	
	mRDMEM rPC,edi
	inc		rPC
	BackupZ80regs
	and		eax,0xFF
	push	eax
	push	edi
	call	_doOut		; doOut(port,value);
	add		esp,8
	RestoreZ80regs
	mEOI

iIN_A_n:
	mRDMEM rPC,edi
	inc		rPC
	BackupZ80regs A
	push	edi
	call	_doIn			; eax=doIn(port);
	add		esp,4
	RestoreZ80regs A
	mEOI
	
iEXX:
	xchg	rBC,[_rsBC]
	xchg	rDE,[_rsDE]
	xchg	rHL,[_rsHL]
	mEOI
	
iEX_DE_HL:
	xchg	rDE,rHL
	mEOI
	
iEX_AF_AFp
	xchg	rFA,[_rsFA]
	mEOI
	
iLD_B_B: mEOI
iLD_B_C: mLD_r_r rB,rC
iLD_B_D: mLD_r_r rB,rD
iLD_B_E: mLD_r_r rB,rE
iLD_B_H: mLD_r_r rB,rH
iLD_B_L: mLD_r_r rB,rL
iLD_B_A: mLD_r_r rB,rA

iLD_C_B: mLD_r_r rC,rB
iLD_C_C: mEOI
iLD_C_D: mLD_r_r rC,rD
iLD_C_E: mLD_r_r rC,rE
iLD_C_H: mLD_r_r rC,rH
iLD_C_L: mLD_r_r rC,rL
iLD_C_A: mLD_r_r rC,rA

iLD_D_B: mLD_r_r rD,rB
iLD_D_C: mLD_r_r rD,rC
iLD_D_D: mEOI
iLD_D_E: mLD_r_r rD,rE
iLD_D_H: mLD_r_r rD,rH
iLD_D_L: mLD_r_r rD,rL
iLD_D_A: mLD_r_r rD,rA

iLD_E_B: mLD_r_r rE,rB
iLD_E_C: mLD_r_r rE,rC
iLD_E_D: mLD_r_r rE,rD
iLD_E_E: mEOI
iLD_E_H: mLD_r_r rE,rH
iLD_E_L: mLD_r_r rE,rL
iLD_E_A: mLD_r_r rE,rA

iLD_H_B: mLD_r_r rH,rB
iLD_H_C: mLD_r_r rH,rC
iLD_H_D: mLD_r_r rH,rD
iLD_H_E: mLD_r_r rH,rE
iLD_H_H: mEOI
iLD_H_L: mLD_r_r rH,rL
iLD_H_A: mLD_r_r rH,rA

iLD_L_B: mLD_r_r rL,rB
iLD_L_C: mLD_r_r rL,rC
iLD_L_D: mLD_r_r rL,rD
iLD_L_E: mLD_r_r rL,rE
iLD_L_H: mLD_r_r rL,rH
iLD_L_L: mEOI
iLD_L_A: mLD_r_r rL,rA

iLD_A_B: mLD_r_r rA,rB
iLD_A_C: mLD_r_r rA,rC
iLD_A_D: mLD_r_r rA,rD
iLD_A_E: mLD_r_r rA,rE
iLD_A_H: mLD_r_r rA,rH
iLD_A_L: mLD_r_r rA,rL
iLD_A_A: mEOI

iLD_mHL_B: mLD_mHL_r rB
iLD_mHL_C: mLD_mHL_r rC
iLD_mHL_D: mLD_mHL_r rD
iLD_mHL_E: mLD_mHL_r rE
iLD_mHL_H: mLD_mHL_r rH
iLD_mHL_L: mLD_mHL_r rL
iLD_mHL_A: mLD_mHL_r rA

iLD_B_mHL: mLD_r_mHL rB
iLD_C_mHL: mLD_r_mHL rC
iLD_D_mHL: mLD_r_mHL rD
iLD_E_mHL: mLD_r_mHL rE
iLD_H_mHL: mLD_r_mHL rH
iLD_L_mHL: mLD_r_mHL rL
iLD_A_mHL: mLD_r_mHL rA

iLD_mBC_A:
	mWRMEM rBC,rA
	mEOI

iLD_mDE_A:
	mWRMEM rDE,rA
	mEOI

iLD_B_n: mLD_r_n rB
iLD_C_n: mLD_r_n rC
iLD_D_n: mLD_r_n rD
iLD_E_n: mLD_r_n rE
iLD_H_n: mLD_r_n rH
iLD_L_n: mLD_r_n rL
iLD_A_n: mLD_r_n rA	

iLD_mHL_n:
	push	rBC
	mRDMEMB rPC,rB
	inc		rPC
	mWRMEM rHL,rB
	pop		rBC
	mEOI
	
iLD_mnn_HL:
	push	rBC
	mRDMEMW rPC,rBC
	add		rPC,2
	mWRMEM rBC,rL
	inc		rBC
	mWRMEM rBC,rH
	pop		rBC
	mEOI
	
iLD_HL_mnn:
	push	rBC
	mRDMEMW rPC,rBC
	add		rPC,2
	mRDMEMW rBC,rHL
	pop		rBC
	mEOI

iLD_A_mnn:
	mRDMEMW rPC,di
	add		rPC,2
	mRDMEMB di,rA
	mEOI
	
iLD_mnn_A:
	mRDMEMW rPC,di
	add		rPC,2
	mWRMEM di,rA
	mEOI

iEX_mSP_HL:
	push	rBC
	push	ax
	mov		rBC,[_rSP]
	mRDMEMW rBC,ax
	xchg	rHL,ax
	mWRMEM rBC,al
	inc		rBC
	mWRMEM rBC,ah
	pop		ax
	pop		rBC
	mEOI

iDAA:
	bt		ax,9
	jc		daa_sub
	mDAA a
daa_sub:
	mDAA s

;
; Z80 INSTRUCTIONS  (CB)
;

iRLC_B:	mRLC rB
iRLC_C: mRLC rC
iRLC_D: mRLC rD
iRLC_E: mRLC rE
iRLC_H: mRLC rH
iRLC_L: mRLC rL
iRLC_A: mRLC rA
iRLC_mHL:
	push	rBC
	mRDMEMB rHL,rB
	mRLC rB,mem,rHL

iRRC_B:	mRRC rB
iRRC_C: mRRC rC
iRRC_D: mRRC rD
iRRC_E: mRRC rE
iRRC_H: mRRC rH
iRRC_L: mRRC rL
iRRC_A: mRRC rA
iRRC_mHL:
	push	rBC
	mRDMEMB rHL,rB
	mRRC rB,mem,rHL

iRL_B: mRLreg rB
iRL_C: mRLreg rC
iRL_D: mRLreg rD
iRL_E: mRLreg rE
iRL_H: mRLreg rH
iRL_L: mRLreg rL
iRL_A: mRLreg rA
iRL_mHL: mRLmem rHL

iRR_B: mRRreg rB
iRR_C: mRRreg rC
iRR_D: mRRreg rD
iRR_E: mRRreg rE
iRR_H: mRRreg rH
iRR_L: mRRreg rL
iRR_A: mRRreg rA
iRR_mHL: mRRmem rHL

iSLA_B: mSLA rB
iSLA_C: mSLA rC
iSLA_D: mSLA rD
iSLA_E: mSLA rE
iSLA_H: mSLA rH
iSLA_L: mSLA rL
iSLA_A: mSLA rA
iSLA_mHL:
	push	rBC
	mRDMEMB rHL,rB
	mSLA rB,mem,rHL
	
iSRA_B: mSRA rB
iSRA_C: mSRA rC
iSRA_D: mSRA rD
iSRA_E: mSRA rE
iSRA_H: mSRA rH
iSRA_L: mSRA rL
iSRA_A: mSRA rA
iSRA_mHL:
	push	rBC
	mRDMEMB rHL,rB
	mSRA rB,mem,rHL
	
iSLL_B: mSLL rB
iSLL_C: mSLL rC
iSLL_D: mSLL rD
iSLL_E: mSLL rE
iSLL_H: mSLL rH
iSLL_L: mSLL rL
iSLL_A: mSLL rA
iSLL_mHL:
	push	rBC
	mRDMEMB rHL,rB
	mSLL rB,mem,rHL
	
iSRL_B: mSRL rB
iSRL_C: mSRL rC
iSRL_D: mSRL rD
iSRL_E: mSRL rE
iSRL_H: mSRL rH
iSRL_L: mSRL rL
iSRL_A: mSRL rA
iSRL_mHL:
	push	rBC
	mRDMEMB rHL,rB
	mSRL rB,mem,rHL
	
iBIT_0_B: mBIT 8,rBC
iBIT_0_C: mBIT 0,rBC
iBIT_0_D: mBIT 8,rDE
iBIT_0_E: mBIT 0,rDE
iBIT_0_H: mBIT 8,rHL
iBIT_0_L: mBIT 0,rHL
iBIT_0_A: mBIT 0,rFA
iBIT_0_mHL:
	mRDMEM rHL,di
	mBIT 0,di

iBIT_1_B: mBIT 9,rBC
iBIT_1_C: mBIT 1,rBC
iBIT_1_D: mBIT 9,rDE
iBIT_1_E: mBIT 1,rDE
iBIT_1_H: mBIT 9,rHL
iBIT_1_L: mBIT 1,rHL
iBIT_1_A: mBIT 1,rFA
iBIT_1_mHL:
	mRDMEM rHL,di
	mBIT 1,di

iBIT_2_B: mBIT 10,rBC
iBIT_2_C: mBIT 2,rBC
iBIT_2_D: mBIT 10,rDE
iBIT_2_E: mBIT 2,rDE
iBIT_2_H: mBIT 10,rHL
iBIT_2_L: mBIT 2,rHL
iBIT_2_A: mBIT 2,rFA
iBIT_2_mHL:
	mRDMEM rHL,di
	mBIT 2,di

iBIT_3_B: mBIT 11,rBC
iBIT_3_C: mBIT 3,rBC
iBIT_3_D: mBIT 11,rDE
iBIT_3_E: mBIT 3,rDE
iBIT_3_H: mBIT 11,rHL
iBIT_3_L: mBIT 3,rHL
iBIT_3_A: mBIT 3,rFA
iBIT_3_mHL:
	mRDMEM rHL,di
	mBIT 3,di

iBIT_4_B: mBIT 12,rBC
iBIT_4_C: mBIT 4,rBC
iBIT_4_D: mBIT 12,rDE
iBIT_4_E: mBIT 4,rDE
iBIT_4_H: mBIT 12,rHL
iBIT_4_L: mBIT 4,rHL
iBIT_4_A: mBIT 4,rFA
iBIT_4_mHL:
	mRDMEM rHL,di
	mBIT 4,di

iBIT_5_B: mBIT 13,rBC
iBIT_5_C: mBIT 5,rBC
iBIT_5_D: mBIT 13,rDE
iBIT_5_E: mBIT 5,rDE
iBIT_5_H: mBIT 13,rHL
iBIT_5_L: mBIT 5,rHL
iBIT_5_A: mBIT 5,rFA
iBIT_5_mHL:
	mRDMEM rHL,di
	mBIT 5,di

iBIT_6_B: mBIT 14,rBC
iBIT_6_C: mBIT 6,rBC
iBIT_6_D: mBIT 14,rDE
iBIT_6_E: mBIT 6,rDE
iBIT_6_H: mBIT 14,rHL
iBIT_6_L: mBIT 6,rHL
iBIT_6_A: mBIT 6,rFA
iBIT_6_mHL:
	mRDMEM rHL,di
	mBIT 6,di

iBIT_7_B: mBIT 15,rBC
iBIT_7_C: mBIT 7,rBC
iBIT_7_D: mBIT 15,rDE
iBIT_7_E: mBIT 7,rDE
iBIT_7_H: mBIT 15,rHL
iBIT_7_L: mBIT 7,rHL
iBIT_7_A: mBIT 7,rFA
iBIT_7_mHL:
	mRDMEM rHL,di
	mBIT 7,di

iRES_0_B: mRES 0,rB
iRES_0_C: mRES 0,rC
iRES_0_D: mRES 0,rD
iRES_0_E: mRES 0,rE
iRES_0_H: mRES 0,rH
iRES_0_L: mRES 0,rL
iRES_0_A: mRES 0,rA
iRES_0_mHL:
	push	rBC
	mRDMEMB rHL,rB
	mRES 0,rB,mem,rHL

iRES_1_B: mRES 1,rB
iRES_1_C: mRES 1,rC
iRES_1_D: mRES 1,rD
iRES_1_E: mRES 1,rE
iRES_1_H: mRES 1,rH
iRES_1_L: mRES 1,rL
iRES_1_A: mRES 1,rA
iRES_1_mHL:
	push	rBC
	mRDMEMB rHL,rB
	mRES 1,rB,mem,rHL

iRES_2_B: mRES 2,rB
iRES_2_C: mRES 2,rC
iRES_2_D: mRES 2,rD
iRES_2_E: mRES 2,rE
iRES_2_H: mRES 2,rH
iRES_2_L: mRES 2,rL
iRES_2_A: mRES 2,rA
iRES_2_mHL:
	push	rBC
	mRDMEMB rHL,rB
	mRES 2,rB,mem,rHL

iRES_3_B: mRES 3,rB
iRES_3_C: mRES 3,rC
iRES_3_D: mRES 3,rD
iRES_3_E: mRES 3,rE
iRES_3_H: mRES 3,rH
iRES_3_L: mRES 3,rL
iRES_3_A: mRES 3,rA
iRES_3_mHL:
	push	rBC
	mRDMEMB rHL,rB
	mRES 3,rB,mem,rHL

iRES_4_B: mRES 4,rB
iRES_4_C: mRES 4,rC
iRES_4_D: mRES 4,rD
iRES_4_E: mRES 4,rE
iRES_4_H: mRES 4,rH
iRES_4_L: mRES 4,rL
iRES_4_A: mRES 4,rA
iRES_4_mHL:
	push	rBC
	mRDMEMB rHL,rB
	mRES 4,rB,mem,rHL

iRES_5_B: mRES 5,rB
iRES_5_C: mRES 5,rC
iRES_5_D: mRES 5,rD
iRES_5_E: mRES 5,rE
iRES_5_H: mRES 5,rH
iRES_5_L: mRES 5,rL
iRES_5_A: mRES 5,rA
iRES_5_mHL:
	push	rBC
	mRDMEMB rHL,rB
	mRES 5,rB,mem,rHL

iRES_6_B: mRES 6,rB
iRES_6_C: mRES 6,rC
iRES_6_D: mRES 6,rD
iRES_6_E: mRES 6,rE
iRES_6_H: mRES 6,rH
iRES_6_L: mRES 6,rL
iRES_6_A: mRES 6,rA
iRES_6_mHL:
	push	rBC
	mRDMEMB rHL,rB
	mRES 6,rB,mem,rHL

iRES_7_B: mRES 7,rB
iRES_7_C: mRES 7,rC
iRES_7_D: mRES 7,rD
iRES_7_E: mRES 7,rE
iRES_7_H: mRES 7,rH
iRES_7_L: mRES 7,rL
iRES_7_A: mRES 7,rA
iRES_7_mHL:
	push	rBC
	mRDMEMB rHL,rB
	mRES 7,rB,mem,rHL

iSET_0_B: mSET 0,rB
iSET_0_C: mSET 0,rC
iSET_0_D: mSET 0,rD
iSET_0_E: mSET 0,rE
iSET_0_H: mSET 0,rH
iSET_0_L: mSET 0,rL
iSET_0_A: mSET 0,rA
iSET_0_mHL:
	push	rBC
	mRDMEMB rHL,rB
	mSET 0,rB,mem,rHL

iSET_1_B: mSET 1,rB
iSET_1_C: mSET 1,rC
iSET_1_D: mSET 1,rD
iSET_1_E: mSET 1,rE
iSET_1_H: mSET 1,rH
iSET_1_L: mSET 1,rL
iSET_1_A: mSET 1,rA
iSET_1_mHL:
	push	rBC
	mRDMEMB rHL,rB
	mSET 1,rB,mem,rHL

iSET_2_B: mSET 2,rB
iSET_2_C: mSET 2,rC
iSET_2_D: mSET 2,rD
iSET_2_E: mSET 2,rE
iSET_2_H: mSET 2,rH
iSET_2_L: mSET 2,rL
iSET_2_A: mSET 2,rA
iSET_2_mHL:
	push	rBC
	mRDMEMB rHL,rB
	mSET 2,rB,mem,rHL

iSET_3_B: mSET 3,rB
iSET_3_C: mSET 3,rC
iSET_3_D: mSET 3,rD
iSET_3_E: mSET 3,rE
iSET_3_H: mSET 3,rH
iSET_3_L: mSET 3,rL
iSET_3_A: mSET 3,rA
iSET_3_mHL:
	push	rBC
	mRDMEMB rHL,rB
	mSET 3,rB,mem,rHL

iSET_4_B: mSET 4,rB
iSET_4_C: mSET 4,rC
iSET_4_D: mSET 4,rD
iSET_4_E: mSET 4,rE
iSET_4_H: mSET 4,rH
iSET_4_L: mSET 4,rL
iSET_4_A: mSET 4,rA
iSET_4_mHL:
	push	rBC
	mRDMEMB rHL,rB
	mSET 4,rB,mem,rHL

iSET_5_B: mSET 5,rB
iSET_5_C: mSET 5,rC
iSET_5_D: mSET 5,rD
iSET_5_E: mSET 5,rE
iSET_5_H: mSET 5,rH
iSET_5_L: mSET 5,rL
iSET_5_A: mSET 5,rA
iSET_5_mHL:
	push	rBC
	mRDMEMB rHL,rB
	mSET 5,rB,mem,rHL

iSET_6_B: mSET 6,rB
iSET_6_C: mSET 6,rC
iSET_6_D: mSET 6,rD
iSET_6_E: mSET 6,rE
iSET_6_H: mSET 6,rH
iSET_6_L: mSET 6,rL
iSET_6_A: mSET 6,rA
iSET_6_mHL:
	push	rBC
	mRDMEMB rHL,rB
	mSET 6,rB,mem,rHL

iSET_7_B: mSET 7,rB
iSET_7_C: mSET 7,rC
iSET_7_D: mSET 7,rD
iSET_7_E: mSET 7,rE
iSET_7_H: mSET 7,rH
iSET_7_L: mSET 7,rL
iSET_7_A: mSET 7,rA
iSET_7_mHL:
	push	rBC
	mRDMEMB rHL,rB
	mSET 7,rB,mem,rHL


;
; Z80 INSTRUCTIONS  (DD)
;

iADD_IX_BC: mADDW word [_rIX],rBC
iADD_IX_DE: mADDW word [_rIX],rDE
iLD_IX_nn:
	mLDWORD word [_rIX]
iLD_mnn_IX:
	push	rBC
	push	rHL
	mov		rHL,[_rIX]
	mRDMEMW rPC,rBC
	add		rPC,2
	mWRMEM rBC,rL
	inc		rBC
	mWRMEM rBC,rH
	mov		[_rIX],rHL
	pop		rHL
	pop		rBC
	mEOI
iINC_IX: mINCW word [_rIX]
iADD_IX_IX:
	mov		di,[_rIX]
	mADDW [_rIX],di
iLD_IX_mnn:
	push	rBC
	push	rHL
	mRDMEMW rPC,rBC
	add		rPC,2
	mRDMEMW rBC,rHL
	mov		[_rIX],rHL
	pop		rHL
	pop		rBC
	mEOI
iDEC_IX: mDECW word [_rIX]
iADD_IX_SP:
	mov		di,[_rSP]
	mADDW [_rIX],di
iPUSH_IX:
	push	rHL
	mov		rHL,[_rIX]
	mPUSH rH,rL
	pop		rHL
	mEOI
iPOP_IX:
	mIPOP word [_rIX]
iLD_SP_IX:
	mov		di,[_rIX]
	mov		[_rSP],di
	mEOI
iJP_mIX:
	mov		rPC,[_rIX]
	mEOI
iEX_mSP_IX:
	push	rBC
	push	ax
	mov		rBC,[_rSP]
	mRDMEMW rBC,ax
	xchg	[_rIX],ax
	mWRMEM rBC,ah
	inc		rBC
	mWRMEM rBC,al
	pop		ax
	pop		rBC
	mEOI

iINC_mIX:
	calcind X
	push	rBC
	push	di
	mRDMEMB di,rB
	mINCO rB
	pop		di
	mWRMEM di,rB
	pop rBC
	mEOI

iDEC_mIX:
	calcind X
	push	rBC
	push	di
	mRDMEMB di,rB
	mDECO rB
	pop		di
	mWRMEM di,rB
	pop rBC
	mEOI

iLD_mIX_n:
	calcind X	
	push	rBC
	push	di
	mRDMEMB rPC,rB
	inc		rPC
	pop		di
	mWRMEM di,rB
	pop		rBC
	mEOI

iLD_B_mIX: mLD_r_mI X,rB
iLD_C_mIX: mLD_r_mI X,rC
iLD_D_mIX: mLD_r_mI X,rD
iLD_E_mIX: mLD_r_mI X,rE
iLD_H_mIX: mLD_r_mI X,rH
iLD_L_mIX: mLD_r_mI X,rL
iLD_A_mIX: mLD_r_mI X,rA

iLD_mIX_B: mLD_mI_r X,rB
iLD_mIX_C: mLD_mI_r X,rC
iLD_mIX_D: mLD_mI_r X,rD
iLD_mIX_E: mLD_mI_r X,rE
iLD_mIX_H: mLD_mI_r X,rH
iLD_mIX_L: mLD_mI_r X,rL
iLD_mIX_A: mLD_mI_r X,rA

iADD_A_mIX:
	calcind X
	mRDMEMB di,ah
	do add,ah
iSUB_mIX:
	calcind X
	mRDMEMB di,ah
	do sub,ah
iAND_mIX:
	calcind X
	mRDMEMB di,ah
	do and,ah
iXOR_mIX:
	calcind X
	mRDMEMB di,ah
	do xor,ah
iOR_mIX:
	calcind X
	mRDMEMB di,ah
	do or,ah
iCP_mIX:
	calcind X
	mRDMEMB di,ah
	do cmp,ah
iADC_A_mIX:
	calcind X
	push 	rBC
	mRDMEMB di,rB
	sahf
	adc		rA,rB
	pop		rBC
	sf_add	
iSBC_A_mIX:
	calcind X
	push 	rBC
	mRDMEMB di,rB
	sahf
	sbb		rA,rB
	pop		rBC
	sf_sub

iADD_A_IXH: do add,byte [_rIXH]
iADD_A_IXL: do add,byte [_rIXL]
iSUB_IXH: do sub,byte [_rIXH]
iSUB_IXL: do sub,byte [_rIXL]
iAND_IXH: do and,byte [_rIXH]
iAND_IXL: do and,byte [_rIXL]
iOR_IXH: do or,byte [_rIXH]
iOR_IXL: do or,byte [_rIXL]
iXOR_IXH: do xor,byte [_rIXH]
iXOR_IXL: do xor,byte [_rIXL]
iCP_IXH: do cmp,byte [_rIXH]
iCP_IXL: do cmp,byte [_rIXL]
iADC_A_IXH: do adc,byte [_rIXH]
iADC_A_IXL: do adc,byte [_rIXL]
iSBC_A_IXH: do sbb,byte [_rIXH]
iSBC_A_IXL: do sbb,byte [_rIXL]
iINC_IXH: mINC byte [_rIXH]
iINC_IXL: mINC byte [_rIXL]
iDEC_IXH: mDEC byte [_rIXH]
iDEC_IXL: mDEC byte [_rIXL]
iLD_IXH_n:
	push	rBC
	mRDMEMB rPC,rB
	inc		rPC
	mov		[_rIXH],rB
	pop		rBC
	mEOI
iLD_IXL_n:
	push	rBC
	mRDMEMB rPC,rB
	inc		rPC
	mov		[_rIXL],rB
	pop		rBC
	mEOI
iLD_B_IXH: mLD_r_r rB,[_rIXH]
iLD_B_IXL: mLD_r_r rB,[_rIXL]
iLD_C_IXH: mLD_r_r rC,[_rIXH]
iLD_C_IXL: mLD_r_r rC,[_rIXL]
iLD_D_IXH: mLD_r_r rD,[_rIXH]
iLD_D_IXL: mLD_r_r rD,[_rIXL]
iLD_E_IXH: mLD_r_r rE,[_rIXH]
iLD_E_IXL: mLD_r_r rE,[_rIXL]
iLD_A_IXH: mLD_r_r rA,[_rIXH]
iLD_A_IXL: mLD_r_r rA,[_rIXL]
iLD_IXH_B: mLD_r_r [_rIXH],rB
iLD_IXL_B: mLD_r_r [_rIXL],rB
iLD_IXH_C: mLD_r_r [_rIXH],rC
iLD_IXL_C: mLD_r_r [_rIXL],rC
iLD_IXH_D: mLD_r_r [_rIXH],rD
iLD_IXL_D: mLD_r_r [_rIXL],rD
iLD_IXH_E: mLD_r_r [_rIXH],rE
iLD_IXL_E: mLD_r_r [_rIXL],rE
iLD_IXH_A: mLD_r_r [_rIXH],rA
iLD_IXL_A: mLD_r_r [_rIXL],rA
iLD_IXH_IXH: mEOI
iLD_IXL_IXL: mEOI
iLD_IXH_IXL:
	push	rBC
	mov		rB,[_rIXL]
	mov		[_rIXH],rB
	pop		rBC
	mEOI
iLD_IXL_IXH
	push	rBC
	mov		rB,[_rIXH]
	mov		[_rIXL],rB
	pop		rBC
	mEOI

;
; Z80 INSTRUCTIONS  (FD)
;

iADD_IY_BC: mADDW word [_rIY],rBC
iADD_IY_DE: mADDW word [_rIY],rDE
iLD_IY_nn:
	mLDWORD word [_rIY]
iLD_mnn_IY:
	push	rBC
	push	rHL
	mov		rHL,[_rIY]
	mRDMEMW rPC,rBC
	add		rPC,2
	mWRMEM rBC,rL
	inc		rBC
	mWRMEM rBC,rH
	mov		[_rIY],rHL
	pop		rHL
	pop		rBC
	mEOI
iINC_IY: mINCW word [_rIY]
iADD_IY_IY:
	mov		di,[_rIY]
	mADDW [_rIY],di
iLD_IY_mnn:
	push	rBC
	push	rHL
	mRDMEMW rPC,rBC
	add		rPC,2
	mRDMEMW rBC,rHL
	mov		[_rIY],rHL
	pop		rHL
	pop		rBC
	mEOI
iDEC_IY: mDECW word [_rIY]
iADD_IY_SP:
	mov		di,[_rSP]
	mADDW [_rIY],di
iPUSH_IY:
	push	rHL
	mov		rHL,[_rIY]
	mPUSH rH,rL
	pop		rHL
	mEOI
iPOP_IY:
	mIPOP word [_rIY]
iLD_SP_IY:
	mov		di,[_rIY]
	mov		[_rSP],di
	mEOI
iJP_mIY:
	mov		rPC,[_rIY]
	mEOI
iEX_mSP_IY:
	push	rBC
	push	ax
	mov		rBC,[_rSP]
	mRDMEMW rBC,ax
	xchg	[_rIY],ax
	mWRMEM rBC,ah
	inc		rBC
	mWRMEM rBC,al
	pop		ax
	pop		rBC
	mEOI

iINC_mIY:
	calcind Y
	push	rBC
	push	di
	mRDMEMB di,rB
	mINCO rB
	pop		di
	mWRMEM di,rB
	pop rBC
	mEOI

iDEC_mIY:
	calcind Y
	push	rBC
	push	di
	mRDMEMB di,rB
	mDECO rB
	pop		di
	mWRMEM di,rB
	pop rBC
	mEOI

iLD_mIY_n:
	calcind Y	
	push	rBC
	push	di
	mRDMEMB rPC,rB
	inc		rPC
	pop		di
	mWRMEM di,rB
	pop		rBC
	mEOI

iLD_B_mIY: mLD_r_mI Y,rB
iLD_C_mIY: mLD_r_mI Y,rC
iLD_D_mIY: mLD_r_mI Y,rD
iLD_E_mIY: mLD_r_mI Y,rE
iLD_H_mIY: mLD_r_mI Y,rH
iLD_L_mIY: mLD_r_mI Y,rL
iLD_A_mIY: mLD_r_mI Y,rA

iLD_mIY_B: mLD_mI_r Y,rB
iLD_mIY_C: mLD_mI_r Y,rC
iLD_mIY_D: mLD_mI_r Y,rD
iLD_mIY_E: mLD_mI_r Y,rE
iLD_mIY_H: mLD_mI_r Y,rH
iLD_mIY_L: mLD_mI_r Y,rL
iLD_mIY_A: mLD_mI_r Y,rA

iADD_A_mIY:
	calcind Y
	mRDMEMB di,ah
	do add,ah
iSUB_mIY:
	calcind Y
	mRDMEMB di,ah
	do sub,ah
iAND_mIY:
	calcind Y
	mRDMEMB di,ah
	do and,ah
iXOR_mIY:
	calcind Y
	mRDMEMB di,ah
	do xor,ah
iOR_mIY:
	calcind Y
	mRDMEMB di,ah
	do or,ah
iCP_mIY:
	calcind Y
	mRDMEMB di,ah
	do cmp,ah
iADC_A_mIY:
	calcind Y
	push 	rBC
	mRDMEMB di,rB
	sahf
	adc		rA,rB
	pop		rBC
	sf_add	
iSBC_A_mIY:
	calcind Y
	push 	rBC
	mRDMEMB di,rB
	sahf
	sbb		rA,rB
	pop		rBC
	sf_sub

iADD_A_IYH: do add,byte [_rIYH]
iADD_A_IYL: do add,byte [_rIYL]
iSUB_IYH: do sub,byte [_rIYH]
iSUB_IYL: do sub,byte [_rIYL]
iAND_IYH: do and,byte [_rIYH]
iAND_IYL: do and,byte [_rIYL]
iOR_IYH: do or,byte [_rIYH]
iOR_IYL: do or,byte [_rIYL]
iXOR_IYH: do xor,byte [_rIYH]
iXOR_IYL: do xor,byte [_rIYL]
iCP_IYH: do cmp,byte [_rIYH]
iCP_IYL: do cmp,byte [_rIYL]
iADC_A_IYH: do adc,byte [_rIYH]
iADC_A_IYL: do adc,byte [_rIYL]
iSBC_A_IYH: do sbb,byte [_rIYH]
iSBC_A_IYL: do sbb,byte [_rIYL]
iINC_IYH: mINC byte [_rIYH]
iINC_IYL: mINC byte [_rIYL]
iDEC_IYH: mDEC byte [_rIYH]
iDEC_IYL: mDEC byte [_rIYL]
iLD_IYH_n:
	push	rBC
	mRDMEMB rPC,rB
	inc		rPC
	mov		[_rIYH],rB
	pop		rBC
	mEOI
iLD_IYL_n:
	push	rBC
	mRDMEMB rPC,rB
	inc		rPC
	mov		[_rIYL],rB
	pop		rBC
	mEOI
iLD_B_IYH: mLD_r_r rB,[_rIYH]
iLD_B_IYL: mLD_r_r rB,[_rIYL]
iLD_C_IYH: mLD_r_r rC,[_rIYH]
iLD_C_IYL: mLD_r_r rC,[_rIYL]
iLD_D_IYH: mLD_r_r rD,[_rIYH]
iLD_D_IYL: mLD_r_r rD,[_rIYL]
iLD_E_IYH: mLD_r_r rE,[_rIYH]
iLD_E_IYL: mLD_r_r rE,[_rIYL]
iLD_A_IYH: mLD_r_r rA,[_rIYH]
iLD_A_IYL: mLD_r_r rA,[_rIYL]
iLD_IYH_B: mLD_r_r [_rIYH],rB
iLD_IYL_B: mLD_r_r [_rIYL],rB
iLD_IYH_C: mLD_r_r [_rIYH],rC
iLD_IYL_C: mLD_r_r [_rIYL],rC
iLD_IYH_D: mLD_r_r [_rIYH],rD
iLD_IYL_D: mLD_r_r [_rIYL],rD
iLD_IYH_E: mLD_r_r [_rIYH],rE
iLD_IYL_E: mLD_r_r [_rIYL],rE
iLD_IYH_A: mLD_r_r [_rIYH],rA
iLD_IYL_A: mLD_r_r [_rIYL],rA
iLD_IYH_IYH: mEOI
iLD_IYL_IYL: mEOI
iLD_IYH_IYL:
	push	rBC
	mov		rB,[_rIYL]
	mov		[_rIYH],rB
	pop		rBC
	mEOI
iLD_IYL_IYH
	push	rBC
	mov		rB,[_rIYH]
	mov		[_rIYL],rB
	pop		rBC
	mEOI


;
; Z80 INSTRUCTIONS  (ED)
;

iLD_mnn_BC:
	push	rDE
	mRDMEMW rPC,rDE
	add		rPC,2
	mWRMEM rDE,rC
	inc		rDE
	mWRMEM rDE,rB
	pop		rDE
	mEOI
	
iLD_BC_mnn:
	push	rDE
	mRDMEMW rPC,rDE
	add		rPC,2
	mRDMEMW rDE,rBC
	pop		rDE
	mEOI

iLD_mnn_DE:
	push	rBC
	mRDMEMW rPC,rBC
	add		rPC,2
	mWRMEM rBC,rE
	inc		rBC
	mWRMEM rBC,rD
	pop		rBC
	mEOI
	
iLD_DE_mnn:
	push	rBC
	mRDMEMW rPC,rBC
	add		rPC,2
	mRDMEMW rBC,rDE
	pop		rBC
	mEOI

iLD_mnn_SP:
	push	rBC
	push	rHL
	mRDMEMW rPC,rBC
	add		rPC,2
	mov		rHL,[_rSP]
	mWRMEM rBC,rL
	inc		rBC
	mWRMEM rBC,rH
	pop		rHL
	pop		rBC
	mEOI
	
iLD_SP_mnn:
	push	rBC
	push	rHL
	mRDMEMW rPC,rBC
	add		rPC,2
	mRDMEMW rBC,rHL
	mov		[_rSP],rHL
	pop		rHL
	pop		rBC
	mEOI

iNEG:
	neg		rA
	sf_sub
	
iOUT_mC_B: mOUT_mC_r rB
iOUT_mC_C: mOUT_mC_r rC
iOUT_mC_D: mOUT_mC_r rD
iOUT_mC_E: mOUT_mC_r rE
iOUT_mC_H: mOUT_mC_r rH
iOUT_mC_L: mOUT_mC_r rL
iOUT_mC_0: mOUT_mC_r 0
iOUT_mC_A: mOUT_mC_r rA

iIN_B_mC: mIN_r_mC _rBC+1
iIN_C_mC: mIN_r_mC _rBC
iIN_D_mC: mIN_r_mC _rDE+1
iIN_E_mC: mIN_r_mC _rDE
iIN_H_mC: mIN_r_mC _rHL+1
iIN_L_mC: mIN_r_mC _rHL
iIN_0_mC: mIN_r_mC 0
iIN_A_mC: mIN_r_mC _rA

iADC_HL_BC: mADCW rHL,rBC
iADC_HL_DE: mADCW rHL,rDE
iADC_HL_HL: mADCW rHL,rHL
iADC_HL_SP: mADCW rHL,[_rSP]

iSBC_HL_BC: mSBCW rHL,rBC
iSBC_HL_DE: mSBCW rHL,rDE
iSBC_HL_HL: mSBCW rHL,rHL
iSBC_HL_SP: mSBCW rHL,[_rSP]

iRETN:
	mRET
iRETI:
	mRET
	
iIM_0: mIM 0
iIM_1: mIM 1
iIM_2: mIM 2

iLD_A_I:
	mov		al,[_rIFF]
	shl		al,2
	and		ah,1
	or		ah,al
	mov		al,byte [_rI]
	push	ax
	or		al,al
	lahf
	pop		di
	and		ax,0xC000
	or		ax,di
	mEOI

iLD_A_R:
	mov		al,[_rIFF]
	shl		al,2
	and		ah,1
	or		ah,al
	mov		al,byte [_rR]
	and		al,0x7F
	push	ax
	or		al,al
	lahf
	pop		di
	and		ax,0xC000
	or		ax,di
	mEOI

iLD_I_A:
	mov		[_rI],rA
	mEOI
	
iLD_R_A:
	mov		[_rR],rA
	mEOI

iRRD:
	push		rBC
	mRDMEMB rHL,rC
	push		rDE
	push		rBC
	mov			rE,rA
	and			rE,0x0F
	and			rC,0xF0
	or			rC,rE
	rol			rC,4
	mWRMEM rHL,rC
	pop			rBC
	pop			rDE
	and			rA,0xF0
	and			rC,0x0F
	or			rA,rC
	pop			rBC
	mov			di,ax
	or			rA,rA
	lahf
	and			rF,0xC4
	and			di,0x0100
	or			ax,di
	mEOI
	
iRLD:
	push		rBC
	mRDMEMB rHL,rC
	push		rDE
	push		rBC
	shl			rC,4
	mov			rE,rA
	and			rE,0x0F
	or			rC,rE
	mWRMEM rHL,rC
	pop			rBC
	pop			rDE
	shr			rC,4
	and			rA,0xF0
	or			rA,rC
	pop			rBC
	mov			di,ax
	or			rA,rA
	lahf
	and			rF,0xC4
	and			di,0x0100
	or			ax,di
	mEOI

iLDD:
	mLD dec
	mEOI
iLDI:
	mLD inc
	mEOI
iLDDR:
	mLD dec
	mREP
iLDIR:
	mLD inc
	mREP

iCPD: mCP dec
iCPI: mCP inc
iCPDR: mCPR dec
iCPIR: mCPR inc

iIND: mIN dec
iINI: mIN inc
iINDR: mINR dec
iINIR: mINR inc

iOUTD: mOUT dec
iOUTI: mOUT inc
iOTDR: mOTR dec
iOTIR: mOTR inc


;
; Z80 INSTRUCTIONS  (DDCB)
;

iRLC_mIX:
	pop 	di
	push	rBC
	push	di
	mRDMEMB di,rB
	pop		di	
	mRLC rB,mem,di

iRRC_mIX:
	pop 	di
	push	rBC
	push	di
	mRDMEMB di,rB
	pop		di
	mRRC rB,mem,di

iRL_mIX:
	pop 	di
	mRLmem di
	
iRR_mIX:
	pop 	di
	mRRmem di

iSLA_mIX:
	pop 	di
	push	rBC
	push	di
	mRDMEMB di,rB
	pop		di
	mSLA rB,mem,di

iSRA_mIX:
	pop 	di
	push	rBC
	push	di
	mRDMEMB di,rB
	pop		di
	mSRA rB,mem,di

iSLL_mIX:
	pop 	di
	push	rBC
	push	di
	mRDMEMB di,rB
	pop		di
	mSLL rB,mem,di

iSRL_mIX:
	pop 	di
	push	rBC
	push	di
	mRDMEMB di,rB
	pop		di
	mSRL rB,mem,di

iBIT_0_mIX:
	pop 	di
	mRDMEM di,di
	mBIT 0,di
iBIT_1_mIX:
	pop 	di
	mRDMEM di,di
	mBIT 1,di
iBIT_2_mIX:
	pop 	di
	mRDMEM di,di
	mBIT 2,di
iBIT_3_mIX:
	pop 	di
	mRDMEM di,di
	mBIT 3,di
iBIT_4_mIX:
	pop 	di
	mRDMEM di,di
	mBIT 4,di
iBIT_5_mIX:
	pop 	di
	mRDMEM di,di
	mBIT 5,di
iBIT_6_mIX:
	pop 	di
	mRDMEM di,di
	mBIT 6,di
iBIT_7_mIX:
	pop 	di
	mRDMEM di,di
	mBIT 7,di

iRES_0_mIX:
	pop 	di
	push	rBC
	push	di
	mRDMEMB di,rB
	pop		di
	mRES 0,rB,mem,di
iRES_1_mIX:
	pop 	di
	push	rBC
	push	di
	mRDMEMB di,rB
	pop		di
	mRES 1,rB,mem,di
iRES_2_mIX:
	pop 	di
	push	rBC
	push	di
	mRDMEMB di,rB
	pop		di
	mRES 2,rB,mem,di
iRES_3_mIX:
	pop 	di
	push	rBC
	push	di
	mRDMEMB di,rB
	pop		di
	mRES 3,rB,mem,di
iRES_4_mIX:
	pop 	di
	push	rBC
	push	di
	mRDMEMB di,rB
	pop		di
	mRES 4,rB,mem,di
iRES_5_mIX:
	pop 	di
	push	rBC
	push	di
	mRDMEMB di,rB
	pop		di
	mRES 5,rB,mem,di
iRES_6_mIX:
	pop 	di
	push	rBC
	push	di
	mRDMEMB di,rB
	pop		di
	mRES 6,rB,mem,di
iRES_7_mIX:
	pop 	di
	push	rBC
	push	di
	mRDMEMB di,rB
	pop		di
	mRES 7,rB,mem,di

iSET_0_mIX:
	pop 	di
	push	rBC
	push	di
	mRDMEMB di,rB
	pop		di
	mSET 0,rB,mem,di
iSET_1_mIX:
	pop 	di
	push	rBC
	push	di
	mRDMEMB di,rB
	pop		di
	mSET 1,rB,mem,di
iSET_2_mIX:
	pop 	di
	push	rBC
	push	di
	mRDMEMB di,rB
	pop		di
	mSET 2,rB,mem,di
iSET_3_mIX:
	pop 	di
	push	rBC
	push	di
	mRDMEMB di,rB
	pop		di
	mSET 3,rB,mem,di
iSET_4_mIX:
	pop 	di
	push	rBC
	push	di
	mRDMEMB di,rB
	pop		di
	mSET 4,rB,mem,di
iSET_5_mIX:
	pop 	di
	push	rBC
	push	di
	mRDMEMB di,rB
	pop		di
	mSET 5,rB,mem,di
iSET_6_mIX:
	pop 	di
	push	rBC
	push	di
	mRDMEMB di,rB
	pop		di
	mSET 6,rB,mem,di
iSET_7_mIX:
	pop 	di
	push	rBC
	push	di
	mRDMEMB di,rB
	pop		di
	mSET 7,rB,mem,di

;
; Z80 INSTRUCTIONS  (FDCB)
;

iRLC_mIY:
	pop 	di
	push	rBC
	push	di
	mRDMEMB di,rB
	pop		di	
	mRLC rB,mem,di

iRRC_mIY:
	pop 	di
	push	rBC
	push	di
	mRDMEMB di,rB
	pop		di
	mRRC rB,mem,di

iRL_mIY:
	pop 	di
	mRLmem di
	
iRR_mIY:
	pop 	di
	mRRmem di

iSLA_mIY:
	pop 	di
	push	rBC
	push	di
	mRDMEMB di,rB
	pop		di
	mSLA rB,mem,di

iSRA_mIY:
	pop 	di
	push	rBC
	push	di
	mRDMEMB di,rB
	pop		di
	mSRA rB,mem,di

iSLL_mIY:
	pop 	di
	push	rBC
	push	di
	mRDMEMB di,rB
	pop		di
	mSLL rB,mem,di

iSRL_mIY:
	pop 	di
	push	rBC
	push	di
	mRDMEMB di,rB
	pop		di
	mSRL rB,mem,di

iBIT_0_mIY:
	pop 	di
	mRDMEM di,di
	mBIT 0,di
iBIT_1_mIY:
	pop 	di
	mRDMEM di,di
	mBIT 1,di
iBIT_2_mIY:
	pop 	di
	mRDMEM di,di
	mBIT 2,di
iBIT_3_mIY:
	pop 	di
	mRDMEM di,di
	mBIT 3,di
iBIT_4_mIY:
	pop 	di
	mRDMEM di,di
	mBIT 4,di
iBIT_5_mIY:
	pop 	di
	mRDMEM di,di
	mBIT 5,di
iBIT_6_mIY:
	pop 	di
	mRDMEM di,di
	mBIT 6,di
iBIT_7_mIY:
	pop 	di
	mRDMEM di,di
	mBIT 7,di

iRES_0_mIY:
	pop 	di
	push	rBC
	push	di
	mRDMEMB di,rB
	pop		di
	mRES 0,rB,mem,di
iRES_1_mIY:
	pop 	di
	push	rBC
	push	di
	mRDMEMB di,rB
	pop		di
	mRES 1,rB,mem,di
iRES_2_mIY:
	pop 	di
	push	rBC
	push	di
	mRDMEMB di,rB
	pop		di
	mRES 2,rB,mem,di
iRES_3_mIY:
	pop 	di
	push	rBC
	push	di
	mRDMEMB di,rB
	pop		di
	mRES 3,rB,mem,di
iRES_4_mIY:
	pop 	di
	push	rBC
	push	di
	mRDMEMB di,rB
	pop		di
	mRES 4,rB,mem,di
iRES_5_mIY:
	pop 	di
	push	rBC
	push	di
	mRDMEMB di,rB
	pop		di
	mRES 5,rB,mem,di
iRES_6_mIY:
	pop 	di
	push	rBC
	push	di
	mRDMEMB di,rB
	pop		di
	mRES 6,rB,mem,di
iRES_7_mIY:
	pop 	di
	push	rBC
	push	di
	mRDMEMB di,rB
	pop		di
	mRES 7,rB,mem,di

iSET_0_mIY:
	pop 	di
	push	rBC
	push	di
	mRDMEMB di,rB
	pop		di
	mSET 0,rB,mem,di
iSET_1_mIY:
	pop 	di
	push	rBC
	push	di
	mRDMEMB di,rB
	pop		di
	mSET 1,rB,mem,di
iSET_2_mIY:
	pop 	di
	push	rBC
	push	di
	mRDMEMB di,rB
	pop		di
	mSET 2,rB,mem,di
iSET_3_mIY:
	pop 	di
	push	rBC
	push	di
	mRDMEMB di,rB
	pop		di
	mSET 3,rB,mem,di
iSET_4_mIY:
	pop 	di
	push	rBC
	push	di
	mRDMEMB di,rB
	pop		di
	mSET 4,rB,mem,di
iSET_5_mIY:
	pop 	di
	push	rBC
	push	di
	mRDMEMB di,rB
	pop		di
	mSET 5,rB,mem,di
iSET_6_mIY:
	pop 	di
	push	rBC
	push	di
	mRDMEMB di,rB
	pop		di
	mSET 6,rB,mem,di
iSET_7_mIY:
	pop 	di
	push	rBC
	push	di
	mRDMEMB di,rB
	pop		di
	mSET 7,rB,mem,di
