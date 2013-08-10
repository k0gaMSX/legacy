// -------------------------------------------------------------
//	TITLE	:	MSX screen2 anime フレーム・フレーム間処理
//	INPUT	:	(C)2001	t.hara (HRA!)
//	HISTORY	:	2001/06/13	初版
// -------------------------------------------------------------

// =============================================================
//	インクルード

#include <memory.h>

#include "anicnv.h"

// =============================================================
//	型

//	バイト型
typedef unsigned char BYTE;

//	パレット型
typedef struct tPAL {
	int	red;
	int	green;
	int	blue;
} PAL;

//	順位表型（単方向リスト）
typedef struct tDISTANCE {
	tDISTANCE		*next;
	unsigned int	dist;
	int				parts;
} DISTANCE;

// =============================================================
//	設定

//	インライン展開
#ifdef	__cplusplus
#define	INLINE	inline
#else
#define	INLINE	static	//	コンパイラ独自拡張のインライン展開がある場合は static と置き換えてください
#endif

//	SCREEN2 VRAM サイズ
#define	_VRAMSIZE		0x4000

//	キャラクタ数
#define	_PARTS			768

//	パターンジェネレータテーブルのアドレス
#define	_PATGENE		0x0000

//	パターンネームテーブルのアドレス
#define	_PATNAME		0x1800

//	パレットテーブルのアドレス
#define	_PALTABLE		0x1B80

//	カラーテーブルのアドレス
#define	_PATCOL			0x2000

//	データ
#define	DAT_MOVE128		128
#define	DAT_CHAR		129		//	続く１６バイトがパーツデータ
#define	DAT_VWAIT		130
#define	DAT_EXIT		131

//	入力ファイル名
#define	_LOADDAT	"F%07X.SC2"

// =============================================================
//	プロトタイプ

static int _bload( BYTE *pvram, const char *fname );
static int _save_header( FILE *fp, BYTE *pvram );
static int _difference( FILE *fp, BYTE *pframe, const BYTE *pnext, PAL *pal, int diff, int size );
static unsigned int _distance_parts( const BYTE *pp1, const BYTE *pc1, const BYTE *pp2, const BYTE *pc2, const PAL *pal );
INLINE unsigned int _distance_line( BYTE p1, BYTE c1, BYTE p2, BYTE c2, const PAL *pal );
INLINE unsigned int _pow2( int n );
static void _get_palette( PAL *pal, const BYTE *pvram );

// =============================================================
//	関数定義

// -------------------------------------------------------------
//	1.	日本語名
//		変換処理
//	2.	引数
//		fname	...	(I)	保存ファイル名
//	3.	返値
//		0	...	失敗
//		n	...	変換したフレーム数
//	4.	備考
//		なし
// -------------------------------------------------------------
int ac_sc2anime( const char *fname, int diff ) {
	BYTE	fbuf[ _VRAMSIZE ];								//	フレームバッファ
	BYTE	nbuf[ _VRAMSIZE ];								//	次フレームバッファ
	FILE	*fp;
	char	sname[ 260 ];
	int		n;
	int		size = 0;
	PAL		pal[16];

	//	補正
	if( diff > _PARTS ) diff = _PARTS;
	if( diff < 1 ) diff = 1;
	printf( "Update parts par frame = %d\n", diff );

	//	ファイルを開く
	fp = fopen( fname, "wb" );
	if( fp == NULL ) goto _error;

	//	第１フレームの読み込み
	n = 0;
	sprintf( sname, _LOADDAT, n );
	if( !_bload( fbuf, sname ) ) goto _error;
	++n;

	//	ヘッダ・第１フレームの出力
	_save_header( fp, fbuf );
	_get_palette( pal, fbuf );

	//	第２フレーム以降
	for( ;; ) {
		//	フレームの読み込み
		sprintf( sname, _LOADDAT, n );
		if( !_bload( nbuf, sname ) ) break;
		++n;
		printf( "%d\r", n );
		//	差分の作成とフレームバッファの更新
		size = _difference( fp, fbuf, nbuf, pal, diff, size );
	}

	//	終了記号
	size = 0x4000 - (size % 0x4000);
	if( size == 0 ) size = 0x4000;
	memset( fbuf, DAT_EXIT, size );
	fwrite( fbuf, size, 1, fp );

	//	成功
	fclose( fp );
	return n;

	//	エラー終了
_error:
	if( fp != NULL ) fclose( fp );
	return 0;
}

// -------------------------------------------------------------
//	1.	日本語名
//		BSAVE形式の SCREEN2 画像データを読み込む
//	2.	引数
//		pvram	...	(I)	ＶＲＡＭイメージアドレス
//		fname	...	(I)	ファイル名
//	3.	返値
//		0	...	失敗
//		1	...	成功
//	4.	備考
//		オフセット 0000 からのデータのみ対応
// -------------------------------------------------------------
static int _bload( BYTE *pvram, const char *fname ) {
	FILE	*fp;

	//	ファイルを開く
	fp = fopen( fname, "rb" );
	if( fp == NULL ) return 0;

	//	読み込む
	fread( pvram, 7, 1, fp );
	fread( pvram, 1, _VRAMSIZE, fp );
	fclose( fp );

	return 1;
}

