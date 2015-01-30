; サンプルプログラム
;￣￣￣￣￣￣￣￣￣￣
; 100 ' Example for MSX2 BASIC
; 110 '
; 120 ' Initialization
; 130 CLEAR 200,&HD513     'The machine language work area is secured.
; 140 DEFINT A-Z           'Set it as an integer.
; 150 DEFUSR=&HD514        'The routine address of compression and decompression.
; 160 BLOAD "BARGAIN.BIN"  'Loading of the machine language file.
; 170 SM=8 :SCREEN SM      'Screen mode [5-12]
; 180 SET PAGE 1,0
; 190 BLOAD "SAMPLE.BN8",S 'Load an image to decompress to the video page0.
; 200 POKE &HDE6E,(VPEEK(3)AND16)\16 'Permutation decipher
; 210 VA=USR(SM)           'A compressed image is decompressed to the video page1.
; 220 A$=INPUT$(1)
; 230 END


; アセンブリソースコード
;￣￣￣￣￣￣￣￣￣￣￣￣
;*********************************************************************
; BARGAIN.BIN  BARGAIN decompression exclusive routine for MSX2 BASIC 
;              Created by Katsuhiro Noguchi 2011/1228
;              Under GPL http://creativecommons.org/licenses/GPL/2.0/
;************* Using SjASM v0.39g Special thanks Sjoerd Mastijn ******

; BIOS entry

DCOMPR	EQU	 0020h	;HLレジスタとDEレジスタの内容を比較する
ENASLT	EQU	 0024h	;任意のページのスロットを切り換える
LDIRMV	EQU	 0059h	;VRAMからRAMにデータをブロック転送
LDIRVM	EQU	 005Ch	;RAMからVRAMにデータをブロック転送
SETPAG	EQU	 013Dh	;VRAMのアクティブページを切り換える
RSTPLT	EQU	 0145h	;VRAMからパレットをリストア
KILBUF	EQU	 0156h	;キーボードバッファをクリアする
EXTROM	EQU	 015Fh	;SUB-ROMのインタースロットコール
BIGFIL	EQU	 016Bh	;VRAMの指定領域を同一のデータで埋める
NRDVRM	EQU	 0174h	;VRAMの内容を読み出す
NWRVRM	EQU	 0177h	;VRAMにデータを書き込む
BLTVV	EQU	 0191h	;VRAM領域内で論理矩形転送
BLTVM	EQU	 0195h	;メモリからVRAMに論理矩形転送
BLTMV	EQU	 0199h	;VRAMからメモリに論理矩形転送
BDOS	EQU	0F37Dh	;システムコール
_ALLOC	EQU	   1Bh 	;アロケーション情報の獲得

; System work area

RAMAD1	EQU	0F342h 	;(1) ページ1のRAMのスロット番号
LINLEN	EQU 	0F3B0h 	;(1) 現在の画面の1行の幅
CSRY	EQU	0F3DCh 	;(1) カーソル Y座標
CSRX	EQU	0F3DDh 	;(1) 　　〃　 X座標
SX	EQU	0F562h 	;(2) 転送元基準点 X座標/RAMの転送元アドレス
SY	EQU	0F564h 	;(2)   　 〃      Y座標
DX	EQU	0F566h 	;(2) 転送先基準点 X座標/RAMの転送先アドレス
DY	EQU	0F568h 	;(2)  　  〃 　　 Y座標
NX	EQU	0F56Ah 	;(2) X方向転送ドット数
NY	EQU	0F56Ch 	;(2) Y方向　　 〃
ARG	EQU	0F56Fh 	;(1) 転送方向 [0]
LOGOP	EQU	0F570h 	;(1) ロジカルオペレーションコード [0-4,8-12]
DAC	EQU	0F7F6h 	;(2) 演算の対象となる値を設定するエリア
;		0F7F8h	;(2) 引数の値[画面モード:圧縮展開モード/テキスト保存再生モード]
CGPBAS	EQU	0F924h 	;(2) パターンジェネレータテーブルのベース番地
ATRBAS	EQU	0F928h 	;(2) スプライトアトリビュートテーブルのベース番地
ACPAGE	EQU	0FAF6h 	;(1) アクティブビデオページ番号
SCRMOD	EQU	0FCAFh 	;(1) スクリーンモードの番号
EXPTBL	EQU	0FCC1h 	;(1) MAIN-ROMのスロット番号

; Program work area (/重ね合わせ)

IP	EQU	 4000h 	;(224) 分割画像の位置 X-low /(1920) TEXT画面の待避領域
IP_XH	EQU	 4100h 	;(224) 分割画像の位置 X-high
IP_Y	EQU	 4200h 	;(224) 分割画像の位置 Y
IP_BM	EQU	 4300h 	;(224) 分割画像の最初の色
IP_SIZ	EQU	 4400h 	;(224) 分割画像の大きさ
IP_NX	EQU	 4500h 	;(224) 分割画像の横幅
IP_CHK	EQU	 4600h 	;(224) 分割画像のチェックサム
BLTHED	EQU	 46FCh 	;  (4) ビットブロックトランスファのヘッダ(SX,SY)
BLTWRK	EQU	 4700h 	;(256) ビットブロックトランスファの転送領域
BM	EQU	 4800h 	;(256) 原画像 /(256) 90度左回転行列 /(4352) 動的パレット後半退避
WTBL	EQU	 4900h 	;(256) 横     /横       /横引返     /横引返YJK
ZTBL	EQU	 4A00h 	;(256) 左45   /左45     /横ディザ   /横YJK
RWTBL	EQU	 4B00h 	;(256) 縦     /縦       /縦往復     /縦引返YJK
RZTBL	EQU	 4C00h 	;(256) 右45   /右45     /縦ハニカム /縦YJK
Z27TBL	EQU	 4D00h 	;(256) 左27   /横市松   /横市松     /横引折返YJK
Z63TBL	EQU	 4E00h 	;(256) 左63   /左45市松 /左45市松   /縦引折返YJK
RZ63TL	EQU	 4F00h 	;(256) 右63   /縦市松   /縦市松     /縦
RZ27TL	EQU	 5000h 	;(256) 右27   /横往復   /右45市松   /縦引往復折返YJK
W_Scan	EQU	 5100h 	;(256) 横走査画像
Z_Scan	EQU	 5200h 	;(256) 左45走査画像
RWScan	EQU	 5300h 	;(256) 縦走査画像
CN	EQU	 5400h 	;(256) 右45走査画像 /色
LN	EQU	 5500h 	;(256) 左27走査画像 /長さ
VD	EQU	 5600h 	;(256) 左63走査画像 /最適走査画像 /(257) 圧縮データ
LIVB	EQU	 5601h 	; (48)   /長さのγ符号
LA	EQU	 5660h 	; (32)   /長さのα符号
LB	EQU	 5680h 	; (32)   /長さのβ符号
PLTPOS	EQU	 5700h 	;(256) 右63走査画像 /パレットポジション [MTF係数]
PLTMAP	EQU	 5800h 	;(256) 右27走査画像 /パレットマップ [Pγ符号]
DYNPLT	EQU	 5900h 	;(14336) 動的パレット┌ 1番色x256
BASIC0	EQU	 8000h 	;(8960) BASIC前半    │40番色x :
;		 90F0h	;                    └56番色x256(設計上の最大値は62番色x256)
aDYPLT	EQU	 9100h 	;(17428) スタック領域の下限※これを越えると暴走する。
;		0D513h	;        スタック領域の上限
;		0D514h	;プログラム開始番地
;		0DDBFh	;プログラム終了番地
CommKey	EQU	0DDC0h 	;(64) 共通暗号鍵
;		0DE00h 	;(110) Variable data area       
CARCPL	EQU	0DE0Ch 	; (12) /反転文字列コード

; VRAM Page 0 (SCREEN6以下)
; 		06A00h 	; (1920)  TEXT画面の退避領域
;             (SCREEN7以上)
TextG	EQU	0D500h 	; (1920)  TEXT画面の退避領域
BAS0	EQU	0DD00h 	; (8960)┐BASIC前半退避領域
;		0FFFFh          ┘
; VRAM Page 1 (SCREEN7以上)
BAS1	EQU	0D400h 	; (9728)┐BASIC後半退避領域
;		0F9FFh          ┘
; VRAM Page 2 (SCREEN6以下)
; 	 	 0000h 	;(18688)┐BASIC退避領域
;		 48FFh          ┘

; Variable data area

X2	EQU	0DE00h 	; (2) 終点 X座標 [0-511]
Y2	EQU	0DE02h 	; (2)  〃  Y座標 [0-211]
X1	EQU	0DE04h 	; (2) 始点 X座標 [0-511]
Y1	EQU	0DE06h 	; (1)  〃  Y座標 [0-211]
LOGOP2	EQU	0DE07h 	; (1) ディザ+暗号+ロジカルオペレーションコード [0-4,8-12]
X3	EQU	0DE08h 	; (2) 大きさ X方向 [0-511] X2-X1
Y3	EQU	0DE0Ah 	; (2)   〃   Y方向 [0-211] Y2-Y1
RGBPLT	EQU	0DE0Ch 	;(32) RGBパレット
B0	EQU	0DE2Dh 	; (1) 1バイトのドット数 [1,2,4]=SCRMOD[8-12,5/7,6]
X4	EQU	0DE2Eh 	; (2) 分割画像の横幅 [16,32,64] B0*16
X5	EQU	0DE30h 	; (2) 末端分割画像の横幅 [1-64] (X3 AND(X4-1))+1
Y5	EQU	0DE32h 	; (2)  　   〃      縦幅 [1-16] (Y3 AND 15)+1
KX	EQU	0DE34h 	; (1) 分割画像の回数 X方向 [1-16] X3\X4+1
KY	EQU	0DE35h 	; (1)  　   〃	     Y方向 [1-14] Y3\16+1
NBM	EQU	0DE36h 	; (2) 分割画像の大きさ [0-255](NX*NY-1)\B0
BM0	EQU	0DE38h 	; (1)     　〃　　　 標準 [   255] X4,16
BM1	EQU	0DE39h 	; (1)     　〃　　　 右端 [ 3-255] X5,16
BM2	EQU	0DE3Ah 	; (1)     　〃　　　 下端 [15-255] X4,Y5
BM3	EQU	0DE3Bh 	; (1)     　〃　　　 右下 [ 0-255] X5,Y5
K	EQU	0DE3Ch 	; (2) 色が変化した回数 [0-255]
EndCol	EQU	0DE3Eh 	; (1) 動的パレットの初期値 [0]
Kps1	EQU	0DE3Fh 	; (1) K+1 (8bit)
RP	EQU	0DE40h 	; (1) 繰り返しの数 [0-223]
SD	EQU	0DE41h 	; (1) 走査法 [横,左45,縦,右45,左27,左63,右63,右27]=[0,1,2,3,4,5,6,7]
MP	EQU	0DE42h 	; (1) 最大パレットポジション [7,14,28,56,31,62,30]
PT	EQU	0DE43h 	; (1) パレットマップの種類 [0,1,2,3,0,1,1]
PMSUB	EQU	0DE44h 	; (1) パレットマップの補数 [0,1,3,7,0,1,1] 2^PT-1
IS	EQU	0DE45h 	; (2) 新色符号のインデックス長 [3,4,5] 
VLN	EQU	0DE47h 	; (1) 長さ符号の大きさ
VLIVB	EQU	0DE48h 	; (2) γ符号の大きさ [1-40..]
VLA	EQU	0DE4Ah 	; (2) α符号の大きさ [1-32] NBM\8+1
VLB	EQU	0DE4Ch 	; (2) β符号の大きさ [1-33] __スタティックデータ初期化領域↑
LOGOP1	EQU	0DE4Eh 	; (1) ロジカルオペレーションコード [0-4,8-12]
InterF	EQU	0DE4Fh 	; (1) インターレースフラグ [0,1]
VM0	EQU	0DE50h 	; (2)  7色パレットマップサイズ
VM1	EQU	0DE52h 	; (2) 14色パレットマップサイズ
VM2	EQU	0DE54h 	; (2) 28色パレットマップサイズ
VM3	EQU	0DE56h 	; (2) 56色パレットマップサイズ
VM4	EQU	0DE58h 	; (2) 31色パレットマップサイズ
VM5	EQU	0DE5Ah 	; (2) 62色パレットマップサイズ
VM6	EQU	0DE5Ch 	; (2) 30色パレットマップサイズ
VM5WRK	EQU	0DE5Eh 	; (2) VM5,VM4計算用ワークエリア
NX2	EQU	0DE60h 	; (2) 分割画像の方向転換 [16,32,64]
BMm	EQU	0DE62h 	; (2) 分割画像の大きさの場所 [BM0-BM3]
VA	EQU	0DE64h 	; (2) 圧縮データの総容量 [11-54536]
WS_K	EQU	0DE66h 	; (8) 横/左45/縦/右45/左27/左63/右63/右27の色変化数 [0-255]
Encryp	EQU	0DE6Eh	; (1) 暗号化フラグ [0=初期化,1=順列,2=共通]

; Constant

IP_H	EQU	   40h
IP_B_H	EQU	   43h
IP_S_H	EQU	   44h
BM_H	EQU	   48h
sBAS_H	EQU	   49h
WTBL_H	EQU	   49h
ZTBL_H	EQU	   4Ah
RWTL_H	EQU	   4Bh
RZTL_H	EQU	   4Ch
Z27T_H	EQU	   4Dh
Z63T_H	EQU	   4Eh
RZ63_H	EQU	   4Fh
RZ27_H	EQU	   50h
CN_H	EQU	   54h
PP_H	EQU	   57h
PM_H	EQU	   58h
DP_H	EQU	   59h
LIVB_L	EQU	   01h
LA_L	EQU	   60h
LB_L	EQU	   80h
WS_K_L	EQU	   66h
LOCK_H	EQU	  0CFh
sTextG	EQU	 1920 	;TEXT画面領域の保護バイト数
sDYPLT	EQU	14336 	;動的パレットのバイト数(56色x256)
sBASIC	EQU	18688 	;BASIC領域の保護バイト数
sBAS0	EQU	 8960 	;BASIC前半領域の保護バイト数
sBAS1	EQU	 9728 	;BASIC後半領域の保護バイト数
VerNum	EQU	  142	;Version number

Format:
	ORG	0D514h-7	;Bsave format
	DB	0FEh		;Header
	DW	Main		;Start address
	DW	End-1		;End address
	DW	Main		;Execution start address

;********************************
; [USR1]
; 画像の展開 2011/1228
; Compression and Decompression of an image.
;********************************

Main:
	CALL	RAMSLT		;PAGE1をRAMにする
	LD	HL,1
	LD	BC,8
	LD	A,(DAC+2)	;A#=スクリーンモード番号
	CP	10
	JR	Z,SCA

	CP	C
	JR	NC,SC8BC	;SCREEN 8,11,12

	INC	L		;L#=2
SCA:
	LD	C,40
	CP	7
	JR	NC,SC8BC	;SCREEN 7,10

	RRA
	JR	C,SC8BC		;SCREEN 5

	SLA	L		;SCREEN 6	L#=4
SC8BC:
	LD	(VA),BC
	LD	(B0),HL		;１バイトのドット数 B0
	CALL	VPAGE0		;アクティブページをVRAM-0
	LD	HL,BASIC0	;BASIC領域の始まり 8000h
	LD	DE,BAS0
	LD	BC,sBAS0	;BC#=1100h
	LD	A,(DAC+2)	;A#=SCREEN MODE
	CP	7
	JR	NC,DPLTSV

	LD	A,2		;SCREEN<7
	CALL	VPAGE
	LD	D,E		;DE#=0
DPLTSV:
	PUSH	HL
	PUSH	DE
	PUSH	BC

	CALL	LDIRVM		;BASIC領域をVRAMに退避
	CALL	VPAGE0
	LD	HL,3
	CALL	NRDVRM		;A#=Default logical oparation code
	LD	(LOGOP2),A
	PUSH	AF

	AND	15
	LD	(LOGOP),A
	LD	A,(Encryp)
	RRCA
	JR	NC,R90MTX

	LD	HL,BM		;暗号化が有効なら現状のパレットを継承する
	LD	DE,BASIC0
	LD	BC,4352
	LDIR			;裏RAMから動的パレットの後半を元の場所に戻す

