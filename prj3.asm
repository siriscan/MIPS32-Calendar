#s0 = year, s1 = month, s2 = day, s3 = hour, s4 = minute, s5 = second
#s6 = AM/PM, s7 = Leap Year, t8 = Number of days in Month, t9 = First day of month

#Seth Iris Canonigo
#Project 3 for CMPE 221

	.data
newline:	.asciiz	"\n"
space:	.asciiz	" "
colon:	.asciiz	":"

m1:	.asciiz	"January"
m2:	.asciiz	"Febuary"
m3:	.asciiz	"March"
m4:	.asciiz	"April"
m5:	.asciiz	"May"
m6:	.asciiz	"June"
m7:	.asciiz	"July"
m8:	.asciiz	"August"
m9:	.asciiz	"September"
m10:	.asciiz	"October"
m11:	.asciiz	"November"
m12:	.asciiz	"December"
monthNames:	.word	m1,m2,m3,m4,m5,m6,m7,m8,m9,m10,m11,m12
ampm:	.asciiz	"AM"
	.asciiz	"PM"

days_normal:	.byte	31,28,31,30,31,30,31,31,30,31,30,31
days_leap:	.byte	31,29,31,30,31,30,31,31,30,31,30,31

	.text
	.globl main

# Perform the date_time syscall to get current date
getDate:
	syscall	$date_time
	srl	$s0,$v1,9         # Extract year into $s0
	andi	$s0,$s0,0x7FFFFF # Isolate year
	srl	$s1,$v1,5         # Extract month into $s1
	andi	$s1,$s1,0xF      # Isolate month
	andi	$s2,$v1,0x1F     # Extract day into $s2 (Isolate day)

	# Extract hour (5 bits)
	srl	$s3,$v0,27      # Shift right to align hour bits to the least significant bits
	
	# Extract minute (6 bits)
	sll	$s4,$v0,5       # Shift left to remove hour bits
	srl	$s4,$s4,26      # Shift right to align minute bits to the least significant bits
	
	# Extract second (6 bits)
	sll	$s5,$v0,11      # Shift left to remove hour and minute bits
	srl	$s5,$s5,26      # Shift right to align second bits to the least significant bits
	

	la	$s6,ampm	#Calculate PM or AM

	addi	$sp,$sp,-8
	sw	$ra,0($sp)
	sw	$t1,4($sp)

	addi	$t1,$s3,-12
	addi	$s6,3	# Initialize to PM
	bltzal	$t1,AM	# If hour < 0, set to AM

	lw	$ra,0($sp)
	lw	$t1,4($sp)
	addi	$sp,$sp,8

	jr	$ra

AM:	
	addi	$s6,-3
	jr	$ra

print_date:
	lw	$a0,-4($t2)
	syscall	$print_string            # Print month name
 	la	$a0,space
	syscall	$print_string            # Print space
	move	$a0,$s2
 	syscall	$print_int             # Print day
 	la	$a0,space
	syscall	$print_string            # Print space
	move	$a0,$s0
 	syscall	$print_int             # Print year
 	la	$a0,space
	syscall	$print_string            # Print space
	move	$a0,$s3
 	syscall	$print_int             # Print hour
 	la	$a0,colon
 	syscall	$print_string            # Print colon
	move	$a0,$s4
 	syscall	$print_int             # Print minute
 	la	$a0,colon
 	syscall	$print_string            # Print colon
	move	$a0,$s5
 	syscall	$print_int             # Print second
 	la	$a0,space
	syscall	$print_string            # Print space
	move	$a0,$s6
 	syscall	$print_string             # Print am/pm
 	la	$a0,newline
 	syscall	$print_string            # Newline
	jr	$ra

leap_check:
	li	$t0,4
	div	$s0,$t0
	mfhi	$t1
	li	$t2,0
	bne	$t1,$t2,not_leap_year
	li	$t0,100
	div	$s0,$t0
	mfhi	$t1
	bne	$t1,$t2,leap_year
	li	$t0,400
	div	$s0,$t0
	mfhi	$t1
	beq	$t1,$t2,leap_year
not_leap_year:
	li	$s7,0      # Not a leap year
	jr	$ra
leap_year:
	li	$s7,1      # Leap year
	jr	$ra

calc_days:
	bne	$s7,$0,1f	# Calculates days in current month
	la	$t4,days_normal	# Non leap year
	add	$t4,$t4,$s1
	addi	$t4,$t4,-1
	lb	$t8,0($t4)
	j	2f

1:
	la	$t4,days_leap	# Leap year
	add	$t4,$t4,$s1
	addi	$t4,$t4,-1
	lb	$t8,0($t4)
2:
	jr	$ra

calculate_day_of_week: # A modified Zeller's Congruence
    # Adjust month and year for January and February
	blt	$s1,3,adjust_year  # If month is January or February, adjust year
	j	3f
