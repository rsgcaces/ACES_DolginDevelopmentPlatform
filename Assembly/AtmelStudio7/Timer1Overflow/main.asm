;PROJECT    :T1NormalOVF
;PURPOSE    :Demonstration of Timer1 Normal Mode with Overflow Interrupt
;AUTHOR     :C. D'Arcy
;DATE       :2020 05 18
;DEVICE     :Dolgin Development Platform
;MCU        :ATtiny84
;COURSE     :ICS4U
;STATUS     :Working
;REFERENCE  :https://mail.rsgc.on.ca/~cdarcy/Datasheets/doc0856.pdf
.include	"prescalers84.h"    ;include all possible Timer/Counter prescaler defines
.def        util    = r16       ;readability is enhanced through 'use' aliases for GP Registers
.cseg                           ;locate for Code Segment (FLASH) 
; ***** INTERRUPT VECTOR TABLE ***********************************************
.org        0x0000              ;start of Interrupt Vector Table (IVT) aka. Jump Table
	rjmp    reset               ;lowest interrupt address == highest priority!
.org        OVF1addr			;External Interrupt Request 0 (prefined in tn84def.inc)
	rjmp    T1OVFISR			;
; ***** START OF CODE ********************************************************
.org	INT_VECTORS_SIZE		;set Location Counter just beyond the interrupt jump table
reset:                          ;PC jumps to here (start of code) on reset interrupt...
	sbi		DDRA,PA0			;declare digital pin 0 for output
	rcall	T1OVFSetup			;configure Timer/Counter 1 for Normal Mode
	sei							;enable global interrupts 
hold:
    rjmp    hold                ;hold and admire the square wave on pin 0 

T1OVFISR:						;Timer 1 Nomral Mode ISR 
	sbi		PINA,PA0			;toggle the corresponding PORT bit for digital pin 0
	reti						;return from interrupt

T1OVFSetup:
	clr		util				;zero everything for the most basic use
	out		TCCR1A,util			;set for Timer/Counter1 Mode 0 (Normal)
	ldi		util,T1ps64			;Clk/64 yields 1 Hz (approximately)
 	out		TCCR1B,util			;do it
	clr		util				;not technically necessary, but jworth a look... 
	out		TCNT1H,util			;zero the high byte of the counter first
	out		TCNT1L,util			;zero the low byte of the counter second
	ldi		util,1<<TOIE1		;prepare to enable Timer 1 Overlow Interrupt capability
	out		TIMSK1,util			;do it
	ret							;return

