//Arduino powered thermostat by Dustin Andrews
//License: http://creativecommons.org/licenses/by/3.0/


//MAX6675 Version


// constants won't change. They're used here to 
//pins for segment of the displays, Semi random due to board layout considerations.
const int segA = 7; 
const int segB = 5;
const int segC = 8;
const int segD = 4;
const int segE = 3;
const int segF = 9;
const int segG = 6; 

const int pinSO  = 11; //MISO
const int pinSSB = 12; //enable serial interface LOW.
const int pinSCK = 13; //Serial Clock


const int pinPot = 4; //analog pin 4.
const int trimPot = 5;

const int pinRelay = 2;

//probe variables
unsigned int temp = 0;
//run for 10-20 minutes to determine offset. As the thermocouple booster chips warms up the reading will rise a bit.
int calibration = 0; //temp calibration compensation * .25deg C
#define READINGNUM 20
int readings[READINGNUM];
unsigned int readingCurrent = 0;


//pins for the digits in the display
int digit[4] ={
  14,15,16,17};

int tempReadDelayTime = 750;
unsigned long lastDelay = 0;

int segments[8][7] =
{
  {
    1,0,0,0,0,0,0
  },
  {
    0,1,0,0,0,0,0
  },
  {
    0,0,1,0,0,0,0
  },
  {
    0,0,0,1,0,0,0
  },
  {
    0,0,0,0,1,0,0
  },
  {
    0,0,0,0,0,1,0
  },
  {
    0,0,0,0,0,0,1
  },
  {
    0,0,0,0,0,0,0
  }
};

//Digit Mapping
int numbers[18][7] =
{
  {
    1,1,1,1,1,1,0  }
  ,//0
  {
    0,1,1,0,0,0,0  }
  ,//1
  {
    1,1,0,1,1,0,1  }
  ,//2
  {
    1,1,1,1,0,0,1  }
  ,//3
  {
    0,1,1,0,0,1,1  }
  ,//4
  {
    1,0,1,1,0,1,1  }
  ,//5
  {
    1,0,1,1,1,1,1  }
  ,//6
  {
    1,1,1,0,0,0,0  }
  ,//7
  {
    1,1,1,1,1,1,1  }
  ,//8
  {
    1,1,1,1,0,1,1  }
  , //9
  {
    1,1,1,0,1,1,1  }
  ,//A
  {
    0,0,1,1,1,1,1  }
  ,//b
  {
    1,0,0,1,1,1,0  }
  ,//C
  {
    0,1,1,1,1,0,1  }
  ,//d
  {
    1,0,0,1,1,1,1  }
  ,//E
  {
    1,0,0,0,1,1,1  },
   //F
  {
    0,1,1,0,1,1,1},
    //H
  {
   0,0,0,1,1,1,0}
    //L
};

#define _E 14
#define _H 16
#define _L 17

int _digit = 0;
int _segment = 0;
unsigned int _setTemp = 0;
unsigned long _displayChangeDelay = 1000;
unsigned long _displayTimer = 0;


void setup() {

  //start off with all the seg pins OFF 
  pinMode(segA, OUTPUT); 
  pinMode(segB, OUTPUT); 
  pinMode(segC, OUTPUT);
  pinMode(segD, OUTPUT);
  pinMode(segE, OUTPUT);
  pinMode(segF, OUTPUT);
  pinMode(segG, OUTPUT);

  pinMode(digit[0], OUTPUT);
  pinMode(digit[1], OUTPUT);
  pinMode(digit[2], OUTPUT); 
  pinMode(digit[3], OUTPUT);
  
  //Temp Probe setup
  pinMode(pinSO, INPUT);
  pinMode(pinSCK, OUTPUT);
  pinMode(pinSSB, OUTPUT);
  digitalWrite(pinSSB, HIGH);//disable device.
  
  
  //relay
  pinMode(pinRelay, OUTPUT);
  digitalWrite(pinRelay, LOW);
  
  unsigned int tempStart = 0;
  for(int i = 0; i < 250; i++)
  {
    lightDigit(digit[0], numbers[_H]);
    lightDigit(digit[1], numbers[_E]);
    lightDigit(digit[2], numbers[_L]);
    lightDigit(digit[3], numbers[0]);
    tempStart += read_temp(pinSSB,0,calibration,1);
  }
  
  for(int i = 0; i < READINGNUM; i++)
  {
    readings[i] = 710;
  }
  
  _displayTimer = millis();
  _setTemp = readTemp();
  //Serial.begin(9600);
}




void loop(){    
  
  int test = 0;//normally 0
  
  if(test)//run a test that lights each segment one at a time to check for wiring issues.
  {
    _segment++;
    if(_segment > 7) {_segment = 0; _digit++;}
    if(_digit > 3) {_digit = 0;}
    delay(50);
    lightDigit(digit[_digit], segments[_segment]);
  }
  else
  {    
    unsigned int lastSetting = _setTemp;
    unsigned int temp =  readTemp();

    _setTemp = ReadControlPot(); 
    
    
    if(lastSetting != _setTemp)
    {
      _displayTimer = millis();
    }
    
    RunRelay(temp, _setTemp);  

    //run display last due to timing needs.
    if(_displayTimer + _displayChangeDelay > millis())
    {
      printThreeDigitNum(_setTemp);
    }
    else
    {
      //printFourDigitNum(analogRead(trimPot));
      printThreeDigitNum(temp);
      lightDigit(digit[0], numbers[15]);
    }    
  }
}


unsigned long _lastRelayChange = 0;
unsigned long _minRelayTime = 10000;
void RunRelay(unsigned int temp, unsigned int setTemp)
{
  //don't change relay state more often than )_minRelayTime. Prevents "ringing" in the case of wild readings.  
  if(_lastRelayChange + _minRelayTime < millis())
  {
    _lastRelayChange = millis();
    return;
  }
    
  //leave a degree in the middle to prevent bouncing the relay
  if(temp < setTemp)
  {
    digitalWrite(pinRelay, HIGH);
  }
  
  if(temp > setTemp)
  {
    digitalWrite(pinRelay, LOW);
  }
}

int ReadControlPot()
{  
  int setTemp = 0;  
  int potValue = 1024 - analogRead(pinPot);
  if(potValue > 5)
  { 
   setTemp = 125;
   setTemp += potValue / 30;
  }
  else
  {
    setTemp = 0; //have a swtitched off state.
  }
  return setTemp;
}


unsigned int lastTemp = 71;
int readTemp()
{
  if((millis() - lastDelay > tempReadDelayTime))
  {    
    lastDelay = millis();
    readings[readingCurrent] = read_temp(pinSSB,0,calibration,5);        
    //Serial.print("current reading: ");
    //Serial.println(readings[readingCurrent]);
    //Serial.println(buttonState);
  }
  else
  {
    return lastTemp;
  }
  
  for(int i = 0; i < READINGNUM; i++)
  {
    temp += readings[i];
  }
  
  
  temp /= READINGNUM;
  if(temp % 10 > 5) //round before truncation
  {
    temp += 10;
  }

  temp /= 10;
  temp += (analogRead(trimPot) - 512)/20;
  
  if(++readingCurrent >= READINGNUM)
  {
    readingCurrent = 0;
  }
  
  lastTemp = temp;
  return temp;
}

void printThreeDigitNum(unsigned int num)
{
  num = num % 1000;
  int h = num / 100;
  num -= h * 100;
  int t = num / 10;
  num -= t * 10;
  int o = num;


  lightDigit(digit[1], numbers[h]);
  lightDigit(digit[2], numbers[t]);
  lightDigit(digit[3], numbers[o]);

}

void printFourDigitNum(unsigned int num)
{
  
  int m= num / 1000;
  num = num % 1000;
  int h = num / 100;
  num -= h * 100;
  int t = num / 10;
  num -= t * 10;
  int o = num;


  lightDigit(digit[0], numbers[m]);
  lightDigit(digit[1], numbers[h]);
  lightDigit(digit[2], numbers[t]);
  lightDigit(digit[3], numbers[o]);

}



void resetDigits()
{
  digitalWrite(digit[0], LOW);
  digitalWrite(digit[1], LOW);
  digitalWrite(digit[2], LOW); 
  digitalWrite(digit[3], LOW);
}

void lightDigit(int digit, int pattern[])
{
  resetDigits();

  digitalWrite(digit, HIGH);
  digitalWrite(segA, !pattern[0]);
  digitalWrite(segB, !pattern[1]);
  digitalWrite(segC, !pattern[2]);
  digitalWrite(segD, !pattern[3]);
  digitalWrite(segE, !pattern[4]);
  digitalWrite(segF, !pattern[5]);
  digitalWrite(segG, !pattern[6]);
  delay(5); 
}

/* Create a function read_temp that returns an unsigned int
   with the temp from the specified pin (if multiple MAX6675).  The
   function will return 9999 if the TC is open.
  
   Usage: read_temp(int pin, int type, int error)
     pin: the CS pin of the MAX6675
     type: 0 for ˚F, 1 for ˚C
     error: error compensation in digital counts
     samples: number of measurement samples (max:10)
*/

unsigned int read_temp(int pin, int type, int error, int samples) {
  unsigned int value = 0;
  int error_tc;
  float temp;
  unsigned int temp_out;
  
  for (int i=samples; i>0; i--){
    digitalWrite(pin,LOW); // Enable device

    /* Cycle the clock for dummy bit 15 */
    digitalWrite(pinSCK,HIGH);
    digitalWrite(pinSCK,LOW);

    /* Read bits 14-3 from MAX6675 for the Temp
	 Loop for each bit reading the value and
	 storing the final value in 'temp'
    */
    for (int i=11; i>=0; i--){
	digitalWrite(pinSCK,HIGH);  // Set Clock to HIGH
	value += digitalRead(pinSO) << i;  // Read data and add it to our variable
	digitalWrite(pinSCK,LOW);  // Set Clock to LOW
    }
  
    /* Read the TC Input inp to check for TC Errors */
    digitalWrite(pinSCK,HIGH); // Set Clock to HIGH
    error_tc = digitalRead(pinSO); // Read data
    digitalWrite(pinSCK,LOW);  // Set Clock to LOW
  
    digitalWrite(pin, HIGH); //Disable Device
  }
  
  value = value/samples;  // Divide the value by the number of samples to get the average
  
  /*
     Keep in mind that the temp that was just read is on the digital scale
     from 0˚C to 1023.75˚C at a resolution of 2^12.  We now need to convert
     to an actual readable temperature (this drove me nuts until I figured
     this out!).  Now multiply by 0.25.  I tried to avoid float math but
     it is tough to do a good conversion to ˚F.  THe final value is converted
     to an int and returned at x10 power.
    
   */
  
  value = value + error;  // Insert the calibration error value
  
  if(type == 0) {  // Request temp in ˚F
    temp = ((value*0.25) * (9.0/5.0)) + 32.0;  // Convert value to ˚F (ensure proper floats!)
  } else if(type == 1) {  // Request temp in ˚C
    temp = (value*0.25);  // Multiply the value by 25 to get temp in ˚C
  }
  
  temp_out = temp*10;  // Send the float to an int (X10) for ease of printing.
  
  /* Output 9999 if there is a TC error, otherwise return 'temp' */
  if(error_tc != 0) { return 9999; } else { return temp_out; }
}


