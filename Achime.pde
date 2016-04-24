// Achime.pde written by Jack Kayser April 24, 2016
// Written to run on Processing 3.0.1 and Ubuntu 14.04
// Licensed under the GNU General Public License v2.0
// Comments and questions can be sent to me at jackkayser7374@gmail.com

// This program reads data from an Arduino which uses a LTC2400 ADC Module [24 bit A/D converter]
// to measure the voltage from a Wheatstone Bridge.  The bridge is connected to a small sample bottle
// which has two electrodes for measuring the resistivity of a fluid.  The serial data stream gets
// refreshed 7 or 8 times a second, as the ADC Module takes a new reading.
 
// A running average of the voltage is computed with each new reading and a deviation of that new
// reading from the average is computed.  After each full second, the average voltage and average
// deviation is computed for that second.  These numbers are plotted and posted to the file Achime.csv.

// Options buttons are available on the the user interface to turn the data file recording on and off,
// and set a chime alarm on and off, as well as set the value of the deviation chime trigger.  The
// system can be used to measure the effect of environmental conditions on the resistivity of the fluid.
// These environmental conditions can include the ambient Chi energy generated in Qigong or meditation.

import processing.serial.*;
import ddf.minim.*;         // Comes installed with Processing
import ddf.minim.ugens.*;   //

Table table;  // Sets up the table object which will be used in the Achime.csv file output.
PFont font;   // Required to create font styles. 

// The LTC2400 ADC Module [24 bit A/D converter] is used in an Arduino which sends voltage 
// readings to the serial port.  Processing reads the serial port and computes a running
// average of the voltage as well as the deviations from the average.
Serial port;
String value;   // Value read from serial port.
float newVolt = 0;  // Voltage value determined from serial port value.
float deltaVolt = 0;  // Deviation in current voltage from average running voltage.
float meanVolt = 0; // Running average voltage from the current second.
float mVolt = 0;   // Voltage value reported for the current second.
float sumDeltaVolt = 0; // Within this second sum of deviation of voltage from average voltage.
float aveDev = 0;  // The average magnitude of voltage deviation within the past second.
int   aveUvolt;   // The value of the average micro volt in the past second.
int count = 0;  // Keeps track of the number of serial port reads.
int lastSecond = second();  // Use in deciding whether to write line to file.

// Set the noise threshold in volts, which will play the chime sound.  Default = 10 uV, see mouse 
// click rules for other values at bottom.
float threshold = 0.000010;
int Ithresh = int(1000000*threshold);

// Sets up sounds, see Learning Processing Example 20-3
Minim minim;

// These are the aetheric wind chime notes.  They are stored as .mp3 files in the
// Achime data folder.
AudioPlayer n21Gs32, n28Ef43, n35Bf43, n42F54, n49C65, n56G65; 

// Create the array which will be used to plot the data.
int aSize = 160; // Number of data points held in an array for plotting.
int[] voltArray = new int[aSize];
int[] eXArray = new int[aSize];
int[] eYArray = new int[aSize];

// Sets up the threshold level box for triggering a chime sound.
int threshX = 35;
int threshY = 100;
int threshW = 468;
int threshH = 68;
int sideEdge = 17;
int topEdge = 30;
int littleBoxW = 60;
int littleBoxH = 28;
int littleBox1X = threshX + sideEdge/2 + 6 ;
int littleBox1Y = threshY + topEdge;
int littleBox2X = threshX + (threshW/6) + (sideEdge/2) + 4;
int littleBox2Y  = threshY + topEdge;
int littleBox3X = threshX + (threshW/3) + (sideEdge/2) + 2;
int littleBox3Y  = threshY + topEdge;
int littleBox4X = threshX + (threshW/2) + (sideEdge/2) - 2;
int littleBox4Y = threshY + topEdge;
int littleBox5X = threshX + (2*threshW/3) + (sideEdge/2) - 4;
int littleBox5Y  = threshY + topEdge;
int littleBox6X = threshX + (5*threshW/6) + (sideEdge/2) - 6;
int littleBox6Y  = threshY + topEdge;

int choice = 1;  // Default value for the audio feedback threshold trigger.

