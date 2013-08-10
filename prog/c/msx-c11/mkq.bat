/* Generate "q.com" */
dir q.*
dir rnd.*
dir line.*
dir color.*
dir calbio.*
cf q
cg -k q
m80 =q/z
del q.mac
m80 =rnd/z
l80 ck,q,rnd,line,color,calbio,clib/s,crun/s,cend,q/n/e:xmain
del q.rel
q
