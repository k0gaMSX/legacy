type install.txt /p
ECHO
ECHO Creating A:\WINDOWS\ ..
MD A:\WINDOWS
ECHO Creating A:\WINDOWS\TEMP\
MD A:\WINDOWS\TEMP
ECHO Creating A:\WINDOWS\DESKTOP\
MD A:\WINDOWS\DESKTOP
ECHO Creating A:\WINDOWS\HELP\
MD A:\WINDOWS\HELP
ECHO
ECHO
COPY MSXW98EN.ARJ A:\WINDOWS
COPY unarj.com A:\WINDOWS
A:
CD \WINDOWS
ECHO Extracting system files ..
ECHO
UNARJ E MSXW98EN.ARJ
COPY WIN.BAT A:\
COPY *.ICO DESKTOP
COPY DESKTOP.INI DESKTOP
COPY *.HLP HELP
DEL *.ico
DEL *.HLP
DEl DESKTOP.INI
echo
echo MSX Windows 98 v1.1e has been installed in A:\WINDOWS\
echo Type WIN at the DOS prompt to start
echo

