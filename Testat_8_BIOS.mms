%	this is a generic MMIX BIOS
%	it is considert to be in ROM mapped
%	at physical address 0000 0000 0000 0000
%	used with 
%	virtual address 8000 0000 0000 0000

%	Definition of Constants

%	Physical Addresses and Interrupt Numbers of Devices
		PREFIX	:RAM:
HI		IS	#8000
MH		IS	#0001

		PREFIX	:FLASH:
HI			IS	#8000		physical address
MH			IS	#0002
USERHI		IS	#2000  		virtual mapped address
USERML 		IS	#0001

		PREFIX	:VRAM:
HI			IS	#8002

		PREFIX	:IO:
HI			IS	#8001
Keyboard 	IS	#00
Screen		IS	#08
Mouse		IS	#10
GPU			IS	#20
Timer		IS	#60
Serial		IS	#80
Sevensegment	IS	#90
Led0		IS	#B0
Led1		IS	#B8
Led2		IS	#C0
Led3		IS	#C8
Disk		IS	#D0

		PREFIX	:Interrupt:

Keyboard	IS	40
Screen		IS	41
Mouse		IS	42	
GPU			IS	43
Timer		IS	44
SerialIn 	IS	45
SerialOut	IS	46
Disk		IS	47
Button		IS	44
Button1		IS	49
Button2		IS	50
Button3		IS	51

%	Code

		.section    .text,"ax",@progbits		
		LOC	#8000000000000000

		PREFIX :Boot:
tmp		IS	$0
	
%	page table setup (see small model in address.howto)

:Main	IS		@  dummy	%Main, to keep mmixal happy
:Boot	GETA	tmp,:DTrap	%set dynamic- and forced-trap  handler
		PUT		:rTT,tmp
		GETA	tmp,:FTrap
		PUT		:rT,tmp
		PUSHJ	tmp,:memory	%initialize the memory setup
	
		PUSHJ	tmp,:gui	%initialize the GUI setup

		GET		tmp,:rQ
		PUT		:rQ,0		%clear interrupts

%	here we start a loaded user program
%       rXX should be #FB0000FF = UNSAVE $255
%	rBB is coppied to $255, it should be the place in the stack 
%	where UNSAVE will find its data
%	rWW should be the entry point in the main program, 
%	thats where the program
%	continues after the UNSAVE.
%	If no program is loaded, rXX will be 0, that is TRAP 0,Halt,0
%	and we end the program before it has started in the Trap handler.

		NEG		$255,1	% enable interrupt $255->rK with resume 1
		RESUME	1		% loading a file sets up special registers for that

%	Dynamic Trap Handling

		PREFIX	:DTrap:
	
:DTrap	PUSHJ	$255,Handler
		PUT		:rJ,$255
		NEG		$255,1		% enable interrupt $255->rK with resume 1
		RESUME	1

tmp		IS	$0	
ibits	IS	$1
inumber IS	$2
base	IS	$3

Handler GET 	ibits,:rQ
		SUBU	tmp,ibits,1			%from xxx...xxx1000 to xxx...xxx0111
		SADD	inumber,tmp,ibits	%position of lowest bit
		ANDN	tmp,ibits,tmp		%the lowest bit
    	ANDN	tmp,ibits,tmp		%delete lowest bit
		PUT		:rQ,tmp				%and return to rQ
		SLU		tmp,inumber,2		%scale
        GETA	base,Table			%and jump
		GO		tmp,base,tmp

	
Table	JMP PowerFail		%0	the machine bits
		JMP MemParityError	%1
		JMP MemNonExiistent	%2
		JMP Unhandled       %3
		JMP Reboot   		%4
		JMP Unhandled		%5
		JMP PageTableError  %6
		JMP Intervall		%7

		JMP Unhandled  %8
		JMP Unhandled  %9
		JMP Unhandled  %10
		JMP Unhandled  %11
		JMP Unhandled  %12
		JMP Unhandled  %13
		JMP Unhandled  %14
		JMP Unhandled  %15

		JMP Unhandled  %16
		JMP Unhandled  %17
		JMP Unhandled  %18
		JMP Unhandled  %19
		JMP Unhandled  %20
		JMP Unhandled  %21
		JMP Unhandled  %22
		JMP Unhandled  %23
		JMP Unhandled  %24
		JMP Unhandled  %25
		JMP Unhandled  %26
		JMP Unhandled  %27
		JMP Unhandled  %28
		JMP Unhandled  %29
		JMP Unhandled  %30
		JMP Unhandled  %31

		JMP Privileged		%32	% Program bits
		JMP Security		%33
		JMP RuleBreak		%34
		JMP KernelOnly		%35
		JMP TanslationBypass	%36
		JMP NoExec		%37
		JMP NoWrite		%38
		JMP NoRead		%39

		JMP Ignore     %40 formerly registered: Keyboard
		JMP Screen     %41
		JMP Mouse      %42
		JMP GPU	       %43
		JMP Timer      %44
		JMP SerialIn   %45
		JMP SerialOut  %46
		JMP Disk       %47

		JMP Button     %48
		JMP Unhandled  %49
		JMP Unhandled  %50
		JMP Unhandled  %51
		JMP Unhandled  %52
		JMP Unhandled  %53
		JMP Unhandled  %54
		JMP Unhandled  %55
		JMP Unhandled  %56
		JMP Unhandled  %57
		JMP Unhandled  %58
		JMP Unhandled  %59
		JMP Unhandled  %60
		JMP Unhandled  %61
		JMP Unhandled  %62
		JMP Unhandled  %63
		JMP Ignore     %64  rQ was zero

%	Default Dynamic Trap Handlers

Unhandled	GETA	tmp,1F
			SWYM	tmp,5		% tell the debugger
			POP	0,0
1H		BYTE    "DEBUG Trap unhandled",0

Ignore		POP	0,0

%	Required Dynamic Trap Handlers

Reboot	GETA	tmp,1F
		SWYM	tmp,5		% tell the debugger
		JMP	:Boot
1H		BYTE    "DEBUG Rebooting",0


MemParityError	GETA	tmp,1F
		SWYM	tmp,5		% tell the debugger
		POP	0,0
1H		BYTE    "DEBUG Memory parity error",0


MemNonExiistent	GETA	tmp,1F
		SWYM	tmp,5		% tell the debugger
		POP	0,0
1H		BYTE    "DEBUG Access to nonexistent Memory",0


PowerFail	GETA	tmp,1F
		SWYM	tmp,5		% tell the debugger
		POP	0,0
1H		BYTE    "DEBUG Power Fail - switching to battery ;-)",0


PageTableError	GETA	tmp,1F
		SWYM	tmp,5		% tell the debugger
		POP	0,0
1H		BYTE    "DEBUG Error in page table structure",0


Intervall	GETA	tmp,1F
		SWYM	tmp,5		% tell the debugger
		POP	0,0
1H		BYTE    "DEBUG Intervall Counter rI is zero",0



Privileged	GETA	tmp,1F
		SWYM	tmp,5		% tell the debugger
		POP	0,0
1H		BYTE    "DEBUG Privileged Instruction",0


Security	GETA	tmp,1F
		SWYM	tmp,5		% tell the debugger
		POP	0,0
1H		BYTE    "DEBUG Security violation",0


RuleBreak	GETA	tmp,1F
		SWYM	tmp,5		% tell the debugger
		POP	0,0
1H		BYTE    "DEBUG Illegal Instruction",0


KernelOnly	GETA	tmp,1F
		SWYM	tmp,5		% tell the debugger
		POP	0,0
1H		BYTE    "DEBUG Instruction for kernel use only",0


TanslationBypass GETA	tmp,1F
		SWYM	tmp,5		% tell the debugger
		POP	0,0
1H		BYTE    "DEBUG Illegal access to negative address",0


NoExec		GETA	tmp,1F
		SWYM	tmp,5		% tell the debugger
		POP	0,0
1H		BYTE    "DEBUG Missing execute permission",0


NoWrite		GETA	tmp,1F
		SWYM	tmp,5		% tell the debugger
		POP	0,0
1H		BYTE    "DEBUG  Missing write permission",0


NoRead		GETA	tmp,1F
		SWYM	tmp,5		% tell the debugger
		POP	0,0
1H		BYTE    "DEBUG Missing read permission",0


%	Devicespecific Dynamic Trap Handlers

		PREFIX	Keyboard:

base		IS	$1
data		IS	$2
count		IS	$3
return		IS	$4
tmp			IS	$5
%	echo a character from the keyboard
:DTrap:Keyboard	SETH	base,:IO:HI    			
		LDO	data,base,:IO:Keyboard	keyboard status/data
		BN	data,1F	
		SR	count,data,32
		AND	count,count,#FF
		BZ	count,1F	
		GET	return,:rJ
		AND	tmp+1,data,#FF
		PUSHJ	tmp,:ScreenC
		PUT	:rJ,return
1H		POP	0,0

:DTrap:Screen   IS 	:DTrap:Ignore   
:DTrap:Mouse	IS	:DTrap:Ignore 
:DTrap:GPU		IS	:DTrap:Ignore
:DTrap:Timer    IS	:DTrap:Ignore
:DTrap:Disk     IS	:DTrap:Ignore 
:DTrap:SerialIn	IS	:DTrap:Ignore 
:DTrap:SerialOut IS	:DTrap:Ignore
:DTrap:Button   IS	:DTrap:Ignore 


%	Forced Trap Handling

 		PREFIX :FTrap:

%		Entry point for a forced TRAP
:FTrap		PUSHJ	$255,Handler
		PUT	:rJ,$255
		NEG	$255,1		%enable interrupt $255->rK with resume 1
		RESUME	1


tmp		IS	$0
instr	IS	$1
Y		IS	$2

Handler		GET	instr,:rXX
		BNN	instr,1F
		SRU	tmp,instr,24       
		AND	tmp,tmp,#FF	%the opcode
		BZ	tmp,Trap		
1H		POP	0,0		%not a TRAP or ropcode>=0
       
%       Handle a TRAP Instruction
Trap    SRU	Y,instr,8
		AND	Y,Y,#FF		%the Y value (the function code)
		GETA	tmp,Table
		SL	Y,Y,2
		GO	tmp,tmp,Y	%Jump into the Trap Table
	
Table	JMP	Halt		%0
		JMP	Fopen		%1
		JMP	Fclose		%2
		JMP	Fread		%3
		JMP	Fgets		%4
		JMP	Fgetws		%5
		JMP	Fwrite		%6
		JMP	Fputs		%7 
		JMP	Fputws		%8
		JMP	Fseek		%9
		JMP	Ftell		%a
		JMP	Unhandled	%b
		JMP	Unhandled	%c
		JMP	Unhandled	%d
		JMP	Unhandled	%e
		JMP	Unhandled	%f


		JMP	TWait		%10
		JMP	TDate		%11
		JMP	TTimeOfDay	%12
		JMP	Unhandled	%13
		JMP	Unhandled	%14
		JMP	Unhandled	%15
		JMP	Unhandled	%16
		JMP	Unhandled	%17
		JMP	Unhandled	%18
		JMP	Unhandled	%19
		JMP	Unhandled	%1a
		JMP	Unhandled	%1b
		JMP	Unhandled	%1c
		JMP	Unhandled	%1d
		JMP	Unhandled	%1e
		JMP	GPutBmp		%1f


		JMP	VPut		%20
		JMP	VGet		%21
		JMP	GSize		%22
		JMP	GSetWH 		%23
		JMP	GSetPos		%24
		JMP	GSetTextColor	%25
		JMP	GSetFillColor	%26
		JMP	GSetLineColor	%27

		JMP	GPutPixel	%28
		JMP	GPutChar	%29
		JMP	GPutStr		%2A
		JMP	GLine		%2B
		JMP	GRectangle	%2C
		JMP	GBitBlt		%2D
		JMP	GBitBltIn	%2E
		JMP	GBitBltOut	%2F

		JMP	MWait		%30
		JMP	Unhandled	%31
		JMP	Unhandled	%32
		JMP	Unhandled	%33
		JMP	Unhandled	%34
		JMP	Unhandled	%35
		JMP	Unhandled	%36
		JMP	Unhandled	%37
		JMP	KGet		%38
		JMP	KStatus	    %39
		JMP	KWait		%3a
		JMP	Unhandled	%3b
		JMP	Unhandled	%3c
		JMP	Unhandled	%3d
		JMP	Unhandled	%3e
		JMP	Unhandled	%3f

		JMP	BWait		%40
		JMP	Unhandled	%41
		JMP	Unhandled	%42
		JMP	Unhandled	%43
		JMP	Unhandled	%44
		JMP	Unhandled	%45
		JMP	Unhandled	%46
		JMP	Unhandled	%47
		JMP	Unhandled	%48
		JMP	Unhandled	%49
		JMP	Unhandled	%4a
		JMP	Unhandled	%4b
		JMP	Unhandled	%4c
		JMP	Unhandled	%4d
		JMP	Unhandled	%4e
		JMP	Unhandled	%4f

		JMP	SSet		%50
		JMP	SDecimal	%51
		JMP	Unhandled	%52
		JMP	Unhandled	%53
		JMP	Unhandled	%54
		JMP	Unhandled	%55
		JMP	Unhandled	%56
		JMP	Unhandled	%57
		JMP	Unhandled	%58
		JMP	Unhandled	%59
		JMP	Unhandled	%5a
		JMP	Unhandled	%5b
		JMP	Unhandled	%5c
		JMP	Unhandled	%5d
		JMP	Unhandled	%5e
		JMP	Unhandled	%5f

		JMP	EWait		%60    ****** Ihr neuer Forced TRAP EWait ******
		JMP	Unhandled	%61
		JMP	Unhandled	%62
		JMP	Unhandled	%63
		JMP	Unhandled	%64
		JMP	Unhandled	%65
		JMP	Unhandled	%66
		JMP	Unhandled	%67
		JMP	Unhandled	%68
		JMP	Unhandled	%69
		JMP	Unhandled	%6a
		JMP	Unhandled	%6b
		JMP	Unhandled	%6c
		JMP	Unhandled	%6d
		JMP	Unhandled	%6e
		JMP	Unhandled	%6f
		JMP	Unhandled	%70
		JMP	Unhandled	%71
		JMP	Unhandled	%72
		JMP	Unhandled	%73
		JMP	Unhandled	%74
		JMP	Unhandled	%75
		JMP	Unhandled	%76
		JMP	Unhandled	%77
		JMP	Unhandled	%78
		JMP	Unhandled	%79
		JMP	Unhandled	%7a
		JMP	Unhandled	%7b
		JMP	Unhandled	%7c
		JMP	Unhandled	%7d
		JMP	Unhandled	%7e
		JMP	Unhandled	%7f

		JMP	Unhandled	%80
		JMP	Unhandled	%81
		JMP	Unhandled	%82
		JMP	Unhandled	%83
		JMP	Unhandled	%84
		JMP	Unhandled	%85
		JMP	Unhandled	%86
		JMP	Unhandled	%87
		JMP	Unhandled	%88
		JMP	Unhandled	%89
		JMP	Unhandled	%8a
		JMP	Unhandled	%8b
		JMP	Unhandled	%8c
		JMP	Unhandled	%8d
		JMP	Unhandled	%8e
		JMP	Unhandled	%8f
		JMP	Unhandled	%90
		JMP	Unhandled	%91
		JMP	Unhandled	%92
		JMP	Unhandled	%93
		JMP	Unhandled	%94
		JMP	Unhandled	%95
		JMP	Unhandled	%96
		JMP	Unhandled	%97
		JMP	Unhandled	%98
		JMP	Unhandled	%99
		JMP	Unhandled	%9a
		JMP	Unhandled	%9b
		JMP	Unhandled	%9c
		JMP	Unhandled	%9d
		JMP	Unhandled	%9e
		JMP	Unhandled	%9f

		JMP	Unhandled	%a0
		JMP	Unhandled	%a1
		JMP	Unhandled	%a2
		JMP	Unhandled	%a3
		JMP	Unhandled	%a4
		JMP	Unhandled	%a5
		JMP	Unhandled	%a6
		JMP	Unhandled	%a7
		JMP	Unhandled	%a8
		JMP	Unhandled	%a9
		JMP	Unhandled	%aa
		JMP	Unhandled	%ab
		JMP	Unhandled	%ac
		JMP	Unhandled	%ad
		JMP	Unhandled	%ae
		JMP	Unhandled	%af
		JMP	Unhandled	%b0
		JMP	Unhandled	%b1
		JMP	Unhandled	%b2
		JMP	Unhandled	%b3
		JMP	Unhandled	%b4
		JMP	Unhandled	%b5
		JMP	Unhandled	%b6
		JMP	Unhandled	%b7
		JMP	Unhandled	%b8
		JMP	Unhandled	%b9
		JMP	Unhandled	%ba
		JMP	Unhandled	%bb
		JMP	Unhandled	%bc
		JMP	Unhandled	%bd
		JMP	Unhandled	%be
		JMP	Unhandled	%bf

		JMP	Unhandled	%c0
		JMP	Unhandled	%c1
		JMP	Unhandled	%c2
		JMP	Unhandled	%c3
		JMP	Unhandled	%c4
		JMP	Unhandled	%c5
		JMP	Unhandled	%c6
		JMP	Unhandled	%c7
		JMP	Unhandled	%c8
		JMP	Unhandled	%c9
		JMP	Unhandled	%ca
		JMP	Unhandled	%cb
		JMP	Unhandled	%cc
		JMP	Unhandled	%cd
		JMP	Unhandled	%ce
		JMP	Unhandled	%cf
		JMP	Unhandled	%d0
		JMP	Unhandled	%d1
		JMP	Unhandled	%d2
		JMP	Unhandled	%d3
		JMP	Unhandled	%d4
		JMP	Unhandled	%d5
		JMP	Unhandled	%d6
		JMP	Unhandled	%d7
		JMP	Unhandled	%d8
		JMP	Unhandled	%d9
		JMP	Unhandled	%da
		JMP	Unhandled	%db
		JMP	Unhandled	%dc
		JMP	Unhandled	%dd
		JMP	Unhandled	%de
		JMP	Unhandled	%df

		JMP	Unhandled	%e0
		JMP	Unhandled	%e1
		JMP	Unhandled	%e2
		JMP	Unhandled	%e3
		JMP	Unhandled	%e4
		JMP	Unhandled	%e5
		JMP	Unhandled	%e6
		JMP	Unhandled	%e7
		JMP	Unhandled	%e8
		JMP	Unhandled	%e9
		JMP	Unhandled	%ea
		JMP	Unhandled	%eb
		JMP	Unhandled	%ec
		JMP	Unhandled	%ed
		JMP	Unhandled	%ee
		JMP	Unhandled	%ef
		JMP	Unhandled	%f0
		JMP	Unhandled	%f1
		JMP	Unhandled	%f2
		JMP	Unhandled	%f3
		JMP	Unhandled	%f4
		JMP	Unhandled	%f5
		JMP	Unhandled	%f6
		JMP	Unhandled	%f7
		JMP	Unhandled	%f8
		JMP	Unhandled	%f9
		JMP	Unhandled	%fa
		JMP	Unhandled	%fb
		JMP	Unhandled	%fc
		JMP	Unhandled	%fd
		JMP	Unhandled	%fe
		JMP	Unhandled	%ff


%	Default TRAP Handlers
Unhandled	GETA	tmp,1F
		SWYM	tmp,5		% inform the debugger
		NEG	tmp,1
		PUT	:rBB,tmp	%return -1
		POP	0,0
1H		BYTE	"DEBUG Unhandled TRAP",0

Halt	GETA	tmp,1F
		SWYM	tmp,5		% inform the debugger
idle	SYNC	4			%go to power save mode
		GET	tmp,:rQ
		BZ	tmp,idle
		PUSHJ	tmp,:DTrap:Handler
		JMP	idle			 % and loop idle
1H		BYTE	"DEBUG Program halted",0

		PREFIX :

%	Devicespecific TRAP Handlers

%	MMIXware Traps


:FTrap:Fopen	IS	:FTrap:Unhandled

% Here |handle| is a
% one-byte integer, |name| is a string, and |mode| is one of the
% values TextRead, TextWrite, BinaryRead, BinaryWrite,
% BinaryReadWrite. An Fopen call associates |handle| with the
% external file called |name| and prepares to do input and/or output
% on that file. It returns 0 if the file was opened successfully; 
% otherwise returns the value~$-1$. If |mode| is TextWrite, 
% BinaryWrite, or BinaryReadWrite,
% any previous contents of the named file are discarded. If |mode| is
% TextRead or TextWrite, the file consists of ``lines'' terminated
% by ``newline'' characters, and it is said to be a text file; 
% otherwise the file consists of uninterpreted bytes, and it is said 
% to be a binary file.


:FTrap:Fclose	IS	:FTrap:Unhandled

% If the given file handle has been opened, it is
% closed---no longer associated with any file. 
% Again the result is 0 if % successful, 
% or $-1$ if the file was already closed or unclosable.


:FTrap:Fread	IS	:FTrap:Unhandled

% The next |size| characters are read into MMIX's memory starting 
% at address |buffer|. If an error occurs, the value |-1-size| is 
% returned; otherwise, if the end of file does not intervene, 
% 0 is returned; otherwise the negative value |n-size| is returned,
% where |n| is the number of characters successfully read and stored.

		PREFIX	:Fgets:
% Characters are read into MMIX's memory starting at address |buffer|,
% until either |size-1| characters have been read and stored or a 
% newline character has been read and stored; the next byte in memory
% is then set to zero.
% If an error or end of file occurs before reading is complete, the 
% memory contents are undefined and the value $-1$ is returned; 
% otherwise the number of characters successfully read and stored is 
% returned.

buffer		IS	$0
size		IS	$1
n			IS	$2
return		IS	$3
tmp			IS	$4


:FTrap:Fgets	GET	tmp,:rXX	% instruction
		AND     tmp,tmp,#FF	% Z value 
        BNZ     tmp,Error	% this is not StdIn


%		Fgets from the keyboard
	    GET	tmp,:rBB	% get the $255 parameter: buffer, size
		LDO	buffer,tmp,0	
        LDO size,tmp,8
		SET	n,0	
		GET	return,:rJ
		JMP	1F

Loop	PUSHJ	tmp,:KeyboardC	% read blocking from the keyboard
		STBU	tmp,buffer,n
		ADDU	n,n,1
		CMP	tmp,tmp,10	% newline
		BZ	tmp,Done
1H		SUB	size,size,1
		BP	size,Loop

Done	SET	tmp,0		% terminating zero byte
		STBU	tmp,buffer,n
		PUT	:rBB,n   	% result
		PUT	:rJ,return
		POP	0,0

Error	NEG	tmp,1
		PUT	:rBB,tmp
		POP	0,0


:FTrap:Fgetws	IS	:FTrap:Unhandled


		PREFIX	:Fwrite:

% The next |size| characters are written from MMIX's memory starting 
% at address |buffer|. If no error occurs, 0~is returned;
% otherwise the negative value |n-size| is returned, 
% where |n|~is the number of characters successfully written.

%		we work with a pointer to the end of the buffer (last) 
%		and a negative offset towards this point (tolast)
%		to have only a single ADD in the Loop.

last		IS	$0	buffer+size
tolast		IS	$1	n-size
n			IS	$1
return		IS	$2
tmp			IS	$3

:FTrap:Fwrite 	GET	tmp,:rXX	% instruction
		AND     tmp,tmp,#FF	% Z value 
        BZ      tmp,Error	% this is stdin
        CMP     tmp,tmp,2		% StdOut or StdErr
        BP	tmp,Error	% this is a File

%       	Fwrite to the screen

	    GET	tmp,:rBB	% get the $255 parameter: buffer, size
		LDO	last,tmp,0	% buffer
        LDO     tolast,tmp,8	% size
		ADDU	last,last,tolast
		NEG	tolast,tolast
		GET	return,:rJ
		JMP	1F

Loop	LDBU    tmp+1,last,tolast
		PUSHJ	tmp,:ScreenC
		ADD	tolast,tolast,1
1H      BN	tolast,Loop

		PUT	:rBB,tolast
		PUT	:rJ,return
		POP	0,0

Error	NEG	tmp,1
		PUT	:rBB,tmp
		POP	0,0


		
		PREFIX	:Fputs:
% One-byte characters are written from MMIX's memory to the file, 
% starting at address string, up to but not including the first 
% byte equal to zero. The number of bytes written is returned, 
% or $-1$ on error.

string		IS	$0
n			IS	$1
return		IS	$2
tmp			IS	$3

:FTrap:Fputs 	GET	tmp,:rXX	% instruction
		AND     tmp,tmp,#FF	% Z value 
        BZ      tmp,Error	% this is stdin
        CMP     tmp,tmp,2		% StdOut or StdErr
        BP	tmp,Error	% this is a File

%       	Fputs to the screen

		GET	return,:rJ
	    GET	string,:rBB	%get the $255 parameter
		SET	n,0
		JMP 	1F

Loop	PUSHJ	tmp,:ScreenC
        ADD	n,n,1
1H		LDBU	tmp+1,string,n
        BNZ     tmp+1,Loop

		PUT	:rJ,return
		PUT	:rBB,n
		POP	0,0

Error	NEG	tmp,1
		PUT	:rBB,tmp
		POP	0,0
	

:FTrap:Fputws	IS	:FTrap:Unhandled

:FTrap:Fseek	IS	:FTrap:Unhandled

:FTrap:Ftell	IS	:FTrap:Unhandled

%		END of MMIXware

%		Timer

		PREFIX	:TWait:
%		$255 	specifies the number of ms to wait
t		IS	#10	%offset of Timer t register

tbit	IS	$0
bits	IS	$1
tmp		IS	$2
ms		IS	$3
base	IS	$4

:FTrap:TWait	SETH	base,:IO:HI
		SET	tbit,1
		SL	tbit,tbit,:Interrupt:Timer
		GET	bits,:rQ
		GET	ms,:rBB		%ms to wait
		BNP	ms,Done

		ANDN	tmp,bits,tbit
		PUT		:rQ,tmp		%Clear Timer Interrupt
		STTU	ms,base,:IO:Timer+t

Loop	SYNC	4
		GET	bits,:rQ
		AND	tmp,bits,tbit
		BZ	tmp,Loop		%test Timer bit
		
Done	STCO	0,base,:IO:Timer+t  %switch Timer off
		ANDN	bits,bits,tbit
		PUT	:rQ,bits
		PUT	:rBB,0
		POP	0,0


		PREFIX	:TDate:		
%		Get the current date in format YYYYMMDW

base	IS	$1
date	IS	$0
W		IS	$2
D		IS	$3
M		IS	$4
YY		IS	$5
tmp		IS	$6

:FTrap:TDate	SETH    base,:IO:HI
		LDOU	date,base,:IO:Timer	  %YYMDXXXW
		AND	W,date,#FF	  %W
		SRU	date,date,32
		AND	D,date,#FF	  %D
		SRU	date,date,8
		AND	M,date,#FF	  %M
		SRU	YY,date,8	  %YY
		
		SL	D,D,8	 
		OR	date,W,D
		SL	M,M,16
		OR	date,date,M
		SL	YY,YY,32
		OR	date,date,YY
		PUT	:rBB,date		  %YYYYMMDW
		POP	0,0


		PREFIX	:TTimeOfDay:
%		Read the current Time in ms since midnight
ms		IS	#0C

base		IS	$0
current		IS	$1

:FTrap:TTimeOfDay	SETH    base,:IO:HI
		LDTU	current,base,:IO:Timer+ms
		PUT	:rBB,current
		POP	0,0



%		Video RAM
	
		PREFIX	:VPut:

%		Put one pixel on the graphics display. 
%		In $255 we have in the Hi 32 bit the RGB value
%               and in the low 32 bit the offset into the video ram

tmp		IS	$0
rgb		IS	$1
offset	IS	$2



:FTrap:VPut	GET	tmp,:rBB	%get the $255 parameter: RGB, offset
	      	SRU     rgb,tmp,32
			SLU	offset,tmp,32
			SRU	offset,offset,32	
            SETH    tmp,:VRAM:HI	
            STTU	rgb,tmp,offset
            PUT	:rBB,0		
	      	POP	0,0

		PREFIX	:VGet:

%		Return one pixel at the given offset from the graphics display. 
%		In $255 we have in the low 32 bit the offset into the video ram

tmp		IS	$0
rgb		IS	$1
offset	IS	$2



:FTrap:VGet	GET	tmp,:rBB	%get the $255 parameter: RGB, offset
		SLU	offset,tmp,32
		SRU	offset,offset,32	
        SETH    tmp,:VRAM:HI	
		LDTU	rgb,tmp,offset
        PUT	:rBB,rgb		
	    POP	0,0
	      	
%		GPU
		
		PREFIX	:GPU:CMD:
CHAR	IS	#0100
RECT	IS	#0200
LINE	IS	#0300
BLT		IS	#0400
BLTIN	IS	#0500
BLTOUT	IS	#0600
BLTDIB	IS	#0700

		PREFIX	:GPU:
