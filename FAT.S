#FAT Driver for the nibble knowledge system
#Searches the table for a file name and returns the location of that filename 
#On first entry will do the setup loop to find the program list - on subsequent entries the list location should be saved

FAT_DRIVER.Enter:

#Check if first loop (IndexAddr = 0xFFFF) - if it is go to setup loop, otherwise skip to inner loop
JMPNE16 N_[0xFFFF] FAT_DRIVER.IndexAddr TO FAT_DRIVER.Skip

######Loop until we find the first magic number - this will be the index file which lists all other files in order   #######
MOVADDR FAT_DRIVER.FuncReturn1 INTO FAT_DRIVER.CallIDEReturn:
LOD N_[0]
JMP FAT_DRIVER.CallIDE
FAT_DRIVER.FuncReturn1:
MOVADDR FAT_DRIVER.Scratch INTO FAT_DRIVER.Temp[1]

FAT_DRIVER.SetupLoop:
FAT_DRIVER.Temp:
LOD 0x0000
STR FAT_DRIVER.Index

JMPEQ16 FAT_DRIVER.MagicNumber FAT_DRIVER.Index TO FAT_DRIVER.FindName

INC16 FAT_DRIVER.Temp[1]

LOD N_[0]
JMP FAT_DRIVER.SetupLoop


######Search through the program list until we find the given program name - count how far down the list it is ######
FAT_DRIVER.FindName:
#Save the address of index and its size
#Not sure this works in macro?
MOVADDR FAT_DRIVER.IndexTemp[1] INTO FAT_DRIVER.IndexAddr
INC16 FAT_DRIVER.Temp[1]
LOD FAT_DRIVER.Temp[1]
STR FAT_DRIVER.IndexSize
LOD N_[0]
JMP FAT_DRIVER.IndexLoop

#If its a new load then load up the ide driver
FAT_DRIVER.Skip:
MOVADDR FAT_DRIVER.FuncReturn2 INTO FAT_DRIVER.CallIDEReturn:
LOD N_[0]
JMP FAT_DRIVER.CallIDE
FAT_DRIVER.FuncReturn2:
MOVADDR FAT_DRIVER.Scratch INTO FAT_DRIVER.IndexTemp[1]
ADD16 FAT_DRIVER.IndexTemp[1] FAT_DRIVER.IndexAddr INTO FAT_DRIVER.IndexTemp[1]

#Loop until we find the name match
FAT_DRIVER.IndexLoop:
FAT_DRIVER.IndexTemp[1]:
LOD 0x0000
STR FAT_DRIVER.FoundFile

#Increment which number program it is in the list
INC8 FAT_DRIVER.ProgCount

JMPEQ64 FAT_DRIVER.FoundFile FAT_DRIVER.FileName TO FAT_DRIVER.Match

#Increment past file name
INC64 FAT_DRIVER.Temp[1]

LOD N_[0]
JMP FAT_DRIVER.IndexLoop


####### Loop until we find x magic numbers where x is determined by the order in inxed file ###########
FAT_DRIVER.Match:
#Skip to the end of the index file
ADD16 FAT_DRIVER.IndexAddr FAT_DRIVER.IndexSize INTO FAT_DRIVER.MatchTemp[1]

#Loop until we find the nth magic number where n = ProgCount
FAT_DRIVER.MatchLoop:
FAT_DRIVER.MatchTemp:
LOD 0x0000
STR FAT_DRIVER.NewProg

JMPEQ16 FAT_DRIVER.MagicNumber FAT_DRIVER.NewProg TO FAT_DRIVER.MatchFound

INC16 FAT_DRIVER.MatchTemp[1]

LOD N_[0]
JMP FAT_DRIVER.MatchLoop

#If a match was found, check if it was the right number, otherwise increment the addr by the file size
FAT_DRIVER.MatchFound:
INC8 FAT_DRIVER.NewCount
MOVADDR FAT_DRIVER.MatchTemp[1] INTO FAT_DRIVER.FoundLocPtr
JMPEQ FAT_DRIVER.NewCount FAT_DRIVER.ProgCount TO FAT_DRIVER.Matched

#Skip past the size found in file
INC16 FAT_DRIVER.FoundLocPtr
MOV FAT_DRIVER.FoundLocPtr INTO FAT_DRIVER.SkipSize
ADD FAT_DRIVER.SkipSize FAT_DRIVER.MatchTemp[1] INTO FAT_DRIVER.MatchTemp[1]

LOD N_[0]
JMP FAT_DRIVER.MatchLoop


###### Match was found - do the end stuff - still not quite sure what this entails atm ########
FAT_DRIVER.Matched:
MOVADDR FAT_DRIVER.MatchTemp[1] INTO FAT_DRIVER.FoundLocPtr

LOD N_[0]
JMP FAT_DRIVER.Done

##### End stuff     ##########
FAT_DRIVER.Done:
#Exit - this needs the return address to be supplied
LOD N_[0]
FAT_DRIVER.Exit:
JMP 0x0000


##### CALL IDE DRIVER function			########
FAT_DRIVER.CallIDE:

MOVADDR Return INTO IDE_DRIVER.Exit[1]
MOV16 FAT_DRIVER.Cyl INTO IDE_DRIVER.Cyl
MOV N[1] INTO IDE_DRIVER.ZeroToWrite
MOV8 FAT_DRIVER.SecNum INTO IDE_DRIVER.SecNum
#Not sure this value is right will need to double check 
MOVADDR FAT_DRIVER.Scratch INTO IDE_DRIVER.DataPtr

LOD N_[0]
JMP IDE_DRIVER.Enter

Return:
NOP 0

LOD N_[0]
FAT_DRIVER.CallIDEReturn:
JMP 0x0000


########	Vars		########



#Arbitrary - just needs to be consistent 
FAT_DRIVER.MagicNumber:     .data   4   0x40F0
FAT_DRIVER.MagicNumberEnd:  .data   4   0x4111

FAT_DRIVER.Index			.data	4	
FAT_DRIVER.IndexAddr:       .data   4   0xFFFF   
FAT_DRIVER.IndexSize:       .data   4   

FAT_DRIVER.FileName:        .data   16   
FAT_DRIVER.FoundFile:		.data	16

FAT_DRIVER.ProgCount:       .data   2   0x0 

FAT_DRIVER.NewProg:			.data	4	  
FAT_DRIVER.NewCount:      	.data   2   0x0

FAT_DRIVER.FoundLocPtr:     .data   4   0x0
FAT_DRIVER.SkipSize:        .data   4   0x0

#Not sure on values of these yet
FAT_DRIVER.Cyl:				.data	4	0x0000
FAT_DRIVER.SecNum:			.data	2	0x00

FAT_DRIVER.Scratch:         .data   1024
