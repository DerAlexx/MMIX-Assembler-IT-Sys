%            TRAP numbers
GSetPos	     IS     #24
GPutStr      IS     #2A
GPutBmp      IS     #20
KGet         IS     #38
TCount 		 IS		#13
EWait 		 IS		#60	

%            Globale Register
x            GREG   0                   now in model coordinates [0..9]
y            GREG   0

%            Global Constants
WIDTH        IS     10                  0<=x<WIDTH
HEIGHT       IS     10                  0<=y<HEIGHT
STARTX       IS     1
STARTY       IS     1

%            Field Constants/Icon Ids
F            IS     0                   Free
B            IS     1                   Box
T            IS     2                   Target
TB           IS     B|T                 Box on Target
W            IS     4                   Wall


             LOC    Data_Segment
             GREG   @
GameBoard    BYTE   W,W,W,W,W,W,W,W,W,W
             BYTE   W,F,F,F,F,F,F,F,F,W
             BYTE   W,F,F,W,W,W,W,F,F,W
             BYTE   W,F,F,W,T,F,F,F,F,W
             BYTE   W,F,B,W,F,F,F,F,F,W
             BYTE   W,F,F,W,F,B,F,F,F,W
             BYTE   W,F,F,W,W,T,W,F,F,W
             BYTE   W,F,F,F,F,F,W,F,F,W
             BYTE   W,F,F,F,F,F,F,F,F,W
             BYTE   W,W,W,W,W,W,W,W,W,W
Counter		 OCTA	7
forTimer	 BYTE	"0","0","0","0"
					#30  30  30  30 
TargetsLeft  GREG   0

             LOC    #100
	     PREFIX :InitTargets:
%	     Initialize the variable TargetsLeft to the number of target fields without a box.
x            IS     $0
y            IS     $1
return       IS     $2
tmp          IS     $3

:InitTargets GET    return,:rJ
	     SET    :TargetsLeft,0
             SET    y,:HEIGHT
2H           SUB    y,y,1
             SET    x,:WIDTH
1H           SUB    x,x,1
             SET    tmp+1,x
             SET    tmp+2,y
             PUSHJ  tmp,:PosType
	     CMP    tmp,tmp,:T
	     ZSZ   tmp,tmp,1
	     ADD    :TargetsLeft,:TargetsLeft,tmp
             BP     x,1B
             BP     y,2B
             PUT    :rJ,return
             POP    0,0
	

             PREFIX :ShowField:
%            Description:  Receives the model coordinates (x,y),
%            determines what needs to be displayed,
%            and outputs the according icon on the display (GPutBmp).
%            Parameters (2): x, y (model coordinates)

x            IS     $0                  parameter 1
y            IS     $1                  parameter 2
return       IS     $2
tmp          IS     $3

:ShowField   GET    return,:rJ
             SET    tmp+1,x
             SET    tmp+2,y
             PUSHJ  tmp,:PosType

             SL     $255,x,16
             OR     $255,$255,y
             SL     $255,$255,5         multiplication by 32
	     SL	    tmp,tmp,32          Shift field id.
	     OR     $255,$255,tmp	Add field id to $255.
             TRAP   0,:GPutBmp,0
             PUT    :rJ,return
             POP    0,0

             PREFIX :ShowBoard          :
%            Description:  Output in a nested loop the complete GameBoard
%            calling the function ShowField with all the existing model
%            coordinates.

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

             PREFIX :ShowSokoban:
%            Beschreibung: Die Funktion gibt den Sokoban aus. Die aktuelle
%            Position wird aus den globalen Registern x und y entnommen.
%            (x,y) sind Modellkoordinaten, die vor der Nutzung für die
%            Ausgabe hier in Bildkoordinaten umgerechnet werden.
SokobanIcon  IS     5
:ShowSokoban SL     $255,:x,16          Combine x, and y for GPutBmp.
             OR     $255,$255,:y
             SL     $255,$255,5         multiplication by 32
             ORMH   $255,SokobanIcon   
             TRAP   0,:GPutBmp,0
             POP    0,0

             PREFIX :PosType:
%            Beschreibung: Überprüft ob eine gültige Modellkoorinaten
%            Position für Sokoban als Parameter übergeben wurde.
%            Parameter (2): x, y (Modellkoordinaten)
%            Rückgabewert (1): Wenn Position ungültig, :W, sonst Feldinhalt

