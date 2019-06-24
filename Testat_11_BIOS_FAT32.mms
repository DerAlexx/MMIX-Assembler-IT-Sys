%	this is a generic MMIX BIOS
%	it is considert to be in ROM mapped
%	at physical address 0000 0000 0000 0000
%	used with
%	virtual address 8000 0000 0000 0000

%	Definition of Constants

%	Physical Addresses and Interrupt Numbers of Devices
                PREFIX :RAM:
HI              IS     #8000
MH              IS     #0001


LoRAM           IS     #8000000100000000               The RAM starts here (virtual address)
PageSize        IS     #0000000000002000               The size of one page
LoOSSize        IS     8*PageSize                      The size reserved  for the OS
8H              IS     @                               Last position in ROM

OS_SP           IS     :RAM:LoRAM
User_SP         IS     :RAM:LoRAM+8

REG_TOS         IS     LoRAM+PageSize                  After one page of general purpose RAM, we start the Register Stack
GCC_TOS         IS     LoRAM+LoOSSize-8                The gcc stack grows down form here (the -8 is not strictly necessary)
UserRAM         IS     LoRAM+LoOSSize                  The RAM starting here is mapped by the page table into user space.
UserRAM         IS     LoRAM+LoOSSize                  The RAM starting here is mapped by the page table into user space.

                PREFIX :FLASH:
HI              IS     #8000                           physical address
MH              IS     #0002
USERHI          IS     #2000                           virtual mapped address
USERML          IS     #0001

                PREFIX :VRAM:
HI              IS     #8002

                PREFIX :IO:
HI              IS     #8001
Keyboard        IS     #00
Screen          IS     #08
Mouse           IS     #10
GPU             IS     #20
Timer           IS     #60
Serial          IS     #80
Sevensegment    IS     #90
Led0            IS     #B0
Led1            IS     #B8
Led2            IS     #C0
Led3            IS     #C8
Disk            IS     #D0
Sound           IS     #200

                PREFIX :Interrupt:

Keyboard        IS     40
Screen          IS     41
Mouse           IS     42
GPU             IS     43
Timer           IS     44
SerialIn        IS     45
SerialOut       IS     46
Disk            IS     47
Button          IS     48
Button1         IS     49
Button2         IS     50
Button3         IS     51
Sound           IS     52

%	Code


                LOC    #8000000000000000

                PREFIX :Boot:
tmp             IS     $0

%		page table setup (see small model in address.howto)

:Main           IS     @                               dummy	Main, to keep mmixal happy
:Boot           GETA   tmp,:DTrap                      set dynamic- and forced-trap  handler
                PUT    :rTT,tmp
                GETA   tmp,:FTrap
                PUT    :rT,tmp
                PUSHJ  tmp,:memory                     initialize the memory setup

%		PUSHJ	tmp,:gui		       initialize the GUI setup
%		PUSHJ		tmp,:MP3Init

                GET    tmp,:rQ
                PUT    :rQ,0                           clear interrupts

%	here we start a loaded user program
%       rXX should be #FB0000FF = UNSAVE $255
%	rBB is coppied to $255, it should be the place in the stack
%	where UNSAVE will find its data
%	rWW should be the entry point in the main program,
%	thats where the program
%	continues after the UNSAVE.
%	If no program is loaded, rXX will be 0, that is TRAP 0,Halt,0
%	and we end the program before it has started in the Trap handler.

                NEG    $255,1                          enable interrupt $255->rK with resume 1
                RESUME 1                               loading a file sets up special registers for that

%	Dynamic Trap Handling

                PREFIX :DTrap:

:DTrap          PUSHJ  $255,Handler
                PUT    :rJ,$255
                NEG    $255,1                          enable interrupt $255->rK with resume 1
                RESUME 1

tmp             IS     $0
ibits           IS     $1
inumber         IS     $2
base            IS     $3

Handler         GET    ibits,:rQ
                SUBU   tmp,ibits,1                     from xxx...xxx1000 to xxx...xxx0111
                SADD   inumber,tmp,ibits               position of lowest bit
                ANDN   tmp,ibits,tmp                   the lowest bit
                ANDN   tmp,ibits,tmp                   delete lowest bit
                PUT    :rQ,tmp                         and return to rQ
                SLU    tmp,inumber,2                   scale
                GETA   base,Table                      and jump
                GO     tmp,base,tmp


Table           JMP    PowerFail                       0	the machine bits
                JMP    MemParityError                  1
                JMP    MemNonExiistent                 2
                JMP    Unhandled                       3
                JMP    Reboot                          4
                JMP    Unhandled                       5
                JMP    PageTableError                  6
                JMP    Intervall                       7

                JMP    Unhandled                       8
                JMP    Unhandled                       9
                JMP    Unhandled                       10
                JMP    Unhandled                       11
                JMP    Unhandled                       12
                JMP    Unhandled                       13
                JMP    Unhandled                       14
                JMP    Unhandled                       15

                JMP    Unhandled                       16
                JMP    Unhandled                       17
                JMP    Unhandled                       18
                JMP    Unhandled                       19
                JMP    Unhandled                       20
                JMP    Unhandled                       21
                JMP    Unhandled                       22
                JMP    Unhandled                       23
                JMP    Unhandled                       24
                JMP    Unhandled                       25
                JMP    Unhandled                       26
                JMP    Unhandled                       27
                JMP    Unhandled                       28
                JMP    Unhandled                       29
                JMP    Unhandled                       30
                JMP    Unhandled                       31

                JMP    Privileged                      32	  Program bits
                JMP    Security                        33
                JMP    RuleBreak                       34
                JMP    KernelOnly                      35
                JMP    TanslationBypass                36
                JMP    NoExec                          37
                JMP    NoWrite                         38
                JMP    NoRead                          39

                JMP    Ignore                          40  Keyboard currently ignored
                JMP    Screen                          41
                JMP    Mouse                           42
                JMP    GPU                             43
                JMP    Timer                           44
                JMP    SerialIn                        45
                JMP    SerialOut                       46
                JMP    Disk                            47

                JMP    Button                          48
                JMP    Unhandled                       49
                JMP    Unhandled                       50
                JMP    Unhandled                       51
                JMP    Ignore                          52 Sound currently ignored
                JMP    Unhandled                       53
                JMP    Unhandled                       54
                JMP    Unhandled                       55
                JMP    Unhandled                       56
                JMP    Unhandled                       57
                JMP    Unhandled                       58
                JMP    Unhandled                       59
                JMP    Unhandled                       60
                JMP    Unhandled                       61
                JMP    Unhandled                       62
                JMP    Unhandled                       63
                JMP    Ignore                          64  rQ was zero

%	Default Dynamic Trap Handlers

Unhandled       GETA   tmp,1F
                SWYM   tmp,5                           tell the debugger
                POP    0,0
1H              BYTE   "DEBUG Trap unhandled",0

Ignore          POP    0,0

%	Required Dynamic Trap Handlers

Reboot          GETA   tmp,1F
                SWYM   tmp,5                           tell the debugger
                JMP    :Boot
1H              BYTE   "DEBUG Rebooting",0


MemParityError  GETA   tmp,1F
                SWYM   tmp,5                           tell the debugger
                POP    0,0
1H              BYTE   "DEBUG Memory parity error",0


MemNonExiistent GETA   tmp,1F
                SWYM   tmp,5                           tell the debugger
                POP    0,0
1H              BYTE   "DEBUG Access to nonexistent Memory",0


PowerFail       GETA   tmp,1F
                SWYM   tmp,5                           tell the debugger
                POP    0,0
1H              BYTE   "DEBUG Power Fail - switching to battery ;-)",0


PageTableError  GETA   tmp,1F
                SWYM   tmp,5                           tell the debugger
                POP    0,0
1H              BYTE   "DEBUG Error in page table structure",0


Intervall       GETA   tmp,1F
                SWYM   tmp,5                           tell the debugger
                POP    0,0
1H              BYTE   "DEBUG Intervall Counter rI is zero",0



Privileged      GETA   tmp,1F
                SWYM   tmp,5                           tell the debugger
                POP    0,0
1H              BYTE   "DEBUG Privileged Instruction",0


Security        GETA   tmp,1F
                SWYM   tmp,5                           tell the debugger
                POP    0,0
1H              BYTE   "DEBUG Security violation",0


RuleBreak       GETA   tmp,1F
                SWYM   tmp,5                           tell the debugger
                POP    0,0
1H              BYTE   "DEBUG Illegal Instruction",0


KernelOnly      GETA   tmp,1F
                SWYM   tmp,5                           tell the debugger
                POP    0,0
1H              BYTE   "DEBUG Instruction for kernel use only",0


TanslationBypass GETA  tmp,1F
                SWYM   tmp,5                           tell the debugger
                POP    0,0
1H              BYTE   "DEBUG Illegal access to negative address",0


NoExec          GETA   tmp,1F
                SWYM   tmp,5                           tell the debugger
                POP    0,0
1H              BYTE   "DEBUG Missing execute permission",0


NoWrite         GETA   tmp,1F
                SWYM   tmp,5                           tell the debugger
                POP    0,0
1H              BYTE   "DEBUG  Missing write permission",0


NoRead          GETA   tmp,1F
                SWYM   tmp,5                           tell the debugger
                POP    0,0
1H              BYTE   "DEBUG Missing read permission",0


%	Devicespecific Dynamic Trap Handlers

                PREFIX Keyboard:

base            IS     $1
data            IS     $2
count           IS     $3
return          IS     $4
tmp             IS     $5
%	echo a character from the keyboard
:DTrap:Keyboard SETH   base,:IO:HI
                LDO    data,base,:IO:Keyboard          keyboard status/data
                BN     data,1F
                SR     count,data,32
                AND    count,count,#FF
                BZ     count,1F
                GET    return,:rJ
                AND    tmp+1,data,#FF
                PUSHJ  tmp,:ScreenC
                PUT    :rJ,return
1H              POP    0,0

:DTrap:Screen   IS     :DTrap:Ignore
:DTrap:Mouse    IS     :DTrap:Ignore
:DTrap:GPU      IS     :DTrap:Ignore
:DTrap:Timer    IS     :DTrap:Ignore
:DTrap:Disk     IS     :DTrap:Ignore
:DTrap:SerialIn IS     :DTrap:Ignore
:DTrap:SerialOut IS    :DTrap:Ignore
:DTrap:Button   IS     :DTrap:Ignore


%	Forced Trap Handling

                PREFIX :FTrap:

%		Entry point for a forced TRAP
:FTrap          PUSHJ  $255,Handler
                PUT    :rJ,$255
                NEG    $255,1                          enable interrupt $255->rK with resume 1
                RESUME 1


tmp             IS     $0
instr           IS     $1
Y               IS     $2

Handler         GET    instr,:rXX
                BNN    instr,1F
                SRU    tmp,instr,24
                AND    tmp,tmp,#FF                     the opcode
                BZ     tmp,Trap
1H              POP    0,0                             not a TRAP or ropcode>=0

%       Handle a TRAP Instruction
Trap            SRU    Y,instr,8
                AND    Y,Y,#FF                         the Y value (the function code)
                GETA   tmp,Table
                SL     Y,Y,2
                GO     tmp,tmp,Y                       Jump into the Trap Table

