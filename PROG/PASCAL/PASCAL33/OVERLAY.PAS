{$A-}

TYPE Str63 = STRING[12];

VAR Maximum: INTEGER;
    OverlayBaseAddress: ARRAY[0..1] OF LONGINT;

procedure _OverlayProc0_2(Maximum: INTEGER); forward;

overlay
procedure OverLayProc0_1(Maximum: INTEGER);
begin
   writeln('Overlay 0--routine 1 ',Maximum);

   if Maximum < 2 then _OverlayProc0_2(Maximum+1);

   writeln('Overlay 0, routine 1 ',Maximum);
end;

overlay
procedure OverLayProc0_2(Maximum: INTEGER);
begin
   writeln('Overlay 0--routine 2 ',Maximum);

   if Maximum < 2 then OverlayProc0_1(Maximum+1);

   writeln('Overlay 0, routine 2 ',Maximum);
end;

procedure _OverlayProc0_2;
begin
   OverlayProc0_2(Maximum);
end;

procedure Dummy_0;
begin
end;

overlay
procedure OverLayProc1_1;
begin
   writeln('Overlay 1, routine 1');
end;

overlay
procedure OverLayProc1_2;
begin
   writeln('Overlay 1, routine 2');
end;

overlay
function ReverseString(S: Str63): Str63;
var C: CHAR;
begin
   if length(S) = 0 then exit;

   if length(S) = 1 then
   begin
      ReverseString:=S;
      exit;
   end;

   C:=S[1];

   ReverseString:=ReverseString(copy(S,2,length(S))) + C;
end;

procedure OverlayHandler(Address: INTEGER; Pos: LONGINT; DataLength: INTEGER;
			 OverlayNum: INTEGER; VAR Name: Str63);
begin
   writeln('OverlayHandler ',OverlayNum,' ',Pos,' - ',DataLength,' ',Name);
   setchannel(0,OverlayBaseAddress[OverlayNum] + Pos);
   readmem(0,Address,DataLength);

   if (pos = 0) and (overlaynum = 0) then
   begin
      OverlayProc1_1;
      OverlayProc1_2;
   end;
end;

begin
   Maximum:=SetMem(1);

   if Maximum < 1 then
   begin
      writeln('Not enough memory');
      halt;
   end;

   writeln('SetChannel');
   SetChannel(0,0);
   OverlayBaseAddress[0]:=GetChannel(0);

   writeln('MemReadFile overlay 0');
   MemReadFile(0,0,102400,'overlay.000');

   if GetError <> 0 then
   begin
      writeln('Error reading overlay file');
      halt;
   end;

   OverlayBaseAddress[1]:=GetChannel(0);

   writeln('MemReadFile overlay 1');

   MemReadFile(0,0,102400,'overlay.001');

   if GetError <> 0 then
   begin
      writeln('Error reading overlay file');
      halt;
   end;

   writeln('Overlay 0 BaseAddress: ',OverlayBaseAddress[0]);
   writeln('Overlay 1 BaseAddress: ',OverlayBaseAddress[1]);

   writeln('OverlayPTR');
   OverlayPTR:=ADDR(OverlayHandler);

   writeln('Frits Hilderink');

   writeln(ReverseString('Frits Hilderink'));

end.

