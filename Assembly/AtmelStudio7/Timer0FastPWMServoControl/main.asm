;PROJECT    :Timer0FastPWMMode7
;PURPOSE    :ADC-Controlled Servo Horn Position with Timer0 FastPWM Mode 7 Signal
;AUTHOR     :C. D'Arcy
;DATE       :2020 05 22
;DEVICE     :Dolgin Development Platform
;MCU        :ATtiny84
;COURSE     :ICS4U
;STATUS     :Working
;REFERENCE  :https://mail.rsgc.on.ca/~cdarcy/Datasheets/doc0856.pdf
;NOTES		:Hobby servos require a PWM frequency of 50Hz (20ms period)
;			:Typical horn positions range from 0deg (5%dc) to 180deg 10%dc)
;			:Timer0 is not the best choice for this demonstration due to its limited
;			:resolution but we haven't showcased it before so, why not?... 
.include	"prescalers84.h"    ;include all possible Timer/Counter prescaler defines
.def    util	= r16			;readability is enhanced through 'use' aliases for GP Registers
.cseg                           ;locate for Code Segment (FLASH) 
; ***** INTERRUPT VECTOR TABLE ***********************************************
.org    0x0000                  ;start of Interrupt Vector Table (IVT) aka. Jump Table
		rjmp	reset			;lowest interrupt address == highest priority!
;.org	OC0Aaddr				;not actually required since no specific action taken
;		rjmp	TIM0_CompA_Match;interrupt enabled below as trigger for AD Conversion
.org	ADCCaddr				;this IS required since we need to read the pot
		rjmp	ADC_Conv_Comp	;to control horm position through OCR0B value
.org	INT_VECTORS_SIZE        ;position segment LUT beyond the IVT
; ***** START OF CODE ********************************************************
reset:                          ;PC jumps to here (start of code) on reset interrupt...	ldi		util,low(RAMEND)    ;position the Stack pointer to the end of SRAM
	ldi		util,low(RAMEND)	;ensure the Stack Pointer points to the end
	out		SPL,util            ;of SRAM to ensure maximum stack size
	ldi		util,high(RAMEND)   ;This is technically not necessary as the  
	out		SPH,util            ;assembler does it for us, but it's good practice
;	sbi		DDRB,PB2			;not actually required for PWM 
	sbi		DDRA,PA7			;THIS is in the PWM signal pin! so OC0B set for output
	rcall	T0Setup				;configure Fast PWM Mode 7 (OCR0A as top)
	rcall	ADCSetup			;trigger ADC Conversion on Timer/Counter0 Compare Match A
	sei							;enable Global Interrupt System 
 hold:
	rjmp	hold				;nothing to do control servo horn with pot 

ADCSetup:
	ldi		util, 0				;AVcc as reference, MUX:A0
	out		ADMUX,util			;set it...
;Enable, Start Dummy Conversion, prescaler of 64 to yield freq of 128k
	ldi		util,(1<<ADEN)|(1<<ADSC)|(1<<ADPS2)|(1<<ADPS1)
	out		ADCSRA,util			;set it
dummy:
	in		util,ADCSRA			;read the ADCSRA 
	sbrs	util,ADIF			;is the 25-cycle conversion complete?
	rjmp	dummy				;if not, keep waiting
	sbi		ADCSRA,ADIF			;dummy conversion complete, clear the interrupt flag (by setting it!)
	sbi		ADCSRA,ADATE		;enable an automatic trigger for ADC of pot reading  
;request left-alignment of ADC reading and identify Timer/Counter0 Compare Match A as trigger
	ldi		util,(1<<ADLAR)|(1<<ADTS1)|(1<<ADTS0)	
	out		ADCSRB,util			;set it..
	sbi		ADCSRA,ADIE			;enable ADC interrupt
	ret							;off we go...

T0Setup:
;disconnect OC0A, Clear OC0B on Match;Set on Bottom, Mode 7
	ldi		util,(1<<COM0B1)|(1<<WGM01)|(1<<WGM00)
	out		TCCR0A,util			
;complete Mode 7 and define max precaler to reach 50Hz (20ms)
	ldi		util,(1<<WGM02)| T0ps1024
	out		TCCR0B,util			;2^23/2^10(PS)/OCR0A = 50Hz
	ldi		util,160			;closer to 157 to achieve period of 20ms (50Hz)
	out		OCR0A,util          ;set compare match threshold
	ldi		util,8				;8:1ms(0 degree horn pos.) 16:2ms(180degree horn)
	out		OCR0B,util			;set duty cycle

	ldi		util,1<<OCIE0A		;enable Output Compare Match A Interrupt
	out		TIMSK0,util			;set it
	ret							;done

TIM0_CompA_Match:
	reti

ADC_Conv_Comp:
	in		util,ADCH			;ADLAR set so only read the high byte of the conversion
	lsr		util				;map to a range of [0..7] so divide by 32
	lsr		util				; "
	lsr		util				; "
	lsr		util				; "
	lsr		util				; "
	ori		util,8				;add 8 to achieve range of [8,15]
	out		OCR0B,util			;OCR0B controls duty cycle hence horn position
	reti						;return from interrupt