Table           JMP    Halt                            0
                JMP    Fopen                           1
                JMP    Fclose                          2
                JMP    Fread                           3
                JMP    Fgets                           4
                JMP    Fgetws                          5
                JMP    Fwrite                          6
                JMP    Fputs                           7
                JMP    Fputws                          8
                JMP    Fseek                           9
                JMP    Ftell                           a
                JMP    Unhandled                       b
                JMP    Unhandled                       c
                JMP    Unhandled                       d
                JMP    Unhandled                       e
                JMP    Idle                            f


                JMP    TWait                           10
                JMP    TDate                           11
                JMP    TTimeOfDay                      12
                JMP    Unhandled                       13
                JMP    Unhandled                       14
                JMP    Unhandled                       15
                JMP    Unhandled                       16
                JMP    Unhandled                       17
                JMP    Unhandled                       18
                JMP    Unhandled                       19
                JMP    Unhandled                       1a
                JMP    Unhandled                       1b
                JMP    Unhandled                       1c
                JMP    Unhandled                       1d
                JMP    Unhandled                       1e
                JMP    Unhandled                       1f

                JMP    GPutBmp                         20
                JMP    GPutDIB                         21
                JMP    GSize                           22
                JMP    GSetWH                          23
                JMP    GSetPos                         24
                JMP    GSetTextColor                   25
                JMP    GSetFillColor                   26
                JMP    GSetLineColor                   27
                JMP    GPutPixel                       28
                JMP    GPutChar                        29
                JMP    GPutStr                         2A
                JMP    GLine                           2B
                JMP    GRectangle                      2C
                JMP    GBitBlt                         2D
                JMP    GBitBltIn                       2E
                JMP    GBitBltOut                      2F

                JMP    MWait                           30
                JMP    Unhandled                       31
                JMP    Unhandled                       32
                JMP    Unhandled                       33
                JMP    Unhandled                       34
                JMP    Unhandled                       35
                JMP    Unhandled                       36
                JMP    Unhandled                       37
                JMP    KGet                            38
                JMP    KStatus                         39
                JMP    KWait                           3a
                JMP    Unhandled                       3b
                JMP    Unhandled                       3c
                JMP    Unhandled                       3d
                JMP    Unhandled                       3e
                JMP    Unhandled                       3f

                JMP    BWait                           40
                JMP    Unhandled                       41
                JMP    Unhandled                       42
                JMP    Unhandled                       43
                JMP    Unhandled                       44
                JMP    Unhandled                       45
                JMP    Unhandled                       46
                JMP    Unhandled                       47
                JMP    VPut                            48
                JMP    VGet                            49
                JMP    Unhandled                       4a
                JMP    Unhandled                       4b
                JMP    Unhandled                       4c
                JMP    Unhandled                       4d
                JMP    Unhandled                       4e
                JMP    Unhandled                       4f

                JMP    SSet                            50
                JMP    SDecimal                        51
                JMP    Unhandled                       52
                JMP    Unhandled                       53
                JMP    Unhandled                       54
                JMP    Unhandled                       55
                JMP    Unhandled                       56
                JMP    Unhandled                       57
                JMP    Unhandled                       58
                JMP    Unhandled                       59
                JMP    Unhandled                       5a
                JMP    Unhandled                       5b
                JMP    Unhandled                       5c
                JMP    Unhandled                       5d
                JMP    Unhandled                       5e
                JMP    Unhandled                       5f

                JMP    Unhandled                       60
                JMP    Unhandled                       61
                JMP    Unhandled                       62
                JMP    Unhandled                       63
                JMP    Unhandled                       64
                JMP    Unhandled                       65
                JMP    Unhandled                       66
                JMP    Unhandled                       67
                JMP    Unhandled                       68
                JMP    Unhandled                       69
                JMP    Unhandled                       6a
                JMP    Unhandled                       6b
                JMP    Unhandled                       6c
                JMP    Unhandled                       6d
                JMP    Unhandled                       6e
                JMP    Unhandled                       6f
                JMP    MP3PlayOnce                     70
                JMP    Unhandled                       71
                JMP    Unhandled                       72
                JMP    Unhandled                       73
                JMP    Unhandled                       74
                JMP    Unhandled                       75
                JMP    Unhandled                       76
                JMP    Unhandled                       77
                JMP    Unhandled                       78
                JMP    Unhandled                       79
                JMP    Unhandled                       7a
                JMP    Unhandled                       7b
                JMP    Unhandled                       7c
                JMP    Unhandled                       7d
                JMP    Unhandled                       7e
                JMP    Unhandled                       7f

                JMP    Unhandled                       80
                JMP    Unhandled                       81
                JMP    Unhandled                       82
                JMP    Unhandled                       83
                JMP    Unhandled                       84
                JMP    Unhandled                       85
                JMP    Unhandled                       86
                JMP    Unhandled                       87
                JMP    Unhandled                       88
                JMP    Unhandled                       89
                JMP    Unhandled                       8a
                JMP    Unhandled                       8b
                JMP    Unhandled                       8c
                JMP    Unhandled                       8d
                JMP    Unhandled                       8e
                JMP    Unhandled                       8f
                JMP    Unhandled                       90
                JMP    Unhandled                       91
                JMP    Unhandled                       92
                JMP    Unhandled                       93
                JMP    Unhandled                       94
                JMP    Unhandled                       95
                JMP    Unhandled                       96
                JMP    Unhandled                       97
                JMP    Unhandled                       98
                JMP    Unhandled                       99
                JMP    Unhandled                       9a
                JMP    Unhandled                       9b
                JMP    Unhandled                       9c
                JMP    Unhandled                       9d
                JMP    Unhandled                       9e
                JMP    Unhandled                       9f

                JMP    Unhandled                       a0
                JMP    Unhandled                       a1
                JMP    Unhandled                       a2
                JMP    Unhandled                       a3
                JMP    Unhandled                       a4
                JMP    Unhandled                       a5
                JMP    Unhandled                       a6
                JMP    Unhandled                       a7
                JMP    Unhandled                       a8
                JMP    Unhandled                       a9
                JMP    Unhandled                       aa
                JMP    Unhandled                       ab
                JMP    Unhandled                       ac
                JMP    Unhandled                       ad
                JMP    Unhandled                       ae
                JMP    Unhandled                       af
                JMP    Unhandled                       b0
                JMP    Unhandled                       b1
                JMP    Unhandled                       b2
                JMP    Unhandled                       b3
                JMP    Unhandled                       b4
                JMP    Unhandled                       b5
                JMP    Unhandled                       b6
                JMP    Unhandled                       b7
                JMP    Unhandled                       b8
                JMP    Unhandled                       b9
                JMP    Unhandled                       ba
                JMP    Unhandled                       bb
                JMP    Unhandled                       bc
                JMP    Unhandled                       bd
                JMP    Unhandled                       be
                JMP    Unhandled                       bf

                JMP    Unhandled                       c0
                JMP    Unhandled                       c1
                JMP    Unhandled                       c2
                JMP    Unhandled                       c3
                JMP    Unhandled                       c4
                JMP    Unhandled                       c5
                JMP    Unhandled                       c6
                JMP    Unhandled                       c7
                JMP    Unhandled                       c8
                JMP    Unhandled                       c9
                JMP    Unhandled                       ca
                JMP    Unhandled                       cb
                JMP    Unhandled                       cc
                JMP    Unhandled                       cd
                JMP    Unhandled                       ce
                JMP    Unhandled                       cf
                JMP    Unhandled                       d0
                JMP    Unhandled                       d1
                JMP    Unhandled                       d2
                JMP    Unhandled                       d3
                JMP    Unhandled                       d4
                JMP    Unhandled                       d5
                JMP    Unhandled                       d6
                JMP    Unhandled                       d7
                JMP    Unhandled                       d8
                JMP    Unhandled                       d9
                JMP    Unhandled                       da
                JMP    Unhandled                       db
                JMP    Unhandled                       dc
                JMP    Unhandled                       dd
                JMP    Unhandled                       de
                JMP    Unhandled                       df

                JMP    Unhandled                       e0
                JMP    Unhandled                       e1
                JMP    Unhandled                       e2
                JMP    Unhandled                       e3
                JMP    Unhandled                       e4
                JMP    Unhandled                       e5
                JMP    Unhandled                       e6
                JMP    Unhandled                       e7
                JMP    Unhandled                       e8
                JMP    Unhandled                       e9
                JMP    Unhandled                       ea
                JMP    Unhandled                       eb
                JMP    Unhandled                       ec
                JMP    Unhandled                       ed
                JMP    Unhandled                       ee
                JMP    Unhandled                       ef
                JMP    Unhandled                       f0
                JMP    Unhandled                       f1
                JMP    Unhandled                       f2
                JMP    Unhandled                       f3
                JMP    Unhandled                       f4
                JMP    Unhandled                       f5
                JMP    Unhandled                       f6
                JMP    Unhandled                       f7
                JMP    Unhandled                       f8
                JMP    Unhandled                       f9
                JMP    Unhandled                       fa
                JMP    Unhandled                       fb
                JMP    Unhandled                       fc
                JMP    Unhandled                       fd
                JMP    Unhandled                       fe
                JMP    Unhandled                       ff


%	Default TRAP Handlers
Unhandled       GETA   tmp,1F
                SWYM   tmp,5                           inform the debugger
                NEG    tmp,1
                PUT    :rBB,tmp                        return -1
                POP    0,0
1H              BYTE   "DEBUG Unhandled TRAP",0

Halt            GETA   tmp,1F
                SWYM   tmp,5                           inform the debugger
idle            SYNC   4                               go to power save mode
                GET    tmp,:rQ
                BZ     tmp,idle
                PUSHJ  tmp,:DTrap:Handler
                JMP    idle                            and loop idle
1H              BYTE   "DEBUG Program halted",0

Idle            SYNC   4
                POP    0,0
                PREFIX :

%	Devicespecific TRAP Handlers


%	MMIXware Traps
                PREFIX :Fopen:
arg             IS     $0
tmp             IS     $1

:FTrap:Fopen    SAVE   $255,0                          Save the user environment
                SET    tmp,$255                        $255 is needed for address calculations
                STOU   tmp,:RAM:User_SP                Store User Stack Pointer
                LDOU   $255,:RAM:OS_SP                 Load OS Stack Pointer
                UNSAVE 0,$255                          Restore OS environment

                GET    arg,:rBB                        get the $255 parameter
                LDO    tmp+1,arg,0                     the name string
                LDO    tmp+2,arg,8                     the mode number
                GET    tmp+3,:rXX                      instruction
                AND    tmp+3,tmp+3,#FF                 Z value	is the handle
                PUSHJ  tmp,:FAT32:fat32_fopen
                SUB    tmp,tmp,1                       zero means false 1, one means true
                PUT    :rBB,tmp                        the error code is returned with resume 1

                SAVE   $255,0                          Reverse the steps above
                SET    tmp,$255
                STOU   tmp,:RAM:OS_SP
                LDOU   $255,:RAM:User_SP
                UNSAVE 0,$255

                POP    0,0

                PREFIX :Fclose:

tmp             IS     $0

:FTrap:Fclose   SAVE   $255,0				See above
                SET    tmp,$255
                STOU   tmp,:RAM:User_SP
                LDOU   $255,:RAM:OS_SP
                UNSAVE 0,$255

                GET    tmp+1,:rXX                      instruction
                AND    tmp+1,tmp+1,#FF                 Z value is the handle
                PUSHJ  tmp,:FAT32:fat32_fclose
                PUT    :rBB,tmp                        the error code is returned with resume 1

                SAVE   $255,0
                SET    tmp,$255
                STOU   tmp,:RAM:OS_SP
                LDOU   $255,:RAM:User_SP
                UNSAVE 0,$255

                POP    0,0


                PREFIX :Fread:
arg				IS	    $0
size			IS		$1
tmp				IS		$2

:FTrap:Fread    GET    tmp,:rXX                        
                AND    tmp,tmp,#FF  
				SUB	   tmp,tmp,3			
                BN     tmp,:FTrap:Fgets                    
				
				SAVE   $255,0				
                SET    tmp,$255
                STOU   tmp,:RAM:User_SP
                LDOU   $255,:RAM:OS_SP
                UNSAVE 0,$255

				GET    arg,:rBB                        
                LDO    tmp+1,arg,0                     
                LDO    size,arg,8      
                GET    tmp+3,:rXX                      
                AND    tmp+3,tmp+3,#FF                 
                PUSHJ  tmp,:FAT32:fat32_fread
                SUB    tmp,tmp,size                     
                PUT    :rBB,tmp   

                SAVE   $255,0
                SET    tmp,$255
                STOU   tmp,:RAM:OS_SP
                LDOU   $255,:RAM:User_SP
                UNSAVE 0,$255

				POP    0,0


                PREFIX :Fgets:
% Characters are read into MMIX's memory starting at address |buffer|,
% until either |size-1| characters have been read and stored or a
% newline character has been read and stored; the next byte in memory
% is then set to zero.
% If an error or end of file occurs before reading is complete, the
% memory contents are undefined and the value $-1$ is returned;
% otherwise the number of characters successfully read and stored is
% returned.

buffer          IS     $0
size            IS     $1
n               IS     $2
return          IS     $3
tmp             IS     $4


:FTrap:Fgets    GET    tmp,:rXX                        instruction
                AND    tmp,tmp,#FF                     Z value
                BNZ    tmp,Error                       this is not StdIn


%		Fgets from the keyboard
                GET    tmp,:rBB                        get the $255 parameter: buffer, size
                LDO    buffer,tmp,0
                LDO    size,tmp,8
                SET    n,0
                GET    return,:rJ
                JMP    1F

Loop            PUSHJ  tmp,:KeyboardC                  read blocking from the keyboard
                STBU   tmp,buffer,n
                ADDU   n,n,1
                CMP    tmp,tmp,10                      newline
                BZ     tmp,Done
1H              SUB    size,size,1
                BP     size,Loop

Done            SET    tmp,0                           terminating zero byte
                STBU   tmp,buffer,n
                PUT    :rBB,n                          result
                PUT    :rJ,return
                POP    0,0

Error           NEG    tmp,1
                PUT    :rBB,tmp
                POP    0,0


:FTrap:Fgetws   IS     :FTrap:Unhandled


                PREFIX :Fwrite:

% The next |size| characters are written from MMIX's memory starting
% at address |buffer|. If no error occurs, 0~is returned;
% otherwise the negative value |n-size| is returned,
% where |n|~is the number of characters successfully written.

%		we work with a pointer to the end of the buffer (last)
%		and a negative offset towards this point (tolast)
%		to have only a single ADD in the Loop.

last            IS     $0                              buffer+size
tolast          IS     $1                              n-size
n               IS     $1
return          IS     $2
tmp             IS     $3

:FTrap:Fwrite   GET    tmp,:rXX                        instruction
                AND    tmp,tmp,#FF                     Z value
                BZ     tmp,Error                       this is stdin
                CMP    tmp,tmp,2                       StdOut or StdErr
                BP     tmp,Error                       this is a File

%       	Fwrite to the screen

                GET    tmp,:rBB                        get the $255 parameter: buffer, size
                LDO    last,tmp,0                      buffer
                LDO    tolast,tmp,8                    size
                ADDU   last,last,tolast
                NEG    tolast,tolast
                GET    return,:rJ
                JMP    1F

Loop            LDBU   tmp+1,last,tolast
                PUSHJ  tmp,:ScreenC
                ADD    tolast,tolast,1
1H              BN     tolast,Loop

                PUT    :rBB,tolast
                PUT    :rJ,return
                POP    0,0

Error           NEG    tmp,1
                PUT    :rBB,tmp
                POP    0,0



                PREFIX :Fputs:
% One-byte characters are written from MMIX's memory to the file,
% starting at address string, up to but not including the first
% byte equal to zero. The number of bytes written is returned,
% or $-1$ on error.

string          IS     $0
n               IS     $1
return          IS     $2
z               IS     $3
tmp             IS     $4

:FTrap:Fputs    GET    z,:rXX                          instruction
                AND    z,z,#FF                         Z value
                BZ     z,Error                         this is stdin
                CMP    tmp,z,2                         StdOut or StdErr
                BP     tmp,Error                       this is a File

%       	Fputs to the screen

                GET    return,:rJ
                GET    string,:rBB                     get the $255 parameter
                SET    n,0
                JMP    1F

Loop            PUSHJ  tmp,:ScreenC
                ADD    n,n,1
1H              LDBU   tmp+1,string,n
                BNZ    tmp+1,Loop

                PUT    :rJ,return
                PUT    :rBB,n
                POP    0,0

Error           NEG    tmp,1
                PUT    :rBB,tmp
                POP    0,0


:FTrap:Fputws   IS     :FTrap:Unhandled

:FTrap:Fseek    IS     :FTrap:Unhandled

:FTrap:Ftell    IS     :FTrap:Unhandled

%		END of MMIXware

%		Timer

                PREFIX :TWait:
%		$255 	specifies the number of ms to wait
t               IS     #10                             offset of Timer t register

tbit            IS     $0
bits            IS     $1
tmp             IS     $2
ms              IS     $3
base            IS     $4

:FTrap:TWait    SETH   base,:IO:HI
                SET    tbit,1
                SL     tbit,tbit,:Interrupt:Timer
                GET    bits,:rQ
                GET    ms,:rBB                         ms to wait
                BNP    ms,Done

                ANDN   tmp,bits,tbit
                PUT    :rQ,tmp                         Clear Timer Interrupt
                STTU   ms,base,:IO:Timer+t

