Handleiding van de blok fade.

De blok fade is een machinetaal programma (blok.bin) om plaatjes soepel in
elkaar te laten overlopen (faden). Het programma werkt in principe op alle
MSX 2(+) schermen, dus op scherm 5,6,7,8,10,11 en 12. Aangezien echter de
x-coordinaat binnen het bereik van 0 tot en met 255 blijft en er gewerkt wordt
met blokjes van 2 pixels bij 2 pixels, is de routine in de praktijk alleen
maar bruikbaar op scherm 5 en 8 (op scherm 6 en 7 wordt alleen de linker helft
gedaan en op de 2+ schermen krijg je tijdens de fade af en toe kleur fouten
van het yjk systeem).
De routine werkt met een x-stap en een y-stap, die normaal willekeurig gekozen
worden. Het is echter ook mogelijk om ze erin te poken.

Een aantal adressen zijn:
&HD400  :  start adres van de routine
&HD40D  :  x-stap keuze adres
&HD418  :  y-stap keuze adres.

De routine een vaste x-stap laten gebruiken gaat als volgt:
POKE &HD40D,&H3E:POKE &HD40E,XSTAP
met XSTAP de grootte van de x-stap.

De routine weer op een willekeurige x-stap zetten gaat als volgt:
POKE &HD40D,&HED:POKE &HD40E,&H5F

Voor de y-stap gaat hetzelfde verhaal op, met dit verschil dat er dan op
adres &HD418 en &HD419 gepoked dient te worden.

De routine werkt altijd van een onzichtbare pagina naar de zichtbare pagina
waarbij altijd van de volgende combinaties wordt uitgegaan:
zichtbare pagina   ophaal pagina
     0                  1
     1                  0
     2                  3
     3                  2

Een voorbeeld van het gebruik van de routine is te vinden in het programma
BLOK.NED.



