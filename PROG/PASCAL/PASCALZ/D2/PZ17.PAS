{Program 3.1
example of constant definition part}

Program convert;	{ * ( output ) is implicit in Pascal/Z * }

const	addin = 32; mulby = 1.8; low = 0; high = 39;
	separator = ' __________';
var	degree : low..high;

begin
	writeln( separator );
	for degree := low to high do
	begin
		write( degree, 'c', round( degree * mulby + addin ), 'f' );
		if odd( degree ) then writeln
	end;
	writeln;
	writeln( separator )
end.
                                                                         