// Audio feedback button box and boolean that indicates whether the button has been pushed.
int feedX = 537;
int feedY = 100;
boolean feedback = false;

// Recorder button box and the boolean that indicates whether the button has been pushed.
int recX = 766;
int recY = 100;
int boxW = 196;
int boxH = 68;
boolean record = false;

// Set the position and size of the data plot box.
int plotBoxX = 162;
int plotBoxY = 205;
int plotBoxW = 800;
int plotBoxH = 400;

void setup() {

  // Read in the audio chime note audio files, they must be in the project data folder,
  // loaded there by using the Menu => Sketch => Add File... function.
  minim = new Minim(this);
  n21Gs32 = minim.loadFile("n21Gs32.mp3"); 
  n28Ef43 = minim.loadFile("n28Ef43.mp3");  
  n35Bf43 = minim.loadFile("n35Bf43.mp3");
  n42F54 = minim.loadFile("n42F54.mp3");
  n49C65 = minim.loadFile("n49C65.mp3");
  n56G65 = minim.loadFile("n56G65.mp3");

  // General parameters for the application window
  size(1000, 680);
  frameRate(1);
  smooth();
  font = createFont("Arial", 16, true);

  // Define the column format for the Achime.csv output file
  table = new Table();
  table.addColumn("Time", Table.STRING);
  table.addColumn("Mvolt", Table.FLOAT);
  table.addColumn("AveDev", Table.FLOAT); 

  // This script was written for a computer running Ubuntu Linux.
  String arduinoPort  = "/dev/ttyUSB0";
  port = new Serial(this, arduinoPort, 9600);
  port.bufferUntil('\n');
}

