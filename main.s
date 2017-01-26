;****************** main.s ***************
; Program written by: Albert Bautista (abb2639)
; Date Created: 1/15/2017 
; Last Modified: 1/25/2017 
; Brief description of the program
; The objective of this system is to implement a Car door signal system
; Hardware connections: Inputs are negative logic; output is positive logic
;  PF0 is right-door input sensor (1 means door is open, 0 means door is closed)
;  PF4 is left-door input sensor (1 means door is open, 0 means door is closed)
;  PF3 is Safe (Green) LED signal - ON when both doors are closed, otherwise OFF
;  PF1 is Unsafe (Red) LED signal - ON when either (or both) doors are open, otherwise OFF
; The specific operation of this system 
;   Turn Unsafe LED signal ON if any or both doors are open, otherwise turn the Safe LED signal ON
;   Only one of the two LEDs must be ON at any time.
; NOTE: Do not use any conditional branches in your solution. 
;       We want you to think of the solution in terms of logical and shift operations

GPIO_PORTF_DATA_R  EQU 0x400253FC
GPIO_PORTF_DIR_R   EQU 0x40025400
GPIO_PORTF_AFSEL_R EQU 0x40025420
GPIO_PORTF_PUR_R   EQU 0x40025510
GPIO_PORTF_DEN_R   EQU 0x4002551C
GPIO_PORTF_LOCK_R  EQU 0x40025520
GPIO_PORTF_CR_R    EQU 0x40025524
GPIO_PORTF_AMSEL_R EQU 0x40025528
GPIO_PORTF_PCTL_R  EQU 0x4002552C
GPIO_LOCK_KEY      EQU 0x4C4F434B  ; Unlocks the GPIO_CR register
SYSCTL_RCGCGPIO_R  EQU   0x400FE608
      THUMB
      AREA    DATA, ALIGN=2
;global variables go here
      ALIGN
      AREA    |.text|, CODE, READONLY, ALIGN=2
      EXPORT  Start
Start
	;Borrowed initialization prompts from Input Output example and changed the enable and direction bits
    LDR R1, =SYSCTL_RCGCGPIO_R      ; 1) activate clock for Port F
    LDR R0, [R1]                 
    ORR R0, R0, #0x20               ; set bit 5 to turn on clock
    STR R0, [R1]                  
    NOP
    NOP                             ; allow time for clock to finish
    LDR R1, =GPIO_PORTF_LOCK_R      ; 2) unlock the lock register
    LDR R0, =0x4C4F434B             ; unlock GPIO Port F Commit Register
    STR R0, [R1]                    
    LDR R1, =GPIO_PORTF_CR_R        ; enable commit for Port F
    MOV R0, #0xFF                   ; 1 means allow access
    STR R0, [R1]                    
    LDR R1, =GPIO_PORTF_AMSEL_R     ; 3) disable analog functionality
    MOV R0, #0                      ; 0 means analog is off
    STR R0, [R1]                    
    LDR R1, =GPIO_PORTF_PCTL_R      ; 4) configure as GPIO
    MOV R0, #0x00000000             ; 0 means configure Port F as GPIO
    STR R0, [R1]                  
    LDR R1, =GPIO_PORTF_DIR_R       ; 5) set direction register
    MOV R0,#0x0A                    ; PF0 and PF7-4 input, PF3-1 output
    STR R0, [R1]                    
    LDR R1, =GPIO_PORTF_AFSEL_R     ; 6) regular port function
    MOV R0, #0                      ; 0 means disable alternate function 
    STR R0, [R1]                    
    LDR R1, =GPIO_PORTF_PUR_R       ; pull-up resistors for PF4,PF0
    MOV R0, #0x11                   ; enable weak pull-up on PF0 and PF4
    STR R0, [R1]              
    LDR R1, =GPIO_PORTF_DEN_R       ; 7) enable Port F digital port
    MOV R0, #0x1B                   ; 1 means enable digital I/O
    STR R0, [R1]
	LDR	R0,=GPIO_PORTF_DATA_R		; R0 points to DATA_R for Port F to allow to read inputs and write outputs to the location

loop
	LDR	R1,[R0]					;	[DATA_R] -> R1
	AND	R2,R1,#0x01				;	Masks DATA_R bit 0 for right door input
	AND	R3,R1,#0x10				;	Masks DATA_R bit 4 for left door input
	MOV R2,R2,LSL #3			;	R2 -> DATA_R bit 0 into the same bit position for comparison
	MOV	R3,R3,LSR #1			;	R3 -> DATA_R bit 4 into the same bit position for comparison
	;EOR	R2,#8				;	NOT R2[3] Negative Logic already implemented no need for this
	;EOR	R3,#8				;	NOT	R3[3] Negative Logic already implemented no need for this
	AND	R2,R2,R3				;	R2[3] & R3[3] -> R2[3] Compare if both switches are on for safe LED
	EOR	R3,R2,#8				;	Puts NOT R2[3] -> R3[3]
	LSR	R3,#2					;	R3[3]-R3[1] Places the complement of safe LED into unsafe LED bit position
	AND	R1,#0xF5				;	Clears Bits 1 & 3 to have empty spaces to 
	ORR	R1,R1,R2				;	Copies New PF_3 Safe LED to be put into system
	ORR R1,R1,R3				;	Copies New PF_1 Unsafe LED to be put into system
	STR	R1,[R0]					;	Stores Outputs back into [DATA_R]
    B   loop
	
	ALIGN        ; make sure the end of this section is aligned
	END          ; end of file