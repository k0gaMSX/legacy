echo off
echo 開発ファイル群を圧縮しC:ドライブのディスクにバックアップします．
echo プロジェクト名は zero です．
echo --------------------------------------------------------------
echo 内容　ソースファイル
echo 　　　インクルードファイル
echo 　　　ログファイル／マニュアル
echo 　　　バッチファイル
echo 　　　プロジェクトファイル
echo --------------------------------------------------------------

del a:\junk\zmac20.ish
lha a a:\junk\BACKUP\zmac20.lzh b:\zero\*.* b:\zero\mac\*.*
ISH A:\JUNK\BACKUP\zmac20.lzh /SS /M a:\junk
copy a:\junk\BACKUP\zmac20.lzh c:
