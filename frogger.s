#####################################################################
#
# CSC258H5S Winter 2022 Assembly Final Project
# University of Toronto, St. George
#
# Student: Qingyi Liu, 1005703311
#
# Bitmap Display Configuration:
# - Unit width in pixels: 8
# - Unit height in pixels: 8
# - Display width in pixels: 512
# - Display height in pixels: 512
# - Base Address for Display: 0x10000000 (global data)
#
# Which milestone is reached in this submission?
# (See the assignment handout for descriptions of the milestones)
# - Milestone 5 
#
# Which approved additional features have been implemented?
# (See the assignment handout for the list of additional features)
# 1. (Easy feature) Display the number of lives remaining
# 2. (Easy feature) Dynamic increase in difficulty (speed), After the third frog being placed at the top block, the speed will increase
# 3. (Easy feature) Have objects in different rows move at different speeds
# 4. (Easy feature) Add a third row in each of the water and road sections
# 5. (Easy feature) Randomize the size of the logs and cars in the scene.
# 6. (Hard feature) Make a second level that starts after the player completes the first level. Five levels in total, one level per 
# 			frog placed at the top area
#
# Any additional information that the TA needs to know:
# - Press Q to quit the game at any time (when game is quit, needs reassemble and run to restart)
# - Press R to restart the game at any time of the game
# - The game WILL auto restart once the player loose all five lives (Number of lives remaining shown at the left bottom corner)
# - The game will NOT restart automatically after level 5 being finished (i.e. all 5 frogs placed at top), press R if wish to restart
# - if keyboard input is pressed too frequently without a pause, MARS could crash... (or it's my computer's problem)
#####################################################################
#
.data
### Settings
	displayAddress: .word 0x10000000
	keyboardAddress: .word 0xffff0000
	edgeSize: .word 64
### Colors
	grassColor: .word 0xA1CD7A
	sandColor: .word 0xECE993
	waterColor: .word 0x0066CC
	roadColor: .word 0x524B3C
	frogColor: .word 0x3E7940
	carColor: .word  0xCC0000
	logColor: .word 0x994C00
	pink: .word  0xFFB6C1
### Static Background Dimensions
	startZoneStartX: .word 0
	startZoneStartY: .word 52
	startZoneLength: .word 64
	startZoneHeight: .word 12
	roadOneStartX: .word 0
	roadOneStartY: .word 46
	roadOneLength: .word 64
	roadOneHeight: .word 6
	roadTwoStartX: .word 0
	roadTwoStartY: .word 40
	roadTwoLength: .word 64
	roadTwoHeight: .word 6
	roadThreeStartX: .word 0
	roadThreeStartY: .word 34
	roadThreeLength: .word 64
	roadThreeHeight: .word 6
	safeZoneStartX: .word 0
	safeZoneStartY: .word 26
	safeZoneLength: .word 64
	safeZoneHeight: .word 8
	logOneStartX: .word 0
	logOneStartY: .word 20
	logOneLength: .word 64
	logOneHeight: .word 6
	logTwoStartX: .word 0
	logTwoStartY: .word 14
	logTwoLength: .word 64
	logTwoHeight: .word 6
	logThreeStartX: .word 0
	logThreeStartY: .word 8
	logThreeLength: .word 64
	logThreeHeight: .word 6
	endZoneStartX: .word 0
	endZoneStartY: .word 0
	endZoneLength: .word 64
	endZoneHeight: .word 8
### Oobject state info
	frogLocationXAddress: .space 4
	frogLocationRowAddress: .space 4
	isFrogOnLog: .space 4
	frogOnLogSpeed: .space 4
	frogOnLogDir: .space 4
	locationYBaseAddress: .space 40
	allRowXBaseAddress: .space 32
	allRowDirAddress: .space 32
	allRowSizeBaseAddress: .space 32
	allRowSpeedBaseAddress: .space 32
	safeZoneXBaseAddress: .space 24
	safeZoneIsUsedBaseAddress: .space 24
	numLivesRemain: .space 4
	numFrogEntered: .space 4
	


### MARCO FUNCTIONS USED FOR JAL

.macro stack_push(%reg)
	subi $sp, $sp, 4
	sw %reg, ($sp)
.end_macro 


.macro stack_pop(%reg)
	lw %reg, ($sp)
	addi $sp, $sp, 4
.end_macro 

### DRAW BASIC BACKGROUND
.text

init:
	jal initPara
	jal initObject
	jal randomSize # apply random size to cars and logs

	addi $t0, $zero, 1 # init frame counter 
main:
# Handel keyboard interruption
	lw $t8, 0xffff0000
	beq $t8, 1, keyboard_input
	
# Handel display
	addi $a0, $t0, 0 # Pass down frame counter
	jal moveObject
	jal drawScene
	jal frogCheck
	
# Sleep
	li $v0, 32
	li $a0, 32 # ~30 refreshes per second
	syscall
	
# Handel frame counter
	addi $t0, $t0, 1 # Increment frame counter
	ble $t0, 5, endMain # Frame counter range 1-4
	addi $t0, $zero, 1 # Restart frame counter
	
endMain:
	j main



### Init Helper Routines
# init parameters
initPara:
	stack_push($ra)
	stack_push($t0)
	stack_push($t1)
	stack_push($t2)
	stack_push($t3)
	
# Init numLivesRemain
	addi $t0, $zero, 5
	sw $t0, numLivesRemain
	addi $t0, $zero, 0
	sw $t0, numFrogEntered
	
# Init isFrogOnLog paras
	addi $t0, $zero, 0
	sw $t0, isFrogOnLog
	sw $t0, frogOnLogSpeed
	sw $t0, frogOnLogDir
	
