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
 // Read FSRs and set LED brightness individually

// FSR 0 → LED D3 (max 200 to avoid super brightness)
fsrValues[0] = analogRead(fsrPins[0]);
int ledBrightness0 = 0;
if (fsrValues[0]<15) {
  ledBrightness0 = 0;

} 
else ledBrightness0 = map(fsrValues[0], 0, 1023, 0, 200);

analogWrite(ledPins[0], ledBrightness0);

// FSR 1 → LED D5 (max 245)
fsrValues[1] = analogRead(fsrPins[1]);
int ledBrightness1 = map(fsrValues[1], 0, 1023, 0, 245);
analogWrite(ledPins[1], ledBrightness1);

// FSR 2 → LED D6 (max 255)
fsrValues[2] = analogRead(fsrPins[2]);
int ledBrightness2 = map(fsrValues[2], 0, 1023, 0, 255);
analogWrite(ledPins[2], ledBrightness2);

// FSR 3 → LED D11 (max 255)
fsrValues[3] = analogRead(fsrPins[3]);
int ledBrightness3 = map(fsrValues[3], 0, 1023, 0, 255);
analogWrite(ledPins[3], ledBrightness3);

  // Read accelerometer (and gyroscope if needed)
  mpu.getMotion6(&ax, &ay, &az, &gx, &gy, &gz);
  ax_g = ax / 16384.0;
  ay_g = ay / 16384.0;
  az_g = az / 16384.0;
  gx_dps = gx / 131.0;
  gy_dps = gy / 131.0;
  gz_dps = gz / 131.0;

  // Print all values in CSV format
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

  delay(100); // 10 Hz sampling
}
