REM ======== [GENLIB] =========
rem --- generating CRUN.LIB ---
mx -lo%1 crun >run01.bat
echo genlib01 %1 >>run01.bat
REM ======== [RUN01] ==========
run01
