;// -------------------------------------------------------------
;	.AS2 アニメーションプレイヤー.
;								(C)	2001 t.hara (HRA!)
;								http://www.imasy.or.jp/~hra/
;	MSX2/2+/turboR
;
;	History:
;		2001/06/23	v0.00a1	製作開始.
;
;	Coment
;		TAB幅4 でご覧ください
;

;// -------------------------------------------------------------
;	定数.
;

;-	システム.
BDOS	equ	00005H	;	DOSシステムコール (BDOS).
FCB		equ	0005CH	;	コマンドラインのファイルコントロールブロック.
CALSLT	equ	0001CH	;	他のスロットにあるサブルーチンの呼び出し.
EXPTBL	equ	0FCC1H	;	拡張スロットテーブル.

;-	MSX-DOS ファンクション.
CONOUT	equ	00002H	;	コンソール１文字出力.
STROUT	equ	00009H	;	コンソール文字列出力.
SETDTA	equ	0001AH	;	DTA の設定.
FOPEN	equ	0000FH	;	ファイルオープン.
FCLOSE	equ	00010H	;	ファイルクローズ.
FREAD	equ	00027H	;	ファイルランダムリード.

;-	FCB 構造体メンバ.
DRVNO	equ	0		;	ドライブ番号 (0:デフォルト / 1:A / 2:B ... )
NAME	equ	1		;	ファイル名.
EXT		equ	9		;	ファイル拡張子.
CURBLK	equ	12		;	カレントブロック.
BLKREC	equ	15		;	レコード数[block].
RECSIZE	equ	14		;	レコードサイズ.
FSIZE	equ	16		;	ファイルサイズ.
DATE	equ	20		;	日付.
TIME	equ	22		;	時刻.
DEVICE	equ	24		;	デバイスID
DIRLOC	equ	25		;	ディレクトリ位置.
TCLUST	equ	26		;	先頭クラスタ.
LCLUST	equ	28		;	最終アクセスクラスタ.
LPOINT	equ	30		;	最終クラスタ内最終アクセスポイントのオフセット.
CURREC	equ	32		;	カレントレコード.
RNDREC	equ	33		;	ランダムアクセスレコード.
FCBSIZE	equ	37		;	FCB 構造体サイズ.

;-	BIOS
WRTVDP	equ	00047H	;	VDP レジスタへ出力. in)C=reg# B=data
CHGMOD	equ	0005FH	;	スクリーンモード変更. in)A=screen mode
GTTRIG	equ	000D8H	;	ジョイスティックトリガ入力.

;-	VDP I/O ( not support MSX1+V9938 )
VPORT0	equ	098H	;	VRAMアクセスレジスタ.
VPORT1	equ	099H	;	コマンドレジスタ.
VPORT2	equ	09AH	;	パレットレジスタ.
VPORT3	equ	09BH	;	VDPレジスタ直接アクセス.

;-	screen2 VRAM マップ.
S2PAT	equ	00000H	;	パターンジェネレータテーブル.
S2NAME	equ	01800H	;	パターンネームテーブル.
S2COL	equ	02000H	;	カラーテーブル.
SONAME	equ	768		;	パターンネームテーブルのアドレス.

;	システムワークエリア.
PUTPNT	equ	0F3F8H	;	循環キー入力バッファのライトポインタ.
GETPNT	equ	0F3FAH	;	循環キー入力バッファのリードポインタ.

;	DTA
DEFDTA	equ	00080H	;	デフォルトの DTA

;	このアプリの設定.
NEWDTA	equ	08000H	;	DTA の移動先
RSIZE	equ	04000H	;	最大読み込みサイズ
HSIZE	equ	03024H	;	ファイルヘッダサイズ

DTMOVE	equ	128		;	移動データ
DTCHAR	equ	129		;	キャラクタ形状データ
DTVWAIT	equ	130		;	フレーム区切り目
DTEXIT	equ	131		;	データ終了

;// -------------------------------------------------------------
;	コードセグメント.
;
		aseg
		org		100h
