
rename(n1, n2)
char *	n1, * n2;
{
  char namebuf[64]; /* needed for slash-flipping */
  int i;
  char c;
  
  for (i=0,c=1 ; c && (i<64) ; ++i)
  {
    c=n1[i];
    namebuf[i++]= (c=='/') ? '\\':c ;
  }
#asm
global _errno, cret, bDos
  push ix
  pop hl
  ld de,-64
  add hl,de
  ex de,hl
  ld l,(ix+8) ; n2
  ld h,(ix+9)
  call bDos
  ld hl,0
  jp z,cret ; return 0
  ld (_errno),a
  ld a,l
  ld (_errno+1),a
  dec hl
1:
#endasm
  /* implicit return hl; */
}
