		LOC #0
		PUSHJ 	$255,Handl 		% Call routine for forced TRIP
		PUT 	rJ,$255 		% restore rJ
		GET 	$255,rB 		% restore bootstrap register
		RESUME 	0 		 		% return from TRIP

		LOC #10
		PUSHJ 	$255,:handle		
		PUT 	rJ,$255 		
		GET 	$255,rB 		
		RESUME 	0 		 		

GSetPos		IS		#24

		LOC	Data_Segment
		GREG	@
Text	BYTE	"a forced TRIP has appared!",0,0
Text2	BYTE	"Division by Zero!",10,0

		LOC #100

x		IS	$0
y		IS	$1
z		IS  $2
ex 		IS	$3

Main 	SWYM
		TRIP ex,x,y
		PUT	rA,#ff00
		SET x,15
		SET	y,0
		DIV	z,x,y	
		TRAP 	0,Halt,0 		

		PREFIX :DHandl:
tmp 	IS	$0


:handle	SWYM
		PUT		:rA,#0000
		SET		tmp,$255
		LDA		$255,:Text2
		TRAP	0,:GSetPos,0
		TRAP	0,:Fputs,:StdOut
		SET		$255,tmp
		PUT		:rA,#ff00
		POP		0,0
		PREFIX :

		PREFIX :Handl:
tmp 	IS	$0

:Handl	SWYM
		SET		tmp,$255
		LDA		$255,:Text
		TRAP	0,:GSetPos,0
		TRAP	0,:Fputs,:StdOut
		SET		$255,tmp
		POP		0,0

		PREFIX :


		
		
		
		