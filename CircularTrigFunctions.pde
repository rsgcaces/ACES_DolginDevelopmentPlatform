// PROJECT  :CircularTrigFunctions
// PURPOSE  :Visualization of the 6 circular trig functions around the unit circle using a Thumb Joystick 
// COURSE   :Inspired by 2019-2020 ICS3U
// AUTHOR   :C. D'Arcy
// DATE     :2020 02 29 (Leap day)
// MCU      :84/328P  (Serial feed from Arduino/MyProcessing/ThumbJoystick.ino)
// STATUS   :Working
import processing.serial.*;
PGraphics Cartesian;          //Full Stage
PGraphics RxR;                //Layer0: Axes, label, unit circle, calibration
PGraphics Pot;                //Layer1: Trig values rendered as segment lengths

PFont serif;
PFont numbers;

float minX =-1.5;
float maxX = -minX;
float domain = maxX-minX;
float minY =-1.5;
float maxY = -minY;
float range = maxY-minY;
float epsilon = 1E-2;          //tolerance of 0
float piBy2 = PI/2;
float threePiBy2 = 3*piBy2;
float originX, originY;

Serial myPort;        // The serial port
int potHorz = -3;     //this is the horizontal, default centered, at-rest reading
int potVert = 0;      //this is the vertical, default centered, at-rest reading
int horz;
int vert;
int horzPrev = 0;
int vertPrev = 0;
int sample = 20;
int smoothX[] = new int[sample];      //smoothing arrays
int smoothY[] = new int[sample];      //

void setup() {
  serif = loadFont("TimesNewRomanPS-ItalicMT-32.vlw");
  numbers = loadFont("TimesNewRomanPSMT-32.vlw");
  // List all the available serial ports:
  //printArray(Serial.list());
  // Open the port you are using at the rate you want:
  myPort = new Serial(this, Serial.list()[0], 9600);
  for (int i=0; i<sample; i++) {
    smoothX[i]=128;
    smoothY[i]=131;
  }
  originX = mapX(0.0);
  originY = mapY(0.0);
  size(700, 700);
  RxR = createGraphics(width, height);
  composeRxR();                                //Layer0: one-time creation
  Pot = createGraphics(width, height);
  Cartesian = createGraphics(width, height);
  background(255);                             //clear background (to white)
}

void draw() {
  while (myPort.available()>2) {    //must be at least 2 to read otherwise read returns -1.
    while ((horz = myPort.read()) == 0);  //read to the registration byte: 0
    vert = myPort.read();
    horz = smoothHorz(horz);        //clean up a potentially jittery pot
    vert = smoothVert(vert);
    composeCartesian(horz, vert);   //construct updated image in off-screen virtual buffer 
    image(Cartesian, 0, 0);         //now, place layered content in view 
  }
}

void composeCartesian(int horz, int vert) {
  Cartesian.beginDraw();           //create a new canvas
  Cartesian.background(255);       //clear canvas to white
  Cartesian.image(RxR, 0, 0);      //add the static axes backdrop   
  composePot(horz, vert);          //create the current context        
  Cartesian.image(Pot, 0, 0);      //add the current context 
  Cartesian.endDraw();             //finish up
}

