;PROJECT    :T0NormalOVF
;PURPOSE    :Simple confirmation of Timer0 Normal Mode Overflow
;AUTHOR     :C. D'Arcy
;DATE       :2020 05 18
;DEVICE     :Dolgin Development Platform
;MCU        :ATtiny84
;COURSE     :ICS4U
;STATUS     :Working
;REFERENCE  :https://mail.rsgc.on.ca/~cdarcy/Datasheets/doc0856.pdf
;NOTES		:The limited range of Extended Ports [0x20-0x5F] is entirelt addressable
;			:with the out instruction (no need to use sts) 
.include	"prescalers84.h"    ;include all possible Timer/Counter prescaler defines
.def    util		= r16       ;readability is enhanced through 'use' aliases for GP Registers
.equ	DDR			= DDRA      ;typically, we'll need the use of PortA
.equ	PORT		= PORTA     ;both its data direction register and output register and, eventually,
.cseg                           ;locate for Code Segment (FLASH) 
; ***** INTERRUPT VECTOR TABLE ***********************************************
.org    0x0000                  ;start of Interrupt Vector Table (IVT) aka. Jump Table
		rjmp	reset			;lowest interrupt address == highest priority!
.org	OVF0addr
		rjmp	TIM0_OVF		;Timer0 Overflow Interrupt Service Routine
.org	INT_VECTORS_SIZE        ;position segment LUT beyond the IVT
; ***** START OF CODE ********************************************************
reset:                          ;PC jumps to here (start of code) on reset interrupt...	ldi		util,low(RAMEND)    ;position the Stack pointer to the end of SRAM
	ldi		util,low(RAMEND)	;ensure the Stack Pointer points to the end
	out		SPL,util            ;of SRAM to ensure maximum stack size
	ldi		util,high(RAMEND)   ;This is technically not necessary as the  
	out		SPH,util            ;assembler does it for us, but it's good practice
	sbi		DDR,PA0				;place an LED in digital pin 1 on the DDP, cathode in ground
	rcall	T0Setup				;configure Mode 0
	sei							;enable Global Interrupt System 
 hold:
	rjmp	hold				;nothing to do but watch

T0Setup:
	clr		util				;
	out		TCCR0A,util			;Normal Mode 0
	ldi		util,T0ps1024		;Maximum prescalar to see oscillations
	out		TCCR0B,util			;2^23/2^10(PS)/2^8/2 = 2^6/2 = 32Hz
	ldi		util,1<<TOIE0		;enable overflow interrupts
	out		TIMSK0,util			;set it
	ret

;ISR: Timer 0 Overflow  
TIM0_OVF:
	sbi		PINA,PA0			;toggle PORTA0		
	reti
