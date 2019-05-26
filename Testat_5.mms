GPutBmp      IS     #1F
KGet         IS     #38
WIDTH        IS     10                
HEIGHT       IS     10                 
STARTX       IS     1
STARTY       IS     1
x            GREG   0                   
y            GREG   0
F            IS     0                   
B            IS     1                   
T            IS     2                   
TB           IS     B|T                 
W            IS     4                   

             LOC    Data_Segment
             GREG   @
GameBoard    BYTE   W,W,W,W,W,W,W,W,W,W
             BYTE   W,F,F,F,F,F,F,F,F,W
             BYTE   W,F,B,W,W,W,W,F,F,W
             BYTE   W,F,F,W,T,F,F,F,F,W
             BYTE   W,F,F,W,F,F,F,F,F,W
             BYTE   W,F,F,W,F,F,F,F,F,W
             BYTE   W,F,F,W,W,W,W,F,F,W
             BYTE   W,F,F,F,F,F,F,F,F,W
             BYTE   W,F,F,F,F,F,F,F,F,W
             BYTE   W,W,W,W,W,W,W,W,W,W

             LOC    #100

=================== SHOWFIELD ========================
             PREFIX :ShowField:
x            IS     $0                  
y            IS     $1                  
bmpID        IS     $2
return       IS     $3
tmp          IS     $4

:ShowField   GET    return,:rJ
             SET    tmp+1,x
             SET    tmp+2,y
             PUSHJ  tmp,:PosType
             SL     $255,tmp,11         
             OR     $255,$255,x
             SL     $255,$255,16
             OR     $255,$255,y
             SL     $255,$255,5         
             TRAP   0,:GPutBmp,0
             PUT    :rJ,return
             POP    0,0

=================== ShowBoard =======================
             PREFIX :ShowBoard          
x            IS     $0
y            IS     $1
return       IS     $2
tmp          IS     $3

:ShowBoard   GET    return,:rJ
             SET    y,:HEIGHT
2H           SUB    y,y,1
             SET    x,:WIDTH
1H           SUB    x,x,1
             SET    tmp+1,x
             SET    tmp+2,y
             PUSHJ  tmp,:ShowField
             BP     x,1B
             BP     y,2B
             PUT    :rJ,return
             POP    0,0
			 PREFIX :

=================== ShowSokoban ======================
             PREFIX :ShowSokoban:
:ShowSokoban SL     $255,:x,16          
             OR     $255,$255,:y
             SL     $255,$255,5         
             ORMH   $255,5              
             TRAP   0,:GPutBmp,0
             POP    0,0
			 PREFIX :

=================== POSTYPE ==========================
            PREFIX :PosType:
x		IS	$0
y		IS	$1	
adr		IS	$2
offset	IS	$3
tmp		IS	$4
tmp1	IS	$5

:PosType SWYM
		LDA	adr,:GameBoard
		MUL offset,y,:WIDTH
		ADD offset,offset,x
		LDB tmp,adr,offset	
		SET	x,tmp
		POP	1,0
		PREFIX :

=================== MoveSokoban =======================
        PREFIX :MoveSokoban:
dx		IS	$0			
dy		IS	$1			
rj		IS	$2
tmp		IS	$3

:MoveSokoban SWYM
		GET	rj,:rJ
		SET	tmp+1,dx
		SET	tmp+2,dy
		PUSHJ	tmp,:CheckMove:move
		BP	tmp,exit
		BZ	tmp,sF
		SET	tmp+1,dx
		SET	tmp+2,dy
		PUSHJ tmp,:MoveBox:move
sF		SET	tmp+1,:x		
		SET	tmp+2,:y
		PUSHJ tmp,:ShowField	
		ADD	:x,:x,dx
		ADD	:y,:y,dy
		PUSHJ	tmp,:ShowSokoban	
exit	PUT	:rJ,rj
        POP    0,0
		PREFIX :

=================== DoCommand =======================
             PREFIX :DoCommand:
UP           IS     #126
DOWN         IS     #128
RIGHT        IS     #127
LEFT         IS     #125
STEP         IS     1
command      IS     $0                  

arrow        IS     $1
return       IS     $2
dx           IS     $3
dy           IS     $4
tmp          IS     $5

:DoCommand   SET    dx,0
             SET    dy,0
             SET    arrow,UP
             CMP    tmp,command,arrow
             BNZ    tmp,1F
             NEG    dy,STEP
             JMP    Done

1H           SET    arrow,DOWN
             CMP    tmp,command,arrow
             BNZ    tmp,1F
             SET    dy,STEP
             JMP    Done

1H           SET    arrow,RIGHT
             CMP    tmp,command,arrow
             BNZ    tmp,1F
             SET    dx,STEP
             JMP    Done

1H           SET    arrow,LEFT
             CMP    tmp,command,arrow
             BNZ    tmp,Done
             NEG    dx,STEP

Done         GET    return,:rJ          
             SET    tmp+1,dx
             SET    tmp+2,dy
             PUSHJ  tmp,:MoveSokoban
             PUT    :rJ,return          
             POP    0,0
			PREFIX	:

=================== CheckMove =======================
		PREFIX	:CheckMove:
dx		IS	$0	
dy		IS	$1	
rj		IS	$2
tmp		IS	$3

move	GET	rj,:rJ
		ADD	tmp+1,:x,dx
		ADD	tmp+2,:y,dy
		PUSHJ	tmp,:PosType
		BZ tmp,Alone
		CMP	tmp+1,tmp,4
		BZ	tmp+1,exit
		CMP	tmp+1,tmp,2
		BZ	tmp+1,Alone			
		AND	tmp,tmp,3
		BNZ	tmp,wBox
exit	SET	dx,1
		JMP final
wBox	MUL	tmp+1,dx,2
		MUL	tmp+2,dy,2
		ADD	tmp+1,tmp+1,:x	
		ADD	tmp+2,tmp+2,:y
		PUSHJ tmp,:PosType
		CMP	tmp,tmp,4
		BZ	tmp,exit		
		NEG	dx,1
		JMP	final	
Alone	SET	dx,0
final	PUT	:rJ,rj
		POP	1,0	
		PREFIX :

=================== MoveBox =======================
		PREFIX	:MoveBox:
dx			IS	$0	
dy			IS	$1			
rj			IS	$2	
offset		IS	$3
adr			IS	$4
tmp			IS	$5
x			IS	$6
y			IS	$7

move	GET		rj,:rJ
		ADD		x,:x,dx
		ADD		y,:y,dy
		LDA		adr,:GameBoard
		MUL		offset,y,:WIDTH
		ADD		offset,offset,x
		LDB		tmp,adr,offset	   	
		ANDN	tmp,tmp,1	   	
		STB		tmp,adr,offset
		ADD		x,x,dx		   	
		ADD		y,y,dy
		MUL 	offset,y,:WIDTH
		ADD		offset,offset,x
		LDB		tmp,adr,offset	
		OR		tmp,tmp,1			
		STB		tmp,adr,offset
		PUSHJ	tmp,:ShowField	
		PUT		:rJ,rj
		POP 	0,0
		PREFIX :	 

=================== Main =======================
tmp          IS     $0

Main         SET    x,STARTX
             SET    y,STARTY
			 PUSHJ  tmp,ShowBoard
             PUSHJ  tmp,ShowSokoban
while		 TRAP   0,KGet,0            
             SET    tmp+1,$255
             PUSHJ  tmp,DoCommand
             JMP    while