# Init safeZone paras
	addi $t0, $zero, 7 # Current safe zone X
	sw $t0, safeZoneXBaseAddress
	sw $zero, safeZoneIsUsedBaseAddress
	addi $t0, $zero, 19 # Current safe zone X
	sw $t0, safeZoneXBaseAddress + 0x4
	sw $zero, safeZoneIsUsedBaseAddress + 0x4
	addi $t0, $zero, 31 # Current safe zone X
	sw $t0, safeZoneXBaseAddress + 0x8
	sw $zero, safeZoneIsUsedBaseAddress + 0x8
	addi $t0, $zero, 43 # Current safe zone X
	sw $t0, safeZoneXBaseAddress + 0xc
	sw $zero, safeZoneIsUsedBaseAddress + 0xc
	addi $t0, $zero, 55 # Current safe zone X
	sw $t0, safeZoneXBaseAddress + 0x10
	sw $zero, safeZoneIsUsedBaseAddress + 0x10
	
	
# Init locationYBaseAddress
	addi $t2, $zero, 54 # Set frog Y at each row
	sw $t2, locationYBaseAddress # locationYBaseAddress + offset
	addi $t2, $zero, 48 # Set frog Y at each row
	sw $t2, locationYBaseAddress + 0x4 # locationYBaseAddress + offset
	addi $t2, $zero, 42 # Set frog Y at each row
	sw $t2, locationYBaseAddress + 0x8 # locationYBaseAddress + offset
	addi $t2, $zero, 36 # Set frog Y at each row
	sw $t2, locationYBaseAddress + 0xc # locationYBaseAddress + offset
	addi $t2, $zero, 29 # Set frog Y at each row
	sw $t2, locationYBaseAddress + 0x10 # locationYBaseAddress + offset
	addi $t2, $zero, 22 # Set frog Y at each row
	sw $t2, locationYBaseAddress + 0x14 # locationYBaseAddress + offset
	addi $t2, $zero, 16 # Set frog Y at each row
	sw $t2, locationYBaseAddress + 0x18 # locationYBaseAddress + offset
	addi $t2, $zero, 10 # Set frog Y at each row
	sw $t2, locationYBaseAddress + 0x1c # locationYBaseAddress + offset
	addi $t2, $zero, 3 # Set frog Y at each row
	sw $t2, locationYBaseAddress + 0x20 # locationYBaseAddress + offset
	
	stack_pop($t3)
	stack_pop($t2)
	stack_pop($t1)
	stack_pop($t0)
	stack_pop($ra)
	jr $ra

# Init movable object like cars and logs
initObject:
	stack_push($ra)
	stack_push($t0)
	stack_push($t1)
	stack_push($t2)
	stack_push($t3)
	stack_push($t4)
	stack_push($t5)
	
# Init Frog
	addi $t0, $zero, 31 # Initial frog X
	addi $t1, $zero, 0 # Initial frog Row
	sw $t0, frogLocationXAddress
	sw $t1, frogLocationRowAddress
	
	addi $t2, $zero, 20 # start X for all rows object
# Row 0
	addi $t3, $zero, 2 # size of current row
	addi $t4, $zero, 2 # speed of current row
	addi $t5, $zero, 1 # dir of current row
	sw $t2, allRowXBaseAddress # store X for current row
	sw $t3, allRowSizeBaseAddress # store size for current row
	sw $t4, allRowSpeedBaseAddress # store speed for current row
	sw $t5, allRowDirAddress # store dir for current row
# Row 1
	addi $t3, $zero, 4 # size of current row
	addi $t4, $zero, 3 # speed of current row
	addi $t5, $zero, -1 # dir of current row
	sw $t2, allRowXBaseAddress + 0x4 # store X for current row
	sw $t3, allRowSizeBaseAddress + 0x4 # store size for current row
	sw $t4, allRowSpeedBaseAddress + 0x4 # store speed for current row
	sw $t5, allRowDirAddress + 0x4 # store dir for current row
# Row 2
	addi $t3, $zero, 2 # size of current row
	addi $t4, $zero, 3 # speed of current row
	addi $t5, $zero, 1 # dir of current row
	sw $t2, allRowXBaseAddress + 0x8 # store X for current row
	sw $t3, allRowSizeBaseAddress + 0x8 # store size for current row
	sw $t4, allRowSpeedBaseAddress + 0x8 # store speed for current row
	sw $t5, allRowDirAddress + 0x8 # store dir for current row
# Row 3
	addi $t3, $zero, 3 # size of current row
	addi $t4, $zero, 2 # speed of current row
	addi $t5, $zero, 1 # dir of current row
	sw $t2, allRowXBaseAddress + 0xc # store X for current row
	sw $t3, allRowSizeBaseAddress + 0xc # store size for current row
	sw $t4, allRowSpeedBaseAddress + 0xc # store speed for current row
	sw $t5, allRowDirAddress + 0xc # store dir for current row
# Row 4
	addi $t3, $zero, 4 # size of current row
	addi $t4, $zero, 3 # speed of current row
	addi $t5, $zero, -1 # dir of current row
	sw $t2, allRowXBaseAddress + 0x10 # store X for current row
	sw $t3, allRowSizeBaseAddress + 0x10 # store size for current row
	sw $t4, allRowSpeedBaseAddress + 0x10 # store speed for current row
	sw $t5, allRowDirAddress + 0x10 # store dir for current row
