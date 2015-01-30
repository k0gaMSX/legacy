;************************************************
; 可逆画像圧縮フォーマット BARGAIN 14.2 技術解説
;                    ～ また旅支度 (C)2011 KATSU
;************************************************

; バーゲン圧縮の特長
;￣￣￣￣￣￣￣￣￣￣
; LZ法を遥かに凌ぐ圧縮力と高速処理を両立した画像圧縮法です。
; アニメ調から自然画までありとあらゆる画像に対応しています。
; ロジカルオペレーション、インターレース表示、暗号化も装備。


; 画像をタイル化して走査する
;￣￣￣￣￣￣￣￣￣￣￣￣￣￣
; 画像をタイル状(分割画像)に分割して走査していきます。
; 画像の両端で折り返すことでタイルのつながりを良くしています。

; ┏━┯━┯━┯━┯━━画像━━━━━━━━━━┓ 分割画像サイズ
; ┃①  ②  ③  ‥──────────────┐┃ (SC8～12) 16x16ドット
; ┠─┴─┴─┴─┴                          │┃ (SC5,SC7) 32x16ドット
; ┃┌────────────────────┘┃ (  SC6  ) 64x16ドット
; ┃│                  ┏分割画像              ┃
; ┃└────過去探索←┨  ┠→走査            ┃ 総タイル数    224枚
; ┃                    ┗━┛                  ┃ 過去探索数 24,976枚

; タイルが一つ進む毎に過去にさかのぼって分割画像と同じタイルを探します。
; a)タイルランレングスは同じタイルが連続する個数で符号化します。
; b)タイルインデックスは過去のタイルの参照番号で符号化します。
; c)なければ参照番号(①②③‥)を登録して分割画像内の画素を連長変換します。


; 分割画像内の画素を連長変換する
;￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣
; 分割画像内を4系統の画像に最適化された8種類の走査法で色の変化数を比較します。
; 分割画像内で折り返すことで画素のつながりを良くしています。
; 色の変化数が最少になる走査法で連長変換して色と長さを符号化します。

;            横             左45            縦(*)           右45
;     ┏━━━━━━┓┏━━━━━━┓┏━━━━━━┓┏━━━━━━┓
;     ┃0 1 2 ‥ E F┃┃0 1 5 6   ／┃┃F ┐┌┐┌┐┃┃＼    ‥FDFF┃
;     ┃┌────┘┃┃2 4 7   ／  ┃┃E │││││┃┃  ＼      FE┃
;     ┃└────┐┃┃3 8   ／    ┃┃: │││││┃┃6   ＼      ┃
;   ┌┨┌────┘┠┨9   ／    ：┠┨2 │││││┠┨5 7   ＼    ┠┐
;   │┃└────┐┃┃  ／      FD┃┃1 ││││↓┃┃1 4 8   ＼  ┃│
;   │┃FF←───┘┃┃／      FEFF┃┃0 └┘└┘FF┃┃0 2 3 9   ＼┃│
; 通│┗━━━━━━┛┗━━━━━━┛┗━━━━━━┛┗━━━━━━┛│
; 常┤      左27            左63            右63            右27      │
;   │┏━━━━━━┓┏━━━━━━┓┏━━━━━━┓┏━━━━━━┓│
;   │┃0 1 2 5 6 B ┃┃0 3 8 E    /┃┃B    │   FF┃┃＼＿    ‥FF┃│
;   │┃3 4 7 A C   ┃┃1 4 9 F   / ┃┃6 C   ＼  ：┃┃    ＼＿    ┃│Ｍ
;   └┨8 9 D     ＿┠┨2 7 D    /  ┠┨5 A    │   ┠┨E F     ＼＿┃├ｉ
;     ┃E F   ＿／  ┃┃5 A     /   ┃┃2 7 D   ＼  ┃┃8 9 D       ┃│ｘ
;     ┃  ＿／      ┃┃6 C    /  ：┃┃1 4 9 F  │ ┃┃3 4 7 A C   ┃│
;     ┃／      ‥FF┃┃B     /   FF┃┃0 3 8 E   ＼┃┃0 1 2 5 6 B ┃│
;     ┗━━━━━━┛┗━━━━━━┛┗━━━━━━┛┗━━━━━━┛│
;          横市松         左45市松         縦市松          横往復     │
;     ┏━━━━━━┓┏━━━━━━┓┏━━━━━━┓┏━━━━━━┓│
;     ┃ 0 FF  1 FE`┃┃0 FF1 FA  ／┃┃ `  `  `┌┐┃┃ 0  1  2‥ F┃│
;     ┃F0  F F1  E`┃┃FE2 FB  ／  ┃┃     ： ││┃┃FF←───│┃│
;     ┃10 EF 11 EE`┠┨3 FC  ／    ┠┨FE  E EE││┠┨┌────┘┠┘
;     ┃     ：     ┃┃FD  ／      ┃┃ 1 F1 11│↑┃┃     ：     ┃
;     ┃‥────┐┃┃  ／      復┃┃FF  F EF│往┃┃└────┐┃
;     ┃往復─→─┘┃┃／      往  ┃┃ 0 F0 10：復┃┃└往復──┘┃
;     ┗━━━━━━┛┗━━━━━━┛┗━━━━━━┛┗━━━━━━┛
;          横引返         横ディザ         縦往復        縦ハニカム
;     ┏━━━━━━┓┏━━━━━━┓┏━━━━━━┓┏━━━━━━┓
;     ┃0 F 1 E ‥ 8┃┃ 0 80  1 81`┃┃F ─┐┐┌┐┃┃ `  `  `┌┐┃
;     ┃ /          ┃┃FF 7F FE 7E`┃┃E │││││┃┃     ： ││┃
;     ┃0 F 1 E ‥ 8┃┃ F 90  E 8F`┃┃: │││││┃┃7E FE  E│↑┃
;   ┌┨     ：     ┠┨     ：     ┠┨2 ││││往┠┨ 1 81 F1│二┃
;   │┃→────←┃┃‥────┐┃┃1 ↓│││復┃┃7F FF  F│往┃
;   │┃→FF←─引返┃┃二往復─→┘┃┃0 FF└─┘┘┃┃ 0 80 F0：復┃
; デ│┗━━━━━━┛┗━━━━━━┛┗━━━━━━┛┗━━━━━━┛
; ィ┤     横市松         左45市松        縦市松(*)       右45市松
; ザ│┏━━━━━━┓┏━━━━━━┓┏━━━━━━┓┏━━━━━━┓
;   │┃ 0 FF  1 FE`┃┃0 FF1 FA  ／┃┃ `  `  `┌┐┃┃＼      往  ┃
;   │┃F0  F F1  E`┃┃FE2 FB  ／  ┃┃     ： ││┃┃  ＼      復┃
;   └┨10 EF 11 EE`┠┨3 FC  ／    ┠┨FE  E EE││┠┨FA  ＼      ┃
;     ┃     ：     ┃┃FD  ／      ┃┃ 1 F1 11│↑┃┃1 FB  ＼    ┃
;     ┃‥────┐┃┃  ／      復┃┃FF  F EF│往┃┃FF2 FC  ＼  ┃
;     ┃往復─→─┘┃┃／      往  ┃┃ 0 F0 10：復┃┃0 FE3 FD  ＼┃
;     ┗━━━━━━┛┗━━━━━━┛┗━━━━━━┛┗━━━━━━┛
;        横引返YJK         横YJK         縦引返YJK         縦YJK
;     ┏━━━━━━┓┏━━━━━━┓┏━━━━━━┓┏━━━━━━┓
;     ┃0 8 7 F 1‥C┃┃0 80 7F FF 1┃┃┌四往復→‥┃┃F ┐┌┌─┐┃
;     ┃      ↓    ┃┃┌────┘┃┃     ：     ┃┃E │││││┃
;     ┃F 7 8 0 E‥3┃┃└────┐┃┃3E BE 7E FE`┃┃: ││││二┃
;   ┌┨     ：     ┠┨┌────┘┠┨ 1 81 41 C1`┠┨2 ││││往┃
;   │┃└→─┌─←┃┃└─‥──┐┃┃3F BF 7F FF`┃┃1 │↓││復┃
;   │┃FF←往復引返┃┃二往復─→┘┃┃ 0 80 40 C0`┃┃0 └FF┘└┘┃
; Ｙ│┗━━━━━━┛┗━━━━━━┛┗━━━━━━┛┗━━━━━━┛
; Ｊ┤  横引折返YJK     縦引折返YJK         縦(*)      縦引往復折返YJK
; Ｋ│┏━━━━━━┓┏━━━━━━┓┏━━━━━━┓┏━━━━━━┓
;   │┃ 0 80 7F←二┃┃ 0 80 7F 9F`┃┃0 ┌┐┌┐FF┃┃ 0 80 7F FF`┃
;   │┃3F 8F 40→往┃┃3F 81 40 9E`┃┃1 ││││↑┃┃3F 81 40 FE`┃
;   └┨ 7 90 78→復┠┨ 1 82 7E 9D`┠┨2 │││││┠┨ 1 82 7E FD`┃
;     ┃38 9F 47←↓┃┃3E 83 41 9C`┃┃: │││││┃┃3E 83 41 FC`┃
;     ┃     ：     ┃┃     ：     ┃┃E │││││┃┃     ：     ┃
;     ┃20 FF← ‥  ┃┃└─二往復→┃┃F ┘└┘└┘┃┃└─三往復→┃
;     ┗━━━━━━┛┗━━━━━━┛┗━━━━━━┛┗━━━━━━┛
;             (*)画面を左方向にタイル走査するときにマトリックスも反転

