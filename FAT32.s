#FAT32 is split into 3 main sections:
#	Boot record
#	File allocation table
#	directory and data area
#Info from: http://wiki.osdev.org/FAT32

############		Extract values from BPB			############
#total_sectors = (fat_boot->total_sectors_16 == 0)? fat_boot->total_sectors_32 : fat_boot->total_sectors_16;
MOV FAT32.total_sec_32 INTO total_secs

#fat_size = (fat_boot->table_size_16 == 0)? fat_boot_ext_32->table_size_16 : fat_boot->table_size_16;
MOV FAT32.sec_p_table_32 INTO fat_size

#(root_entry_cnt * 32) + (bytes_p_sec - 1) / bytes_p_sec = (0) + 511 / 512 round up = 1
MOV N_[1] INTO root_dir_secs

#first_data_sector  = FAT32.reserved_cnt + (FAT32.table_cnt * fat_size) + root_dir_secs
ADD first_data_sec FAT32.reserved_cnt INTO first_data_sec
ADD first_data_sec root_dir_secs INTO first_data_sec
MOV FAT32.table_cnt INTO temp8[6]
MOV32 temp8 INTO Mult32_Op1
MOV32 fat_size INTO Mult32_Op2
MOVADDR Return1 INTO Mult32_RetAddr[1]
LOD N_[0]
JMP Mult8_SignedEntry
Return1:
NOP 0
ADD first_data_sec Mult32_Ans INTO first_data_Sec

#first_fat_sector = fat_boot->reserved_sector_count
MOV FAT32.reserved_cnt INTO first_fat_sec

#data_secs = total_sectors - (fat_boot->reserved_sector_count + (fat_boot->table_count * fat_size) + root_dir_sectors)
MOV FAT32.table_cnt INTO temp8[6]
MOV32 temp8 INTO Mult32_Op1
MOV32 fat_size INTO Mult32_Op2
MOVADDR Return2 INTO Mult32_RetAddr[1]
LOD N_[0]
JMP Mult8_SignedEntry
Return2:
NOP 0
MOV Mult32_Ans INTO data_secs
ADD data_secs Mult32_Ans INTO data_secs
ADD data_secs FAT32.reserved_sec INTO data_secs
ADD data_secs root_dir_secs INTO data_secs
SUB total_secs data_secs INTO data_secs

total_clusters = data_sectors / fat_boot->sectors_per_cluster;
MOV total_secs INTO total_clusts


############			Reading Directories			############
ReadStart:

#first_root_dir_sector = first_data_sector - root_dir_sectors;
SUB	first_data_sec root_dir_secs INTO first_root_dir_sec

#root_cluster_32 = extBS_32->root_cluster;
MOV FAT32.root_clust INTO root_cluster_32

#first_sector_of_cluster = ((cluster - 2) * fat_boot->sectors_per_cluster) + first_data_sector;
#Not sure what cluster this referes to yet
MOV N_[0] INTO temp8
SUB cluster N_[2] INTO temp8
MOV FAT32.sec_p_clust INTO temp8_2
MOV32 temp8 INTO Mult32_Op1
MOV32 temp8_2 INTO Mult32_Op2
MOVADDR Return3 INTO Mult32_RetAddr[1]
LOD N_[0]
JMP Mult8_SignedEntry
Return3:
NOP 0
MOV Mult32_Ans INTO first_sec_of_clust
ADD first_sec_of_clust first_data_sec INTO first_sec_of_clust

#1.If the first byte of the entry is equal to 0 then there are no more files/directories in this directory. Yes, goto 2. No, finish.
#2.If the first byte of the entry is equal to 0xE5 then the entry is unused. Yes, goto number 3. No, goto number 9
#3.Is this entry a long file name entry? If the 11'th byte of the entry equals 0x0F, then it is a long file name entry. Otherwise, it is not. Yes, goto number 4. No, goto number 5.
#4.Read the portion of the long filename into a temporary buffer. Goto 9.
#5.Parse the data for this entry using the table from further up on this page. It would be a good idea to save the data for later. Possibly in a virtual file system structure. goto number 7
#6.s there a long file name in the temporary buffer? Yes, goto number 8. No, goto 9
#7.Apply the long file name to the entry that you just read and clear the temporary buffer. goto number 9
#8.Increment pointers and/or counters and check the next entry. (goto number 1)
#9.Doesnt actually say...

#Think i need to set up a pointer or something for thispart, not sure 
#1. if (firstbyte == 0) no more files
MOV first_sec_of_clust[1] INTO temp2 
JMPEQ  temp2 N_[0] TO Finish

#2. 
JMPEQ temp2 long_check TO Step9

#3.
JMPNEQ first_sec_of_clust[11] 0x0F TO Step5

#4.
#Read long portion in to buffer
LOD N_[0]
JMP Step9

#5.
Step5:
#Parse data using data table

#6.
#check temp buf for long name

#7.




Step9:

Finish:


#Following cluster chains:
#1.Extract the value from the FAT for the _current_ cluster. (Use the previous section on the File Allocation Table for details on how exactly to extract the value.) goto number 2
#2.Is this cluster marked as the last cluster in the chain? (again, see the above section for more details) Yes, goto number 4. No, goto number 3
#3.Read the cluster represented by the extracted value and return for more directory parsing.
#4.The end of the cluster chain has been found. Our work here is finished.

