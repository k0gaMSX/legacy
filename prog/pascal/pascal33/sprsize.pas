PROGRAM voorbeeld_SpriteSize;

CONST sprite : ARRAY[0..31] OF BYTE =($FF,$FF,$00,$FF,$00,$C3,$3C,$24,
                                      $24,$24,$C3,$00,$FF,$00,$FF,$FF,
                                      $FF,$FF,$00,$FF,$00,$3B,$44,$44,
                                      $84,$84,$1B,$00,$FF,$00,$FF,$FF);
VAR maat : BYTE;

BEGIN
  Screen(1);
  SpritePattern(0,ADDR(sprite));
  FillSprite(0,4);
  PutSprite(100,100,0,0);
  maat:=2;
  REPEAT
    SpriteSize(maat);
    DELAY(500);
    maat:=5-maat
  UNTIL KEYPRESSED;
  Screen(0);
END.
