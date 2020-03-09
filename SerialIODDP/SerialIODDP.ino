// PROJECT  :SerialIODDP
// PURPOSE  :(Software) Serial Input and Output on the DDP: Blink command toggle
// COURSE   :ICS4U
// AUTHOR   :C. D'Arcy
// DATE     :2020 03 09
// MCU      :84 (for the DDP)
// STATUS   :So Working :)
// REFERENCE:https://www.instructables.com/id/ATtiny8485-In-circuit-Debugging-Using-Serial-Outpu/
// PHOTO    :https://mail.rsgc.on.ca/~cdarcy/DDPJoyStickSerialFull.jpg
//************************************************************************
#include <SoftwareSerial.h>    // Arduino SoftwareSerial class
// Pins used are device specific (84/85)
#if defined(__AVR_ATtiny84__) || defined(__AVR_ATtiny84A__)
#define ledPin  0               // Toggle to turn connected Led on/off
#define rxPin   9               // Green Pin B1 used for Serial receive
#define txPin   10              // White Pin B0 used for Serial transmit
#elif defined(__AVR_ATtiny85__)
#define ledPin  1
#define rxPin   4
#define txPin   3
#else
#error Only ATtiny84 and ATtiny85 are Supported by this Project
#endif
// Create an instance of the Software Serial class specifying which device
// pins are to be used for receive and transmit
SoftwareSerial mySerial(rxPin, txPin);
void setup() {
  mySerial.begin(9600);       // Start serial processing
  delay(2000);                // Give Serial class time to complete initialization.
  // otherwise, 1st output likely missing or garbled
  pinMode(ledPin, OUTPUT);    // Configure led pin for OUTPUT
  mySerial.println("SETUP Complete - SoftwareSerial Example\n");
}
//------------------------------------------------------------------------
// Toggle the led; document HIGH/LOW with serial output messages
//------------------------------------------------------------------------
void loop() {
  //Issue a prompt...
  mySerial.println("Enter a 0 (Off) or 1 (On)...");
  while (!mySerial.available());
  char choice = mySerial.read();
  digitalWrite(ledPin, choice & 1);
  while (mySerial.available())    //clear input buffer...
    mySerial.read();
}