START:
		jp		S1					;	MS-DOS 起動防止.
S1:
;-	SCREEN2 へ変更.
		ld		a,2
		call	SCREEN

;-	スプライト表示禁止/パレット０不透明化.
		ld		bc,02208H
		call	WRVDP

;-	DTA セット.
		ld		de,NEWDTA			;	新しい DTA アドレス.
		ld		c,SETDTA
		call	BDOS

;-	file を開く.
		ld		de,FCB
		ld		c,FOPEN
		call	BDOS				;	file オープン.
		ld		de,MEOPEN			;	ファイルが開けない.
		or		a					;	エラーチェック.
		jp		nz,EXIT

;-	アニメーション展開ルーチン.
		call	ANPLAY

;-	file を閉じる.
		ld		de,FCB
		ld		c,FCLOSE
		call	BDOS

		ld		de,MCOMPL			;	完了メッセージ

EXIT:
;-	パレットをデフォルト値にする
		ld		hl,DEFPLT
		call	SETPLT

;-	SCREEN0 へ変更.
		push	de					;	メッセージアドレスの保存
		xor		a
		call	SCREEN

;-	DTA をデフォルトへ戻す.
		ld		de,DEFDTA			;	デフォルトの DTA アドレス.
		ld		c,SETDTA
		call	BDOS

;-	キーバッファをクリアする.
		call	CLRKEY

;-	終了.
		pop		de					;	メッセージアドレスの復帰
		ld		c,STROUT
		call	BDOS
		ret							;	DOSへ戻す.

;// -------------------------------------------------------------
;	1.	名称.
;		アニメーションの表示.
;	2.	引数.
;		(FCB)	...	(I)	オープンされた FCB
;	3.	戻り値.
;		なし.
;	4.	機能.
;		(FCB) で示されるファイルを読み込みながらアニメーションを.
;		表示する。あらかじめ SCREEN2 へ変更しておくようにする.
;		VRAM の各ベースアドレスはデフォルトである必要がある.
;	5.	破壊.
;		全て.
;
ANPLAY:
;-	FCB の初期化.
		xor		a
		ld		(FCB+CURBLK),a		;	カレントブロック			= 00H
		ld		hl,1
		ld		(FCB+RECSIZE),hl	;	レコードサイズ				= 1
		ld		h,a
		ld		l,a
		ld		(FCB+CURREC),a		;	カレントレコード			= 00H
		ld		(FCB+RNDREC),hl		;	ランダムアクセスレコード	= 00000000H
		ld		(FCB+RNDREC+2),hl

;-	VRAM のパターンネームテーブルを初期化する.
		ld		hl,S2NAME+4000h		;	パターンネームテーブル.
		call	VRAMADR
		ld		bc,SONAME			;	パターンネームテーブルのサイズ.
APVINI:
		out		(VPORT0),a
		inc		a
		dec		c
		jp		nz,APVINI
		dec		b
		jp		p,APVINI

;-	ヘッダ解析.
		call	READHD				;	ヘッダの読み込み.
		ret		z					;	エラーチェック.

;-	メインループ.
		ld		hl,NEWDTA+RSIZE		;	データ読み込みインデックス.
		ld		(SAVEAD),hl
APLP1:
;	-	１フレーム分の処理.
		call	DRAWFRM
		jp		z,APLE1

;	-	フレームウェイト.
		;;;		なし.
		jp		APLP1

;-	ending
APLE1:
		ret

;// -------------------------------------------------------------
;	1.	名称.
;		ヘッダの解析.
;	2.	引数.
;		(FCB)	...	(I)	オープンされた FCB
;	3.	返値.
;		Z Flag	...	0	正常.
;				...	1	異常.
;	4.	機能.
;		ファイルのヘッダを読み込んで解析する.
;		目的のファイル無い場合はエラーを返す.
;	5.	破壊.
;		全て.
;
READHD:
;	-	ヘッダの読み込み.
		ld		de,FCB
		ld		hl,HSIZE			;	一気にまとめて読み込む.
		ld		c,FREAD
		call	BDOS
		or		a
		ret		nz					;	エラーチェック.

