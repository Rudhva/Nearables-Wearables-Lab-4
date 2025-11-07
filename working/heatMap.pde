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
// Graph data
// -------------------------
int graphLength = 150;                // number of data points shown per graph
float[][] fsrHistory = new float[4][graphLength];  // history for each FSR
float graphWidth = 250;
float graphHeight = 100;
float graphX = 600;
float graphYStart = 200;

// -------------------------
// Data logging
// -------------------------
Table sensorData;

// -------------------------
// Heatmap setup
// -------------------------
void heatMapSetup() {
  smooth(8);
  footImg = loadImage("foot.jpg");

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
  drawFSRGraphs();
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
// Update and draw FSR graphs
// -------------------------
void drawFSRGraphs() {
  for (int i = 0; i < 4; i++) {
    // Shift old data
    for (int j = 0; j < graphLength - 1; j++) {
      fsrHistory[i][j] = fsrHistory[i][j + 1];
    }
    // Add new reading
    fsrHistory[i][graphLength - 1] = fsrValues[i];

    // Draw graph background
    float gx = graphX;
    float gy = graphYStart + i * (graphHeight + 40);
    fill(245);
    stroke(0);
    rect(gx - 10, gy - graphHeight - 10, graphWidth + 20, graphHeight + 20);

    // Draw label
    fill(0);
    text(labels[i], gx, gy - graphHeight - 20);

    // Draw graph line
    noFill();
    stroke(0, 120, 255);
    beginShape();
    for (int j = 0; j < graphLength; j++) {
      float x = gx + map(j, 0, graphLength - 1, 0, graphWidth);
      float y = gy - map(fsrHistory[i][j], 0, 1023, 0, graphHeight);
      vertex(x, y);
    }
    endShape();

    // Axis line
    stroke(0);
    line(gx, gy, gx + graphWidth, gy);
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
// -------------------------
// Motion detection (fixed)
// -------------------------
float baselineAccel = 1.0;        // average gravity magnitude (in g)
float smoothedAccel = 0;          // low-pass filter variable
float accelAlpha = 0.1;           // smoothing factor (0.0-1.0)
float currentSpeed = 0;           // estimated motion intensity (arbitrary units)
float speedDecay = 0.95;          // speed slows down over time

void detectMotion() {
  // Calculate acceleration magnitude (normalized around 1g)
  float accelMag = sqrt(accelX*accelX + accelY*accelY + accelZ*accelZ);

  // Smooth acceleration
  smoothedAccel = lerp(smoothedAccel, accelMag, accelAlpha);

  // Compute motion intensity (difference from gravity)
  float motion = abs(smoothedAccel - baselineAccel);

  // Integrate motion into a "speed" variable
  currentSpeed = currentSpeed * speedDecay + motion * 5.0; // scale factor adjusts responsiveness

  // Motion threshold determines if we're moving
  if (motion > motionThreshold) {
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
// Draw motion info (with speed)
// -------------------------
void drawMotionStatus() {
  fill(0);
  textSize(20);
  String status = inMotion ? "In Motion" : "Standing Still";
  float activeSec = totalActiveTime / 1000.0;
  if (inMotion) activeSec += (millis() - activityStartTime) / 1000.0;
  
  float xPos = width - 300;
  float yPos = 50;
  
  text("User Status: " + status, xPos, yPos);
  text("Speed: " + nf(currentSpeed, 1, 2), xPos, yPos + 30);
  text("Active Time: " + nf(activeSec, 1, 2) + " s", xPos, yPos + 60);
}