x            IS     $0                  parameter 1
y            IS     $1                  parameter 2
base         IS     $2
offset       IS     $3
data         IS     $4
tmp          IS     $5

:PosType     BN     x,Outside
             BN     y,Outside
             CMP    tmp,x,:WIDTH
             BNN    tmp,Outside
             CMP    tmp,y,:HEIGHT
             BNN    tmp,Outside

             LDA    base,:GameBoard
             MULU   offset,y,:WIDTH
             ADDU   offset,offset,x
             LDBU   $0,base,offset	Lade Feldinhalt und return.
             POP    1,0
Outside      SET    $0,:W
             POP    1,0

             PREFIX :CheckMove:
%            Return Alone, if sokoban can move to this position;
%            return WithBox, if sokoban can move a box at this position;
%            return No otherwise.

%            Return Codes für CheckMove
:Alone        IS     1
:WithBox      IS     -1
:No           IS     0

dx           IS     $0                  parameter 1
dy           IS     $1                  parameter 2
return       IS     $2
tmp          IS     $3

:CheckMove   GET    return,:rJ
             ADD    tmp+1,:x,dx
             ADD    tmp+2,:y,dy
             PUSHJ  tmp,:PosType	Whats on the next field?
             ANDN   tmp,tmp,:T          Remove the Target bit.
             BOD    tmp,HasBox          Jump if the Box bit (1) is set.
             BNZ    tmp,No              Jump if not free.
             SET    $0,:Alone
             JMP    Done

No           SET    $0,:No
             JMP    Done

HasBox       2ADDU  tmp+1,dx,:x         Check next field.
             2ADDU  tmp+2,dy,:y
             PUSHJ  tmp,:PosType	Whats on the next next field?
             ANDN   tmp,tmp,:T          Remove the Target bit.
             BNZ    tmp,No              Jump if not free.
             NEG    $0,-(:WithBox)      Set a negative Value with NEG.

Done         PUT    :rJ,return
             POP    1,0

             PREFIX :MoveBox:
%            Sokoban at (:x,:y) moves box by going (dx,dy).
%            Box moves from (:x+dx,:y+dy) to (:x+2dx,:y+2dy)

dx           IS     $0                  parameter 1
dy           IS     $1                  parameter 2
x            IS     $2			box x
y            IS     $3			box y
return       IS     $4
id           IS     $5
base         IS     $6
offset       IS     $7
tmp          IS     $8

:MoveBox     GET    return,:rJ
             ADD    x,:x,dx             box position
             ADD    y,:y,dy
             LDA    base,:GameBoard
             MULU   offset,y,:WIDTH
             ADDU   offset,offset,x
             LDBU   id,base,offset      This should be a box.
             ANDN   id,id,:B            Remove the box bit.
             SR	    tmp,id,1            Move the target bit to the right
	     ADD    :TargetsLeft,:TargetsLeft,tmp 
             STBU   id,base,offset
             ADD    x,x,dx              Advance to new position.
             ADD    y,y,dy
             LDA    base,:GameBoard
             MULU   offset,y,:WIDTH
             ADDU   offset,offset,x
             LDBU   id,base,offset
             SR	    tmp,id,1            Move the target bit to the right
	     SUB    :TargetsLeft,:TargetsLeft,tmp 
             OR     id,id,:B            Add the box bit.
             STBU   id,base,offset
             SET    tmp+1,x
             SET    tmp+2,y
             PUSHJ  tmp,:ShowField      
             PUT    :rJ,return
             POP    0,0


             PREFIX :MoveSokoban:
%            Beschreibung: Funktion verändert die Position von Sokoban.
%            Parameter (2): dx, dy

dx           IS     $0                  parameter 1
dy           IS     $1                  parameter 2
return       IS     $2
tmp          IS     $3

:MoveSokoban GET    return,:rJ
             SET    tmp+1,dx
             SET    tmp+2,dy
             PUSHJ  tmp,:CheckMove
	     BZ	    tmp,No		
	     BP	    tmp,Alone
             SET    tmp+1,dx
             SET    tmp+2,dy
             PUSHJ  tmp,:MoveBox

Alone        SET    tmp+1,:x
             SET    tmp+2,:y
             PUSHJ  tmp,:ShowField      Clear the old position.
             ADDU   :x,:x,dx
             ADDU   :y,:y,dy
             PUSHJ  tmp,:ShowSokoban    Display the new position.

