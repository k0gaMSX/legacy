;*************************
;*     ORG-43 . MSD      *
;*                       *
;*    Presented by       *
;* TRAGIC - Kaori Ashino *
;*                       *
;*************************

FM1 =*I,*F1,  MAA,MAB,MAC,MAD, MAE,MAF,MAG,MAH
           ,  MAA,MAB,MAC,MAD, MAE,MAF,MAG,MAH, MAG,MAH
FM2 =*I,*F2,  MAA,MAB,MAC,MAD, MAE,MAF,MAG,MAH
           ,  MAA,MAB,MAC,MAD, MAE,MAF,MAG,MAH, MAG,MA.
FM3 =*I,*F3,  MBA,MBB,MBC,MBD, MBE,MBF,MBG,MBH
           ,  MBA,MBB,MBC,MBD, MBE,MBF,MBG,MBP, MBG,MBH
FM4 =*I,*F4,  MBA,MBB,MBC,MBD, MBE,MBF,MBG,MBH
           ,  MBA,MBB,MBC,MBD, MBE,MBF,MBG,MBP, MBG,MB.
FM5 =*I,*F5,  CAA,CAB,CAC,CAD, CAE,CAF,CAE,CAH
           ,  CAA,CAB,CAC,CAD, CAE,CAF,CAE,CAH, CAE,CAH
FM6 =*I,*F6,  CAA,CAB,CAC,CAD, CAE,CAF,CAE,CAH
           ,  CAA,CAB,CAC,CAD, CAE,CAF,CAE,CAH, CAE,CA.
FMR =
FM7 =*I,*F7,  CBA,CBB,CBC,CBD, CBE,CBF,CBE,CBH
           ,  CBA,CBB,CBC,CBD, CBE,CBF,CBE,CBH, CBE,CBH
FM8 =*I,*F8,  BA ,BB ,BA ,BD , BE ,BF ,BE ,BH
           ,  BA ,BB ,BA ,BD , BE ,BF ,BE ,BH , BE ,BH
FM9 =*I,*F9,  BA ,BB ,BA ,BD , BE ,BF ,BE ,BH
           ,  BA ,BB ,BA ,BD , BE ,BF ,BE ,BH , BE ,BH
PSG1=*I,*P1,  BDA/4          , BDA,BDF,BDA/ 2
           ,  BDA/4          , BDA,BDF,BDA/2  , BDA/2
PSG2=*I,*P2,  SDA,SDB,SDA,SDD, SDA,SDF,SDA,SDD
           ,  SDA,SDB,SDA,SDD, SDA,SDF,SDA,SDD, SDA,SDD
PSG3=*I,*P3,  SYA,SYB,SYA,SYD, SYA,SYF,SYA,SYD
           ,  SYA,SYB,SYA,SYD, SYA,SYF,SYA,SYD, SYA,SYD
