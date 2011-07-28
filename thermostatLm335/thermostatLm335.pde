const int lm335 = A0;
void setup() {
    Serial.begin(9600);
}




void loop(){    
    float AnalogV = analogRead(lm335);
    float Kelvin = (((AnalogV / 1023) * 5) * 100);
    float Celsius = Kelvin-273;
    float Fahrenheit=(Celsius)*(9/5)+32;
    Serial.print(AnalogV);
    Serial.print("Raw ");
    Serial.print(Kelvin);
    Serial.print("K ");
    Serial.print(Celsius);
    Serial.print("C ");
    Serial.print(Fahrenheit);
    Serial.print("F ");
    Serial.println();
}



