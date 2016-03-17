
IDE_DRIVER.Enter:

#Subject to change if necessary
MOV CS_HD INTO CHIP_SELECT

#Arrange our location table
MOV8 IDE_DRIVER.Cyl[2] INTO IDE_DRIVER.Cyl23
MOV8 IDE_DRIVER.Cyl[0] INTO IDE_DRIVER.Cyl01

#Setup our pointers for the location loop
MOVADDR IDE_DRIVER.RegTable INTO IDE_DRIVER.RegPtr[1]
MOVADDR IDE_DRIVER.LocTable INTO IDE_DRIVER.LocPtr1[1]

MOV N_[0] INTO IDE_DRIVER.LocationLoop

IDE_DRIVER.SetupLoop:

#Enter sector count - always 1

MOV N_[0b0100] INTO STATUS_BUS
IDE_DRIVER.RegPtr:
LOD 0x0000
STR DATA_BUS
MOV N_[0b0000] INTO STATUS_BUS

MOV N_[0b0100] INTO STATUS_BUS
MOV N_[0b0000] INTO STATUS_BUS
MOV N_[0b0100] INTO STATUS_BUS
MOV N_[0b0000] INTO STATUS_BUS

MOV N_[0b0100] INTO STATUS_BUS
IDE_DRIVER.LocPtr1:
LOD 0x0000
STR DATA_BUS
MOV N_[0b0000] INTO STATUS_BUS

INC16 IDE_DRIVER.LocPtr1[1] INTO IDE_DRIVER.LocPtr2[1]

MOV N_[0b0100] INTO STATUS_BUS
IDE_DRIVER.LocPtr2:
LOD 0x0000
STR DATA_BUS
MOV N_[0b0000] INTO STATUS_BUS

INC16 IDE_DRIVER.LocPtr2[1] INTO IDE_DRIVER.LocPtr1[1]

MOV N_[0b0100] INTO STATUS_BUS
MOV N_[0b0000] INTO STATUS_BUS
MOV N_[0b0100] INTO STATUS_BUS
MOV N_[0b0000] INTO STATUS_BUS
MOV N_[0b0100] INTO STATUS_BUS
MOV N_[0b0000] INTO STATUS_BUS
MOV N_[0b0100] INTO STATUS_BUS
MOV N_[0b0000] INTO STATUS_BUS

INC16 IDE_DRIVER.RegPtr[1]
INC IDE_DRIVER.LocationLoop
#will never cause carry, and leaves value in acc

ADD N_[B]
LOGNOT ACC
JMP IDE_DRIVER.SetupLoop
#Repeat 5 times

#Control flow splits here:
#If they wrote zero to ZeroToWrite, skip
#ahead to the write driver

MOV N_[0] INTO IDE_DRIVER.LoopCount[0]
MOV N_[0] INTO IDE_DRIVER.LoopCount[1]
MOV N_[0] INTO IDE_DRIVER.LoopCount[2]
MOV N_[0] INTO IDE_DRIVER.LoopCount[3]

LOD IDE_DRIVER.ZeroToWrite
JMP IDE_DRIVER.Write

#-----------------------------------------------------------------
#Code to read:


#Tell it to start reading
MOV N_[0b0100] INTO STATUS_BUS
MOV N_[F] INTO DATA_BUS
MOV N_[0b0000] INTO STATUS_BUS

MOV N_[0b0100] INTO STATUS_BUS
MOV N_[0b0000] INTO STATUS_BUS
MOV N_[0b0100] INTO STATUS_BUS
MOV N_[0b0000] INTO STATUS_BUS

MOV N_[0b0100] INTO STATUS_BUS
MOV N_[2] INTO DATA_BUS
MOV N_[0b0000] INTO STATUS_BUS

MOV N_[0b0100] INTO STATUS_BUS
MOV N_[0] INTO DATA_BUS
MOV N_[0b0000] INTO STATUS_BUS

