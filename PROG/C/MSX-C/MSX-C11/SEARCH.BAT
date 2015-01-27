/*Start on batch process */
/*generates "search.bin".*/
dir search.*
dir bk.*
/*CF (parser)*/
cf search
/*FPC (parameter checker)*/
fpc search lib
/*CG (code generator)*/
cg -k search
/*Assemble*/
m80 =search/z
m80 =bk/z
del search.mac
/*Link*/
l80 /p:d000,bk,search,clib/s,crun/s,search/n/x/e:search
del search.rel
del bk.rel
dir search.*
bsave search.hex >search.bin
del search.hex
dir search.*
basic search.bas
