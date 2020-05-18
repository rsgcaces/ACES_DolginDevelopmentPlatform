;PROJECT    :ExternalInterrupt84
;PURPOSE    :First Look at Assembly Coding of Interrupts: External Interrupt
;AUTHOR     :C. D'Arcy
;DATE       :2020 05 13
;DEVICE     :Dolgin Development Platform plus Universal Shield
;MCU        :ATtiny84
;COURSE     :ICS4U
;STATUS     :Working
;REFERENCE  :https://mail.rsgc.on.ca/~cdarcy/Datasheets/doc0856.pdf
;REFERENCE  :http://darcy.rsgc.on.ca/ACES/TEI4M/iotnx4.h
#include  "avr/io.h"      //pulls in the master set of predefines
.section .text            ;optional
.global main              ;expose this code to the compiler
.org    0x0000            ;start of vector jump table
 rjmp main                ;lower the interrupt address => the higher the priority!
//.org    0x0002
// rjmp INT0_vect 
#define util  r16         //readability is enhanced through the use of aliases for GP Registers
.org    _VECTORS_SIZE     ;set Location Counter just beyond the interrupt jump table
main:                     ;PC jumps to here on reset interrupt...
 sbi  DDRA-0x20,PA0       ;set digital pin 0 for output 
 cbi  DDRB-0x20,PB2       ;guarantee INT0 (PB2) declared for input
 sbi  PORTB-0x20,PB2      ;set pullup resistor on INT0 (PB2)

 rcall  Int0Setup         ;configure the required registers to respond to Ext. Int. 0 (PB2)
 sei                      ;enable Global Interrupt System (I flag in SREG)

hold:
 rjmp hold                ;hold here a press the button to toggle the LED on PA0

Int0Setup:
 ldi  util,1<<ISC01     ;prepare the Interrupt Sense Control for FALLING edge
 out  MCUCR-0x20,util        ;set it! (MCUCR is beyond the address range of the out instruction)
 ldi  util,1<<INT0      ;prepare to respond to Ext. Int. 0
 out  GIMSK-0x20,util        ;set it! (GIMSK is beyond the address range of the out instruction)
 ret

.global INT0_vect
INT0_vect:
 sbi  PINA-0x20,PA0     ;remember this? Fastest way to toggle a PORT bit :)
 reti                   ;return from interrupt
