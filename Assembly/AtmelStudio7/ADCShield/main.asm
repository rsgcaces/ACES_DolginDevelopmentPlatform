;PROJECT    :ADCShieldASM
;PURPOSE    :Demonstration of cumulative use cases: functions, Stack, binary to BCD  
;AUTHOR     :C. D'Arcy
;DATE       :2020 05 20
;DEVICE     :Dolgin Development Platform
;MCU        :ATtiny84
;COURSE     :ICS4U
;STATUS     :Not Working
;REFERENCE  :https://mail.rsgc.on.ca/~cdarcy/Datasheets/doc0856.pdf
.include	"prescalers84.h"    ;include all possible Timer/Counter prescaler defines
.def    util		= r16       ;readability is enhanced through 'use' aliases for GP Registers
.def	base		= r17		;register holds base pin of active transistor
.def	bin0		= r18		;low byte of 16-bit ADC reading
.def	bin1		= r19       ;high byte of 16-bit ADC reading
.def	BCD10		= r22		;two lowest BCD digits of the Double-Dabble
.def	BCD32		= r23       ;next two BCD digits of the Double Dabble
.def	BCD4		= r24       ;highest BCD digit of the Double DAbble (always 0 for 10-bit ADC)
.equ	DDR			= DDRA      ;typically, we'll need the use of PortA
.equ	PORT		= PORTA     ;both its data direction register and output register and, eventually,
.equ    units		= PA4		;ground the respective displays 
.equ    DATA		= PA5       ;595 data pin
.equ    LATCH		= PA6       ;595 latch pin
.equ    CLOCK		= PA7       ;595 clock pin
.cseg                           ;locate for Code Segment (FLASH) 
; ***** INTERRUPT VECTOR TABLE ***********************************************
.org    0x0000                  ;start of Interrupt Vector Table (IVT) aka. Jump Table
		rjmp	reset			;lowest interrupt address == highest priority!
;.org	OVF1addr				;Local Timer 1 Overflow ISR used but not explicitly required
;		rjmp	TIM1_OVF		;as sole purpose is to trigger the next ADC Conversion
.org	ADCCaddr				;Analog to Digital Conversion Complete vector
		rjmp	ADC_Conv_Comp	;ISR: ADC Complete ISR
