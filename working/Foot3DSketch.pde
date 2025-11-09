import processing.serial.*;
import processing.core.PApplet;
import processing.core.PShape;

class Foot3DSketch extends PApplet {
  final PApplet parent;
  SketchWindowListener listener;

  Serial myPort;
  int SERIAL_PORT_INDEX = -1;

  float accelX = 0, accelY = 0, accelZ = 0;
  int heel, mf, mm, lf;
  int[] fsrValues = new int[4];
  String latestSerialMessage = "";

  float rotX = 0, rotY = 0, rotZ = 0;
  float smoothRotation = 0.1f;

  float baseAccelX = 0;
  float baseAccelY = 0;
  float baseAccelZ = 0;
  boolean calibrated = false;

  PShape foot;

  float navHeight = 60;
  float navButtonHeight = 32;
  float navButtonMargin = 14;
  float backBtnX, backBtnY, backBtnW = 200, backBtnH = navButtonHeight;
  float quitBtnX, quitBtnY, quitBtnW = 140, quitBtnH = navButtonHeight;
  int navButtonColor;
  int quitButtonColor;

  Foot3DSketch(PApplet parent, SketchWindowListener listener) {
    this.parent = parent;
    this.listener = listener;
  }

  public void settings() {
    size(1000, 800, P3D);
  }

  public void setup() {
    frameRate(60);
    textAlign(LEFT, BASELINE);
    smooth(8);

    navHeight = navButtonMargin * 2 + navButtonHeight;
    navButtonColor = color(82, 126, 255);
    quitButtonColor = color(244, 114, 117);

    setupSerial();

    foot = loadAssetShape("foot.obj");
    if (foot == null) {
      println("⚠️ Could not find foot.obj inside data/ – ensure the file is present.");
      exit();
      return;
    }
    foot.scale(35);
    foot.rotateX(HALF_PI);
  }

  public void draw() {
    background(12);
    lights();
    ambientLight(60, 60, 60);
    directionalLight(255, 220, 200, -0.3f, 0.4f, -1);
    pointLight(255, 180, 160, width/2, height/2, 400);

    updateRotationFromAccel();

    translate(width/2, height/1.6f, -400);
    rotateX(rotX);
    rotateY(rotY);
    rotateZ(rotZ);

    fill(242, 198, 158);
    shape(foot);

    drawHUD();
    drawNavBar();
  }

  void drawHUD() {
    camera();
    hint(DISABLE_DEPTH_TEST);
    fill(255);
    textSize(14);
    textAlign(LEFT);
    text("AccelX: " + nf(accelX, 1, 2)
       + "  AccelY: " + nf(accelY, 1, 2)
       + "  AccelZ: " + nf(accelZ, 1, 2), 12, height - 30);
    text("Latest packet: " + latestSerialMessage, 12, height - 10);
    if (calibrated) {
      text("✅ Calibrated (press C to recalibrate)", 12, height - 50);
    } else {
      text("Press C to calibrate baseline", 12, height - 50);
    }
    hint(ENABLE_DEPTH_TEST);
  }

  void drawNavBar() {
    noStroke();
    fill(255, 225);
    rect(0, 0, width, navHeight);

    backBtnX = navButtonMargin;
    backBtnY = navButtonMargin;
    backBtnH = navButtonHeight;
    quitBtnH = navButtonHeight;
    quitBtnX = width - navButtonMargin - quitBtnW;
    quitBtnY = navButtonMargin;

    drawNavButton(backBtnX, backBtnY, backBtnW, backBtnH, "Back to dashboard", navButtonColor);
    drawNavButton(quitBtnX, quitBtnY, quitBtnW, quitBtnH, "Quit app", quitButtonColor);

    fill(20, 160);
    textSize(18);
    textAlign(CENTER, CENTER);
    text("Foot 3D Viewer", width / 2, navHeight / 2);
    textAlign(LEFT, BASELINE);
  }

