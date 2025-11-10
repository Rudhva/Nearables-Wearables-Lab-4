import processing.core.PApplet;
import processing.core.PShape;

class Foot3DSketch extends PApplet {
  final PApplet parent;
  SketchWindowListener listener;

  // --- Live sensor data ---
  float accelX, accelY, accelZ;
  int[] fsrValues = new int[4];  // 0=big toe, 1=ball, 2=midfoot, 3=heel
  String latestSerialMessage = "";

  // --- 3D rotation ---
  float rotX = 0, rotY = 0;
  float smoothRotation = 0.15f;

  // --- Calibration ---
  float baseAccelX = 0, baseAccelY = 0, baseAccelZ = 0;
  boolean calibrated = false;

  // --- 3D foot model ---
  PShape foot;

  // --- UI ---
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

    // Load 3D model
    foot = loadAssetShape("foot.obj");
    if (foot == null) {
      println("⚠️ foot.obj missing in data/");
      exit();
    }
    foot.scale(35);
    foot.rotateX(HALF_PI);
  }

  public void draw() {
    background(12);
    lights();
    ambientLight(80, 80, 80);
    directionalLight(255, 220, 200, -0.3f, 0.4f, -1);

    // Update foot orientation
    updateRotationFromAccel();

    // --- Draw foot ---
    pushMatrix();
    translate(width/2, height/1.6f, -400);
    rotateX(rotX);
    rotateY(rotY);
    fill(242, 198, 158);
    noStroke();
    shape(foot);

    drawPressurePoints();
    popMatrix();

    drawHUD();
    drawNavBar();
  }

  // --- Called by parent sketch with real sensor data ---
  public void updateSensorValues(float ax, float ay, float az, float[] fsr, String msg) {
  this.accelX = ax;
  this.accelY = ay;
  this.accelZ = az;
  if (fsr != null && fsr.length == 4) {
    for (int i = 0; i < 4; i++) fsrValues[i] = (int)fsr[i];  // convert to int
  }
  this.latestSerialMessage = msg;
}

void drawPressurePoints() {
  pushStyle();

  // Corrected offsets for right foot bottom view
  // Format: {x (left-right), y (up-down), z (front-back)}
  float[][] offsets = {
    { 70, -10, -50 },   //LATERAL
    { 20, -10, -150 }, //BIG TOE
    { -20, -10, -30 },     // MIDFOOT
    { 0, -10, 140 }       // HEEL
  };

  float sphereBaseSize = 18;

  colorMode(HSB, 255);

  for (int i = 0; i < 4; i++) {
    float intensity = constrain(map(fsrValues[i], 0, 1023, 50, 255), 50, 255);
    float radius = map(fsrValues[i], 0, 1023, sphereBaseSize, sphereBaseSize * 2.5f);

    int c;
    if (fsrValues[i] < 512) c = color(180, 255, intensity);      // blue
    else if (fsrValues[i] < 768) c = color(60, 255, intensity);  // yellow
    else c = color(0, 255, intensity);                            // red

    fill(c, 200);
    noStroke();

    pushMatrix();
    translate(offsets[i][0], offsets[i][1], offsets[i][2]);
    sphere(radius);
    popMatrix();
  }

  popStyle();
}




  void drawHUD() {
    camera();
    hint(DISABLE_DEPTH_TEST);
    fill(255);
    textSize(14);
    textAlign(LEFT);

    text("FSR: " + fsrValues[0] + ", " + fsrValues[1] + ", " + fsrValues[2] + ", " + fsrValues[3],
         12, height - 70);

    text("AccelX: " + nf(accelX, 1, 2) +
         "  AccelY: " + nf(accelY, 1, 2) +
         "  AccelZ: " + nf(accelZ, 1, 2), 12, height - 50);

    text("Latest packet: " + latestSerialMessage, 12, height - 30);

    text(calibrated ? "✅ Calibrated (press C to recalibrate)"
                    : "Press C to calibrate baseline", 12, height - 10);

    hint(ENABLE_DEPTH_TEST);
  }

  void drawNavBar() {
    camera();
    hint(DISABLE_DEPTH_TEST);
    noStroke();
    fill(255, 235);
    rect(0, 0, width, navHeight);

    backBtnX = navButtonMargin;
    backBtnY = navButtonMargin;
    quitBtnX = width - navButtonMargin - quitBtnW;
    quitBtnY = navButtonMargin;

    drawNavButton(backBtnX, backBtnY, backBtnW, backBtnH, "Back to Dashboard", navButtonColor);
    drawNavButton(quitBtnX, quitBtnY, quitBtnW, quitBtnH, "Quit App", quitButtonColor);

    fill(20, 160);
    textSize(18);
    textAlign(CENTER, CENTER);
    text("Foot 3D Viewer", width / 2, navHeight / 2);
    hint(ENABLE_DEPTH_TEST);
  }

  void drawNavButton(float x, float y, float w, float h, String label, int btnColor) {
    fill(btnColor);
    rect(x, y, w, h, 18);
    fill(255);
    textSize(13);
    textAlign(CENTER, CENTER);
    text(label, x + w / 2, y + h / 2);
  }

  void mousePressed() {
    if (pointInRect(mouseX, mouseY, backBtnX, backBtnY, backBtnW, backBtnH)) {
      if (listener != null) listener.onWindowClosed();
      surface.stopThread();
      dispose();
      return;
    }
    if (pointInRect(mouseX, mouseY, quitBtnX, quitBtnY, quitBtnW, quitBtnH)) {
      if (parent != null) parent.exit();
      exit();
    }
  }

  void keyPressed() {
    if (key == 'c' || key == 'C') {
      baseAccelX = accelX;
      baseAccelY = accelY;
      baseAccelZ = accelZ;
      calibrated = true;
      println("✅ Calibrated baseline: " + baseAccelX + ", " + baseAccelY + ", " + baseAccelZ);
    }
    if (key == ESC) key = 0;
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

  PShape loadAssetShape(String filename) {
    PShape s = null;
    if (parent != null) s = parent.loadShape(filename);
    if (s == null) {
      String path = parent != null ? parent.dataPath(filename) : dataPath(filename);
      s = loadShape(path);
      if (s == null) println("⚠️ Failed to load shape " + filename + " from " + path);
    }
    return s;
  }

  boolean pointInRect(float px, float py, float rx, float ry, float rw, float rh) {
    return px >= rx && px <= rx + rw && py >= ry && py <= ry + rh;
  }

  public void exit() {
    if (listener != null) listener.onWindowClosed();
    super.exit();
  }
}
