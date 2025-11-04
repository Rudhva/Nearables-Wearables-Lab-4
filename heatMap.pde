PImage footImg;
float[] fsrValues = new float[4]; 
float[] fsrTargets = new float[4]; 

// Original offsets from top-left of the image
float[] xOffsets = {170, 45, 150, 90};
float[] yOffsets = {170, 200, 265, 470};

// Labels for left foot
String[] labels = {"LF", "MF", "MM", "Heel"};

// Scaling factors and position
float scaleFactor;
float imgWidth, imgHeight;
float imgX = 200, imgY = 100;

void heatMapSetUp() {
  footImg = loadImage("foot.jpg"); // put in 'data' folder

  // Scale foot image to fill more of the window
  scaleFactor = 600.0 / footImg.height;
  imgWidth = footImg.width * scaleFactor;
  imgHeight = footImg.height * scaleFactor;

  // Initialize FSR values and targets
  for (int i = 0; i < fsrValues.length; i++) {
    fsrValues[i] = random(0, 1023);
    fsrTargets[i] = fsrValues[i];
  }

  noStroke();
  textSize(16);
  fill(0);
}

void heatMapDraw() {
  image(footImg, imgX, imgY, imgWidth, imgHeight);

  // Gradually update fsrValues
  for (int i = 0; i < fsrValues.length; i++) {
    fsrValues[i] += (fsrTargets[i] - fsrValues[i]) * 0.05;
  }

  // Occasionally pick new target every 60 frames (~1 sec)
  if (frameCount % 60 == 0) {
    for (int i = 0; i < fsrTargets.length; i++) {
      fsrTargets[i] = random(0, 1023);
    }
  }

  // Draw FSR heatmap circles and labels
  for (int i = 0; i < fsrValues.length; i++) {
    float x = imgX + xOffsets[i] * scaleFactor;
    float y = imgY + yOffsets[i] * scaleFactor;

    // Flip horizontally for left foot
    x = imgX + imgWidth - (x - imgX);

    float radius = map(fsrValues[i], 0, 1023, 20, 60); // smaller bubbles
    if (fsrValues[i] < 0.6 * 1023) fill(0, 150, 255, 180);
    else if (fsrValues[i] < 0.8 * 1023) fill(255, 200, 0, 180);
    else fill(255, 0, 0, 180);
    ellipse(x, y, radius, radius);

    // Draw label to the right of the dot
    fill(0);
    text(labels[i], x + radius/2 + 5, y + 5);
  }

  // Draw bar graphs with matching labels
  for (int i = 0; i < fsrValues.length; i++) {
    fill(100, 200, 255);
    float barHeight = map(fsrValues[i], 0, 1023, 0, 200);
    rect(1000, 150 + i * 150, 30, -barHeight);
    fill(0);
    text(labels[i] + ": " + int(fsrValues[i]), 1040, 150 + i * 150 - barHeight);
  }
}