###########		Declarations 		############
#Boot Record
#BPB(BIOS PARAM BLOCK)
#OFFSET		SIZE				(IN BYTES)
#0			3 		EB 3C 90
#3			8 		29 3A 63 7E 2D 49 48 43
#11			2		# BYTES PER SECTOR
#13			1		# SECTORS PER CLUSTER
#14			2		# RESERVED SECTORS
#16			1		# OF FAT's (OFTEN 2)
#17			2		# OF DIRECTORY ENTRIES
#19			2		TOTAL SECTORS IN LOGICAL VOLUME
#21			1		MEDIA DISCRIPTOR TYPE
#22			2		# SECTORS PER FAT
#24			2		# SECTORS PER TRACK
#26			2		# HEADS 
#28			4		# HIDDEN SECTORS
#32			4		LARGE AMOUNT OF SECTOR ON MEDIA (SET IF > 65535 SECTORS IN VOLUME)
#36			4		# SECTORS PER FAT
#40			2		FLAGS
#42			2		FAT VERSION NUMBER
#44			4		CLUSTER # OF ROOT DIR
#48			2		SECTOR # OF FSINFO STRUCT
#50			2		SECTOR NUMBER OF BACKUP BOOT SECTOR
#52			12		RESERVED. WHEN VOLUME FORMATTED SHOULD BE 0
#64			1		DRIVE #
#65			1		RESERVED		
#66			1		SIGNATURE(0x28 OR 0x29)
#67			4		VOLUMEID 'SERIAL' NUMBER
#71			11		VOLUME LABEL STRING - PADDED WITH SPACES
#82			8		ALWAYS "FAT32   "
#90			420		BOOT CODE
#510		2		0xAA55 BOOTABLE PARTITION SIG

FAT32.bootjmp			.data	6	0xEB3C90
FAT32.oem_name			.data	16	0x293A637E2D494843
FAT32.bytes_p_sec		.data	4	512 #(one of 512,1024,2048, or 4096)
FAT32.sec_p_clust		.data	2	1 	#(one of 1,2,4,8,16,32,64,128)
FAT32.reserved_sec		.data	4	32
FAT32.table_cnt			.data	2	2
FAT32.root_entry_cnt	.data	4	0
FAT32.total_sec_16		.data	4	0
FAT32.media_type		.data	2	0xF8
FAT32.sec_p_table_16	.data	4	0
FAT32.sec_p_track		.data	4	12	#(Sectors per track for interrupt 0x13)
FAT32.head_cnt			.data	4	2	#(# heads for interupt 0x13)
FAT32.hidden_sec_cnt	.data	8	0	#(0 if not partioned, otherwise only relevent for interrupt 0x13)
FAT32.total_sec_32		.data	8		#(Must be non 0)

FAT32.sec_p_table_32	.data	8		#(FAT32 32-bit count of secs operated by one fat)
FAT32.flags				.data	4		#(0-3 zero-based num of active fat 4-6 reserved 7 1 8-15 reserved)
FAT32.fat_version		.data	4		#(version # of fat32 volume)
FAT32.root_clust		.data	8	2
FAT32.fat_info			.data	4	1
FAT32.backup_bs_sec		.data	4	6
FAT32.reserved_0		.data	24	
FAT32.drive_num			.data	2	0x80
FAT32.reserved_1		.data	2	0
FAT32.boot_sig			.data	2	0x29
FAT32.volume_id			.data	8	#(usually generated by combined current date+time into 32 bits)
FAT32.volume_label		.data	22	#(matches 11-byte volume label recorded in root dir
FAT32.fat_label			.ascii		"FAT32   "   


#File Allocation Table
#Only uses 28 of 32 bits, top 4 are off limits

fat_offset				.data	8
fat_sector				.data	8
ent_offset				.data 	8

table_value				.data	8


total_secs				.data	8
fat_size				.data	8
root_dir_secs			.data	8
first_data_sec			.data	8
first_fat_sec			.data	8
data_secs				.data	8
total_clusts			.data	8
fat_type 				.data	8	0xFAT32

#Reading directories
first_root_dir_sec		.data	8
root_clust_32			.data	8
first_sec_of_clust		.data	8

long_check				.data	2	0xE5

#Directory and Data area
#OFFSET		LENGTH	(IN BYTES)
#0			11		FIRST 8 CHARS ARE FILE NAME, LAST 3 EXTENSION
#11			1		ATTRIBUTES
#12			1		RESERVED
#13			1		CREATION TIME IN TENTHS OF A SECOND
#14			2		TIME FILE CREATED - HOUR 5 BITS, MIN 6 BITS, SEC 5 BITS
#16			2		DATE CREATED - YEAR 7 BITS, MONTH 4 BITS, DAY 5 BITS
#18			2		LAST ACCESSED DATE (SAME FORMAT AS DATE CREATED)
#20			2		HIGH 16 BITS OF ENTRYS FIRST CLUSTER NUMBER
#22			2		LAST MODIFICATION TIME (SAME FORMAT AS TIME)
#24			2		LAST MOD DATE (SAME AS DATE)
#26			2		LOW 16 BITS ENTRYS FIRST CLUSTER NUMBER
#28			4		SIZE OF FILE IN BYTES

DIR.name				.data	22
DIR.attr				.data	2
DIR.res					.data	2
DIR.tenth_sec			.data	2
DIR.crt_time			.data	4
DIR.crt_date			.data	4
DIR.accessed			.data	4
DIR.first_clus_hi		.data	4
DIR.last_mod_time		.data	4
DIR.last_mod_date		.data	4
DIR.first_clus_low		.data	4
DIR.size				.data	8

attr.read_only			.data	2	0x01
attr.hidden				.data	2	0x02
attr.system_file		.data	2	0x04	
attr.volume_label		.data	2	0x08
attr.subdirectory		.data	2	0x10
attr.archive			.data	2	0x20

#Temporary values
temp2					.data	2
temp4					.data 	4
temp8					.data	8
temp8_2					.data	8