  void drawNavButton(float x, float y, float w, float h, String label, int btnColor) {
    fill(btnColor);
    rect(x, y, w, h, 18);
    fill(255);
    textSize(13);
    textAlign(CENTER, CENTER);
    text(label, x + w / 2, y + h / 2);
    textAlign(LEFT, BASELINE);
  }

  void mousePressed() {
    if (pointInRect(mouseX, mouseY, backBtnX, backBtnY, backBtnW, backBtnH)) {
      closeToDashboard();
      return;
    }
    if (pointInRect(mouseX, mouseY, quitBtnX, quitBtnY, quitBtnW, quitBtnH)) {
      quitApp();
      return;
    }
  }

  void keyPressed() {
    if ((key == 'c' || key == 'C')) {
      baseAccelX = accelX;
      baseAccelY = accelY;
      baseAccelZ = accelZ;
      calibrated = true;
      println("✅ Calibration complete: " + baseAccelX + ", " + baseAccelY + ", " + baseAccelZ);
    }
    if (key == ESC) {
      key = 0;
    }
  }

  void closeToDashboard() {
    exit();
  }

  void quitApp() {
    if (parent != null) {
      parent.exit();
    }
    exit();
  }

  boolean pointInRect(float px, float py, float rx, float ry, float rw, float rh) {
    return px >= rx && px <= rx + rw && py >= ry && py <= ry + rh;
  }

  void updateRotationFromAccel() {
    float adjX = accelX - baseAccelX;
    float adjY = accelY - baseAccelY;
    float adjZ = accelZ - baseAccelZ;

    float tiltX = atan2(adjY, sqrt(adjX*adjX + adjZ*adjZ));
    float tiltY = atan2(-adjX, sqrt(adjY*adjY + adjZ*adjZ));

    rotX = lerp(rotX, tiltX, smoothRotation);
    rotY = lerp(rotY, tiltY, smoothRotation);
  }

  void setupSerial() {
    println("Serial ports available:");
    String[] ports = Serial.list();
    for (int i = 0; i < ports.length; i++) {
      println("  [" + i + "] " + ports[i]);
    }
    if (ports.length == 0) {
      println("No serial ports detected.");
      return;
    }
    String chosen;
    if (SERIAL_PORT_INDEX >= 0 && SERIAL_PORT_INDEX < ports.length) {
      chosen = ports[SERIAL_PORT_INDEX];
    } else {
      chosen = ports[ports.length - 1];
    }

    println("Opening serial on " + chosen + " at 115200...");
    try {
      myPort = new Serial(this, chosen, 115200);
      myPort.bufferUntil('\n');
      println("✅ Serial opened successfully.");
    } catch (Exception e) {
      println("❌ Failed to open serial: " + e.getMessage());
    }
  }

  PShape loadAssetShape(String filename) {
    PShape loaded = null;
    if (parent != null) {
      loaded = parent.loadShape(filename);
    }
    if (loaded == null) {
      String assetPath = parent != null ? parent.dataPath(filename) : dataPath(filename);
      loaded = loadShape(assetPath);
      if (loaded == null) {
        println("⚠️ Failed to load shape " + filename + " from " + assetPath);
      }
    }
    return loaded;
  }

  void serialEvent(Serial p) {
    String line = trim(p.readStringUntil('\n'));
    if (line == null || line.length() == 0) return;
    if (!line.matches("^[0-9,\\-\\.]+$")) return;
    String[] tokens = split(line, ',');
    if (tokens.length != 10) return;

    try {
      heel = int(tokens[0]);
      mf = int(tokens[1]);
      mm = int(tokens[2]);
      lf = int(tokens[3]);
      accelX = float(tokens[4]);
      accelY = float(tokens[5]);
      accelZ = float(tokens[6]);
      latestSerialMessage = line;
    } catch (Exception e) {
      println("⚠️ Parse error: " + e.getMessage());
      return;
    }

    fsrValues[0] = lf;
    fsrValues[1] = mf;
    fsrValues[2] = mm;
    fsrValues[3] = heel - 10;
  }

  public void exit() {
    if (listener != null) {
      listener.onWindowClosed();
      listener = null;
    }
    super.exit();
  }
}