; 90度左回転行列の作成 2003/0210
; Creation of a 90-degree left rotation matrix
;-------------------------------*
R90MTX:
	LD	HL,WTBL-1	;D=-1		Hand compile!
	LD	DE,10F0h	;DS=-16 DE#[16,-16]
	XOR	A		;S=256
	LD	B,D		;B#=16
LP_R90:
	LD	C,B		;FOR I=1 TO 16
	LD	B,D		;  JI=16
MTRX4:				;FOR J=1 TO JI
	INC	L		;  D=D+1
	ADD	A,E		;  S=S+DS
	LD	(HL),A		;  M(D)=S
	DJNZ	MTRX4		;NEXT J

	LD	B,C
	INC	A		;  S=S+257
	DJNZ	LP_R90		;NEXT I

	INC	HL		;HL#=WTBL  BC#[0,1]

	POP	AF		;A#=User logical oparation code
	RLA			;bit7 CY=Dither YJK mode
	PUSH	AF

	JR	C,ChkYJK	;dither ON

; 横行列の作成(通常画像) 2009/1018
; Creation of a horizontal matrix
;-------------------------------*
	XOR	A
	LD	B,D		;BC#[16, 1]
	LD	E,15		;DE#[16,15]
	CALL	SubDd2
	EXX

; 左45行列の作成 2009/1016
; Creation of a left incline matrix
;-------------------------------*
	INC	H		;HL#=ZTBL
	LD	BC,070Fh	;BC#[ 7,15]
	LD	D,C
	XOR	A
	LD	E,A		;DE#[15, 0]
	LD	(HL),A
	INC	L
LoopZi:
	CALL	SubA1i
	ADD	A,D
	CALL	SubA1i
	DJNZ	LoopZi

	CALL	SubA1i
	LD	B,7
LoopZd:
	CALL	SubA1d
	ADD	A,D
	CALL	SubA1d
	DJNZ	LoopZd

	INC	A
	LD	(HL),A

	POP	AF		;A#=マトリックスモード
	BIT	7,A
	PUSH	AF

	LD	HL,Z27TBL
	JR	NZ,DitMT	;bit6 ON ミックス画像

; 左27行列の作成 2009/0422
; Creation of a left 27-degree incline matrix
;-------------------------------*
	LD	D,1
	LD	A,14
	CALL	MTXEG3		;BC#[8,7]
LpMX2:
	CALL	ME3a1
	DJNZ	LpMX2

	LD	B,6
LpMX3:
	DEC	C
	CALL	ME3a1
	DJNZ	LpMX3

	LD	E,D
	CALL	ME3b1

; 左63行列の作成
; Creation of a left 63-degree incline matrix
;-------------------------------*
	INC	HL		;HL#=Z63TBL
	LD	D,16
	LD	A,-31
	CALL	MTXEG3		;BC#[8,7]
LpMX21:
	CALL	ME3a11
	DJNZ	LpMX21

	LD	B,6
LpMX31:
	DEC	C
	CALL	ME3a11
	DJNZ	LpMX31

	LD	E,D
	CALL	ME3b11
	JP	RL90		;基本行列の90度左回転

;-------------------------------*
ChkYJK:
	LD	A,(DAC+2)	;A#=スクリーンモード番号
	CP	10
	JR	NC,YJKMTX

; 横往復行列(縦往復行列の元)を作成 2008/1226
; The horizontal round trip procession (origin of the length round trip procession) is made.
;-------------------------------*
	CALL	YokoOu		;HL#=WTBL

; 縦ハニカム行列の元を作成 2009/0504
; The origin of the vertical honeycomb procession is made. 
;-------------------------------*
	INC	H		;HL#=ZTBL
	XOR	A
	LD	BC,0402h	;BC#[ 4, 2]
	LD	DE,211Fh	;DE#[33,31]
	CALL	SubHan
	ADD	A,48
	CALL	SubHan

; 横市松行列の作成 2009/0504
; Making of the horizontal dither procession
;-------------------------------*
	LD	H,Z27T_H
DitMT:
	XOR	A
	LD	BC,0802h	;BC#[ 8, 2]
	LD	DE,110Fh	;DE#[17,15]
	CALL	SubSdt
	SUB	16
	CALL	SubSdt

; 左45市松行列の作成 2008/1213
; Making of the 45 dither in the left processions
;-------------------------------*
	INC	H		;HL#=Z63TBL
	LD	A,-17
	LD	BC,040Fh	;BC#[ 4,15]
	LD	DE,11FFh	;DE#[17,-1]
	CALL	DMa
	ADD	A,C
	INC	E
	INC	E
	LD	D,-13
	EX	AF,AF'
	LD	A,47
	CALL	DMb
	INC	A
	LD	BC,04F1h	;BC#[  4,-15]
	LD	DE,0EF00h	;DE#[-17,  0]
	CALL	DMa2
	SUB	30
	INC	E
	INC	E
	INC	E
	INC	E
	LD	D,13
	EX	AF,AF'
	NEG
	CALL	DMb
	JR	RL90

; 縦引返YJK行列の元を作成 2009/0516
; The origin of vertical reversion YJK procession is made. 
;-------------------------------*
YJKMTX:
	XOR	A
	LD	BC,0402h	;BC#[ 4,2]
	LD	DE,4007h	;DE#[64,7]
	EXX
	LD	C,47		; C'#[47]
	LD	DE,5F3Fh	;DE'#[95,63]
	CALL	HikYJK
	EXX

; 縦YJK行列の元を作成 2008/1218
; The origin of vertical YJK procession is made. 
;-------------------------------*
	INC	H		;HL#=ZTBL
	XOR	A
	LD	BC,0210h	;BC#[ 2,16]
LpYJK:
	LD	DE,3F41h	;DE#[63,65]
	CALL	YJK
	LD	E,33
	CALL	YJK
	LD	DE,0BFC1h	;DE#[-65,-63]
	CALL	YJK
	LD	E,-15
	CALL	YJK
	DJNZ	LpYJK

; 横引折返YJK行列の作成 2009/0515
; Making of the [orikaeshi] YJK procession sidewise pull
;-------------------------------*
	LD	H,Z27T_H	;HL#=Z27TBL
	XOR	A
	LD	BC,0804h	;BC#[ 8,4]
	LD	DE,2003h	;DE#[32,3]
	EXX
	LD	BC,0F022h	;BC'#[-16,34]
	LD	DE,0D01Fh	;DE'#[-48,31]
	CALL	HV_YJK
	LD	BC,1002h	;BC#[16,2]
	LD	DE,1007h	;DE#[16,7]
	CALL	SubDd2
	EXX

; 縦引折返YJK行列の作成
; [Tatehiki] making of the YJK procession by return
;-------------------------------*
	INC	H		;HL#=Z63TBL
	CALL	VHOYJK
	LD	BC,0810h	;BC#[8,16]
	LD	DE,020Fh	;DE#[2,15]
	CALL	SubDd2
	EXX
GoRL90:
	LD	B,L		;B#=0

; 基本行列の90度左回転 2011/1228
; 90-degree left rotation of a basic matrix
;-------------------------------*
RL90:
	LD	DE,BM		;B#=0,L#=255
LP_WZR:
	PUSH	BC

	LD	H,D
	INC	L
	LD	B,2
LpRL90:
	INC	H		;HL#=WTBL(I),Z27TBL(I)
	LD	E,(HL)		;E#=W(I)
	LD	A,(DE)
	LD	C,A		;C#=R90(W(I))
	INC	H
	LD	E,(HL)		;E#=Z(I)
	LD	A,(DE)		;A#=R90(Z(I))
	INC	H		;縦行列=90度左回転(横行列)
	LD	(HL),C		;RW(I)=R90(W(I))
	INC	H		;右45行列=90度左回転(左45行列)
	LD	(HL),A		;RZ(I)=R90(Z(I))
	DJNZ	LpRL90

	POP	BC
	DJNZ	LP_WZR

	POP	AF		;CY=Dither YJK mode
	LD	L,B		;L#=0
	JR	NC,Normal	;ディザでないなら通常かミックス

	LD	A,(DAC+2)	;A#=スクリーンモード番号
	CP	10
	JR	C,GoDit

