cf %1
fpc %1 lib
cg -k %1
m80 =%1/z
del %1.mac
l80 ck,%1,clib/s,crun/s,cend,%1/n/y/e:xmain
