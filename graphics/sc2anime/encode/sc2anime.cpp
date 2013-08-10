// -------------------------------------------------------------
//	TITLE	:	MSX screen2 anime
//	INPUT	:	(C)2001	t.hara (HRA!)
//	HISTORY	:	2001/06/13	初版
// -------------------------------------------------------------

// =============================================================
//	インクルード

#include <stdio.h>
#include <stdlib.h>
#include "anicnv.h"

// =============================================================
//	設定

//	メッセージ
#define	_TITLE		"sc2anime v0.10625 (C)2001 HRA!\n"
#define	_USAGE		"Usage>SC2ANIME <save name> [diff]\n"		\
					"\tdiff = 1~768\n"
#define	_ERROR		"convert error.\n"
#define	_COMPLETE	"completed.\n"

//	デフォルトの diff（大きくすると再生画質向上、小さくすると再生速度向上）
#define	_DIFFLEVEL	150

// =============================================================
//	関数定義

// -------------------------------------------------------------
//	1.	日本語名
//		起動関数
//	2.	引数
//		argc	...	(I)	コマンドライン引数の数
//		argv	...	(I)	コマンドライン引数
//	3.	返値
//		0
//	4.	備考
//		なし
// -------------------------------------------------------------
int main( int argc, char* argv[] ) {
	int	diff;

	//	タイトル表示
	printf( _TITLE );

	//	引数不足チェック
	if( argc < 2 ) {
		printf( _USAGE );
		return 0;
	}
	if( argc > 2 ) {
		diff = atoi( argv[2] );
	} else {
		diff = _DIFFLEVEL;
	}

	//	変換処理
	if( ac_sc2anime( argv[1], diff ) ) {
		printf( _COMPLETE );
	} else {
		printf( _ERROR );
	}
	return 0;
}