MOV N_[0b0100] INTO STATUS_BUS
MOV N_[0b0000] INTO STATUS_BUS
MOV N_[0b0100] INTO STATUS_BUS
MOV N_[0b0000] INTO STATUS_BUS
MOV N_[0b0100] INTO STATUS_BUS
MOV N_[0b0000] INTO STATUS_BUS
MOV N_[0b0100] INTO STATUS_BUS
MOV N_[0b0000] INTO STATUS_BUS

IDE_DRIVER.CheckReadLoop:
#Wait for ready

MOV N_[0b0100] INTO STATUS_BUS
MOV N_[F] INTO DATA_BUS
MOV N_[0b0000] INTO STATUS_BUS

MOV N_[0b1000] INTO STATUS_BUS
MOV N_[0b0000] INTO STATUS_BUS

MOV N_[0b1000] INTO STATUS_BUS
MOV N_[0b0000] INTO STATUS_BUS

MOV N_[0b1000] INTO STATUS_BUS
MOV N_[0b0000] INTO STATUS_BUS

MOV N_[0b1000] INTO STATUS_BUS
MOV N_[0b0000] INTO STATUS_BUS

MOV N_[0b1000] INTO STATUS_BUS
MOV N_[0b0000] INTO STATUS_BUS

MOV N_[0b1000] INTO STATUS_BUS
MOV N_[0b0000] INTO STATUS_BUS

MOV N_[0b1000] INTO STATUS_BUS
LOD DATA_BUS
STR IDE_DRIVER.Status[0]
MOV N_[0b0000] INTO STATUS_BUS
MOV N_[0b1000] INTO STATUS_BUS
LOD DATA_BUS
STR IDE_DRIVER.Status[1]
MOV N_[0b0000] INTO STATUS_BUS



#Loop until MSB of .Status[1] is 1
LOD IDE_DRIVER.Status[1]
ADD N_[8]
GETCARR ACC
JMP IDE_DRIVER.CheckReadLoop

#Drive is ready, time to start reading

MOV16 IDE_DRIVER.DataPtr INTO IDE_DRIVER.RPtr4[1]

IDE_DRIVER.ReadLoop:

MOV N_[0b0100] INTO STATUS_BUS
MOV N_[8] INTO DATA_BUS
MOV N_[0b0000] INTO STATUS_BUS

MOV N_[0b1000] INTO STATUS_BUS
MOV N_[0b0000] INTO STATUS_BUS

MOV N_[0b1000] INTO STATUS_BUS
MOV N_[0b0000] INTO STATUS_BUS

MOV N_[0b1000] INTO STATUS_BUS
MOV N_[0b0000] INTO STATUS_BUS

MOV N_[0b1000] INTO STATUS_BUS
MOV N_[0b0000] INTO STATUS_BUS

#When it starts presenting data,
#take that data and put it into memory.
#Increment the memory pointer each time;
#writing sixteen bits each time through
#this loop.

INC16 IDE_DRIVER.RPtr4[1] INTO IDE_DRIVER.RPtr3[1]
INC16 IDE_DRIVER.RPtr3[1] INTO IDE_DRIVER.RPtr2[1]
INC16 IDE_DRIVER.RPtr2[1] INTO IDE_DRIVER.RPtr1[1]


MOV N_[0b1000] INTO STATUS_BUS
LOD DATA_BUS
IDE_DRIVER.RPtr1:
STR 0x0000
MOV N_[0b0000] INTO STATUS_BUS


MOV N_[0b1000] INTO STATUS_BUS
LOD DATA_BUS
IDE_DRIVER.RPtr2:
STR 0x0000
MOV N_[0b0000] INTO STATUS_BUS


MOV N_[0b1000] INTO STATUS_BUS
LOD DATA_BUS
IDE_DRIVER.RPtr3:
STR 0x0000
MOV N_[0b0000] INTO STATUS_BUS


MOV N_[0b1000] INTO STATUS_BUS
LOD DATA_BUS
IDE_DRIVER.RPtr4:
STR 0x0000
MOV N_[0b0000] INTO STATUS_BUS

INC16 IDE_DRIVER.RPtr1[1] INTO IDE_DRIVER.RPtr4[1]

#Control flow - this loop only goes around 256 times