;	-	ヘッダのチェック.
		ld		bc,4
		ld		de,REFHED
		ld		hl,NEWDTA
		call	STRCMP
		ret		nz

;	-	パレット設定.
		call	SETPLT

;	-	1stフレーム（パタジェネ）をセット.
		ld		hl,S2PAT+4000h
		call	VRAMADR
		ld		bc,VPORT0
		ld		a,18H
		ld		hl,NEWDTA+4+32
RHLT1:
		outi						;	out (C), (HL); ++HL; --B;
		jp		nz,RHLT1
		dec		a
		jp		nz,RHLT1

;	-	1stフレーム（カラー）をセット.
		ld		hl,S2COL+4000h
		call	VRAMADR
		ld		bc,VPORT0
		ld		a,18H
		ld		hl,NEWDTA+4+32+1800h
RHLT2:
		outi
		jp		nz,RHLT2
		dec		a
		jp		nz,RHLT2

		inc		a					;	Z = 0
		ret

;// -------------------------------------------------------------
;	1.	名称.
;		１フレーム描画.
;	2.	引数.
;		(FCB)	...	(I)	オープンされた FCB
;	3.	返値.
;		Z Flag	...	0	続行.
;				...	1	データ終わり.
;	4.	機能.
;		１フレーム分の画像データを処理する.
;	5.	破壊.
;		全て.
;
DRAWFRM:
;	-	位置情報初期化.
		ld		hl,SONAME-1			;	着目パーツ位置.
		ld		(SAVEPT),hl
DFMLP1:
;	-	データ存在の確認.
		call	GETDAT
		ret		z					;	データ終わり.

;	-	オペレーションコードの入力.
		ld		hl,(SAVEAD)			;	入力.
		ld		a,(hl)
		inc		hl					;	次の位置.
		ld		(SAVEAD),hl
		cp		DTCHAR				;	if( a >= DTCHAR ) goto DFOP2
		jp		nc,DFOP2

;	-	移動オペレーション.
		ld		c,a
		xor		a					;	Cy = 0, a = 0
		ld		b,a
		ld		hl,(SAVEPT)
		sbc		hl,bc
		ld		(SAVEPT),hl
		jp		DFMLP1

;	-	キャラクタデータオペレーション.
DFOP2:
		jp		nz,DFEXIT			;	キャラクタデータオペレーションでない場合.

;		-	転送先 VRAM アドレスを計算.
		ld		hl,(SAVEPT)
		add		hl,hl				;	VAGENE = hl * 8 + S2PAT
		add		hl,hl
		add		hl,hl
		ld		(VAGENE),hl
		ld		bc,S2COL			;	VACOL  = hl + S2COL - S2PAT
		add		hl,bc
		ld		(VACOL),hl

;		-	転送元データの分離確認（境界上か否か）.
		ld		hl,(SAVEAD)
		ld		d,h					;	save HL
		ld		e,l
		ld		bc,NEWDTA+RSIZE-16	;	キャラクタデータは 16byte, きっちり収まる場合でも.
									;	Cy = 1 になるように 16 を引く.
		sbc		hl,bc				;	if( HL < BC ) goto DFFAST (※Cy = 0 になっていることを期待)
		jp		c,DFFAST
		jp		z,DFFAST

;		-	データが分割される場合（たまに発生）.
		push	hl
		ld		a,16				;	DTA に残ってるデータ数を求める.
		sub		l
		ld		c,a					;	bc = 16 - (SAVEAD - (NEWDTA+RSIZE-16))
		ld		b,0
		ld		hl,BUFDAT			;	de = BUFDAT
		ex		de,hl				;	hl = SAVEAD
		jp		z,DFBSKP1			;	if( bc == 0 ) goto DFSKP1
		ldir						;	転送.