Loop            SYNC   4
                GET    bits,:rQ
                AND    tmp,bits,tbit
                BZ     tmp,Loop                        test Timer bit

Done            STCO   0,base,:IO:Timer+t              switch Timer off
                ANDN   bits,bits,tbit
                PUT    :rQ,bits
                PUT    :rBB,0
                POP    0,0


                PREFIX :TDate:
%		Get the current date in format YYYYMMDW

base            IS     $1
date            IS     $0
W               IS     $2
D               IS     $3
M               IS     $4
YY              IS     $5
tmp             IS     $6

:FTrap:TDate    SETH   base,:IO:HI
                LDOU   date,base,:IO:Timer             YYMDXXXW
                AND    W,date,#FF                      W
                SRU    date,date,32
                AND    D,date,#FF                      D
                SRU    date,date,8
                AND    M,date,#FF                      M
                SRU    YY,date,8                       YY

                SL     D,D,8
                OR     date,W,D
                SL     M,M,16
                OR     date,date,M
                SL     YY,YY,32
                OR     date,date,YY
                PUT    :rBB,date                       YYYYMMDW
                POP    0,0


                PREFIX :TTimeOfDay:
%		Read the current Time in ms since midnight
ms              IS     #0C

base            IS     $0
current         IS     $1

:FTrap:TTimeOfDay SETH base,:IO:HI
                LDTU   current,base,:IO:Timer+ms
                PUT    :rBB,current
                POP    0,0



%		Video RAM

                PREFIX :VPut:

%		Put one pixel on the graphics display.
%		In $255 we have in the Hi 32 bit the RGB value
%               and in the low 32 bit the offset into the video ram

tmp             IS     $0
rgb             IS     $1
offset          IS     $2



:FTrap:VPut     GET    tmp,:rBB                        get the $255 parameter: RGB, offset
                SRU    rgb,tmp,32
                SLU    offset,tmp,32
                SRU    offset,offset,32
                SETH   tmp,:VRAM:HI
                STTU   rgb,tmp,offset
                PUT    :rBB,0
                POP    0,0

                PREFIX :VGet:

%		Return one pixel at the given offset from the graphics display.
%		In $255 we have in the low 32 bit the offset into the video ram

tmp             IS     $0
rgb             IS     $1
offset          IS     $2



:FTrap:VGet     GET    tmp,:rBB                        get the $255 parameter: RGB, offset
                SLU    offset,tmp,32
                SRU    offset,offset,32
                SETH   tmp,:VRAM:HI
                LDTU   rgb,tmp,offset
                PUT    :rBB,rgb
                POP    0,0

%		GPU

                PREFIX :GPU:CMD:
CHAR            IS     #0100
RECT            IS     #0200
LINE            IS     #0300
BLT             IS     #0400
BLTIN           IS     #0500
BLTOUT          IS     #0600
BLTDIB          IS     #0700

                PREFIX :GPU:
CMD             IS     0
AUX             IS     1
XY2             IS     4
X2              IS     4
Y2              IS     6
WHXY            IS     8
WH              IS     8
W               IS     8
H               IS     #0A
XY              IS     #0C
X               IS     #0C
Y               IS     #0E
BBA             IS     #10
TBCOLOR         IS     #18                             Text Background Color
TFCOLOR         IS     #1C                             Text Foreground Color
FCOLOR          IS     #20                             Fill Color
LCOLOR          IS     #24                             Line Color
CWH             IS     #28                             Character Width and Height
CW              IS     #28
CH              IS     #2A
FW              IS     #30                             Frame and Screen Width and Height
FH              IS     #32
SW              IS     #34
SH              IS     #36

                PREFIX :GSize:

tmp             IS     $0

:FTrap:GSize    SETH   tmp,:IO:HI
                LDTU   tmp,tmp,:IO:GPU+:GPU:FW
                PUT    :rBB,tmp
                POP    0,0

                PREFIX :GSet

tmp             IS     $0
base            IS     $1
%		Set the width and height for the next Rectangle
:FTrap:GSetWH   GET    tmp,:rBB                        get the $255 parameter: w,h
                SETH   base,:IO:HI                     base address of gpu -20
                STTU   tmp,base,:IO:GPU+:GPU:WH
                POP    0,0

%		Set the position for the next GChar,GPutStr,GLine Operation
:FTrap:GSetPos  GET    tmp,:rBB                        get the $255 parameter: x,y
                SETH   base,:IO:HI                     base address of gpu -20
                STTU   tmp,base,:IO:GPU+:GPU:XY
                POP    0,0

:FTrap:GSetTextColor GET tmp,:rBB                      background RGB, foreground RGB
                SETH   base,:IO:HI
                STOU   tmp,base,:IO:GPU+:GPU:TBCOLOR
                POP    0,0

:FTrap:GSetFillColor GET tmp,:rBB                      RGB
                SETH   base,:IO:HI
                STTU   tmp,base,:IO:GPU+:GPU:FCOLOR
                POP    0,0


:FTrap:GSetLineColor GET tmp,:rBB                      RGB
                SETH   base,:IO:HI                     base address of gpu -20
                STTU   tmp,base,:IO:GPU+:GPU:LCOLOR
                POP    0,0

                PREFIX :GPutPixel                      obsolete
%		Put one pixel on the graphics display.
%		In $255 we have in the Hi 32 bit the RGB value
%               and in the low 32 bit the x y value as two WYDEs

param           IS     $0
x               IS     $1
y               IS     $2
width           IS     $3
tmp             IS     $4
%       convert x,y from rBB to an offset and put back in rBB
%       then call VPut
:FTrap:GPutPixel GET   param,:rBB
                SLU    x,param,32
                SRU    x,x,48
                SLU    y,param,48
                SRU    y,y,48
                SETH   tmp,:IO:HI
                LDWU   tmp,tmp,:IO:GPU+:GPU:FW         width
                MUL    y,y,tmp
                ADD    x,x,y                           ((y*width)+x)
                SL     x,x,2                           *4 for TETRA
                SRU    param,param,32
                SLU    param,param,32                  clear low TETRA
                OR     param,param,x                   add offset
                PUT    :rBB,param
                JMP    :FTrap:VPut

                PREFIX :GPutChar
%		Put one character on the graphics display.
%		In $255 we have in the Hi 32 bit the ASCII value
%               and in the low 32 bit the x y value as two WYDEs

cmd             IS     $0
base            IS     $1

:FTrap:GPutChar GET    cmd,:rBB                        get the $255 parameter: c, x, y
                SETH   base,:IO:HI                     base address of gpu -20
                ORH    cmd,:GPU:CMD:CHAR
                STTU   cmd,base,:IO:GPU+:GPU:XY
                STHT   cmd,base,:IO:GPU+:GPU:CMD
                POP    0,0

                PREFIX :GPutStr:
%		Put a string pointed to by $255 at the current position

string          IS     $0
base            IS     $1
cmd             IS     $2

:FTrap:GPutStr  GET    string,:rBB                     get the $255 point to the string
                SETH   base,:IO:HI
                JMP    1F

Loop            ORML   cmd,:GPU:CMD:CHAR
                STT    cmd,base,:IO:GPU+:GPU:CMD
                ADD    string,string,1
1H              LDBU   cmd,string,0
                BNZ    cmd,Loop
Error           POP    0,0

                PREFIX :GLine:
%		Draw a line from the current position to x,y with width w
%		$255 has the format 0000 WWWW XXXX YYYY

cmd             IS     $0
base            IS     $1

:FTrap:GLine    GET    cmd,:rBB
                ORH    cmd,:GPU:CMD:LINE
                SETH   base,:IO:HI
                STO    cmd,base,:IO:GPU+:GPU:CMD
                POP    0,0

                PREFIX :GRectangle:

cmd             IS     $0
base            IS     $1
wh              IS     $2

:FTrap:GRectangle SETH base,:IO:HI
                GET    cmd,:rBB                        low TETRA XXXX YYYY
                SRU    wh,cmd,32
                STTU   wh,base,:IO:GPU+:GPU:WH
                SLU    cmd,cmd,32
                SRU    cmd,cmd,32                      clear high TETRA
                ORH    cmd,:GPU:CMD:RECT
                STO    cmd,base,:IO:GPU+:GPU:CMD
                POP    0,0

                PREFIX :GBitBlt:

%	transfer a bit block within vram
%	at $255	we have  WYDE destwith,destheigth,destx,desty,srcx,srcy

tmp             IS     $0
base            IS     $1
args            IS     $2
:FTrap:GBitBlt  GET    args,:rBB                       get the $255 parameter
                SETH   base,:IO:HI                     base address of gpu -20
                LDO    tmp,args,0                      destwith,destheigth,destx,desty
                STO    tmp,base,:IO:GPU+:GPU:WHXY
                LDTU   tmp,args,8                      srcx,srcy
                ORH    tmp,:GPU:CMD:BLT|#CC            CMD|RasterOP
                ORMH   tmp,#0020                       CC0020=SRCCOPY
                STOU   tmp,base,:IO:GPU+:GPU:CMD
                POP    0,0


                PREFIX :GPutBmp:

%	transfer a 32x32 Bitmap identified by a number from off-screen memory to on-screen memory
%	in $255	we have  RRRRRR,NN,XXXX,YYYY
%       where RRRRRR is the raster op, NN the bitmap id, XXXX and YYYY the destination coordinates
%	if RRRRRR is zero, the raster mode #CC0020 (SRCCOPY) is used

tmp             IS     $0
base            IS     $1
args            IS     $2
op              IS     $3
idx             IS     $4
idy             IS     $5
cmd             IS     $6

:FTrap:GPutBmp  GET    args,:rBB                       get the $255 parameter
                SETH   base,:IO:HI                     base address of gpu -20
                SLU    tmp,args,32
                SRU    tmp,tmp,32                      extract destination XXXX,YYYY
                ORMH   tmp,32                          add height
                ORH    tmp,32                          add width
                STO    tmp,base,:IO:GPU+:GPU:WHXY
                SRU    tmp,args,32
                AND    tmp,tmp,#FF                     the bitmap id
                AND    idx,tmp,#03                     last 3 bit for x
                SRU    idy,tmp,2                       other bits for y
                SL     idx,idx,5                       x*32
                INCL   idx,640                         x+=640
                SL     idy,idy,5                       y*32

                SRU    tmp,args,40
                SLU    op,tmp,32
                BNZ    op,OpGiven
                SETH   op,#00CC                        RasterOP
                ORMH   op,#0020                        CC0020=SRCCOPY
OpGiven         SLU    cmd,idx,16
                OR     cmd,cmd,idy
                OR     cmd,cmd,op
                ORH    cmd,:GPU:CMD:BLT                add Command

                STOU   cmd,base,:IO:GPU+:GPU:CMD
                POP    0,0



                PREFIX :GBitBltIn

%	transfer a bit block from normal memory into vram
%	at $255	we have:  WYDE with,heigth,destx,desty; OCTA srcaddress
args            IS     $0
base            IS     $1
return          IS     $2
gbit            IS     $3
bits            IS     $4
cmd             IS     $5
tmp             IS     $6


:FTrap:GBitBltIn GET   args,:rBB
                SETH   base,:IO:HI
                LDO    tmp,args,0                      with,heigth,destx,desty
                STO    tmp,base,:IO:GPU+:GPU:WHXY

                GET    return,:rJ
                LDOU   tmp+1,args,8                    srcaddress
                PUSHJ  tmp,:V2Paddr
                PUT    :rJ,return
                BN     tmp,Error

                STO    tmp,base,:IO:GPU+:GPU:BBA
                SETH   cmd,:GPU:CMD:BLTIN|#CC          CMD|RasterOP
                ORMH   cmd,#0020                       CC0020=SRCCOPY
                SET    gbit,1
                SL     gbit,gbit,:Interrupt:GPU
                GET    bits,:rQ
                ANDN   bits,bits,gbit
                PUT    :rQ,bits

%               issue command
                STHT   cmd,base,:IO:GPU+:GPU:CMD

%               wait for completion
Loop            SYNC   4
                GET    bits,:rQ
                AND    tmp,bits,gbit
                BZ     tmp,Loop

                ANDN   bits,bits,gbit
                PUT    :rQ,bits
                PUT    :rBB,0
                POP    0,0

Error           NEG    tmp,1
                PUT    :rBB,tmp
                POP    0,0

                PREFIX :GBitBltOut:

%	transfer a bit block from vram into normal memory
%	at $255	we have:  WYDE with,heigth,srcx,srcy; OCTA destaddress

args            IS     $0
base            IS     $1
return          IS     $2
gbit            IS     $3
bits            IS     $4
cmd             IS     $5
tmp             IS     $6

:FTrap:GBitBltOut GET  args,:rBB
                SETH   base,:IO:HI
                LDO    tmp,args,0                      with,heigth,srcx,srcy
                STO    tmp,base,:IO:GPU+:GPU:WHXY

                GET    return,:rJ
                LDO    tmp+1,args,8                    srcaddress
                PUSHJ  tmp,:V2Paddr
                PUT    :rJ,return
                BN     tmp,Error

                STO    tmp,base,:IO:GPU+:GPU:BBA

                SETH   cmd,:GPU:CMD:BLTOUT|#CC         CMD|RasterOP
                ORMH   cmd,#0020                       CC0020=SRCCOPY
                SET    gbit,1
                SL     gbit,gbit,:Interrupt:GPU
                GET    bits,:rQ
                ANDN   bits,bits,gbit
                PUT    :rQ,bits

%               issue command
                STHT   cmd,base,:IO:GPU+:GPU:CMD

%               wait for completion
Loop            SYNC   4
                GET    bits,:rQ
                AND    tmp,bits,gbit
                BZ     tmp,Loop

                ANDN   bits,bits,gbit
                PUT    :rQ,bits
                PUT    :rBB,0
                POP    0,0

Error           NEG    tmp,1
                PUT    :rBB,tmp
                POP    0,0



                PREFIX :GPutDIB

%	transfer a bit block from normal memory into vram
%	at $255	we have:  WYDE with,heigth,destx,desty; OCTA srcaddress
args            IS     $0
base            IS     $1
return          IS     $2
gbit            IS     $3
bits            IS     $4
cmd             IS     $5
tmp             IS     $6