// -------------------------------------------------------------
//	1.	日本語名
//		AS2形式のファイルヘッダを出力する
//	2.	引数
//		fp		...	(I)	出力先ファイルストリーム
//		pvram	...	(I)	ＶＲＡＭイメージアドレス
//	3.	返値
//		0	...	失敗
//		1	...	成功
//	4.	備考
//		なし
// -------------------------------------------------------------
static int _save_header( FILE *fp, BYTE *pvram ) {
	BYTE	head[4];

	//	ファイルヘッダの出力
	head[0] = 'A';		//	Animation
	head[1] = 'S';		//	full Screen
	head[2] = '2';		//	screen 2
	head[3]	= 0;		//	予約（ゼロにすること）

	fwrite( head, sizeof(head), 1, fp );

	//	パレットの出力
	fwrite( pvram + _PALTABLE, 32, 1, fp );

	//	第１フレームの出力
	fwrite( pvram + _PATGENE, 0x1800, 1, fp );
	fwrite( pvram + _PATCOL , 0x1800, 1, fp );

	return 1;
}

// -------------------------------------------------------------
//	1.	日本語名
//		２フレームの差分を求めて新しいフレームを作成する
//	2.	引数
//		fp		...	(I)		差分データ出力先ファイルストリーム
//		pframe	...	(I/O)	フレームバッファ
//		pnext	...	(I)		次フレーム
//		diff	...	(I)		更新パーツ最大数
//		size	...	(I)		これまでに書き込んだサイズ
//	3.	返値
//		書き込み済みサイズ
//	4.	備考
//		なし
// -------------------------------------------------------------
static int _difference( FILE *fp, BYTE *pframe, const BYTE *pnext, PAL *pal, int diff, int size ) {
	DISTANCE		distance[_PARTS];			//	遠さ表
	DISTANCE		update[_PARTS];				//	位地順
	DISTANCE		*pdis, *psearch, *ptop, *pupd, *pprev;
	int				i, d, c;
	int				cur;						//	カレントポジション
	BYTE			buf[2];

	//	クリア
	memset( distance, 0, sizeof( distance	) );
	memset( update	, 0, sizeof( update		) );

	//	遠さ表を挿入ソートで作成する
	ptop = pdis = distance;
	for( i = 0; i < _PARTS; ++i ) {
		pdis->parts	= i;
		pdis->dist	= _distance_parts(	pframe + i*8 + _PATGENE, pframe + i*8 + _PATCOL, 
										pnext  + i*8 + _PATGENE, pnext  + i*8 + _PATCOL, pal );
		if( i != 0 ) {
			//	挿入場所を求める
			pprev	= NULL;
			psearch = ptop;
			for( ;; ) {
				//	大きさを確認する
				if( (psearch->dist) <= (pdis->dist) ) {
					//	先頭が更新の場合
					if( psearch == ptop ) ptop = pdis;
					//	前挿入
					if( pprev != NULL ) pprev->next = pdis;
					pdis->next		= psearch;
					break;
				} else if( (psearch->next == NULL) ) {
					//	後追加
					psearch->next	= pdis;
					break;
				}
				//	次
				pprev	= psearch;
				psearch = psearch->next;
			}
		}
		//	次
		++pdis;
	}

	//	遠さの上位 diff 位までを parts 位置で大きい順に挿入ソートする
	pupd = pdis = update;
	for( i = 0; i < diff; ++i ) {
		*pdis		= *ptop;
		pdis->next	= NULL;
		ptop		= ptop->next;
		if( i != 0 ) {
			//	挿入場所を求める
			pprev	= NULL;
			psearch = pupd;
			for( ;; ) {
				//	大きさを確認する
				if( (psearch->parts) < (pdis->parts) ) {
					//	先頭が更新の場合
					if( psearch == pupd ) pupd = pdis;
					//	前挿入
					if( pprev != NULL ) pprev->next = pdis;
					pdis->next		= psearch;
					break;
				} else if( (psearch->next == NULL) ) {
					//	後追加
					psearch->next	= pdis;
					break;
				}
				//	次
				pprev	= psearch;
				psearch = psearch->next;
			}
		}
		//	次
		++pdis;
	}

	//	ファイルへ出力する
	pdis	= pupd;
	cur		= _PARTS-1;		//	現在位置
	for( i = 0; i < diff; ++i ) {
		//	現在位置からの移動分を取得
		d = cur - (pdis->parts);
		//	移動データを出力
		buf[0] = DAT_MOVE128;
		while( d > 127 ) {
			fwrite( buf, 1, 1, fp );	size += 1;
			d -= 128;
		}
		if( d ) {
			buf[0] = (BYTE)d;
			buf[1] = DAT_CHAR;
			fwrite( &buf, 2, 1, fp );	size += 2;
		} else {
			buf[0] = DAT_CHAR;
			fwrite( &buf, 1, 1, fp );	size += 1;
		}
		//	形状データを出力
		cur	= (pdis->parts);
		c	= (*(pnext + cur + _PATNAME) + (cur & 0x300)) * 8;
		fwrite( pnext + c + _PATGENE, 8, 1, fp );	size += 8;
		fwrite( pnext + c + _PATCOL , 8, 1, fp );	size += 8;
		//	フレームバッファを更新
		memcpy( pframe + c + _PATGENE, pnext + c + _PATGENE, 8 );
		memcpy( pframe + c + _PATCOL , pnext + c + _PATCOL , 8 );
		//	次
		pdis = pdis->next;
	}
	//	フレームの区切り目を出力
	buf[0] = DAT_VWAIT;
	fwrite( buf, 1, 1, fp );	size += 1;
	return size;
}