# Row 5
	addi $t3, $zero, 5 # size of current row
	addi $t4, $zero, 3 # speed of current row
	addi $t5, $zero, 1 # dir of current row
	sw $t2, allRowXBaseAddress + 0x14 # store X for current row
	sw $t3, allRowSizeBaseAddress + 0x14 # store size for current row
	sw $t4, allRowSpeedBaseAddress + 0x14 # store speed for current row
	sw $t5, allRowDirAddress + 0x14 # store dir for current row
	
	stack_pop($t5)
	stack_pop($t4)
	stack_pop($t3)
	stack_pop($t2)
	stack_pop($t1)
	stack_pop($t0)
	stack_pop($ra)
	jr $ra
	



### Randomize object size for all cars and logs:
randomSize:
	stack_push($ra)
	stack_push($t0)
	stack_push($t1)
	stack_push($t2)

	addi $t2, $zero, 0 # Initiate counter
randomSizeLoop:
	li $v0, 42
	li $a0, 0
	li $a1, 3
	syscall
	addi $t0, $a0, 0 # Get the random number
	lw $t1, allRowSizeBaseAddress($t2) # Load size of this row
	add $t1, $t1, $t0 # Apply random change to this size
	sw $t1, allRowSizeBaseAddress($t2) # Store the new size back
	addi $t2, $t2, 4 # Increment the address offset by 4
	ble $t2, 24, randomSizeLoop
	
	stack_pop($t2)
	stack_pop($t1)
	stack_pop($t0)
	stack_pop($ra)
	jr $ra
	
	
### Frog Location Check routines
# Checking frog location if legal
frogCheck:
	stack_push($ra)
	stack_push($t0)
	stack_push($t1)
	stack_push($t2)
	stack_push($t3)
	stack_push($t4)
	stack_push($t5)
	stack_push($t6)
	
	lw $t0, frogLocationXAddress # Get Frog X
	lw $t1, frogLocationRowAddress # Get Frog Row
	beq $t1, 0, frogCheckDone # No check for start zone
	beq $t1, 4, frogCheckDone # No check for safe zone
	beq $t1, 8, frogCheckEndZone # Branch to check for end zone
	bgt $t1, 4, frogCheckWater # Branch to water check if in row 5-7
frogCheckRoad:	
	addi $t1, $t1, -1 # Get Actual row in range 0-2
	sll $t2, $t1, 2 # Get Address offset by row index
	lw $t3, allRowXBaseAddress($t2) # Load row object X
	lw $t4, allRowSizeBaseAddress($t2) # Load row object size
	sub $t5, $t3, $t0 # Get distance diff
	abs $t5, $t5 # Get absolute value
	bgt $t5, $t4, roadCheckOnePass
	jal frogDead
	j frogCheckDone
roadCheckOnePass:
	addi $t3, $t3, 35 # Offset for Object two in this row
	addi $t6, $zero, 64
	divu $t3, $t6 # Wrap around
	mfhi $t3 # Get remainder, which is X for car 2 in this row
	sub $t5, $t3, $t0 # Get distance diff
	abs $t5, $t5 # Get absolute value
	bgt $t5, $t4, frogCheckDone
	jal frogDead
	j frogCheckDone
frogCheckWater:
	addi $t1, $t1, -2 # Get Actual row in range 3-5
	sll $t2, $t1, 2 # Get Address offset by row index
	lw $t3, allRowXBaseAddress($t2) # Load row object X
	lw $t4, allRowSizeBaseAddress($t2) # Load row object size
	sub $t5, $t3, $t0 # Get distance diff
	abs $t5, $t5 # Get absolute value
	ble $t5, $t4, frogCheckWaterAttach
	addi $t3, $t3, 35 # Offset for Object two in this row
	addi $t6, $zero, 64
	divu $t3, $t6 # Wrap around
	mfhi $t3 # Get remainder, which is X for car 2 in this row
	sub $t5, $t3, $t0 # Get distance diff
	abs $t5, $t5 # Get absolute value
	ble $t5, $t4, frogCheckWaterAttach
	jal frogDead
	j frogCheckDone
frogCheckWaterAttach:
	addi $t6, $zero, 1
	sw $t6, isFrogOnLog # Set isFrogOnLog to true
	lw $t6, allRowSpeedBaseAddress($t2) # Load row speed
	sw $t6, frogOnLogSpeed # Store row speed to frog speed
	lw $t6, allRowDirAddress($t2) # Load row dir
	sw $t6, frogOnLogDir # Store row speed to frog dir
	j frogCheckDone
frogCheckEndZone:
	addi $t6, $zero, 0
	sw $t6, isFrogOnLog # Clear isFrogOnLog
	sw $t6, frogOnLogSpeed # Clear frogOnLogSpeed
	sw $t6, frogOnLogDir # Clear frogOnLogDir
	addi $t1, $zero, 0 # Counter for safeZone address
	addi $t2, $zero, 20 # Max safeZone address offset
frogCheckEndZoneLoop:
	lw $t3, safeZoneXBaseAddress($t1) # Load X of current safeZone
	lw $t4, safeZoneIsUsedBaseAddress($t1) # Load isUsed of current safeZone
	sub $t5, $t3, $t0 # Get distance diff
	abs $t5, $t5 # Get absolute value
	ble $t5, 2, frogCheckEndZoneContact
	addi $t1, $t1, 4 # Increament address offset
	ble $t1, $t2, frogCheckEndZoneLoop
	jal frogDead
	j frogCheckDone
frogCheckEndZoneContact:
	beq $t4, 1, frogCheckEndZoneDead # If already occupied by previous frog
	addi $t6, $zero, 1
	sw $t6, safeZoneIsUsedBaseAddress($t1)
	jal frogNext
	j frogCheckDone
frogCheckEndZoneDead:
	jal frogDead
	j frogCheckDone