:FTrap:GPutDIB  GET    args,:rBB
                SETH   base,:IO:HI
                LDO    tmp,args,0                      0,0,destx,desty
                STO    tmp,base,:IO:GPU+:GPU:WHXY

                GET    return,:rJ
                LDOU   tmp+1,args,8                    srcaddress
                PUSHJ  tmp,:V2Paddr
                PUT    :rJ,return
                BN     tmp,Error

                STO    tmp,base,:IO:GPU+:GPU:BBA
                SETH   cmd,:GPU:CMD:BLTDIB
                SET    gbit,1
                SL     gbit,gbit,:Interrupt:GPU
                GET    bits,:rQ
                ANDN   bits,bits,gbit
                PUT    :rQ,bits

%		issue command
                STHT   cmd,base,:IO:GPU+:GPU:CMD

%		wait for completion
Loop            SYNC   4
                GET    bits,:rQ
                AND    tmp,bits,gbit
                BZ     tmp,Loop

                ANDN   bits,bits,gbit
                PUT    :rQ,bits
                PUT    :rBB,0
                POP    0,0

Error           NEG    tmp,1
                PUT    :rBB,tmp
                POP    0,0

%		Mouse

                PREFIX :MWait:
%		Wait for a mouse event and return the descriptor

bits            IS     $0
mbit            IS     $1
tmp             IS     $2

:FTrap:MWait    SET    mbit,1
                SL     mbit,mbit,:Interrupt:Mouse
                JMP    1F

Loop            SYNC   4                               wait idle for an interrupt
1H              GET    bits,:rQ
                AND    tmp,bits,mbit
                BZ     tmp,Loop

                ANDN   bits,bits,mbit                  clear mouse Interrupt
                PUT    :rQ,bits

                SETH   tmp,:IO:HI                      base address
                LDO    tmp,tmp,:IO:Mouse               mouse status
                PUT    :rBB,tmp                        return via rBB in $255
                POP    0,0

%		Keyboard

                PREFIX :Keyboard:
%		Wait until the button is pressed
%		return immediately if button was already pressed

base            IS     $0
status          IS     $1
kbit            IS     $2
bits            IS     $3
return          IS     $4
tmp             IS     $5


:FTrap:KGet     SETH   base,:IO:HI                     base address
1H              LDO    status,base,:IO:Keyboard        keyboard status
                BNZ    status,1F
                GET    return,:rJ
                PUSHJ  tmp,:FTrap:KWait
                PUT    :rJ,return
                JMP    1B

1H              SLU    status,status,32
                SRU    status,status,32                remove high tetra
                PUT    :rBB,status                     return via rBB in $255
                POP    0,0


:FTrap:KStatus  SETH   base,:IO:HI                     base address
                LDHT   status,base,:IO:Keyboard        keyboard status
                PUT    :rBB,status                     return via rBB in $255
                POP    0,0

:FTrap:KWait    SET    kbit,1
                SL     kbit,kbit,:Interrupt:Keyboard
                JMP    1F

Loop            SYNC   4
1H              GET    bits,:rQ
                AND    tmp,bits,kbit
                BZ     tmp,Loop

                ANDN   bits,bits,kbit
                PUT    :rQ,bits

                PUT    :rBB,0
                POP    0,0


%		Button

                PREFIX :BWait:
%		Wait until the button is pressed
%		return immediately if button was already pressed

base            IS     $0
state           IS     $1
bbit            IS     $2
bits            IS     $3
tmp             IS     $4

:FTrap:BWait    SET    bbit,1
                SL     bbit,bbit,:Interrupt:Button
                JMP    1F

Loop            SYNC   4
1H              GET    bits,:rQ
                AND    tmp,bits,bbit
                BZ     tmp,Loop

                ANDN   bits,bits,bbit
                PUT    :rQ,bits

                PUT    :rBB,0
                POP    0,0


                PREFIX :Sevensegment:

top             IS     #01
mid             IS     #02
bot             IS     #04
tleft           IS     #08                             top
bleft           IS     #10                             bottom
tright          IS     #20                             top
bright          IS     #40                             bottom
dot             IS     #80

segments        BYTE   top|tleft|tright|bleft|bright|bot 0
                BYTE   tright|bright                   1
                BYTE   top|tright|mid|bleft|bot        2
                BYTE   top|tright|mid|bright|bot       3
                BYTE   tleft|tright|mid|bright         4
                BYTE   top|tleft|mid|bright|bot        5
                BYTE   top|tleft|mid|bleft|bright|bot  6
                BYTE   top|tright|bright               7
                BYTE   top|mid|bot|tleft|tright|bleft|bright 8
                BYTE   top|mid|bot|tleft|tright|bright 9

base            IS     $0
bits            IS     $1
head            IS     $2
tail            IS     $3
code            IS     $4
shift           IS     $5
tmp             IS     $6

%		$255 specifies the number to display
%		Z    specifies the number of decimal places

:FTrap:SDecimal GET    tmp,:rXX
                AND    tmp,tmp,#FF                     Z value
                SL     tmp,tmp,3                       Z*8
                SET    bits,dot
                SL     bits,bits,tmp                   dot after Z places
                CSZ    bits,tmp,0                      no dot if Z equal zero
                SET    shift,0
                GET    head,:rBB
                GETA   base,segments

1H              DIV    head,head,10
                GET    tail,:rR
                LDB    code,base,tail
                SLU    code,code,shift
                OR     bits,bits,code
                ADD    shift,shift,8
                BP     head,1B

                SETH   base,:IO:HI
                STO    bits,base,:IO:Sevensegment
                POP    0,0

%		$255 specifies the raw bits to display
:FTrap:SSet     GET    bits,:rBB
                SETH   base,:IO:HI
                STO    bits,base,:IO:Sevensegment
                POP    0,0

                PREFIX :MP3:

%		Preload mp3 buffers
base            IS     $0
command         IS     $1
buffer          IS     $2
addr            IS     $3
size            IS     $4
mp3s            IS     $5
tmp             IS     $6
N               IS     5                               Number of sound files

:MP3Init        SETH   base,:IO:HI
                INCL   base,:IO:Sound
                GETA   mp3s,:mp3s
                ADDU   mp3s,mp3s,8*N
                SET    buffer,N                        Number of sound buffers

1H              LDOU   size,mp3s,0
                SUBU   mp3s,mp3s,8
                LDOU   addr,mp3s,0

                SUBU   size,size,addr
                ANDNH  addr,#8000                      convert to physical address

                SL     tmp,buffer,4
                STOU   addr,base,tmp
                ADDU   tmp,tmp,8
                STO    size,base,tmp
                STBU   buffer,base,1
                SET    command,#03
                STBU   command,base,0                  execute preload buffer
                SUB    buffer,buffer,1
                BNZ    buffer,1B
                POP    0,0


%		Play a single sound buffer of mp3 data
%       The number of the sound buffer is given as Z value


:FTrap:MP3PlayOnce SETH base,:IO:HI
                INCL   base,:IO:Sound
                GET    buffer,:rXX
                AND    buffer,buffer,#FF               Get Z value of instruction
                BZ     buffer,Error
                CMPU   tmp,buffer,N
                BP     tmp,Error
                SLU    command,buffer,48
                ORH    command,#0100                   play once mp3,
                STOU   command,base,#0                 execute play once mp3 buffer
                PUT    :rBB,0
                POP    0,0

Error           NEG    tmp,1
                PUT    :rBB,tmp
                POP    0,0
%		Preload a single sound buffer with mp3 data
%       The number of the sound buffer is given as Z value


%	two auxiliar functions to read and write characters.

                PREFIX :AUX:Keyboard:
c               IS     $0                              parameter
base            IS     $1
return          IS     $2
bits            IS     $3
kbit            IS     $4
tmp             IS     $5
CR              IS     #0D
NL              IS     #0A
%	read blocking a character from the keyboard
:KeyboardC      SETH   base,:IO:HI
Test            LDO    c,base,:IO:Keyboard             keyboard status/data
                SR     tmp,c,32
                AND    tmp,tmp,#FF                     count
                BNZ    tmp,Done                        char available

                SET    kbit,1
                SLU    kbit,kbit,:Interrupt:Keyboard
Wait            SYNC   4                               power save mode
                GET    bits,:rQ
                AND    tmp,bits,kbit
                BZ     tmp,Wait
                ANDN   bits,bits,kbit                  reset the keybaord interrupt bit
                PUT    :rQ,bits                        and store back to rQ
                JMP    Test

Done            AND    c,c,#FF
                CMP    tmp,c,CR
                CSZ    c,tmp,NL                        replace cr by nl
                GET    return,:rJ
                SET    tmp+1,c
                PUSHJ  tmp,:ScreenC                    echo
                PUT    :rJ,return
                POP    1,0


                PREFIX :AUX:Screen:

%	Put one character contained in $0 on the screen
%	version for the winvram device with GPU

c               IS     $0                              parameter
base            IS     $1
cmd             IS     $2
tmp             IS     $3
CR              IS     #0D
NL              IS     #0A
ScreenC         SETH   base,:IO:HI
1H              LDB    tmp,base,:IO:GPU+:GPU:CMD       wait for idle
                BNZ    tmp,1B
                SETML  cmd,:GPU:CMD:CHAR
                AND    c,c,#FF                         clean it
                OR     tmp,cmd,c
                STT    tmp,base,:IO:GPU+:GPU:CMD
                CMP    tmp,c,CR
                BNZ    tmp,2F
1H              LDB    tmp,base,:IO:GPU+:GPU:CMD       wait for idle
                BNZ    tmp,1B
                OR     tmp,cmd,NL
                STT    tmp,base,:IO:GPU+:GPU:CMD
2H              POP    0,0

                PREFIX :UNUSED:Screen:
%	Put one character contained in $0 on the screen
%	version for the screen device

c               IS     $0                              parameter
base            IS     $1
tmp             IS     $2

ScreenC         SETH   base,:IO:HI
1H              LDO    tmp,base,:IO:Screen
                BNZ    tmp,1B
                STO    c,base,:IO:Screen
                POP    0,0

:ScreenC        IS     :AUX:Screen:ScreenC

%               END of Basic BIOS functionality. This must fit into ROM before the page tables.

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

                LOC    #8000000000002000
%               The start is fixed in mmix-sim.ch
%		To allow loading mmo files from the commandline

PageRAM         IS     :RAM:UserRAM-#8000000000000000  removing the sign bit to physical start address

%       Text Segment 12 pages = 96kByte
Table           OCTA   PageRAM+#00005                  text permission 5=r-x
                OCTA   PageRAM+#02005                  text permission 5=r-x
                OCTA   PageRAM+#04005
                OCTA   PageRAM+#06005
                OCTA   PageRAM+#08005
                OCTA   PageRAM+#0a005
                OCTA   PageRAM+#0c005
                OCTA   PageRAM+#0e005
                OCTA   PageRAM+#10005
                OCTA   PageRAM+#12005
                OCTA   PageRAM+#14005
                OCTA   PageRAM+#16005
                OCTA   PageRAM+#18005

