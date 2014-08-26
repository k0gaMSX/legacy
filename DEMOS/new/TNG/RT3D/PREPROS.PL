#!/usr/bin/perl
$verbose =$ARGV[0];

#
# Dit is een preprocessor voor het aanmaken van 
# de nodige sourcecode voor een 3D object
# in de snelste 3D engine for MSX that was ever made
# 

#inlezen van datafile gebeurt via STDIN piping mechanisme
#
# inlezen of links/rechtsdraaiend switch actief
$_=<STDIN>;
chomp;
s/#.*//;
$l_r_draaien=$_;


# Nu inlezen parameters
while(<STDIN>){
	chomp;	
	s/#.*//;
	next if /^\s*$/;
	last if !(s/^\%//);
	eval($_);
	};

while(<STDIN>){
	chomp;	
	s/#.*//;
	next if /^\s*$/;
	$nr_poly=$_;
	last;
	};

$i=0;
while(<STDIN>){
	chomp;	
	s/#.*//;
	next if /^\s*$/;
	eval("\$\_=\"$_\"");
	($detail,$color,$shaded,$texture,@polypoint)= split /,/;
	push @polysdetail, $detail;
	push @polyscolor, "$color,$shaded,$texture";
	for $i (@polypoint){$i--;};
	push @polys,[ @polypoint ];
	$i++;
	last if $i==$nr_poly;
	};

while(<STDIN>){
	chomp;	
	s/#.*//;
	next if /^\s*$/;
	$nr_points=$_;
	last;
	};

$i=0;
while(<STDIN>){
	chomp;	
	s/#.*//;
	next if /^\s*$/;
	eval("\$\_=\"$_\"");
	push @points,[ split /,/];
	$i++;
	last if $i==$nr_points;
	};

while(<STDIN>){
	s/#.*//;
	next if /^\s*$/;
	$restdata.=$_;
	};



# printen van de echte data
print <<EOT;
; data made by perl pre-parser
START	EQU	#A000
	db	254
	dw	START,einde,START
	org	START

	; eerst 11 bytes voor de filenaam van de texture
	db	"FIGURE00MAP"

EOT
print " db ".$nr_poly." ; nr of polygons\n";
print " db ".$nr_points." ; nr of points\n\n";
print "; eerst de normaal vectoren per polygon\n";
for ($i=0;$i<$nr_poly;$i++){
	print " db ".join(',',&norm_triangle(
		$polys[$i][0],
		$polys[$i][1],
		$polys[$i][2],
		))."\n";
};
print "\n\n; de aanhechtingspunten van de vorige normaalvectoren\n";
for ($i=0;$i<$nr_poly;$i++){
	print " db ".join(',',&grip_triangle(
		$polys[$i][0],
		$polys[$i][1],
		$polys[$i][2],
		))."\n";
};

print "\n\n; de echte 3d punten\n";
for ($i=0;$i<$nr_points;$i++){
	print " db ".join(',',
		@{$points[$i]}
		)."\n";
};

print "\n\n; de normaal vectoren in elk 3d punt\n";
print "; dit zijn nu nog dummy waarden\n";
for ($i=0;$i<$nr_points;$i++){
	print " db ".join(',',
		@{$points[$i]}
		)."\n";
};

print "\n\n; de polygon verbindingswegen\n";
print "; de aanhechtingspunten van de vorige normaalvectoren\n";
for ($i=0;$i<$nr_poly;$i++){
	print " db ".
		$polysdetail[$i].','.
		$polyscolor[$i].', '.
		($polys[$i][0]+2*$nr_poly).','.
		($polys[$i][1]+2*$nr_poly).','.
		($polys[$i][2]+2*$nr_poly).
		"\n";
};
print <<EOT;
; de texture gegevens
$restdata
 db 0 ; geen textures
einde equ \$ ; einde file
EOT

if ($verbose){
for ($i=0;$i<$nr_poly;$i++){
	print "polygone $i ($polys[$i][0],$polys[$i][1],$polys[$i][2])\n";
	print "norm: ".join(',',&norm_triangle(
                $polys[$i][0],
                $polys[$i][1],
                $polys[$i][2],
                ))."\n\n";

	}
}


sub norm_triangle{
my ($a,$b,$c,$l,$x,$y,$z);
my ($x1,$x2,$y1,$y2,$z1,$z2);

($a,$b,$c)=@_;
($a,$b)=($b,$a) if $l_r_draaien;
$x2=$points[$a][0]-$points[$b][0];
$x1=$points[$c][0]-$points[$b][0];
$y2=$points[$a][1]-$points[$b][1];
$y1=$points[$c][1]-$points[$b][1];
$z2=$points[$a][2]-$points[$b][2];
$z1=$points[$c][2]-$points[$b][2];

$x=$y1*$z2-$y2*$z1;
$y=-($x1*$z2-$x2*$z1);
$z=$x1*$y2-$x2*$y1;
$l=sqrt($x**2+$y**2+$z**2);

if ($l == 0){

print <<EOF;
\$x2=\$points[\$a][0]-\$points[\$b][0];
$x2=$points[$a][0]-$points[$b][0];
\$x1=\$points[\$c][0]-\$points[\$b][0];
$x1=$points[$c][0]-$points[$b][0];
\$y2=\$points[\$a][1]-\$points[\$b][1];
$y2=$points[$a][1]-$points[$b][1];
\$y1=\$points[\$c][1]-$points[\$b][1];
$y1=$points[$c][1]-$points[$b][1];
\$z2=\$points[\$a][2]-$points[\$b][2];
$z2=$points[$a][2]-$points[$b][2];
\$z1=\$points[\$c][2]-\$points[\$b][2];
$z1=$points[$c][2]-$points[$b][2];

 x y z l : $x $y $z $l
 a b c : $a $b $c
EOF
	die;
	};

return (int($x/$l*31),int($y/$l*31),int($z/$l*31));
}

sub grip_triangle{
my ($a,$b,$c,$x,$y,$z);

($a,$b,$c)=@_;
$x=int(($points[$a][0]+$points[$b][0]+$points[$c][0])/3);
$y=int(($points[$a][1]+$points[$b][1]+$points[$c][1])/3);
$z=int(($points[$a][2]+$points[$b][2]+$points[$c][2])/3);

return ($x,$y,$z);
}

	