CMD		IS	0
AUX		IS	1
XY2		IS	4
X2		IS	4
Y2		IS	6
WHXY	IS	8
WH		IS	8
W		IS	8
H		IS	#0A
XY		IS	#0C
X		IS	#0C
Y		IS	#0E
BBA		IS	#10
TBCOLOR		IS	#18	Text Background Color
TFCOLOR		IS	#1C	Text Foreground Color	
FCOLOR		IS	#20	Fill Color
LCOLOR		IS	#24	Line Color
CWH		IS	#28	Character Width and Height
CW		IS	#28
CH		IS	#2A
FW		IS	#30	Frame and Screen Width and Height
FH		IS	#32
SW		IS	#34
SH		IS	#36

		PREFIX	:GSize:

tmp		IS	$0

:FTrap:GSize    SETH    tmp,:IO:HI		
		LDTU	tmp,tmp,:IO:GPU+:GPU:FW  
		PUT	:rBB,tmp
	    POP	0,0
			
		PREFIX	:GSet

tmp		IS	$0
base	IS	$1
%		Set the width and height for the next Rectangle
:FTrap:GSetWH	GET	tmp,:rBB		%get the $255 parameter: w,h
              	SETH    base,:IO:HI	%base address of gpu -20
              	STTU	tmp,base,:IO:GPU+:GPU:WH
				POP	0,0

%		Set the position for the next GChar,GPutStr,GLine Operation
:FTrap:GSetPos	GET	tmp,:rBB		%get the $255 parameter: x,y
              	SETH    base,:IO:HI	%base address of gpu -20
              	STTU	tmp,base,:IO:GPU+:GPU:XY
				POP	0,0

:FTrap:GSetTextColor GET tmp,:rBB	% background RGB, foreground RGB
              	SETH    base,:IO:HI	
              	STOU	tmp,base,:IO:GPU+:GPU:TBCOLOR
				POP	0,0
	     	
:FTrap:GSetFillColor GET tmp,:rBB	% RGB
              	SETH    base,:IO:HI	
              	STTU	tmp,base,:IO:GPU+:GPU:FCOLOR
				POP	0,0


:FTrap:GSetLineColor GET tmp,:rBB	% RGB
              	SETH    base,:IO:HI	%base address of gpu -20
              	STTU	tmp,base,:IO:GPU+:GPU:LCOLOR
				POP	0,0

		PREFIX	:GPutPixel obsolete
%		Put one pixel on the graphics display. 
%		In $255 we have in the Hi 32 bit the RGB value
%               and in the low 32 bit the x y value as two WYDEs

param	IS	$0
x		IS	$1
y		IS	$2
width	IS	$3
tmp		IS	$4
		% convert x,y from rBB to an offset and put back in rBB
		% the call VPut
:FTrap:GPutPixel GET	param,:rBB
		SLU	x,param,32
		SRU	x,x,48
		SLU	y,param,48
		SRU	y,y,48
		SETH	tmp,:IO:HI
		LDWU	tmp,tmp,:IO:GPU+:GPU:FW	width
		MUL	y,y,tmp
		ADD	x,x,y		((y*width)+x)
		SL	x,x,2		*4 for TETRA
		SRU	param,param,32
		SLU	param,param,32	clear low TETRA
		OR	param,param,x   add offset
		PUT	:rBB,param
		JMP	:FTrap:VPut	

		PREFIX	:GPutChar
%		Put one character on the graphics display. 
%		In $255 we have in the Hi 32 bit the ASCII value
%               and in the low 32 bit the x y value as two WYDEs

cmd		IS	$0
base	IS	$1

:FTrap:GPutChar GET	cmd,:rBB	%get the $255 parameter: c, x, y
              	SETH    base,:IO:HI	%base address of gpu -20
              	ORH	cmd,:GPU:CMD:CHAR
              	STTU	cmd,base,:IO:GPU+:GPU:XY
              	STHT	cmd,base,:IO:GPU+:GPU:CMD
				POP	0,0

		PREFIX	:GPutStr:
%		Put a string pointed to by $255 at the current position

string	IS	$0
base	IS	$1
cmd		IS	$2

:FTrap:GPutStr	GET	string,:rBB	%get the $255 point to the string
              	SETH    base,:IO:HI	
              	JMP 1F

Loop	ORML	cmd,:GPU:CMD:CHAR
		STT	cmd,base,:IO:GPU+:GPU:CMD
		ADD	string,string,1
1H		LDBU	cmd,string,0
		BNZ	cmd,Loop
Error	POP	0,0

		PREFIX	:GLine:
%		Draw a line from the current position to x,y with width w
%		$255 has the format 0000 WWWW XXXX YYYY

cmd		IS	$0		
base	IS	$1

:FTrap:GLine	GET	cmd,:rBB
		ORH	cmd,:GPU:CMD:LINE
		SETH    base,:IO:HI
		STO	cmd,base,:IO:GPU+:GPU:CMD
		POP	0,0	

		PREFIX	:GRectangle:

cmd		IS	$0
base	IS	$1
wh		IS	$2

:FTrap:GRectangle SETH	base,:IO:HI
		GET	cmd,:rBB		low TETRA XXXX YYYY
		SRU	wh,cmd,32
		STTU	wh,base,:IO:GPU+:GPU:WH
		SLU	cmd,cmd,32
		SRU	cmd,cmd,32			clear high TETRA
		ORH	cmd,:GPU:CMD:RECT
		STO	cmd,base,:IO:GPU+:GPU:CMD
		POP	0,0	

		PREFIX	:GBitBlt:		
		
%	transfer a bit block within vram
%	at $255	we have  WYDE destwith,destheigth,destx,desty,srcx,srcy

tmp		IS	$0
base	IS	$1
args	IS	$2
:FTrap:GBitBlt	GET	args,:rBB		%get the $255 parameter
              	SETH	base,:IO:HI	%base address of gpu -20
              	LDO	tmp,args,0	%destwith,destheigth,destx,desty
              	STO	tmp,base,:IO:GPU+:GPU:WHXY
              	LDTU	tmp,args,8	%srcx,srcy
              	ORH	tmp,:GPU:CMD:BLT|#CC	CMD|RasterOP
              	ORMH	tmp,#0020		CC0020=SRCCOPY
              	STOU	tmp,base,:IO:GPU+:GPU:CMD
              	POP	0,0


		PREFIX	:GPutBmp:		
		
%	transfer a 32x32 Bitmap identified by a number from off-screen memory to on-screen memory
%	in $255	we have  IIIIII,NN,XXXX,YYYY
%       where IIIIII is ignored, NN the bitmap id, XXXX and YYYY the destination coordinates

tmp		IS	$0
base	IS	$1
args	IS	$2
op		IS	$3
idx		IS	$4
idy		IS	$5
cmd		IS	$6

:FTrap:GPutBmp	GET	args,:rBB	%get the $255 parameter
        SETH	base,:IO:HI		%base address of gpu -20
		SLU		tmp,args,32
		SRU		tmp,tmp,32		%extract destination XXXX,YYYY
		ORMH	tmp,32			%add height
		ORH		tmp,32	        %add width	
        STO		tmp,base,:IO:GPU+:GPU:WHXY
		SRU		tmp,args,32
		AND		tmp,tmp,#FF		%the bitmap id
		AND		idx,tmp,#03		last 3 bit for x
		SRU		idy,tmp,2		other bits for y
		SL		idx,idx,5		x*32
		INCL	idx,640			x+=640
		SL		idy,idy,5		y*32
        SETH	op,#00CC		%RasterOP
        ORMH	op,#0020		%CC0020=SRCCOPY
        SLU		cmd,idx,16
		OR		cmd,cmd,idy
		OR		cmd,cmd,op
		ORH		cmd,:GPU:CMD:BLT %add Command
        
        STOU	cmd,base,:IO:GPU+:GPU:CMD
        POP		0,0



		PREFIX	:GBitBltIn

%	transfer a bit block from normal memory into vram
%	at $255	we have:  WYDE with,heigth,destx,desty; OCTA srcaddress
args		IS	$0
base		IS	$1
return		IS	$2
gbit		IS	$3
bits		IS	$4
cmd			IS	$5
tmp			IS	$6


:FTrap:GBitBltIn GET	args,:rBB
              	SETH	base,:IO:HI
              	LDO	tmp,args,0	%with,heigth,destx,desty
              	STO	tmp,base,:IO:GPU+:GPU:WHXY

              	GET	return,:rJ
              	LDOU	tmp+1,args,8	%srcaddress
              	PUSHJ	tmp,:V2Paddr
              	PUT	:rJ,return
				BN	tmp,Error

              	STO	tmp,base,:IO:GPU+:GPU:BBA
              	SETH	cmd,:GPU:CMD:BLTIN|#CC	CMD|RasterOP
              	ORMH	cmd,#0020		CC0020=SRCCOPY
              	SET	gbit,1
              	SL	gbit,gbit,:Interrupt:GPU
              	GET	bits,:rQ
              	ANDN	bits,bits,gbit
              	PUT	:rQ,bits

		%issue command
              	STHT	cmd,base,:IO:GPU+:GPU:CMD

		% wait for completion
Loop			SYNC	4
              	GET	bits,:rQ
              	AND	tmp,bits,gbit
              	BZ	tmp,Loop

              	ANDN	bits,bits,gbit
              	PUT	:rQ,bits
				PUT	:rBB,0
              	POP	0,0

Error			NEG	tmp,1
				PUT	:rBB,tmp
              	POP	0,0

		PREFIX	:GBitBltOut:

%	transfer a bit block from vram into normal memory
%	at $255	we have:  WYDE with,heigth,srcx,srcy; OCTA destaddress

args		IS	$0
base		IS	$1
return		IS	$2
gbit		IS	$3
bits		IS	$4
cmd			IS	$5
tmp			IS	$6

:FTrap:GBitBltOut 	GET	args,:rBB
              	SETH	base,:IO:HI
              	LDO	tmp,args,0	%with,heigth,srcx,srcy
              	STO	tmp,base,:IO:GPU+:GPU:WHXY

              	GET	return,:rJ
              	LDO	tmp+1,args,8	%srcaddress	
              	PUSHJ	tmp,:V2Paddr
              	PUT	:rJ,return
				BN	tmp,Error

              	STO	tmp,base,:IO:GPU+:GPU:BBA               	

              	SETH	cmd,:GPU:CMD:BLTOUT|#CC	CMD|RasterOP
              	ORMH	cmd,#0020		CC0020=SRCCOPY
              	SET	gbit,1
              	SL	gbit,gbit,:Interrupt:GPU
              	GET	bits,:rQ
              	ANDN	bits,bits,gbit
              	PUT	:rQ,bits

		%issue command
              	STHT	cmd,base,:IO:GPU+:GPU:CMD

		% wait for completion
Loop			SYNC	4
              	GET	bits,:rQ
              	AND	tmp,bits,gbit
              	BZ	tmp,Loop

              	ANDN	bits,bits,gbit
              	PUT	:rQ,bits
				PUT	:rBB,0
              	POP	0,0

Error			NEG	tmp,1
				PUT	:rBB,tmp
              	POP	0,0

		PREFIX	:GDIB

%	transfer a bit block from normal memory into vram
%	at $255	we have:  WYDE with,heigth,destx,desty; OCTA srcaddress
args		IS	$0
base		IS	$1
return		IS	$2
gbit		IS	$3
bits		IS	$4
cmd			IS	$5
tmp			IS	$6


:FTrap:GDIB 	GET		args,:rBB
              	SETH	base,:IO:HI
              	LDO		tmp,args,0	%0,0,destx,desty
              	STO		tmp,base,:IO:GPU+:GPU:WHXY

              	GET	return,:rJ
              	LDOU	tmp+1,args,8	%srcaddress
              	PUSHJ	tmp,:V2Paddr
              	PUT	:rJ,return
				BN	tmp,Error

              	STO		tmp,base,:IO:GPU+:GPU:BBA
              	SETH	cmd,:GPU:CMD:BLTDIB
              	SET	gbit,1
              	SL	gbit,gbit,:Interrupt:GPU
              	GET	bits,:rQ
              	ANDN	bits,bits,gbit
              	PUT	:rQ,bits

		%issue command
              	STHT	cmd,base,:IO:GPU+:GPU:CMD

		% wait for completion
Loop			SYNC	4
              	GET	bits,:rQ
              	AND	tmp,bits,gbit
              	BZ	tmp,Loop

              	ANDN	bits,bits,gbit
              	PUT	:rQ,bits
				PUT	:rBB,0
              	POP	0,0

Error			NEG	tmp,1
				PUT	:rBB,tmp
              	POP	0,0

%		Mouse		
		
		PREFIX	:MWait:
%		Wait for a mouse event and return the descriptor

bits	IS	$0
mbit	IS	$1
tmp		IS	$2

:FTrap:MWait	SET	mbit,1		
				SL	mbit,mbit,:Interrupt:Mouse
				JMP		1F

Loop	SYNC	4		%wait idle for an interrupt
1H		GET		bits,:rQ		
		AND		tmp,bits,mbit
		BZ		tmp,Loop
	
		ANDN	bits,bits,mbit	%clear mouse Interrupt		
		PUT		:rQ,bits
		
		SETH	tmp,:IO:HI		base address
		LDO		tmp,tmp,:IO:Mouse	mouse status
		PUT		:rBB,tmp		return via rBB in $255
		POP		0,0

%		Keyboard
	
		PREFIX	:Keyboard:
%		Wait until the button is pressed
%		return immediately if button was already pressed

base		IS 	$0
status		IS	$1
kbit		IS	$2
bits		IS	$3
return		IS	$4
tmp			IS	$5


:FTrap:KGet	SETH	base,:IO:HI		base address
1H		LDO	status,base,:IO:Keyboard	keyboard status
		BNZ	status,1F
		GET	return,:rJ
		PUSHJ	tmp,:FTrap:KWait
		PUT	:rJ,return
		JMP	1B

1H		SLU	status,status,32
		SRU	status,status,32	remove high tetra
		PUT	:rBB,status		return via rBB in $255
		POP	0,0


:FTrap:KStatus SETH	base,:IO:HI		base address
		LDHT	status,base,:IO:Keyboard	keyboard status
		PUT		:rBB,status		return via rBB in $255
		POP		0,0

:FTrap:KWait	SET	kbit,1
		SL	kbit,kbit,:Interrupt:Keyboard
		JMP	1F

Loop	SYNC	4
1H		GET	bits,:rQ
		AND	tmp,bits,kbit
		BZ	tmp,Loop
		
		ANDN	bits,bits,kbit
		PUT	:rQ,bits

		PUT	:rBB,0
		POP	0,0