; 縦引往復折返YJK行列の作成 2009/0522
; Making of the turn YJK procession of [tatehiki] who blows eagerly
;-------------------------------*
	CALL	VHOYJK		;HL#=RZ27TL
	LD	C,16		;BC#[4,16]
	LD	E,15		;DE#[4,15]
	EXX
	DEC	E		;E'#[2]
	CALL	SubC
	EXX

; 縦行列の作成 2009/0522
; Making of the vertical procession
;-------------------------------*
	DEC	H		;HL#=RZ63TL
	XOR	A
	LD	B,C		;BC#[16,16]
	LD	D,1		;DE#[ 1,15]
	CALL	SubDd2
	EXX

; 横YJK行列の作成 2009/0516
; Making of the side YJK procession
;-------------------------------*
	LD	H,ZTBL_H	;HL#=ZTBL
	XOR	A
	LD	C,4		;BC#[16,4]
	LD	DE,1003h	;DE#[16,3]
	EXX
	LD	DE,0F0Eh	;DE'#[15,14]
	CALL	HiYJK2

; 横引返YJK行列の作成 2011/0420
; Making of the horizontal reversion YJK procession
;-------------------------------*
	LD	BC,0FF10h	;BC'#[-1,16]
	EXX
	DEC	H		;HL#=WTBL
	XOR	A		;BC#[16,4]
	LD	D,2		;DE#[ 2,3]
LpHYJK:
	CALL	SubA3
	EXX
	ADD	A,B		;+B'#
	EXX
	CALL	SubA3
	EXX
	ADD	A,C		;+C'#
	EX	AF,AF'
	XOR	A
	SUB	B
	LD	B,A		;B'#=-B'#
	EXX
	XOR	A
	SUB	D
	LD	D,A		;D#=-D#
	EX	AF,AF'
	DJNZ	LpHYJK

	JR	CallRC

; 横引き返し行列の作成 2009/0501
; Making of the horizontal reversion procession
;-------------------------------*
GoDit:
	LD	H,WTBL_H	;HL#=WTBL
	XOR	A
	LD	BC,1002h	;BC#[16, 2]
	LD	DE,010Fh	;DE#[ 1,15]
	CALL	LpSdt

; 横ディザ行列の作成 2009/0515
; Making of the horizontal dither procession
;-------------------------------*
	INC	H		;HL#=ZTBL
	XOR	A
	LD	B,8		;BC#[ 8,2]
	LD	DE,2007h	;DE#[32,7]
	EXX
	LD	BC,0F110h	;BC'#[-15,16]
	LD	D,-17		; D'#[-17]
	CALL	HV_YJK
	JR	CallRC
Normal:
	RLA
	JR	NC,CallRC	;bit6=0なら通常画像

; 横往復行列を作成 2010/0509
; The horizontal round trip procession is made. 
;-------------------------------*
	CALL	YokoOu		;HL#=RZ27TL

; 圧縮と展開の呼び出し
;The call of compression and decompression
;-------------------------------*
CallRC:
	LD	H,L		;L#=0 転送方向
	LD	(ARG-1),HL
	LD	(IP),HL
	LD	DE,X1
	LD	BC,(VA)
	CALL	Decomp		;画像を展開する
	LD	HL,BASIC0
	LD	DE,BM
	LD	BC,4352
	LDIR			;裏RAMに動的パレット後半を退避
	LD	A,(DAC+2)	;A#=SCREEN MODE
	CP	7
	LD	A,2
	JR	C,CalPPD

	XOR	A
CalPPD:
	POP	BC		;BC#=sBAS0
	POP	HL		;HL#=BAS0
	POP	DE		;DE#=BASIC0
	CALL	VPAGE
	CALL	LDMVP0		;VRAMに退避したBASIC領域を元に戻す
	LD	HL,(VA)
	LD	(DAC+2),HL	;圧縮データの総容量をBASICの戻り値として返す
	JP	ROMSLT		;PAGE1をBASIC ROMに戻してBASICに戻る

;********************************
; 行列エンジン2 2011/1226
; Matrix Engine 2
;********************************

; 左45市松行列 2008/1226
; 45 dither in the left procession
;-------------------------------*
DMa:
	PUSH	BC

	ADD	A,D
	INC	E
	INC	E
	LD	B,E
LpDMa1:
	LD	(HL),A
	INC	L
	SUB	C
	DJNZ	LpDMa1

	DEFB	0FEh		;CP n (1byte skip)
DMa2:
	PUSH	BC

	ADD	A,D
	INC	E
	INC	E
	LD	B,E
LpDMa2:
	LD	(HL),A
	INC	L
	ADD	A,C
	DJNZ	LpDMa2

	POP	BC
	DJNZ	DMa

	RET

;-------------------------------*
DMb:
	EX	AF,AF'
	LD	B,4
LpDMb:
	PUSH	BC

	ADD	A,D
	DEC	E
	DEC	E
	LD	B,E
LpDMb1:
	LD	(HL),A
	INC	L
	SUB	C
	DJNZ	LpDMb1

	EX	AF,AF'
	LD	B,A
	EX	AF,AF'
	ADD	A,B
	DEC	E
	DEC	E
	LD	B,E
LpDMb2:
	LD	(HL),A
	INC	L
	ADD	A,C
	DJNZ	LpDMb2

	POP	BC
	DJNZ	LpDMb

	RET

; 横往復行列を作成
; The horizontal round trip procession is made. 
;-------------------------------*
YokoOu:
	XOR	A
	LD	BC,0310h	;BC#[ 3,16]
	LD	DE,1F21h	;DE#[31,33]
	CALL	LpHRT2
	LD	E,17
	CALL	YJK
	LD	DE,0DFE1h	;DE#[-33,-31]
	LD	B,4
LpHRT2:
	CALL	YJK
	DJNZ	LpHRT2

	RET

;-------------------------------*
YJK:
	PUSH	BC

	LD	B,C
LpYJK1:
	LD	(HL),A
	INC	L
	INC	A
	DJNZ	LpYJK1

	ADD	A,D
	LD	B,C
LpYJK2:
	LD	(HL),A
	INC	L
	DEC	A
	DJNZ	LpYJK2

	ADD	A,E

	POP	BC
	RET

;********************************
; 行列エンジン3 2011/0417
; Matrix Engine 3
;********************************

; 左27,左63行列 2009/0522
; 27 in the left and 63 processions in the left
;-------------------------------*
MTXEG3:
	EX	AF,AF'
	XOR	A
	LD	B,1
	LD	E,D		;E#[1,16]
	CALL	ME3b3
	LD	BC,700h
LpMX1:
	INC	C
	CALL	ME3a0
	DJNZ	LpMX1

	LD	B,8		;BC#[8,7]
	RET

;-------------------------------*
ME3a0:
	PUSH	BC

	CALL	ME3b0
	JR	ME3a2
ME3a1:
	PUSH	BC

	LD	E,A
	CALL	ME3b1
	JR	ME3a2
ME3a11:
	PUSH	BC

	LD	E,A
	CALL	ME3b11
ME3a2:
	NEG
	CALL	ME3b0
	NEG

	POP	BC
	RET
		
;-------------------------------*
ME3b0:
	LD	E,A
	LD	B,D
	JR	ME3b2
ME3b1:
	LD	B,15
	JR	ME3b2
ME3b11:
	LD	B,-15
ME3b2:
	EX	AF,AF'
	ADD	A,B
	INC	L
	LD	B,C
ME3b3:
	LD	(HL),A
LpME1:
	ADD	A,E
	INC	L
	LD	(HL),A
	DJNZ	LpME1

	EX	AF,AF'
	RET

;********************************
; 行列エンジン4 2011/0620
; Matrix Engine 4
;********************************

; 横ハニカム行列
; Horizontal honeycomb procession
;-------------------------------*
SubHan:
	CALL	SubSdt
	SUB	32

; 横市松行列
; Horizontal dither procession
;-------------------------------*
SubSdt:
	PUSH	BC

	CALL	LpSdt
	EX	AF,AF'
	XOR	A
	SUB	D
	LD	B,E
	LD	E,A		;E#=-D#
	XOR	A
	SUB	B
SSdt:
	LD	D,A		;D#=-E#
	EX	AF,AF'

	POP	BC
	RET

;-------------------------------*
LpSdt:
	CALL	SubA
	ADD	A,D
	CALL	SubA
	ADD	A,E
	DJNZ	LpSdt

	RET