adjust_year:
	addi	$s1,$s1,12    # January becomes 13, February becomes 14
	addi	$s0,$s0,-1    # Decrement year
3:
	# Compute K and J
	li	$t0,100
	div	$s0,$t0         # Divide year by 100
	mfhi	$t1             # $t1 = K (year % 100)
	mflo	$t2             # $t2 = J (year / 100)
	
	# Zeller's formula calculation
	li	$t3,13
	addi	$t4,$s1,1     # $t4 = m + 1
	mul	$t4,$t4,$t3    # $t4 = (m + 1) * 13
	div	$t4,$t4,5      # $t4 = floor((m + 1) * 13 / 5)
	mflo	$t4             # $t4 = floor((m + 1) * 13 / 5)
	
	add	$t5,$t4,$t1    # $t5 = floor((m + 1) * 13 / 5) + K
	add	$t5,$t5,$t2    # $t5 = floor((m + 1) * 13 / 5) + K + J
	addi	$t5,$t5,1     # Add day of the month (1st)
	
	# Divisions to compute the rest of the Zeller's formula
	div	$t6,$t1,4      # t6 = floor(K / 4)
	mflo	$t6
	add	$t5,$t5,$t6    # Add floor(K / 4)
	
	div	$t6,$t2,4      # t6 = floor(J / 4)
	mflo	$t6
	add	$t5,$t5,$t6    # Add floor(J / 4)
	
	li	$t6,2
	mul	$t6,$t6,$t2    # t6 = 2 * J
	sub	$t5,$t5,$t6    # Subtract 2 * J
	
	# Final day of the week calculation
	li	$t6,7
	rem	$t6,$t5,$t6    # h = result % 7
	addi	$t6,$t6,1	

	# Modify the day index to start from Sunday
	li	$t7,6
	beq	$t6,$t0,adjust_saturday # If $t6 is 0 (Saturday), adjust to 6
	addi	$t6,$t6,-1             # Otherwise, subtract 1 to start from Sunday
	j	finish_adjustment
adjust_saturday:
	move	$t6,$t7                 # Set $t6 to 6 for Saturday
	
finish_adjustment:
	move	$t9,$t6                 # Move adjusted result to $t9


	jr	$ra               # Return from the function
	


main:
	jal	getDate          # Get current date

	la	$t2,monthNames	# Calculates the month name
	sll	$t3,$s1,2
	add	$t2,$t2,$t3

	jal	print_date	# Prints the date

	jal	leap_check	# Checks if year is leap year, stores it in $s7. 1 = leap. 0 = no leap
	
	jal	calc_days	# Calculates the number of days in month, stores in $t8
	
	jal	calculate_day_of_week	# Calculates which day is first day of the month, stores in $t9 (0=Sunady,1=Monday,...)
	


	##########################################################################
	#Calendar Printing

	.data
header:	.asciiz	"Sun\tMon\tTue\tWed\tThu\tFri\tSat\n"
tab:	.asciiz	"\t" 

digit_col_line1: .asciiz "    "
digit_col_line2: .asciiz "  \xfe "
digit_col_line3: .asciiz "    "
digit_col_line4: .asciiz "  \xfe "
digit_col_line5: .asciiz "    "

digit_0_line1: .asciiz "\xfe\xfe\xfe "
digit_0_line2: .asciiz "\xfe \xfe "
digit_0_line3: .asciiz "\xfe \xfe "
digit_0_line4: .asciiz "\xfe \xfe "
digit_0_line5: .asciiz "\xfe\xfe\xfe "

digit_1_line1: .asciiz " \xfe  "
digit_1_line2: .asciiz " \xfe  "
digit_1_line3: .asciiz " \xfe  "
digit_1_line4: .asciiz " \xfe  "
digit_1_line5: .asciiz " \xfe  "

digit_2_line1:	.asciiz	"\xfe\xfe\xfe "
digit_2_line2: .asciiz "  \xfe "
digit_2_line3: .asciiz "\xfe\xfe\xfe "
digit_2_line4: .asciiz "\xfe   "
digit_2_line5: .asciiz "\xfe\xfe\xfe "

digit_3_line1:	.asciiz "\xfe\xfe\xfe "
digit_3_line2:	.asciiz "  \xfe "
digit_3_line3:	.asciiz "\xfe\xfe\xfe "
digit_3_line4:	.asciiz "  \xfe "
digit_3_line5:	.asciiz "\xfe\xfe\xfe "

digit_4_line1:	.asciiz "\xfe \xfe "
digit_4_line2:	.asciiz "\xfe \xfe "
digit_4_line3:	.asciiz "\xfe\xfe\xfe "
digit_4_line4:	.asciiz "  \xfe "
digit_4_line5:	.asciiz "  \xfe "