frogCheckDone:
	stack_pop($t6)
	stack_pop($t5)
	stack_pop($t4)
	stack_pop($t3)
	stack_pop($t2)
	stack_pop($t1)
	stack_pop($t0)
	stack_pop($ra)
	jr $ra

#safeZoneXBaseAddress: .space 24
#safeZoneIsUsedBaseAddress: .space 24

# Frog death handler
frogDead:
	stack_push($ra)
	stack_push($t0)
	
	lw $t0, numLivesRemain
	addi $t0, $t0, -1
	bgt $t0, $zero, frogDeadStoreBackLives
	# Restart the game
	stack_pop($t0)
	stack_pop($ra)
	j init
frogDeadStoreBackLives:
	sw $t0, numLivesRemain
	jal resetFrog
	
	stack_pop($t0)
	stack_pop($ra)
	jr $ra
	
# Next frog handler
frogNext:
	stack_push($ra)
	stack_push($t0)
	
	lw $t0, numFrogEntered
	addi $t0, $t0, 1 # Increment numFrogEntered by 1
	sw $t0, numFrogEntered
	bne $t0, 3, skipFasterCarAndLog
	jal fasterCarAndLog
skipFasterCarAndLog:
	jal resetFrog
	
	stack_pop($t0)
	stack_pop($ra)
	jr $ra
	
# Make cars and logs move faster
fasterCarAndLog:
	stack_push($ra)
	stack_push($t0)
	stack_push($t1)
	
	addi $t0, $zero, 0 # Initiate counter
fasterCarAndLogLoop:
	lw $t1, allRowSpeedBaseAddress($t0)
	addi $t1, $t1, -1 # Make the object move faster
	sw $t1, allRowSpeedBaseAddress($t0)
	addi  $t0, $t0, 4 # Increment the counter by 4
	ble $t0, 24, fasterCarAndLogLoop
	
	stack_pop($t1)
	stack_pop($t0)
	stack_pop($ra)
	jr $ra		
			
					
### Draw Backgroud/Object routines
# Draw Static Background
drawScene:
	stack_push($ra)
	stack_push($t0)
	stack_push($t1)

	lw $t0, frogLocationRowAddress
drawStartZone:
	# Row 0
	lw $a0, startZoneStartX
	lw $a1, startZoneStartY
	lw $a2, startZoneLength
	lw $a3, startZoneHeight
	lw $t9, grassColor
	jal drawRectangle
	jal drawLivesRemaining # draw num of lives remaining in row 0
	bne $t0, 0, drawRoadOne # Check Frog if is at current row
	jal drawFrog
drawRoadOne:
	# Row 1
	lw $a0, roadOneStartX
	lw $a1, roadOneStartY
	lw $a2, roadOneLength
	lw $a3, roadOneHeight
	lw $t9, roadColor
	jal drawRectangle
	# Draw Object at current row
	lw $a0, allRowXBaseAddress # load X for current row car
	addi $a1, $zero, 1 # load row index for current row car
	lw $a2, allRowSizeBaseAddress # load size for current row car
	lw $a3, carColor # load color for current row car
	jal drawObject
	lw $a0, allRowXBaseAddress
	addi $a0, $a0, 35
	addi $t1, $zero, 64
	divu $a0, $t1 # Wrap around
	mfhi $a0 # Get remainder
	addi $a1, $zero, 1 # load row index for current row car
	lw $a2, allRowSizeBaseAddress # load size for current row car
	lw $a3, carColor # load color for current row car
	jal drawObject
	bne $t0, 1, drawRoadTwo # Check Frog if is at current row
	jal drawFrog
drawRoadTwo: 
	# Row 2 
	lw $a0, roadTwoStartX
	lw $a1, roadTwoStartY
	lw $a2, roadTwoLength
	lw $a3, roadTwoHeight
	lw $t9, roadColor
	jal drawRectangle
	# Draw Object at current row
	lw $a0, allRowXBaseAddress + 4 # load X for current row car
	addi $a1, $zero, 2 # load row index for current row car
	lw $a2, allRowSizeBaseAddress + 4 # load size for current row car
	lw $a3, carColor # load color for current row car
	jal drawObject
	lw $a0, allRowXBaseAddress + 4
	addi $a0, $a0, 35
	addi $t1, $zero, 64
	divu $a0, $t1  # Wrap around
	mfhi $a0 # Get remainder
	addi $a1, $zero, 2 # load row index for current row car
	lw $a2, allRowSizeBaseAddress + 4 # load size for current row car
	lw $a3, carColor # load color for current row car
	jal drawObject
	bne $t0, 2, drawRoadThree # Check Frog if is at current row
	jal drawFrog
drawRoadThree: 
	# Row 3
	lw $a0, roadThreeStartX
	lw $a1, roadThreeStartY
	lw $a2, roadThreeLength
	lw $a3, roadThreeHeight
	lw $t9, roadColor
	jal drawRectangle
	# Draw Object at current row
	lw $a0, allRowXBaseAddress + 8 # load X for current row car
	addi $a1, $zero, 3 # load row index for current row car
	lw $a2, allRowSizeBaseAddress + 8 # load size for current row car
	lw $a3, carColor # load color for current row car
	jal drawObject
	lw $a0, allRowXBaseAddress + 8
	addi $a0, $a0, 35
	addi $t1, $zero, 64
	divu $a0, $t1  # Wrap around
	mfhi $a0 # Get remainder
	addi $a1, $zero, 3 # load row index for current row car
	lw $a2, allRowSizeBaseAddress + 8 # load size for current row car
	lw $a3, carColor # load color for current row car
	jal drawObject
	bne $t0, 3, drawSafeZone # Check Frog if is at current row
	jal drawFrog
