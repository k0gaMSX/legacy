
         org #0100
         jp starttis


 include file.inc
 include sample.i

spr_buffer: db 0
sequ: 
sequ2:
 dw s2,k2
 dw s2,k2
 dw s2,k2
 dw s2,k2
 dw file,koko
 dw file,koko
 dw file,k2
 dw file,koko

 dw #00FF 

spede dw 0

paletti
 db #61,#81,#91,#A1,#41,#51,#71,#F1

starttis:
         call refile
 
 ei
 halt

; call colors

         ld a,7
         out (#A0),a
         ld a,%11111000
         out (#A1),a
         sub a

         out (#A0),a
         out (#A1),a

         ld a,1
         out (#A0),a
         sub a
         out (#A1),a

         ld a,2
         out (#A0),a
         sub a
         out (#A1),a
         ld a,3
         out (#A0),a
         sub a
         out (#A1),a

         ld a,4
         out (#A0),a
         sub a
         out (#A1),a
         ld a,5
         out (#A0),a
         sub a
         out (#A1),a

 di 

 ld (spede),sp
 ld sp,sequ


 pop hl
 pop de

; ld hl,file ; pois!
; ld de,(FCB+16) ; pois!

pl_lop:

 ld a,(HL) ; 7

 xor #80 ; 7

 exx       ; 4
 
 ld c,a    ; 4
 ld b,0    ; 7

 ld hl,volatab ; 14
 add hl,bc     ; 11
 add hl,bc     ; 11
 add hl,bc     ; 11

 ld b,12 ; 4  
ahit: 
 djnz ahit ; 12(=b)*13+8=160

 ld a,8 ; 4
 out (#A0),a ; 11

 ld a,(hl) ; 7

 out (#A1),a ; 11
 ld a,9 ; 4
 out (#A0),a ; 11

 inc hl   ; 6
 ld a,(hl) ; 7

 out (#A1),a ; 11
 ld a,10 ; 4
 out (#A0),a ; 11

 inc hl ; 6
 ld a,(hl) ; 7

 out (#A1),a ; 11

 exx ; 4

 inc hl ; 6

 dec de ; 6
 ld a,d ; 4
 or e ; 4
 jp nz,pl_lop ; 10

; yht. 408
; 3.57E6 ticks/sec
; l. 8750 hz.

nollaa_sam:
; call ispressed
 in a,(#AA)
 and #F0
 or 8
 out (#AA),a
 in a,(#A9)
 and 1

 jp z,outasample

; jp playnull

castillo:

 pop hl
 pop de

; ld hl,file ; pois!
; ld de,(FCB+16); pois!

 ld a,l
 cp #FF
 jp nz,pl_lop
 
 ld hl,sequ2
 ld sp,hl
 pop hl
 pop de

; ld hl,file ; pois!
;ld de,(FCB+16) ; pois!
 
 jp pl_lop

outasample:

 ld sp,(spede)
 ei

 ld a,7
 out (#A0),a
 ld a,255
 out (#A1),a

;sub a
;call scrmode

 ret

colors:
 sub a
 out (#99),a
 ld a,#20+#40
 out (#99),a
 
 ld d,0
color_luup:
 ld c,#98
 ld b,8
 ld hl,paletti
 otir

 dec d
 jp nz,color_luup

 ret
 
file:

koko equ 37632
k2 equ 18816
s2 equ file+k2

o/2

le+koko/2


file:
 
file:
 ret
 
f