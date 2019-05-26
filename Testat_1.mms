				LOC #100
	
MWait IS #30
GPutBmp IS #1F

co 				IS $1 
x				IS $2 
y				IS $3 
	
	
Main 	TRAP 0,MWait,0 
			SET x,$255
			SET	y,$255
			SL x,x,32
			SR x,x,48 
			SL x,x,16
			SETMH  $255,5  
			ADD 	$255,$255,x			
			SL y,y,48
			SR y,y,48 
			ADD $255,$255,y
			TRAP	0,GPutBmp,0
			JMP	Main