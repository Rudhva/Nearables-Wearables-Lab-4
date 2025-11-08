
// -------------------------
// serial.pde (Processing)
// -------------------------
import processing.serial.*;
boolean useFakeData = true;

final int SERIAL_PORT_INDEX = 7; 

Serial myPort;
String latestSerialMessage = "";

// Buffers for latest sensor readings
int heel, mf, lf, mm;
float accelX, accelY, accelZ;
float gyroX, gyroY, gyroZ;

void setupSerial() {
  println("Serial ports:");
  String[] ports = Serial.list();
  for (int i = 0; i < ports.length; i++) println("  [" + i + "] " + ports[i]);
  if (ports.length == 0) { 
    println("No serial ports found."); 
    return; 
  }

  // Choose a port (either by index or auto-pick)
  String chosen;
  if (SERIAL_PORT_INDEX >= 0 && SERIAL_PORT_INDEX < ports.length) {
    chosen = ports[SERIAL_PORT_INDEX];
  } else {
    chosen = ports[ports.length - 1];
  }

  println("Opening serial on " + chosen + " at 115200...");
  try {
    myPort = new Serial(this, chosen, 115200);
    println("✅ Serial opened successfully!");
  } catch (Exception e) {
    println("❌ Failed to open serial: " + e.getMessage());
  }
}



void readSerial() {
  if (myPort == null) return;
  if (myPort.available() <= 0) return;

  String line = myPort.readStringUntil('\n');
  if (line == null) return;

  line = trim(line);
  if (line.length() == 0) return;
  

  // Example expected input:
  // "512,623,421,870,15,-22,101,-5,2,-3"
  if (!line.matches("^[0-9,\\-\\.]+$")) return;
  String[] tokens = split(line, ',');
  if (tokens.length != 10) {
    println("⚠️ Invalid packet (" + tokens.length + " fields): " + line);
    return;
  }

  try { 
    heel    = int(tokens[0]);
    mf      = int(tokens[3]);
    mm      = int(tokens[1]);
    lf      = int(tokens[2]);
    accelX  = float(tokens[4]);
    accelY  = float(tokens[5]);
    accelZ  = float(tokens[6]);
    gyroX   = float(tokens[7]);
    gyroY   = float(tokens[8]);
    gyroZ   = float(tokens[9]);

    // Optional: update debug message
    latestSerialMessage = line;

  } catch (Exception e) {
    println("⚠️ Parse error: " + e.getMessage());
  }
  fsrValues[0] = lf;   // Big Toe
  fsrValues[1] = mf;   // Ball
  fsrValues[2] = mm;   // Midfoot
  fsrValues[3] = heel - 10;
}



// -------------------------
// Random realistic fallback
// -------------------------
void randomInput() {
  // simulate foot pressure pattern: heel + ball dominant, midfoot low
  float t = millis() / 1000.0;
  float stepPhase = sin(t * 2.0); // smooth walking rhythm

  // Add some noise
  float noiseScale = 50;

  heel = int(700 + 200 * max(0, -stepPhase) + random(-noiseScale, noiseScale));
  mf   = int(500 + 250 * max(0, stepPhase) + random(-noiseScale, noiseScale));
  lf   = int(400 + 180 * max(0, stepPhase) + random(-noiseScale, noiseScale));
  mm   = int(150 + 80  * abs(sin(t * 1.5)) + random(-noiseScale / 2, noiseScale / 2));

  // Simulate accelerometer motion
  accelX = 0.05 * sin(t * 4) + random(-2, 2);
  accelY = 0.07 * cos(t * 3) + random(-0.02, 0.02);
  accelZ = 1.0 + 0.05 * sin(t * 2) + random(-0.02, 0.02); // around 1g

  // Gyro values fluctuate slightly
  gyroX = random(-5, 5);
  gyroY = random(-5, 5);
  gyroZ = random(-5, 5);

  fsrValues[0] = lf;
  fsrValues[1] = mf;
  fsrValues[2] = mm;
  fsrValues[3] = heel - 10;

  latestSerialMessage = nf(heel, 1, 0) + "," + nf(mf, 1, 0) + "," + nf(mm, 1, 0) + "," + nf(lf, 1, 0);
}
