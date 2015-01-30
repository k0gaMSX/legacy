cc1 kintest
cc2 kintest
as kintest.asm
as setheap.asm
ld e:kintest,e:setheap,e:intlib,tlib/s,mlib/s,rlib/s,clib/s/gSETHEAP
popd
