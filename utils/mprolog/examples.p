((typesum X Y) (SUM X Y Z) (PP Z)) 
((typedif X Y) (SUM Z Y X) (PP Z)) 
((Calc X + Y) (SUM X Y Z) (PP Z)) 
((Calc X - Y) (SUM Z Y X) (PP Z)) 
((Calc X * Y) (TIMES X Y Z) (PP Z)) 
((Calc X : Y) (TIMES Z Y X) (PP Z)) 
((Number X) (PP X - 1) FAIL) 
((Numbers 1) (PP 1)) 
((Numbers X) (PP X) (SUM Y 1 X) (Numbers Y)) 
((inf bear (honey berries peas))) 
((inf rabbit (carrots lettuce cabbage))) 
((inf wolf (rabbit gregor andrew))) 
((food X) (inf X Y) (PP X eats Y)) 
((first (X|Y)) (PP X) (PP Y)) 
((typelist ())) 
((typelist (X|Y)) (PP X) (typelist Y)) 
((member X (X|Y))) 
((member X (Y|Z)) (member X Z)) 
((tm X Y) (member X Y) (PP ��)) 
((tm X Y) (PP ���)) 
