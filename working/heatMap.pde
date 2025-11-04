// -------------------------
// heatmap_with_steps_mfp_motion.pde
// -------------------------

PImage footImg;
float[] fsrValues = new float[4];   // 0=Big Toe (LF), 1=Ball (MF), 2=Midfoot (MM), 3=Heel
float[] fsrTargets = new float[4];

float[] xOffsets = {160, 80, 70, 115};
float[] yOffsets = {180, 100, 240, 470};
String[] labels = {"Big Toe", "Ball", "Midfoot", "Heel"};

float scaleFactor;
float imgWidth, imgHeight;
float imgX = 200, imgY = 100;

// -------------------------
// Step detection variables
// -------------------------
int stepCount = 0;
float cadence = 0;
float stepThreshold = 300;
boolean stepDetected = false;

// -------------------------
// MFP calculation
// -------------------------
float cumulativeMM = 0;
float cumulativeMF = 0;
float cumulativeLF = 0;
float cumulativeHeel = 0;
float MFP = 0;

// -------------------------
// Motion detection
// -------------------------
boolean inMotion = false;
float motionThreshold = 0.15;   // adjust according to your sensor
float activityStartTime = 0;
float totalActiveTime = 0;

// -------------------------
// Data logging
// -------------------------
Table sensorData;

// -------------------------
// Heatmap setup
// -------------------------
void heatMapSetup() {
  smooth(8);
  footImg = loadImage("RightFoot.jpg");

  scaleFactor = 600.0 / footImg.height;
  imgWidth = footImg.width * scaleFactor;
  imgHeight = footImg.height * scaleFactor;

  for (int i = 0; i < fsrValues.length; i++) {
    fsrValues[i] = random(0, 1023);
    fsrTargets[i] = fsrValues[i];
  }

  textSize(16);
}

// -------------------------
// Heatmap draw
// -------------------------
void heatMapDraw() {
  image(footImg, imgX, imgY, imgWidth, imgHeight);

  // Update fsrValues with already-provided values (from serial or other files)
  // fsrValues[0] = lf, fsrValues[1] = mf, fsrValues[2] = mm, fsrValues[3] = heel

  detectStep();      // Update step count and cadence
  updateMFP();       // Update MFP calculation
  detectMotion();    // Detect motion using accelerometer

  noStroke();
  for (int i = 0; i < fsrValues.length; i++) {
    float x = imgX + xOffsets[i] * scaleFactor;
    float y = imgY + yOffsets[i] * scaleFactor;

    float val = fsrValues[i];
    float radius = map(val, 0, 1023, 40, 150);
    radius = constrain(radius, 40, 120);

    drawSoftSpot(x, y, radius, val);
  }

  drawBars();
  drawStepInfo();
  drawMotionStatus();
}

// -------------------------
// Draw soft spot on foot
// -------------------------
void drawSoftSpot(float x, float y, float radius, float val) {
  int layers = 10;
  int c = heatColor(val);
  for (int i = layers; i > 0; i--) {
    float r = radius * i / layers;
    float alpha = map(i, 0, layers, 0, 100);
    fill(red(c), green(c), blue(c), alpha);
    ellipse(x, y, r, r);
  }
}

// -------------------------
// Heat color interpolation
// -------------------------
int heatColor(float v) {
  float n = constrain(v / 1023.0, 0, 1);
  color c1 = color(0, 0, 255);
  color c2 = color(255, 255, 0);
  color c3 = color(255, 0, 0);
  if (n < 0.5) return lerpColor(c1, c2, n * 2);
  else return lerpColor(c2, c3, (n - 0.5) * 2);
}

// -------------------------
// Draw side bars for each sensor
// -------------------------
void drawBars() {
  for (int i = 0; i < fsrValues.length; i++) {
    fill(100, 200, 255);
    float barHeight = map(fsrValues[i], 0, 1023, 0, 200);
    rect(1000, 150 + i * 150, 30, -barHeight);
    fill(0);
    text(labels[i] + ": " + int(fsrValues[i]), 1040, 150 + i * 150 - barHeight);
  }
}

// -------------------------
// Step detection
// -------------------------
void detectStep() {
  boolean active = (fsrValues[0] > stepThreshold || fsrValues[3] > stepThreshold);

  if (active && !stepDetected) {
    stepCount++;
    stepDetected = true;
    float elapsedMinutes = (millis() / 60000.0);
    if (elapsedMinutes > 0) cadence = stepCount / elapsedMinutes;
  } else if (!active) {
    stepDetected = false;
  }
}

// -------------------------
// Draw step and MFP info
// -------------------------
void drawStepInfo() {
  fill(0);
  textSize(20);
  text("Step Count: " + stepCount, 50, 50);
  text("Cadence: " + int(cadence) + " steps/min", 50, 80);
  text("MFP: " + nf(MFP,1,2) + "%", 50, 110);
}

// -------------------------
// MFP calculation
// -------------------------
void updateMFP() {
  cumulativeMM += mm;
  cumulativeMF += mf;
  cumulativeLF += lf;
  cumulativeHeel += heel;

  MFP = (cumulativeMM + cumulativeMF) * 100.0 / (cumulativeMM + cumulativeMF + cumulativeLF + cumulativeHeel + 0.001);
}

// -------------------------
// Motion detection
// -------------------------
void detectMotion() {
  float accelMag = sqrt(accelX*accelX + accelY*accelY + accelZ*accelZ);

  if (accelMag > motionThreshold) {
    if (!inMotion) {
      inMotion = true;
      activityStartTime = millis();
    }
  } else {
    if (inMotion) {
      inMotion = false;
      totalActiveTime += millis() - activityStartTime;
    }
  }
}

// -------------------------
// Draw motion info (moved to top-right corner)
// -------------------------
void drawMotionStatus() {
  fill(0);
  textSize(20);
  String status = inMotion ? "In Motion" : "Standing Still";
  float activeSec = totalActiveTime / 1000.0;
  if (inMotion) activeSec += (millis() - activityStartTime) / 1000.0;
  
  // Position at top-right corner
  float xPos = width - 300;
  float yPos = 50;
  text("User Status: " + status, xPos, yPos);
  text("Active Time: " + nf(activeSec,1,2) + " s", xPos, yPos + 30);
}



