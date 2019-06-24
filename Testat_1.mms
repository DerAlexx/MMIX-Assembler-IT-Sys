				LOC #100
	
MWait IS #30
GPutBmp IS #1F

co 				IS $1 
x				IS $2 
y				IS $3 
	
	
Main 	JMP	2F

1H		SWYM
2H		SWYM
		SET	$1,2
		SET	$4,#20<<1
		MUL	$0,$1,#20<<1
		SWYM
		SWYM
		SET $0,2
		SET	$1,2
		SLU	$0,$1,6
		SET	$5,#1<<10
		SWYM