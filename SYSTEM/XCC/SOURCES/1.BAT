echo Initializing XCC development environment
b:
cd \ontw\xcc
copy b:macs\*.mac h:\ > nul
copy b:rels\*.rel h:\ > nul
attrib +h h:*.mac + h:*.rel > nul
res-arch h: > nul

if not exist h:\link.bat copy link.bat/h h:\
attrib +h link.bat/h
if not exist h:\xcg.bat copy xcg.bat/h h:\
attrib +h xcg.bat/h
if not exist h:\xcr.bat copy xcr.bat/h h:\
attrib +h xcr.bat/h
if not exist h:\xcm.bat copy xcm.bat/h h:\
attrib +h xcm.bat/h
if not exist h:\xcb.bat copy xcb.bat/h h:\
attrib +h xcb.bat/h
res-arch h:\*.bat > nul

if not exist h:\xcc.mf copy xcc.mf h:\xcc.mf
if not exist h:\xcc.com copy xcc.com h:\xcc.com
if not exist h:\xcc.ovl copy xcc.ovl h:\xcc.ovl
if not exist h:\xcc.hlp copy xcc.hlp h:\xcc.hlp
if not exist h:\xcc.cfg copy xcc.cfg h:\xcc.cfg

cd sources