INC8 IDE_DRIVER.LoopCount
JMPEQ8 IDE_DRIVER.LoopCount IDE_DRIVER.ZeroByte TO IDE_DRIVER.DoneReadLoop

LOD N_[0]
JMP IDE_DRIVER.ReadLoop

IDE_DRIVER.DoneReadLoop:




LOD N_[0]
JMP IDE_DRIVER.Done

#-----------------------------------------------------------------------------

IDE_DRIVER.Write:
#Tell it to start writing (0x30 to reg F)


MOV N_[0b0100] INTO STATUS_BUS
MOV N_[F] INTO DATA_BUS
MOV N_[0b0000] INTO STATUS_BUS

MOV N_[0b0100] INTO STATUS_BUS
MOV N_[0b0000] INTO STATUS_BUS
MOV N_[0b0100] INTO STATUS_BUS
MOV N_[0b0000] INTO STATUS_BUS

MOV N_[0b0100] INTO STATUS_BUS
MOV N_[3] INTO DATA_BUS
MOV N_[0b0000] INTO STATUS_BUS

MOV N_[0b0100] INTO STATUS_BUS
MOV N_[0] INTO DATA_BUS
MOV N_[0b0000] INTO STATUS_BUS

#execute

MOV N_[0b0100] INTO STATUS_BUS
MOV N_[0b0000] INTO STATUS_BUS
MOV N_[0b0100] INTO STATUS_BUS
MOV N_[0b0000] INTO STATUS_BUS
MOV N_[0b0100] INTO STATUS_BUS
MOV N_[0b0000] INTO STATUS_BUS
MOV N_[0b0100] INTO STATUS_BUS
MOV N_[0b0000] INTO STATUS_BUS



MOV16 IDE_DRIVER.DataPtr INTO IDE_DRIVER.WPtr4[1]

IDE_DRIVER.WriteLoop:

MOV N_[0b0100] INTO STATUS_BUS
MOV N_[8] INTO DATA_BUS
MOV N_[0b0000] INTO STATUS_BUS

#This code self-modifies by inserting the data pointer
#provided into the LOD instructions below, then incrementing it
#and putting the result in the other LOD instruction

INC16 IDE_DRIVER.WPtr4[1] INTO IDE_DRIVER.WPtr3[1]
INC16 IDE_DRIVER.WPtr3[1] INTO IDE_DRIVER.WPtr2[1]
INC16 IDE_DRIVER.WPtr2[1] INTO IDE_DRIVER.WPtr1[1]

MOV N_[0b0100] INTO STATUS_BUS
IDE_DRIVER.WPtr1:
LOD 0x0000
STR DATA_BUS
MOV N_[0b0000] INTO STATUS_BUS

MOV N_[0b0100] INTO STATUS_BUS
IDE_DRIVER.WPtr2:
LOD 0x0000
STR DATA_BUS
MOV N_[0b0000] INTO STATUS_BUS

MOV N_[0b0100] INTO STATUS_BUS
IDE_DRIVER.WPtr3:
LOD 0x0000
STR DATA_BUS
MOV N_[0b0000] INTO STATUS_BUS

MOV N_[0b0100] INTO STATUS_BUS
IDE_DRIVER.WPtr4:
LOD 0x0000
STR DATA_BUS
MOV N_[0b0000] INTO STATUS_BUS

INC16 IDE_DRIVER.WPtr1[1] INTO IDE_DRIVER.WPtr4[1]

#execute

MOV N_[0b0100] INTO STATUS_BUS
MOV N_[0b0000] INTO STATUS_BUS
MOV N_[0b0100] INTO STATUS_BUS
MOV N_[0b0000] INTO STATUS_BUS
MOV N_[0b0100] INTO STATUS_BUS
MOV N_[0b0000] INTO STATUS_BUS
MOV N_[0b0100] INTO STATUS_BUS
MOV N_[0b0000] INTO STATUS_BUS

#Control flow - this loop only goes around 256 times

INC8 IDE_DRIVER.LoopCount
JMPEQ8 IDE_DRIVER.LoopCount IDE_DRIVER.ZeroByte TO IDE_DRIVER.DoneWriteLoop

