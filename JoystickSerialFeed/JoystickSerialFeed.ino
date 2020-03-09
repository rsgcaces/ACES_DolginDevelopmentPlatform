// PROJECT  :JoystickSerialFeed
// PURPOSE  :High-level reading and Serial println of two ThumbJoystick pots
//          :Support for Processing Circular Functions Demo
// COURSE   :ICS3U/ICS4U
// AUTHOR   :C. D'Arcy
// DATE     :Latest: 2020 03 07
// MCU      :DDP(84)/(UNO)328P
// STATUS   :Working
// REFERENCE:https://www.instructables.com/id/ATtiny8485-In-circuit-Debugging-Using-Serial-Outpu/
// NOTES    :DDP: (0,1,2,3,4)=(VCC,VERT,HORZ,SEL,GROUND)
//          :This would be ideal for the Universal Shield (Challenge???!!)
//Activate one of the two targets...
//#define   LOCAL           //Serial Monitor or Plotter
#define   PROCESSING        //...Arduino/MyProcessing/JoyStickTrig/CircularTrigFunctions.pde

// Pick an MCU...
#if defined (__AVR_ATtiny84__)
#define VCC     0
#define VERT    1         //ADC1
#define HORZ    2         //ADC2
#define SEL     3         //
#define GND     4         //  
#define HORZOUT 6         //PWM: OC1A (Pin 5:OC1B inaccessbile)
#define VERTOUT 8         //PWM: OC0A (avoided pin 7:OC0B)
#define RXPIN   9         // Pin used for Serial receive
#define TXPIN   10        // Pin used for Serial transmit
#define VERTGND 10        //
#include <SoftwareSerial.h>    // Arduino SoftwareSerial class
SoftwareSerial mySerial(RXPIN, TXPIN);
#else  //#if defined(__AVR_ATmega328P__)
#define VCC     14        //A0
#define VERT    15        //ADC1
#define HORZ    16        //ADC2
#define SEL     17        //ADC3
#define GND     18        //ADC4  
#define HORZOUT 11        //PWM: OC2A (Pin 11)
#define VERTOUT 9         //PWM: OC1A (Pin 9)
#define VERTGND 8         //
#endif
#define LOWER 0
#define UPPER 255

uint8_t horzRead, vertRead;

void setup() {
#if defined (__AVR_ATmega328P__)
  Serial.begin(9600);
  //   Serial.println(String(0)+" "+String(260));
  //   Serial.print(" ");
  //   Serial.println(255);
#endif
#if defined (__AVR_ATtiny84__)
  pinMode(VCC, OUTPUT);       //provides 5V (little current draw)
  digitalWrite(VCC, HIGH);    //
  pinMode(GND, OUTPUT);       //provides sink, again, little draw
  digitalWrite(GND, LOW);
  mySerial.begin(9600);       // Start serial processing
  delay(1000);                // Give Serial class time to complete initialization.
  // otherwise, 1st output likely missing or garbled
  //  mySerial.println("SETUP Complete - SoftwareSerial Example");
  //  pinMode(VERTGND, OUTPUT);   //provide a pseudo-ground for LED sourced
  //  digitalWrite(VERTGND, LOW); //by PWM (OC0A) on pin 8
#endif
}

void loop() {
  // Avoid 0, used as the registration marker
  horzRead = constrain(analogRead(HORZ) >> 2, 1, 255);
  delay(10);
  vertRead = constrain(analogRead(VERT) >> 2, 1, 255);
  delay(10);
  //  analogWrite(HORZOUT, horzRead);
  //  analogWrite(VERTOUT, vertRead);
#if defined (__AVR_ATmega328P__)
#ifdef PROCESSING
  Serial.write(0);            //registration marker
  Serial.write(horzRead);     //
  Serial.write(vertRead);     //place the byte value in the stream
#else  //LOCAL Serial Monitor/Plotter...
//  Serial.print(LOWER + String(" "));
//  Serial.print(UPPER + String(" "));
  Serial.print(horzRead + String(" "));
  Serial.println(vertRead);
#endif
#endif
#if defined (__AVR_ATtiny84__)
#ifdef PROCESSING
  mySerial.write((byte)0);      //registration marker
  mySerial.write((byte)horzRead);     //
  mySerial.write((byte)vertRead);     //place the byte value in the stream
#else  //LOCAL Serial Monitor/Plotter...
  //   mySerial.print(LOWER + String(" "));
  //   mySerial.print(UPPER + String(" "));
  mySerial.print(horzRead + String(" "));
  mySerial.println(vertRead);
#endif
#endif
}
