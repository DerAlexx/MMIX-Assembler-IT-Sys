%	Thread Test: Race Condition
# Alexander Michael Westphal und Paul Schroeder
%	Constants
		% Booleans
TRUE		IS	1
FALSE		IS	0

		% Traps
KWait		IS	#3A
TCreate		IS	#80
TStatus		IS	#81			1
TKill		IS	#82
SSend		IS	#83
SReceive	IS	#84

		% Signals
SigStart	IS	1
SigHalt		IS	2


%	Variables
		LOC	Data_Segment
		GREG	@
Lock		OCTA
MeStr		BYTE	"!.",0
YouStr		BYTE	"..",0
Done		BYTE	#0A,"Main Program halted",#0A,0
LF		BYTE	#0A,0
Char		BYTE	'A'		Shared variable
Stop		OCTA	FALSE
Random		OCTA	1234567		Some random seed for the random number generator		

%	Code
		LOC	#100

%	Main Program
%	Set the Stop variable to FALSE.
%	Start two threads, giving them two different strings as parameters.
%	Wait for keyboard input.
%	Sets the Stop variable to TRUE.
%	Wait for the two treads to terminate.
%	Halt.

t		IS	$0

Main		STCO	FALSE,Stop
		
		SET		t+2,0
		LDA		t+1,:Lock
		STO		t+2,t+1

		TRAP	0,SSend,SigStart	Send one signal before threads are waiting

		LDA	t,MeStr
		GETA	$255,Thread
		TRAP	0,TCreate,t

		LDA	t,YouStr
		GETA	$255,Thread
		TRAP	0,TCreate,t

		TRAP	0,SSend,SigStart	Send one signal after threads have started
		
		TRAP	0,KWait,0		Wait for keyboard input.

		STCO	TRUE,Stop		Set the Stop variable.

		TRAP	0,SReceive,SigHalt		Wait for one thread to terminate.
		TRAP	0,SReceive,SigHalt		Wait for the other thread to terminate.

		LDA	$255,Done	
		TRAP	0,Fputs,StdOut		Output a final message.

		TRAP	0,Halt,0		Terminate.


		PREFIX	:Thread:

%	Thread routine
%	Expect a string parameter in $0 (either MeStr or YouStr).
%	WHILE NOT Stop DO
%		Load Char;
%		Insert it into the string;
%		Print the string;
%		Increment Char cyclic in the range A to Z;
%		Store Char;
%	END WHILE.
%	Send Signal SigHalt.
%	Halt.

str		IS	$0
c		IS	$1
t		IS	$2
tmp		IS	$3

:Thread		TRAP	0,:SReceive,:SigStart		Wait until Main sends the start signal

Loop	LDO	t,:Stop				Check the Stop variable
		BNZ	t,End
		
		LDA		t+3,:Lock
		SET     tmp,0
		PUT     :rP,tmp
		CSWAP   tmp,t+3,0
		BZ      tmp,Loop
		STO		tmp,t+3,0
			
		LDBU	c,:Char				Load the shared character.
		STBU	c,str,1				Store it in the private string.

		SET	$255,str			Output the string.
		TRAP	0,:Fputs,:StdOut

		ADD	c,c,1				Advance to the next character.
		CMP	t,c,'Z'			        Check for the last character Z.
		PBNP	t,1F				If yes:
		LDA	$255,:LF


			
		TRAP	0,:Fputs,:StdOut		Output a new line.
		SET	c,'A'			        Start over with the first character A.
1H		STBU	c,:Char	Update shared character.		
		LDA	t+3,:Lock
		SET t+4,0
		STO	t+4,t+3	

		PUSHJ	t,:Workload
		JMP	Loop
End		TRAP	0,:SSend,:SigHalt		Signal the Main program the end of the thread.
		TRAP	0,:Halt,0			Terminate the thread.



		PREFIX	:Workload:
		% Spend some time (outside the critical region)
		% to give the poor other thread a chance.
i		IS	$0
t		IS	$1

:Workload	LDOU	t,:Random	Introducing some randomness.
		MULU	t,t,60
		ADD	t,t,1
		STOU	t,:Random
		GET	i,:rI		The remaining quantum.
		SRU	i,i,1		half of the remaining quantum
		BZ	i,End
		DIV	t,t,i
		GET	t,:rR		Some random number 0<= t < rI/2
		BZ	t,End
1H		SUB	t,t,1		Wasting some cycles.
		BP	t,1B
End		POP	0,0



