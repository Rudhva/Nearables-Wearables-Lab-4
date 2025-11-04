PImage footImg;
float[] fsrValues = new float[4];
float[] fsrTargets = new float[4];

// Fine-tuned offsets for better alignment on the flipped right foot
// Indexes: 0=Big Toe, 1=Ball (lateral), 2=Medial midfoot, 3=Heel
float[] xOffsets = {70, 160, 100, 110};   // medial midfoot moved left
float[] yOffsets = {170, 210, 290, 470};  // lateral + midfoot slightly up

String[] labels = {"Big Toe", "Ball", "Midfoot", "Heel"};

float scaleFactor;
float imgWidth, imgHeight;
float imgX = 200, imgY = 100;

void setup() {
  size(1200, 800);
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

void draw() {
  background(255);
  image(footImg, imgX, imgY, imgWidth, imgHeight);

  for (int i = 0; i < fsrValues.length; i++) {
    fsrValues[i] += (fsrTargets[i] - fsrValues[i]) * 0.1;
  }

  if (frameCount % 60 == 0) {
    for (int i = 0; i < fsrTargets.length; i++) {
      fsrTargets[i] = random(0, 1023);
    }
  }

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
}

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

int heatColor(float v) {
  float n = constrain(v / 1023.0, 0, 1);
  color c1 = color(0, 0, 255);
  color c2 = color(255, 255, 0);
  color c3 = color(255, 0, 0);
  if (n < 0.5) return lerpColor(c1, c2, n * 2);
  else return lerpColor(c2, c3, (n - 0.5) * 2);
}

void drawBars() {
  for (int i = 0; i < fsrValues.length; i++) {
    fill(100, 200, 255);
    float barHeight = map(fsrValues[i], 0, 1023, 0, 200);
    rect(1000, 150 + i * 150, 30, -barHeight);
    fill(0);
    text(labels[i] + ": " + int(fsrValues[i]), 1040, 150 + i * 150 - barHeight);
  }
}
