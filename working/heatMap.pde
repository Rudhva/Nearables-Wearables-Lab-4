// -------------------------
// heatmap_with_steps_mfp_motion.pde
// -------------------------

PImage footImg;
float[] fsrValues = new float[4];   // 0=Big Toe (LF), 1=Ball (MF), 2=Midfoot (MM), 3=Heel
float[] fsrTargets = new float[4];

float[] xOffsets = {160, 80, 70, 115};
float[] yOffsets = {180, 100, 240, 470};
String[] labels = {" Forefoot", "Medial Forefoot", "Midfoot", "Heel"};

// -------------------------
// Layout + palette
// -------------------------
color bgColor = color(241, 244, 252);
color cardColor = color(255);
color headingColor = color(26, 33, 54);
color mutedTextColor = color(103, 112, 130);
color accentPrimary = color(82, 126, 255);
color accentSecondary = color(254, 157, 74);
color alertColor = color(244, 114, 117);
color successColor = color(45, 212, 191);

float heatPanelX = 40;
float heatPanelY = 150;
float heatPanelWidth = 520;
float heatPanelHeight = 580;

float rightPanelX = 600;
float rightPanelWidth = 520;
float rightColumnSpacing = 24;
float gameButtonX = 0;
float gameButtonY = 0;
float gameButtonWidth = 160;
float gameButtonHeight = 48;
float gameButtonSpacing = 16;
float view3DButtonX = 0;
float view3DButtonY = 0;
float view3DButtonWidth = 180;
float view3DButtonHeight = 48;

String fsrUnitAbbrev = "FSR";
String fsrAxisLabel = "FSR units (0-1023)";
String graphTimeLabel = "Time (older -> now)";
String accelSensorLabel = "MPU-6050 (GY-521)";
String accelUnitLabel = "g";

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
long lastStepTimeMs = -1000;
final long MIN_STEP_INTERVAL_MS = 250;
final int STEP_HISTORY_SIZE = 12;
float[] stepTimestamps = new float[STEP_HISTORY_SIZE];
int stepTimestampCount = 0;

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
float graphHeight = 60;

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
  float maxFootWidth = heatPanelWidth - 120;
  float maxFootHeight = heatPanelHeight - 160;
  float scaleW = maxFootWidth / footImg.width;
  float scaleH = maxFootHeight / footImg.height;
  scaleFactor = min(scaleW, scaleH);
  imgWidth = footImg.width * scaleFactor;
  imgHeight = footImg.height * scaleFactor;
  imgX = heatPanelX + (heatPanelWidth - imgWidth) / 2;
  imgY = heatPanelY + 100;

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
  background(bgColor);

  detectStep();      // Update step count and cadence
  updateMFP();       // Update MFP calculation
  detectMotion();    // Detect motion using accelerometer

  drawStepInfo();
  drawHeatPanel();
  float motionBottom = drawMotionStatus();
  float barsBottom = drawBars(motionBottom + rightColumnSpacing);
  drawFSRGraphs(barsBottom + rightColumnSpacing);
  drawActionButtons();
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

void drawHeatPanel() {
  float radius = 28;
  drawCard(heatPanelX, heatPanelY, heatPanelWidth, heatPanelHeight, radius);

  fill(mutedTextColor);
  textSize(13);
  text("Pressure Map", heatPanelX + 32, heatPanelY + 38);
  fill(headingColor);
  textSize(26);
  text("Foot Heatmap", heatPanelX + 32, heatPanelY + 70);

  imgX = heatPanelX + (heatPanelWidth - imgWidth) / 2;
  imgY = heatPanelY + 110;
  image(footImg, imgX, imgY, imgWidth, imgHeight);

  noStroke();
  for (int i = 0; i < fsrValues.length; i++) {
    float x = imgX + xOffsets[i] * scaleFactor;
    float y = imgY + yOffsets[i] * scaleFactor;

    float val = fsrValues[i];
    float radiusSpot = map(val, 0, 1023, 40, 150);
    radiusSpot = constrain(radiusSpot, 40, 120);

    drawSoftSpot(x, y, radiusSpot, val);
  }

  drawHeatLegend(heatPanelX + 32, heatPanelY + heatPanelHeight - 60);
}

