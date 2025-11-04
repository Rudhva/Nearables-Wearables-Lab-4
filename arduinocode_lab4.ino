#include <Wire.h>
#include <MPU6050.h>   

MPU6050 mpu;

// Pin LED
const int ledPins[] = {3, 5, 6, 11};

// FSR pins
const int fsrPins[] = {A0, A1, A2, A3};

// Variabiles
int fsrValues[4];
int16_t ax, ay, az;
int16_t gx, gy, gz;
float ax_g, ay_g, az_g;
float gx_dps, gy_dps, gz_dps;

void setup() {
  Serial.begin(115200);
  Wire.begin();

  // Initialize MPU6050
  Serial.println("Initializing MPU6050...");
  mpu.initialize();

  if (!mpu.testConnection()) {
    Serial.println("Error: MPU6050 not connected!");
    while (1);
  }
  Serial.println("MPU6050 connected.");

  for (int i = 0; i < 4; i++) {
    pinMode(ledPins[i], OUTPUT);
    digitalWrite(ledPins[i], LOW); // Switch off all the LEDs at first
  }

  Serial.println("Setup successful.\n");
}

void loop() {
  // Read 4 FSR analog pins
  for (int i = 0; i < 4; i++) {
    fsrValues[i] = analogRead(fsrPins[i]);
  }

  // Read accelerometer (and gyroscope if needed)
  mpu.getMotion6(&ax, &ay, &az, &gx, &gy, &gz);
  ax_g = ax / 16384.0;
  ay_g = ay / 16384.0;
  az_g = az / 16384.0;
  gx_dps = gx / 131.0;
  gy_dps = gy / 131.0;
  gz_dps = gz / 131.0;



  // Print all the values in a CSV format on the same line
  Serial.print(fsrValues[0]); Serial.print(",");
  Serial.print(fsrValues[1]); Serial.print(",");
  Serial.print(fsrValues[2]); Serial.print(",");
  Serial.print(fsrValues[3]); Serial.print(",");
  Serial.print(ax_g); Serial.print(",");
  Serial.print(ay_g); Serial.print(",");
  Serial.print(az_g);Serial.println(",");
  Serial.print(gx_dps); Serial.print(",");
  Serial.print(gy_dps); Serial.print(",");
  Serial.print(gz_dps);
  Serial.println();
  

  //check if any command is coming on the Serial Monitor from Processing
  if (Serial.available() > 0) {
    String cmd = Serial.readStringUntil('\n');
    cmd.trim();
    if (cmd == "LEDGREEN_ON") digitalWrite(3, HIGH);
    else if (cmd == "LEDGREEN_OFF") digitalWrite(3, LOW);
    if(cmd== "LEDBLUE_ON") digitalWrite(5, HIGH);
    else if (cmd == "LEDBLUE_OFF") digitalWrite(5, LOW);
    if(cmd== "LEDRED_ON") digitalWrite(6, HIGH);
    else if (cmd == "LEDRED_OFF") digitalWrite(6, LOW);
    if(cmd== "LEDYELLOW_ON") digitalWrite(11, HIGH);
    else if (cmd == "LEDYELLOW_OFF") digitalWrite(11, LOW);
    
  } 

  delay(100); // 10 Hz sampling
}