LOD N_[0]
JMP IDE_DRIVER.WriteLoop

IDE_DRIVER.DoneWriteLoop:

IDE_DRIVER.CheckWriteLoop:

#Check for error codes

MOV N_[0b0100] INTO STATUS_BUS
MOV N_[F] INTO DATA_BUS
MOV N_[0b0000] INTO STATUS_BUS

MOV N_[0b1000] INTO STATUS_BUS
MOV N_[0b0000] INTO STATUS_BUS

MOV N_[0b1000] INTO STATUS_BUS
MOV N_[0b0000] INTO STATUS_BUS

MOV N_[0b1000] INTO STATUS_BUS
MOV N_[0b0000] INTO STATUS_BUS

MOV N_[0b1000] INTO STATUS_BUS
MOV N_[0b0000] INTO STATUS_BUS

MOV N_[0b1000] INTO STATUS_BUS
MOV N_[0b0000] INTO STATUS_BUS

MOV N_[0b1000] INTO STATUS_BUS
MOV N_[0b0000] INTO STATUS_BUS

#execute

MOV N_[0b1000] INTO STATUS_BUS
LOD DATA_BUS
STR IDE_DRIVER.Status[0]
MOV N_[0b0000] INTO STATUS_BUS
MOV N_[0b1000] INTO STATUS_BUS
LOD DATA_BUS
STR IDE_DRIVER.Status[1]
MOV N_[0b0000] INTO STATUS_BUS

#Loop until MSB of .Status[1] is 0
LOD IDE_DRIVER.Status[1]
ADD N_[8]
GETCARR ACC
LOGNOT ACC
JMP IDE_DRIVER.CheckWriteLoop

#Check the status register one last time,
#leaving the code for the higher-level coder.

MOV N_[0b0100] INTO STATUS_BUS
MOV N_[F] INTO DATA_BUS
MOV N_[0b0000] INTO STATUS_BUS

MOV N_[0b1000] INTO STATUS_BUS
MOV N_[0b0000] INTO STATUS_BUS

MOV N_[0b1000] INTO STATUS_BUS
MOV N_[0b0000] INTO STATUS_BUS

MOV N_[0b1000] INTO STATUS_BUS
MOV N_[0b0000] INTO STATUS_BUS

MOV N_[0b1000] INTO STATUS_BUS
MOV N_[0b0000] INTO STATUS_BUS

MOV N_[0b1000] INTO STATUS_BUS
MOV N_[0b0000] INTO STATUS_BUS

MOV N_[0b1000] INTO STATUS_BUS
MOV N_[0b0000] INTO STATUS_BUS

#execute

MOV N_[0b1000] INTO STATUS_BUS
LOD DATA_BUS
STR IDE_DRIVER.Status[0]
MOV N_[0b0000] INTO STATUS_BUS
MOV N_[0b1000] INTO STATUS_BUS
LOD DATA_BUS
STR IDE_DRIVER.Status[1]
MOV N_[0b0000] INTO STATUS_BUS

IDE_DRIVER.Done:
MOV N_[F] INTO CHIP_SELECT
#Exit - this needs the return address to be supplied
LOD N_[0]
IDE_DRIVER.Exit:
JMP 0x0000


IDE_DRIVER.Cyl:		.data 4
IDE_DRIVER.ZeroToWrite:	.data 1
IDE_DRIVER.RegTable:	.data 5 0xABCDE
IDE_DRIVER.LocTable:
IDE_DRIVER.SecCount:	.data 2 0x01
IDE_DRIVER.SecNum: 	.data 2
IDE_DRIVER.Cyl23:	.data 2
IDE_DRIVER.Cyl01:	.data 2
IDE_DRIVER.Head:	.data 2 0xE0
IDE_DRIVER.DataPtr:	.data 4
IDE_DRIVER.LoopCount: 	.data 2 0x0
IDE_DRIVER.LocationLoop:	.data 1 0x0
IDE_DRIVER.Status:	.data 2
IDE_DRIVER.ZeroByte:	.data 2 0x00