; ┌┐┌┐┌┐┌┐┌┐┌┐
; ││││││││││││ →右タイル走査時
; │└┘↓│└┘↓│└┘↓

; ┌┐┌┐┌┐┌┐┌┐┌┐
; ││││││││││││ ←左タイル走査時
; ↓└┘│↓└┘│↓└┘│   縦マトリックスを反転して画素のつながりを良くする


;<8種類のマトリックスの優先順位>

; ノンインターレース画像   インターレース画像
;         降順                     昇順
;  ┌┐8┌┐7┌┐6┌┐5     ┌┐1┌┐2┌┐3┌┐4
;  └┘ └┘ └┘ └┘      └┘ └┘ └┘ └┘
;  ┌┐4┌┐3┌┐2┌┐1     ┌┐5┌┐6┌┐7┌┐8
;  └┘ └┘ └┘ └┘      └┘ └┘ └┘ └┘
; ※インターレースモードをOFFにするとどちらも昇順になります。


;<YJKマトリックス変換>

; YJK画素の下位3bitにある色相成分(KL,KH,JL,JH)の配列に着目します。
;     ┌─縦折返し──┐
;   ┏┿┯━┯━┯━┯↓┯━━┓ 同じ色相を縦・横方向に全て走査し終えたら
; 横→KL─横折返し─→KL─‥┐┃ 次の色相に移ります。各色相[64要素]
; ┌╂KL│KH│JL│JH│KL←‥┘┃
; └→KL│KH│JL│JH│KL─‥┐┃ KL[*] → JL[*] → KH[*] → JH[*]
; ┌╂：│：│：│：│：←‥┘┃
; └→KL│KH│JL│JH│KL→‥┐┃
; 横╂KL│KH│JL│JH│KL←‥┘┃
;   ┗↑┷━┷━┷━┷┿┷↑━┛
;     縦              └縦┘


; 色を符号化する
;￣￣￣￣￣￣￣￣
;<色のMTF変換>

; 連長変換した色成分を動的パレット上の順位を表すMTF※係数に変換します。
; 動的パレットは直前の色別に256本用意されたそれぞれに56色記憶しており、
; 直前色のパレットと現在色のパレットを双方向で更新していきます。(簡易PPM※)
;			※Move To Front ※Prediction by Partial Matching
; 例として色列{C,A,T,A}をMTF係数{0,3,2,1}に変換する様子を図解します。
; 実際の動的パレットは様々な初期状態にありますが、ここでは解り易くするために
; 全てのパレットで[‥,G,A,T]だったとします。

;   動的パレット[56]x256
;  ┌─┬─┬─┬─┬─┐  パレット[0]から<C>を探す。
;┌┤‥  ‥  G   A   T │                       ┌─┐
;│└56┴─┴3 ┴2 ┴1 ┘  <C>がない。          │0 │MTF係数
;[0]            shift┌──┘                   └↑┘
;│┌←┬←┬←┬←┬↓┐  先頭に追加する。
;├┤‥│G │A │T │C │
;│└─┴─┴─┴─┴─┘  パレット[C]に切り替える。
;└───→ PPM shift┐
;  ┌←┬←┬←┬←┬↓┐  <0>を先頭に追加して<A>を探す。
;┌┤‥│G │A │T │0 │                       ┌─┬─┐
;│└─┴─┴3 ┴─┴─┘  <A>が3番目にある。   │0 │3 │
;[C]         ┌rotate┐                         └─┴↑┘
;│┌─┬─┬←┬←┬↓┐  先頭に出す。
;├┤‥  G │T │0 │A │
;│└─┴─┴─┴─┴─┘  パレット[A]に切り替える。
;└───→ PPM shift┐
;  ┌←┬←┬←┬←┬↓┐  <C>を先頭に追加して<T>を探す。
;┌┤‥│G │A │T │C │                       ┌─┬─┬─┐
;│└─┴─┴─┴2 ┴─┘  <T>が2番目にある。   │0 │3 │2 │
;[A]       rotate┌─┐                         └─┴─┴↑┘
;│┌─┬─┬─┬←┬↓┐  先頭に出す。
;├┤‥  G   A │C │T │
;│└─┴─┴─┴─┴─┘  パレット[T]に切り替える。
;└─→PPM rotate┌─┐
;  ┌─┬─┬─┬←┬↓┐  <A>を先頭に出して<A>を探す。
;┌┤‥  ‥  G │T │A │                       ┌─┬─┬─┬─┐
;│└─┴─┴─┴─┴1 ┘  <A>が1番目にある。   │0 │3 │2 │1 │
;[T](簡易PPMの予測が的中)                       └─┴─┴─┴↑┘
;│┌─┬─┬─┬─┬─┐  先頭なのでそのままにする。
;└┤‥  ‥  G   T   A │
;  └─┴─┴─┴─┴─┘  パレット[A]に切り替える。

; この動的パレットは順列暗号の鍵ストリームとしても機能します。(最大鍵長114,688bit)
; 画像の色数と暗号強度(理論値※)の関係　※色の出現頻度には偏りがあるので実効値は相当低い
; [ 色数=C ]-+-------[ 鍵長 ]------------+----------(256P56)^C=[ 鍵の総数 ]-------------
; [ 1～ 56色]  C^2*8=[     8～ 25,088bit]    (256!/(256-C)!)^C=[ 256      ～1.11e+7394 ]
; [57～256色] C*56*8=[25,536～114,688bit]   (256!/(256-56)!)^C=[1.20e+7526～2.22e+33801]
;           推定される実効値(C>56の場合)→(256!/(256-C/10)!)^C=[1.36e+781 ～1.54e+15641]

;<動的パレット(=順列暗号鍵)の初期値>
; DYNPLT[256,56]=14KB        (0,0)=255 <SC5-12>共通

; <SC5-7>   0 0 x x x x x x  (0,1-55)
;                `_/_/_/_/      │
;               _/_/_/_/        │
;             _/_/_/_/`         │
;            / / / /  `､`､      ↓
;           P P P P 0 0 P P  Palette配列
;    [ 0]                  [255]│
;[ 0]255,  0,  1,‥,252,253,254 │
;     ┌────────────┘
;[ 1] 16, 17, 18,‥, 13, 14, 15
;[ 2] 32, 33, 34,‥, 29, 30, 31
;[ :]  :         ‥           :
;[53] 83, 84, 85,‥, 80, 81, 82
;[54] 99,100,101,‥, 96, 97, 98
;[55]115,116,117,‥,112,113,114

; <SC8>     0 0 x x x x x x  (0,1-55)
;              / / / / /  |     │
;             / / / / /   |     │
;            / / /  | |   |     ↓
;           G G G 0 R R 0 B  RGB配列
;    [ 0]                  [255]│
;[ 0]255,  0,  1,‥,252,253,254 │
;     ┌────────────┘
;[ 1]  1,  2,  3,‥,254,255,  0
;[ 2]  4,  5,  6,‥,  1,  2,  3
;[ :]  :         ‥           :
;[53]201,202,203,‥,198,199,200
;[54]204,205,206,‥,201,202,203
;[55]205,206,207,‥,202,203,204

; <SC10-12> 0 0 x x x x x x  (0,1-55)
;              / / / / /  |     │
;             / / / / /   |     │
;            / / / / /    |     ↓
;           Y Y Y Y Y 0 0 J  YJK配列
;    [ 0]                  [255]│
;[ 0]255,  0,  1,‥,252,253,254 │
;     ┌────────────┘
;[ 1]  1,  2,  3,‥,254,255,  0
;[ 2]  8,  9, 10,‥,  5,  6,  7
;[ :]  :         ‥           :
;[53]209,210,211,‥,206,207,208
;[54]216,217,218,‥,213,214,215
;[55]217,218,219,‥,214,215,216

;<共通鍵暗号>
; カレントドライブにある共通鍵"*.KEY"で暗号化・復号化を行います。
; 64ﾊﾞｲﾄの乱数列で動的パレットを512回掻き混ぜて色成分を暗号化しています。

;<色の符号化>

; 変換されたMTF係数列を7種類のパレット符号Pγ0～Pγ6で符号量が最少になるもので符号化します。
; 上の例では色列{C,A,T,A}=32bitが、Pγ0符号{000<C>0110101}=18bitに圧縮されます。

;    色列             <C>  <A>  <T>  <A>  32bit
;     ↓
; MTF係数列           <0>  <3>  <2>  <1>  32bit
;     ↓
; Pγ符号 表現力┌─── 符 号 化───┐符号量
;    Pγ0     7    000<C>  011  010    1  18bit←符号量が最少
;    Pγ1    14    000<C> 0100   11   10  19bit
;    Pγ2    28    000<C>  110  101  100  20bit
;    Pγ3    56    000<C> 1010 1001 1000  23bit
;    Pγ4    31  00000<C>  011  010    1  20bit
;    Pγ5    62  00000<C> 0100   11   10  21bit
;    Pγ6    30   0000<C> 0100   11   10  20bit

; ┌──── Pγ符号変換式────┐
; │MTF係数 + 補足数 =パレット符号│
; └───────────────┘