drawSafeZone:
	# Row 4
	lw $a0, safeZoneStartX
	lw $a1, safeZoneStartY
	lw $a2, safeZoneLength
	lw $a3, safeZoneHeight
	lw $t9, sandColor
	jal drawRectangle
	bne $t0, 4, drawLogOne # Check Frog if is at current row
	jal drawFrog
drawLogOne:
	# Row 5
	lw $a0, logOneStartX
	lw $a1, logOneStartY
	lw $a2, logOneLength
	lw $a3, logOneHeight
	lw $t9, waterColor
	jal drawRectangle
	# Draw Object at current row
	lw $a0, allRowXBaseAddress + 12 # load X for current row car
	addi $a1, $zero, 5 # load row index for current row car
	lw $a2, allRowSizeBaseAddress + 12 # load size for current row car
	lw $a3, logColor # load color for current row car
	jal drawObject
	lw $a0, allRowXBaseAddress + 12
	addi $a0, $a0, 35
	addi $t1, $zero, 64
	divu $a0, $t1  # Wrap around
	mfhi $a0 # Get remainder
	addi $a1, $zero, 5 # load row index for current row car
	lw $a2, allRowSizeBaseAddress + 12 # load size for current row car
	lw $a3, logColor # load color for current row car
	jal drawObject
	bne $t0, 5, drawLogTwo # Check Frog if is at current row
	jal drawFrog
drawLogTwo:
	# Row 6
	lw $a0, logTwoStartX
	lw $a1, logTwoStartY
	lw $a2, logTwoLength
	lw $a3, logTwoHeight
	lw $t9, waterColor
	jal drawRectangle
	# Draw Object at current row
	lw $a0, allRowXBaseAddress + 16 # load X for current row car
	addi $a1, $zero, 6 # load row index for current row car
	lw $a2, allRowSizeBaseAddress + 16 # load size for current row car
	lw $a3, logColor # load color for current row car
	jal drawObject
	lw $a0, allRowXBaseAddress + 16
	addi $a0, $a0, 35
	addi $t1, $zero, 64
	divu $a0, $t1  # Wrap around
	mfhi $a0 # Get remainder
	addi $a1, $zero, 6 # load row index for current row car
	lw $a2, allRowSizeBaseAddress + 16 # load size for current row car
	lw $a3, logColor # load color for current row car
	jal drawObject
	bne $t0, 6, drawLogThree # Check Frog if is at current row
	jal drawFrog
drawLogThree:
	# Row 7
	lw $a0, logThreeStartX
	lw $a1, logThreeStartY
	lw $a2, logThreeLength
	lw $a3, logThreeHeight
	lw $t9, waterColor
	jal drawRectangle
	# Draw Object at current row
	lw $a0, allRowXBaseAddress + 20 # load X for current row car
	addi $a1, $zero, 7 # load row index for current row car
	lw $a2, allRowSizeBaseAddress + 20 # load size for current row car
	lw $a3, logColor # load color for current row car
	jal drawObject
	lw $a0, allRowXBaseAddress + 20
	addi $a0, $a0, 35
	addi $t1, $zero, 64
	divu $a0, $t1  # Wrap around
	mfhi $a0 # Get remainder
	addi $a1, $zero, 7 # load row index for current row car
	lw $a2, allRowSizeBaseAddress + 20 # load size for current row car
	lw $a3, logColor # load color for current row car
	jal drawObject
	bne $t0, 7, drawEndZone # Check Frog if is at current row
	jal drawFrog
drawEndZone:
	# Row 8
	jal drawEndZoneBlock
	jal drawAllStaticFrog
	bne $t0, 8, drawSceneEnd # Check Frog if is at current row
	jal drawFrog
drawSceneEnd:	

	stack_pop($t1)
	stack_pop($t0)
	stack_pop($ra)
	jr $ra
	


# Draw the block at the top of the screen for end zone
drawEndZoneBlock:
	stack_push($ra)
	stack_push($t0)
	stack_push($t1)

	# Top Block
	addi $a0, $zero, 0
	addi $a1, $zero, 0
	addi $a2, $zero, 64
	addi $a3, $zero, 2
	lw $t9, grassColor
	jal drawRectangle
	# Left Block
	addi $a0, $zero, 0
	addi $a1, $zero, 2
	addi $a2, $zero, 5
	addi $a3, $zero, 6
	lw $t9, grassColor
	jal drawRectangle
	lw $a0, safeZoneXBaseAddress
	addi $a0, $a0, -2
	addi $a1, $zero, 2
	addi $a2, $zero, 5
	addi $a3, $zero, 6
	lw $t9, sandColor
	jal drawRectangle
	# Block 1
	addi $a0, $zero, 10
	addi $a1, $zero, 2
	addi $a2, $zero, 7
	addi $a3, $zero, 6
	lw $t9, grassColor
	jal drawRectangle
	lw $a0, safeZoneXBaseAddress + 4
	addi $a0, $a0, -2
	addi $a1, $zero, 2
	addi $a2, $zero, 5
	addi $a3, $zero, 6
	lw $t9, sandColor
	jal drawRectangle
	# Block 2
	addi $a0, $zero, 22
	addi $a1, $zero, 2
	addi $a2, $zero, 7
	addi $a3, $zero, 6
	lw $t9, grassColor
	jal drawRectangle
	lw $a0, safeZoneXBaseAddress + 8
	addi $a0, $a0, -2
	addi $a1, $zero, 2
	addi $a2, $zero, 5
	addi $a3, $zero, 6
	lw $t9, sandColor
	jal drawRectangle
	# Block 3
	addi $a0, $zero, 34
	addi $a1, $zero, 2
	addi $a2, $zero, 7
	addi $a3, $zero, 6
	lw $t9, grassColor
	jal drawRectangle
	lw $a0, safeZoneXBaseAddress + 12
	addi $a0, $a0, -2
	addi $a1, $zero, 2
	addi $a2, $zero, 5
	addi $a3, $zero, 6
	lw $t9, sandColor
	jal drawRectangle
	# Block 4
	addi $a0, $zero, 46
	addi $a1, $zero, 2
	addi $a2, $zero, 7
	addi $a3, $zero, 6
	lw $t9, grassColor
	jal drawRectangle
	lw $a0, safeZoneXBaseAddress + 16
	addi $a0, $a0, -2
	addi $a1, $zero, 2
	addi $a2, $zero, 5
	addi $a3, $zero, 6
	lw $t9, sandColor
	jal drawRectangle
	# Right Block
	addi $a0, $zero, 58
	addi $a1, $zero, 2
	addi $a2, $zero, 6
	addi $a3, $zero, 6
	lw $t9, grassColor
	jal drawRectangle
	
	stack_pop($t1)
	stack_pop($t0)
	stack_pop($ra)
	jr $ra



