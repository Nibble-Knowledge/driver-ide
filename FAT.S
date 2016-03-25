#FAT Driver for the nibble knowledge system
#Searches the table for a file name and returns the location of that filename 
#On first entry will do the setup loop to find the program list - on subsequent entries the list location should be saved

FAT_DRIVER.Enter:

#Check if first loop (ProgListPtr = 0xFFFF) - if it is go to setup loop, otherwise skip to inner loop
JMPNE16 N_[0xFFFF] FAT_DRIVER.IndexFile TO FAT_DRIVER.FindName

######Loop until we find the first magic number - this will be the index file which lists all other files in order   #######
FAT_DRIVER.SetupLoop:

FAT_DRIVER.ProgramListPtr:
LOD 0x0000
STR FAT_DRIVER.IndexFile
#Check if we found our magic number
JMPEQ16 FAT_DRIVER.IndexFile FAT_DRIVER.MagicNumber TO FAT_DRIVER.FindName

INC16 FAT_DRIVER.ProgramListPtr[1]

LOD N_[0]
JMP FAT_DRIVER.SetupLoop


######Search through the program list until we find the given program name - count how far down the list it is ######
FAT_DRIVER.FindName:
MOV16 FAT_DRIVER.IndexFile INTO FAT_DRIVER.Offset 
INC16 FAT_DRIVER.Offset
MOV16 FAT_DRIVER.Offset INTO FAT_DRIVER.IndexSize

FAT_DRIVER.InnerLoop:
INC16 FAT_DRIVER.Offset

#If we reach end of program list without finding filename exit loop
JMPEQ16 FAT_DRIVER.Offset FAT_DRIVER.MagicNumberEnd TO FAT_DRIVER.Done

#If we the filename matches our value then the next line should be the locaiton of the file, otherwise loop again
JMPNE16 FAT_DRIVER.Offset FAT_DRIVER.FileName TO FAT_DRIVER.InnerLoop


####### Loop until we find x magic numbers where x is determined by the order in inxed file ###########

FAT_DRIVER.MagicSearch:
FAT_DRIVER.MSPtr:
LOD 0x0000
STR FAT_DRIVER.FoundLocPtr

JMPNE FAT_DRIVER.MagicNumber FAT_DRIVER.FoundLocPtr TO FAT_DRIVER.NotMag   
    INC8 FAT_DRIVER.FoundCount
    JMPEQ FAT_DRIVER.ProgCount FAT_DRIVER.FoundCount TO FAT_DRIVER.MATCH 
FAT_DRIVER.NotMag:

INC16 FAT_DRIVER.MSPtr[1]
LOD N_[0]
JMP FAT_DRIVER.MagicSearch



###### Match was found - do the end stuff - still not quite sure what this entails atm ########
FAT_DRIVER.Match:

##### End stuff     ##########
FAT_DRIVER.Done:
#Exit - this needs the return address to be supplied
LOD N_[0]
FAT_DRIVER.Exit:
JMP 0x0000




#Arbitrary - just needs to be consistent 
FAT_DRIVER.MagicNumber:     .data   4   0x40F0
FAT_DRIVER.MagicNumberEnd:  .data   4   0x4111

FAT_DRIVER.FileName:        .data   8   

FAT_DRIVER.IndexFile:       .data   4   0xFFFF   
FAT_DRIVER.IndexSize:       .data   4   
FAT_DRIVER.Offset:          .data   4   

FAT_DRIVER.ProgCount:       .data   2   0x0   
FAT_DRIVER.FoundCount:      .data   2   0x0
FAT_DRIVER.FoundLocPtr:     .data   4   0x0

FAT_DRIVER.Scratch:         .data   1024