%       Data Segment 8 pages = 64 kByte RAM
                LOC    (@&~#1FFF)+#2000                data permission rw-
                OCTA   PageRAM+#1a006
                OCTA   PageRAM+#1c006
                OCTA   PageRAM+#1e006
                OCTA   PageRAM+#20006
                OCTA   PageRAM+#22006
                OCTA   PageRAM+#24006
                OCTA   PageRAM+#26006
                OCTA   PageRAM+#28006

%       Data Segment next 8 pages = 64 kByte FLASH
                OCTA   #0000000200000006               flash permission rw-
                OCTA   #0000000200002006
                OCTA   #0000000200004006
                OCTA   #0000000200006006
                OCTA   #0000000200008006
                OCTA   #000000020000a006
                OCTA   #000000020000c006
                OCTA   #000000020000e006

%	Pool Segment 2 pages = 16 kByte
                LOC    (@&~#1FFF)+#2000
                OCTA   PageRAM+#2a006                  pool permission rw-
                OCTA   PageRAM+#2c006

%	Stack Segment 10+2 pages = 80+16 kByte
                LOC    (@&~#1FFF)+#2000
                OCTA   PageRAM+#2e006                  10 pages register stack
                OCTA   PageRAM+#30006
                OCTA   PageRAM+#32006
                OCTA   PageRAM+#34006
                OCTA   PageRAM+#36006
                OCTA   PageRAM+#38006
                OCTA   PageRAM+#3a006
                OCTA   PageRAM+#3c006
                OCTA   PageRAM+#3e006
                OCTA   PageRAM+#40006

                LOC    (@&~#1FFF)+#2000-2*8
                OCTA   PageRAM+#42006                  gcc memory stack < #6000 0000 0080 0000
                OCTA   PageRAM+#44006

                LOC    (@&~#1FFF)+#2000


:HiRAM          IS     :RAM:UserRAM+#46000             free High RAM starts after user RAM


                PREFIX :memory:
%       	initialize the memory management
rV              IS     $0
tos             IS     $1
rG              IS     $2
t               IS     $3
:memory         SETH   rV,#1234                        set rV register
                ORMH   rV,#0D00
                ORML   rV,#0000
                ORL    rV,#2000
                PUT    :rV,rV

                SETH   tos,#8000
                ORMH   tos,#0001                       This is LoRAM
                ORL    tos,#2000                       This is the bottom of the OS register stack
                % Initialize the new stack.
                STCO   1,tos,#00                       This will become $0.
                STCO   2,tos,#08                       This will become $1.
                STCO   2,tos,#10                       This will become rL
                STCO   0,tos,#18                       This will become $253. GCC frame pointer
                LDA    t,:RAM:GCC_TOS		       
                STOU   t,tos,#20                       This will become $254. GCC stack pointer
                STCO   5,tos,#28                       This will become $255.
                ADDU   tos,tos,8*(2+1+3+12)            locals+rL+globals+specials
                SETH   rG,(#100-3)<<8                  3 globals
                STOU   rG,tos,0                        This is now the new top of stack.
                SETH   t,#8000
                ORMH   t,#0001                         The address of :OSstackptr
                STOU   tos,t,0

                POP    0,0

                PREFIX :V2Paddr:

% Translate virtual adresses to physical
% we assume s in rV to be 13. and b1,b2,b3,b4=1,2,3,4
% pte Format:  x(16) addr(48-s) unused(s-13) n(10) p(3)
% return -1 on failure
addr            IS     $0                              parameter and return value
tab             IS     $1
n               IS     $2
pte             IS     $3
mask            IS     $4
tmp             IS     $5

:V2Paddr        BN     addr,Negativ
                GETA   tab,:PageTable:Table
                SRU    tmp,addr,61
                AND    tmp,tmp,3                       segment
                SLU    tmp,tmp,13
                ADD    tab,tab,tmp                     PageTab+segment*1024
                ANDNH  addr,#E000                      remove segment from addr

                SRU    n,addr,13                       page number
                SET    mask,#1FFF                      13-bit mask
                CMP    tmp,n,mask
                BP     tmp,Error

                SL     n,n,3                           offset into the page table
                LDOU   pte,tab,n                       PTE
                BZ     pte,Error
                ANDNL  pte,#1FFF                       remove unused, n and p bits
                ANDNH  pte,#FFFF                       remove x bits
                AND    tmp,addr,mask                   get page offset
                ADDU   addr,pte,tmp
                POP    1,0

Negativ         ANDNH  addr,#8000                      remove sign bit
                POP    1,0

Error           NEG    addr,1
                POP    1,0



%               Functions to access the disk device

                PREFIX :Disk:
statusOffset    IS     #00
controlOffset   IS     #04
capacityOffset  IS     #08
sectorOffset    IS     #10
countOffset     IS     #18
dmaOffset       IS     #20
dmaSize         IS     #28
GO              IS     #01                             Execute command
IEN             IS     #02                             Interrupt Enable
WRT             IS     #04                             Write
BUSSY           IS     #01

disk_init       SETH   $1,:IO:HI
                LDO    $0,$1,:IO:Disk+capacityOffset
                ZSNZ   $0,$0,1                         return capacity != 0
                POP    1,0



%		The Function Disk Read is the Hardware Interface to
%		the Disk Simulator.
%		It has three parameters:
%			sector: the start sector
%			count: the number of sectors to read
%			buffer: the address where to store the data. 
%				The buffer address must be negative (OS).
%		The function returns	1 (True) if successfull, 
%					0 (False) otherwise.

                % parameters
sector          IS     $0
count           IS     $1
buffer          IS     $2                              should be negative to be a physical address
                %local variables
base            IS     $3
control         IS     $4
status          IS     $5
diskflag        IS     $6
tmp             IS     $7


disk_read      	SET	tmp,512
				SET	control,IEN|GO
				MUL	tmp,tmp,count
				SET	diskflag,buffer
				SET	status,2

loop			SYNCD #FF,buffer,0
				INCL buffer,#100
				SUB	status,status,1
				BNZ	status,loop

				SET	buffer,diskflag
				ANDNH buffer,#8000
				SETH  base,:IO:HI
				OR	  base,base,:IO:Disk
				STO	  buffer,base,dmaOffset
				STO	  tmp,base,dmaSize
				STO	  count,base,countOffset
				STO	  sector,base,sectorOffset
			
				SET	tmp,1
				SL	tmp,tmp,:Interrupt:Disk
				GET	tmp+1,:rQ
				ANDN	tmp+1,tmp+1,tmp
				PUT	:rQ,tmp+1
				
				
				STT control,base,controlOffset

				SYNC 4

				SET	tmp,1
				SL	tmp,tmp,:Interrupt:Disk
				GET	tmp+1,:rQ
				ANDN	tmp+1,tmp+1,tmp
				PUT	:rQ,tmp+1

loop2			LDT	 status,base,controlOffset
				AND	 tmp,status,:Disk:BUSSY
				BNZ	 tmp,loop2
				BZ	 status,fail

suc				SET sector,1
				POP	1,0		

fail			SET sector,0
				POP	1,0





%       	Functions for a read-only FAT32 file system
%		Compiler generated code, using:
%			mmix-gcc -Os -fno-inline -Ilibfat32 -S -o FAT32.mms FAT32.c
%		bios needs to be assembled with -x switch because no global registers
%		are defined for address calculations (may be that could be improved).
 	
                PREFIX :FAT32:

8H              IS     @                               Last position in ROM


                %       Allocate global variables

                LOC    :HiRAM                          Switch to RAM

% 		Define variable addresses but do not allocate 
%		because the image file will not contain the RAM

FAT2Cache       IS     (@+7)&~7; LOC @+528	Sizes taken from FAT32.mms
FATCache        IS     (@+7)&~7; LOC @+528
FileCache       IS     (@+7)&~7; LOC @+2112
Files           IS     (@+7)&~7; LOC @+4864
Filelib_Init    IS     (@+7)&~7; LOC @+4
FAT32           IS     (@+7)&~7; LOC @+80
DirCache        IS     (@+7)&~7; LOC @+528

                LOC    8B                              Switch back to ROM

memcpy          IS     @
                SETL   $3,0
L:2             IS     @
                CMP    $4,$3,$2
                BZ     $4,L:5
                LDB    $4,$1,$3
                STBU   $4,$0,$3
                ADDU   $3,$3,1
                JMP    L:2
L:5             IS     @
                POP    1,0


FAT32_LBAofCluster IS  @
                SUBU   $0,$0,2
                LDB    $2,FAT32
                SLU    $1,$2,56
                SRU    $1,$1,56
                MULU   $0,$0,$1
                LDO    $1,FAT32+32
                ADDU   $0,$0,$1
                POP    1,0


FAT32_InitCache IS     @
                SETL   $2,#200
                ADDU   $1,$0,$2
                SETL   $2,#ffff
                INCML  $2,#ffff
                STOU   $2,$1,0
                INCL   $0,#208
                SETL   $1,0
                STTU   $1,$0,0
                POP    0,0


FAT32_WriteCache IS    @
                SETL   $1,#208
                ADDU   $2,$0,$1
                LDT    $3,$2,0
                SLU    $1,$3,32
                SR     $1,$1,32
                BZ     $1,L:9
                INCL   $0,#200
                LDO    $1,$0,0
                SETL   $0,#ffff
                INCML  $0,#ffff
                CMP    $0,$1,$0
                BZ     $0,L:9
                SETL   $0,0
                STTU   $0,$2,0
L:9             IS     @
                SETL   $0,#1
                POP    1,0


FAT32_FAT_shutdown IS  @
                GET    $1,:rJ
                GETA   $0,FAT32_WriteCache
                LDA    $3,FATCache
                PUSHGO $2,$0,0
                LDA    $3,FAT2Cache
                PUSHGO $2,$0,0
                PUT    :rJ,$1
                POP    0,0

                .p2align 2
                LOC    @+(4-@)&3
islower         IS     @
                SUBU   $1,$0,97
                SETL   $0,#1
                SLU    $1,$1,32
                SRU    $1,$1,32
                CMPU   $1,$1,25
                BNP    $1,L:16
                SETL   $0,0
L:16            IS     @
                POP    1,0

                .p2align 2
                LOC    @+(4-@)&3
toupper         IS     @
                GET    $1,:rJ
                SET    $3,$0
                PUSHJ  $2,islower
                PUT    :rJ,$1
                SLU    $2,$2,32
                SR     $2,$2,32
                BZ     $2,L:19
                SUBU   $0,$0,32
L:19            IS     @
                POP    1,0

                .p2align 2
                LOC    @+(4-@)&3
isspace         IS     @
                XOR    $0,$0,32
                SLU    $0,$0,32
                SRU    $0,$0,32
                SUBU   $0,$0,1
                SRU    $0,$0,63
                POP    1,0

                .p2align 2
                LOC    @+(4-@)&3
Name_GetNextDirectory IS @
                BNP    $2,L:30
                ADDU   $5,$0,1
                SET    $3,$1
                SUBU   $2,$2,1
                SLU    $2,$2,32
                SR     $2,$2,32
L:25            IS     @
                SUBU   $6,$5,1
                LDB    $4,$6,0
                SLU    $0,$4,56
                SR     $0,$0,56
                SLU    $7,$4,56
                BZ     $0,L:35
                SR     $0,$7,56
                CMP    $7,$0,92
                PBNZ   $7,L:26
L:27            IS     @
                SETL   $0,0
                STBU   $0,$3,0
                ADDU   $0,$6,1
                POP    1,0
L:26            IS     @
                CMP    $0,$0,47
                BZ     $0,L:27
                SUBU   $0,$3,$1
                CMP    $0,$0,$2
                BNN    $0,L:28
                STBU   $4,$3,0
                ADDU   $3,$3,1
L:28            IS     @
                ADDU   $5,$5,1
                JMP    L:25
L:35            IS     @
                STBU   $0,$3,0
                POP    1,0
L:30            IS     @
                SETL   $0,0
                POP    1,0

                .p2align 2
                LOC    @+(4-@)&3
skip_root       IS     @
                LDB    $1,$0,0
                BZ     $1,L:37
                LDB    $2,$0,1
                CMP    $1,$2,58
                PBNZ   $1,L:38
                ADDU   $0,$0,2
L:38            IS     @
                LDB    $3,$0,0
                CMP    $2,$3,47
                SLU    $1,$3,56
                BZ     $2,L:42
                SR     $1,$1,56
                CMP    $1,$1,92
                PBNZ   $1,L:37
L:42            IS     @
                ADDU   $0,$0,1
L:37            IS     @
                POP    1,0

                .p2align 2
                LOC    @+(4-@)&3
Name_CompareSN  IS     @
                GET    $3,:rJ
                SETL   $2,0
L:45            IS     @
                LDB    $4,$0,$2
                CMP    $5,$4,32
                BZ     $5,L:47
                LDB    $5,$1,0
                SLU    $8,$5,32
                SR     $8,$8,32
                PUSHJ  $7,toupper
                PUT    :rJ,$3
                SLU    $4,$4,56
                SRU    $4,$4,56
                SLU    $7,$7,32
                SR     $7,$7,32
                CMP    $4,$4,$7
                BNZ    $4,L:55
                ADDU   $1,$1,1
                ADDU   $2,$2,1
                CMP    $4,$2,8
                PBNZ   $4,L:45
L:47            IS     @
                LDB    $6,$1,0
                CMP    $2,$6,46
                PBNZ   $2,L:49
                ADDU   $0,$0,8
                ADDU   $4,$1,4
                ADDU   $1,$1,1
L:50            IS     @
                LDB    $2,$0,0
                CMP    $5,$2,32
                BZ     $5,L:51
                LDB    $5,$1,0
                SLU    $8,$5,32
                SR     $8,$8,32
                PUSHJ  $7,toupper
                PUT    :rJ,$3
                SLU    $2,$2,56
                SRU    $2,$2,56
                SLU    $7,$7,32
                SR     $7,$7,32
                CMP    $2,$2,$7
                BNZ    $2,L:55
                ADDU   $1,$1,1
                ADDU   $0,$0,1
                CMP    $2,$1,$4
                PBNZ   $2,L:50
                JMP    L:51
L:49            IS     @
                LDB    $0,$0,8
                SLU    $0,$0,56
                SRU    $0,$0,56
                CMP    $0,$0,32
                PBNZ   $0,L:55
L:51            IS     @
                LDB    $1,$1,0
                SLU    $0,$1,56
                SRU    $0,$0,56
                SUBU   $0,$0,1
                SRU    $0,$0,63
                POP    1,0
L:55            IS     @
                SETL   $0,0
                POP    1,0

                .p2align 2
                LOC    @+(4-@)&3
Name_Trim       IS     @
                GET    $4,:rJ
                GETA   $2,isspace
L:61            IS     @
                LDB    $3,$1,0
                SLU    $10,$3,32
                SR     $10,$10,32
                PUSHGO $9,$2,0
                PUT    :rJ,$4
                SLU    $9,$9,32
                SR     $9,$9,32
                GETA   $7,isspace
                BZ     $9,L:65
                ADDU   $1,$1,1
                JMP    L:61
L:65            IS     @
                SET    $2,$9
                LDB    $3,$1,$9
                BZ     $3,L:64
                STBU   $3,$0,$9
                ADDU   $9,$9,1
                CMP    $2,$9,255
                PBNZ   $2,L:65
                SET    $2,$9
L:64            IS     @
                SET    $1,$2
                SETL   $2,0
                SLU    $8,$1,32
                SR     $8,$8,32
                ADDU   $8,$0,$8
L:66            IS     @
                SLU    $3,$1,32
                SR     $3,$3,32
                SLU    $6,$1,32
                BZ     $3,L:69
                SUBU   $1,$1,1
                ADDU   $5,$8,$2
                SUBU   $5,$5,1
                LDB    $3,$5,0
                SLU    $10,$3,32
                SR     $10,$10,32
                PUSHGO $9,$7,0
                PUT    :rJ,$4
                SLU    $9,$9,32
                SR     $9,$9,32
                BNZ    $9,L:68
                SLU    $3,$3,56
                SR     $3,$3,56
                CMP    $3,$3,46
                BNZ    $3,L:69
                SLU    $3,$1,32
                SR     $3,$3,32
                CMP    $3,$3,1
                BNP    $3,L:69
L:68            IS     @
                SUBU   $2,$2,1
                JMP    L:66
L:69            IS     @
                SR     $6,$6,32
                SETL   $5,0
                STBU   $5,$0,$6
                POP    0,0

                .p2align 2
                LOC    @+(4-@)&3
FATName_ChkSum  IS     @
                SETL   $1,0
                SET    $2,$1
L:77            IS     @
                AND    $3,$2,1
                BZ     $3,L:75
                NEGU   $3,0,128
L:75            IS     @
                SLU    $2,$2,56
                SRU    $2,$2,57
                LDB    $4,$0,$1
                ADDU   $2,$2,$4
                ADDU   $3,$2,$3
                SET    $2,$3
                ADDU   $1,$1,1
                CMP    $4,$1,11
                PBNZ   $4,L:77
                SET    $0,$3
                POP    1,0

                .p2align 2
                LOC    @+(4-@)&3
FATName_Compare_entry IS @
                GET    $7,:rJ
                LDB    $6,$0,0
                AND    $4,$6,31
                CMP    $3,$4,$3
                PBNZ   $3,L:90
                LDB    $4,$0,13
                SLU    $3,$4,56
                SRU    $3,$3,56
                CMP    $3,$3,$2
                PBNZ   $3,L:90
                SET    $2,$1
                SETL   $3,0
L:82            IS     @
                SUBU   $5,$2,$1
                LDB    $8,$2,0
                BZ     $8,L:83
                GETA   $4,nameIndexes
                LDT    $4,$4,$3
                SLU    $4,$4,32
                SR     $4,$4,32
                LDB    $10,$0,$4
                BZ     $10,L:83
                SLU    $10,$10,56
                GETA   $5,toupper
                SR     $10,$10,56
                PUSHGO $9,$5,0
                SET    $4,$9
                SLU    $10,$8,56
                SR     $10,$10,56
                PUSHGO $9,$5,0
                PUT    :rJ,$7
                SLU    $4,$4,32
                SR     $4,$4,32
                SLU    $9,$9,32
                SR     $9,$9,32
                CMP    $4,$4,$9
                BNZ    $4,L:90
                ADDU   $2,$2,1
                ADDU   $3,$3,4
                CMP    $4,$3,52
                PBNZ   $4,L:82
                SETL   $5,#d
L:83            IS     @
                AND    $6,$6,64
                BZ     $6,L:89
                LDB    $2,$2,0
                SLU    $0,$2,56
                SR     $0,$0,56
                BNZ    $0,L:90
L:89            IS     @
                SET    $0,$5
                POP    1,0
L:90            IS     @
                SETL   $0,0
                POP    1,0

                .p2align 2
                LOC    @+(4-@)&3
FAT32_dir_shutdown IS  @
                GET    $0,:rJ
                LDA    $2,DirCache
                PUSHJ  $1,FAT32_WriteCache
                PUT    :rJ,$0
                POP    0,0

                .p2align 2
                LOC    @+(4-@)&3
FAT_InitDrive   IS     @
                GET    $0,:rJ
                PUSHJ  $1,:Disk:disk_init
                PUT    :rJ,$0
                SET    $0,$1
                POP    1,0

                .p2align 2
                LOC    @+(4-@)&3
FAT_ReadSector  IS     @
                GET    $2,:rJ
                SLU    $0,$0,32
                SRU    $4,$0,32
                SETL   $5,#1
                SET    $6,$1
                PUSHJ  $3,:Disk:disk_read
                PUT    :rJ,$2
                SET    $0,$3
                POP    1,0

                .p2align 2
                LOC    @+(4-@)&3
FAT32_ReadCache IS     @
                GET    $2,:rJ
                SETL   $4,#200
                ADDU   $3,$0,$4
                LDO    $4,$3,0
                CMP    $4,$1,$4
                BZ     $4,L:102
                SET    $6,$0
                PUSHJ  $5,FAT32_WriteCache
                PUT    :rJ,$2
                SLU    $5,$5,32
                SR     $5,$5,32
                BNZ    $5,L:100
L:101           IS     @
                SETL   $0,0
                POP    1,0
L:100           IS     @
                SET    $6,$1
                SET    $7,$0
                PUSHJ  $5,FAT_ReadSector
                PUT    :rJ,$2
                SLU    $5,$5,32
                SR     $5,$5,32
                BZ     $5,L:101
                STOU   $1,$3,0
                INCL   $0,#208
                SETL   $1,0
                STTU   $1,$0,0
L:102           IS     @
                SETL   $0,#1
                POP    1,0

                .p2align 2
                LOC    @+(4-@)&3
FAT32_FindNextCluster IS @
                GET    $2,:rJ
                CSZ    $0,$0,2
                SRU    $1,$0,7
                LDA    $6,FATCache
                LDO    $7,FAT32+24
                ADDU   $7,$1,$7
                PUSHJ  $5,FAT32_ReadCache
                PUT    :rJ,$2
                SLU    $5,$5,32
                SR     $5,$5,32
                PBZ    $5,L:111
                SLU    $1,$1,7
                SUBU   $0,$0,$1
                SLU    $0,$0,2
                LDA    $2,FATCache+3
                LDB    $1,$2,$0
                SLU    $3,$1,56
                SRU    $3,$3,32
                SUBU   $2,$2,1
                LDB    $2,$2,$0
                SLU    $1,$2,56
                SRU    $1,$1,40
                ADDU   $3,$3,$1
                LDA    $2,FATCache
                LDB    $4,$2,$0
                SLU    $1,$4,56
                SRU    $1,$1,56
                ADDU   $1,$3,$1
                ADDU   $2,$2,1
                LDB    $2,$2,$0
                SLU    $0,$2,56
                SRU    $0,$0,48
                ADDU   $1,$1,$0
                SETL   $0,#ffff
                INCML  $0,#fff
                AND    $1,$1,$0
                SETL   $2,#fff7
                INCML  $2,#fff
                CMPU   $2,$1,$2
                SETL   $0,#fff8
                INCML  $0,#fff
                CSNP   $0,$2,$1
                POP    1,0
L:111           IS     @
                SETL   $0,#fff8
                INCML  $0,#fff
                POP    1,0

                .p2align 2
                LOC    @+(4-@)&3
FATName_is_lfn_entry_isra::0 IS @
                AND    $1,$1,63
                CMP    $1,$1,15
                PBNZ   $1,L:119
                BZ     $0,L:115
                CMP    $1,$0,229
                BZ     $1,L:119
                AND    $1,$0,64
                AND    $0,$0,31
                BZ     $1,L:115
                NEGU   $0,0,$0
                POP    1,0
L:119           IS     @
                SETL   $0,0
L:115           IS     @
                POP    1,0

                .p2align 2
                LOC    @+(4-@)&3
FATName_is_sfn_entry_isra::1 IS @
                AND    $1,$1,8
                BNZ    $1,L:123
                BZ     $0,L:122
                XOR    $0,$0,229
                NEGU   $0,0,$0
                SRU    $0,$0,63
                POP    1,0
L:123           IS     @
                SETL   $0,0
L:122           IS     @
                POP    1,0

                .p2align 2
                LOC    @+(4-@)&3
FATName_is_dir_entry_isra::2 IS @
                AND    $1,$1,24
                CMP    $1,$1,16
                PBNZ   $1,L:128
                BZ     $0,L:127
                XOR    $0,$0,229
                NEGU   $0,0,$0
                SRU    $0,$0,63
                POP    1,0
L:128           IS     @
                SETL   $0,0
L:127           IS     @
                POP    1,0

                .p2align 2
                LOC    @+(4-@)&3
FAT32_GetFilelength_isra::3 IS @
                SLU    $1,$1,8
                ADDU   $0,$1,$0
                SLU    $2,$2,16
                ADDU   $0,$0,$2
                SLU    $3,$3,24
                ADDU   $0,$0,$3
                POP    1,0

                .p2align 2
                LOC    @+(4-@)&3
FAT32_GetFileStartcluster_isra::4 IS @
                SLU    $1,$1,8
                ADDU   $0,$1,$0
                SLU    $1,$0,16
                SLU    $3,$3,8
                ADDU   $0,$3,$2
                ADDU   $0,$1,$0
                POP    1,0

                .p2align 2
                LOC    @+(4-@)&3
FAT32_Name_Equal_isra::5 IS @
                GET    $5,:rJ
                GETA   $6,FAT32_ReadCache
                LDA    $12,DirCache
                SET    $13,$3
                PUSHGO $11,$6,0
                PUT    :rJ,$5
                SLU    $11,$11,32
                SR     $11,$11,32
                SET    $9,$6
                PBNZ   $11,L:134
L:137           IS     @
                SETL   $0,0
                POP    1,0
L:134           IS     @
                LDA    $7,DirCache
                ADDU   $3,$4,$7
                SET    $12,$3
                SET    $13,$0
                PUSHJ  $11,Name_CompareSN
                PUT    :rJ,$5
                SLU    $11,$11,32
                SR     $11,$11,32
                PBZ    $11,L:136
L:139           IS     @
                SETL   $0,#1
                POP    1,0
L:136           IS     @
                CMP    $6,$1,1
                BNP    $6,L:137
                SET    $12,$3
                PUSHJ  $11,FATName_ChkSum
                SETL   $3,#1
                SLU    $11,$11,56
                SRU    $10,$11,56
L:140           IS     @
                SUBU   $4,$4,32
                SLU    $4,$4,32
                SR     $4,$4,32
                PBNN   $4,L:138
                LDA    $12,DirCache
                SET    $13,$2
                PUSHGO $11,$9,0
                PUT    :rJ,$5
                SLU    $11,$11,32
                SR     $11,$11,32
                BZ     $11,L:137
                SETL   $4,#1e0
L:138           IS     @
                SLU    $15,$3,32
                ADDU   $12,$7,$4
                SET    $13,$0
                SET    $14,$10
                SR     $15,$15,32
                PUSHJ  $11,FATName_Compare_entry
                PUT    :rJ,$5
                SLU    $6,$11,32
                SR     $6,$6,32
                BZ     $6,L:137
                ADDU   $0,$0,$6
                ADDU   $8,$3,1
                SET    $3,$8
                SLU    $6,$8,32
                SR     $6,$6,32
                CMP    $6,$6,$1
                PBNZ   $6,L:140
                JMP    L:139

                .p2align 2
                LOC    @+(4-@)&3
FAT32_ClusterOffset2lba_isra::6_constprop::8 IS @
                GET    $4,:rJ
                SET    $9,$0
                PBNZ   $0,L:149
L:152           IS     @
                SETL   $0,0
                POP    1,0
L:149           IS     @
                LDB    $0,FAT32
                SLU    $2,$0,56
                SRU    $2,$2,56
                DIVU   $0,$1,$2
                SETL   $3,0
                SETL   $5,#fff7
                INCML  $5,#fff
L:151           IS     @
                CMP    $6,$3,$0
                BZ     $6,L:155
                PUSHJ  $8,FAT32_FindNextCluster
                PUT    :rJ,$4
                SET    $9,$8
                SETL   $7,#ffff
                INCML  $7,#fff
                AND    $6,$8,$7
                CMPU   $6,$6,$5
                BP     $6,L:152
                ADDU   $3,$3,1
                JMP    L:151
L:155           IS     @
                PUSHJ  $8,FAT32_LBAofCluster
                PUT    :rJ,$4
                MULU   $2,$3,$2
                SUBU   $1,$1,$2
                ADDU   $0,$1,$8
                POP    1,0

                .p2align 2
                LOC    @+(4-@)&3
sector_to_lba_constprop::7 IS @
                GET    $3,:rJ
                LDO    $5,$0,32
                CMP    $2,$1,$5
                PBNZ   $2,L:157
                LDO    $0,$0,40
                POP    1,0
L:157           IS     @
                LDB    $4,FAT32
                SLU    $2,$4,56
                SRU    $2,$2,56
                DIVU   $4,$1,$2
                DIVU   $2,$5,$2
                CMP    $2,$4,$2
                PBNZ   $2,L:159
                LDO    $2,$0,40
                SUBU   $5,$2,$5
                ADDU   $5,$5,$1
                JMP    L:160
L:159           IS     @
                LDO    $6,$0,16
                SET    $7,$1
                PUSHJ  $5,FAT32_ClusterOffset2lba_isra::6_constprop::8
                PUT    :rJ,$3
L:160           IS     @
                BZ     $5,L:161
                STOU   $1,$0,32
                STOU   $5,$0,40
L:161           IS     @
                SET    $0,$5
                POP    1,0

                .p2align 2
                LOC    @+(4-@)&3
read_block      IS     @
                GET    $7,:rJ
                BZ     $1,L:173
                SETL   $4,#260
                MULU   $4,$2,$4
                LDA    $3,Files
                ADDU   $4,$4,$3
                LDO    $6,$4,24
                LDO    $3,$4,48
                CMPU   $5,$6,$3
                BNN    $5,L:174
                ADDU   $5,$1,$6
                CMPU   $5,$5,$3
                BNP    $5,L:165
                SUBU   $1,$3,$6
                SLU    $1,$1,32
                SRU    $1,$1,32
L:165           IS     @
                SRU    $5,$6,9
                SETL   $3,#1ff
                AND    $6,$6,$3
                SETL   $3,#3
                INCH   $3,#8000
                AND    $2,$2,$3
                PBNN   $2,L:166
                SUBU   $2,$2,1
                NEGU   $3,0,4
                OR     $2,$2,$3
                ADDU   $2,$2,1
L:166           IS     @
                SLU    $2,$2,32
                SR     $2,$2,32
                SLU    $3,$2,4
                SLU    $2,$2,9
                ADDU   $2,$3,$2
                LDA    $3,FileCache
                ADDU   $2,$2,$3
                SETL   $3,#1ff
                ADDU   $10,$6,$3
                ADDU   $10,$10,$1
                SRU    $10,$10,9
                ADDU   $10,$10,$5
                SETL   $3,0
                SETL   $9,#200
L:167           IS     @
                CMP    $8,$5,$10
                BZ     $8,L:171
                SET    $13,$4
                SET    $14,$5
                PUSHJ  $12,sector_to_lba_constprop::7
                PUT    :rJ,$7
                BZ     $12,L:178
                SET    $13,$2
                SET    $14,$12
                PUSHJ  $12,FAT32_ReadCache
                PUT    :rJ,$7
                SLU    $12,$12,32
                SR     $12,$12,32
                BZ     $12,L:178
                ADDU   $8,$1,$6
                SUBU   $11,$9,$6
                CMPU   $8,$8,$9
                CSNP   $11,$8,$1
                ADDU   $13,$0,$3
                ADDU   $14,$2,$6
                SET    $15,$11
                PUSHJ  $12,memcpy
                PUT    :rJ,$7
                ADDU   $3,$3,$11
                SUBU   $1,$1,$11
                SLU    $1,$1,32
                SRU    $1,$1,32
                BZ     $1,L:171
                ADDU   $5,$5,1
                SETL   $6,0
                JMP    L:167
L:171           IS     @
                LDO    $0,$4,24
                ADDU   $0,$0,$3
                STOU   $0,$4,24
L:178           IS     @
                SET    $0,$3
                POP    1,0
L:173           IS     @
                SET    $0,$1
                POP    1,0
L:174           IS     @
                NEGU   $0,0,1
                POP    1,0

                .p2align 2
                LOC    @+(4-@)&3
FAT32_SectorReader IS  @
                GET    $2,:rJ
                SET    $4,$0
                SET    $5,$1
                PUSHJ  $3,FAT32_ClusterOffset2lba_isra::6_constprop::8
                PUT    :rJ,$2
                PBZ    $3,L:181
                LDA    $4,DirCache
                SET    $5,$3
                PUSHJ  $3,FAT32_ReadCache
                PUT    :rJ,$2
L:181           IS     @
                SET    $0,$3
                POP    1,0

                .p2align 2
                LOC    @+(4-@)&3
FAT32_FindNextFile IS  @
                SUBU   $254,$254,40
                STOU   $253,$254,0
                GET    $10,:rJ
                LDT    $11,$1,0
                LDT    $8,$2,0
                SETL   $7,0
                SET    $253,$7
                SET    $9,$7
                SLU    $14,$11,32
                SR     $14,$14,32
                LDA    $12,DirCache
L:185           IS     @
                ADDU   $13,$7,$11
                STTU   $13,$254,36
                SET    $16,$0
                ADDU   $17,$7,$14
                PUSHJ  $15,FAT32_SectorReader
                PUT    :rJ,$10
                SLU    $13,$15,32
                SR     $13,$13,32
                BZ     $13,L:191
L:193           IS     @
                SLU    $13,$8,56
                SRU    $13,$13,56
                CMPU   $13,$13,15
                BP     $13,L:201
                SLU    $19,$8,56
                SRU    $19,$19,56
                SLU    $13,$19,5
                LDB    $22,$12,$13
                ADDU   $15,$12,$13
                LDB    $21,$15,11
                SLU    $16,$22,56
                SLU    $17,$21,56
                SRU    $16,$16,56
                SRU    $17,$17,56
                STOU   $19,$254,8
                STOU   $21,$254,16
                STOU   $22,$254,24
                PUSHJ  $15,FATName_is_lfn_entry_isra::0
                SLU    $20,$15,32
                SR     $20,$20,32
                LDO    $22,$254,24
                SLU    $16,$22,56
                LDO    $21,$254,16
                SLU    $17,$21,56
                LDO    $19,$254,8
                BZ     $20,L:186
                PBNN   $20,L:187
                NEGU   $9,0,$15
                LDO    $13,DirCache+512
                STOU   $13,$3,0
                SLU    $19,$19,5
                STTU   $19,$4,0
                NOR    $15,$15,0
                JMP    L:199
L:187           IS     @
                SLU    $18,$253,32
                SR     $18,$18,32
                CMP    $18,$20,$18
                PBNZ   $18,L:194
                SUBU   $15,$15,1
L:199           IS     @
                SET    $253,$15
                JMP    L:188
L:186           IS     @
                SRU    $16,$16,56
                SRU    $17,$17,56
                PUSHJ  $15,FATName_is_sfn_entry_isra::1
                PUT    :rJ,$10
                SLU    $15,$15,32
                SR     $15,$15,32
                PBZ    $15,L:195
                SLU    $0,$9,32
                SR     $0,$0,32
                BNZ    $0,L:189
                LDO    $0,DirCache+512
                STOU   $0,$5,0
                STOU   $0,$3,0
                SETL   $0,#1fe0
                AND    $13,$13,$0
                STTU   $13,$6,0
                STTU   $13,$4,0
                JMP    L:190
L:189           IS     @
                LDO    $16,DirCache+512
                STOU   $16,$5,0
                SETL   $0,#1fe0
                AND    $13,$13,$0
                STTU   $13,$6,0
L:190           IS     @
                LDT    $13,$254,36
                STTU   $13,$1,0
                SLU    $8,$8,56
                SRU    $8,$8,56
                STTU   $8,$2,0
                ADDU   $15,$9,1
                JMP    L:191
L:194           IS     @
                SETL   $253,0
                SET    $9,$253
                JMP    L:188
L:195           IS     @
                SET    $9,$15
L:188           IS     @
                ADDU   $8,$8,1
                JMP    L:193
L:201           IS     @
                ADDU   $7,$7,1
                SETL   $8,0
                JMP    L:185
L:191           IS     @
                SET    $0,$15
                LDO    $253,$254,0
                ADDU   $254,$254,40
                POP    1,0

                .p2align 2
                LOC    @+(4-@)&3
FAT32_GetFileEntry IS  @
                SUBU   $254,$254,32
                GET    $4,:rJ
                SETL   $3,0
                STTU   $3,$254,0
L:207           IS     @
                STTU   $3,$254,4
                SET    $7,$0
                SET    $8,$254
                ADDU   $9,$254,4
                ADDU   $10,$254,16
                ADDU   $11,$254,8
                ADDU   $12,$254,24
                ADDU   $13,$254,12
                PUSHJ  $6,FAT32_FindNextFile
                PUT    :rJ,$4
                SLU    $3,$6,32
                SR     $3,$3,32
                SLU    $8,$6,32
                BZ     $3,L:209
                LDT    $5,$254,12
                SLU    $11,$5,32
                SET    $7,$1
                SR     $8,$8,32
                LDO    $9,$254,16
                LDO    $10,$254,24
                SR     $11,$11,32
                PUSHJ  $6,FAT32_Name_Equal_isra::5
                SLU    $6,$6,32
                SR     $6,$6,32
                PBZ    $6,L:204
                LDA    $7,DirCache
                LDO    $8,$254,24
                PUSHJ  $6,FAT32_ReadCache
                PUT    :rJ,$4
                LDT    $1,$254,0
                SLU    $0,$1,4
                LDT    $3,$254,4
                ADDU   $0,$0,$3
                STTU   $0,$2,0
                LDA    $0,DirCache
                LDT    $5,$254,12
                ADDU   $0,$0,$5
                JMP    L:205
L:204           IS     @
                LDT    $5,$254,4
                ADDU   $3,$5,1
                JMP    L:207
L:209           IS     @
                SET    $0,$3
L:205           IS     @
                ADDU   $254,$254,32
                POP    1,0

                .p2align 2
                LOC    @+(4-@)&3
FAT32_FindLBABegin_constprop::9 IS @
                GET    $0,:rJ
                LDA    $4,FATCache
                SETL   $5,0
                PUSHJ  $3,FAT32_ReadCache
                PUT    :rJ,$0
                SLU    $3,$3,32
                SR     $3,$3,32
                BZ     $3,L:216
                LDB    $0,FATCache+511
                SLU    $1,$0,56
                SRU    $1,$1,48
                LDB    $2,FATCache+510
                SLU    $0,$2,56
                SRU    $0,$0,56
                ADDU   $0,$0,$1
                SETL   $1,#aa55
                CMP    $0,$0,$1
                PBNZ   $0,L:216
                LDB    $0,FATCache+450
                SUBU   $2,$0,5
                SLU    $1,$2,56
                SRU    $1,$1,56
                CMPU   $1,$1,10
                SLU    $2,$2,56
                BP     $1,L:212
                SRU    $2,$2,56
                SETL   $1,#1
                SLU    $2,$1,$2
                SETL   $1,#6c3
                AND    $2,$2,$1
                BNZ    $2,L:213
L:212           IS     @
                SLU    $0,$0,56
                SRU    $0,$0,56
                CMPU   $0,$0,6
                BP     $0,L:216
L:213           IS     @
                LDB    $2,FATCache+457
                SLU    $1,$2,56
                SRU    $1,$1,32
                LDB    $2,FATCache+456
                SLU    $0,$2,56
                SRU    $0,$0,40
                ADDU   $1,$1,$0
                LDB    $2,FATCache+454
                SLU    $0,$2,56
                SRU    $0,$0,56
                ADDU   $0,$1,$0
                LDB    $2,FATCache+455
                SLU    $1,$2,56
                SRU    $1,$1,48
                ADDU   $0,$0,$1
                STOU   $0,FAT32+16
                SETL   $0,#1
                POP    1,0
L:216           IS     @
                SETL   $0,0
                POP    1,0

                .p2align 2
                LOC    @+(4-@)&3
FAT32_Init      IS     @
                GET    $0,:rJ
                GETA   $1,FAT32_InitCache
                LDA    $7,FATCache
                PUSHGO $6,$1,0
                LDA    $7,FAT2Cache
                PUSHGO $6,$1,0
                PUSHJ  $6,FAT32_FindLBABegin_constprop::9
                PUT    :rJ,$0
                SLU    $6,$6,32
                SR     $6,$6,32
                BNZ    $6,L:219
L:221           IS     @
                SETL   $0,0
                POP    1,0
L:219           IS     @
                LDA    $7,FATCache
                LDO    $8,FAT32+16
                PUSHJ  $6,FAT32_ReadCache
                PUT    :rJ,$0
                SLU    $6,$6,32
                SR     $6,$6,32
                BZ     $6,L:221
                LDB    $0,FATCache+511
                SLU    $1,$0,56
                SRU    $1,$1,48
                LDB    $2,FATCache+510
                SLU    $0,$2,56
                SRU    $0,$0,56
                ADDU   $0,$0,$1
                SETL   $1,#aa55
                CMP    $0,$0,$1
                PBNZ   $0,L:221
                LDB    $3,FATCache+12
                SLU    $1,$3,56
                SRU    $1,$1,48
                LDB    $5,FATCache+11
                SLU    $0,$5,56
                SRU    $0,$0,56
                ADDU   $0,$0,$1
                STWU   $0,FAT32+2
                SLU    $0,$0,48
                SRU    $0,$0,48
                SETL   $1,#200
                CMP    $0,$0,$1
                PBNZ   $0,L:221
                LDB    $0,FATCache+13
                STBU   $0,FAT32
                LDB    $1,FATCache+15
                SLU    $2,$1,56
                SRU    $2,$2,48
                LDB    $3,FATCache+14
                SLU    $1,$3,56
                SRU    $1,$1,56
                ADDU   $1,$1,$2
                STWU   $1,FAT32+4
                LDB    $2,FATCache+16
                STBU   $2,FAT32+6
                LDB    $5,FATCache+23
                SLU    $4,$5,56
                SRU    $4,$4,48
                LDB    $5,FATCache+22
                SLU    $3,$5,56
                SRU    $3,$3,56
                ADDU   $3,$3,$4
                STOU   $3,FAT32+40
                BNZ    $3,L:222
                LDB    $3,FATCache+39
                SLU    $4,$3,56
                SRU    $4,$4,32
                LDB    $5,FATCache+38
                SLU    $3,$5,56
                SRU    $3,$3,40
                ADDU   $4,$4,$3
                LDB    $5,FATCache+36
                SLU    $3,$5,56
                SRU    $3,$3,56
                ADDU   $3,$4,$3
                LDB    $5,FATCache+37
                SLU    $4,$5,56
                SRU    $4,$4,48
                ADDU   $3,$3,$4
                STOU   $3,FAT32+40
L:222           IS     @
                LDB    $3,FATCache+47
                SLU    $4,$3,56
                SRU    $4,$4,32
                LDB    $5,FATCache+46
                SLU    $3,$5,56
                SRU    $3,$3,40
                ADDU   $4,$4,$3
                LDB    $5,FATCache+44
                SLU    $3,$5,56
                SRU    $3,$3,56
                ADDU   $3,$4,$3
                LDB    $5,FATCache+45
                SLU    $4,$5,56
                SRU    $4,$4,48
                ADDU   $3,$3,$4
                STOU   $3,FAT32+8
                LDB    $3,FATCache+49
                SLU    $4,$3,56
                SRU    $4,$4,48
                LDB    $5,FATCache+48
                SLU    $3,$5,56
                SRU    $3,$3,56
                ADDU   $3,$3,$4
                STWU   $3,FAT32+72
                SLU    $1,$1,48
                SRU    $1,$1,48
                LDO    $4,FAT32+16
                ADDU   $4,$1,$4
                STOU   $4,FAT32+24
                SLU    $2,$2,56
                SRU    $2,$2,56
                LDO    $3,FAT32+40
                MULU   $3,$2,$3
                ADDU   $4,$4,$3
                STOU   $4,FAT32+32
                LDB    $2,FATCache+18
                SLU    $4,$2,56
                SRU    $4,$4,48
                LDB    $5,FATCache+17
                SLU    $2,$5,56
                SRU    $2,$2,56
                ADDU   $2,$2,$4
                BNZ    $2,L:221
                LDB    $2,FATCache+20
                SLU    $4,$2,56
                SRU    $4,$4,48
                LDB    $5,FATCache+19
                SLU    $2,$5,56
                SRU    $2,$2,56
                ADDU   $2,$2,$4
                STOU   $2,FAT32+48
                BNZ    $2,L:223
                LDB    $2,FATCache+35
                SLU    $4,$2,56
                SRU    $4,$4,32
                LDB    $5,FATCache+34
                SLU    $2,$5,56
                SRU    $2,$2,40
                ADDU   $4,$4,$2
                LDB    $5,FATCache+32
                SLU    $2,$5,56
                SRU    $2,$2,56
                ADDU   $2,$4,$2
                LDB    $5,FATCache+33
                SLU    $4,$5,56
                SRU    $4,$4,48
                ADDU   $2,$2,$4
                STOU   $2,FAT32+48
L:223           IS     @
                LDO    $2,FAT32+48
                SUBU   $2,$2,$3
                SUBU   $1,$2,$1
                STOU   $1,FAT32+56
                SLU    $0,$0,56
                SRU    $0,$0,56
                DIVU   $0,$1,$0
                STOU   $0,FAT32+64
                SETL   $0,#1
                POP    1,0

                .p2align 2
                LOC    @+(4-@)&3
                .global fat32_initialize
fat32_initialize IS    @
                GET    $1,:rJ
                SETL   $0,0
                STTU   $0,Filelib_Init
                PUSHJ  $6,FAT_InitDrive
                PUT    :rJ,$1
                SLU    $6,$6,32
                SR     $6,$6,32
                PBZ    $6,L:228
                PUSHJ  $6,FAT32_Init
                PUT    :rJ,$1
                SLU    $6,$6,32
                SR     $6,$6,32
                BZ     $6,L:228
                SETL   $0,0
                LDA    $4,Files
                SETL   $3,#1300
L:233           IS     @
                ADDU   $2,$0,$4
                INCL   $2,#248
                SETL   $5,0
                STTU   $5,$2,0
                INCL   $0,#260
                CMP    $2,$0,$3
                PBNZ   $2,L:233
                GETA   $0,FAT32_InitCache
                LDA    $7,FileCache
                PUSHGO $6,$0,0
                LDA    $7,FileCache+528
                PUSHGO $6,$0,0
                LDA    $7,FileCache+1056
                PUSHGO $6,$0,0
                LDA    $7,FileCache+1584
                PUSHGO $6,$0,0
                PUT    :rJ,$1
                SETL   $0,#1
                STTU   $0,Filelib_Init
L:228           IS     @
                POP    0,0

                .p2align 2
                LOC    @+(4-@)&3
                .global fat32_fclose
fat32_fclose    IS     @
                GET    $2,:rJ
                LDT    $3,Filelib_Init
                SLU    $1,$3,32
                SR     $1,$1,32
                PBNZ   $1,L:239
                PUSHJ  $4,fat32_initialize
                PUT    :rJ,$2
L:239           IS     @
                SLU    $1,$0,32
                SRU    $1,$1,32
                CMPU   $1,$1,7
                BP     $1,L:241
                SETL   $1,#260
                MULU   $1,$0,$1
                LDA    $3,Files
                ADDU   $1,$1,$3
                STCO   0,$1,24
                STCO   0,$1,48
                STCO   0,$1,16
                SETL   $3,#ffff
                INCML  $3,#ffff
                STOU   $3,$1,32
                INCL   $1,#248
                SETL   $3,0
                STTU   $3,$1,0
                AND    $0,$0,3
                SLU    $1,$0,4
                SLU    $0,$0,9
                ADDU   $0,$1,$0
                LDA    $5,FileCache
                ADDU   $5,$5,$0
                PUSHJ  $4,FAT32_WriteCache
                PUT    :rJ,$2
                SET    $0,$3
                POP    1,0
L:241           IS     @
                NEGU   $0,0,1
                POP    1,0

                .p2align 2
                LOC    @+(4-@)&3
                .global fat32_shutdown
fat32_shutdown  IS     @
                GET    $3,:rJ
                LDT    $1,Filelib_Init
                SLU    $0,$1,32
                SR     $0,$0,32
                BZ     $0,L:243
                SETL   $0,0
                SET    $1,$0
                LDA    $5,Files
                SETL   $4,#1300
L:247           IS     @
                ADDU   $2,$0,$5
                INCL   $2,#248
                LDT    $2,$2,0
                SLU    $2,$2,32
                SR     $2,$2,32
                PBZ    $2,L:245
                SLU    $7,$1,32
                SR     $7,$7,32
                PUSHJ  $6,fat32_fclose
L:245           IS     @
                ADDU   $1,$1,1
                INCL   $0,#260
                CMP    $2,$0,$4
                PBNZ   $2,L:247
                GETA   $0,FAT32_WriteCache
                LDA    $7,FileCache
                PUSHGO $6,$0,0
                LDA    $7,FileCache+528
                PUSHGO $6,$0,0
                LDA    $7,FileCache+1056
                PUSHGO $6,$0,0
                LDA    $7,FileCache+1584
                PUSHGO $6,$0,0
                PUSHJ  $6,FAT32_dir_shutdown
                PUSHJ  $6,FAT32_FAT_shutdown
                PUT    :rJ,$3
L:243           IS     @
                POP    0,0

                .p2align 2
                LOC    @+(4-@)&3
                .global fat32_fread
fat32_fread     IS     @
                GET    $5,:rJ
                LDT    $4,Filelib_Init
                SLU    $3,$4,32
                SR     $3,$3,32
                PBNZ   $3,L:256
                PUSHJ  $7,fat32_initialize
                PUT    :rJ,$5
L:256           IS     @
                SLU    $3,$2,32
                SRU    $3,$3,32
                CMPU   $3,$3,7
                BP     $3,L:261
                LDA    $4,Files+584
                SETL   $3,#260
                MULU   $3,$2,$3
                ADDU   $6,$4,$3
                LDT    $4,$4,$3
                SLU    $4,$4,32
                SR     $4,$4,32
                BZ     $4,L:261
                LDT    $6,$6,4
                SLU    $4,$6,32
                SR     $4,$4,32
                BZ     $4,L:261
                BZ     $0,L:261
                LDA    $4,Files
                ADDU   $3,$4,$3
                LDO    $4,$3,24
                LDO    $3,$3,48
                CMPU   $3,$4,$3
                PBNN   $3,L:262
                SET    $8,$0
                SET    $9,$1
                SET    $10,$2
                PUSHJ  $7,read_block
                PUT    :rJ,$5
                SET    $0,$7
                POP    1,0
L:261           IS     @
                NEGU   $0,0,1
                POP    1,0
L:262           IS     @
                SETL   $0,0
                POP    1,0

                .p2align 2
                LOC    @+(4-@)&3
                .global Name_GetFirstDirectory
Name_GetFirstDirectory IS @
                GET    $3,:rJ
                SET    $5,$0
                PUSHJ  $4,skip_root
                SET    $5,$4
                SET    $6,$1
                SET    $7,$2
                PUSHJ  $4,Name_GetNextDirectory
                PUT    :rJ,$3
                SET    $0,$4
                POP    1,0

                .p2align 2
                LOC    @+(4-@)&3
FAT32_GetDirectory IS  @
                SUBU   $254,$254,8
                GET    $7,:rJ
                LDO    $5,FAT32+8
                SETL   $4,#2f
                STBU   $4,$1,0
                ADDU   $4,$1,1
                SET    $10,$0
                SET    $11,$4
                SETL   $12,#103
                PUSHJ  $9,Name_GetFirstDirectory
L:276           IS     @
                SET    $6,$9
                BZ     $9,L:278
                SET    $10,$5
                SET    $11,$4
                ADDU   $12,$254,4
                PUSHJ  $9,FAT32_GetFileEntry
                PUT    :rJ,$7
                SET    $5,$9
                BZ     $9,L:267
                LDB    $8,$9,0
                SLU    $10,$8,56
                LDB    $8,$9,11
                SLU    $11,$8,56
                SRU    $10,$10,56
                SRU    $11,$11,56
                PUSHJ  $9,FATName_is_dir_entry_isra::2
                PUT    :rJ,$7
                SLU    $9,$9,32
                SR     $9,$9,32
                BZ     $9,L:267
                LDB    $8,$5,20
                SLU    $10,$8,56
                LDB    $8,$5,21
                SLU    $11,$8,56
                LDB    $8,$5,26
                SLU    $12,$8,56
                LDB    $5,$5,27
                SLU    $13,$5,56
                SRU    $10,$10,56
                SRU    $11,$11,56
                SRU    $12,$12,56
                SRU    $13,$13,56
                PUSHJ  $9,FAT32_GetFileStartcluster_isra::4
                SET    $5,$9
                SUBU   $0,$6,$0
                SLU    $0,$0,32
                SR     $0,$0,32
                ADDU   $4,$4,$0
                SUBU   $0,$4,1
                SETL   $8,#2f
                STBU   $8,$0,0
                SUBU   $12,$1,$4
                INCL   $12,#104
                SLU    $12,$12,32
                SET    $10,$6
                SET    $11,$4
                SR     $12,$12,32
                PUSHJ  $9,Name_GetNextDirectory
                SET    $0,$6
                JMP    L:276
L:267           IS     @
                SETL   $0,0
                STBU   $0,$2,0
                STBU   $0,$1,0
                STCO   0,$3,0
                SETL   $0,0
                JMP    L:268
L:278           IS     @
                SET    $10,$2
                SET    $11,$4
                PUSHJ  $9,Name_Trim
                PUT    :rJ,$7
                SUBU   $4,$4,1
                STBU   $6,$4,0
                STOU   $5,$3,0
                SETL   $0,#1
L:268           IS     @
                ADDU   $254,$254,8
                POP    1,0

                .p2align 2
                LOC    @+(4-@)&3
open_read_file  IS     @
                GET    $3,:rJ
                SETL   $2,#260
                MULU   $0,$0,$2
                LDA    $5,Files
                ADDU   $2,$0,$5
                SETL   $6,#13c
                ADDU   $4,$2,$6
                SET    $8,$1
                ADDU   $9,$2,56
                SET    $10,$4
                SET    $11,$2
                PUSHJ  $7,FAT32_GetDirectory
                PUT    :rJ,$3
                SLU    $7,$7,32
                SR     $7,$7,32
                BNZ    $7,L:280
L:282           IS     @
                SETL   $0,0
                POP    1,0
L:280           IS     @
                LDO    $8,$0,$5
                SET    $9,$4
                ADDU   $10,$2,8
                PUSHJ  $7,FAT32_GetFileEntry
                PUT    :rJ,$3
                SET    $0,$7
                BZ     $7,L:282
                LDB    $1,$7,0
                SLU    $8,$1,56
                LDB    $4,$7,11
                SLU    $9,$4,56
                SRU    $8,$8,56
                SRU    $9,$9,56
                PUSHJ  $7,FATName_is_dir_entry_isra::2
                PUT    :rJ,$3
                SLU    $1,$7,32
                SR     $1,$1,32
                PBNZ   $1,L:282
                SETL   $6,#23c
                ADDU   $8,$2,$6
                SET    $9,$0
                SETL   $10,#b
                PUSHJ  $7,memcpy
                LDB    $4,$0,28
                SLU    $8,$4,56
                LDB    $6,$0,29
                SLU    $9,$6,56
                LDB    $4,$0,30
                SLU    $10,$4,56
                LDB    $6,$0,31
                SLU    $11,$6,56
                SRU    $8,$8,56
                SRU    $9,$9,56
                SRU    $10,$10,56
                SRU    $11,$11,56
                PUSHJ  $7,FAT32_GetFilelength_isra::3
                STOU   $7,$2,48
                STOU   $1,$2,24
                LDB    $1,$0,20
                SLU    $8,$1,56
                LDB    $4,$0,21
                SLU    $9,$4,56
                LDB    $6,$0,26
                SLU    $10,$6,56
                LDB    $0,$0,27
                SLU    $11,$0,56
                SRU    $8,$8,56
                SRU    $9,$9,56
                SRU    $10,$10,56
                SRU    $11,$11,56
                PUSHJ  $7,FAT32_GetFileStartcluster_isra::4
                PUT    :rJ,$3
                STOU   $7,$2,16
                SETL   $0,#ffff
                INCML  $0,#ffff
                STOU   $0,$2,32
                INCL   $2,#248
                SETL   $1,#1
                STTU   $1,$2,0
                SET    $0,$1
                POP    1,0

                .p2align 2
                LOC    @+(4-@)&3
                .global fat32_fopen
fat32_fopen     IS     @
                GET    $5,:rJ
                LDT    $4,Filelib_Init
                SLU    $3,$4,32
                SR     $3,$3,32
                PBNZ   $3,L:288
                PUSHJ  $7,fat32_initialize
                PUT    :rJ,$5
L:288           IS     @
                SLU    $3,$2,32
                SRU    $3,$3,32
                CMPU   $3,$3,7
                BP     $3,L:296
                BZ     $0,L:296
                CMP    $3,$1,4
                BP     $3,L:296
                LDA    $4,Files+584
                SETL   $3,#260
                MULU   $3,$2,$3
                LDT    $6,$4,$3
                SLU    $3,$6,32
                SR     $3,$3,32
                BNZ    $3,L:296
                BZ     $1,L:292
                CMP    $1,$1,2
                BZ     $1,L:298
                SET    $1,$3
L:290           IS     @
                SETL   $0,#260
                MULU   $2,$2,$0
                ADDU   $5,$4,$2
                LDT    $0,$4,$2
                BZ     $0,L:300
                STTU   $3,$5,4
                LDA    $0,Files+592
                ADDU   $3,$0,$2
                SETL   $4,0
                STTU   $4,$0,$2
                STTU   $4,$3,4
                ADDU   $0,$0,8
                ADDU   $3,$0,$2
                STTU   $1,$0,$2
                STTU   $4,$3,4
                SET    $0,1
                POP    1,0
L:296           IS     @
                NEGU   $0,0,1
                POP    1,0
L:298           IS     @
                SETL   $1,#1
L:292           IS     @
                SLU    $7,$2,56
                SRU    $7,$7,56
                SET    $8,$0
                PUSHJ  $6,open_read_file
                PUT    :rJ,$5
                SETL   $3,#1
                JMP    L:290
L:300           IS     @
                POP    1,0

nameIndexes     IS     @
                TETRA  #1
                TETRA  #3
                TETRA  #5
                TETRA  #7
                TETRA  #9
                TETRA  #e
                TETRA  #10
                TETRA  #12
                TETRA  #14
                TETRA  #16
                TETRA  #18
                TETRA  #1c
                TETRA  #1e

%		END of compiler generated code: FAT32.mms 


                PREFIX :GUI:
%		Initialize GUI
%		Preload sound buffers to the sound card
%		Load Bitmaps to off-screen memory
width           IS     32
height          IS     32
ids             IS     15                              number of possible ids
                % 0=RIGHT, 1=UP, 2=LEFT, 3=DOWN
                % 4=TURNRIGHT, 5=TURNLEFT, 6=STRAIGHT,
                % 7=LETTERA, 8=LETTERB, 9=EMPTY,
                % 10=STOP, 11=RUN, 12=RUNFAST
return          IS     $0
rBB             IS     $1
tmp             IS     $2

                % initialize bitmaps
:gui            GET    return,:rJ
                GET    rBB,:rBB
                GETA   tmp+1,:args
                PUT    :rBB,tmp+1
                PUSHJ  tmp,:FTrap:GPutDIB
                PUT    :rBB,rBB
                PUT    :rJ,return
                POP    0,0


                PREFIX :ADDR:
                LOC    (@+7)&~7                        align to OCTA
:args           WYDE   0,0,640,0
                OCTA   bitmaps

:mp3s           IS     @
%		OCTA	slurp
%		OCTA	crunch
%		OCTA	munch
%		OCTA	crash
%		OCTA	bite
%		OCTA	last

                % here we have the bitmaps:
                LOC    (@+7)&~7                        align to OCTA
bitmaps         IS     @
%                FILE	"bitmaps.bmp"

%		 here we have the sound files
%		LOC		(@+7)&~7	align to OCTA
%slurp	FILE	"slurp.mp3"
%crunch	FILE	"crunch.mp3"
%munch	FILE	"munch.mp3"
%crash	FILE	"crash.mp3"
%bite	FILE	"bite.mp3"
%last	BYTE	0