# Draw Frog
drawFrog:
	stack_push($ra)
	stack_push($t0)
	stack_push($t1)
	stack_push($t2)

	lw $t0, frogLocationXAddress # Get frog X
	lw $t1, frogLocationRowAddress # Get frog Y
	lw $t2, locationYBaseAddress
	sll $t1, $t1, 2 # times 4 to get actual address offset
	lw $t2, locationYBaseAddress($t1) # Get actual Y
	addi $t1, $t2, 0 # Move t2 to t1
	lw $t2, frogColor # Get frog color
	addi $a0, $t0, 0
	addi $a1, $t1, 0
	addi $a2, $t2, 0
	jal paint
	addi $a0, $t0, 1
	addi $a1, $t1, 0
	jal paint
	addi $a0, $t0, -1
	addi $a1, $t1, 0
	jal paint
	addi $a0, $t0, 0
	addi $a1, $t1, 1
	jal paint
	addi $a0, $t0, 0
	addi $a1, $t1, 2
	jal paint
	addi $a0, $t0, -1
	addi $a1, $t1, -1
	jal paint
	addi $a0, $t0, 1
	addi $a1, $t1, -1
	jal paint
	addi $a0, $t0, -1
	addi $a1, $t1, 2
	jal paint
	addi $a0, $t0, 1
	addi $a1, $t1, 2
	jal paint

	stack_pop($t2)
	stack_pop($t1)
	stack_pop($t0)
	stack_pop($ra)
	jr $ra
	

	
# Draw All Static Frog in end Zone	
drawAllStaticFrog:	
	stack_push($ra)
	stack_push($t0)
	stack_push($t1)
	stack_push($t2)
	stack_push($t3)
	
	addi $t2, $zero, 0 # counter
	addi $t3, $zero, 20 # Max address offset
drawAllStaticFrogLoop:
	lw $t0, safeZoneXBaseAddress($t2)
	lw $t1, safeZoneIsUsedBaseAddress($t2)
	beq $t1, 0, drawAllStaticFrogLoopSkip # Skip if not isUsed
	addi $a0, $t0, 0 # Pass down X
	addi $a1, $zero, 3 # pass down Y
	lw $a2, frogColor # pass down frog color
	jal drawStaticFrog
drawAllStaticFrogLoopSkip:
	addi $t2, $t2, 4 # Increment counter by 4
	ble $t2, $t3, drawAllStaticFrogLoop # Loop back if within address range
	
	stack_pop($t3)
	stack_pop($t2)
	stack_pop($t1)
	stack_pop($t0)
	stack_pop($ra)
	jr $ra

	
	
		
# Draw number of remaining lives
drawLivesRemaining:	
	stack_push($ra)
	stack_push($t0)
	stack_push($t1)
	stack_push($t2)
	stack_push($t3)
	
	lw $t0, numLivesRemain # Load num of lives 
	addi $t1, $zero, 2 # Init X
	addi $t2, $zero, 60 # Init Y
	addi $t3, $zero, 0 # Counter
drawLivesRemainingLoop:
	bge $t3, $t0, drawLivesRemainingEnd
	addi $a0, $t1, 0 # Pass down X
	addi $a1, $t2, 0 # Pass down Y
	lw $a2, pink # Color
	jal drawStaticFrog
	addi $t1, $t1, 4 # Increment X by 4 to draw next
	addi $t3, $t3, 1 # Increment counter
	j drawLivesRemainingLoop
drawLivesRemainingEnd:	
	stack_pop($t3)
	stack_pop($t2)
	stack_pop($t1)
	stack_pop($t0)
	stack_pop($ra)
	jr $ra
	
	
	
				
						
# Draw Static Frog in end Zone
drawStaticFrog:
	stack_push($ra)
	stack_push($t0)
	stack_push($t1)
	stack_push($t2)

	addi $t0, $a0, 0 # Pass in frog X
	addi $t1, $a1, 0 # Pass in frog Y
	addi $t2, $a2, 0 # Pass in frog color
	addi $a0, $t0, 0
	addi $a1, $t1, 0
	addi $a2, $t2, 0
	jal paint
	addi $a0, $t0, 1
	addi $a1, $t1, 0
	jal paint
	addi $a0, $t0, -1
	addi $a1, $t1, 0
	jal paint
	addi $a0, $t0, 0
	addi $a1, $t1, 1
	jal paint
	addi $a0, $t0, 0
	addi $a1, $t1, 2
	jal paint
	addi $a0, $t0, -1
	addi $a1, $t1, -1
	jal paint
	addi $a0, $t0, 1
	addi $a1, $t1, -1
	jal paint
	addi $a0, $t0, -1
	addi $a1, $t1, 2
	jal paint
	addi $a0, $t0, 1
	addi $a1, $t1, 2
	jal paint

	stack_pop($t2)
	stack_pop($t1)
	stack_pop($t0)
	stack_pop($ra)
	jr $ra
		