No           PUT    :rJ,return
             POP    0,0

             PREFIX :DoCommand:
%            Beschreibung: Funktion verarbeitet eine Benuztereingabe.
%            Parameter (1): Benutzereingabe

%            character constants
UP           IS     #126
DOWN         IS     #128
RIGHT        IS     #127
LEFT         IS     #125
%            other constants
STEP         IS     1

command      IS     $0                  parameter
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
             BNZ    tmp,1F
             NEG    dx,STEP
	     JMP    Done

1H	     CMP    tmp,command,'q'
	     BZ     tmp,Quit
             JMP    Illegal
	 
Done         GET    return,:rJ          backup of rJ (=> nested PUSHJ)
             SET    tmp+1,dx
             SET    tmp+2,dy
             PUSHJ  tmp,:MoveSokoban
Illegal      PUT    :rJ,return          restore rJ (=> nested PUSHJ)
             POP    0,0                 return zero

Quit	     SET    $0,1
	     POP    1,0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                Main program starts here
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
             PREFIX :
%            Initialize variables;
%            Repeat: Get a keyboard entry and process it.
tmp          IS     $10 # War vorher 0 
ewaitFlags	 IS		$0
counterAdr	 IS		$1
interReturn	 IS		$2
ewaitIsTimer IS		$3
tmp2		 IS		$4
counterVal	 IS		$5
counterAdr2	 IS		$6
counterVal2	 IS		$7

Main         SET    x,STARTX
             SET    y,STARTY
			 LDA	counterAdr,Counter
			 LDO	counterVal,counterAdr 
		     SET	$255,counterVal
			 TRAP	0,TCount,0
             PUSHJ  tmp,InitTargets
             PUSHJ  tmp,ShowBoard
             PUSHJ  tmp,ShowSokoban
Loop		 SET	ewaitFlags,17
			 SL		ewaitFlags,ewaitFlags,40
			 SET	$255,ewaitFlags
			 TRAP	0,EWait,0
			 SET	interReturn,$255
			 SET	ewaitIsTimer,16
			 SL		ewaitIsTimer,ewaitIsTimer,40
			 AND	tmp2,interReturn,ewaitIsTimer

			 BZ		tmp2,KGET
				
dek			 LDA	counterAdr,Counter
			 LDO	counterVal,counterAdr 
			 SET	tmp+5,counterVal
			 PUSHJ	tmp+4,:Start
			 SUB	counterVal,counterVal,1
			 STOU   counterVal,counterAdr,0
			 SET	$255,counterVal
			 TRAP	0,TCount,0
			 BNZ	counterVal,Loop
			 SET	$255,0
			 TRAP	0,TCount,0
			 LDA	counterAdr,Counter
			 LDO	counterVal,counterAdr 
			 SET	tmp+5,counterVal
			 PUSHJ	tmp+4,:Start
			 JMP	End
KGET		 TRAP   0,KGet,0            Get the next character.
             SET    tmp+1,$255
			 PUSHJ  tmp,DoCommand
			 BZ	    TargetsLeft,Success
			 BNZ    tmp,Fail
             JMP    Loop
End			 BZ	    TargetsLeft,Success
			 BNZ	TargetsLeft,Fail

Success	    SET    $255,(HEIGHT+1)*32 
			TRAP   0,GSetPos,0
			GETA    $255,1F
            TRAP    0,GPutStr,0
            TRAP    0,Halt,0
1H	   		BYTE   "Congratualtion! Job well done.",0

Fail	    SET    $255,(HEIGHT+1)*32 
			TRAP   0,GSetPos,0
			GETA    $255,1F
            TRAP    0,GPutStr,0
            TRAP    0,Halt,0
1H	    	BYTE   "Thanks for trying. See you!",0




			PREFIX	:Printer:
counter		IS	$0
n			IS	$1
localtmp	IS	$2
addr		IS	$3


:Start		SWYM
			SET	n,3
			LDA	addr,:forTimer
for			DIV	counter,counter,10
			GET	localtmp,:rR
			ADD	localtmp,localtmp,#30
			STB	localtmp,addr,n  #30 -> STB 5 --> 30 + 5 = 35 
			SUB	n,n,1
			BNN	n,for
print		SET	$255,(:HEIGHT+2)*32
			TRAP 0,:GSetPos,0
			SET	$255,addr
			SWYM
			TRAP 0,:GPutStr,0
			POP	0,0
			
			PREFIX :
		