SCC1=
SCC2=
SCC3=
SCC4=
SCC5=
;====
;--INITIALIZE.---
*I=T112 L16
;::::FM initialize.::::
*F1=@83 V13Q7 O4
*F2=@83 V11Q7 O4  Z32 R8
*F3=@83 V12Q7 O4
*F4=@83 V10Q7 O4  Z32 R8
*F5=@83 V12Q7 O5
*F6=@83 V10Q7 O5  Z32 R16.
*F7=@83 V11Q7 O5
*F8=@33 V13Q7 O3
*F9=@23 V12Q7 O3
;:::PSG initialize.:::::
*P1=@11 V15   O2  L16
*P2=@14 V11   O3  L16
*P3=@15 V13   O3  L64
;======================================
;music data. 
;+++melody. +++++++++++++++++++++++++++
MAA=i32m9 <A8>C8E8A(B) BBA8E8C(B) B8A8
E8G8 G8. (F) F4
MBA=i32m9 CBE8A8>C(D) D8C8<A8E>(D)   D8C8<A8B8 B8. (A) A4
MAB=<G8B8>D8G(A) A8G8D8<B>(A)  A8G#8D8F8 F8. (E)E4
MBB=<B8>D8G8B>(C) CB<B8F8D>(C) C8<BBF8A8 A8. (G#)G#4
MAC=<A8>C8E8A(B) B8A8E8C(B)  B8A8B>C8. <A4. B>C<
MBC=C8E8A8>C(D) D8C8<A8E>(D)  D8C8DE8. C4. DE<
MAD=B2 G4B4 A1
MBD=>D2 <B4>D4    C1<
MAE=>E4E8F(E) E8E8D8C8 D8.<B8.(G8 G4) GGAB
MBE=>G4G8A(G) G8G8F8E8 F8.D8.<(B8 B4) BB>CD<
MAF=B8.A8.(G#8) G#8E8>E8<B8  >D8.(CC4) C4C<B8.
MBF=>D8.C8.<(B8) B8G#8>G#8D8  F8.(EE4) E4ED8.<
MAG=A4.B8 >C8.<B8.A8  B4.>C8 D8.C8.<B8
MBG=>C4.D8 E8.D8.C8  D4. E8 F8. E8. D8<
MAH=(A1 A2) A4. r8
MBH=>(C1 C2) C4. r8<
;
MBP=>C1  >CE<B>D<A>C<G#B FAEG#DFCE<
MA.=(A1 A2) A4.
MB.=>(C1 C2) C4. <
;+++chorus. +++++++++++++++++++++++++++
CAA=i24m12 A2 G2 F2 G8. (A)A4
CBA=i24m12 >C2 <B2 A2 B8. > (C) C4<
CAB=B2 A2 G#2 A8. (B) B4
CBB=>D2 C2 <B2 >C8. (D) D4
CAC=>C2 <B2 >F2 E8. (D) D4<
CBC=>E2 D2 A2 G8. (F) F4<
CAD=B2 >D2 C1 <
CBD=>D2 F2 E1<
CAE=ArArArAr ArArArAr BrBrBrBr BrBrBrBr
CBE=>CrCrCrCr CrCrCrCr DrDrDrDr DrDrDrD
r<
CAF=G#rG#rG#rG#r G#rG#rG#rG#r >CrCrCrCr
 CrCrCrCr<
CBF=BrBrBrBr BrBrBrBr  >ErErErEr ErErErEr<
CAH=>CrCrCrCr CrCrCrCr  CrCrCrCr CrCrCrCr<
CA.=>CrCrCrCr CrCrCrCr  CrCrCrCr CrCrCrC32<
CBH=>ErErErEr ErErErEr  ErErErEr ErErErEr<
;+++bass.+++++++++++++++++++++++++++++
BA=AAAAAAAG AAAAAAAG  FFFFFFFE FFFFFFFE
BB=GGGGGGGF GGGGGGGF  G#G#G#G#G#G#G#(E)
E<B>EG#BG#E<B>
BD=GGGGGGGF GGGGGGGF  AAAAAAAG AAAAAG8.
BE=FFFFFFFE FFFFFFFE  GGGGGGGF GGGGGGGF
BF=EEEEEEED EEEEEEED  AAAAAAAG AAAAAG8.
BH=AAAAAAAG AAAAAAAG  AAAAAAAG AAAAAAAG
;+++drums ( bass IL snare  synthe ).+++
BDA=GGGGGGGG GGGGGGGG GGGGGGGG GGGGGGGG
SDA=rrGrrrGr rrGrrrGr rrGrrrGr rrGrrrGr
SYA=r8 (DC<BAGFE)D> r8 (DC<BAGFE) D>
    r8 (DC<BAGFE)D> r8 (DC<BAGFE) D>
    r8 (DC<BAGFE)D> r8 (DC<BAGFE) D>
    r8 (DC<BAGFE)D> r8 (DC<BAGFE) D>
;BDB=BDA
SDB=rrGrrrGr rrGrrrGr rrGrrrGr rrGrrrGG
SYB=r8 (DC<BAGFE)D> r8 (DC<BAGFE) D>
    r8 (DC<BAGFE)D> r8 (DC<BAGFE) D>
    r8 (DC<BAGFE)D> r8 (DC<BAGFE) D>
    r8 (DC<BAGFE)D> r8 (GFE)D (DC<B)A>
;BDD=BDA
SDD=rrGrrrGr rrGrrrGr rrGrrrGr rrGrrGGG
SYD=r8 (DC<BAGFE)D> r8 (DC<BAGFE) D>
    r8 (DC<BAGFE)D> r8 (DC<BAGFE) D>
    r8 (DC<BAGFE)D> r8 (DC<BAGFE) D>
    r8 (DC<BAGFE)D> r16 (GFE)D (DC<B)A><(GFE)D>
BDF=GGGGGGGG GGGGGGGG GGGGGGGG GGGGGGrG
SDF=rrGrrrGr rrGrrrGr rrGrrrGr rrGrGGrr
SYF=r8 (DC<BAGFE)D> r8 (DC<BAGFE) D>
    r8 (DC<BAGFE)D> r8 (DC<BAGFE) D>
    r8 (DC<BAGFE)D> r8 (DC<BAGFE) D>
    r8 (DC<BAGFE)D> (GFE)D (DC<BAGFE)D>
r16