# Move frog
moveFrog:
	stack_push($ra)
	stack_push($t0)
	stack_push($t1)
	stack_push($t2)
	stack_push($t3)
	
	addi $t0, $a0, 0 # Pass in X offset
	addi $t1, $a1, 0 # Pass in Y offset
	lw $t2, frogLocationXAddress # Get frog X
	lw $t3, frogLocationRowAddress # Get frog Y ROW
	add $t2, $t2, $t0 # Get new X
	add $t3, $t3, $t1 # Get new Y
	bgt $t2, 61, End # Check boundary
	bgt $t3, 8, End # Check boundary
	blt $t2, 2, End # Check boundary
	blt $t3, 0, End # Check boundary
	sw $t2, frogLocationXAddress # Store new frog X
	sw $t3, frogLocationRowAddress # Store new frog Y
End:
	stack_pop($t3)
	stack_pop($t2)
	stack_pop($t1)
	stack_pop($t0)
	stack_pop($ra)
	jr $ra



# Reset frog
resetFrog:
	stack_push($ra)
	stack_push($t0)
	stack_push($t1)

	addi $t0, $zero, 31 # Initial frog X
	addi $t1, $zero, 0 # Initial frog Y
	sw $t0, frogLocationXAddress
	sw $t1, frogLocationRowAddress
	sw $zero, isFrogOnLog # Set frog not on log
	sw $zero, frogOnLogSpeed # Set frog speed to zero
	sw $zero, frogOnLogDir # Set frog dir to zero

	stack_pop($t1)
	stack_pop($t0)
	stack_pop($ra)
	jr $ra




# Draw Movable object
drawObject:
	stack_push($ra)
	stack_push($t0)
	stack_push($t1)
	stack_push($t2)
	stack_push($t3)
	stack_push($t4)
	stack_push($t5)
	stack_push($t6)
	stack_push($t7)
	
	addi $t0, $a0, 0 # Pass in X location
	addi $t1, $a1, 0 # Pass in Row location
	addi $t2, $a2, 0 # Pass in size
	addi $t3, $a3, 0 # Pass in color
	sll $t1, $t1, 2 # Get actual addr offset
	lw $t1, locationYBaseAddress($t1) # Get actual Y
	addi $t5, $zero, -1 # Counter for Outter
drawObjectOuter:
	add $t7, $t1, $t5 # newY
	addi $t4, $zero, 0 # Counter for inner
drawObjectInner:
	add $t6, $t0, $t4 # newX right move
	ble $t6, 64, drawObjectPaintRight # Boundary check for X-dimension
	sub $t6, $t6, 64 # newX after passing the edge
drawObjectPaintRight:
	addi $a0, $t6, 0 # Pass down newX
	addi $a1, $t7, 0 # Pass down newY
	addi $a2, $a3, 0 # Pass down color
	jal paint
	sub $t6, $t0, $t4 # newX left move
	bge $t6, 0, drawObjectPaintLeft # Boundary check for X-dimension
	add $t6, $t6, 64 # newX after passing the edge
drawObjectPaintLeft:
	addi $a0, $t6, 0 # Pass down newX
	addi $a1, $t7, 0 # Pass down newY
	addi $a2, $a3, 0 # Pass down color
	jal paint
	addi $t4, $t4, 1 # Increment counter inner
	ble $t4, $t2, drawObjectInner # Repeat if less than size
	addi $t5, $t5, 1 # Increment counter Outter
	ble $t5, 2, drawObjectOuter # Repeat if less than size

	stack_pop($t7)
	stack_pop($t6)
	stack_pop($t5)
	stack_pop($t4)
	stack_pop($t3)
	stack_pop($t2)
	stack_pop($t1)
	stack_pop($t0)
	stack_pop($ra)
	jr $ra



# Calculate Object movement, speed, and size dynamically
moveObject:
	stack_push($ra)
	stack_push($t0)
	stack_push($t1)
	stack_push($t2)
	stack_push($t3)
	stack_push($t4)
	stack_push($t5)
	stack_push($t6)
	stack_push($t7)
	
	addi $t0, $a0, 0 # Pass in Frame counter
	addi $t1, $zero, 0 # Loop counter and address offset
	addi $t2, $zero, 24 # Number of loop iterations since there are 6 rows
	addi $t7, $zero, 63 # UpperBond
moveObjectLoop:
	lw $t3, allRowXBaseAddress($t1) # Load current row X
	lw $t4, allRowSpeedBaseAddress($t1) # Load current row speed
	lw $t5, allRowDirAddress($t1) # Load current row dir
	# Check wether move
	divu $t0, $t4 # Frame counter % speed
	mfhi $t6 # Get remainder
	bne $t6, $zero, moveObjectDone
	# Do a move 
	add $t3, $t3, $t5 # Current row new X based on dir
	ble $t3, $zero, moveObjectChangeToEnd
	bge $t3, $t7, moveObjectChangeToFirst
	sw $t3, allRowXBaseAddress($t1)
	j moveObjectDone
moveObjectChangeToEnd:
	addi $t3, $zero, 63
	sw $t3, allRowXBaseAddress($t1)
	j moveObjectDone