; 引折返YJK行列
; It pulls and YJK is formed a line by return. 
;-------------------------------*
VHOYJK:
	XOR	A
	LD	BC,0420h	;BC#[4,32]
	LD	DE,0407h	;DE#[4, 7]
	EXX
	LD	BC,0C06h	;BC'#[ 12,6]
	LD	DE,0EC03h	;DE'#[-20,3]
HV_YJK:
	CALL	SubDd
	ADD	A,B
	CALL	SubDd
	ADD	A,C
	CALL	SubDd
	ADD	A,D
	CALL	SubDd
	ADD	A,E
	EXX
	RET

; 横縦引返YJK行列
; Horizontal vertical reversion YJK procession
;-------------------------------*
HikYJK:
	CALL	HiYJK2
	ADD	A,C
HiYJK2:
	CALL	SubC
	ADD	A,D
SubC:
	CALL	SubDd
	SUB	E		;E'#[63,14,2,1]
SubDd:
	EXX
SubDd2:
	PUSH	BC
LpDdt:
	CALL	SubA1
	ADD	A,D
	DJNZ	LpDdt

	EX	AF,AF'
	XOR	A
	SUB	D
	LD	D,A		;D#=-D#
	EX	AF,AF'

	POP	BC
	EXX
	RET

;-------------------------------*
SubA:
	PUSH	BC

	LD	B,7
	JR	SubA2		;C#=+-2
SubA3:
	CALL	SubA1
	ADD	A,D
	JR	SubA1
SubA1d:
	DEC	E
	DEC	E
SubA1i:
	INC	E
	INC	A
SubA1:
	PUSH	BC

	LD	B,E
SubA2:
	LD	(HL),A
LpSubA:
	INC	L
	ADD	A,C
	LD	(HL),A
	DJNZ	LpSubA

	POP	BC
	INC	L
	EX	AF,AF'
	XOR	A
	SUB	C
	LD	C,A		;C#=-C#
	EX	AF,AF'
	RET

;********************************
; アクティブビデオページの切り換え 2011/0421
; Change of an active video page
;********************************

LDMVP0:
	CALL	LDIRMV
VPAGE0:
	XOR	A		;Page 0
VPAGE:
	LD	(ACPAGE),A
	LD	IX,SETPAG
	JP	EXTROM

;********************************
; スタティックデータの計算 2011/0519
; Calculation for the static data
;********************************

STATIC:
	LD	HL,DYNPLT	;動的パレット(暗号鍵)の初期化
	LD	B,L		;B#=0
	LD	A,(Encryp)
	CP	1
	JR	Z,Encry		;順列暗号が有効なら現状のパレットを継承する

	EX	AF,AF'

; 暗号鍵を初期化する
; The cipher key is initialized.
;-------------------------------*
	LD	BC,38FFh	;BC#[56,255]
	LD	A,(DAC+2)	;A#=screen mode
	CP	8
	LD	D,L		;D#=0
	LD	E,L		;E#=0
	JR	Z,NotZ2

	INC	E		;E#=1
	JR	NC,NotZ2
	JR	NotZ1
LpDPLT:
	INC	D		;D#=1-56
	LD	A,D
	RLCA			; SC5-7
	RLCA
	RLCA
	RLCA			; PPPP00PP
	LD	C,A
NotZ1:
	LD	E,B
	LD	B,L		;B#=0
Lp256:
	LD	(HL),C
	INC	C
	INC	L
	DJNZ	Lp256

	LD	B,E
	INC	H
	DJNZ	LpDPLT

	JR	ChkKey
LpDPLa:
	INC	D		;D#=1-56
	LD	A,D
	LD	C,L		;C#=0
	RRA			; RGB       YJK
	RR	C		; B0000000  J0000000
	RR	C		; 0B000000  0J000000
	DEC	E
	JR	Z,NotRGB

	RRA
NotRGB:
	INC	E
	RR	C		; R0B00000  00J00000
	RRA
	RR	C		; RR0B0000  Y00J0000
	DEC	E
	JR	NZ,NotYJK

	RRA
NotYJK:
	INC	E
	RR	C		; 0RR0B000  YY00J000  
	RRA
	RR	C		; G0RR0B00  YYY00J00  
	RRA
	RR	C		; GG0RR0B0  YYYY00J0  
	RRA
	RR	C		; GGG0RR0B  YYYYY00J  
NotZ2:
	LD	A,B
	LD	B,L		;B#=0
Lp256a:
	LD	(HL),C
	INC	C
	INC	L
	DJNZ	Lp256a

	LD	B,A
	INC	H
	DJNZ	LpDPLa
ChkKey:
	EX	AF,AF'
	JR	C,Encry

; 共通鍵で動的パレットを512回掻き混ぜる 2011/0519
; A dynamic palette is mixed 512 times with a common key.
;-------------------------------*
	LD	HL,CommKey
	LD	DE,PLTMAP
	LD	C,64
	LDIR
	LD	H,D		;HL#=PLTMAP
	LD	L,B
	LD	C,192
	LDIR
	LD	B,192
LpADD:
	LD	A,(HL)
	ADD	A,B
	LD	(HL),A
	INC	L
	DJNZ	LpADD
LpKey:
	LD	A,(HL)
	LD	E,B
	CALL	DPscan
	CALL	DPsca1
	LD	B,E
	DEC	H		;HL#=PLTMAP
	INC	L
	DJNZ	LpKey

; スタティックデータを初期化 
; Static data is initialized.
;-------------------------------*
Encry:
	LD	HL,X5+1		;X5+1～VLB+1
	LD	DE,Y5
	LD	(HL),B
	LD	C,28
	LDIR
	LD	HL,16
	LD	(NY),HL		;初期値 NY=16
	LD	A,(B0)		;分割画像の横幅 X4=B0*16
	LD	C,A		;C#=B0[1,2,4]
	RRA
	JR	C,SETX4

	SLA	L		;HL#=32
	RRA
	JR	C,SETX4

	SLA	L		;HL#=64
SETX4:
	LD	(X4),HL
	LD	(NX),HL		;初期値 NX=X4
	LD	(NX2),HL	;       NX2=X4
	LD	E,L		;E#=X4
	LD	D,L
	LD	HL,(X3)		;末端分割画像の横幅 X5=(X3 AND (X4-1))+1
	LD	A,L
	DEC	D
	AND	D
	INC	A
	LD	(X5),A
	EX	AF,AF'		;A'#=X5
	LD	A,(Y3)		;縦幅 Y5=(Y3 AND 15)+1
	LD	D,A		;D#=Y3
	AND	15
	INC	A
	LD	(Y5),A
	SRL	H		;KX=X3\X4+1
	RR	L
	SRL	E
	SRL	E
LPKX:
	SRL	L
	SRL	E
	JR	NC,LPKX

	INC	L		;L#=KX
	LD	A,D		;縦方向の回数 KY=Y3\16+1
	RRA
	RRA
	RRA
	RRA
	AND	15
	INC	A
	LD	H,A		;H#=KY
	LD	(KX),HL
	LD	IX,BM1
	EX	AF,AF'		;A#=X5
	LD	E,16		;H#=X5
	CALL	BM1_32		;右端 BM1(X5,16)
	LD	HL,(B0)		;H#=X4
	LD	DE,(Y5)		;E#=Y5
	CALL	BM1_3		;下端 BM2(X4,Y5)
	CALL	BM1_32		;右下 BM3(X5,Y5)
	LD	HL,BM0
	LD	A,255
	LD	(HL),A		;標準 BM0=255
	LD	(NBM),A		;NBM 初期値=255
	LD	(BMm),HL	;m(BMm)=mBM0
	LD	HL,(Y1)
	LD	H,1
	LD	(SY),HL		;矩形転送先はVRAM-1
	LD	(DY),HL
	LD	A,(DAC+2)	;A#=スクリーンモード番号
	CP	8
	JR	C,SC567A

	CP	10
	RET	NZ		;SCREEN 8,11,12
SC567A:
	LD	A,H		;A#=1 RGBパレットの転送準備
	CALL	VPAGE		;アクティブページをVRAM-1
	LD	HL,(ATRBAS)
	LD	L,80h
	LD	DE,RGBPLT
	LD	C,32
	XOR	A		;F#=Z
	RET

