
// -------------------------
// serial.pde (Processing)
// -------------------------
import processing.serial.*;


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
    myPort = new Serial(this, "COM", 115200);
    println("Serial opened on COM3 115200");
  } catch (Exception e) {
    println("Failed to open serial on WINDOWS: " + e.getMessage());
  }
  try {
    String portName = Serial.list()[Serial.list().length - 1];
    println(portName);
    myPort = new Serial(this, portName, 115200);
    println("Serial opened on MAC");
  } catch (Exception e) {
    println("Failed to open serial on MAC: " + e.getMessage());
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
  String[] tokens = split(line, ',');
  if (tokens.length != 10) {
    println("⚠️ Invalid packet (" + tokens.length + " fields): " + line);
    return;
  }

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

    // Optional: update debug message
    latestSerialMessage = line;

  } catch (Exception e) {
    println("⚠️ Parse error: " + e.getMessage());
  }
}
