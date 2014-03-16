del run05.bat
del %1:*.rel
rem --- generating LIBK.LIB ---
cf libk
mx -lo%1 libk >run06.bat
echo genlib06 %1 >>run06.bat
REM ======== [RUN06] ==========
run06
