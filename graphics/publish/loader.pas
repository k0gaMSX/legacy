{** MSX COMMAND LOADER vers�o 1.5 **}
{** STAR SOFTWORKS 1993 - Slotman **}

type literal= STRING [80];

VAR ArqtoLoad:FILE;
    dados1,dados2,DADOSX:literal;

procedure WRITEMEM(ENDERECO:integer;texto:literal);
VAR INDICE,COMPRIMENTO:INTEGER;
BEGIN
 COMPRIMENTO:=LENGTH (TEXTO);
 FOR INDICE:=1 to comprimento do
  begin
   mem [endereco]:=ord(texto[indice]);
   endereco:=endereco+1;end;
   mem [endereco]:=0

end;

procedure programe (dadosx:literal);
var slot:integer;
begin
if port[168]= $FF then slot:=$f0
   else slot:= $a0;

   DADOS1:=#$DB+#$a8+#$f5+#$3e+chr(slot)+#$d3+#$a8;
   dados2:=#$f1+#$d3+#$a8+#$c9;
   dadosx:= dados1+dadosx+dados2;

   writemem ($b100,dadosx);
   inline ($c3/$00/$b1);
end;


PROCEDURE SCREEN0;
begin
 DADOSX:=#$CD+#$6C+#00;
 programe(DADOSX);
end;

procedure COLOR;
begin
 mem[$f3e9]:=1;
 mem[$f3ea]:=1;
 mem[$f3eb]:=1;
 dadosx:=#$cd+#$62+#00;
 programe (dadosx);
end;

BEGIN

  screen0;
  COLOR;
  Assign (ArqtoLoad,'STARDOS.COM');
  Execute (ArqtoLoad);

END.