void draw() {

  background(#000000);

  // Title block at top of user interface.
  textFont(font, 55);
  fill(#C7FAF9);
  text("Aetheric Chime", 28, 75);
  textFont(font, 20);
  text("Author - Jack Kayser", 492, 45);
  text("April 24, 2016", 492, 75);

  // Generate and write to the screen the digital time
  String time1 = hour()+ ":" +minute()+ ":" +second();
  textFont(font, 55); 
  fill(#FF9A03);
  text(time1, 720, 75);

  // Draw out the boxes that contain the chime trigger threshold options.
  fill(#F6FFB9);
  strokeWeight(2);
  stroke(#FF9A03);
  rect(threshX, threshY, threshW, threshH);
  fill(0);
  textFont(font, 18);
  text("   Audio Feedback Threshold in micro Volts (uV)", threshX+10, threshY+20);

  stroke(#F57207);
  fill(#F55048);
  if ( choice == 1 ) {
    fill(#14B726);
  }
  rect(littleBox1X, littleBox1Y, littleBoxW, littleBoxH);
  fill(0);
  text("   10", littleBox1X+3, littleBox1Y+21);

  stroke(#F57207);
  fill(#F55048);
  if ( choice == 2 ) {
    fill(#14B726);
  }
  rect(littleBox2X, littleBox2Y, littleBoxW, littleBoxH);
  fill(0);
  text("   25", littleBox2X+3, littleBox2Y+21);

  stroke(#F57207);
  fill(#F55048);
  if ( choice == 3 ) {
    fill(#14B726);
  }
  rect(littleBox3X, littleBox3Y, littleBoxW, littleBoxH);
  fill(0);
  text("   40", littleBox3X+3, littleBox3Y+21);

  stroke(#F57207);
  fill(#F55048);
    if ( choice == 4 ) {
    fill(#14B726);
  }
  rect(littleBox4X, littleBox4Y, littleBoxW, littleBoxH);
  fill(0);
  text("  100", littleBox4X+2, littleBox4Y+21);
  
  stroke(#F57207);
  fill(#F55048);
    if ( choice == 5 ) {
    fill(#14B726);
  }
  rect(littleBox5X, littleBox5Y, littleBoxW, littleBoxH);
  fill(0);
  text("  500", littleBox5X+2, littleBox5Y+21);

  stroke(#F57207);
  fill(#F55048);
    if ( choice == 6 ) {
    fill(#14B726);
  }
  rect(littleBox6X, littleBox6Y, littleBoxW, littleBoxH);
  fill(0);
  text("1,000", littleBox6X+5, littleBox6Y+21);


  // If feedback is turned off show how to turn it on
  if (feedback == false) {
    fill(#F6FFB9);
    strokeWeight(2);
    stroke(#FF9A03);
    rect(feedX, feedY, boxW, boxH);
    fill(0);
    textFont(font, 18);
    text("Click to start", feedX+50, feedY+20);
    text("audio feedback", feedX+51, feedY+40);
    text("chime sounds", feedX+50, feedY+60);
    fill(#00FF1B);
    stroke(0);
    goSign(feedX, feedY);
  }

  // If feedback is turned on show how to turn it off
  if (feedback == true) {
    fill(#F6FFB9);
    strokeWeight(2);
    stroke(#FF9A03);
    rect(feedX, feedY, boxW, boxH);
    fill(0);
    textFont(font, 18);
    text("Click to stop", feedX+50, feedY+20);
    text("audio feedback", feedX+51, feedY+40);
    text("chime sounds", feedX+50, feedY+60);
    fill(#FF0303);
    stroke(0);
    stopSign(feedX, feedY);
  }

  // If recorder is turned off show how to turn it on
  if (record == false) {
    fill(#F6FFB9);
    strokeWeight(2);
    stroke(#FF9A03);
    rect(recX, recY, boxW, boxH);
    fill(0);
    textFont(font, 18);
    text("Click to start", recX+50, recY+20);
    text("recording to", recX+51, recY+40);
    text("Achime.csv", recX+51, recY+60);
    fill(#00FF1B);
    stroke(0);
    goSign(recX, recY);
  }

  // If recorder is turned on show how to turn it off
  if (record == true) {
    fill(#F6FFB9);
    strokeWeight(2);
    stroke(#FF9A03);
    rect(recX, recY, boxW, boxH);
    fill(0);
    textFont(font, 18);
    text("Click to stop", recX+50, recY+20);
    text("recording to", recX+51, recY+40);
    text("Achime.csv", recX+51, recY+60);
    fill(#FF0303);
    stroke(0);
    stopSign(recX, recY);
  }

  // Generate the plot of recent results.
  fill(#030F08);
  strokeWeight(1);
  stroke(#0A2E15);
  rect(plotBoxX, plotBoxY, plotBoxW, plotBoxH);
  // Call the routine that draws up the grid of lines.
  grid(plotBoxX, plotBoxY, plotBoxW, plotBoxH);
  plotArray();  // Call function to plot the voltArray data.
}  // End draw routine.

// Read in the values from the searial port and compute the average during the current second.
void serialEvent( Serial port) {
  value = port.readStringUntil('\n');
  println("Value Read From Serial Port = " + value);

  if (count == 0) {  
    mVolt = float( value );
  }

  count = count + 1;
  newVolt = float( value );
  meanVolt = meanVolt + (newVolt - meanVolt)/count;  // Running mean voltage within current second.
  deltaVolt = newVolt - meanVolt;  // Deviation of current reading from running mean voltage.
  sumDeltaVolt = sumDeltaVolt + abs(deltaVolt);  // Summation of absolute value of deviations within current second.

  int thisSecond = second();
  if ( thisSecond != lastSecond ) {
    mVolt = meanVolt;  // Set the average voltage for the given second.
    aveDev = sumDeltaVolt/count;  // Compute and set the average deviation for the given second.
    meanVolt = 0;  // Reset the values to zero in preparation for the next second.
    count = 0;
    sumDeltaVolt = 0;
    lastSecond = thisSecond;

    // Play the notes depending on the magnitude of the average voltage in the last second.
    if ( feedback == true && aveDev >= threshold ) {
      aveUvolt = int ( 1000000*aveDev );
      Ithresh = int ( 1000000*threshold );
      if( aveUvolt >= 10 && aveUvolt < 25 ){
        n21Gs32.play(0);
      } else if ( aveUvolt >= 25 && aveUvolt < 40 ){
        n28Ef43.play(0);
      } else if ( aveUvolt >= 40 && aveUvolt < 100 ){
        n35Bf43.play(0);
      } else if ( aveUvolt >= 100 && aveUvolt < 500 ){
        n42F54.play(0);
      } else if ( aveUvolt >= 500 && aveUvolt < 1000 ){
        n49C65.play(0);
      } else if ( aveUvolt >= 1000 ){
        n56G65.play(0);
      }
    }

    // Update the voltArray and then call the routine to plot the voltArray data.
    for (int i = 1; i < aSize; i = i+1) {
      int j = aSize - i;
      voltArray[j] = voltArray[j-1];
    }
    voltArray[0] = int (1000000*aveDev);

    // If the record button is turned on write data to the file.
    if (record == true) {
      writeFile();  // Call function that writes out data
    }
  }
}

// These next lines are used to plot the array of data.
void plotArray() {  
  int eSize = 5;   // Size of the ellipse use to illustrate the plot.
  ellipseMode(CENTER);
  fill(#FF6200);
  stroke(#FF6200);
  strokeWeight(2);
  // Build the array of plot locations.
  for (int k = 0; k < aSize; k = k+1) {
    eXArray[k] =  plotBoxX + k*5 + 5;
    if ( voltArray[k] > 10000 ) { 
      voltArray[k] = 10000;
    }
    if ( voltArray[k] < 1 ) { 
      voltArray[k] = 1;
    }
    // This plot is in a base 10 four-cycle semi-log style due to the dymanic range of reading.
    eYArray[k] =  plotBoxY + plotBoxH - int( ( log( voltArray[k] )/log(10) ) * plotBoxH/4 );
  }

  // Plot the ellipses and the lines connecting them.
  for (int j = 0; j < aSize; j = j+1) {
    ellipse(eXArray[j], eYArray[j], eSize, eSize);
    if (j < (aSize - 1)) {
      line(eXArray[j], eYArray[j], eXArray[j+1], eYArray[j+1]);
    }
  }
}

// Function to write out the data to the Achime.csv file.
public void writeFile() {
  String time = hour()+ ":" +minute()+ ":" +second(); //  + "." +millis();
  TableRow newRow = table.addRow();
  newRow.setString("Time", time); 
  newRow.setFloat("Mvolt", mVolt);
  newRow.setFloat("AveDev", aveDev);
  saveTable(table, "Achime.csv");
}

// Function that draws a triangle go sign
void goSign(int datumX, int datumY) {
  beginShape();
  vertex(datumX + 11, datumY + 14);
  vertex(datumX + 42, datumY + 32);
  vertex(datumX + 11, datumY + 48);
  endShape(CLOSE);
}

// Function that draw a stop sign
void stopSign(int datumX, int datumY) {
  beginShape();
  vertex(datumX + 20, datumY + 18);
  vertex(datumX + 32, datumY + 18);
  vertex(datumX + 41, datumY + 27);
  vertex(datumX + 41, datumY + 39);
  vertex(datumX + 32, datumY + 48);
  vertex(datumX + 20, datumY + 48);
  vertex(datumX + 11, datumY + 39);
  vertex(datumX + 11, datumY + 27);
  endShape(CLOSE);
}

// Draw out the grid pattern on the data plot.
void grid(int cornerX, int cornerY, int plotWidth, int plotHeight) {
  beginShape();
  strokeWeight(1);
  stroke(#0A2E15);

  // Horizontal lines
  line(cornerX, cornerY+5, cornerX+plotWidth, cornerY+5);  
  line(cornerX, cornerY+10, cornerX+plotWidth, cornerY+10);
  line(cornerX, cornerY+16, cornerX+plotWidth, cornerY+16);  
  line(cornerX, cornerY+22, cornerX+plotWidth, cornerY+22);
  line(cornerX, cornerY+30, cornerX+plotWidth, cornerY+30);  
  line(cornerX, cornerY+40, cornerX+plotWidth, cornerY+40);
  line(cornerX, cornerY+52, cornerX+plotWidth, cornerY+52);  
  line(cornerX, cornerY+70, cornerX+plotWidth, cornerY+70);   
  line(cornerX, cornerY+100, cornerX+plotWidth, cornerY+100);
  line(cornerX, cornerY+105, cornerX+plotWidth, cornerY+105);  
  line(cornerX, cornerY+110, cornerX+plotWidth, cornerY+110);
  line(cornerX, cornerY+116, cornerX+plotWidth, cornerY+116);  
  line(cornerX, cornerY+122, cornerX+plotWidth, cornerY+122);
  line(cornerX, cornerY+130, cornerX+plotWidth, cornerY+130);  
  line(cornerX, cornerY+140, cornerX+plotWidth, cornerY+140);
  line(cornerX, cornerY+152, cornerX+plotWidth, cornerY+152);  
  line(cornerX, cornerY+170, cornerX+plotWidth, cornerY+170);   
  line(cornerX, cornerY+200, cornerX+plotWidth, cornerY+200);
  line(cornerX, cornerY+205, cornerX+plotWidth, cornerY+205);  
  line(cornerX, cornerY+210, cornerX+plotWidth, cornerY+210);
  line(cornerX, cornerY+216, cornerX+plotWidth, cornerY+216);  
  line(cornerX, cornerY+222, cornerX+plotWidth, cornerY+222);
  line(cornerX, cornerY+230, cornerX+plotWidth, cornerY+230);  
  line(cornerX, cornerY+240, cornerX+plotWidth, cornerY+240);
  line(cornerX, cornerY+252, cornerX+plotWidth, cornerY+252);  
  line(cornerX, cornerY+270, cornerX+plotWidth, cornerY+270);   
  line(cornerX, cornerY+300, cornerX+plotWidth, cornerY+300);
  line(cornerX, cornerY+305, cornerX+plotWidth, cornerY+305);  
  line(cornerX, cornerY+310, cornerX+plotWidth, cornerY+310);
  line(cornerX, cornerY+316, cornerX+plotWidth, cornerY+316);  
  line(cornerX, cornerY+322, cornerX+plotWidth, cornerY+322);
  line(cornerX, cornerY+330, cornerX+plotWidth, cornerY+330);  
  line(cornerX, cornerY+340, cornerX+plotWidth, cornerY+340);
  line(cornerX, cornerY+352, cornerX+plotWidth, cornerY+352);  
  line(cornerX, cornerY+370, cornerX+plotWidth, cornerY+370);

  // Vertical lines
  line(cornerX+50, cornerY, cornerX+50, cornerY+plotHeight);
  line(cornerX+100, cornerY, cornerX+100, cornerY+plotHeight);
  line(cornerX+150, cornerY, cornerX+150, cornerY+plotHeight);
  line(cornerX+200, cornerY, cornerX+200, cornerY+plotHeight);
  line(cornerX+250, cornerY, cornerX+250, cornerY+plotHeight);
  line(cornerX+300, cornerY, cornerX+300, cornerY+plotHeight);
  line(cornerX+350, cornerY, cornerX+350, cornerY+plotHeight);
  line(cornerX+400, cornerY, cornerX+400, cornerY+plotHeight);
  line(cornerX+450, cornerY, cornerX+450, cornerY+plotHeight);
  line(cornerX+500, cornerY, cornerX+500, cornerY+plotHeight);
  line(cornerX+550, cornerY, cornerX+550, cornerY+plotHeight);
  line(cornerX+600, cornerY, cornerX+600, cornerY+plotHeight);
  line(cornerX+650, cornerY, cornerX+650, cornerY+plotHeight);
  line(cornerX+700, cornerY, cornerX+700, cornerY+plotHeight);  
  line(cornerX+750, cornerY, cornerX+750, cornerY+plotHeight);

  // Horizontal ticks and bottom boundary line
  strokeWeight(1);
  stroke(#17A55A);
  line(cornerX-6, cornerY, cornerX, cornerY);
  line(cornerX-6, cornerY+16, cornerX, cornerY+16);  
  line(cornerX-6, cornerY+30, cornerX, cornerY+30);    
  line(cornerX-6, cornerY+52, cornerX, cornerY+52);
  line(cornerX-6, cornerY+70, cornerX, cornerY+70);  
  line(cornerX-6, cornerY+100, cornerX, cornerY+100);  
  line(cornerX-6, cornerY+116, cornerX, cornerY+116);  
  line(cornerX-6, cornerY+130, cornerX, cornerY+130);    
  line(cornerX-6, cornerY+152, cornerX, cornerY+152);
  line(cornerX-6, cornerY+170, cornerX, cornerY+170);  
  line(cornerX-6, cornerY+200, cornerX, cornerY+200);
  line(cornerX-6, cornerY+216, cornerX, cornerY+216);  
  line(cornerX-6, cornerY+230, cornerX, cornerY+230);    
  line(cornerX-6, cornerY+252, cornerX, cornerY+252);
  line(cornerX-6, cornerY+270, cornerX, cornerY+270);
  line(cornerX-6, cornerY+300, cornerX, cornerY+300);
  line(cornerX-6, cornerY+316, cornerX, cornerY+316);  
  line(cornerX-6, cornerY+330, cornerX, cornerY+330);    
  line(cornerX-6, cornerY+352, cornerX, cornerY+352);
  line(cornerX-6, cornerY+370, cornerX, cornerY+370);  
  line(cornerX-6, cornerY+400, cornerX, cornerY+400);
  strokeWeight(2);
  line(cornerX, cornerY+plotHeight, cornerX+plotWidth, cornerY+plotHeight);

  // Vertical ticks and left boundary line
  strokeWeight(1);
  line(cornerX, cornerY+plotHeight, cornerX, cornerY+plotHeight+6);
  line(cornerX+50, cornerY+plotHeight, cornerX+50, cornerY+plotHeight+6);  
  line(cornerX+100, cornerY+plotHeight, cornerX+100, cornerY+plotHeight+6);  
  line(cornerX+150, cornerY+plotHeight, cornerX+150, cornerY+plotHeight+6);  
  line(cornerX+200, cornerY+plotHeight, cornerX+200, cornerY+plotHeight+6);  
  line(cornerX+250, cornerY+plotHeight, cornerX+250, cornerY+plotHeight+6);  
  line(cornerX+300, cornerY+plotHeight, cornerX+300, cornerY+plotHeight+6);  
  line(cornerX+350, cornerY+plotHeight, cornerX+350, cornerY+plotHeight+6);  
  line(cornerX+400, cornerY+plotHeight, cornerX+400, cornerY+plotHeight+6);
  line(cornerX+450, cornerY+plotHeight, cornerX+450, cornerY+plotHeight+6);  
  line(cornerX+500, cornerY+plotHeight, cornerX+500, cornerY+plotHeight+6);  
  line(cornerX+550, cornerY+plotHeight, cornerX+550, cornerY+plotHeight+6);  
  line(cornerX+600, cornerY+plotHeight, cornerX+600, cornerY+plotHeight+6);  
  line(cornerX+650, cornerY+plotHeight, cornerX+650, cornerY+plotHeight+6);  
  line(cornerX+700, cornerY+plotHeight, cornerX+700, cornerY+plotHeight+6);  
  line(cornerX+750, cornerY+plotHeight, cornerX+750, cornerY+plotHeight+6);  
  line(cornerX+800, cornerY+plotHeight, cornerX+800, cornerY+plotHeight+6);
  strokeWeight(2);
  line(cornerX, cornerY, cornerX, cornerY+plotHeight);

  // Add in axis numbers
  textFont(font, 14);
  fill(#17A55A);
  // Along Y axis
  text("10,000", cornerX-60, cornerY+5);
  text(" 7,000", cornerX-56, cornerY+21);
  text(" 5,000", cornerX-56, cornerY+35);
  text(" 3,000", cornerX-56, cornerY+57);
  text(" 2,000", cornerX-56, cornerY+75);  
  text(" 1,000", cornerX-56, cornerY+105);
  text(" 700", cornerX-42, cornerY+121);
  text(" 500", cornerX-42, cornerY+135);
  text(" 300", cornerX-42, cornerY+157);
  text(" 200", cornerX-42, cornerY+175);  
  text(" 100", cornerX-42, cornerY+205);
  text(" 70", cornerX-32, cornerY+221);
  text(" 50", cornerX-32, cornerY+235);
  text(" 30", cornerX-32, cornerY+257);
  text(" 20", cornerX-32, cornerY+275);  
  text(" 10", cornerX-32, cornerY+305);
  text(" 7", cornerX-24, cornerY+321);
  text(" 5", cornerX-24, cornerY+335);
  text(" 3", cornerX-24, cornerY+357);
  text(" 2", cornerX-24, cornerY+375);  
  text(" 1", cornerX-24, cornerY+405);    
  // Along X axis
  text("0", cornerX-3, cornerY+plotHeight+23);
  text("10", cornerX+42, cornerY+plotHeight+23);
  text("20", cornerX+92, cornerY+plotHeight+23);
  text("30", cornerX+142, cornerY+plotHeight+23);
  text("40", cornerX+192, cornerY+plotHeight+23);
  text("50", cornerX+242, cornerY+plotHeight+23);
  text("60", cornerX+292, cornerY+plotHeight+23);
  text("70", cornerX+342, cornerY+plotHeight+23);
  text("80", cornerX+392, cornerY+plotHeight+23);
  text("90", cornerX+442, cornerY+plotHeight+23);
  text("100", cornerX+488, cornerY+plotHeight+23);
  text("110", cornerX+538, cornerY+plotHeight+23);
  text("120", cornerX+588, cornerY+plotHeight+23);
  text("130", cornerX+638, cornerY+plotHeight+23);
  text("140", cornerX+688, cornerY+plotHeight+23);
  text("150", cornerX+738, cornerY+plotHeight+23);
  text("160", cornerX+788, cornerY+plotHeight+23);

  // Add it the axis titles
  textFont(font, 18);
  text("Average", cornerX-134, cornerY+150);
  text("Voltage", cornerX-132, cornerY+175); 
  text("Noise in", cornerX-134, cornerY+200);
  text("Each", cornerX-121, cornerY+225);
  text("Previous", cornerX-136, cornerY+250);
  text("Second", cornerX-132, cornerY+275); 
  text("(uV)", cornerX-118, cornerY+300);
  text("Seconds Into the Past", cornerX+300, cornerY+450);

  endShape();
}

// React when the mouse is clicked
public void mousePressed() { 

  // Mouse click inside of box to set level 1 threshold
  if (mouseX > littleBox1X && mouseX < littleBox1X+littleBoxW && mouseY > littleBox1Y && mouseY < littleBox1Y+littleBoxH) {
    choice = 1;
    threshold = .000010;
    println("threshold set to " + threshold);
  }

  // Mouse click inside of box to set level 2 threshold
  if (mouseX > littleBox2X && mouseX < littleBox2X+littleBoxW && mouseY > littleBox2Y && mouseY < littleBox2Y+littleBoxH) {
    choice = 2;
    threshold = .000025;
    println("threshold set to " + threshold);
  }

  // Mouse click inside of box to set level 3 threshold
  if (mouseX > littleBox3X && mouseX < littleBox3X+littleBoxW && mouseY > littleBox3Y && mouseY < littleBox3Y+littleBoxH) {
    choice = 3;
    threshold = .000040;
    println("threshold set to " + threshold);
  }

  // Mouse click inside of box to set level 4 threshold
  if (mouseX > littleBox4X && mouseX < littleBox4X+littleBoxW && mouseY > littleBox4Y && mouseY < littleBox4Y+littleBoxH) {
    choice = 4;
    threshold = .000100;
    println("threshold set to " + threshold);
  }

  // Mouse click inside of box to set level 5 threshold
  if (mouseX > littleBox5X && mouseX < littleBox5X+littleBoxW && mouseY > littleBox5Y && mouseY < littleBox5Y+littleBoxH) {
    choice = 5;
    threshold = .000500;
    println("threshold set to " + threshold);
  }

  // Mouse click inside of box to set level 6 threshold
  if (mouseX > littleBox6X && mouseX < littleBox6X+littleBoxW && mouseY > littleBox6Y && mouseY < littleBox6Y+littleBoxH) {
    choice = 6;
    threshold = .001000;
    println("threshold set to " + threshold);
  }

  // Mouse click in the feedback control box
  if (mouseX > feedX && mouseX < feedX+boxW && mouseY > feedY && mouseY < feedY+boxH ) {
    if ( feedback == false ) {
      feedback = true;
    } else if ( feedback == true ) {
      feedback = false;
    }
  }

  // Mouse click in the record control box
  if (mouseX > recX && mouseX < recX+boxW && mouseY > recY && mouseY < recY+boxH ) {
    if ( record == false ) {
      record = true;
    } else if ( record == true ) {
      record = false;
    }
  }
}

void stop()
{
  minim.stop();
  super.stop();
}