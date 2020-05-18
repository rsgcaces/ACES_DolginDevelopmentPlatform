// RSGC ACES: ICS4U
// Prescale constants for ATtiny84 Timer/Counters
// Reference: https://mail.rsgc.on.ca/~cdarcy/Datasheets/ATtiny84.pdf
// Comments assume System Clock Speed is 8 MHz or (approximately) 2^23
#define T0Stopped 0b00000000    // Timer0 stopped
#define T0psNone  0b00000001    // T0:2^23/2^8  (no prescale)> 2^15 ovf/s = 2^14 Hz
#define T0ps8     0b00000010    // T0:2^23/2^3/2^8 (prescale)> 2^12 ovf/s = 2^11 Hz
#define T0ps64    0b00000011    // T0:2^23/2^6/2^8 (prescale)> 2^9 ovf/s = 2^8 Hz
#define T0ps256   0b00000100    // T0:2^23/2^8/2^8 (prescale)> 2^7 ovf/s = 2^6 Hz
#define T0ps1024  0b00000101    // T0:2^23/2^10/2^8(prescale)> 2^5 ovf/s = 2^4 Hz
#define T1Stopped 0b00000000    // Timer1 stopped
#define T1psNone  0b00000001    // T1:2^23/2^16  (no prescale)> 2^7 ovf/s > 2^6 or 64 Hz
#define T1ps8     0b00000010    // T1:2^23/2^3/2^16 (prescale)> 2^4 ovf/s > 2^3 or 8 Hz
#define T1ps64    0b00000011    // T1:2^23/2^6/2^16 (prescale)> 2^1 ovf/s > 2^0 or 1 Hz
#define T1ps256   0b00000100    // T1:2^23/2^8/2^16 (prescale)> 1 ovf/s   > 0.5Hz
#define T1ps1024  0b00000101    // T1:2^23/2^10/2^16(prescale)> 2^(-3) ovf/s > 2^(-4) or 0.0625 Hz