DFBSKP1:
;			-	ディスクから読み込み残りの半端も BUFDAT へ.
		push	de
		call	RDDAT				;	hl = NEWDTA
		pop		de					;	de = BUFDAT + (16 - (SAVEAD - (NEWDTA+RSIZE-16)) )
		pop		bc					;	bc = SAVEAD - (NEWDTA+RSIZE-16)
		ret		z					;	データ終わり.
		ldir						;	転送.
		ld		(SAVEAD),hl

		ld		de,BUFDAT			;	転送元.
		call	DFDRAW
		jp		DFMLP1

;		-	データが連続している場合.
DFFAST:
		call	DFDRAW
		ld		(SAVEAD),hl
		jp		DFMLP1

;		-	終了判定.
DFEXIT:
		cp		DTEXIT				;	データ終わりなら Z=1 にする.
		ret

;// -------------------------------------------------------------
;	1.	名称.
;		１キャラ描画.
;	2.	引数.
;		(VAGENE)	...	(I)	目的のキャラのパタジェネアドレス.
;		(VACOL)		...	(I)	目的のキャラのカラーアドレス.
;		de			...	(I)	ソースデータのアドレス.
;	3.	返値.
;		hl			...	ソースデータの次の位置.
;	4.	機能.
;		１キャラ分のデータを RAM から VRAM へ転送する.
;	5.	破壊.
;		全て.
;
DFDRAW:
;		-	転送先アドレスセット（パタジェネ）.
		ld		hl,(VAGENE)
		ld		a,h
		or		40h
		ld		c,VPORT1
		out		(c),l
		out		(c),a
;		-	出力.
		ex		de,hl
		ld		bc,0800h+VPORT0		;	8byte
		otir
;		-	転送先アドレスセット（カラー）.
		ld		de,(VACOL)
		ld		a,d
		or		40h
		ld		c,VPORT1
		out		(c),e
		out		(c),a
;		-	出力.
		ld		bc,0800h+VPORT0		;	8byte
		otir
		ret

;// -------------------------------------------------------------
;	1.	名称.
;		データの存在確認.
;	2.	引数.
;		(FCB)	...	(I)	オープンされた FCB
;	3.	返値.
;		Z Flag	...	0	続行.
;				...	1	データ終わり.
;	4.	機能.
;		１フレーム分の画像データを処理する.
;	5.	破壊.
;		全て.
;
GETDAT:
;	-	データの存在を確認する.
		ld		hl,(SAVEAD)
		ld		de,NEWDTA+RSIZE
		xor		a
		sbc		hl,de
		jp		nc,RDDAT
		inc		a					;	Z = 0
		ret

;// -------------------------------------------------------------
;	1.	名称.
;		ディスクからデータを読む.
;	2.	引数.
;		(FCB)	...	(I)	オープンされた FCB
;	3.	返値.
;		Z Flag	...	0	続行.
;				...	1	データ終わり.
;		HL		...	NEWDTA
;	4.	機能.
;		１フレーム分の画像データを処理する.
;	5.	破壊.
;		全て.
;
RDDAT:
		ld		de,FCB
		ld		hl,RSIZE			;	一気にまとめて読み込む.
		ld		c,FREAD
		call	BDOS
		dec		a					;	エラーなら Z = 1 になるようにする.
		ld		hl,NEWDTA
		ld		(SAVEAD),hl
		ret

;// -------------------------------------------------------------
;	サブルーチン.
;

;// -------------------------------------------------------------
;	1.	名称.
;		文字列の比較.
;	2.	引数.
;		bc		...	(I)	文字数.
;		de		...	(I)	比較対照文字列のアドレス１.
;		hl		...	(I)	比較対照文字列のアドレス２.
;	3.	返値.
;		Z Flag	...	1	一致.
;				...	0	不一致.
;		HL		...		比較を終えた場所（一致の場合は文字列の次）.
;	4.	機能.
;		なし.
;	5.	破壊.
;		全て.
;
STRCMP:
		ld		a,(de)
		inc		de
		cpi
		jp		po,SCEXIT
		jr		z,STRCMP
SCEXIT:
		ret

