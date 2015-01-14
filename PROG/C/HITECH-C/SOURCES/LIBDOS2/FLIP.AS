;extern int errno;
;int _flip(char *d, char *s, unsigned int n)
;{
;  for ( ++n ;  (--n) && (*s) ; s++)  *(d++) = (*s=='/') ? '\\' : *s ;
;  if (n) *d='\0'; else errno=0xd8; /* PLONG: path too long */
;  return n;
;}

global _errno
global __flip
psect text
__flip:
pop af ; ret-addr
pop de ; d
pop hl ; s
pop bc ; n
push bc
push hl
push de
push af

loop:
ld a,b
or c
jr z,full
1:
ld a,(hl)
cp '/'
jr z,slash
or a
jr z,done
ldi
jp pe,1b
full:
ld hl,0D8h ; PLONG : path too long
ld (_errno),hl
ld l,c
ret
done:
ld (de),a
ld l,c
ld h,b
ret

slash:
inc hl
ld a,'\'
ld (de),a
inc de
dec bc
jr loop