;    0         =  000[新色] (Pγ0～3共通)
;    1               1
;    2～3  + 0 =    01x     <Pγ0>
;    4～7          001xx

;    1～2            1x
;    3～6  + 1 =    01xx    <Pγ1>
;    7～14         001xxx

;    1～4            1xx
;    5～12 + 3 =    01xxx   <Pγ2>
;   13～28         001xxxx

;    1～8            1xxx
;    9～24 + 7 =    01xxxx  <Pγ3>
;   25～56         001xxxxx

;    0         =00000[新色] (Pγ4～5共通)
;    1               1
;    2～3  + 0 =    01x     <Pγ4>
;    4～7          001xx
;    8～15        0001xxx
;   16～31       00001xxxx

;    1～2            1x
;    3～6  + 1 =    01xx    <Pγ5>
;    7～14         001xxx
;   15～30        0001xxxx
;   31～62*      00001xxxxx (*57～62はダミー)

;    0         = 0000[新色]
;    1～2            1x
;    3～6  + 1 =    01xx    <Pγ6>
;    7～14         001xxx
;   15～30        0001xxxx


; 長さを符号化する
;￣￣￣￣￣￣￣￣￣
; 連長変換した長さ成分を<γ><α><β>符号のうちで最少になるもので符号化します。

;    長さ        <γ符号>
;    1               1
;    2～3           01x
;    4～7          001xx
;    8～15        0001xxx
;   16～31       00001xxxx
;   32～63      000001xxxxx
;   64～127    0000001xxxxxx
;  128～255   00000001xxxxxxx

;    長さ        <α符号>  →  <β符号>
;    1               1         α符号化した色変化bit列を色列とみなし、
;    2              01         白[11111111]以外ならbitを立ててその色を付加する。
;    3             001
;    4            0001         画像[色x256バイト]
;    5           00001         ↓長さ成分		色列
;    6          000001         α[色変化bit列x32バイト]=[色x32バイト]
;    7         0000001         ↓
;    8...     00000001...      β[白以外bit列x4バイト+白以外の色]

; 下の例では長さ列{1,2,1...1}=255byteが、β符号{<128><0><0><0><191>}=5byteに圧縮されます。

; 長さ列  <1><2><1><1>...<1><1><1>  255byte
;    ↓  ┌────符 号 化 ───┐ 符号量
; γ符号  10101111 11...11 10000000  33byte
; α符号  10111111 11...11 11111111  32byte
; β符号  10000000<0><0><0>10111111   5byte←符号量が最少
;            <128>         <191>


; 対応機種
;￣￣￣￣￣
; MSX2以降(VRAM128KB) Disk BASIC version 1.0/ 2.01


; 圧縮データのフォーマット
;￣￣￣￣￣￣￣￣￣￣￣￣￣
; VRAM Page-0 Address Data                       ┌(SC8,11,12)─→ 8     9...
;                                                │
;   0     1     2     3     4     5     6     7  │ 8...    39    40    41...
;┌──┬──┬──┬──┬──┬──┬──┬──┼──────┬──┬─────┬──┬─────
;│X1L   X1H │ Y1 │Mode│X3L   X3H │ Y3 │Ver │RGB Palette │Head│   Data   │Head│  Data ...
;└──┴──┴──┴──┴──┴──┴──┴──┴──────┴──┴─────┴──┴─────
;  └─開始位置─┘ モード └─ 大きさ ─┘ [142]  (SC5,6,7,10)
;                 ┌─┴─┐
;                  ----xxxx bit 3-0: Logical Operation Code
;                      0000 Pset *Tile Encoder 1000 TPset
;                      0001 And                1001 TAnd
;                      0010 Or                 1010 TOr
;                      0011 Xor                1011 TXor
;                      0100 Preset             1100 TPreset
;                  --xx---- bit 5-4: Encryption Mode
;                    00 Initialize Vector
;                    01 Permutaion Chipher
;                    10 Common Key Chipher
;                  xx------ bit 7-6: Matrix Mode
;                  00 Normal
;                  01 Mix
;                  10 Dither/YJK

; ┌─────Header─────┐┌───Data───┐
;    長さ ｘ   色   ｘ  走査       長さ ｘ   色
; ┌───┬────┬────┐┌───┬────┐
; │γ  00│PM0  000│横*  000││ LIVB │  Pγ0  │
; ├      ┼        ┼        ┤├───┼────┤
; │α  01│PM1  001│左*  001││  LA  │  Pγ1  │
; ├      ┼        ┼        ┤├───┼────┤
; │β  10│PM2  010│縦*  010││  LB  │  Pγ2  │
; ├      ┼        ┼        ┤├───┼────┤
; │長  11│PM3  011│右*  011││  LN  │  Pγ3  │
; └───┼        ┼        ┤└───┼────┤
;         │PM4  100│左27*100│        │  Pγ4  │
;         ├        ┼        ┤        ├────┤
;         │PM5  101│左63*101│        │  Pγ5  │
;         ├        ┼        ┤        ├────┤
;         │PM6  110│右63*110│        │  Pγ6  │
;         ├        ┼        ┤        ├────┤
;   タイル│色   111│右27*111│        │   CN   │
; ┌───┴────┼────┤        └────┘
; │%   11       110  RNLN 000│[RP]タイルランレングス
; └────────┼        ┤
;                   │INDX 001│[IP]タイルインデックス
;                   ├        ┤┌────────┐
;                   │無圧 010││     Bitmap     │
;                   ├────┤└────────┘
;                   │#    011│ * 通常/Mix/ディザ/YJK 適宜切替え
;                   │      ：│ % [長+PM6]の組み合わせを排除して利用
;                   │     111│ # 将来の拡張用
;                   └────┘


; 機械語サブルーチンの機能
;￣￣￣￣￣￣￣￣￣￣￣￣￣
; <DEF USR1=&HCE86>
;〔機能〕画像を[圧縮 / 展開]して圧縮サイズを整数変数に返します。
;〔書式〕整数変数=USR1(スクリーンモード番号+[256=圧縮 / 0=展開])
;〔設定〕圧縮範囲を指定します。
;             始点 0DE04h,X1 [0-511]
;                  0DE06h,Y1 [0-211]
;             終点 0DE00h,X2 [0-511]
;                  0DE02h,Y2 [0-211]

;        マトリックスモード DT、暗号化モード EN、ロジカルオペレーション LGを指定します。
;             DT=[0,1,2]                ' bit7-6: Matrix mode 
;             EN=[0,1,2]                ' bit5-4: Encrypt mode
;             LG=[0-4,8-12]             ' bit3-0: Logical operation code
;                                       '         *PSETのときにタイル圧縮が働きます。
;             SCREEN SM :SET PAGE ,0    ' SM;Screen mode 5-12
;             VPOKE 3,(DT+(2-DT)*(DT<2)*(SM>8))*64+EN*16+LG-(LG>4)*3
;             POKE &HDE6E,EN

; < DEF USR6=&HDCB4 >
;〔機能〕キー入力コードに応じてカーソルの位置を計算して垂直位置を数値変数に代入する。
;〔書式〕数値変数=USR8(キー入力コード)
;〔設定〕移動パラメーターをアドレス(DE6F-DE77)にセット。水平位置は(DE6F)にあります。

; <DEF USR5=&HDD1E>
;〔機能〕ドライブの1クラスタあたりの論理セクタ数を数値変数に代入する。
;〔書式〕数値変数=USR7(ドライブ番号)
;〔設定〕ドライブ番号: 0=カレントドライブ,1=A,2=B ... 8=H

; <DEF USR4=&HDD28>
;〔機能〕パレット付画像の画面外領域をゼロクリアします。
;〔書式〕数値変数=USR6(0)
;〔設定〕なし

; <DEF USR2=&HDD3D>
;〔機能〕カーソル位置にある12文字を文字変数に代入して反転表示します。
;〔書式〕文字列変数=USR2(文字列変数)
;〔設定〕あらかじめ適当な12文字を文字列変数に代入しておきます。

; <DEF USR3=&HDD99>
;〔機能〕テキスト画面の[保存 / 再生]を行います。
;〔書式〕数値変数=USR3([0=保存 / 1=再生])
;〔設定〕なし


; サンプルプログラム
;￣￣￣￣￣￣￣￣￣￣
; 100 ' Example for MSX2 BASIC
; 110 '
; 120 ' Initialization
; 130 CLEAR 200,&HCE85    'The machine language work area is secured.
; 140 DEFINT A-Z          'Set it as an integer.
; 150 DEFUSR=&HCE86       'The routine address of compression and decompression.
; 160 BLOAD "BN142.BIN"   'Loading of the machine language file.
; 170 SM=8 :SCREEN SM     'Screen mode [5-12]
; 180 DT=0                'Matrix mode [0,1,2]
; 190 EN=0                'Cipher mode [0,1,2]
; 200 LG=0                'Logical operation code [0-4,8-12]
; 210 '
; 220 ' Compression
; 230 SET PAGE 1,1        'Load an image to compress to the video page1.
; 240 BLOAD "SAMPLE.SC8",S
; 250 SET PAGE 0,0        'Setup of a dither mode and a logical operation-code.
; 260 VPOKE 3,(DT+(2-DT)*(DT<2))*64+EN*16+LG-(LG>4)*3
; 270 X1=0 :Y1=0 :X2=255 :Y2=211 :A=&HDE00   'Setup of a range and a cipher.
; 280 POKE A  ,X2 AND 255 :POKE A+1,X2 \ 256 :POKE A+2,Y2
; 290 POKE A+4,X1 AND 255 :POKE A+5,X1 \ 256 :POKE A+6,Y1 :POKE &HDE6E,EN
; 300 VA=USR(SM+256)      'An image is compressed to the video page0.
; 310 BSAVE "SAMPLE.BN8",0,VA-1,S   'Save a compressed image.
; 320 '
; 330 ' Decompression
; 340 SET PAGE 0,1 :CLS
; 350 SET PAGE 1,0        'Load an image to decompress to the video page0.
; 360 BLOAD "SAMPLE.BN8",S
; 370 POKE &HDE6E,(VPEEK(3)AND16)\16 'Permutation decipher
; 380 VA=USR(SM)          'A compressed image is decompressed to the video page1.
; 390 A$=INPUT$(1)
; 400 END