// -------------------------------------------------------------
//	1.	日本語名
//		２つのパーツの遠さを求める
//	2.	引数
//		pp1	...	(I)	パーツ１形状情報のアドレス
//		pc1	...	(I)	パーツ１色情報のアドレス
//		pp2	...	(I)	パーツ２形状情報のアドレス
//		pc2	...	(I)	パーツ２色情報のアドレス
//		pal	...	(I)	パレットのアドレス
//	3.	返値
//		遠さ
//	4.	備考
//		返す遠さは大小関係の比較のみを保証し、数値の絶対的な意味
//		は保証しない（必ずしも比例関係ではない）
// -------------------------------------------------------------
static unsigned int _distance_parts( const BYTE *pp1, const BYTE *pc1, const BYTE *pp2, const BYTE *pc2, const PAL *pal ) {
	unsigned int	sum;
	int				i;

	//	遠さの計算
	sum = 0;
	for( i = 0; i < 8; ++i ) {

		//	１ライン分の距離
		sum += _distance_line( *pp1, *pc1, *pp2, *pc2, pal );
		++pp1;
		++pc1;
		++pp2;
		++pc2;
	}

	return sum;
}

// -------------------------------------------------------------
//	1.	日本語名
//		２つのラインの遠さを求める
//	2.	引数
//		p1	...	(I)	パーツ１形状
//		c1	...	(I)	パーツ１色
//		p2	...	(I)	パーツ２形状
//		c2	...	(I)	パーツ２色
//		pal	...	(I)	パレットのアドレス
//	3.	返値
//		遠さ
//	4.	備考
//		返す遠さは大小関係の比較のみを保証し、数値の絶対的な意味
//		は保証しない（必ずしも比例関係ではない）
// -------------------------------------------------------------
INLINE unsigned int _distance_line( BYTE p1, BYTE c1, BYTE p2, BYTE c2, const PAL *pal ) {
	unsigned int	sum;
	int				i;
	int				col1[2], col2[2];
	const PAL		*pal1, *pal2;

	//	色
	col1[0] = c1 & 0x0F;	col1[1] = (c1 >> 4) & 0x0F;
	col2[0] = c2 & 0x0F;	col2[1] = (c2 >> 4) & 0x0F;

	//	遠さの計算
	sum = 0;
	for( i = 0; i < 8; ++i ) {

		//	パレット取得
		pal1 = &pal[ col1[ p1 & 1 ] ];
		pal2 = &pal[ col2[ p2 & 1 ] ];

		//	ピクセル間遠さ加算
		sum += _pow2( (pal1->red  ) - (pal2->red  ) )
			 + _pow2( (pal1->green) - (pal2->green) )
			 + _pow2( (pal1->blue ) - (pal2->blue ) );

		//	次
		p1 = p1 >> 1;
		p2 = p2 >> 1;
	}

	return sum;
}

// -------------------------------------------------------------
//	1.	日本語名
//		２乗を求める
//	2.	引数
//		n	...	(I)	数値
//	3.	返値
//		２乗値
//	4.	備考
//		なし
// -------------------------------------------------------------
INLINE unsigned int _pow2( int n ) {

	return( (unsigned int) (n*n) );
}

// -------------------------------------------------------------
//	1.	日本語名
//		パレットを取得する
//	2.	引数
//		pal		...	(O)	パレット格納先
//		pvram	...	(I)	フレームデータ
//	3.	返値
//		なし
//	4.	備考
//		pal は必ず 16色分 以上存在しなければならない
// -------------------------------------------------------------
static void _get_palette( PAL *pal, const BYTE *pvram ) {
	int		i;

	pvram += _PALTABLE;
	for( i = 0; i < 16; ++i ) {

		pal->red	= ((*pvram) >> 4) & 0x07;
		pal->blue	=  (*pvram)		  & 0x07; ++pvram;
		pal->green	=  (*pvram)		  & 0x07; ++pvram;
		++pal;
	}
}