; ***** FLASH DATA ***********************************************************
.org	INT_VECTORS_SIZE        ;position segment LUT beyond the IVT
segStart:						;(MSBFIRST:)ABCDEFGx
.db		0b11111100,0b01100000,0b11011010,0b11110010  ;0-3
.db		0b01100110,0b10110110,0b10111110,0b11100000  ;4-7
.db		0b11111110,0b11110110,0b11101110,0b00111110  ;8-b
.db		0b10011100,0b01111010,0b10011110,0b10110110  ;C-F
segEnd:
; ***** START OF CODE ********************************************************
.org	0x0100              ;well clear of IVT
reset:                          ;PC jumps to here (start of code) on reset interrupt...	ldi		util,low(RAMEND)    ;position the Stack pointer to the end of SRAM
	ldi		util,low(RAMEND)	;ensure the Stack Pointer points to the end
	out		SPL,util            ;of SRAM to ensure maximum stack size
	ldi		util,high(RAMEND)   ;This is technically not necessary as the  
	out		SPH,util            ;assembler does it for us, but it's good practice
	ldi		util,0xFE			;easy to forget to set output ports
	out		DDR,util			;this has cost me more than a few lost hours :(

	rcall	ADCSetup			;configure Timer 1 Overflow interrupt to trigger conversions
	rcall	Timer1Setup         ;Normal mode to generate a 1Hz interrupt
	sei							;enable global interrupt system
	rcall	packedBCDPoV		;call function and remain, forever
 hold:
	rjmp	hold				;watch Shield display while adjusting pot or other V.D. 

Timer1Setup:
	clr		util				;zero everything for the most basic use
	out		TCCR1A,util			;set for Timer/Counter1 Mode 0 (Normal)
	ldi		util,T1ps64			;Clk/64 yields 1Hz (approximately)
 	out		TCCR1B,util			;do it
	clr		util				;not technically necessary, but jworth a look... 
	out		TCNT1H,util			;zero the high byte of the counter first
	out		TCNT1L,util			;zero the low byte of the counter second
	ldi		util,1<<TOIE1		;prepare to enable Timer 1 Overlow Interrupt capability
	out		TIMSK1,util			;do it
	ret

;ISR:
;TIM1_OVF:
;	reti						;not explicitly required, see IVT Comment above

ADCSetup:
	ldi		util, 0						;AVcc as reference, MUX:A0
	out		ADMUX,util					;
;Enable, Start Dummy Conversion, prescaler of 64 to yield freq of 128k
	ldi		util,(1<<ADEN)|(1<<ADSC)|(1<<ADPS2)|(1<<ADPS1)	;
	out		ADCSRA,util					;
dummy:
	in		util,ADCSRA					;read the ADCSRA 
	sbrs	util,ADIF					;is the 25 cycle conversion complete?
	rjmp	dummy						;if not, keep waiting
	sbi		ADCSRA,ADIF					;dummy conversion complete, clear the interrupt flag (by setting it!)
	sbi		ADCSRA,ADATE				;enable auto-triggering
	ldi		util,(1<<ADTS2)|(1<<ADTS1)	;request Timer 1 Overflow as Trigger Source
	out		ADCSRB,util					;set Trigger
	sbi		ADCSRA,ADIE					;enable ADC interrupt
	ret									;off we go...

;ISR:
ADC_Conv_Comp:
	in		bin0,ADCL					;MUST read the low-byte of the conversion,
	in		bin1,ADCH					;then read the high byte of the conversion
	rcall	bin16BCD5					;routine convert 16-bit binary to 5 (packed) byte BCD
	reti								;return to PoVing with new value...

;****** DOUBLE DABBLE Algorithm applied to 16-bit decimal *************************
;PreConditions
; 16-bit binary number to be converted is in register pair bin1:bin0 = r19:r18
;Clobbers: R24:r23:r22
;PostConditions: packedBCD in register set BCD4:BCD32:BCD10=R24:r23:r22
;**********************************************************************************
bin16BCD5:
	push	r16                 ;preserve contents of registers to be utilized
	push	r17                 ;
	push	r20					;
	push	r21					;
	
	ldi		r20,0x03            ;prepare the constant 3 in two ways for efficiency
	ldi		r21,0x30            ;one as a low nibble add and the other as a high nibble add
	ldi		r17,16              ;Loop Control Variable (LCV): a full 16 shifts are required
	
	clr		r24                 ;ensure the BCD target registers are zeroed
	clr		r23                 ;"
	clr		r22                 ;"
binNext:
	lsl		r18                 ;Shift bin0 left, MSB -> C Flag of SREG
	rol		r19                 ;rotate bin1 left so C Flag becomes LSB
	rol		r22                 ;rotate similarly for BCD10
	rol		r23                 ;rotate similarly for BCD32
	rol		r24                 ;rotate similarly for BCD4
	dec		r17                 ;one less shift to do...
	breq	binDone             ;are we finished all 16?
bin1s:
	mov		r16,r22             ;prepare to check BCD10 for need to Add 3
	andi	r16,0x0F            ;temporarily mask off high nibble
	cpi		r16,0x05            ;is the result greater than 4?
	brlo	bin10s              ;if not, continue
	add		r22,r20             ;if so, Add 3
bin10s:
	cpi		r22,0x50            ;is the high nibble of BCD10 greater than 4?
	brlo	bin100s             ;if not, continue
	add		r22,r21             ;if so, Add 3 to high nibble of BCD10
bin100s:
	mov		r16,r23             ;prepare to check BCD32 for need to Add 3
	andi	r16,0x0F            ;temporarily mask off high nibble
	cpi		r16,0x05            ;is the result greater than 4?
	brlo	bin1000s            ;if not, continue
	add		r23,r20             ;if so, Add 3
bin1000s:
	cpi		r23,0x50            ;is the high nibble of BCD32 greater than 4?
	brlo	bin10000s           ;if not, continue
	add		r23,r21             ;if so, Add 3 to high nibble of BCD32
bin10000s:                      ;not necessarily for ADC values, but complete for future use                     
	mov		r16,r24             ;prepare to check BCD4 for need to Add 3
	cpi		r16,0x05            ;is the result greater than 4?
	brlo	binNext             ;if not, continue
	add		r24,r20             ;if so, Add 3
	rjmp	binNext             ;keep going...
binDone:                        
	pop		r21                 ;restore preserved register values
	pop		r20                 ;"
	pop		r17                 ;"
	pop		r16                 ;"
	ret

;************PACKEDBCDPOV*************************************
;PreConditions...
; packed BCD value as follows: BCD32:BCD10 = R23:r22
;Predefines: PORT, digital pin for units is defined
;PostConditions: packed BCD value persistent on the ADC displays
;************************************************************* 
packedBCDPoV:
;Stack use is not really required
; as function never exits (only interrupted) 
 push	r16                     ;util
 push	r17                     ;base 
 push	r18                     ;(bin0)
 push	r19                     ;(bin1)

 ldi	base,1<<units           ;to get the loop started correctly assume units have been done
 sbi	PORT,units              ;this requires setting the units' base pin in the PORT
 ldi	XL,low(segStart<<1)		;one time initialization of pointer to 
 ldi	XH,high(segStart<<1)	; starting address of LUT

PoVTop:							;display order: thousands>hundreds>tens>units
 mov	r16,r23                 ;obtain BCD32
 swap	r16                     ;switch nibbles
 andi	r16,0x0F                ;obtain the thousands digit
 movw	Z,X                     ;assign X to Z; the start of the segment LUT
 add	ZL,r16                  ;use digit for correct offset into the segment LUT 
 lpm	r20,Z                   ;get the segment map corresponding to the thousands digit
 rcall	updateDisplay           ;self-explanatory
 rcall	delay5ms                ;timeout to reduce flicker

 mov	r16,r23                 ;obtain BCD32
 andi	r16,0x0F                ;obtain the hundreds digit
 movw	Z,X                     ;assign X to Z; the start of the segment LUT
 add	ZL,r16                  ;use digit for correct offset into the segment LUT 
 lpm	r20,Z                   ;get the segment map corresponding to the thousands digit
 rcall	updateDisplay           ;self-explanatory
 rcall	delay5ms                ;timeout to reduce flicker
 
 mov	r16,r22                 ;obtain BCD10
 swap	r16                     ;switch nibbles
 andi	r16,0x0F                ;obtain the tens digit
 movw	Z,X                     ;assign X to Z; the start of the segment LUT
 add	ZL,r16                  ;use digit for correct offset into the segment LUT 
 lpm	r20,Z                   ;get the segment map corresponding to the thousands digit
 rcall	updateDisplay           ;self-explanatory
 rcall	delay5ms                ;timeout to reduce flicker

 mov	r16,r22                 ;obtain BCD10
 andi	r16,0x0F                ;obtain the units digit
 movw	Z,X                     ;assign X to Z; the start of the segment LUT
 add	ZL,r16                  ;use digit for correct offset into the segment LUT 
 lpm	r20,Z                   ;get the segment map corresponding to the thousands digit
 rcall	updateDisplay           ;self-explanatory
 rcall	delay5ms                ;timeout to reduce flicker

 rjmp	PoVTop                  ;repeat unconditionally

 pop	r19                     ;Unreachable as function never exits but,
 pop	r18                     ; for the record, if use to be exported
 pop	r17                     ;
 pop	r16                     ;
 ret

;************UPDATEDISPLAY*************************************
;PreConditions...
; PORTA bits declared for output
; X points to start of Segment LUT in Flash
; packed BCD value as follows: BCD32:BCD10 = R23:r22
;Predefines: PORT, units
;PostConditions: packed BCD value persistent on the ADC displays
;************************************************************* 
updateDisplay:
;----Toggle previous base pin so it is OFF------------------------------------------
 in		r16,PORT                ;read the PORT for the current base pin
 eor	r16,base				;toggle previous base pin off
 out	PORT,r16                ;write the PORT 
;----End of toggle OFF ----------------------------------------------------
 rcall	shiftout				;shift out the segment map (it's in n!)
;----Determine which base pin to turn ON------------------------------------------
 sbrc	base,units				;have we already reached the units digit? 
 ldi	base,1<<PA0				;if so, we're here and we need to prepare for the thousands digit (PA1) 
 lsl	base					;shift the base pin to turn on the next digits
;----Toggle correct base pin so it is ON------------------------------------------
 in		r16,PORT                ;read the PORT
 eor	r16,base				;toggle previous base pin off
 out	PORT,r16                ;write the PORT
;-------End of toggle base pin so it is ON ---------------------------------------------------
 ret

;************SHIFTOUT ********************************************************
;PreConditions:
; byte to be shifted is in r20
; X points to start of Segment LUT in Flash
; shift order is MSBFIRST
;Predefines: PORT, LATCH, CLOCK, DATA
;PostConditions: Segments for BCD byte in r20 appear on the respective display
;*****************************************************************************
shiftout:                       ;shifts r20 into the 595 MSBFIRST
 push	r16						;(util)
 push	r18						;(bin0)

 ldi	r18,0x80                ;commit to MSBFIRST
 cbi	PORT,LATCH              ;pull LATCH pin LOW

topSO:
 cbi	PORT,CLOCK              ;pull CLOCK pin LOW
 mov	r16,r20                 ;obtain a copy of the original value to be presented 
 and	r16,r18                 ;mask off the target bit
 breq	lo                      ;was it 0?
 sbi	PORT,DATA               ;no, so pull DATA pin HIGH
 rjmp	clockit                 ;ready to clock the 1
lo:
 cbi	PORT,DATA               ;else, it was a 0, so pull DATA pin LOW
clockit:
 sbi	PORT,CLOCK              ;pull CLOCK pin HIGH
 lsr	r18                     ;MSBFIRST shifts the mask right
 brne	topSO                   ;repeat if there are still more bits to stuff in

 sbi	PORT,LATCH              ;pull LATCH pin HIGH to present 595's internal latches on output pins
 
 pop	r18						;util
 pop	r16						;mask
 ret                            ;finished, return.

delay5ms:
; Assembly code auto-generated
; by utility from Bret Mulvey
; Delay 40 000 cycles
; 5ms at 8.0 MHz
 push	r21                     ;preserve exploited register values
 push	r25                     ;
 ldi	r21, 52                 ;
 ldi	r25, 242                ;
L1:
 dec	r25                     ;
 brne	L1                      ;
 dec	r21                     ;
 brne	L1                      ;
 nop
 pop	r25                     ;restore preserved register values 
 pop	r21                     ;
 ret 