;// -------------------------------------------------------------
;	1.	名称.
;		パレット設定
;	2.	引数.
;		hl		...	(I)	パレットデータのアドレス.
;	3.	返値.
;		hl		...	パレットデータの次.
;	4.	機能.
;		なし.
;	5.	破壊.
;		全て.
;
SETPLT:
;	-	パレットレジスタ R#16 を設定.
		push	hl
		ld		bc,0010h
		call	WRVDP
		pop		hl
;	-	16パレット分出力.
		ld		bc,2000h+VPORT2
		otir
		ret

;// -------------------------------------------------------------
;	1.	名称.
;		メモリセット.
;	2.	引数.
;		A	...	メモリにセットする値.
;		BC	...	メモリのサイズ.
;		HL	...	セット対象の先頭アドレス.
;	3.	返値.
;		なし.
;	4.	機能.
;		[HL+0] ... [HL+BC-1] のメモリを A の値で埋め尽くす.
;	5.	破壊.
;		AF, BC, HL
;
MEMSET:
		ld		(hl),a
		inc		hl
		dec		c
		jp		nz,MEMSET
		dec		b
		jp		p,MEMSET
		ret

;// -------------------------------------------------------------
;	1.	名称.
;		VRAMアドレスの設定.
;	2.	引数.
;		HL	...	セットしたい VRAMアドレス ( 0000H~3FFFH )
;	3.	返値.
;		なし
;	4.	機能.
;		VDP の VRAMアクセス用アドレスレジスタに値をセットする.
;		HL bit6 ... 0: read / 1: write
;	5.	破壊.
;		C
;
VRAMADR:
		ld		c,VPORT1
		out		(c),l
		out		(c),h
		ret

;// -------------------------------------------------------------
;	1.	名称.
;		スクリーンモードの設定（低速）.
;	2.	引数.
;		A	...	スクリーンモード（MSX-BASIC互換）.
;	3.	返値.
;		なし.
;	4.	機能.
;		スクリーンモードを変更する.
;	5.	破壊.
;		すべて.
;
SCREEN:
		push	af					;	引数の保存.
		ld		a,(EXPTBL)			;	MAIN-ROM スロット番号取得.
		push	af
		pop		iy					;	iy 上位 8bit がスロット番号になる.
		ld		ix,CHGMOD			;	BIOS の該当エントリ.
		pop		af					;	引数の復帰.
		call	CALSLT				;	インタースロットコール.
		ret

;// -------------------------------------------------------------
;	1.	名称.
;		VDP レジスタ書き込み（低速）.
;	2.	引数.
;		C	...	レジスタ番号 ( 0-23, 32-46 )
;		B	...	設定値.
;	3.	返値.
;		なし.
;	4.	機能.
;		VDP の指定レジスタに指定の値を書き込む.
;	5.	破壊.
;		af, bc, ix, iy
;
WRVDP:
		ld		a,(EXPTBL)
		push	af
		pop		iy
		ld		ix,WRTVDP
		call	CALSLT
		ret

;// -------------------------------------------------------------
;	1.	名称.
;		キーバッファクリア.
;	2.	引数.
;		なし.
;	3.	返値.
;		なし.
;	4.	機能.
;		循環バッファであるキーバッファの読み書きポインタを同じにする.
;	5.	破壊.
;		なし.
;
CLRKEY:
		push	hl
		ld		hl,(PUTPNT)
		ld		(GETPNT),hl
		pop		hl
		ret

;// -------------------------------------------------------------
;	データ

;-	メッセージ.
MCOMPL:	db		'Complete.',13,10,'$'
MEOPEN:	db		'ERR: Cannot open file.'
MCRLF:	db		13,10,'$'

;-	変数
SAVEAD:	dw		0					;	読み込みポインタ.

REFHED:	db		'AS2',0				;	ファイルヘッダ（4byte）

VAGENE:	dw		0
VACOL:	dw		0
SAVEPT:	dw		0
BUFDAT:	ds		16					;	一時バッファ.

DEFPLT:	dw		000h,000h,611h,733h	;	デフォルトのパレット値
		dw		117h,327h,151h,627h
		dw		171h,373h,661h,664h
		dw		411h,265h,555h,777h
	end