moveObjectChangeToFirst:
	addi $t3, $zero, 0
	sw $t3, allRowXBaseAddress($t1)
	j moveObjectDone
moveObjectDone:	
	addi $t1, $t1, 4 # Increment loop counter = address offset
	ble $t1, $t2, moveObjectLoop
	
	# Check frog move
	addi $a0, $t0, 0 # Pass down frame counter
	jal frogOnLogMove
	stack_pop($t7)
	stack_pop($t6)
	stack_pop($t5)
	stack_pop($t4)
	stack_pop($t3)
	stack_pop($t2)
	stack_pop($t1)
	stack_pop($t0)
	stack_pop($ra)
	jr $ra



# Move frog along with a log if the frog is on a log
frogOnLogMove:
	stack_push($ra)
	stack_push($t0)
	stack_push($t1)
	stack_push($t2)
	stack_push($t3)
	stack_push($t4)
	stack_push($t5)
	
	addi $t0, $a0, 0 # Pass in frame counter
	lw $t1, isFrogOnLog
	beq $t1, 0, frogOnLogMoveEnd
	lw $t2, frogOnLogSpeed
	lw $t3, frogOnLogDir
	lw $t5, frogLocationXAddress
	# Check wether move frog based on frame counter
	divu $t0, $t2 # Frame counter % speed
	mfhi $t4 # Get remainder
	bne $t4, $zero, frogOnLogMoveEnd
	# Make a move 
	add $t5, $t5, $t3 # new X based on dir
	# Check if the move will cause frog move out of boundary, if out of bound the frog dead
	bgt $t5, 61, frogOnLogMoveDead # Check right bound
	blt $t5, 2, frogOnLogMoveDead # Check left bound
	sw $t5, frogLocationXAddress
	j frogOnLogMoveEnd
frogOnLogMoveDead:
	jal frogDead	
frogOnLogMoveEnd:
	stack_pop($t5)
	stack_pop($t4)
	stack_pop($t3)
	stack_pop($t2)
	stack_pop($t1)
	stack_pop($t0)
	stack_pop($ra)
	jr $ra

### Helper routines
# Monitor keyboard_input
keyboard_input:
	lw $t5, 0xffff0004
	beq $t5, 0x61, respond_to_A
	beq $t5, 0x77, respond_to_W
	beq $t5, 0x73, respond_to_S
	beq $t5, 0x64, respond_to_D
	beq $t5, 0x71, respond_to_Q
	beq $t5, 0x72, respond_to_R
	j main

respond_to_A:
	addi $a0, $zero, -1 # X offset
	addi $a1, $zero, 0 # Y offset
	jal moveFrog	
	j main
respond_to_W:
	addi $a0, $zero, 0 # X offset
	addi $a1, $zero, 1 # Y offset
	jal moveFrog	
	j main
respond_to_S:
	addi $a0, $zero, 0 # X offset
	addi $a1, $zero, -1 # Y offset
	jal moveFrog	
	j main
respond_to_D:
	addi $a0, $zero, 1 # X offset
	addi $a1, $zero, 0 # Y offset
	jal moveFrog	
	j main
respond_to_R:
	j init	
respond_to_Q:
	j Exit


# Draw rectangle from X,Y location with a specific color
drawRectangle:
	stack_push($ra)
	stack_push($t0)
	stack_push($t1)
	stack_push($t2)
	stack_push($t3)
	stack_push($t4)
	stack_push($t5)
	stack_push($t6)

	addi $t0, $a0, 0 # Pass in starting X location
	addi $t1, $a1, 0 # Pass in starting Y location
	addi $t2, $a2, 0 # Pass in length in X-dimension
	addi $t3, $a3, 0 # Pass in height in Y-dimension
	addi $t4, $t9, 0 # Pass in Color
	addi $t5, $zero, 0 # Counter for Y
	addi $t6, $zero, 0 # Counter for X
drawRectangleOuter:
	# Outer Loop for Y
	j drawRectangleInner
drawRectangleReturnInner:
	addi $t5, $t5, 1 # Increment Counter
	bne $t5, $t3, drawRectangleOuter
	addi $t5, $zero, 0 # Reset counter for Y
	j drawRectangleReturnOuter
drawRectangleInner:
	# Inner Loop for X
	add $a0, $t0, $t6 # Calculate X location
	add $a1, $t1, $t5 # Calculate Y location
	addi $a2, $t4, 0 
	jal paint # Call paint
	addi $t6, $t6, 1 # Increment Counter
	bne $t6, $t2, drawRectangleInner
	addi $t6, $zero, 0 # Reset counter for X
	j drawRectangleReturnInner

drawRectangleReturnOuter:
	stack_pop($t6)
	stack_pop($t5)
	stack_pop($t4)
	stack_pop($t3)
	stack_pop($t2)
	stack_pop($t1)
	stack_pop($t0)
	stack_pop($ra)
	jr $ra


# paint a color at given location
paint:
	stack_push($ra)
	stack_push($t0)
	stack_push($t1)

	addi $t0, $a0, 0 # Pass in X
	lw $t1, displayAddress # Load base address
	sll $t0, $a1, 6 # Y*64
	add $t0, $t0, $a0 # Sum Y*64 and X
	sll $t0, $t0, 2 # *4 to get memory address offset
	add $t1, $t1, $t0 # Get final address
	sw $a2, 0($t1) # paint the color
	
	stack_pop($t1)
	stack_pop($t0)
	stack_pop($ra)
	jr $ra
	







	
Exit:
	li $v0, 10 # terminate the program gracefully
	syscall