//one time construction for Layer 0
void composeRxR() {
  RxR.beginDraw();

  //Legend: sin
  RxR.fill(255, 0, 0);
  RxR.stroke(255, 0, 0);
  RxR.rect(10, 10, 20, 20);
  //cos
  RxR.fill(0, 255, 0);
  RxR.stroke(0, 255, 0);
  RxR.rect(10, 40, 20, 20);
  //tan
  RxR.fill(0, 0, 255);
  RxR.stroke(0, 0, 255);
  RxR.rect(10, 70, 20, 20);
  //csc
  RxR.fill(255, 255, 0);
  RxR.stroke(255, 255, 0);
  RxR.rect(10, 100, 20, 20);
  //sec
  RxR.fill(0, 255, 255);
  RxR.stroke(0, 255, 255);
  RxR.rect(10, 130, 20, 20);
  //cot
  RxR.fill(255, 0, 255);
  RxR.stroke(255, 0, 255);
  RxR.rect(10, 160, 20, 20);

  RxR.stroke(0);
  RxR.textFont(serif, 32);
  RxR.fill(0);
  RxR.strokeWeight(1);
  RxR.line(mapX(minX), mapY(0), mapX(maxX), mapY(0));
  RxR.line(mapX(0), mapY(minY), mapX(0), mapY(maxY));
  RxR.text("u", mapX(1.8), mapY(-0.2));
  RxR.text("v", mapX(-0.2), mapY(1.8));
  RxR.textFont(numbers, 32);
  RxR.text("The Circular Functions", 375, 670);
  RxR.text("1.0", mapX(1.0), mapY(-0.2));
  RxR.text("1.0", mapX(-0.3), mapY(1.0));
  RxR.text("sin", 40, 30);
  RxR.text("cos", 40, 60);
  RxR.text("tan", 40, 90);
  RxR.text("csc", 40, 120);
  RxR.text("sec", 40, 150);
  RxR.text("cot", 40, 180);
  RxR.noFill();
  RxR.strokeWeight(2);
  RxR.ellipse(mapX(0.0), mapY(0.0), mapX(1.0)-mapX(-1.0), mapX(1.0)-mapX(-1.0));
  RxR.endDraw();
}

void composePot(int horz, int vert) {
  Pot.beginDraw();
  Pot.clear();

  int horzAdj =horz+potHorz;                    //obtain horizontal pot reading relative to default position
  int vertAdj =vert+potVert;                    //obtain vertical pot reading relative to default position

  float whereX = minX+horzAdj*domain/256;
  float whereY = maxY-vertAdj*range/256;

  float theta = 0.0;

  if (abs(whereX)<epsilon)
    if (abs(whereY)<epsilon)
      theta = 0.0;
    else
      theta = whereY>=0 ? piBy2 : threePiBy2;
  else {
    theta = atan(whereY/whereX);
    if (whereX<0)
      theta += PI;
  }
  float u = cos(theta);
  float v = sin(theta);

  int coordX = mapX(u);
  int coordY = mapY(v);

  //draw the radius  on the unit circle...
  //Pot.ellipse(coordX, coordY, 6, 6);
  Pot.stroke(0);
  Pot.strokeWeight(3);
  Pot.line(originX, originY, coordX, coordY);

  //determine the two intercepts of the tangent line (required for all but sin and cos)
  float numerator = u*u+v*v;
  float xInt = mapX(numerator/u);
  float yInt = mapY(numerator/v);


  Pot.strokeWeight(8);
  //tan
  Pot.stroke(0, 0, 255);
  Pot.line(coordX, coordY, xInt, originY);

  //cot
  Pot.stroke(255, 0, 255);
  Pot.line(coordX, coordY, originX, yInt);

  //csc
  Pot.stroke(255, 255, 0);
  Pot.line(originX, originY, originX, yInt);

  //sec
  Pot.stroke(0, 255, 255);
  Pot.line(originX, originY, xInt, originY);

  Pot.strokeWeight(6);
  //sin
  Pot.stroke(255, 0, 0);
  Pot.line(coordX, originY, coordX, coordY);
  //cos
  Pot.stroke(0, 255, 0);
  Pot.line(originX, originY, coordX, originY);
  
  //draw the point on the unit circle...
  Pot.stroke(0);
  Pot.ellipse(coordX, coordY, 10, 10);
  
  Pot.endDraw();
}

//----------UTILITY Functions---------------
int mapX(float x) {
  return int((x-minX)*width/domain);
}
int mapY(float y) {
  return int((maxY-y)*height/range);
}

//data smoothing functions (could consider placing this in the Serial Feeder) 
int smoothHorz(int h) {
  long total = 0;
  for (int i=0; i<sample-1; i++) {
    smoothX[i+1] = smoothX[i];
    total+=smoothX[i];
  }
  smoothX[0] = h;
  return int((total+h)/sample);
}

int smoothVert(int v) {
  long total = 0;
  for (int i=0; i<sample-1; i++) {
    smoothY[i+1] = smoothY[i];
    total+=smoothY[i];
  }
  smoothY[0] = v;
  return int((total+v)/sample);
}