digit_5_line1:	.asciiz "\xfe\xfe\xfe "
digit_5_line2:	.asciiz "\xfe   "
digit_5_line3:	.asciiz "\xfe\xfe\xfe "
digit_5_line4:	.asciiz "  \xfe "
digit_5_line5:	.asciiz "\xfe\xfe\xfe "

digit_6_line1:	.asciiz "\xfe\xfe\xfe "
digit_6_line2:	.asciiz "\xfe   "
digit_6_line3:	.asciiz "\xfe\xfe\xfe "
digit_6_line4:	.asciiz "\xfe \xfe "
digit_6_line5:	.asciiz "\xfe\xfe\xfe "

digit_7_line1:	.asciiz "\xfe\xfe\xfe "
digit_7_line2:	.asciiz "  \xfe "
digit_7_line3:	.asciiz "  \xfe "
digit_7_line4:	.asciiz "  \xfe "
digit_7_line5:	.asciiz "  \xfe "

digit_8_line1:	.asciiz "\xfe\xfe\xfe "
digit_8_line2:	.asciiz "\xfe \xfe "
digit_8_line3:	.asciiz "\xfe\xfe\xfe "
digit_8_line4:	.asciiz "\xfe \xfe "
digit_8_line5:	.asciiz "\xfe\xfe\xfe "

digit_9_line1:	.asciiz "\xfe\xfe\xfe "
digit_9_line2:	.asciiz "\xfe \xfe "
digit_9_line3:	.asciiz "\xfe\xfe\xfe "
digit_9_line4:	.asciiz "  \xfe "
digit_9_line5:	.asciiz "\xfe\xfe\xfe "

	.text

	la	$a0,header
	syscall	$print_string
	
	# Load total days and start day
	move	$t2,$t8      # Total days in the month
	move	$t3,$t9         # Starting day of the week
	
	# Initial spacing based on the starting day of the week
	li	$t1,0
initial_spacing:
	# Day printing loop
	li	$t0,1                # Start from day 1
	beq	$t1,$t3,print_days
	la	$a0,tab
	syscall	$print_string
	addi	$t1,$t1,1
	j	initial_spacing
	

print_days:
	bgt	$t0,$t2,print_big_time   # Exit to big time if all days are printed

	# Print the day
	move	$a0,$t0
	syscall	$print_int
	
	# Print a tab
	la	$a0,tab
	syscall	$print_string
	
	# Check if the day is the end of the week
	addi	$t1,$t1,1      # Increment position in the week
	li	$t4,7
	rem	$t5,$t1,$t4
	beqz	$t5,new_line
	
	addi	$t0,$t0,1      # Increment day of the month
	j	print_days

new_line:
	# Print a new line
	la	$a0,newline
	syscall	$print_string
	li	$t1,0             # Reset week position
	addi	$t0,$t0,1      # Increment day of the month
	j	print_days

print_columns:
	li	$v1,25

	mul	$t2,$v1,$t1	# Number
	add	$a0,$v0,$t2
	syscall	$print_string


	mul	$t2,$v1,$t0
	add	$a0,$v0,$t2
	syscall	$print_string

	mul	$t2,$v1,$t3
	add	$a0,$v0,$t2
	syscall	$print_string

	mul	$t2,$v1,$t4
	add	$a0,$v0,$t2
	syscall	$print_string

	mul	$t2,$v1,$t5
	add	$a0,$v0,$t2
	syscall	$print_string

	jr	$ra

print_big_time:

	addi	$sp,$sp,-8
	sw	$t8,0($sp)
	sw	$t9,4($sp)

	
	
	mov	$a0,$s3	# Number - 1, 0 = Colon
	jal	isolate_digits
	mov	$t1,$t8
	addi	$t1,1
	mov	$t0,$t9
	addi	$t0,1

	lw	$t9,4($sp)
	lw	$t8,0($sp)
	addi	$sp,$sp,8


	li	$t3,0	# Colon



	mov	$a0,$s4	# Number - 1, 0 = Colon
	jal	isolate_digits
	mov	$t4,$t8
	addi	$t4,1
	mov	$t5,$t9
	addi	$t5,1
	

	la	$a0,newline
 	syscall	$print_string

	la	$v0,digit_col_line1
	jal	print_columns

	la	$a0,newline
 	syscall	$print_string

	addi	$v0,5
	jal	print_columns
	la	$a0,newline
 	syscall	$print_string
	addi	$v0,5
	jal	print_columns
	la	$a0,newline
 	syscall	$print_string
	addi	$v0,5
	jal	print_columns
	la	$a0,newline
 	syscall	$print_string
	addi	$v0,5
	jal	print_columns
	j	exit

isolate_digits:
	li	$t6,10        # Load the divisor, which is 10, into $t0.
	div	$a0,$t6      # Divide the input number by 10.
	mflo	$t8          # Move the quotient (tens place) into $t8.
	mfhi	$t9          # Move the remainder (ones place) into $t9.
	jr	$ra            # Return to the calling function.



exit:
	# Exit program
	syscall	$exit