%		Events
		PREFIX	:Event:

%		Forced TRAP Event-Wait - EWait
%		Get the Event mask from rBB and wait for a matching event
%		Return rQ in rBB
%		****************** Ab hier Ihr eigener Code *************
base		IS 	$0
state		IS	$1
bbit		IS	$2
bits		IS	$3
tmp			IS	$4

:FTrap:EWait GET	bbit,:rBB
		JMP	1F

Loop	SYNC	4
1H		GET	bits,:rQ
		AND	tmp,bits,bbit
		BZ	tmp,Loop
		ANDN bits,bits,bbit
		PUT	:rQ,bits
		PUT	:rBB,tmp
		POP	0,0

%		****************** Ende Ihres eigenen Codes *************
		PREFIX :


%		Button
	
		PREFIX	:BWait:
%		Wait until the button is pressed
%		return immediately if button was already pressed

base		IS 	$0
state		IS	$1
bbit		IS	$2
bits		IS	$3
tmp			IS	$4

:FTrap:BWait	SET	bbit,1
		SL	bbit,bbit,:Interrupt:Button
		JMP	1F

Loop	SYNC	4
1H		GET	bits,:rQ
		AND	tmp,bits,bbit
		BZ	tmp,Loop
		
		ANDN	bits,bits,bbit
		#SET bits,0
		PUT	:rQ,bits

		PUT	:rBB,0
		POP	0,0


		PREFIX	:Sevensegment:

top		IS	#01
mid		IS	#02
bot		IS	#04
tleft	IS	#08 top
bleft	IS	#10 bottom
tright	IS	#20 top
bright	IS	#40 bottom
dot		IS	#80

segments	BYTE	top|tleft|tright|bleft|bright|bot  	%0
		BYTE	tright|bright				%1
		BYTE	top|tright|mid|bleft|bot		%2
		BYTE	top|tright|mid|bright|bot		%3
		BYTE	tleft|tright|mid|bright			%4
		BYTE	top|tleft|mid|bright|bot		%5
		BYTE	top|tleft|mid|bleft|bright|bot		%6
		BYTE	top|tright|bright			%7
		BYTE	top|mid|bot|tleft|tright|bleft|bright	%8
		BYTE	top|mid|bot|tleft|tright|bright		%9

base		IS	$0
bits		IS	$1
head		IS	$2
tail		IS	$3
code		IS	$4
shift       IS	$5
tmp			IS 	$6

%		$255 specifies the number to display
%		Z    specifies the number of decimal places

:FTrap:SDecimal	GET	tmp,:rXX
		AND	tmp,tmp,#FF	% Z value
		SL	tmp,tmp,3	% Z*8
		SET	bits,dot
		SL	bits,bits,tmp	% dot after Z places
		CSZ	bits,tmp,0	% no dot if Z equal zero
		SET	shift,0
		GET	head,:rBB
		GETA	base,segments
		
1H		DIV	head,head,10
		GET	tail,:rR
		LDB	code,base,tail
		SLU	code,code,shift
		OR	bits,bits,code
		ADD	shift,shift,8
		BP	head,1B
		
		SETH	base,:IO:HI	
		STO	bits,base,:IO:Sevensegment
		POP	0,0

%		$255 specifies the rwa bits to display
:FTrap:SSet	GET	bits,:rBB
		SETH	base,:IO:HI	
		STO	bits,base,:IO:Sevensegment
		POP	0,0


%	two auxiliar functions to read and write characters.

		PREFIX :AUX:Keyboard:
c		IS	$0	parameter
base	IS	$1	
return	IS	$2
bits	IS	$3
kbit	IS	$4
tmp		IS	$5
CR		IS	#0D
NL		IS	#0A
%	read blocking a character from the keyboard
:KeyboardC 	SETH	base,:IO:HI    
Test		LDO	c,base,:IO:Keyboard	% keyboard status/data
		SR	tmp,c,32
		AND	tmp,tmp,#FF		% count
		BNZ	tmp,Done		% char available

		SET	kbit,1
		SLU	kbit,kbit,:Interrupt:Keyboard
Wait	SYNC	4			% power save mode
		GET 	bits,:rQ
		AND	tmp,bits,kbit
		BZ	tmp,Wait           
		ANDN	bits,bits,kbit		% reset the keybaord interrupt bit
		PUT	:rQ,bits		and store back to rQ
		JMP	Test

Done	AND	c,c,#FF
		CMP	tmp,c,CR
		CSZ	c,tmp,NL	replace cr by nl
		GET	return,:rJ
		SET	tmp+1,c
		PUSHJ	tmp,:ScreenC	%echo
		PUT	:rJ,return
		POP	1,0
	

		PREFIX :AUX:Screen:

%	Put one character contained in $0 on the screen
%	version for the winvram device with GPU

c		IS	$0	parameter
base	IS	$1
cmd		IS	$2
tmp		IS	$3
CR		IS	#0D
NL		IS	#0A
ScreenC	SETH	base,:IO:HI
1H		LDB	tmp,base,:IO:GPU+:GPU:CMD	wait for idle
		BNZ	tmp,1B
	    SETML	cmd,:GPU:CMD:CHAR
		AND	c,c,#FF				clean it
	    OR	tmp,cmd,c		
		STT	tmp,base,:IO:GPU+:GPU:CMD
		CMP	tmp,c,CR
		BNZ	tmp,2F
1H		LDB	tmp,base,:IO:GPU+:GPU:CMD	wait for idle
		BNZ	tmp,1B
		OR	tmp,cmd,NL
		STT	tmp,base,:IO:GPU+:GPU:CMD
2H		POP	0,0
		
		PREFIX :UNUSED:Screen:
%	Put one character contained in $0 on the screen
%	version for the screen device

c		IS	$0	parameter
base	IS	$1
tmp		IS	$2

ScreenC	SETH	base,:IO:HI	
1H		LDO	tmp,base,:IO:Screen
		BNZ	tmp,1B
		STO	c,base,:IO:Screen
		POP	0,0

:ScreenC	IS	:AUX:Screen:ScreenC

		PREFIX :PageTable:

%       The ROM Page Table
%       the table maps each segement with up to 1024 pages
%	currently, the first page is system rom, the next four pages are for
%       text, data, pool, and stack. 
%	Flash Memory is mapped to the data segment at
%       The page tables imply the following RAM Layout

%	The RAM Layout

%       the ram layout uses the small memmory model (see memory.howto)
%       8000000100000000    first page for OS, layout see below
%       Next the  pages for the user programm

		LOC	#8000000000002000	%The start is fixed in mmix-sim.ch
								%To allow loading mmo files from the commandline

%       Text Segment 12 pages = 96kByte
Table	OCTA	#0000000100002005	%text permission 5=r-x
   	OCTA	#0000000100004005 
   	OCTA	#0000000100006005 
   	OCTA	#0000000100008005 
   	OCTA	#000000010000a005 
   	OCTA	#000000010000c005 
   	OCTA	#000000010000e005 
   	OCTA	#0000000100010005
   	OCTA	#0000000100012005
   	OCTA	#0000000100014005
	OCTA	#0000000100016005 
	OCTA	#0000000100018005  
   	 
