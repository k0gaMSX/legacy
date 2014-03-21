echo Stop de XCC disk in drive C: en druk op een toets
pause > nul
xcopy sources c:\xcc\sources /m
xcopy macs c:\xcc\macs /m
xcopy *.* c:\xcc /h /m