; アセンブリソースコード
;￣￣￣￣￣￣￣￣￣￣￣￣
;**********************************************************************
; BN142.BIN  BARGAIN lossless image compression routine for MSX2 BASIC
;            Created by Katsuhiro Noguchi 2011/1228
;            Under GPL http://creativecommons.org/licenses/GPL/2.0/
;*********** Using SjASM v0.39g Special thanks Sjoerd Mastijn *********

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
aDYPLT	EQU	 9100h 	;(14336) 更新する前の動的パレット┌ 1番色x256
BASIC1	EQU	0A300h 	;(9728) BASIC後半                │        :
;		0C8F0h	;                                └56番色x256
;		0C900h	;(1414) スタック領域の下限※これを越えると暴走する。
;		0CE85h	;       スタック領域の上限
;		0CE86h	;プログラム開始番地
;		0DDBFh	;プログラム終了番地
CommKey	EQU	0DDC0h 	;(64) 共通暗号鍵
;		0DE00h 	;(120) Variable data area       
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
cR	EQU	0DE6Fh 	; (1) カーソル X座標
cQ	EQU	0DE70h 	; (1) カーソル Y座標
Q1	EQU	0DE71h 	; (1) カーソル 移動フラグ
Q6	EQU	0DE72h 	; (1)       〃
Q9	EQU	0DE73h 	; (1)       〃
Q3	EQU	0DE74h 	; (1)       〃
Q4	EQU	0DE75h 	; (1)       〃
Q5	EQU	0DE76h 	; (1)       〃
Q8	EQU	0DE77h 	; (1)       〃

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
	ORG	0CE86h-7   	;Bsave format
	DB	0FEh		;Header
	DW	Main		;Start address
	DW	End-1		;End address
	DW	Main		;Execution start address

;********************************
; [USR1]
; 画像の圧縮と展開 2011/1228
; Compression and Decompression of an image.
;********************************

Main:
	CALL	RAMSLT		;PAGE1のスロットをRAMにする
	LD	HL,1
	LD	DE,TextG
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

	LD	D,6Ah
	RRA
	JR	C,SC8BC		;SCREEN 5

	SLA	L		;SCREEN 6	L#=4
SC8BC:
	LD	(VA),BC
	LD	(B0),HL		;１バイトのドット数 B0
	CALL	VPAGE0		;アクティブページをVRAM-0
	LD	HL,IP
	LD	BC,sTextG
	PUSH	HL
	PUSH	DE
	PUSH	BC

	CALL	LDIRVM		;TEXT画面領域をVRAMに退避
	LD	HL,BASIC0	;BASIC領域の始まり 8000h
	LD	DE,BAS0
	LD	BC,sBAS0	;BC#=2300h
	LD	A,(DAC+2)	;A#=SCREEN MODE
	CP	7
	JR	NC,DPLTSV

	LD	A,2		;SCREEN<7
	CALL	VPAGE
	LD	D,E		;DE#=0
	LD	B,sBAS_H	;BC#=4900h
	JR	CalPPE
DPLTSV:
	PUSH	HL
	PUSH	DE
	PUSH	BC

	CALL	LDIRVM		;BASIC前半領域をVRAMに退避
	LD	A,1
	CALL	VPAGE
	LD	HL,BASIC1
	LD	DE,BAS1
	LD	BC,sBAS1
CalPPE:
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
	LD	(LOGOP1),A
	LD	(LOGOP),A
	LD	A,(Encryp)	;A#[0,<1>,2]
	RRCA
	JR	NC,R90MTX

	LD	HL,BM		;順列暗号が有効なら現状のパレットを継承する
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
	LD	H,Z27T_H	;HL#=Z27TBL
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
	LD	BC,0802h	;BC#[ 8,2]
	LD	DE,2007h	;DE#[32,7]
	EXX
	LD	BC,0F110h	;BC'#[-15,16]
	LD	D,-17		; D'#[-17]
	CALL	HV_YJK
	JR	CallRC

; 横往復行列を作成 2010/0509
; The horizontal round trip procession is made. 
;-------------------------------*
Normal:
	RLA			;bit6=1ならMix画像
	CALL	C,YokoOu	;HL#=RZ27TL

; 圧縮と展開の呼び出し
; The call of compression and decompression
;-------------------------------*
CallRC:
	LD	H,L		;L#=0 転送方向
	LD	(ARG-1),HL
	LD	(IP),HL
	LD	DE,X1
	LD	BC,(VA)
	LD	A,(DAC+3)	;A#[0,1]=[展開,圧縮]
	OR	A
	CALL	Z,Decomp	;画像を展開する
	CALL	NZ,Comprs	;画像を圧縮する
	LD	HL,BASIC0
	LD	DE,BM
	LD	BC,4352
	LDIR			;裏RAMに動的パレット後半を退避

	POP	BC		;BC#=sBAS1  /sBASIC
	POP	HL		;HL#=BAS1   /BAS0
	POP	DE		;DE#=BASIC1 /BASIC0
	LD	A,(DAC+2)	;A#=SCREEN MODE
	CP	7
	LD	A,1
	JR	NC,DPLTLD

	INC	A		;A#=2
	CALL	VPAGE
	JR	CalPPD
DPLTLD:
	CALL	VPAGE
	CALL	LDMVP0		;VRAMに退避したBASIC後半領域を元に戻す

	POP	BC		;BC#=sBAS0
	POP	HL		;HL#=BAS0
	POP	DE		;DE#=BASIC0
CalPPD:
	CALL	LDMVP0		;VRAMに退避したBASIC領域を元に戻す

	POP	BC		;BC#=sTextG
	POP	HL		;HL#=TextG
	POP	DE		;DE#=IP
	CALL	LDIRMV		;VRAMに退避したTEXT画面領域を元に戻す
	LD	HL,(VA)
	LD	(DAC+2),HL	;圧縮データの総容量をBASICの戻り値として返す
	JP	ROMSLT		;PAGE1のスロットをBASIC ROMに戻してBASICに戻る

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
	LD	DE,RWTBL	;第3マトリックスを反転 Normal/Mix
	LD	A,(LOGOP2)
	RLA			;Matrix Mode 00 01 10
	JR	NC,LpRVT

	LD	D,RZ63_H	;第7マトリックスを反転 Dit/YJK
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
; 画像の圧縮 2011/0731
; Compression of an image
;********************************

Comprs:
	LD	A,4		;PRESET
	LD	(LOGOP),A
	EXX			;HL#=0 DE#=X1
	LD	HL,(X2)
	LD	DE,(X1)
	XOR	A
	SBC	HL,DE		;X3=X2-X1
	LD	(X3),HL
	LD	HL,(Y2)
	LD	DE,(Y1)
	LD	H,A
	LD	D,A
	OR	A
	SBC	HL,DE		;Y3=Y2-Y1
	LD	H,VerNum	;Y3の上位バイトにバージョン番号
	LD	(Y3),HL
	CALL	STATIC		;スタティックデータを計算
	CALL	Z,LDMVP0	;SCREEN 5-7,10はメモリにRGBパレットを転送
DSC8BC:
	EXX			;BC#=[8,40]
	EX	DE,HL		;HL#=X1 DE#=0
	CALL	LDIRVM		;VRAM-0に始点と大きさを転送
	LD	HL,(X1)
	LD	(SX),HL
	LD	BC,(KX)
LPYcmp:
	PUSH	BC		;Y方向の処理	(B,C)#=(KY,KX)		

	CALL	NYEND		;分割サイズの検出_Y
LPXcmp:
	PUSH	BC		;X方向の処理	(B,C)#=(KX,KY)		

	CALL	NXEND		;分割サイズの検出_X
	LD	HL,BLTHED
	LD	(DX),HL
	LD	HL,SX
	LD	IX,BLTMV	;VRAMからRAMに矩形転送
	CALL	EXTROM
	CALL	MEMcmp		;圧縮データを作ってVRAMに転送
	LD	A,(VA+1)	;A#=圧縮データのY座標
	LD	C,A
	LD	A,(DAC+2)
	CP	7
	LD	A,C
	JR	NC,SC7_C

	RLA			;SCREEN5,6は1ラインが128ﾊﾞｲﾄ
SC7_C:
	LD	HL,(SY)		;L#=分割画像のY座標
	CP	L
	JR	NC,NotPrs

	DEC	H
	LD	(DY),HL
	LD	HL,(SX)
	LD	(DX),HL
	LD	IX,BLTVV	;VRAM間で矩形転送
	CALL	EXTROM		;処理済みの分割画像を反転表示
NotPrs:
	POP	BC
	LD	HL,(SX)		;分割画像をX方向に移動
	LD	DE,(NX2)
	ADD	HL,DE
	LD	(SX),HL
	DJNZ	LPXcmp

	CALL	TURNX		;分割画像の方向転換
	LD	(SX),HL		;次の行の開始位置
	LD	HL,(SY)
	LD	DE,(NY)
	ADD	HL,DE		;分割画像をY方向に移動
	LD	(SY),HL

	POP	BC
	DJNZ	LPYcmp
RPc:
	LD	A,(RP)
	OR	A
	RET	Z

	DEC	A		;繰り返しがあればVRAMに転送する
	LD	B,A
	LD	A,11110000b	;VQ-RLN 11110000b
RPIPVM:
	LD	HL,(VA)
	CALL	NWRVRM
	INC	HL
	LD	A,B
	CALL	NWRVRM
	INC	HL
	LD	(VA),HL
	XOR	A
	LD	(RP),A
	RET

;********************************
; 圧縮データを作ってVRAMに転送する 2011/1228
; Compression data is made and it transmits to VRAM.
;********************************

MEMcmp:
	LD	HL,(NBM)
	INC	HL
	EX	DE,HL		;DE#=VBM
	LD	A,(LOGOP1)
	OR	A		;ロジカルオペレーションが
	JR	NZ,IPc		;[PSET]でないとタイルを利用できない

	LD	A,(IP)
	OR	A
	JR	Z,IPc

; タイルランレングス変換
; Tile run length conversion
;-------------------------------*
	LD	L,A		;L#=IP
	LD	H,IP_S_H
	LD	A,E		;A#=VBM
	OR	A
	JR	NZ,CHKNX	;分割画像が標準より小さいなら横幅を調べる

	LD	A,(HL)		;(HL#)=IP_SIZ
	CP	E
	JR	NZ,RPOK		;現在と過去の分割画像の大きさが違うと利用できない
	JR	RPON
CHKNX:
	INC	H		;(HL#)=IP_NX
	LD	A,(NX)
	CP	(HL)
	JR	NZ,RPOK		;現在と過去の分割画像の横幅が違うと利用できない
RPON:
	LD	B,E		;B#=VBM
	LD	HL,BLTWRK
LPCB:
	LD	A,(HL)
	INC	H		;HL#=BM
	CP	(HL)
	JR	NZ,RPOK

	DEC	H		;HL#=BLTWRK
	INC	L
	DJNZ	LPCB

	LD	HL,RP		;タイルランレングスを利用する
	INC	(HL)		;繰り返しの数を１つ増やす
	RET
RPOK:
	CALL	RPc		;VRAMに繰り返しの数を転送 (戻り値 A#=0)

; タイルインデックス変換 2001/0401
; Tile index conversion
;-------------------------------*
IPc:
	LD	B,D		;画像_BLTWRK()をBM()に転送
	LD	C,E		;BC#=VBM
	LD	HL,BLTWRK
	LD	DE,BM
	PUSH	BC
	PUSH	DE

	LDIR
	DEC	HL
	LD	L,C		;HL#=BLTWRK

	POP	DE		;DE#=BM
	POP	BC
	LDIR			;BLTWRK -> BM 原画像保護
	OR	A		;ロジカルオペレーションが
	JR	NZ,PXscan	;[PSET]でないとタイルを利用できない

	LD	E,L		;E#=VBM
	DEC	HL
	LD	L,C		;HL#=BM
	LD	D,(HL)		;D#=BM(0) 先頭色
	LD	B,E		;B#=VBM
	XOR	A
LPSUM:
	ADD	A,(HL)		;画像のチェックサムを計算
	INC	L
	DJNZ	LPSUM

	LD	C,A		;C#=CHECK*SUM
	LD	A,(IP)
	CP	2
	JR	C,SetIP		;過去に分割画像がない

	LD	B,A
	DEC	B
LOOPIP:
	PUSH	BC		;(B,C)#=(IP,CHECK*SUM)

	LD	L,B
	LD	H,IP_B_H
	LD	A,D		;A#=BM(0)
	CP	(HL)		;(IP_BM)
	JR	NZ,NOTIP	;分割画像の先頭色が違うなら利用できない

	INC	H
	LD	A,E		;A#=VBM
	OR	A
	JR	NZ,CHK_NX	;分割画像が標準より小さいなら横幅を調べる

	LD	A,(HL)		;(HL#)=IP_SIZ
	CP	E
	JR	NZ,NOTIP	;現在と過去の分割画像の大きさが違うと利用できない

	INC	H		;(HL#)=IP_NX
	JR	CHKSUM
CHK_NX:
	INC	H		;(HL#)=IP_NX
	LD	A,(NX)
	CP	(HL)
	JR	NZ,NOTIP	;現在と過去の分割画像の横幅が違うと利用できない
	JR	NOCHK		;CHECK*SUMを無視
CHKSUM:
	INC	H
	LD	A,C		;A#=CHECK*SUM
	CP	(HL)		;(IP_CHK)
	JR	NZ,NOTIP	;分割画像のCHECK*SUMが違うと利用できない
NOCHK:
	PUSH	DE		;DE#=(BM(0),VBM)

	LD	L,B		;L#=IP
	LD	IX,BLTMV	;VRAMからBLTWRKに矩形転送する
	CALL	IPBLTV

	POP	DE
	LD	B,E		;B#=VBM
	LD	HL,BLTWRK
LPCBIP:
	LD	A,(HL)		;過去の画像と照合する
	INC	H		;HL#=BM
	CP	(HL)
	JR	NZ,NOTIP

	DEC	H		;HL#=BLTWRK
	INC	L
	DJNZ	LPCBIP
				;タイルインデックスを利用する
	POP	BC		;B#=IP
	LD	A,11110001b	;VQ-IDX 11110001b
	CALL	RPIPVM
IPcall:
	LD	B,E		;B#=VBM
	LD	A,D
	EX	AF,AF'		;A'#=BM(0) 先頭色 HC
	LD	HL,(SX)		;(A',B,C)#=(HC,VBM,CHK*SUM)
	LD	A,(SY)		;(HL,A)#=(SX,SY)
	JP	IPOSIT		;画像の位置を記憶する
NOTIP:
	POP	BC
	DJNZ	LOOPIP
SetIP:
	CALL	IPcall

; 分割画像の画素の走査 2011/0209
; The scan of the pixel of a division image
;-------------------------------*
PXscan:
	LD	A,(NX)
	LD	HL,(X4)
	CP	L
	LD	HL,BM
	LD	A,L		;A#=0
	JR	C,SetVD		;分割画像の横幅が標準未満なら折り返し無し

	LD	E,L		;E#=0
	EXX
	LD	B,A		;B'#=0
	LD	C,Z27T_H
	CALL	LpMtrx		;分割画像の座標変換
	LD	C,WTBL_H
	CALL	LpMtrx		;分割画像の座標変換
	EXX
	LD	L,E		;HL#=W_Scan
	LD	A,(NY)
	CP	16
	LD	A,L		;SD=0
	JR	C,SetVD		;分割画像の縦幅が標準未満なら横のみ

; 色が変化した回数を調べる 2001/0118
; The number of times from which the color changed is investigated.
;-------------------------------*
	LD	DE,WS_K
	LD	C,L		;C#=0
	LD	B,8
LPGETK:
	PUSH	BC

	LD	B,255
	LD	A,(HL)		;HL#=W_Scan/Z_Scan/RWScan/CN
LP_CHK:
	INC	L
	CP	(HL)
	JR	Z,LCHK

	INC	C		;C#=K
	LD	A,(HL)
LCHK:
	DJNZ	LP_CHK

	LD	A,C
	LD	(DE),A
	INC	E
	INC	H
	LD	L,B

	POP	BC
	DJNZ	LPGETK

; 色の変化数が最少になる行列を選ぶ 2011/1228
; It scans by a minimum color change matrix.
;-------------------------------*
	LD	HL,0D642h	;Lp_ZRK_Address
	LD	E,WS_K_L+7	;最優先Matrix
	LD	C,1Dh		;C#=[DEC  E](降順)
	LD	A,(InterF)
	OR	A
	JR	Z,SetCod
				;Interlace Image
	DEC	C		;C#=1Ch [INC  E](昇順)
	LD	E,WS_K_L
SetCod:
	LD	(HL),C		;自己書き換え
	LD	H,D
	LD	L,E		;DE#=HL#=WS_K
	LD	B,7
Lp_ZRK:
	DEC	E		;降順		* INC	E (昇順)
	LD	A,(DE)		;A#=Z-K
	CP	(HL)		;(HL#)=W/Z/RW-K
	JR	NC,NEXT_K

	LD	L,E		;(HL#)=Z/RW/RZ-K
NEXT_K:
	DJNZ	Lp_ZRK

	LD	A,L
	SUB	WS_K_L		;A#=0,1,2,3,4,5,6,7
	LD	B,A
	LD	HL,W_Scan
	ADD	A,H
	LD	H,A
	LD	A,B

; 走査した画像をメモリに転送
; The scanned image is transmitted to a memory.
;-------------------------------*
SetVD:
	LD	(SD),A		;A#=走査角度
	LD	A,(NBM)
	LD	DE,VD
	LD	B,E
 	LD	C,A
	INC	BC		;BC#=VBM
	PUSH	DE

	LDIR			;BM/W_Scan/Z_Scan/RWScan/CN -> VD 最適走査画像

	POP	HL		;HL#VD
	LD	B,A		;B#=NBM
	RRA
	RRA
	RRA
	AND	1Fh
	INC	A
	LD	(VLA),A		;長さのα符号のバイト数 VLA
	PUSH	AF

; 分割画像のランレングス変換 2003/0225
; Run length conversion of a division image
;-------------------------------*
	LD	DE,CN		;K=0
	LD	A,(HL)		;CN=BM(I)
	LD	(DE),A		;CN(K)=CN
LoopRL:
	INC	L		;FOR I=1 TO NBM
	CP	(HL)
	JR	Z,NextRL
				;  IF CN<>BM(I) THEN
	LD	A,(HL)		;    CN=BM(I)
	EX	AF,AF'
	LD	A,L
	DEC	A
	SUB	C
	INC	D
	LD	(DE),A		;    LN(K)=I-J-1
	LD	C,L		;    J=I
	INC	E		;    K=K+1
	EX	AF,AF'
	DEC	D
	LD	(DE),A		;  CN(K)=CN:ENDIF
NextRL:
	DJNZ	LoopRL		;NEXT I		

	LD	A,L
	SUB	C
	INC	D
	LD	(DE),A		;LN(K)=I-J-1
	LD	A,E		;A#=K
	LD	(K),A
	INC	A
	LD	(Kps1),A
	LD	HL,0FFh		;HL#[0,255]
	LD	(MP),HL		;MP=255,PT=0

; 長さのα符号の作成 2011/0209
; Creation of alpha code of length
;-------------------------------*
	LD	HL,LA
	LD	DE,LA+1
	LD	C,35
	LD	(HL),B
	LDIR			;初期化 LA--LB
	DEC	H
	LD	L,B		;HL#=LN
	LD	E,LA_L-1	;DE#=LA-1
	EXX
	LD	B,A		;B#=K+1
	LD	A,80h
LoopLA:
	EXX
	LD	B,(HL)		;B#=長
	INC	B
	EX	DE,HL		;HL#=LA
LPLN:
	RLCA			;ビットを左に回転
	JR	NC,LNCK

	INC	L
LNCK:
	DJNZ	LPLN

	LD	C,A
	OR	(HL)
	LD	(HL),A
	LD	A,C
	EX	DE,HL		;HL#=LNx,DE#=LAx
	INC	L
	EXX
	DJNZ	LoopLA

; 長さのβ符号の作成 2011/0209
; Making of beta code of length
;-------------------------------*
	LD	HL,LB
	LD	A,L		;A#=80h
	EXX			;HL'=LB
	EX	AF,AF'		;A'#=bit counter

	POP	AF
	LD	B,A		;B#=VLA
	DEC	A
	RRA
	RRA
	RRA
	AND	3		;A#=(VLA-1)\8
	ADD	A,LB_L		;A#=(VLA-1)\8+LB_L
	LD	E,A		;DE#=LB+(VLA-1)\8
	LD	HL,LA
LoopLB:
	LD	A,(HL)
	INC	A
	JR	Z,NextLB	;A#=255

	DEC	A
	INC	E
	LD	(DE),A
	EXX			;HL#=LB
	EX	AF,AF'
	LD	C,A
	OR	(HL)
	LD	(HL),A
	LD	A,C	
	EX	AF,AF'
	EXX			;HL#=LA
NextLB:
	EX	AF,AF'		;A#=bit counter
	RRCA
	JR	NC,NextBe

	EXX			;HL#=LB
	INC	L		;LB++
	EXX			;HL#=LA
NextBe:
	EX	AF,AF'
	INC	L		;LA++
	DJNZ	LoopLB		;B#=0

	LD	A,E
	SUB	LB_L-1
	LD	(VLB),A

; 長さのγ符号の作成 2000/1231
; Creation of a gamma code of length
;-------------------------------*
	LD	A,1		;2^PT-1=1
	LD	L,A		;HL#=LIVB
	LD	C,31		;初期化[32]
	CALL	PP_PMc		;γ符号(PT=0)=長さのパレットマップ変換 LIVB
	LD	A,L
	LD	(VLIVB),A	;γ符号のバイト数 VLIVB

; 動的パレットが更新される前の状態を保存 2009/0812
; The state before a dynamic palette is renewed is preserved.
;-------------------------------*
	LD	HL,DYNPLT
	LD	DE,aDYPLT
	LD	BC,sDYPLT
	LDIR

; 色列のMTF変換 2011/0410
; MTF conversion of a color sequence
;-------------------------------*
	LD	HL,VM0		;初期化 VM0--VM6
	LD	DE,VM0+1
	LD	C,13
	LD	(HL),B
	LDIR
	CALL	DPdef		;動的パレットの初期値を更新
	LD	H,CN_H		;HL#=CN
	EXX			;C'#=0
	LD	A,(Kps1)
	LD	B,A		;B#=K+1
LoopPP:
	EXX
	PUSH	HL

	LD	A,(HL)		;A#=今色 C#=前色
	CALL	DPscan		;直前色のパレットを更新
	LD	E,A
	CALL	DPsca1		;現在色のパレットを更新
	LD	A,E
	OR	A		;A#=[0-56]
	JR	NZ,NotNew

	LD	B,11		;新色のとき
	LD	C,B
	LD	D,B
	LD	H,13
	JR	Over62
NotNew:
	LD	BC,0102h	;BC#[1,2]
	LD	DE,0304h	;DE#[3,4]
	CP	C
	JR	C,SumVM4	;PP=1

	LD	B,D		;B#[3]
	JR	Z,SumVM4	;PP=2

	LD	C,E		;C#[4]
	CP	E
	JR	C,SumVM4	;PP=3

	LD	B,5
	JR	Z,SumVM4	;PP=4

	LD	D,B		;D#[5]
	CP	7
	JR	C,SumVM4	;PP=5-6

	LD	C,6
	JR	Z,SumVM4	;PP=7

	LD	B,11
	LD	H,7
	CP	9
	JR	C,SumVM3	;PP=8

	LD	E,C		;E#[6]
	CP	13
	JR	C,SumVM3	;PP=9-12

	LD	D,H		;D#[7]
	CP	15
	JR	C,SumVM3	;PP=13-14

	LD	C,B		;C#[11]
	LD	L,8
	CP	16
	JR	C,SumVM2	;PP=15

	LD	H,9
	CP	25
	JR	C,SumVM2	;PP=16-24

	LD	E,L		;E#[8]
	CP	29
	JR	C,SumVM2	;PP=25-28

	LD	D,B		;D#[11]
	CP	31
	JR	C,SumVM2	;PP=29-30

	LD	L,10
	JR	Z,SumVM		;PP=31

	LD	H,13
	CP	57
	JR	C,SumVM		;PP=32-56
Over62:
	LD	E,B		;E#[11]
	LD	L,H		;H#[13]
	LD	A,63		;PP=63
	JR	SumVM
SumVM4:
	LD	H,B		;H#[1,3,5]
SumVM3:
	LD	L,C		;C#[2,4,6]
SumVM2:
	EX	AF,AF'
	LD	A,L		;A#[2,4,6,8]
	JR	SumVM1
SumVM:
	EX	AF,AF'
	LD	A,12
SumVM1:
	EX	AF,AF'
	LD	(VM5WRK),HL

	POP	HL
	PUSH	HL

	LD	H,PP_H
	LD	(HL),A		;A#=PP MTF係数セット[1-56,63]
	LD	HL,(VM1)
	LD	A,B
	LD	B,0
	ADD	HL,BC
	LD	(VM1),HL	;VM1=VM1+W1
	LD	HL,(VM0)
	LD	C,A
	ADD	HL,BC
	LD	(VM0),HL	;VM0=VM0+W0
	LD	HL,(VM2)
	LD	C,D
	ADD	HL,BC
	LD	(VM2),HL	;VM2=VM2+W2
	LD	HL,(VM3)
	LD	C,E
	ADD	HL,BC
	LD	(VM3),HL	;VM3=VM3+W3
	LD	HL,VM5WRK
	LD	C,(HL)		;C#=W5
	INC	L
	LD	A,(HL)		;A#=W4
	LD	HL,(VM5)
	ADD	HL,BC
	LD	(VM5),HL	;VM5=VM5+W5
	LD	C,A
	LD	HL,(VM4)
	ADD	HL,BC
	LD	(VM4),HL	;VM4=VM4+W4
	EX	AF,AF'
	LD	C,A		;BC#=W6
	LD	HL,(VM6)
	ADD	HL,BC
	LD	(VM6),HL	;VM6=VM6+W6

	POP	HL
	LD	C,(HL)		;C#=前色
	INC	L
	EXX
	DEC	B
	JP	NZ,LoopPP

; 符号量が最小になるパレットを選ぶ 2011/0221
; The amount of codes chooses the palette which becomes the minimum.
;-------------------------------*
	LD	DE,(VM0)	;B#=0
	LD	HL,(VM1)
	CALL	DCOMPR
	JR	NC,VM_2		;(VM1)>=VM0

	EX	DE,HL		;DE#=VM1
	INC	B		;B#=1
VM_2:
	LD	HL,(VM2)
	CALL	DCOMPR
	JR	NC,VM_3

	EX	DE,HL		;DE#=VM2
	LD	B,2
VM_3:
	LD	HL,(VM3)
	CALL	DCOMPR
	JR	NC,VM_4

	EX	DE,HL		;DE#=VM3
	LD	B,3
VM_4:
	LD	HL,(VM4)
	CALL	DCOMPR
	JR	NC,VM_5

	EX	DE,HL		;DE#=VM4
	LD	B,4
VM_5:
	LD	HL,(VM5)
	CALL	DCOMPR
	JR	NC,VM_6

	EX	DE,HL		;DE#=VM5
	LD	B,5
VM_6:
	LD	HL,(VM6)
	CALL	DCOMPR
	LD	A,(K)
	JR	NC,SetVPM

	EX	DE,HL		;DE#=VM6
	LD	B,6
	LD	A,255		;LN符号をキャンセル
SetVPM:
	LD	(VLN),A
	DEC	DE
	SRL	D		;ビット数をバイト数に変換
	RR	E
	SRL	D
	RR	E
	SRL	D
	RR	E
	INC	DE		;DE#=パレットマップサイズ (VMb-1)\8+1
	LD	A,B		;B# [0,1,2,3,4,5,6]
	LD	(PT),A		;パレットタイプ
	OR	A
	LD	A,7
	JR	Z,SetMP
LoopMP:
	RLCA
	DJNZ	LoopMP

	CP	112		;A#[7,14,28,56,112,224,193]
	JR	C,SetMP		;     112      224      193
				;01110000 11100000 11000001
	CPL			;10001111 00011111 00111110
	RLCA			;00011111 00111110 01111100
	CP	124		;      31       62      124
	JR	NZ,SetMP

	LD	A,30
SetMP:
	LD	(MP),A		;MP [7,14,28,56, 31, 62, 30]

; データ量が最小になる組み合わせを選ぶ
; An amount of data chooses the combination which becomes the minimum.
;-------------------------------*
Select:
	LD	A,01000000b	;LA 01xxxxxxb
	EX	AF,AF'
	LD	BC,(VLA)
	LD	A,(VLIVB)
	CP	C
	JR	NC,LB_q

	LD	C,A		;BC#=VLIVB
	EX	AF,AF'
	XOR	A		;LIVB 00xxxxxxb
	EX	AF,AF'
LB_q:
	LD	A,(VLB)
	CP	C
	JR	NC,LN_q

	LD	C,A		;BC#=VLB
	EX	AF,AF'
	LD	A,10000000b	;LB 10xxxxxxb
	EX	AF,AF'
LN_q:
	LD	A,(VLN)
	CP	C
	JR	NC,PM_q

	LD	C,A
	INC	C		;BC#=VLN
	EX	AF,AF'
	LD	A,11000000b	;LN 11xxxxxxb
	EX	AF,AF'
PM_q:
	PUSH	BC		;BC#=VL [VLIVB,VLB,VLA,VLN]
CN_q:
	LD	HL,(K)
	CALL	DCOMPR		;HL#=VCN-1,DE#=[VPMAP]
	JR	NC,BM_q
				;VCN-1<[VPMAP]
	EX	DE,HL
	INC	DE		;DE#=VCN
	EX	AF,AF'
	OR	00111000b	;CN xx111xxxb
	EX	AF,AF'
BM_q:
	POP	HL		;HL#=VL [VLN,VLB,VLA,VLIVB]
	ADD	HL,DE		;DE#=VC [VCN,VPMAP]
	EX	DE,HL		;DE#=VL+VC
	LD	HL,(NBM)
	CALL	DCOMPR
NBMsl2:
	LD	DE,VD
	JR	NC,VLCc

	LD	A,11110010b	;BM 11110010b	圧縮できなかった場合
	LD	(DE),A
	INC	E		;DE#=LIVB
	LD	C,L		;L#=NBM
	INC	BC
	LD	HL,BM
	EXX
	LD	HL,aDYPLT
	LD	DE,DYNPLT
	LD	BC,sDYPLT
	LDIR			;動的パレットを更新される前の状態に戻す
	EXX
	JR	VTEN
VLCc:
	LD	A,(SD)		;VL+VC<VBM
	LD	C,A
	EX	AF,AF'		;A#=ヘッダ
	OR	C		;ヘッダに走査角度を入れよう
	LD	(DE),A		;ヘッダを記録
	INC	E		;DE#=LIVB

; 長さの符号を作る
; The code of length is made.
;-------------------------------*
	PUSH	AF		;A#=ヘッダ,DE#=LIVB,B#=0

	AND	11000000b	;長さの符号
	JR	Z,LIVBc		;00xxxxxxb LIVB

	CP	10000000b
	LD	HL,LA
	JR	C,LAc		;01xxxxxxb LA
	JR	Z,LBc		;10xxxxxxb LB

	DEC	H		;11xxxxxxb LN
	LD	L,B		;HL#=LN
	LD	A,(Kps1)
	JR	Lc

;-------------------------------*
LAc:
	LD	A,(VLA)
	JR	Lc
LBc:
	LD	L,LB_L		;HL#=LB
	LD	A,(VLB)
Lc:
	LD	C,A
	LDIR
	JR	Cc
LIVBc:
	LD	A,(VLIVB)
	INC	A
	LD	E,A

; 色の符号を作る
; The code of a color is made.
;-------------------------------*
Cc:
	POP	AF
	LD	H,D
	LD	L,B		;HL#=VD
	AND	00111000b	;色の符号
	CP	00111000b
	JR	C,PMc		;xx000xxxb PMAP
CNc:
	LD	A,(Kps1)	;K+1色を転送
	LD	C,A
	LD	H,CN_H		;HL#=CN
	JR	VTEN
PMc:
	LD	A,(PT)		;A#=[0,1, 2, 3, 4, 5, 6]
	LD	C,A
	RLCA
	RLCA
	RLCA			;A#=[0,8,16,24,32,40,48] ヘッダ
	OR	(HL)
	LD	(HL),A
	LD	A,C		;A#=PT
	PUSH	DE

	CALL	PMSset		;A#=PMSUB [0,1,3,7,0,1,1]
	LD	C,250		;初期化[251] B#=0
	LD	H,PM_H		;HL#=PLTMAP
	CALL	PP_PMc		;MTF係数の符号変換
	LD	C,L
	INC	C		;BC#=VPMAP
	LD	L,B		;HL#=PLTMAP

	POP	DE		;パレットマップを転送

; VRAMに圧縮データを転送 2011/0208
; Compression data is transmitted to VRAM.
;-------------------------------*
VTEN:
	LDIR
	LD	C,E
	DEC	C
	DEC	C
	INC	BC
	INC	BC
	LD	HL,(VA)
	LD	D,H
	LD	E,L		;DE#=(VA)
	ADD	HL,BC
	LD	(VA),HL
	LD	HL,VD
	JP	LDIRVM

;********************************
; 画像の座標変換 2011/0209
; Geometric transformation of image.
;********************************

LpMtrx:
	LD	A,C
	EXX
	LD	D,A
	LD	H,BM_H		;HL#=BM 原画
	LD	A,(DE)
	LD	L,A		;L#=WTBL(E#)
	LD	C,(HL)		;C#=BM(WTBL(E#))
	INC	D		;DE#=ZTBL
	LD	A,(DE)
	LD	L,A		;L#=ZTBL(E#)
	LD	B,(HL)		;B#=BM(ZTBL(E#))
	INC	D		;DE#=RWTBL
	LD	A,(DE)
	LD	L,A		;L#=RWTBL(E#)
	LD	A,(HL)
	EX	AF,AF'		;A'#=BM(RWTBL(E#))
	INC	D		;DE#=RZTBL
	LD	A,(DE)
	LD	L,A		;L#=RZTBL(E#)
	LD	A,D
	ADD	A,8
	LD	D,A
	LD	A,(HL)		;A#=BM(RZTBL(E#))
	LD	H,D		;H#=CN_H  座標変換した画像＝元の画像(変換行列)
	LD	L,E		;HL#=CN(E#) 右45
	LD	(HL),A		;CN(E#)=BM(RZTBL(E#))
	EX	AF,AF'
	DEC	H		;HL#=RWScan 縦
	LD	(HL),A		;RWScan(E#)=BM(RWTBL(E#))
	DEC	H		;HL#=Z_Scan 左45
	LD	(HL),B		;Z_Scan(E#)=BM(ZTBL(E#))
	DEC	H		;HL#=W_Scan 横
	LD	(HL),C		;W_Scan(E#)=BM(WTBL(E#))
	INC	E
	EXX
	DJNZ	LpMtrx

	RET

;********************************
; MTF係数のPγ符号変換 2009/1103
; Code conversion of a MTF coefficient
;********************************

PP_PMc:
	LD	D,H		;初期化
	LD	E,L
	INC	E
	LD	(HL),B
	LDIR
	LD	C,A		;C#=2^PT-1 [0,1,3,7]
	LD	L,B
	PUSH	HL		;(SP)=PLTMAP,LIVB-1

	LD	A,(MP)
	INC	A
	JR	NZ,NotLN

	EX	(SP),HL
	INC	L
	EX	(SP),HL		;(SP)=LIVB
NotLN:
	DEC	H		;HL#=PLTPOS,LN
	LD	A,(Kps1)
	LD	B,A		;B#=K+1
	LD	A,80h		;A#=Start_BIT
LP_PMc:
	LD	E,L		;E#=(i)
	LD	D,(HL)		;D#=PP
	EX	(SP),HL		;HL#=Next_PLTMAP,(SP)=PLTPOS
	PUSH	BC		;C#=2^PT-1
	PUSH	HL		;(SP)'=PLTMAP=Next_PLTMAP
	PUSH	AF		;A#=Start_bit=Next_Start_bit

	EX	AF,AF'		;A'#=Start_bit
	LD	A,(MP)
	CP	D		;(A,D)#=(MP,PP)
	LD	B,0
	JR	NC,PltPc	;MP>=PP
NewCc:
	LD	D,CN_H		;New Color***** 新色
	LD	A,(DE)		;DE#=CN[i]
	LD	C,A		;C#=CN(i)
	INC	L		;PLTMAP +1
	LD	D,B
	LD	E,B
	LD	A,(IS)
	LD	B,A		;B#=IS [3,4,5]
	EX	AF,AF'		;A#=Start_bit
	JR	LP_ISc		;*****New Color
PltPc:
	LD	A,D		;A#=PP [1-255]
	ADD	A,C		;A#=PP+PT[0,1,3,7,0,1,1]
	LD	E,A		;E#=PM [1-255]
	EX	AF,AF'		;A#=Start_bit
	LD	C,B		;C#=0
LP_VSc:
	INC	B		;Value Shift***** PMの桁数シフトする B#=PMの桁数=VS [1-8]
	RRCA			;Start_bit >>
	JR	NC,VSc

	INC	L		;PLTMAP +1
VSc:
	SRL	E
	PUSH	AF

	RR	C		;E# >> C# = V [PM]

	POP	AF
	JR	NZ,LP_VSc	;*****Value Shift

	EX	AF,AF'		;A'#=Start_bit	E#=0
	LD	A,(PT)
	LD	D,A		;D#=PT [0,1,2,3,0,1,1]
	LD	A,B		;A#=VS [1-8]
	SUB	D		;A#=VS-PT=IS+1
	LD	B,A		;B#=IS+1 [1-8]
	EX	AF,AF'		;A#=Start_bit
	LD	D,E		;DE#=0
	JR	ISc
LP_ISc:
	SRL	C		;Index Shift***** インデックスの桁数シフトする 
	RR	D		;C# >> D# = IV
	RRCA			;Start_bit >>
	JR	NC,ISc

	INC	L		;PLTMAP +1
ISc:
	DJNZ	LP_ISc		;*****Index Shift

	EX	AF,AF'		;A'#=Next_Start_bit

	POP	AF		;A#=Start_bit
	JR	SSc
LP_SSc:
	SRL	C		;Start Shift***** 始まりの桁数シフトする
	RR	D
	RR	E		;C# >> D# >> E# = SIV
SSc:
	RLCA			;Start_bit <<
	JR	NC,LP_SSc	;*****Start Shift

	EX	(SP),HL		;HL#=PLTMAP,(SP)=Next_PLTMAP
	LD	A,(HL)
	OR	C
	LD	(HL),A
	INC	L
	LD	A,(HL)
	OR	D
	LD	(HL),A
	INC	L
	LD	A,(HL)
	OR	E
	LD	(HL),A

	POP	HL		;HL#=Next_PLTMAP
	POP	BC
	EX	AF,AF'		;A#=Next_Start_bit
	EX	(SP),HL		;HL#=PLTPOS,(SP)=Next_PLTMAP
	INC	L		;i++
	DJNZ	LP_PMc

	POP	HL		;HL#=Next_PLTMAP,LIVB
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

;********************************
; [USR6]
; カーソル位置の計算 2011/0622
; Calculation of a cursor position
;********************************

Cursor:
	INC	L
	INC	L		;BASICからキーコードを受け取る
	LD	A,(HL)		;A#=KEY CODE
	LD	BC,0
	LD	DE,(Q3)		;DE#=[Q4,Q3]
	LD	HL,cQ
	CP	30
	JR	NC,K3031

	LD	D,-1
	DEC	L		;HL#=cR
	RRA
	LD	A,(HL)
	JR	C,K29
K28:
	CP	65
	JR	NZ,R13add

	SUB	78
R13add:
	ADD	A,13
	LD	(HL),A
	INC	L		;HL#=cQ
	OR	A
	LD	A,(HL)		;A#=Q
	JR	NZ,SetDAC

	JR	K31
K29:
	OR	A
	JR	NZ,R13sub

	ADD	A,78
R13sub:
	SUB	13
	LD	(HL),A
	INC	L		;HL#=cQ
	CP	65
	LD	A,(HL)		;A#=Q
	JR	NZ,SetDAC

	CP	4
	JR	Z,Q35on
	JR	Q35off
K3031:
	LD	A,(HL)		;A#=Q
	JR	NZ,K31
K30:
	CP	5
	JR	NC,Q35off
Q35on:
	LD	B,E		;B#=Q3
Q35off:
	LD	HL,Q5
	CALL	Q4set
	DEC	A
	ADD	A,B
	ADD	A,C
	JR	Qset
K31:
	INC	L		;HL#=Q1
	CP	(HL)
	INC	L		;HL#=Q6
	JR	C,Q36off

	LD	B,E		;B#=Q3
Q36off:
	CALL	Q4set
	INC	A
	SUB	B
	SUB	C
Qset:
	LD	(cQ),A
SetDAC:
	LD	(DAC+2),A
	RET

;-------------------------------*
Q4set:
	CP	(HL)
	JR	Z,Q4on

	INC	L		;HL#=Q8,Q9
	CP	(HL)
	RET	NZ
Q4on:
	LD	C,D		;C#=Q4
	RET

;********************************
; [USR5]
; アロケーション情報の獲得 2011/0711
; Acquisition of allocation information
;********************************

Sector:
	INC	L
	INC	L		;BASICからドライブ番号を受け取る
	LD	E,(HL)		;E#=Drive Number
	LD	C,_ALLOC  	;C#=Function Code
	CALL	BDOS		;System Call
	JR	SetDAC		;1クラスタあたりの論理セクタ数をBASICに返す

;********************************
; [USR4]
; パレット付画像の画面外領域を初期化 2010/0407
; The area outside the screen of the image with the palette is initialized. 
;********************************

ZeroCL:
	LD	HL,0D400h
	LD	BC,2680h
	LD	A,(SCRMOD)
	CP	7
	JR	NC,ZClear

	LD	H,6Ah
	LD	B,0Ch
ZClear:
	XOR	A
	JP	BIGFIL

;********************************
; [USR2]
; カーソル位置にある12文字を文字変数に代入して反転表示 2011/0216
; 12 characters of the cursor position are substituted for a character variable,
; and it is a reversing display.
;********************************

MOJGET:
	EX	DE,HL
	INC	HL
	LD	E,(HL)
	INC	HL
	LD	D,(HL)		;DE#=String descriptor
	PUSH	DE

	LD	HL,(CSRY)
	DEC	H
	DEC	L
	LD	C,H		;C#=Y
	LD	H,L		;H#=X
	LD	DE,(LINLEN)	;E#=文字数
	CALL	MULT		;掛け算(HL#=H#*E#)
	ADD	HL,BC		;HL#=位置アドレス

	POP	DE		;DE#=文字列コード
	LD	C,12
	PUSH	HL
	PUSH	DE

	CALL	LDIRMV		;カーソル上の文字コードをメモリに転送

	POP	HL
	EXX
	LD	HL,CARCPL	;HL#=反転文字列コード
	LD	B,L		;B#=12
	XOR	A
LPI:
	LD	C,A
	EXX
	PUSH	HL

	LD	E,(HL)		;E#=文字コード
	LD	H,8
	CALL	MULT		;掛け算(HL#=H#*E#)
	LD	E,A		;DE#=[0,8,16･･･88]
	LD	BC,(CGPBAS)
	ADD	HL,BC		;転送元アドレス
	EX	DE,HL
	ADD	HL,BC		;転送先アドレス
	LD	B,8
LPJ:
	EX	DE,HL
	CALL	NRDVRM		;文字パターン読み込み
	INC	HL
	EX	DE,HL
	CPL			;文字パターンの反転
	CALL	NWRVRM		;文字パターン書き込み
	INC	HL
	DJNZ	LPJ

	POP	HL
	INC	HL
	EXX
	LD	A,C
	ADD	A,8
	DJNZ	LPI

	LD	C,L
	LD	B,L		;B#=C#=12
	XOR	A
LPCAR:
	LD	(HL),A
	INC	A
	INC	L
	DJNZ	LPCAR

	POP	DE		;DE#=位置アドレス
	LD	L,C		;HL#=反転文字列コード
	CALL	LDIRVM
	JP	KILBUF		;キーボードバッファをクリア

;********************************
; [USR3]
; テキスト画面の保存と再生 2009/0911
; Save and Load of a text screen.
;********************************

TXTSmL:
	CALL	RAMSLT		;PAGE1のスロットをRAMにする
	LD	BC,sTextG
	LD	DE,IP
	LD	H,E
	LD	L,E		;HL#=0
	LD	A,(DAC+2)
	OR	A
	JR	NZ,LoadTX

	CALL	LDIRMV
	JR	ROMSLT		;PAGE1のスロットをBASIC ROMにする
LoadTX:
	EX	DE,HL		;(HL,DE)#=(IP,0)
	CALL	LDIRVM

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