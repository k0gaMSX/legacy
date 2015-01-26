echo off
echo 開発ファイル群を圧縮しC:ドライブのディスクにバックアップします．
echo プロジェクト名は 丸米 です．
echo --------------------------------------------------------------
echo 内容　ソースファイル
echo 　　　インクルードファイル
echo 　　　ログファイル／マニュアル
echo 　　　バッチファイル
echo 　　　プロジェクトファイル
echo --------------------------------------------------------------

del a:\junk\xmac10.ishU
lha a a:\junk\BACKUP\xmac10.lzh b:\MARK\*.* b:\MARK\mac\*.*
ISH A:\JUNK\BACKUP\xmac10.lzh /SS /M a:\junk
copy a:\junk\BACKUP\xmac10.lzh c:
