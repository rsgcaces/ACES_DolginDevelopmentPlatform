;PROJECT    :BareMinimumDDBv7
;PURPOSE    :Code shell for AVR Assembly projects for the DDP (ATtiny84) 
;AUTHOR     :C. D'Arcy
;DATE       :2022 03 30
;DEVICE     :Dolgin Development Platform. Version 7.
;MCU        :ATtiny84
;COURSE     :ICS4U
;STATUS     :Working
;REFERENCE  :http://darcy.rsgc.on.ca/ACES/Datasheets/ATtiny84.pdf
;NOTES      :
;.include   "prescalars84.inc"  ;assembly directive equivalent to compiler directive #include
.def        util    = r16       ;readability is enhanced through 'use' aliases for GP Registers
.equ        DDR     = DDRA      ;typically, we'll need the use of PortA
.equ        PORT    = PORTA     ;both its data direction register and output register and, eventually,
.equ        PIN     = PINA      ;its input register
; DATA Segment declarations
.dseg                           ;locate for Data Segment (SRAM) requirements (default start at 0x0060)
var:        .BYTE 1             ;reserve one byte for a variable (the label is the symbol)
; CODE Segment (default) 
.cseg                           ;locate for Code Segment (FLASH) 
; ***** INTERRUPT VECTOR TABLE ***********************************************
.org        0x0000              ;start of Interrupt Vector Table (IVT) aka. Jump Table
    rjmp    reset               ;lowest interrupt address == highest priority!
.org        EXT_INT0addr        ;External Interrupt Request 0 (prefined in tn84def.inc)
;   rjmp    INT0_vect
;.org		INT_VECTORS_SIZE	;locate flash data requests here
;.db		1					;sample	also .dw
; ***** START OF CODE ********************************************************
.org        0x0100              ;well clear of IVT & program memory data
reset:                          ;PC jumps to here (start of code) on reset interrupt...
	ldi		util,low(RAMEND)	;AS7 appears to do this by default
	out		SPL,util			;however it is wise to ensure the SP
	ldi		util,high(RAMEND)	;starts out at the highest SRAM address 
	out		SPH,util			;
wait:
    ldi     util,0xAA
    sts     var,util
    rjmp    wait                ;repeat or hold...