;********************************
; 分割画像のバイト数の計算 (NX*NY-1)\B0  2011/0421
; Calculation for the number of bytes of a division image.
;********************************

BM1_32:
	LD	H,A		;H#=X5
BM1_3:
	CALL	MULT		;掛け算(HL#=H#*E#)
	DEC	HL
	LD	B,C		;C#=B0
	SRL	B		;B#=B0\2
	JR	C,BMSET		;SCREEN 8~12	B#=0
LPBM:
	SRL	H		;HL#\2
	RR	L
	DJNZ	LPBM
BMSET:
	LD	(IX+0),L
	INC	IX
	RET

;********************************
; 掛け算^-^;HL# = H# * E#
; Multiplication
;********************************

MULT:
	LD	D,0
	LD	L,D
	LD	B,8
MULT1:
	ADD	HL,HL
	JR	NC,MULT2

	ADD	HL,DE
MULT2:
	DJNZ	MULT1

	RET

;********************************
; 分割画像の位置の記録 2010/0614
; Record of the position of a division image
;********************************

IPOSIT:
	EX	DE,HL		;(HL,A,A',B,C)#=(SX,SY,HC,VBM,CHK*SUM)
	LD	HL,IP
	INC	(HL)
	LD	L,(HL)
	LD	(HL),E		;E#=X_L
	INC	H
	LD	(HL),D		;D#=X_H
	INC	H
	LD	(HL),A		;A#=Y
	EX	AF,AF'
	INC	H
	LD	(HL),A		;A#=HC
	INC	H
	LD	(HL),B		;B#=VBM
	INC	H
	LD	A,(NX)
	LD	(HL),A		;A#=NX
	INC	H
	LD	(HL),C		;C#=CHECK*SUM
	RET

;********************************
; 過去の分割画像の再利用 2011/0209
; Reuse of the past division image
;********************************

IPBLTV:
	LD	H,IP_H
	LD	E,(HL)
	INC	H
	LD	D,(HL)
	INC	H
	LD	A,(HL)
	LD	HL,(SX)
	LD	BC,(SY)
	PUSH	DE

	EXX

	POP	HL
	LD	(SX),HL
	LD	(SY),A
	LD	HL,SX
	CALL	EXTROM
	EXX
	LD	(SX),HL
	LD	(SY),BC
	RET

;********************************
; 縦の分割サイズの検出 2011/0708
; Detection of vertical division size
;********************************

NYEND:
	LD	A,B		;A#=KY
	LD	B,C		;B#=KX
	LD	C,A		;(B,C)#=(KX,KY)
	DEC	A
	RET	NZ
				;KY=1なら分割サイズを下端に
	LD	HL,(Y5)
	LD	(NY),HL
	LD	HL,BMm		;(HL#)=m[BM0,BM1]
	INC	(HL)
	INC	(HL)
	JR	SetNBM		;(HL#)=[BM2,BM3]

;********************************
; 横の分割サイズの検出 2002/0204
; Detection of horizontal division size
;********************************

NXEND:
	LD	HL,(KX)
	LD	A,H		;A#=KY
	DEC	L		;L#=KX-1
	JR	NZ,KXls1

	CP	C		;C#=KY~
	RET	NZ		;(KX=1 AND KY~<>KY)なら分割サイズは不変
KXls1:
	XOR	C		;C#=KY~
	RRA
	JR	C,NXEND2

	DEC	B		;奇数ライン→	B#=KX~		
	RET	NZ
			
	LD	HL,BMm		;最終列なら分割サイズを右端に
	INC	(HL)		;(HL#)=m[BM1,BM3]
	LD	A,(X5)
	JR	SETNX
NXEND2:
	LD	A,L		;偶数ライン←	A#=KX-1	
	CP	B		;		B#=KX~
	RET	NZ
KX_1:
	LD	HL,BMm		;右から２番目なら分割サイズを標準に戻す
	DEC	(HL)		;(HL#)=m[BM0,BM2]
	LD	A,(X4)
SETNX:
	LD	(NX),A
SetNBM:
	LD	L,(HL)
	LD	A,(HL)
	LD	(NBM),A
	RET

;********************************
; 分割画像の方向転換 2011/0617
; Turn of a division image
;********************************

TURNX:
	DEC	DE		;DE#=NX2
	LD	A,E
	CPL
	LD	E,A
	LD	A,D
	CPL
	LD	D,A
	LD	(NX2),DE	;NX2=-NX2
	ADD	HL,DE		;HL#=次の行の開始位置
	LD	DE,RWTBL	;第３マトリックスを反転 Normal/Mix/Dit
	LD	A,(LOGOP2)
	RLA			;Matrix Mode
	JR	NC,LpRVT

	LD	D,RZ63_H	;第７マトリックスを反転 YJK
LpRVT:
	LD	A,(DE)
	CPL
	LD	(DE),A
	INC	E
	DJNZ	LpRVT

	RET

;********************************
; 動的パレットの更新 (色順列) 2011/0418
; Renewal of dynamic palette (Color Permutation)
;********************************

DPdef:
	LD	C,0		;動的パレットの初期値 C#[0]
	LD	L,C		;L#=前色/今色
DPsca1:
	LD	A,L		;A#=前色
DPscan:
	LD	L,C		;L#=前色/今色
DPsca3:
	LD	C,A		;A#=今色/前色
DPsca2:
	LD	H,DP_H
	LD	B,56
LpDynp:
	CP	(HL)
	JR	NZ,NextDP

	LD	A,H
	SUB	DP_H
	INC	A		;A#=[1-56]
	LD	B,A
	DEC	B
	RET	Z

	JR	LpRott	
NextDP:
	INC	H
	DJNZ	LpDynp

	DEC	H		;H#=DP_H+55
	LD	B,55
	XOR	A
LpRott:
	DEC	H
	LD	D,(HL)
	INC	H
	LD	(HL),D
	DEC	H
	DJNZ	LpRott

	LD	(HL),C
	RET

;********************************
; パレットマップの補足数の計算 2011/1226
; Calculation of number of supplementations of palette maps
;********************************

PMSset:
	CP	2		;A#=PT [0,1,2,3,4,5,6]
	LD	C,3		;IS=3
	JR	C,SetPSB
	JR	Z,PT2

	CP	C
	JR	Z,PT3

	SUB	C		;A#=1,2,3
	CP	C
	DEC	A		;A#=0,1,2
	JR	C,SetPT

	LD	C,A		;C#=2
	DEC	A		;A#=1
SetPT:
	LD	(PT),A		;パレットの種類 [0,1,2,3,0,1,1]
	INC	C
	INC	C		;C#=5,5,4
	DEFB	11h		;LD DE,nn (2byte skip)
PT3:
	RLCA
PT2:
	INC	A
SetPSB:
	LD	(IS),BC		;新色符号のインデックス長 [3,3,3,3,5,5,4]
	LD	(PMSUB),A	;  パレットマップの補足数 [0,1,3,7,0,1,1]
	RET

;********************************
; 画像の展開 2011/0420
; Decompression of an image
;********************************

Decomp:
	CALL	LDIRMV		;VRAM-0から始点と大きさを転送
	CALL	STATIC		;スタティックデータを計算
	JR	NZ,ESC8BC

	EX	DE,HL		;SCREEN 5-7,10はVRAM_1にRGBパレットを転送
	CALL	LDIRVM
	LD	IX,RSTPLT	;VRAMからRGBパレットをリストア
	CALL	EXTROM
	CALL	VPAGE0		;アクティブページをVRAM_0
ESC8BC:
	LD	HL,BLTHED
	LD	(SX),HL
	LD	HL,(X1)
	LD	(DX),HL
	LD	BC,(KX)
LPYres:
	PUSH	BC		;(B,C)#=(KY,KX) Ｙ方向の処理

	CALL	NYEND		;分割サイズの検出_Y
LPXres:
	PUSH	BC		;(B,C)#=(KX,KY) X方向の処理

	CALL	NXEND		;分割サイズの検出_X
	LD	A,(RP)		;繰り返しの数を知る
	OR	A
	JR	NZ,VQ_ON

	CALL	MEMdec		;メモリに画像を展開
	LD	HL,NX
	LD	DE,BLTHED
	LD	BC,4
	LDIR
	LD	L,62h
	LD	IX,BLTVM
	CALL	EXTROM		;メモリからVRAMに矩形転送
	JR	NEXTX
VQ_ON:
	DEC	A		;RPを１つ減す
	LD	(RP),A
	LD	A,(IP)
	LD	L,A		;L#=IP 画像番号
VQ_BVV:
	LD	IX,BLTVV	;VRAM間で矩形転送
	CALL	IPBLTV		;過去の分割画像を利用する
NEXTX:
	POP	BC		;分割画像をX方向に移動
	LD	HL,(DX)
	LD	DE,(NX2)
	ADD	HL,DE
	LD	(DX),HL
	DJNZ	LPXres

	CALL	TURNX		;分割画像の方向転換
	LD	(DX),HL		;次の行の開始位置
	LD	HL,(DY)
	LD	DE,(NY)
	ADD	HL,DE		;分割画像をY方向に移動
	LD	(DY),HL

	POP	BC
	DJNZ	LPYres

	XOR	A		;Zフラグを立てる
	RET

;********************************
; メモリに画像を展開する 2011/0417
; An image is decompressed to a memory.
;********************************

MEMdec:
	LD	HL,(DX)		;画像の位置を記憶
	LD	A,(DY)
	CALL	IPOSIT		;(HL,A)#=(DX,DY)
	LD	HL,(VA)		;ヘッダ検出
	CALL	NRDVRM
	INC	HL
	LD	(VA),HL
	LD	B,A		;B#=ヘッダ
	AND	11111000b
	CP	11110000b
	LD	A,B
	JR	NZ,LrCr		;走査角度の検出

	CP	11110010b
	JR	C,VQ_r

	LD	A,(NBM)		;BM 11110010b
	LD	DE,BLTWRK

; VRAMからRAMに圧縮データを転送する
; Compression data is transmitted to RAM from VRAM.
;-------------------------------*
LDMV:
	LD	C,A
	LD	B,0
	INC	BC
	LD	HL,(VA)
	PUSH	HL

	ADD	HL,BC
	LD	(VA),HL

	POP	HL
	JP	LDIRMV
VQ_r:
	EX	AF,AF'		;A'#=ヘッダ保存
	CALL	NRDVRM
	INC	HL
	LD	(VA),HL
	LD	L,A		;L#=IP 画像番号
	EX	AF,AF'		;A'#=(RP,IP)
	RRA
	JR	C,RETCLR	;VQ-IDX 11110001b
				;VQ-RLN 11110000b
	EX	AF,AF'		;A#=RP 繰り返しの数
	LD	(RP),A
	LD	HL,IP
	DEC	(HL)
	LD	L,(HL)		;L#=IP 画像番号
RETCLR:
	POP	BC		;RET CLEAR
	JR	VQ_BVV

; 走査行列の検出
; Detection of a scanning matrix
;-------------------------------*
LrCr:
	AND	00000111b	;(0-7)=(横,左45,縦,右45,左27,左63,右63,右27)
	LD	(SD),A
	LD	A,B
	PUSH	AF

	LD	BC,32
	LD	DE,LA
	AND	11000000b	;長さの符号を調べる
	JR	NZ,LNLALB

; 長さのγ符号を展開する 2011/0209
; Gamma code of length is decompressed.
;-------------------------------*
	PUSH	HL		;00xxxxxxb LIVB	HL#=(VA)

	LD	E,LIVB_L	;DE#=LIVB
	PUSH	DE

	CALL	LDIRMV		;とりあえずLIVBを32バイト獲得
	LD	HL,LN
	EX	(SP),HL		;HL#=LIVB,(SP)=LN
	LD	A,80h
	EXX
	LD	BC,(NBM)
	EXX
LPSIV:
	PUSH	AF		;A#=START_BIT

	LD	C,(HL)		;HL#=LIVB
	INC	L
	LD	D,(HL)
	INC	L
	LD	E,(HL)
	DEC	L
	DEC	L
	JR	LSSr
LPSr:
	SLA	E		;START SHIFT
	RL	D
	RL	C
LSSr:
	RLCA			;START_BIT <<
	JR	NC,LPSr

	POP	AF
	LD	B,0
LPIr:
	INC	B		;INDEX SHIFT	B#=1~8		
	RRCA
	JR	NC,NCIr

	INC	L		;LIVB++
NCIr:
	SLA	D
	RL	C
	JR	NC,LPIr

	LD	E,1
	JR	NCVr
LPVr:
	SLA	C		;VALUE SHIFT
	RL	E		;E#=L+1
	RRCA
	JR	NC,NCVr

	INC	L		;LIVB++
NCVr:
	DJNZ	LPVr

	EX	(SP),HL		;HL#=LN,(SP)=LIVB
	LD	D,A
	LD	A,E
	EXX
	ADD	A,B		;A#=1~256
	DEC	A
	CP	C		;C#=NBM
	INC	A
	LD	B,A
	EXX
	LD	A,D
	DEC	E		;E#=L
	LD	(HL),E
	INC	L		;LN++
	EX	(SP),HL		;HL#=LIVB,(SP)=LN
	JR	C,LPSIV

	LD	B,0
	LD	C,L		;BC#=VLIVB

	POP	HL		;HL#=LN
	LD	A,L
	DEC	A		;A#=色変化の回数

	POP	HL		;HL#=(VA)
	ADD	HL,BC
	JP	SetVA

;-------------------------------*
LNLALB:
	CP	10000000b
	LD	A,(NBM)
	JR	C,LAr		;01xxxxxxb LA	α符号の展開
	JR	NZ,LNr		;11xxxxxxb LN	長さ列の展開

; 長さのβ符号の展開 2009/1026
; Progressing of beta code of length
;-------------------------------*
LBr:				;10xxxxxxb LB
	PUSH	HL		;HL#=VA
	PUSH	DE		;DE#=LA
	PUSH	AF

	LD	E,LB_L		;DE#=LB
	CALL	LDIRMV		;LBにとりあえず32バイト転送

	POP	AF		;A#=NBM
	POP	HL		;HL#=LA
	PUSH	HL

	LD	DE,LA+1
	LD	BC,31
	LD	(HL),255
	LDIR			;LAを255で埋める
	INC	L		;HL#=LB [80h]
	RRA
	RRA
	RRA
	AND	1Fh		;A#=VLA-1 [0-31]
	LD	B,A
	INC	B		;B#=VLA [1-32]
	RRA
	RRA
	RRA
	AND	3		;A# =(VLA-1)\8 [0-3]
	ADD	A,L		;A# =(VLA-1)\8+LB_L
	LD	E,A		;DE#=(VLA-1)\8+LB
	LD	A,L		;A# =80h
LpLBd:
	RL	(HL)
	JR	NC,NexLBd

	EX	AF,AF'		;A'#=bit counter
	EX	(SP),HL		;HL#=LA
	INC	E
	LD	A,(DE)
	LD	(HL),A
	EX	(SP),HL		;HL#=LB
	EX	AF,AF'		;A#=bit counter
NexLBd:
	RRCA
	JR	NC,NexBd

	INC	L		;LB++
NexBd:
	EX	(SP),HL		;HL#=LA
	INC	L		;LA++
	EX	(SP),HL		;HL#=LB
	DJNZ	LpLBd

	POP	HL		;HL#=LA
	POP	HL		;HL#=VA
	LD	A,E
	SUB	LB_L-1
	LD	C,A
	ADD	HL,BC
	LD	(VA),HL
	LD	E,LA_L		;DE#=LA
	PUSH	DE		;(SP)=LA

	JR	GoLA

; 長さのα符号の展開 2000/1231
; Decompression of alpha code of length
;-------------------------------*
LAr:
	RRA			;01xxxxxxb LA
	RRA
	RRA
	AND	1Fh		;A#=VLA-1
	PUSH	DE		;DE#=LA

	CALL	LDMV		;長さのα符号を転送
GoLA:
	LD	HL,VD-1
	LD	C,L		;C#=-1
	EX	(SP),HL		;HL#=LA,(SP)=VD-1
	LD	DE,(NBM)	;(D,E)#=(0,NBM)
	XOR	A
LpLAR:
	LD	B,8
LPLNR1:
	RR	(HL)
	JR	NC,INCL

	EX	(SP),HL		;HL#=LN
	INC	L
	LD	(HL),D
	LD	D,C		;D#=-1
	EX	(SP),HL		;HL#=LA
INCL:
	CP	E
	JR	NC,KSET

	INC	A
	INC	D		;D#=長
	DJNZ	LPLNR1

	INC	L
	JR	LpLAR
KSET:
	POP	HL		;色変化の回数
	LD	A,L
	JR	SetK

; 長さ列の展開 2000/1216
; Decompression of a length sequence
;-------------------------------*
LNr:
	DEC	D		;11xxxxxxB LN
	LD	E,B		;DE#=LN
	LD	C,A		;BC#=[0,NBM]
LP_LNr:
	CALL	NRDVRM
	LD	(DE),A
	INC	E
	INC	HL
	ADD	A,B
	LD	B,A
	INC	B
	CP	C
	JR	C,LP_LNr	;A#<NBM

	LD	A,E
	DEC	A		;A#=色変化の回数
;-------------------------------*
SetVA:
	LD	(VA),HL
SetK:
	LD	(K),A		;色変化の回数
	INC	A
	LD	(Kps1),A

; 色の展開
; Decompression of a color
;-------------------------------*
	CALL	DPdef		;動的パレットの初期値を更新

	POP	AF
	AND	00111000b	;色の符号
	CP	00111000b
	JR	C,PMAPr		;xx110xxxb PMAP_0-6
CNr:
	LD	DE,CN		;色を転送
	PUSH	DE

	LD	A,(K)
	CALL	LDMV

; 動的パレットの更新 2011/0212
; Renewal of dynamic palette
;-------------------------------*
	LD	L,0
	EXX

	POP	HL		;HL'#=CN
	LD	A,(Kps1)
	LD	B,A		;B'#=K+1
LpD256:
	LD	A,(HL)		;A#=今色
	EXX
	CALL	DPsca3		;直前色のパレットを更新
	CALL	DPsca1		;現在色のパレットを更新
	EXX			;HL#=CN
	INC	L
	DJNZ	LpD256

	JP	LC_BMr		;色と長さで画像を展開

; パレットマップから色を展開 2011/0417
; A color is decompressed from a palette map.
;-------------------------------*
PMAPr:
	RRCA			;A# [0,8,16,24,32,40,48]
	RRCA
	RRCA
	LD	(PT),A		;A# [0,1, 2, 3, 4, 5, 6] パレットマップの種類
	CALL	PMSset
	LD	HL,(VA)
	PUSH	HL		;HL#=(VA)

	LD	A,(K)
	LD	C,A		;とりあえずPLTMAPを色の変化数バイト転送
	LD	DE,PLTMAP
	PUSH	DE

	CALL	LDIRMV

	POP	HL		;HL#=PLTMAP
	EXX
	LD	HL,CN		;HL'#=CN
	LD	BC,(EndCol)	;BC'#[K+1,0]
	LD	A,80h		;A#=Start_bit
LP_PMr:
	EXX
	PUSH	AF		;A#=Start_bit

	LD	C,(HL)
	INC	L
	LD	D,(HL)
	INC	L
	LD	E,(HL)
	DEC	L
	DEC	L
	JR	SSr
LP_SSr:
	SLA	E		;Start Shift*****
	RL	D
	RL	C		;C# << D# << E#
SSr:
	RLCA			;Start_bit <<
	JR	NC,LP_SSr	;*****Start Shift

	LD	A,(IS)
	LD	B,A		;B#[3,4,5]

	POP	AF		;A#=Start_bit
Lp_ISr:
	RRCA			;Index_Shift*****  Start_bit >>
	JR	NC,ISr

	INC	L		;PLTMAP +1
ISr:
	SLA	D
	RL	C		;NewCol/PM = C# << D#
	JR	C,GoVSr

	DJNZ	Lp_ISr		;*****Index_Shift
				;新色の場合 PP=0
	EX	AF,AF'		;A'#=Start_bit
	INC	L		;PLTMAP +1
	PUSH	HL

	EXX
	LD	A,C
	EXX
	LD	L,A
	LD	A,C		;A#=今色
	CALL	DPsca2		;直前色のパレットを更新
	CALL	DPsca1		;現在色のパレットを更新
	LD	A,L		;A#=今色
	JR	NextCN
GoVSr:				;PP>0
	EX	AF,AF'		;A'#=Start_bit
	LD	A,(IS)
	SUB	B
	INC	A
	LD	B,A
	LD	A,(PT)
	ADD	A,B		;PT+IS+1
	LD	B,A		;B#=PT+IS+1=VS
	EX	AF,AF'		;A#=Start_bit
	LD	E,1
	JR	VSr
LP_VSr:
	SLA	C		;Value_Shift*****
	RL	E		;PM = E# << C#
	RRCA			;Start_bit >>
	JR	NC,VSr

	INC	L		;PLTMAP +1
VSr:
	DJNZ	LP_VSr		;*****Value_Shift

	EX	AF,AF'		;A'#=Start_bit
	LD	A,(PMSUB)
	LD	C,A
	LD	A,E		;A#=PM
	SUB	C		;A#=PM-PMSUB=PP
	DEC	A		;A#=PP-1
	PUSH	HL
	PUSH	AF

	ADD	A,DP_H		;A#=PP-1+DP_H
	LD	E,A
	LD	H,A		;H#=今色の位置
	EXX
	LD	A,C		;A#=前色	
	EXX
	LD	L,A
	LD	L,(HL)		;L#=今色
	CALL	DPsca3		;現在色のパレットを更新

	POP	AF
	LD	B,A		;B#=PP-1
	LD	A,L		;A#=今色
	JR	Z,NextCN

	LD	H,E		;H#=PP-1+DP_H
	LD	L,C		;L#=前色
LpRot2:
	DEC	H		;直前色のパレットを更新
	LD	D,(HL)
	INC	H
	LD	(HL),D
	DEC	H
	DJNZ	LpRot2

	LD	(HL),A
NextCN:
	POP	HL		;HL#=PLTMAP
	EXX			;HL#=CN
	LD	(HL),A		;CN(i)=今色
	INC	L		;CN(i++)
	LD	C,A		;C#=今色
	EX	AF,AF'		;A#=Start_bit
	DJNZ	LP_PMr

	EXX			;HL#=PLTMAP
	LD	C,L
	INC	C		;BC#=VPMAP

	POP	HL		;HL#=(VA)
	ADD	HL,BC
	LD	(VA),HL

; 色と長さで画像を展開 2001/0120
; An image is decompressed by a color and length.
;-------------------------------*
LC_BMr:
	LD	HL,LN
	LD	DE,BM
	LD	A,(Kps1)
	LD	B,A
LPKR:
	LD	C,B
	LD	B,(HL)
	DEC	H
	LD	A,(HL)		;A#=色
	INC	H
	INC	B		;B#=長+1
LPC:
	LD	(DE),A
	INC	E
	DJNZ	LPC

	INC	L
	LD	B,C
	DJNZ	LPKR

; 画像の逆座標変換 2010/0622
; Reverse-geometric transformation of image
;-------------------------------*
	LD	E,B		;DE#=BM,B#=0,C#=1
	LD	HL,X4
	LD	A,(NX)
	CP	(HL)
	LD	HL,WTBL
	JR	NZ,NoScan

	LD	A,(SD)		;A#=0-7
	ADD	A,H
	LD	H,A		;変換画像(変換行列)＝元の画像
LPDESC:
	LD	A,(DE)		;A#=BM(L#)
	LD	E,(HL)		;E#=WZR(L#)
	DEC	D		;DE#=BLTWRK
	LD	(DE),A		;BLTWRK(WZR(L#))=BM(L#)
	INC	D		;DE#=BM
	INC	L
	LD	E,L
	DJNZ	LPDESC

	RET
NoScan:
	DEC	H		;HL#=BM
	DEC	D		;DE#=BLTWRK
	LD	C,B
	INC	B		;BC#=256
	LDIR
	RET

; ページ1のスロットを切り換える
; The slot on page 1 is switched. 
;-------------------------------*
ROMSLT:
	LD	A,(EXPTBL)	;スロットをBASIC ROMにする
	JR	CHGSLT
RAMSLT:
	LD	A,(RAMAD1)	;スロットをRAMにする
CHGSLT:
	LD	H,40h		;PAGE1の上位アドレス
	JP	ENASLT		;PAGE1のスロット切り換え
End: