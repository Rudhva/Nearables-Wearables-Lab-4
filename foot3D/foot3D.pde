// --- 3D Foot Visualization with MPU6050 Accelerometer ---
// Rudhva Patel | Processing 3D + Serial
// ------------------------------------------------------------

import processing.serial.*;

Serial myPort;
int SERIAL_PORT_INDEX = -1; // optional override if you want to pick a port manually

// Sensor variables
float accelX = 0, accelY = 0, accelZ = 0;
float gyroX = 0, gyroY = 0, gyroZ = 0;
int heel, mf, mm, lf;
int[] fsrValues = new int[4];
String latestSerialMessage = "";

// Rotation values
float rotX = 0;
float rotY = 0;
float rotZ = 0;
float smooth = 0.1;

// Calibration
float baseAccelX = 0;
float baseAccelY = 0;
float baseAccelZ = 0;
boolean calibrated = false;

// 3D foot model
PShape foot;

void setup() {
  size(1000, 800, P3D);
  smooth(8);
  noStroke();

  // --- Serial setup (your helper function) ---
  setupSerial();

  // Load 3D foot model
  foot = loadShape("foot.obj");
  if (foot == null) {
    println("⚠️ Could not find foot.obj in the data folder!");
    exit();
  }

  // Scale and orient
  foot.scale(35);
  foot.rotateX(HALF_PI);
}

void draw() {
  background(0);
  lights();
  ambientLight(60, 60, 60);
  directionalLight(255, 220, 200, -0.3, 0.4, -1);
  pointLight(255, 180, 160, width/2, height/2, 400);

  updateRotationFromAccel();

  translate(width/2, height/1.5, -400);
  rotateX(rotX);
  rotateY(rotY);
  rotateZ(rotZ);

  fill(242, 198, 158);
  shape(foot);

  drawHUD();
}

// ------------------------------------------------------------
// ✅ Your setupSerial() function (unchanged)
// ------------------------------------------------------------
void setupSerial() {
  println("Serial ports:");
  String[] ports = Serial.list();
  for (int i = 0; i < ports.length; i++) println("  ["+i+"] "+ports[i]);
  if (ports.length == 0) { println("No serial ports found."); return; }

  String chosen;
  if (SERIAL_PORT_INDEX >= 0 && SERIAL_PORT_INDEX < ports.length) {
    chosen = ports[SERIAL_PORT_INDEX];               // <<< force by index
  } else {
    // better auto-pick: prefer usbmodem/usbserial/tty.*
    chosen = ports[ports.length - 1];
    for (String p : ports) {
      String pl = p.toLowerCase();
      if ((pl.contains("usbmodem") || pl.contains("usbserial") || pl.contains("tty."))
          && !pl.contains("bluetooth")) { chosen = p; break; }
    }
  }

  // Initialize serial as in Codice 1
  try {
    myPort = new Serial(this, "COM3", 115200);
    println("Serial opened on COM3 115200");
  } catch (Exception e) {
    println("Failed to open serial on WINDOWS: " + e.getMessage());
  }
  try {
    String portName = Serial.list()[Serial.list().length - 1];
    myPort = new Serial(this, portName, 115200);
    println("Serial opened on COM3 115200");
  } catch (Exception e) {
    println("Failed to open serial on MAC: " + e.getMessage());
  }
}

// ------------------------------------------------------------
// Serial input parsing
// ------------------------------------------------------------
void serialEvent(Serial p) {
  String line = trim(p.readStringUntil('\n'));
  if (line == null || line.length() == 0) return;
  if (!line.matches("^[0-9,\\-\\.]+$")) return;
  String[] tokens = split(line, ',');
  if (tokens.length != 10) return;

  try {
    heel    = int(tokens[0]);
    mf      = int(tokens[1]);
    mm      = int(tokens[2]);
    lf      = int(tokens[3]);
    accelX  = float(tokens[4]);
    accelY  = float(tokens[5]);
    accelZ  = float(tokens[6]);
    gyroX   = float(tokens[7]);
    gyroY   = float(tokens[8]);
    gyroZ   = float(tokens[9]);
    latestSerialMessage = line;
  } catch (Exception e) {
    println("⚠️ Parse error: " + e.getMessage());
  }

  fsrValues[0] = lf;
  fsrValues[1] = mf;
  fsrValues[2] = mm;
  fsrValues[3] = heel - 10;
}

// ------------------------------------------------------------
// Map accelerometer to rotation angles
// ------------------------------------------------------------
void updateRotationFromAccel() {
  // Apply calibration offset
  float adjX = accelX - baseAccelX;
  float adjY = accelY - baseAccelY;
  float adjZ = accelZ - baseAccelZ;

  // Convert adjusted values into tilt angles
  float tiltX = atan2(adjY, sqrt(adjX*adjX + adjZ*adjZ));
  float tiltY = atan2(-adjX, sqrt(adjY*adjY + adjZ*adjZ));

  // Smooth transitions for stable movement
  rotX = lerp(rotX, tiltX, smooth);
  rotY = lerp(rotY, tiltY, smooth);
}

// ------------------------------------------------------------
// Debug HUD
// ------------------------------------------------------------
void drawHUD() {
  camera();
  hint(DISABLE_DEPTH_TEST);
  fill(255);
  textSize(14);
  textAlign(LEFT);
  text("AccelX: " + nf(accelX, 1, 2) + 
       "  AccelY: " + nf(accelY, 1, 2) + 
       "  AccelZ: " + nf(accelZ, 1, 2), 10, height - 30);
  text("Latest packet: " + latestSerialMessage, 10, height - 10);

  if (calibrated)
    text("✅ Calibrated (Press 'C' again to recalibrate)", 10, height - 50);
  else
    text("Press 'C' to calibrate baseline", 10, height - 50);

  hint(ENABLE_DEPTH_TEST);
}

// ------------------------------------------------------------
// Calibration trigger
// ------------------------------------------------------------
void keyPressed() {
  if (key == 'c' || key == 'C') {
    baseAccelX = accelX;
    baseAccelY = accelY;
    baseAccelZ = accelZ;
    calibrated = true;
    println("✅ Calibration complete:");
    println("  baseAccelX=" + baseAccelX);
    println("  baseAccelY=" + baseAccelY);
    println("  baseAccelZ=" + baseAccelZ);
  }
}