%       Data Segment 8 pages = 64 kByte RAM
	LOC     (@&~#1FFF)+#2000	%data permission rw-
	OCTA	#000000010001a006  
	OCTA	#000000010001c006  
	OCTA	#000000010001e006  
	OCTA	#0000000100020006  
	OCTA	#0000000100022006  
	OCTA	#0000000100024006  
	OCTA	#0000000100026006  
	OCTA	#0000000100028006

%       Data Segment next 8 pages = 64 kByte FLASH
	OCTA	#0000000200000006	%flash permission rw-
	OCTA	#0000000200002006 
	OCTA	#0000000200004006 
	OCTA	#0000000200006006 
	OCTA	#0000000200008006 
	OCTA	#000000020000a006 
	OCTA	#000000020000c006 
	OCTA	#000000020000e006 
				
%	Pool Segment 2 pages = 16 kByte
	LOC	(@&~#1FFF)+#2000
	OCTA	#000000010002a006	%pool permission rw-
	OCTA	#000000010002c006  
	
%	Stack Segment 10+2 pages = 80+16 kByte
	LOC	(@&~#1FFF)+#2000
	OCTA	#000000010002e006	%10 pages register stack
	OCTA	#0000000100030006  
	OCTA	#0000000100032006  
	OCTA	#0000000100034006  
	OCTA	#0000000100036006  
	OCTA	#0000000100038006  
	OCTA	#000000010003a006  
	OCTA	#000000010003c006  
	OCTA	#000000010003e006  
	OCTA	#0000000100040006  

	LOC	(@&~#1FFF)+#2000-2*8	
	OCTA	#0000000100042006	%gcc memory stack < #6000 0000 0080 0000
	OCTA	#0000000100044006  

	LOC	(@&~#1FFF)+#2000
	

	LOC	(@&~#1FFF)+#2000


%       	free space starts at 8000000100046000

%       	initialize the memory management
tmp		IS	$0
:memory	SETH    tmp,#1234	%set rV register
		ORMH    tmp,#0D00      
		ORML    tmp,#0000
		ORL     tmp,#2000
		PUT		:rV,tmp        
		POP     0,0
		
		PREFIX	:V2Paddr:

% Translate virtual adresses to physical 
% we assume s in rV to be 13. and b1,b2,b3,b4=1,2,3,4
% pte Format:  x(16) addr(48-s) unused(s-13) n(10) p(3)
% return -1 on failure
addr	IS	$0	% parameter and return value
tab		IS	$1
n		IS	$2
pte		IS	$3
mask	IS	$4
tmp		IS	$5

:V2Paddr	BN	addr,Negativ
		GETA	tab,:PageTable:Table
		SRU	tmp,addr,61
		AND	tmp,tmp,3	% segment
		SLU	tmp,tmp,13	
		ADD	tab,tab,tmp	% PageTab+segment*1024
		ANDNH	addr,#E000	% remove segment from addr

		SRU	n,addr,13   	% page number
		SET	mask,#1FFF	% 13-bit mask
		CMP	tmp,n,mask
		BP	tmp,Error

		SL	n,n,3		% offset into the page table
		LDOU  	pte,tab,n   	% PTE
		BZ	pte,Error
              	ANDNL	pte,#1FFF   	% remove unused, n and p bits
		ANDNH	pte,#FFFF	% remove x bits
		AND	tmp,addr,mask	% get page offset 
		ADDU	addr,pte,tmp
		POP	1,0
		
Negativ	ANDNH	addr,#8000	% remove sign bit
		POP	1,0

Error	NEG	addr,1
		POP	1,0
	       

		PREFIX	:GUI:
%		Initialize GUI
%		Load Bitmaps to off-screen memory
width	IS	32
height	IS	32
ids		IS	15	number of possible ids
				% 0=LEFT, 1=UP, 2=RIGHT, 3=DOWN
				% 4=LEFTTAIL, 5=UPTAIL, 6=RIGHTTAIL, 7=DOWNTAIL
				% 8=BODY, 9=TAIL, 10=EMPTY, 11=WALL,
				% 12=APPLE, 13=WIN, 14=TUX

return	IS	$0
rBB		IS	$1
tmp		IS	$2
:gui	GET	return,:rJ
		GET	rBB,:rBB
		GETA	tmp+1,args
		PUT	:rBB,tmp+1
		PUSHJ	tmp,:FTrap:GDIB
		PUT	:rBB,0
		PUSHJ	tmp,:FTrap:GSetPos		
		PUT	:rBB,rBB
		PUT	:rJ,return
		POP	0,0

		% here we have the bitmaps:
		OCTA	0	%align to octa

bitmaps		IS	@	
	OCTA 	#424D384400000000,#0000360400002800,#0000800000008000
	OCTA 	#0000010008000000,#000002400000120B,#0000120B00000000
	OCTA 	#0000000000000001,#0000050003001800,#0100130100001300
	OCTA 	#0400060300001C01,#0000210002002801,#0000320000001004
	OCTA 	#00003A0000000105,#030001030A004000,#0200460000005200
	OCTA 	#0200590000006100,#03006C0002000009,#0A007A000000050A
	OCTA 	#0700830000000008,#13008C0003000F0A,#0D009C020000B100
	OCTA 	#0000A8000600BB00,#0000170F0C00C300,#06001D110600D301
	OCTA 	#0000E0000000E900,#00000D120F002315,#0400F40005000019
	OCTA 	#0C00FC0400000011,#2F0002171C00FF00,#160017191800011F
	OCTA 	#1000000080001F1C,#1E00251E1D000121,#22001E201E000019
	OCTA 	#4000442800001820,#2C00002D11002426,#250000272F00011F
	OCTA 	#4F00003416002B2E,#2A005D370000002A,#6600003640003135
	OCTA 	#3400463433000000,#FF003E3635007244,#0000293B3A000031
	OCTA 	#7B0000501C003D40,#3E004C453E008C54,#0900464947003D49
	OCTA 	#4C00033B9100005D,#23003C533E000251,#5E0023467A004551
	OCTA 	#54000441A0003255,#5300515352005D53,#5100A8650300006E
	OCTA 	#2A00136A34005659,#5700017F0400655C,#5B005B5E5C00605D
	OCTA 	#5F00004CBD003C63,#620005820D005E61,#5F000A8600000E88
	OCTA 	#0000516466000984,#1300006977000080,#2E0064676500CF7D
	OCTA 	#000000853500138A,#1E00506F7200168D,#21000059DC00228F
	OCTA 	#2100EB8500005E72,#71006E716F00367A,#7A0027942800E98A
	OCTA 	#0A00EB8D0000327D,#7E00025EF700007E,#910034992B004B7E
	OCTA 	#7F00009A3B000062,#F8007F7B7D00E890,#1500428180007A7D
	OCTA 	#7B00F3911500369B,#3B000067FE005E84,#8300046BFB00399E
	OCTA 	#3E0000B30D008085,#7F004489890000A6,#4100698E76001571
	OCTA 	#F600EB9C22000091,#A7004093900050A7,#4D002B7CF80053AA
	OCTA 	#500004B83F00139C,#9A00749497007A94,#950054AA5A009194
	OCTA 	#92003A9B9B005DAD,#59003B87F90000A2,#BA0062B167009A9D
	OCTA 	#9B0078A09E002CA7,#A400EEAD530025AA,#A8006DB669003AA8
	OCTA 	#AB0000CB500000D1,#4D0071BA750089A0,#C500A5A8A6005698
	OCTA 	#F90000D8480019B5,#B60000B9BB0000B4,#D000ABAEAC0000D9
	OCTA 	#560036B9B800F3BE,#6C006DA2FC0000E0,#550029D56E000DDC
	OCTA 	#6500F3C3790005BE,#DC0024DE6600B5B9,#B80016C6C30000FF
	OCTA 	#0C0000D1A7007CAE,#F90052BDD50097CB,#9500BDC0BD003CE2
	OCTA 	#780000D0CF00F7CB,#8E0090B7F90000CA,#EA0022D2D00078CB
	OCTA 	#D800B1D2BD005BE9,#8E0061E79300EDD4,#AE00ABC5FD000CDE
	OCTA 	#DF0000DAFD0074EE,#9C00D3D6D4000DE6,#E70000E1FF0027E0
	OCTA 	#FC008AEEAC00E3D9,#D800C1D2FF003DE3,#FE00C8E4CC0000EF
	OCTA 	#ED00BFD7FF00F6E4,#CC00DFE2E00000F4,#F20063E7FF00E6E2
	OCTA 	#E500AFF5C10070EA,#FD00D8EDD900DAE3,#FD00D5E6FB008BED
	OCTA 	#FE00C6F7D400FEF1,#D80001FFFF00E4F1,#E2009DF3FF00E1EE
	OCTA 	#FA00B0F2FE00CFF8,#E500D6F9E000F0F3,#EF00EAF1FA00EAF5
	OCTA 	#EE00BDF6FF00FFF9,#E400FCF7FA00DBFA,#FD00CCFDFF00D2FD
	OCTA 	#FD00E8FEFA00FFFE,#F500F4FEFC00FCFF,#FD00FFFFFF000C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C1A
	OCTA 	#1F1A0C0C0C0C0C0C,#0C0C2D5445010C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#070F060C0C0C0C0C
	OCTA 	#0C0C070E010C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C050C2D6DD0,#EBE0650C0C0C0C0C,#0C38EBEBEBB3300C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C011B
	OCTA 	#27292720100A0C02,#1322292927130C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C1439,#3F3F3F2B0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C318BAED0E0EBEB,#EBEBE0565A554B5A
	OCTA 	#5A7CEBEBEBEBC930,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0A1D2C,#2C2C2C2C2C2C2C2C,#2C2C2C2C2C2C190C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C5090B0
	OCTA 	#BABAB09E7A50050C,#0C0C0C0C0C0C0C0C,#0C81EBEBEBEBEBEB
	OCTA 	#EBEBD4569AB1AB82,#5A7CEBEBEBEBEBD0,#601F0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C01172C2C,#2C2C2C2C2C2C2C2C
	OCTA 	#2C2C2C2C2C2C2C15,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C3990C8D5D5,#D1D1D1D5D5C8390C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C52EBEBEBEBEBEB,#EBEB98FCFEFEFEFE,#DF8AEBEBEBEBEBEB
	OCTA 	#EBC9400C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C102C2C2C
	OCTA 	#2C2C2C2C2C2C2C2C,#2C2C2C2C2C2C2C24,#0F0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C62CAD1D1D1D1,#D1D1D1D1D1D1670C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C41EBEBEBEBEBEB,#EBA6E2FEFEFEFEFE
	OCTA 	#FEE2D0EBEBEBEBEB,#EBEB600C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C03242C2C2C,#2C2C2C2C2C2C2C2C,#2C2C2C2C2C2C2C2C
	OCTA 	#1E040C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#054ACEFAD1D1D1D1
	OCTA 	#D1D1D1D1D1D1B00C,#0C0C0C0C0C0C0C0C,#0C5AEBEBEBEBEBEB
	OCTA 	#D0625AFEFEFEFEFE,#FEF7A6EBEBEBEBEB,#EBA21A0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C1B2C2C2C2C,#2C2C2C2C2C2C2C2C
	OCTA 	#2C2C2C2C2C2C2C2C,#2C10050C0C0C0C35,#57351F0C0C0C2144
	OCTA 	#6A77B4FBD6D1D1D1,#D1D1D1D1D1D1C832,#0C0C0C0C0C0C0C0C
	OCTA 	#0C43E0EBEBEBEBEB,#6562ABFEFEFEFEFE,#FEFC91EBEBEBEBEB
	OCTA 	#EB400C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C06292C2C2C2C
	OCTA 	#2C2C2C2C2C2C2C2C,#2C2C2C2C2C2C2C2C,#2C200A0C0C0C0C1F
	OCTA 	#7777777777777776,#77768FFDE4D1D1D1,#D1D1D1D1D1D1D167
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C3174EBEBEBBD,#5E9AFEFEFEFEFEFE
	OCTA 	#FEFE86EBA49BDCEB,#D4210C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C192C2C2C2C2C,#2C2C2C2C2C2C2C2C,#2C2C2C2C2C2C2C2C
	OCTA 	#2C27030C0C0C0C05,#5783777777777776,#767780DEF5D1D1D1
	OCTA 	#D1D1D1D1D1D1D19E,#0C0C0C0C0C0C0C0C,#0C0C0C057CEBD469
	OCTA 	#BCFEFEFEFEFEFEFE,#FEFEBCD0D8DF5EA6,#480C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C222C2C2C2C2C,#2C2C2C2C2C2C2C2C
	OCTA 	#2C2C2C2C2C2C2C2C,#1C060C0C0C0C0C05,#3D77777777777777
	OCTA 	#777780B9F8D6D1D1,#D1D1D1D1D1D1D1BA,#140C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C305C5EDF,#FEFEFEFEFEFEFEFE,#FEFEFE7FFEFE9AAB
	OCTA 	#380C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C09242C2C2C2C2C
	OCTA 	#2C2C2C2C2C2C2C2C,#2C2C2C2C2C2C2C1D,#0A0C0C0C0C0C0C0C
	OCTA 	#2677777777777777,#7777778FFBE4D1D1,#D1D1D1D1D1D1D1C8
	OCTA 	#500C0C0C0C0C0C0C,#0C0C0C0C2D62A0BC,#FEFEFEFEFEFEFEFE
	OCTA 	#FEFEFEFEA0B1A062,#3C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C11272C2C2C2C2C,#2C2C2C2C2C2C2C2C,#2C2C2C2C2C2C2407
	OCTA 	#0C0C0C0C0C0C0C0C,#1F57837777767776,#77767780EAEDD1D1
	OCTA 	#D1D5D6DADAD6D6D1,#900C0C0C0C0C0C0C,#0C0C0C0C0C62BC73
	OCTA 	#FEFEFEFEFEFEFEFE,#FEFEFEFEA0BC5A62,#3C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C15292C2C2C2C2C,#2C2C2C2C2C2C2C2C
	OCTA 	#2C2C2C2C2C2C1B0C,#0C0C0C0C0C0C0C0C,#0544837777777777
	OCTA 	#77777780C6F9D6D5,#E1EFF8FBFBFAF5ED,#C10D0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C5DA05A,#FEFEFEFEFEFEFEFE,#FEFEFEFE73A05D62
	OCTA 	#250C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C172C2C2C2C2C2C
	OCTA 	#2C2C2C2C2C2C2C2C,#2C2C2C2C2C2C120C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C35777777767777,#76767777A3FBE8EF,#FDE9D7CDCDD2D7E3
	OCTA 	#CB3C0C0C0C0C0C0C,#0C0C0C0C0C406282,#B1FEFEFEFEFEFEFE
	OCTA 	#FEFEFEF2559A6262,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C172C2C2C2C2C2C,#2C2C2C2C2C2C2C2C,#2C2C2C2C2C2C0F0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C21577677767776,#777777768FF2FDE9
	OCTA 	#CDB8ADADADADADB8,#B7590C0C0C0C0C0C,#0C0C0C0C0C0C5A82
	OCTA 	#73FEFEFEFEFEFEFE,#FEFEFE8273826248,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C15292C2C2C2C2C,#2C2C2C2C2C2C2C2C
	OCTA 	#2C2C2C2C2C2C120C,#0C0C0C0C0C0C0C0C,#0C05448376767677
	OCTA 	#77767180C6FCF0C4,#ADB2B2B2B2B2B2B2,#B67D0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C3C69,#69D3FEFEFEFEFEFE,#FEFEF25D825D5D0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C11272C2C2C2C2C
	OCTA 	#2C2C2C2C2C2C2C2C,#2C2C2C2C2C2C1D0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C49CEB48F8076,#768FB4EAF2DDF1C4,#ADB2B2B2B2B2B2B2
	OCTA 	#B2953B0C0C0C0C0C,#0C0C0C0C0C0C0C4B,#6269FEFEFEFEFEFE
	OCTA 	#FEFE8A736269330C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C07242C2C2C2C2C,#2C2C2C2C2C2C2C2C,#2C2C2C2C2C2C2409
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C36AAF3FCF6EA,#EAF6FCDD9D9DE7D2
	OCTA 	#ADB2B2B2B2B2B2B2,#B2A84E0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#5D62F2FEFEFEFEFE,#FEF25D6262480C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C1C2C2C2C2C2C,#2C2C2C2C2C2C2C2C
	OCTA 	#2C2C2C2C2C2C2C1E,#030C0C0C0C0C0C0C,#0C0C0D4D879DB5C7
	OCTA 	#C7B59387858ECFE3,#B2B2B2B2B2B2B2B2,#B2B66B0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#2562BCFEF7F7FEFE,#FEC36262550C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C07272C2C2C2C
	OCTA 	#2C2C2C2C2C2C2C2C,#2C2C2C2C2C2C2C2C,#1C040C0C0C0C0C0C
	OCTA 	#0C0C0C3E8585857E,#857E857E7E7EB5F1,#C4B2B2B2B2B2B2B2
	OCTA 	#B2B68C370C0C0C0C,#0C0C0C0C0C0C0C0C,#0C5582D8AED486F7
	OCTA 	#FE736262160C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C11272C2C2C,#2C2C2C2C2C2C2C2C,#2C2C2C2C2C2C2C2C
	OCTA 	#23090C0C0C0C0C0C,#0C0C0C346F857E7E,#7E7E7E7E7E799DEE
	OCTA 	#CCADB2B2B2B2B2B2,#B2B2A7470C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C2D4CA4BDC596DC,#A15D62400C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C050C10222C2C,#2C2C2C2C241C1D20
	OCTA 	#292C2C2C2C2C291E,#090C0C0C0C0C0C0C,#0C0C0C1853858585
	OCTA 	#7E85857E7E7E8ED9,#D7B2B2B2B2B2B2B2,#B2B2B6580C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0CA2DCEBEBEBBD,#AF5C62160C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C07131B
	OCTA 	#1E1E1C170B0F1517,#13191C1E1C191103,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C46858585,#857E7E7E857E7EC7,#E9BBB2B2B6B2A8A7
	OCTA 	#A8B2B68C2E0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C56AEEBEBE0AE
	OCTA 	#7262620C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C01,#0202030C0C152924,#1E0E010204010C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C346F8585,#7E7E7E7E7E7E79AC
	OCTA 	#EEC4B6A78C6B584E,#58688C8C3B0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0CC3019778432D,#DF5D620C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C10272C
	OCTA 	#2C230B0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C185F857E
	OCTA 	#857E7E7E7E7E7E93,#E6D28C47250C0C0C,#0C0C0C3B280C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0CC3D3C373DF9A,#D35D620C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C01232C,#2C2C1C040C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C4D7E85,#7E857E7E7E7E7E85,#C78D2E0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C69B16962BCF2
	OCTA 	#8262620C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C1129,#2C2C2C0F0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C3A7E85,#857E857E85858579
	OCTA 	#511A0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C625D62625D5A,#62625D0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C15
	OCTA 	#272C2C15010C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0D3E5F
	OCTA 	#8585858585855F3A,#0D0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C5A6262626262,#6262550C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#101E2C1B010C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0D18,#2A3E464D4634180C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C386262626262
	OCTA 	#62620C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C040908010C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0D0D0D0D0D0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C2D5D696262,#5D250C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C161616,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C899F7B64616164,#7B9F890C0C0C0C0C,#0C0C0C0C0C0C0000
	OCTA 	#0000000000000000,#0000000000000000,#0000000000000000
	OCTA 	#0000000000002F2F,#2F2F2F2F2F2F2F2F,#2F2F2F2F2F2F2F2F
	OCTA 	#2F2F2F2F2F2F2F2F,#2F2F2F2F2F2F0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C899F,#615B5B5B5B5B5B5B,#5B5B5B619F89890C
	OCTA 	#0C0C0C0C0C0C0000,#0000000000000000,#0000000000000000
	OCTA 	#0000000000000000,#0000000000004242,#4242424242424242
	OCTA 	#4242424242422F42,#4242424242424242,#4242424242420C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0CA95B5B,#5B5B5B5B5B5B5B5B
	OCTA 	#5B5B5B5B5B5B890C,#0C0C0C0C0C0C0000,#0000000000000000
	OCTA 	#0000000000000000,#0000000000000000,#0000000000004242
	OCTA 	#4242424242424242,#4242424242422F42,#4242424242424242
	OCTA 	#4242424242420C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C897B5B5B5B
	OCTA 	#5B5B5B5B5B5B5B5B,#5B5B5B5B5B5B5B7B,#890C0C0C0C0C0000
	OCTA 	#0000000000000000,#0000000000000000,#0000000000000000
	OCTA 	#0000000000004242,#4242424242424242,#4242424242422F42
	OCTA 	#4242424242424242,#4242424242420C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C89645B5B5B5B,#5B5B5B5BEB5B5B5B,#EB5B5B5B5B5B5B5B
	OCTA 	#64890C0C0C0C0000,#0000000000000000,#0000000000000000
	OCTA 	#0000000000000000,#0000000000004242,#4242424242424242
	OCTA 	#4242424242422F42,#4242424242424242,#4242424242420C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C89645B5B5B5B5B,#5B5B5B5BEBEBEBEB
	OCTA 	#EB5B5B5B5B5B5B5B,#5B64890C0C0C0000,#0000000000000000
	OCTA 	#0000000000000000,#0000000000000000,#0000000000004242
	OCTA 	#4242424242424242,#4242424242422F42,#4242424242424242
	OCTA 	#4242424242420C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C7B5B5B5B5B5B5B
	OCTA 	#5B5B5B5BEBEBEBEB,#EB5B5B5B5B5B5B5B,#5B5B7B0C0C0C0000
	OCTA 	#0000000000000000,#0000000000000000,#0000000000000000
	OCTA 	#0000000000004242,#4242424242424242,#4242424242422F42
	OCTA 	#4242424242424242,#4242424242420C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#A95B5B5B5B5B5B5B,#5B5B5B5BEBEBEBEB,#EB5B5B5B5B5B5B5B
	OCTA 	#5B5B5B89890C0000,#0000000000000000,#0000000000000000
	OCTA 	#0000000000000000,#0000000000002F2F,#2F2F2F2F2F2F2F2F
	OCTA 	#2F2F2F2F2F2F2F2F,#2F2F2F2F2F2F2F2F,#2F2F2F2F2F2F0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C89,#5B5B5B5B5B5B5B5B,#5B5B5BEBEBEBEBEB
	OCTA 	#EBEBEB5B5B5B5B5B,#5B5B5B5B890C0000,#0000000000000000
	OCTA 	#0000000000000000,#0000000000000000,#0000000000004242
	OCTA 	#4242424242422F42,#4242424242424242,#4242424242422F42
	OCTA 	#4242424242420C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C9F,#5B5B5B5B5B5B5B5B
	OCTA 	#5B5B5B5B5BEBEBEB,#5B5B5B5B5B5B5B5B,#5B5B5B5B890C0000
	OCTA 	#0000000000000000,#0000000000000000,#0000000000000000
	OCTA 	#0000000000004242,#4242424242422F42,#4242424242424242
	OCTA 	#4242424242422F42,#4242424242420C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C61
	OCTA 	#5B5B5B5B5B5B5B5B,#5B5B5B5B5B5BEB5B,#5B5B5B5B5B5B5B5B
	OCTA 	#5B5B5B5B610C0000,#0000000000000000,#0000000000000000
	OCTA 	#0000000000000000,#0000000000004242,#4242424242422F42
	OCTA 	#4242424242424242,#4242424242422F42,#4242424242420C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C895B,#5B5B5B5B5B5B5B5B,#5B5B5B5B5B5BEB5B
	OCTA 	#5B5B5B5B5B5B5B5B,#5B5B5B5B5B890000,#0000000000000000
	OCTA 	#0000000000000000,#0000000000000000,#0000000000004242
	OCTA 	#4242424242422F42,#4242424242424242,#4242424242422F42
	OCTA 	#4242424242420C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C9F5B,#5B5B5B5BEB5B5B5B
	OCTA 	#EB5B5B5BBE5B5B5B,#BE5B5B5BEB5B5B5B,#EB5B5B5B5B9F0000
	OCTA 	#0000000000000000,#0000000000000000,#0000000000000000
	OCTA 	#0000000000004242,#4242424242422F42,#4242424242424242
	OCTA 	#4242424242422F42,#4242424242420C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C7B5B
	OCTA 	#5B5B5B5BEBEBEBEB,#EB5B5B5BBEBEBEBE,#BE5B5B5BEBEBEBEB
	OCTA 	#EB5B5B5B5B7B0000,#0000000000000000,#0000000000000000
	OCTA 	#0000000000000000,#0000000000004242,#4242424242422F42
	OCTA 	#4242424242424242,#4242424242422F42,#4242424242420C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C645B,#5B5B5B5BEBEBEBEB,#EB5B5B5BBEBEBEBE
	OCTA 	#BE5B5B5BEBEBEBEB,#EB5B5B5B5B640000,#0000000000000000
	OCTA 	#0000000000000000,#0000000000000000,#0000000000004242
	OCTA 	#4242424242422F42,#4242424242424242,#4242424242422F42
	OCTA 	#4242424242420C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C615B,#5B5B5B5BEBEBEBEB
	OCTA 	#EB5B5B5BBEBEBEBE,#BE5B5B5BEBEBEBEB,#EB5B5B5B5B610000
	OCTA 	#0000000000000000,#0000000000000000,#0000000000000000
	OCTA 	#0000000000002F2F,#2F2F2F2F2F2F2F2F,#2F2F2F2F2F2F2F2F
	OCTA 	#2F2F2F2F2F2F2F2F,#2F2F2F2F2F2F0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C615B
	OCTA 	#5B5B5BEBEBEBEBEB,#EBEBEBBEBEBEBEBE,#BEBEBEEBEBEBEBEB
	OCTA 	#EBEBEB5B5B610000,#0000000000000000,#0000000000000000
	OCTA 	#0000000000000000,#0000000000004242,#4242424242424242
	OCTA 	#4242424242422F42,#4242424242424242,#4242424242420C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C645B,#5B5B5B5B5BEBEBEB,#5B5B5B5B5BBEBEBE
	OCTA 	#5B5B5B5B5BEBEBEB,#5B5B5B5B5B640000,#0000000000000000
	OCTA 	#0000000000000000,#0000000000000000,#0000000000004242
	OCTA 	#4242424242424242,#4242424242422F42,#4242424242424242
	OCTA 	#4242424242420C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C7B5B,#5B5B5B5B5B5BEB5B
	OCTA 	#5B5B5B5B5B5BBE5B,#5B5B5B5B5B5BEB5B,#5B5B5B5B5B7B0000
	OCTA 	#0000000000000000,#0000000000000000,#0000000000000000
	OCTA 	#0000000000004242,#4242424242424242,#4242424242422F42
	OCTA 	#4242424242424242,#4242424242420C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C9F5B
	OCTA 	#5B5B5B5B5B5BEB5B,#5B5B5B5B5B5BBE5B,#5B5B5B5B5B5BEB5B
	OCTA 	#5B5B5B5B5B9F0000,#0000000000000000,#0000000000000000
	OCTA 	#0000000000000000,#0000000000004242,#4242424242424242
	OCTA 	#4242424242422F42,#4242424242424242,#4242424242420C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C895B,#5B5B5B5B5B5B5B5B,#5B5B5B5BEB5B5B5B
	OCTA 	#EB5B5B5B5B5B5B5B,#5B5B5B5B5B890000,#0000000000000000
	OCTA 	#0000000000000000,#0000000000000000,#0000000000004242
	OCTA 	#4242424242424242,#4242424242422F42,#4242424242424242
	OCTA 	#4242424242420C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C61,#5B5B5B5B5B5B5B5B
	OCTA 	#5B5B5B5BEBEBEBEB,#EB5B5B5B5B5B5B5B,#5B5B5B5B61890000
	OCTA 	#0000000000000000,#0000000000000000,#0000000000000000
	OCTA 	#0000000000004242,#4242424242424242,#4242424242422F42
	OCTA 	#4242424242424242,#4242424242420C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C9F
	OCTA 	#5B5B5B5B5B5B5B5B,#5B5B5B5BEBEBEBEB,#EB5B5B5B5B5B5B5B
	OCTA 	#5B5B5B5B9F0C0000,#0000000000000000,#0000000000000000
	OCTA 	#0000000000000000,#0000000000004242,#4242424242424242
	OCTA 	#4242424242422F42,#4242424242424242,#4242424242420C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C89,#5B5B5B5B5B5B5B5B,#5B5B5B5BEBEBEBEB
	OCTA 	#EB5B5B5B5B5B5B5B,#5B5B5B89890C0000,#0000000000000000
	OCTA 	#0000000000000000,#0000000000000000,#0000000000002F2F
	OCTA 	#2F2F2F2F2F2F2F2F,#2F2F2F2F2F2F2F2F,#2F2F2F2F2F2F2F2F
	OCTA 	#2F2F2F2F2F2F0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#A95B5B5B5B5B5B5B
	OCTA 	#5B5B5BEBEBEBEBEB,#EBEBEB5B5B5B5B5B,#5B5B5BA90C0C0000
	OCTA 	#0000000000000000,#0000000000000000,#0000000000000000
	OCTA 	#0000000000004242,#4242424242422F42,#4242424242424242
	OCTA 	#4242424242422F42,#4242424242420C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C7B5B5B5B5B5B5B,#5B5B5B5B5BEBEBEB,#5B5B5B5B5B5B5B5B
	OCTA 	#5B5B7B0C0C0C0000,#0000000000000000,#0000000000000000
	OCTA 	#0000000000000000,#0000000000004242,#4242424242422F42
	OCTA 	#4242424242424242,#4242424242422F42,#4242424242420C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C89645B5B5B5B5B,#5B5B5B5B5B5BEB5B
	OCTA 	#5B5B5B5B5B5B5B5B,#5B64890C0C0C0000,#0000000000000000
	OCTA 	#0000000000000000,#0000000000000000,#0000000000004242
	OCTA 	#4242424242422F42,#4242424242424242,#4242424242422F42
	OCTA 	#4242424242420C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C89645B5B5B5B
	OCTA 	#5B5B5B5B5B5BEB5B,#5B5B5B5B5B5B5B5B,#64890C0C0C0C0000
	OCTA 	#0000000000000000,#0000000000000000,#0000000000000000
	OCTA 	#0000000000004242,#4242424242422F42,#4242424242424242
	OCTA 	#4242424242422F42,#4242424242420C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C89895B5B5B,#5B5B5B5B5B5B5B5B,#5B5B5B5B5B5B5B7B
	OCTA 	#89890C0C0C0C0000,#0000000000000000,#0000000000000000
	OCTA 	#0000000000000000,#0000000000004242,#4242424242422F42
	OCTA 	#4242424242424242,#4242424242422F42,#4242424242420C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C89A9895B,#5B5B5B5B5B5B5B5B
	OCTA 	#5B5B5B5B5B5B890C,#0C0C0C0C0C0C0000,#0000000000000000
	OCTA 	#0000000000000000,#0000000000000000,#0000000000004242
	OCTA 	#4242424242422F42,#4242424242424242,#4242424242422F42
	OCTA 	#4242424242420C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C899F
	OCTA 	#615B5B5B5B5B5B5B,#5B5B5B619F890C0C,#0C0C0C0C0C0C0000
	OCTA 	#0000000000000000,#0000000000000000,#0000000000000000
	OCTA 	#0000000000004242,#4242424242422F42,#4242424242424242
	OCTA 	#4242424242422F42,#4242424242420C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C89897B64616164,#7B9F890C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0000,#0000000000000000,#0000000000000000
	OCTA 	#0000000000000000,#0000000000002F2F,#2F2F2F2F2F2F2F2F
	OCTA 	#2F2F2F2F2F2F2F2F,#2F2F2F2F2F2F2F2F,#2F2F2F2F2F2F0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C8992646492,#890C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C99,#89898975615B5B61
	OCTA 	#75898499890C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C895B5B5B5B5B,#5B890C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C8984
	OCTA 	#645B5B5B5B5B5B5B,#5B5B5B6484890C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C895B5B5B5B5B5B
	OCTA 	#5B5B890C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C7B5B,#5B5B5B5B5B5B5B5B,#5B5B5B5B5B7B0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C6C5B5B5B5B5B5B,#5B5B6C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C665B,#5B5B5B5B5B5B5B5B
	OCTA 	#5B5B5B5B5B660C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#895B5B5B5B5B5B5B,#5B5B5B890C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C6C5B
	OCTA 	#5B5B5B5B5B5BBF5B,#5B5B5B5B5B660C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#615B5B5B5B5B5B5B
	OCTA 	#5B5B5B610C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C895B,#5B5BBFBF5BBFBF5B,#5B5B5B5B5B7B0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C89
	OCTA 	#5B5B5B5B5B5B5B5B,#5B5B5B5B890C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C635B,#5B5B5BBFBFBFBF5B
	OCTA 	#5B5B5B5B5B630C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C84,#5B5B5B5B5B5B5B5B,#5B5B5B5B840C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C635B
	OCTA 	#5B5B5B5BBFBFBFBF,#BFBF5B5B5B6E0C0C,#0C0C0C0C0C0C0C89
	OCTA 	#7B66667B636E6C84,#756C7B6C665B5B66,#6C7B948989380C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C385B,#5B5B5B5B5B5B5B5B
	OCTA 	#5B5B5B5B5B380C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C3889
	OCTA 	#89947B6C665B5B66,#6C7B6C7584666363,#896C667B890C0C0C
	OCTA 	#0C0C0C0C0C0C665B,#5B5B5BBFBFBFBF5B,#5B5B5B5B5B6C0C0C
	OCTA 	#0C0C0C0C0C0C8984,#5B5B5B5B5B5B5B5B,#5B5B5B5B5B5B5B5B
	OCTA 	#5B5B5B5B5B5B8489,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C895B
	OCTA 	#5B5B5B5B5BEB5B5B,#5B5B5B5B5B890C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C89845B5B,#5B5B5B5B5B5B5B5B,#5B5B5B5B5B5B5B5B
	OCTA 	#5B5B5B5B84990C0C,#0C0C0C0C0C0C845B,#5B5BBFBF5BBFBF5B
	OCTA 	#5B5B5B5B5B840C0C,#0C0C0C0C0C0C9964,#5B5B5B5B5B5B5B5B
	OCTA 	#5B5B5B5B5B5B5B5B,#5B5B5B5B5B5B5B5B,#61890C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C895B,#5B5B5B5B5BEBEB5B,#EBEB5B5B5B890C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C89615B5B5B5B,#5B5B5B5B5B5B5B5B
	OCTA 	#5B5B5B5B5B5B5B5B,#5B5B5B5B64890C0C,#0C0C0C0C0C0C755B
	OCTA 	#5B5B5B5B5B5BBF5B,#5B5B5B5B5B750C0C,#0C0C0C0C0C0C845B
	OCTA 	#5B5B5B5B5B5B5B5B,#5B5B5B5B5B5B5B5B,#5B5B5B5B5B5B5B5B
	OCTA 	#5B5B6C890C0C0C0C,#0C0C0C0C0C0C945B,#5B5B5B5B5BEBEBEB
	OCTA 	#EB5B5B5B5B940C0C,#0C0C0C0C0C0C0C0C,#896C5B5B5B5B5B5B
	OCTA 	#5B5B5B5B5B5B5B5B,#5B5B5B5B5B5B5B5B,#5B5B5B5B5B890C0C
	OCTA 	#0C0C0C0C0C0C6C5B,#5B5B5B5B5B5B5B5B,#5B5B5B5B5B6C0C0C
	OCTA 	#0C0C0C0C0C0C895B,#5B5B5B5B5BBF5B5B,#5B5B5B5B5B5B5B5B
	OCTA 	#5BEB5B5B5B5B5B5B,#5B5B5B5B890C0C0C,#0C0C0C0C0C0C7B5B
	OCTA 	#5B5BEBEBEBEBEBEB,#5B5B5B5B5B7B0C0C,#0C0C0C0C0C0C0C89
	OCTA 	#5B5B5B5B5B5B5B5B,#EB5B5B5BEB5B5B5B,#5B5B5B5BBF5B5B5B
	OCTA 	#BF5B5B5B5B890C0C,#0C0C0C0C0C0C7B5B,#5B5B5B5B5B5B5B5B
	OCTA 	#5B5B5B5B5B7B0C0C,#0C0C0C0C0C0C755B,#5B5B5B5B5BBF5B5B
	OCTA 	#5B5B5B5B5B5B5B5B,#5BEB5B5B5B5B5B5B,#5B5B5B5B5B890C0C
	OCTA 	#0C0C0C0C0C0C6C5B,#5B5B5B5B5BEBEBEB,#EB5B5B5B5B6C0C0C
	OCTA 	#0C0C0C0C0C0C895B,#5B5B5B5B5B5B5B5B,#EBEB5BEBEB5B5B5B
	OCTA 	#5B5B5B5BBFBF5BBF,#BF5B5B5B5B750C0C,#0C0C0C0C0C0C6C5B
	OCTA 	#5B5B5B5B5B5B5B5B,#5B5B5B5B5B6C0C0C,#0C0C0C0C0C0C615B
	OCTA 	#5B5B5B5B5BBF5B5B,#5B5B5B5B5B5B5B5B,#5BEB5B5B5B5B5B5B
	OCTA 	#5B5B5B5B5B920C0C,#0C0C0C0C0C0C665B,#5B5B5B5B5BEBEB5B
	OCTA 	#EBEB5B5B5B660C0C,#0C0C0C0C0C0C925B,#5B5B5B5B5B5B5B5B
	OCTA 	#5BEBEBEB5B5B5B5B,#5B5B5B5B5BBFBFBF,#5B5B5B5B5B610C0C
	OCTA 	#0C0C0C0C0C0C665B,#5B5B5B5B5B5B5B5B,#5B5B5B5B5B660C0C
	OCTA 	#0C0C0C0C0C0C5B5B,#5B5BBFBFBFBFBFBF,#BF5B5B5B5B5BEBEB
	OCTA 	#EBEBEBEBEB5B5B5B,#5B5B5B5B5B640C0C,#0C0C0C0C0C0C5B5B
	OCTA 	#5B5B5B5B5BEB5B5B,#5B5B5B5B5B5B0C0C,#0C0C0C0C0C0C645B
	OCTA 	#5B5B5B5B5B5B5B5B,#EBEBEBEBEB5B5B5B,#5B5B5B5BBFBFBFBF
	OCTA 	#BF5B5B5B5B5B0C0C,#0C0C0C0C0C0C5B5B,#5B5B5B5B5B5B5B5B
	OCTA 	#5B5B5B5B5B5B0C0C,#0C0C0C0C0C0C5B5B,#5B5B5BBFBFBFBFBF
	OCTA 	#5B5B5B5B5B5B5BEB,#EBEBEBEB5B5B5B5B,#5B5B5B5B5B640C0C
	OCTA 	#0C0C0C0C0C0C5B5B,#5B5B5B5B5B5B5B5B,#5B5B5B5B5B5B0C0C
	OCTA 	#0C0C0C0C0C0C645B,#5B5B5B5B5B5B5BEB,#EBEBEBEBEBEB5B5B
	OCTA 	#5B5B5BBFBFBFBFBF,#BFBF5B5B5B5B0C0C,#0C0C0C0C0C0C5B5B
	OCTA 	#5B5B5B5B5B5BEB5B,#5B5B5B5B5B5B0C0C,#0C0C0C0C0C0C615B
	OCTA 	#5B5B5B5BBFBFBF5B,#5B5B5B5B5B5B5B5B,#EBEBEB5B5B5B5B5B
	OCTA 	#5B5B5B5B5B920C0C,#0C0C0C0C0C0C665B,#5B5B5B5B5B5B5B5B
	OCTA 	#5B5B5B5B5B660C0C,#0C0C0C0C0C0C925B,#5B5B5B5B5B5B5B5B
	OCTA 	#5B5BEB5B5B5B5B5B,#5B5B5B5B5B5BBF5B,#5B5B5B5B5B610C0C
	OCTA 	#0C0C0C0C0C0C665B,#5B5BEBEB5BEBEB5B,#5B5B5B5B5B660C0C
	OCTA 	#0C0C0C0C0C0C755B,#5B5B5BBFBF5BBFBF,#5B5B5B5B5B5B5BEB
	OCTA 	#EB5BEBEB5B5B5B5B,#5B5B5B5B5B890C0C,#0C0C0C0C0C0C6C5B
	OCTA 	#5B5B5B5B5B5B5B5B,#5B5B5B5B5B6C0C0C,#0C0C0C0C0C0C895B
	OCTA 	#5B5B5B5B5B5B5B5B,#5B5BEB5B5B5B5B5B,#5B5B5B5B5B5BBF5B
	OCTA 	#5B5B5B5B5B750C0C,#0C0C0C0C0C0C6C5B,#5B5B5BEBEBEBEB5B
	OCTA 	#5B5B5B5B5B6C0C0C,#0C0C0C0C0C0C895B,#5B5B5BBF5B5B5BBF
	OCTA 	#5B5B5B5B5B5B5BEB,#5B5B5BEB5B5B5B5B,#5B5B5B5B890C0C0C
	OCTA 	#0C0C0C0C0C0C7B5B,#5B5B5B5B5B5B5B5B,#5B5B5B5B5B7B0C0C
	OCTA 	#0C0C0C0C0C0C0C89,#5B5B5B5B5B5B5B5B,#5B5BEB5B5B5B5B5B
	OCTA 	#5B5B5B5B5B5BBF5B,#5B5B5B5B5B890C0C,#0C0C0C0C0C0C7B5B
	OCTA 	#5B5B5B5BEBEBEBEB,#EBEB5B5B5B7B0C0C,#0C0C0C0C0C0C895B
	OCTA 	#5B5B5B5B5B5B5B5B,#5B5B5B5B5B5B5B5B,#5B5B5B5B5B5B5B5B
	OCTA 	#5B5B6C890C0C0C0C,#0C0C0C0C0C0C6C5B,#5B5B5B5B5B5B5B5B
	OCTA 	#5B5B5B5B5B6C0C0C,#0C0C0C0C0C0C0C0C,#896C5B5B5B5B5B5B
	OCTA 	#5B5B5B5B5B5B5B5B,#5B5B5B5B5B5B5B5B,#5B5B5B5B5B840C0C
	OCTA 	#0C0C0C0C0C0C945B,#5B5B5BEBEBEBEB5B,#5B5B5B5B5B940C0C
	OCTA 	#0C0C0C0C0C0C8964,#5B5B5B5B5B5B5B5B,#5B5B5B5B5B5B5B5B
	OCTA 	#5B5B5B5B5B5B5B5B,#61890C0C0C0C0C0C,#0C0C0C0C0C0C755B
	OCTA 	#5B5B5B5B5BBF5B5B,#5B5B5B5B5B750C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C89615B5B5B5B,#5B5B5B5B5B5B5B5B,#5B5B5B5B5B5B5B5B
	OCTA 	#5B5B5B5B64990C0C,#0C0C0C0C0C0C895B,#5B5BEBEB5BEBEB5B
	OCTA 	#5B5B5B5B5B890C0C,#0C0C0C0C0C0C9984,#5B5B5B5B5B5B5B5B
	OCTA 	#5B5B5B5B5B5B5B5B,#5B5B5B5B5B5B8489,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C845B,#5B5B5B5B5BBFBF5B,#BFBF5B5B5B840C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C89845B5B,#5B5B5B5B5B5B5B5B
	OCTA 	#5B5B5B5B5B5B5B5B,#5B5B5B5B84890C0C,#0C0C0C0C0C0C895B
	OCTA 	#5B5B5B5B5B5BEB5B,#5B5B5B5B5B890C0C,#0C0C0C0C0C0C0C89
	OCTA 	#7B666C8963636684,#756C7B6C665B5B66,#6C7B948989380C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C6C5B,#5B5B5B5B5BBFBFBF
	OCTA 	#BF5B5B5B5B660C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C3889
	OCTA 	#89947B6C665B5B66,#6C7B6C75846C6E63,#7B66667B890C0C0C
	OCTA 	#0C0C0C0C0C0C385B,#5B5B5B5B5B5B5B5B,#5B5B5B5B5B380C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C6E5B
	OCTA 	#5B5BBFBFBFBFBFBF,#5B5B5B5B5B630C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C84,#5B5B5B5B5B5B5B5B
	OCTA 	#5B5B5B5B840C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C635B,#5B5B5B5B5BBFBFBF,#BF5B5B5B5B630C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C89
	OCTA 	#5B5B5B5B5B5B5B5B,#5B5B5B5B890C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C7B5B,#5B5B5B5B5BBFBF5B
	OCTA 	#BFBF5B5B5B890C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#615B5B5B5B5B5B5B,#5B5B5B610C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C665B
	OCTA 	#5B5B5B5B5BBF5B5B,#5B5B5B5B5B6C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#895B5B5B5B5B5B5B
	OCTA 	#5B5B5B890C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C665B,#5B5B5B5B5B5B5B5B,#5B5B5B5B5B660C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C6C5B5B5B5B5B5B,#5B5B6C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C7B5B,#5B5B5B5B5B5B5B5B
	OCTA 	#5B5B5B5B5B7B0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C895B5B5B5B5B5B,#5B5B890C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C8984
	OCTA 	#645B5B5B5B5B5B5B,#5B5B5B6484890C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C895B5B5B5B5B
	OCTA 	#5B890C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C89,#99848975615B5B61,#75898989990C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C8992646492,#890C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C89947061,#898989890C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#8989898989899C89
	OCTA 	#898989890C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C33
	OCTA 	#8989898961709489,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0CEBEBEBEB,#EBEBEBEB0C0C0CEB,#EBEBEBEBEBEBEB0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C896C5B5B5B9C
	OCTA 	#FEFEFEFEA5890C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#8999895B5B5B5B5B,#5B6699890C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C89A5,#FEFEFE5D9C5B5B5B,#6C890C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0CEBEBEBEB,#EBEBEBEB0C0C0CEB
	OCTA 	#EBEBEBEBEBEBEB0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C945B5B5B5B5BE5,#FEFEFEFEE55B940C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C8970,#5B5B5B5B5B5B5B5B,#5B5B5B5B70890C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C945BE5,#FEFEFEFEE55B5B5B
	OCTA 	#5B5B940C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0CEBEBEBEB
	OCTA 	#EBEBEBEBEBEBEBEB,#EBEBEBEBEBEBEB0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C4B,#845B5B5B5B5B92FE,#FEFEFEFEFE925B84
	OCTA 	#8A0C0C0C0C0C0C0C,#0C0C0C0C89705B5B,#5B5B5B5B5B5B5B5B
	OCTA 	#5B5B5B5B5B5B7089,#0C0C0C0C0C0C0C0C,#0C0C0C38845B92FE
	OCTA 	#FEFEFEFEFE925B5B,#5B5B5B84380C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0CEBEBEB0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C84,#5B5B5B5B5B5BC2FE
	OCTA 	#FEFEFEFEFEC25B5B,#840C0C0C0C0C0C0C,#0C0C0C9F5B5B5B5B
	OCTA 	#5B5B5B5B5B5B5B5B,#5B5B5B5B5B5B5B5B,#9F0C0C0C0C0C0C0C
	OCTA 	#0C0C0C845B5BC2FE,#FEFEFEFEFEC25B5B,#5B5B5B5B840C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C89EBEBEB89
	OCTA 	#890C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C9F5B
	OCTA 	#5B5B5B5B5B5BDBFE,#FEFEFEFEFEDB5B5B,#5B9F0C0C0C0C0C0C
	OCTA 	#0C8A845B5B5B5B5B,#5B5B5B5B5B5B5B5B,#5B5B5B5B5B5B5B5B
	OCTA 	#5B84380C0C0C0C0C,#0C0C9F5B5B5BDBFE,#FEFEFEFEFEDB5B5B
	OCTA 	#5B5B5B5B5B9F0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#8999665BEBEBEB5B,#5B6699890C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C895B5B,#5B5B5B5B5B5BF4FE,#FEFEFEFEFEF45B5B
	OCTA 	#5B5B890C0C0C0C0C,#0C845B5B5B5B5B5B,#5B5B5B5B5B5B5B5B
	OCTA 	#5B5B5B5B5B5B5B5B,#5B5B840C0C0C0C0C,#0C895B5B5B5BF4FE
	OCTA 	#FEFEFEFEFEF45B5B,#5B5B5B5B5B5B890C,#0C0C0CEBEBEB0C0C
	OCTA 	#0C0C0C0C0C0C8970,#5B5B5B5BEBEBEB5B,#5B5B5B5B70890C0C
	OCTA 	#0C0C0C0C0C0CEBEB,#EB0C0C0C0C705B5B,#5B5B5B5B5B5BFEFE
	OCTA 	#FEFEFEFEFEFE5B5B,#5B5B700C0C0C0C0C,#945B5B5B5B5B5B5B
	OCTA 	#5B5B5B5B5B5B5B5B,#5B5B5B5B5B5B5B5B,#5B5B5B940C0C0C0C
	OCTA 	#0C705B5B5B5BFEFE,#FEFEFEFEFEFE5B5B,#5B5B5B5B5B5B700C
	OCTA 	#0C0C0CEBEBEB0C0C,#0C0C0C0C89705B5B,#5B5B5B5BEBEBEB5B
	OCTA 	#5B5B5B5B5B5B7089,#0C0C0C0C0C0CEBEB,#EB0C0C0C895B5B5B
	OCTA 	#5B5B5B5B5B5BFE0C,#0C0CFEFEFEFE5B5B,#5B5B5B890C0C0C89
	OCTA 	#5B92C2DBF4FEFEF4,#DBC2925B5B5B5B5B,#5B92C2DBF4FEFEF4
	OCTA 	#DBC2925B890C0C0C,#895B5B5B5B5BFEFE,#FEFE0C0C0CFE5B5B
	OCTA 	#5B5B5B5B5B5B5B89,#0C0C0CEBEBEB0C0C,#0C0C0C9F5B5B5B5B
	OCTA 	#5B5B5B5BEBEBEB5B,#5B5B5B5B5B5B5B5B,#9F0C0C0C0C0CEBEB
	OCTA 	#EB0C0C0C705B5B5B,#5B5B5B5B5B5B0C0C,#0C0C0CFEFEF45B5B
	OCTA 	#5B5B5B700C0C0CA5,#E5FEFEFEFEFEFEFE,#FEFEFEE59C5B5B9C
	OCTA 	#E5FEFEFEFEFEFEFE,#FEFEFEE5A5330C0C,#705B5B5B5B5BF4FE
	OCTA 	#FE0C0C0C0C255B5B,#5B5B5B5B5B5B5B70,#0C0C0CEBEBEB0C0C
	OCTA 	#0C38845B5B5B5B5B,#5B5B5B5B5B5B5B5B,#5B5B5B5B5B5B5B5B
	OCTA 	#5B844B0C0C0CEBEB,#EB0C0C895B5B5B5B,#5B5B5B5B5B5B0C0C
	OCTA 	#0C0C0CFEFEDB5B5B,#5B5B5B5B898989FE,#FEFEFEFEFEFEFEFE
	OCTA 	#FEFEFEFEFEA5A5FE,#FEFEFEFEFEFEFEFE,#FEFEFEFEFE898989
	OCTA 	#5B5B5B5B5B5BDBFE,#FE0C0C0C0C3C5B5B,#5B5B89895B5B5B5B
	OCTA 	#890C0CEBEBEB0C0C,#0C845B5B5B5B5B5B,#89895B5B5B5B5B5B
	OCTA 	#5B89895B5B5B5B5B,#5B5B840C0C0CEBEB,#EB0C0C995B5B5B5B
	OCTA 	#89895B5B5B5B0C0C,#0C0C0CFEFEC25B5B,#5B5B5B5B998989FE
	OCTA 	#FEFEFEFEFEFEFE0C,#0C0CFEFEFEECECFE,#FEFE0C0C0CFEFEFE
	OCTA 	#FEFEFEFEFE898999,#5B5B5B5B5B5BC2FE,#FE0C0C0C0C4F5B5B
	OCTA 	#5B5B89895B5B5B5B,#990C0CEBEBEB0C0C,#945B5B5B5B5B5B5B
	OCTA 	#89895B5B5B5B5B5B,#5B89895B5B5B5B5B,#5B5B5B940C0CEBEB
	OCTA 	#EB0C0C665B5B5B5B,#89895B5B5B5B920C,#0C0CFEFEFE925B5B
	OCTA 	#5B5B5B5B898989FE,#FEFEFEFEFEFE0C0C,#0C0C0CFEFEECECFE
	OCTA 	#FE0C0C0C0C0CFEFE,#FEFEFEFEFE898966,#5B5B5B5B5B5B92FE
	OCTA 	#FEFE0C0C0C925B5B,#5B5B5B5B5B5B5B5B,#660C0CEBEBEB0C89
	OCTA 	#5B5B5B5B5B5B5B5B,#5B5B5B5B5B5B5B5B,#5B5B5B5B5B5B5B5B
	OCTA 	#5B5B5B5B890CEBEB,#EB0C895B5B5B5B5B,#5B5B5B5B5B5B5BE5
	OCTA 	#FEFEFEFEE55B5B5B,#5B5B5B5B5B8989FE,#FEFEFEFEFEFE0C0C
	OCTA 	#0C0C0CFEFEA5A5FE,#FE0C0C0C0C0CFEFE,#FEFEFEFE5D89895B
	OCTA 	#5B5B5B5B5B5B5BE5,#FEFEFEFEE55B5B5B,#5B5B5B5B5B5B5B5B
	OCTA 	#5B890CEBEBEB0C6C,#5B5B5B5B5B5B5B5B,#5B5B5B5B5B5B5B5B
	OCTA 	#5B5B5B5B5B5B5B5B,#5B5B5B5B6C0CEBEB,#EB0C895B5B5B5B5B
	OCTA 	#5B5B5B5B5B5B5B9C,#FEFEFEFE9C5B5B5B,#5B5B5B5B5B89619C
	OCTA 	#E5FEFEFEFEFE0C0C,#0C0C0CE59C5B5B9C,#E50C0C0C0C0CFEFE
	OCTA 	#FEFEFEE59C61895B,#5B5B5B5B5B5B5B9C,#FEFEFEFE9C5B5B5B
	OCTA 	#5B5B5B5B5BEBEBEB,#EBEBEBEB0C0C895B,#5B5B5B5B5B5B5B5B
	OCTA 	#5B5B5B5B5B5B5B5B,#5B5B5B5B5B5B5B5B,#5B5B5B5B5B890C0C
	OCTA 	#EBEBEBEBEBEBEB5B,#5B5B5B5B5B5B5B5B,#A5ECECA55B5B5B5B
	OCTA 	#5B5B5B5B5B89705B,#5B92C2DBF4FEFE0C,#0C0C925B5B5B5B5B
	OCTA 	#5B924F3C25FEFEF4,#DBC2925B5B709C5B,#5B5B5B5B5B5B5B5B
	OCTA 	#A5ECECA55B5B5B5B,#5B5B5B5B5BEBEBEB,#EBEBEBEB0C0C945B
	OCTA 	#5B5B5B5B5B5B5B5B,#5B5B5B5B5B5B5B5B,#5B5B5B5B5B5B5B5B
	OCTA 	#5B5B5B5B5B940C0C,#EBEBEBEBEBEBEB5B,#5B5B5B5B5B5B5B5B
	OCTA 	#A5ECECA55B5B5B5B,#5B5B5B5B5B9C945B,#5B5B5B5B5B5B5B5B
	OCTA 	#5B5B5B5B5B5B5B5B,#5B5B5B5B5B5B5B5B,#5B5B5B5B5B94895B
	OCTA 	#5B5B5B5B5B5B5B5B,#A5ECECA55B5B5B5B,#5B5B5B5B5BEBEBEB
	OCTA 	#EBEBEBEB0C0C705B,#5B92C2DBF4FEFE25,#3C4F925B5B5B5B5B
	OCTA 	#5B920C0C0CFEFEF4,#DBC2925B5B700C0C,#EBEBEBEBEBEBEB5B
	OCTA 	#5B5B5B5B5B5B5B9C,#FEFEFEFE9C5B5B5B,#5B5B5B5B5B89895B
	OCTA 	#5B5B5B5B5B5B5B5B,#5B5B5B5B5B5B5B5B,#5B5B5B5B5B5B5B5B
	OCTA 	#5B5B5B5B5B89895B,#5B5B5B5B5B5B5B9C,#FEFEFEFE9C5B5B5B
	OCTA 	#5B5B5B5B5B5B5B5B,#5B890CEBEBEB619C,#E5FEFEFEFEFE0C0C
	OCTA 	#0C0C0CE59C5B5B9C,#E50C0C0C0C0CFEFE,#FEFEFEE59C61EBEB
	OCTA 	#EB0C895B5B5B5B5B,#5B5B5B5B5B5B5BE5,#FEFEFEFEE55B5B5B
	OCTA 	#5B5B5B5B5B890C6C,#5B5B5B5B5B5B5B5B,#5B5B5B5B5B5B5B5B
	OCTA 	#5B5B5B5B5B5B5B5B,#5B5B5B5B6C0C895B,#5B5B5B5B5B5B5BE5
	OCTA 	#FEFEFEFEE55B5B5B,#5B5B5B5B5B5B5B5B,#5B890CEBEBEB895D
	OCTA 	#FEFEFEFEFEFE0C0C,#0C0C0CFEFEA5A5FE,#FE0C0C0C0C0CFEFE
	OCTA 	#FEFEFEFEFE89EBEB,#EB0C0C665B5B5B5B,#5B5B5B5B5B5B920C
	OCTA 	#0C0CFEFEFE925B5B,#5B5B5B5B66890C89,#5B5B5B5B5B5B5B5B
	OCTA 	#5B5B5B5B5B5B5B5B,#5B5B5B5B5B5B5B5B,#5B5B5B5B890C8989
	OCTA 	#5B5B5B5B5B5B92FE,#FEFE0C0C0C925B5B,#5B5B89895B5B5B5B
	OCTA 	#660C0CEBEBEB89FE,#FEFEFEFEFEFE0C0C,#0C0C0CFEFEECECFE
	OCTA 	#FE0C0C0C0C0CFEFE,#FEFEFEFEFE89EBEB,#EB0C0C995B5B5B5B
	OCTA 	#89895B5B5B5B4F0C,#0C0C0CFEFEC25B5B,#5B5B5B5B99890C0C
	OCTA 	#945B5B5B5B5B5B5B,#5B89895B5B5B5B5B,#5B5B89895B5B5B5B
	OCTA 	#5B5B5B940C0C8999,#5B5B5B5B5B5BC2FE,#FE0C0C0C0C0C5B5B
	OCTA 	#5B5B89895B5B5B5B,#990C0CEBEBEB89FE,#FEFEFEFEFEFEFE0C
	OCTA 	#0C0CFEFEFEECECFE,#FEFE0C0C0CFEFEFE,#FEFEFEFEFE89EBEB
	OCTA 	#EB0C0C895B5B5B5B,#89895B5B5B5B3C0C,#0C0C0CFEFEDB5B5B
	OCTA 	#5B5B5B5B89890C0C,#0C845B5B5B5B5B5B,#5B89895B5B5B5B5B
	OCTA 	#5B5B89895B5B5B5B,#5B5B840C0C0C8989,#5B5B5B5B5B5BDBFE
	OCTA 	#FE0C0C0C0C0C5B5B,#5B5B5B5B5B5B5B5B,#890C0CEBEBEB89FE
	OCTA 	#FEFEFEFEFEFEFEFE,#FEFEFEFEFEA5A5FE,#FEFEFEFEFEFEFEFE
	OCTA 	#FEFEFEFEFE89EBEB,#EB0C0C0C705B5B5B,#5B5B5B5B5B5B250C
	OCTA 	#0C0C0CFEFEF45B5B,#5B5B5B700C0C0C0C,#0C4B845B5B5B5B5B
	OCTA 	#5B5B5B5B5B5B5B5B,#5B5B5B5B5B5B5B5B,#5B84380C0C0C0C0C
	OCTA 	#705B5B5B5B5BF4FE,#FE0C0C0C0C0C5B5B,#5B5B5B5B5B5B5B70
	OCTA 	#0C0C0CEBEBEB33A5,#E5FEFEFEFEFEFEFE,#FEFEFEE59C5B5B9C
	OCTA 	#E5FEFEFEFEFEFEFE,#FEFEFEE5A50CEBEB,#EB0C0C0C895B5B5B
	OCTA 	#5B5B5B5B5B5BFE0C,#0C0CFEFEFEFE5B5B,#5B5B5B890C0C0C0C
	OCTA 	#0C0C0C9F5B5B5B5B,#5B5B5B5B5BEBEBEB,#5B5B5B5B5B5B5B5B
	OCTA 	#9F0C0C0C0C0C0C0C,#895B5B5B5B5BFEFE,#FEFE0C0C0CFE5B5B
	OCTA 	#5B5B5B5B5B5B5B89,#0C0C0CEBEBEB0C89,#5B92C2DBF4FEFEF4
	OCTA 	#DBC2925B5B5B5B5B,#5B92C2DBF4FEFEF4,#DBC2925B890CEBEB
	OCTA 	#EB0C0C0C0C705B5B,#5B5B5B5B5B5BFEFE,#FEFEFEFEFEFE5B5B
	OCTA 	#5B5B700C0C0C0C0C,#0C0C0C0C89705B5B,#5B5B5B5B5BEBEBEB
	OCTA 	#5B5B5B5B5B5B7089,#0C0C0C0C0C0C0C0C,#0C705B5B5B5BFEFE
	OCTA 	#FEFEFEFEFEFE5B5B,#5B5B5B5B5B5B700C,#0C0C0CEBEBEB0C0C
	OCTA 	#945B5B5B5B5B5B5B,#5B5B5B5B5B5B5B5B,#5B5B5B5B5B5B5B5B
	OCTA 	#5B5B5B940C0CEBEB,#EB0C0C0C0C895B5B,#5B5B5B5B5B5BF4FE
	OCTA 	#FEFEFEFEFEF45B5B,#5B5B890C0C0C0C0C,#0C0C0C0C0C0C8970
	OCTA 	#5B5B5B5B5BEBEBEB,#5B5B5B5B70890C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C895B5B5B5BF4FE,#FEFEFEFEFEF45B5B,#5B5B5B5B5B5B890C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C845B5B5B5B5B5B,#5B5B5B5B5B5B5B5B
	OCTA 	#5B5B5B5B5B5B5B5B,#5B5B840C0C0C0C0C,#0C0C0C0C0C0C9F5B
	OCTA 	#5B5B5B5B5B5BDBFE,#FEFEFEFEFEDB5B5B,#5B9F0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#8999665B5BEBEBEB,#5B6699890C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C9F5B5B5BDBFE,#FEFEFEFEFEDB5B5B
	OCTA 	#5B5B5B5B5B9F0C0C,#0C0C0C0C0C0C0C0C,#0C38845B5B5B5B5B
	OCTA 	#5B5B5B5B5B5B5B5B,#5B5B5B5B5B5B5B5B,#5B848A0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C84,#5B5B5B5B5B5BC2FE,#FEFEFEFEFEC25B5B
	OCTA 	#840C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C8989EBEBEB
	OCTA 	#890C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C845B5BC2FE
	OCTA 	#FEFEFEFEFEC25B5B,#5B5B5B5B840C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C9F5B5B5B5B,#5B5B5B5B5B5B5B5B,#5B5B5B5B5B5B5B5B
	OCTA 	#9F0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C38,#845B5B5B5B5B92FE
	OCTA 	#FEFEFEFEFE925B84,#380C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0CEBEBEB,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C8A845B92FE,#FEFEFEFEFE925B5B,#5B5B5B844B0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C89705B5B,#5B5B5B5B5B5B5B5B
	OCTA 	#5B5B5B5B5B5B7089,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C945B5B5B5B5BE5,#FEFEFEFEE55B940C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0CEBEBEB,#EBEBEBEBEBEBEBEB,#EBEBEBEBEBEBEBEB
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C945BE5,#FEFEFEFEE55B5B5B
	OCTA 	#5B5B940C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C8970
	OCTA 	#5B5B5B5B5B5B5B5B,#5B5B5B5B70890C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C896C5B5B5B9C,#5DFEFEFEA5890C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0CEBEBEB,#EBEBEBEBEB0C0C0C
	OCTA 	#EBEBEBEBEBEBEBEB,#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C89A5
	OCTA 	#FEFEFEFE9C5B5B5B,#6C890C0C0C0C0C0C,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#8999665B5B5B5B5B,#5B8999890C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C89947061
	OCTA 	#89898989330C0C0C,#0C0C0C0C0C0C0C0C,#0C0C0C0C0CEBEBEB
	OCTA 	#EBEBEBEBEB0C0C0C,#EBEBEBEBEBEBEBEB,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#8989898961709489,#0C0C0C0C0C0C0C0C
	OCTA 	#0C0C0C0C0C0C0C0C,#0C0C0C0C0C0C0C0C,#89898989899C8989
	OCTA 	#898989890C0C0C0C,#0C0C0C0C0C0C0000,#0000000000000000


args	WYDE	0,0,640,0
		OCTA	bitmaps
		
