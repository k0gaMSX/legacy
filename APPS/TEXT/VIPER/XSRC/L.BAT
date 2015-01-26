echo off
echo わてはメイキングバッチだす～．
echo アセンブルしまひょ．
za b:\MARK\MARK.prj
if errorlevel 1 goto error1

echo うまくいきおったよって
echo リンクでんな．
zl b:\MARK\MARK.prj
if errorlevel 1 goto error2
echo でかしおった！バッチグー！！
goto end

rem -------------------------------- error
:error1
echo ま，ぼちぼちですわ．
echo リンクせんけどかんにんな．
goto end

:error2
echo 残念！あきまへんわ．
goto end

:end
echo またね～ん．