void drawHeatLegend(float x, float y) {
  float legendWidth = heatPanelWidth - 64;
  float legendHeight = 12;
  int steps = 60;
  noStroke();
  for (int i = 0; i < steps; i++) {
    float t = i / float(steps - 1);
    fill(heatColor(t * 1023));
    float segmentWidth = legendWidth / steps;
    rect(x + i * segmentWidth, y+10, segmentWidth + 1, legendHeight, 6);
  }
  textSize(12);
  fill(mutedTextColor);
  textAlign(LEFT);
  text("Low", x, y + 35);
  textAlign(RIGHT);
  text("High", x + legendWidth, y + 35);
  textAlign(LEFT);
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
float drawBars(float startY) {
  float cardHeight = 78;  // ↑ slightly taller than before (was 68)
  float spacing = 18;     // ↑ a little more vertical spacing
  float contentX = rightPanelX + 30;
  float trackWidth = rightPanelWidth - 60;
  float lastBottom = startY;

  for (int i = 0; i < fsrValues.length; i++) {
    float cardY = startY + i * (cardHeight + spacing);
    drawCard(rightPanelX, cardY, rightPanelWidth, cardHeight, 20);

    float value = fsrValues[i];
    float pct = constrain(value / 1023.0, 0, 1);

    fill(mutedTextColor);
    textSize(13);
    text(labels[i].toUpperCase(), contentX, cardY + 26);

    fill(headingColor);
    textSize(24);
    text(int(value) + " " + fsrUnitAbbrev, contentX, cardY + 45);

    float trackY = cardY + cardHeight - 26;
    noStroke();
    fill(230, 234, 245);
    rect(contentX, trackY, trackWidth, 10, 8);
    fill(accentPrimary);
    rect(contentX, trackY, trackWidth * pct, 10, 8);

    textAlign(RIGHT);
    fill(mutedTextColor);
    textSize(12);
    text(int(pct * 100) + "%", rightPanelX + rightPanelWidth - 20, cardY + 32);
    textAlign(LEFT);

    lastBottom = cardY + cardHeight;
  }

  return lastBottom;
}
// -------------------------
// Update and draw FSR graphs
// -------------------------
void drawFSRGraphs(float startY) {
  int cardsPerRow = 2;
  float horizontalPadding = 24;
  float cardSpacing = 16;
  float cardRadius = 22;
  float cardHeight = graphHeight + 64;
  float cardWidth = (rightPanelWidth - horizontalPadding * 2 - cardSpacing) / cardsPerRow;
  float innerPadding = 22;

  for (int i = 0; i < fsrValues.length; i++) {
    // Shift old data
    for (int j = 0; j < graphLength - 1; j++) {
      fsrHistory[i][j] = fsrHistory[i][j + 1];
    }
    // Add new reading
    fsrHistory[i][graphLength - 1] = fsrValues[i];

    int row = i / cardsPerRow;
    int col = i % cardsPerRow;
    float cardX = rightPanelX + horizontalPadding + col * (cardWidth + cardSpacing);
    float cardY = startY + row * (cardHeight + cardSpacing);

    drawCard(cardX, cardY, cardWidth, cardHeight, cardRadius);

    float labelX = cardX + innerPadding;
    float labelY = cardY + 30;

    fill(mutedTextColor);
    textSize(12);
    text(labels[i] + " trend", labelX, labelY);

    textAlign(RIGHT);
    fill(headingColor);
    text("Now " + int(fsrValues[i]) + " " + fsrUnitAbbrev, cardX + cardWidth - innerPadding, labelY);
    textAlign(LEFT);

    float graphLeft = cardX + innerPadding;
    float graphRight = cardX + cardWidth - innerPadding;
    float graphBottom = cardY + cardHeight - innerPadding;
    float graphTop = graphBottom - graphHeight;
    float graphW = graphRight - graphLeft;

    stroke(229, 232, 242);
    strokeWeight(1);
    for (int g = 0; g <= 4; g++) {
      float gy = lerp(graphBottom, graphTop, g / 4.0);
      line(graphLeft, gy, graphLeft + graphW, gy);
    }

    noFill();
    stroke(accentPrimary);
    strokeWeight(2);
    beginShape();
    for (int j = 0; j < graphLength; j++) {
      float x = graphLeft + map(j, 0, graphLength - 1, 0, graphW);
      float y = map(fsrHistory[i][j], 0, 1023, graphBottom, graphTop);
      vertex(x, y);
    }
    endShape();

    noStroke();
    fill(accentSecondary);
    float latestY = map(fsrValues[i], 0, 1023, graphBottom, graphTop);
    ellipse(graphLeft + graphW, latestY, 8, 8);

    // Axis labels for clarity
    fill(mutedTextColor);
    textSize(11);
    textAlign(CENTER);
    text(graphTimeLabel, graphLeft + graphW / 2.0, graphBottom + 18);

    pushMatrix();
    translate(cardX + 12, (graphTop + graphBottom) / 2.0);
    rotate(-HALF_PI);
    text(fsrAxisLabel, 0, 0);
    popMatrix();

    textAlign(LEFT);
  }
}

// -------------------------
// Step detection
// -------------------------
void detectStep() {
  float contact = max(fsrValues[0], fsrValues[3]);
  boolean active = contact > stepThreshold;
  long now = millis();

  if (active) {
    if (!stepDetected && now - lastStepTimeMs >= MIN_STEP_INTERVAL_MS) {
      stepDetected = true;
      lastStepTimeMs = now;
      recordStep(now);
    }
  } else {
    stepDetected = false;
  }

  cadence = computeCadence();
}

void recordStep(long timestampMs) {
  stepCount++;
  addStepTimestamp(timestampMs);
}

void addStepTimestamp(long timestampMs) {
  for (int i = STEP_HISTORY_SIZE - 1; i > 0; i--) {
    stepTimestamps[i] = stepTimestamps[i - 1];
  }
  stepTimestamps[0] = timestampMs;
  if (stepTimestampCount < STEP_HISTORY_SIZE) {
    stepTimestampCount++;
  }
}

float computeCadence() {
  if (stepTimestampCount < 2) return 0;
  float newest = stepTimestamps[0];
  float oldest = stepTimestamps[stepTimestampCount - 1];
  float durationSec = (newest - oldest) / 1000.0;
  if (durationSec <= 0) return 0;
  float intervals = stepTimestampCount - 1;
  return (intervals / durationSec) * 60.0;
}

// -------------------------
// Draw insight cards (steps, cadence, MFP)
// -------------------------
void drawStepInfo() {
  float spacing = 16;
  float cardWidth = (heatPanelWidth - spacing * 2) / 3.0;
  float cardHeight = 90;
  float cardY = 30;

  drawStepCadenceCard(heatPanelX, cardY, cardWidth, cardHeight);

  String gaitType = determineGaitType();
  drawGaitCard(heatPanelX + cardWidth + spacing, cardY, cardWidth, cardHeight, gaitType);

  String mfpValue = nf(MFP, 1, 1) + "%";
  drawMetricCard(heatPanelX + 2 * (cardWidth + spacing), cardY, cardWidth, cardHeight,
                 "MFP", mfpValue, "forefoot load (%)");
}

void drawStepCadenceCard(float x, float y, float w, float h) {
  drawCard(x, y, w, h, 18);
  fill(mutedTextColor);
  textSize(12);
  text("STEP COUNT", x + 18, y + 24);
  fill(headingColor);
  textSize(30);
  text(str(stepCount), x + 18, y + 60);
  fill(mutedTextColor);
  textSize(12);
  text("Cadence: " + nf(cadence, 2, 1) + " steps / min", x + 18, y + h - 16);
}

void drawMetricCard(float x, float y, float w, float h, String label, String value, String helper) {
  drawCard(x, y, w, h, 18);
  fill(mutedTextColor);
  textSize(12);
  text(label.toUpperCase(), x + 18, y + 24);
  fill(headingColor);
  textSize(30);
  text(value, x + 18, y + 60);
  fill(mutedTextColor);
  textSize(12);
  text(helper, x + 18, y + h - 16);
}

void drawCard(float x, float y, float w, float h, float radius) {
  noStroke();
  fill(0, 18);
  rect(x, y + 6, w, h, radius);
  fill(cardColor);
  rect(x, y, w, h, radius);
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
float lastMotionDelta = 0;        // most recent accel delta in g

void detectMotion() {
  // Calculate acceleration magnitude (normalized around 1g)
  float accelMag = sqrt(accelX*accelX + accelY*accelY + accelZ*accelZ);

  // Smooth acceleration
  smoothedAccel = lerp(smoothedAccel, accelMag, accelAlpha);

  // Compute motion intensity (difference from gravity)
  float motion = abs(smoothedAccel - baselineAccel);
  lastMotionDelta = motion;

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
float drawMotionStatus() {
  float cardX = rightPanelX;
  float cardY = 20;
  float cardW = rightPanelWidth;
  float cardH = 100;  // ↓ shortened from 140 to make room for other tiles
  float radius = 22;

  drawCard(cardX, cardY, cardW, cardH, radius);

  String status = inMotion ? "In Motion" : "Idle";
  color statusColor = inMotion ? successColor : alertColor;
  float activeSec = totalActiveTime / 1000.0;
  if (inMotion) activeSec += (millis() - activityStartTime) / 1000.0;

  fill(mutedTextColor);
  textSize(12);
  text("Motion Status", cardX + 28, cardY + 24);

  fill(statusColor);
  textSize(28);
  text(status, cardX + 28, cardY + 58);

  fill(mutedTextColor);
  textSize(13);
  //text("Intensity: " + nf(currentSpeed, 1, 2) + " g", cardX + 28, cardY + 84);

  textAlign(RIGHT);
  fill(headingColor);
  textSize(20);
  text("Active " + nf(activeSec, 1, 1) + "s", cardX + cardW - 28, cardY + 52);
  textSize(11);
  fill(mutedTextColor);
  textAlign(LEFT);

  return cardY + cardH;
}

boolean isPointInsideGameButton(float x, float y) {
  return x >= gameButtonX && x <= gameButtonX + gameButtonWidth &&
         y >= gameButtonY && y <= gameButtonY + gameButtonHeight;
}



// -------------------------
// Toggle threshold UI (bottom-left corner)
// -------------------------
void drawActionButtons() {
  float baseY = height - view3DButtonHeight - 30;
  view3DButtonX = heatPanelX + 30;
  view3DButtonY = baseY;

  drawViewIn3DButton(view3DButtonX, view3DButtonY, view3DButtonWidth, view3DButtonHeight);

  gameButtonY = baseY;
  gameButtonX = view3DButtonX + view3DButtonWidth + gameButtonSpacing;
  drawGameLaunchButton(gameButtonX, gameButtonY, gameButtonWidth, gameButtonHeight);
}

void drawViewIn3DButton(float x, float y, float w, float h) {
  boolean hovered = isPointInsideView3DButton(mouseX, mouseY);
  fill(hovered ? accentSecondary : accentPrimary);
  noStroke();
  rect(x, y, w, h, 18);

  fill(255);
  textSize(14);
  textAlign(CENTER, CENTER);
  text("View in 3D", x + w / 2, y + h / 2);
  textAlign(LEFT);
}

void drawGameLaunchButton(float startX, float startY, float width, float height) {
  gameButtonX = startX;
  gameButtonY = startY;
  gameButtonWidth = width;
  gameButtonHeight = height;

  boolean hovered = isPointInsideGameButton(mouseX, mouseY);
  fill(hovered ? accentSecondary : accentPrimary);
  noStroke();
  rect(gameButtonX, gameButtonY, gameButtonWidth, gameButtonHeight, 18);

  fill(255);
  textSize(14);
  textAlign(CENTER, CENTER);
  text("Play Space Jumper", gameButtonX + gameButtonWidth / 2, gameButtonY + gameButtonHeight / 2);
  textAlign(LEFT);
}

void drawGaitCard(float x, float y, float w, float h, String gaitType) {
  drawCard(x, y, w, h, 18);
  fill(mutedTextColor);
  textSize(12);
  text("Gait Type", x + 18, y + 24);

  fill(headingColor);
  textSize(24);
  text(gaitType, x + 18, y + 54);

  fill(mutedTextColor);
  textSize(12);
  text("Based on dominant FSR zone", x + 18, y + h - 16);
}

String determineGaitType() {
  if (fsrValues == null || fsrValues.length < 4) return "Unknown";

  // Assign meaning to sensors
  float lf   = fsrValues[0];  // Lateral Forefoot (Big Toe side)
  float mf   = fsrValues[1];  // Medial Forefoot
  float mm   = fsrValues[2];  // Medial Midfoot
  float heel = fsrValues[3];  // Heel

  // Compute total force to normalize
  float total = lf + mf + mm + heel + 0.001;

  // --- Calculate Medial Force Percentage (MFP) ---
  float MFP = ((mm + mf) * 100.0) / total;

  // --- Optional: compute region percentages for context ---
  float heelPct = heel / total;
  float forePct = (lf + mf) / total;
  float midPct  = mm / total;

  // --- Classify gait based on MFP and force distribution ---
  if (MFP > 55) {
    return "In-Toeing";          // more pressure on medial side
  }
  else if (MFP < 35 && heelPct > 0.4) {
    return "Heel Walking";       // mostly heel contact, low medial load
  }
  else if (MFP < 35 && forePct > 0.4) {
    return "Out-Toeing";         // lateral side dominant
  }
  else if (forePct > 0.6 && heelPct < 0.25) {
    return "Tiptoeing";          // forefoot only
  }
  else if (MFP >= 40 && MFP <= 50) {
    return "Normal Gait";        // balanced medial-lateral
  }
  else {
    return "Flat Footed / Transitional"; // fallback
  }
}




boolean isPointInsideView3DButton(float x, float y) {
  return x >= view3DButtonX && x <= view3DButtonX + view3DButtonWidth &&
         y >= view3DButtonY && y <= view3DButtonY + view3DButtonHeight;
}

// Handle mouse click toggle
void mousePressed() {
  if (isPointInsideGameButton(mouseX, mouseY)) {
    launchGameWindow();
    return;
  }
  if (isPointInsideView3DButton(mouseX, mouseY)) {
    launchFoot3DWindow();
    return;
  }

  float toggleX = width - 20;
  float toggleY = 20;
  float toggleSize = 16;

  if (dist(mouseX, mouseY, toggleX, toggleY) < toggleSize / 2) {
    useFakeData = !useFakeData;
    println("Data mode: " + (useFakeData ? "FAKE (randomInput)" : "REAL (readSerial)"));
  }
}
