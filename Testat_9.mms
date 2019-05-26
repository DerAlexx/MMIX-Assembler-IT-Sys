		LOC	Data_Segment
		GREG @
Counter OCTA #30
Counter2 OCTA 9

GPutChar IS #29
TCount 	IS	#13
EWait 	IS	#60	
		
counterAdr	IS $5
counterVal	IS $6
tmp			IS $7
tmp2		IS $8
toStringAdr IS $11


		LOC	#100
Main	SWYM
		PUSHJ toStringAdr,:toString
loop	LDA	counterAdr,Counter
		LDO	counterVal,counterAdr 
		SET	$255,counterVal
		TRAP 0,TCount,0
		BZ	counterVal,end
		SET	tmp,17 
		SL	$255,tmp,40
ewait	TRAP 0,EWait,0
		SET	counterVal,$255
		SET	tmp,1
		SL	tmp,tmp,44
		CMP tmp2,tmp,counterVal
		BZ	tmp2,dek
		BNZ	tmp2,ewait
dek		LDA	counterAdr,Counter
		LDO	counterVal,counterAdr 
		SUB	counterVal,counterVal,1
		STOU counterVal,counterAdr,0
		JMP	loop
end		TRAP 0,Halt,0


		PREFIX :toString:
		
:toString SWYM
loop	LDA	:counterAdr,:Counter2
		LDO	:counterVal,:counterAdr 
		ADD :counterVal,:counterVal,#30
		SLU	$255,:counterVal,32
		TRAP 0,:GPutChar,0
		SET	:tmp,1
		SL	$255,:tmp,44
		SUB	 :counterVal,:counterVal,#30
ewait	BZ	:counterVal,exit
		TRAP 0,:EWait,0
		SET	:counterVal,$255
		SET	:tmp,1
		SL	:tmp,:tmp,44
		CMP :tmp2,:tmp,:counterVal
		BZ	:tmp2,dek
		BNZ	:tmp2,ewait
dek		LDA	:counterAdr,:Counter2
		LDO	:counterVal,:counterAdr 
		SUB	:counterVal,:counterVal,1
		STOU :counterVal,:counterAdr,0
		JMP loop
exit	POP 0,0
		PREFIX :
