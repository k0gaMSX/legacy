/**************************************************************
 *
 *	time() for MSXDOS, a standard Hitech-C function
 *	returns time in UNIX format: seconds since
 *	00:00:00, 1/1/1970 (unsigned long)
 *
 *	example:
 *
 *	 time(&t);
 *	 printf("Time/Date is %s\n",ctime(&t));
 *
 *	installation:
 *
 *	 C -S TIME
 *	 ZAS -N -oTIME.OBJ TIME.AS
 *	 LIBR R LIBC.LIB TIME.OBJ
 *
 *
 * Freeware for MSX, by Pierre Gielen, october 1993
 *
 ***************************************************************/


#include	<time.h>
#include	<cpm.h>


time_t
msxtime()
{
	time_t t;
#asm
	psect text

	push	iy
	push	ix
	ld	c,02ah		; get date
	call	5
	pop	ix
	pop	iy

	ld	bc,-1970	; unix offset
	add	hl,bc		; hl=jaren sinds 1970, d=maanden, e=dag
	push	de		; bewaar e=dag, d=maand
	ld	a,l
	push	af		; bewaar jaar

	ld	c,d		; c=maand
b2jul0: ld	b,l		; b jaren sinds 1970
	ld	hl,0		; vanaf 0
	ld	a,1		; modulo 4 teller
	ld	de,365		; dagen per jaar
b2jul1: add	hl,de		; tel 1 jaar in dagen er bij op
	inc	a		; verhoog modulo 4 teller
	and	3		; elke 4 jaar
	jr	nz,b2jul2	; nee
	inc	hl		; ja, 1 dag extra voor schrikkeljaar
b2jul2: djnz	b2jul1		; en dat b keer achter elkaar

; hl bevat nu het aantal dagen in de jaren sinds 1970

b2jul3: pop	af		; het huidige jaar
	and	3		; is dit een schrikkeljaar?
	jr	nz,b2jul5	; nee
	ld	a,c		; ja, dan pak maand
	cp	3		; als februari voorbij is
	jr	c,b2jul5	; nog niet
	inc	hl		; wel, dan 1 extra voor 29 februari
;
b2jul5: ld	b,c		; maand in b
	ld	de,dpermo	; tabel met aantal dagen per maand
	jr	b2jul7		; bereken dagen
;
b2jul6: call	addhl		; tel aantal dagen in deze maand bij totaal
	inc	de		; verhoog maandentabel-pointer
b2jul7: djnz	b2jul6		; volgende (voor b maanden)

	pop	de		; de dag staat nog in e
	ld	a,e
	dec	a		; offset 0 (niet 1)
	call	adda2hl 	; tel op bij totaal
	jr	vulin		; klaar

addhl:	ld	a,(de)		; add day of current month
adda2hl:
	add	a,l
	ld	l,a
	ret	nc
	inc	h
	ret

totaal:
	defw	0

vulin:
	call	kilong
	ld	(long1),hl	; zet totaal in long1 buffer
	ld	hl,0
	ld	(long1+2),hl
	inc	hl
	ld	(long2+2),hl
	ld	hl,05180h
	ld	(long2),hl	; zet 15180h (=seconden per dag) in LONG2
	call	multlong	; long1 = long1 * long2
	call	pushlong	; long3 = long1

	push	iy
	push	ix
	ld	c,02ch		; get time
	call	5
	pop	ix
	pop	iy

	push	de		; bewaar d=seconden
	push	hl		; bewaar h=uren, l=minuten

	call	kilong
	ld	l,h		; hl=uren
	ld	h,0
	ld	(long1),hl
	ld	hl,3600
	ld	(long2),hl
	call	multlong
	ld	hl,(long1)
	ld	(long2),hl
	ld	hl,(long1+2)
	ld	(long2+2),hl	; verplaats long 1 naar long2
	call	poplong 	; haal jaren in seconden
	call	addlong 	; long1=long1+long2

	ld	hl,0		; offset 0
	pop	de		; haal e=minuten (was l)
	ld	a,e
	or	a		; 0?
	jr	z,nomin 	; dan hebben we dit niet nodig
	ld	d,0
	ld	b,60		; seconden per minuut
addmin:
	add	hl,de
	djnz	addmin		; tel minuten in seconden op in hl

nomin:	ld	(long2),hl	; in long2 (long1 nog ok)
	ld	hl,0
	ld	(long2+2),hl
	call	addlong 	; tel minuten op

	pop	hl		; haal h=seconden (was d)
	ld	l,h		; in l
	ld	h,0
	ld	(long2),hl
	ld	hl,0
	ld	(long2+2),hl
	call	addlong 	; tel seconden op

	ld	de,(long1)
	ld	hl,(long1+2)	; resultaat nu in hlde, zoals Hitech wenst
	jp	cret		; en einde


	psect data

; tabel met aantal dagen per maand (geen schrikkeljaar)

dpermo: defb	31,28,31,30,31,30,31,31,30,31,30,31

	psect text

pushlong:
	push	hl
	ld	hl,(long1)
	ld	(long3),hl
	ld	hl,(long1+2)
	ld	(long3+2),hl
	pop	hl
	ret

poplong:
	push	hl
	ld	hl,(long3)
	ld	(long1),hl
	ld	hl,(long3+2)
	ld	(long1+2),hl
	pop	hl
	ret

kilong:
	push	hl
	ld	hl,0
	ld	(long1),hl
	ld	(long1+2),hl
	ld	(long2),hl
	ld	(long2+2),hl
	pop	hl
	ret

multlong:
	ld	hl,long1
	ld	de,long2
	ld	a,4
	ld	c,4
	ld	b,0
	add	hl,bc
	ex	de,hl
	ld	(mlier),hl
	ld	hl,hiprod
	add	hl,bc
	ld	(endhp),hl
	ld	l,c
	ld	h,b
	add	hl,hl
	add	hl,hl
	add	hl,hl
	inc	hl
	ld	(count),hl

zeropd: ld	b,c
	ld	hl,hiprod

zerolp: ld	(hl),0
	inc	hl
	djnz	zerolp

	and	a
loop:	ld	b,c
	ld	hl,(endhp)

srplp:	dec	hl
	rr	(hl)
	djnz	srplp

	ld	l,e
	ld	h,d
	ld	b,c

sra1lp: dec	hl
	rr	(hl)
	djnz	sra1lp

	jp	nc,deccnt

	push	de
	ld	de,(mlier)
	ld	hl,hiprod
	ld	b,c
	and	a

addlp:	ld	a,(de)
	adc	a,(hl)
	ld	(hl),a
	inc	de
	inc	hl
	djnz	addlp
	pop	de

deccnt: ld	a,(count)
	dec	a
	ld	(count),a
	jp	nz,loop
	push	af
	ld	a,(count+1)
	and	a
	jp	z,mexit
	dec	a
	ld	(count+1),a
	pop	af
	jp	loop

mexit:	pop	af
	ret

addlong:
	ld	hl,long1
	ld	de,long2
	ld	b,4		; lengte
addllp:
	ld	a,(de)
	adc	a,(hl)
	ld	(hl),a
	inc	hl
	inc	de
	djnz	addllp
	ret

	psect data

dvend:	defw	0		; adres van dividend
dvsor:	defw	0		; adres van divisor
count:	defs	2		; teller
subcnt: defb	0		; subteller (voor aftrekking)
hdeptr:
endhp:	defs	2
odeptr:
mlier:	defs	2
hiprod: defs	8
long1:	defs	4		; buffers voor longints
long2:	defs	4
long3:	defs	4

#endasm
	return	t;
}


time_t
time(tp)
time_t *	tp;
{
	time_t t;
	t = msxtime();
	if(tp)
	   *tp = t;
	return t;
}


                                                                                                     