echo Make MSX-C Standard Library remake Disk in Current Drive with %1:
rem "Usage: 1. Copy this Batch File into Formatted Disk"
rem "		ex. A>copy b:\batch\forremk.bat \"
rem "       2. And forremk <d>"
rem "		ex. A>forremk b"

pause Insert MSX-DOS2 Master Disk in %1:
copy %1:\msxdos2.sys+%1:\command2.com \

mkdir \bin
mkdir \include

pause Insert MSX-DOS2 TOOLS Master Disk in %1:
copy %1:\m80.com+%1:\lib80.com \bin

pause Insert MSX-C Master Disk in %1:
copy %1:\*.com \bin
copy %1:\include \include
copy %1:\src+%1:\batch\cenv.bat+%1:\batch\gen*.bat+%1:\batch\?rel.bat

echo "Execute cenv.bat before starting remake"
echo "Example  A>cenv a"
echo "  and    A>genlib a"
                                                                       