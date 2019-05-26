	LOC #100

x		IS	$0
y		IS	$1
z		IS  $2
ex 		IS	$3
tmp		IS	$4
tmp2	IS	$5
tmp3	IS	$6

EWait 	IS	#60

Main 	SWYM
		SETH	tmp,#ffff
		SETMH	tmp2,#ffff
		OR		tmp3,tmp2,tmp
		SET		$255,tmp3
		TRAP	0,EWait,0	
		SWYM
		TRAP 	0,Halt,0 		
		
		
		
		