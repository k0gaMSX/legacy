PROGRAM voorbeeld_SpriteColor;

CONST sprite : ARRAY[0..31] OF BYTE =($FF,$FF,$00,$FF,$00,$C3,$3C,$24,
                                      $24,$24,$C3,$00,$FF,$00,$FF,$FF,
                                      $FF,$FF,$00,$FF,$00,$3B,$44,$44,
                                      $84,$84,$1B,$00,$FF,$00,$FF,$FF);
       kleur : ARRAY[0..15] OF BYTE =(0,1,2,3,4,5,6,7,8,
                                      9,10,11,12,13,14,15);

BEGIN
  Screen(5);
  SpriteAttributeAddress($760);
  SpritePatternAddress  ($780);
  SpritePattern(0,ADDR(sprite));
  SpriteSize(3);
  SpriteColor(0,ADDR(kleur[0]));
  PutSprite(100,100,0,0);
  READLN;                           { wacht op return }
  Screen(0);
END.
