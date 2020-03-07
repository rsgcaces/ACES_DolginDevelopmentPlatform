// PROJECT  :SerialOutputDDP 
// PURPOSE  : 
// COURSE   :ICS3U/ICS4U
// AUTHOR   :C. D'Arcy
// DATE     :2020 02 28
// MCU      :84 (DDP)
// STATUS   :Not Working
// REFERENCE:https://www.instructables.com/id/ATtiny8485-In-circuit-Debugging-Using-Serial-Outpu/
//************************************************************************
//  PART 1: Serial output setup and example output:
//  .  Modifies the example Blink code to illustrate serial output
//  .  Common code for ATtiny85 and ATtiny84
//************************************************************************
#include <SoftwareSerial.h>    // Arduino SoftwareSerial class
 
// While the processing code is common, the pins used are device specific
#if defined(__AVR_ATtiny84__) || defined(__AVR_ATtiny84A__)
  #define ledPin  0               // Toggle to turn connected Led on/off
  #define rxPin   9               // Pin used for Serial receive
  #define txPin   10              // Pin used for Serial transmit
#elif defined(__AVR_ATtiny85__)
  #define ledPin  1
  #define rxPin   4
  #define txPin   3
#else
  #error Only ATiny84 and ATtiny85 are Supported by this Project
#endif
 
// Create instance of the Software Serial class specifying which device
// pins are to be used for receive and transmit
SoftwareSerial mySerial(rxPin, txPin);
 
//------------------------------------------------------------------------
// Initialize processing resources
//------------------------------------------------------------------------
void setup() 
{            
  mySerial.begin(9600);       // Start serial processing      
  delay(2000);                // Give Serial class time to complete initialization.
                              // otherwise, 1st output likely missing or garbled
  
  pinMode(ledPin, OUTPUT);    // Configure led pin for OUTPUT  
 
  mySerial.println("SETUP Complete - SoftwareSerial Example");
}
 
//------------------------------------------------------------------------
// Toggle the led; document HIGH/LOW with serial output messages
//------------------------------------------------------------------------
void loop() 
{
  // Turn led on; display "it's on" message
  digitalWrite(ledPin, HIGH);   
  mySerial.println("LED ON");
  delay(2000);                  
  
  // Turn led off; display "it's off" message
  digitalWrite(ledPin, LOW);      
  mySerial.println(" LED OFF");
  delay(2000);            
}
