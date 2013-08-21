PROGRAM voorbeeld_SpriteAttributeAdres;

CONST sprite : ARRAY[0..15] OF BYTE =($FF,$EE,$DD,$CC,$BB,$AA,$99,$88,
                                      $77,$66,$55,$44,$33,$22,$11,$00);

BEGIN
  Screen(5);
  SpriteAttributeAddress($160); { zet de tabel op het zichtbare scherm }
  SpriteColor(0,ADDR(sprite));    { vul de tabel met kleuren }
  READLN;                             { wacht op return }
  Screen(0);
END.
