;**************************************
;*  Dragon Ball                       *
;*                                    *
;*                                    *
;*                                    *
;*                                    *
;*                                    *
;**************************************

FM1 =t,f1,r,ff1,ff2,ff1,ff3
FM2 =t,f2,fm2
FM3 =;t,f3,fm3/10
FM4 =t,f4,r,fm4
FM5 =t,f5,r,fm5
FM6 =t,f6,r,fm6
FMR =t,fr1/19,fr2,fr1/6,fr3
FM7 =
FM8 =
FM9 =
PSG1=
PSG2=
PSG3=
SCC1=t,s1,fm2
SCC2=t,s2,r,fm6
SCC3=
SCC4=
SCC5=

t=T130

f1=v15
f2=v12 @78q4
f3=v10 @33q1
f4=v10 @06q4
f5=v13 @33
f6=v13 @06
s1=v12 @24q4
s2=v10 @0


;----Melodia
r=r1r1
ff1=@78 o5
    f8l16ecr2l8eg.f16er2l8eg
    g8f16>c1.r8
   @6
    <l16cde-4..f2r8g8.a-16r2
ff2=a-8b-4a-8r2g16f16e-16g8.r8r2.
ff3=b-8a-16a-8.g16r16r2r8g1r8       
   @12
    a2r8e4a8g8r4.f8.e8.d16.r32
   @6  f2.e8e2..
   @12 c8c8
   @6
    r2f8e8c8f4e8c2r4
    r2f8e8c8f4e8c2.r4
   @12 >d8d2.r8
;----Bajos
fm2=o4
    l4cccccccc
    l4cccccccc
    <b-b-b-b-b-b-b-b-
    a-a-a-a-a-a-a-a-
    e-e-e-e-gggg
    >l4cccccccc
    <b-b-b-b-b-b-b-b-
    a-a-a-a-a-a-a-a-
    gggggggg
    aaaab8rr8r2
    >cccccccc
    <b-b-b-b-b-b-b-b-8b-8
    aaaaaaaa8a8
    r4g2.
;----Bajos 2
fm3=o6i10
    l4rrrerrre
;----Acorde 1
fm4=o4
    l1rrrrrrrrrrrrrrrr
    rrrrrrc4r2r2.r2.g8g8
;----Acorde 2
fm5=o6
    l1rrrrrrrrrrrrrrrr
    r4r8rr8r2rr2.c8c8rrrrr4<b8b2.r8
;----Mas
fm6=o3l1
    c...r8<b-...r8a-...r8e-g>
    c...r8<b-...r8a-...r8g...r8 
    ab>c...r8
    <b-...r8arr4g4
;----Ritmos
fr1=v13vs15
    b8b8b4b8b8s4
fr2=vc0c8c2 ;c4.c5c5c6
fr3=c4h8h2.

