// ----------------------------------------------------
// Space Jumper Deluxe (FSR + Spacebar, 60 FPS)
// Uses Cactus.png instead of orange rectangles
// ----------------------------------------------------

import processing.serial.*;
Serial myPort;

int state = 0; 
float playerY, playerVel;
float gravity = 0.7;
float jumpPower = -12;
float ground = 300;

float speed = 6;
int score = 0;
int highScore = 0;

// FSR + IMU
int heel, mf, mm, lf;
int[] fsrValues = new int[4];
float accelX, accelY, accelZ;
float gyroX, gyroY, gyroZ;
String latestSerialMessage = "";

// Obstacles
ArrayList<Float> obstacles;
float obstacleW = 30, obstacleH = 50;
float minGap = 250;
float maxGap = 500;

// Background clouds
ArrayList<PVector> clouds;
float cloudSpeed = 1;

// Player visuals
ArrayList<PVector> jumpTrail = new ArrayList<PVector>();
int trailLength = 10;
PImage dino;    // 🦖 Dino sprite
PImage cactus;  // 🌵 Cactus sprite

// ----------------------------------------------------
void setup() {
  size(800, 400, P2D);
  frameRate(60);
  textAlign(CENTER, CENTER);
  smooth(8);

  // 🦖 Load Dino and Cactus images from data folder
  dino = loadImage("Dino.png");
  dino.resize(60, 60);
  
  cactus = loadImage("Cactus.png");
  cactus.resize(45, 65);  // visually replaces the old 30x50 rects

  println(Serial.list());
  try {
    myPort = new Serial(this, Serial.list()[0], 115200);
    myPort.bufferUntil('\n');
  } catch (Exception e) {
    println("⚠️ Serial not connected — running keyboard mode only.");
    myPort = null;
  }

  setupBackground();
  resetGame();
}

// ----------------------------------------------------
void draw() {
  drawGradientBackground();
  drawClouds();

  if (state == 0)      drawMenu();
  else if (state == 1) drawGame();
  else if (state == 2) drawGameOver();
}

// ---------------- MENU ----------------
void drawMenu() {
  fill(0, 80);
  textSize(48);
  text("SPACE JUMPER", width/2, height/2 - 60);
  textSize(20);
  text("Click to Start", width/2, height/2 + 20);
  textSize(14);
  fill(0, 100);
  text("Press SPACE or use FSR sensor to jump", width/2, height/2 + 60);
}

// ---------------- GAME ----------------
void drawGame() {
  readSerial();

  // --- FSR-based jump ---
  int totalPressure = fsrValues[0] + fsrValues[1] + fsrValues[2] + fsrValues[3];
  if (totalPressure >= 2000 && playerY >= ground - 60) {
    playerVel = jumpPower;
  }

  // --- Ground ---
  fill(90, 180, 90);
  rect(0, ground, width, height - ground);

  // --- Shadow (unchanged) ---
  fill(0, 50);
  ellipse(120, ground + 10, 60, 10);

  // --- Player trail (unchanged) ---
  jumpTrail.add(new PVector(120, playerY));
  if (jumpTrail.size() > trailLength) jumpTrail.remove(0);

  for (int i = 0; i < jumpTrail.size(); i++) {
    float alpha = map(i, 0, jumpTrail.size()-1, 10, 80);
    tint(82, 126, 255, alpha);
    PVector p = jumpTrail.get(i);
    image(dino, p.x-20, p.y+10);
  }
  noTint();

  // --- Player (unchanged offsets) ---
  image(dino, 100, playerY+10);

  // --- Physics ---
  playerY += playerVel;
  playerVel += gravity;
  if (playerY > ground - 60) {
    playerY = ground - 60;
    playerVel = 0;
  }

  // --- Obstacles (NOW USING CACTUS.PNG) ---
  for (int i = obstacles.size()-1; i >= 0; i--) {
    float x = obstacles.get(i);

    // draw cactus aligned to same ground position as before
    image(cactus, x, ground - obstacleH - 10);

    x -= speed;
    obstacles.set(i, x);

    if (x < -obstacleW) {
      obstacles.remove(i);
      addNewObstacle();
      score++;
      if (score > highScore) highScore = score;
    }

    // Collision box remains same as before
    if (x < 140 && x + obstacleW > 100 &&
        playerY + 60 > ground - obstacleH) {
      state = 2;
    }
  }

  // --- HUD (unchanged) ---
  fill(0, 120);
  textSize(20);
  textAlign(RIGHT, TOP);
  text("Score: " + score, width - 20, 20);
  textAlign(LEFT, TOP);
  text("High: " + highScore, 20, 20);
}

// ---------------- GAME OVER ----------------
void drawGameOver() {
  fill(0, 150);
  textSize(48);
  text("GAME OVER", width/2, height/2 - 60);
  textSize(22);
  text("Score: " + score, width/2, height/2);
  textSize(16);
  text("Click to Restart", width/2, height/2 + 40);
}

// ---------------- CONTROLS ----------------
void keyPressed() {
  if (state == 1 && key == ' ') {
    if (playerY >= ground - 60) playerVel = jumpPower;
  }
}

void mousePressed() {
  if (state == 0 || state == 2) resetGame();
}

// ---------------- HELPERS ----------------
void resetGame() {
  playerY = ground - 60;
  playerVel = 0;
  score = 0;
  state = 1;

  obstacles = new ArrayList<Float>();
  float startX = width + 300;
  for (int i = 0; i < 3; i++) {
    obstacles.add(startX);
    startX += random(minGap, maxGap);
  }

  jumpTrail.clear();
}

void addNewObstacle() {
  float lastX = obstacles.get(obstacles.size()-1);
  float newX = lastX + random(minGap, maxGap);
  obstacles.add(newX);
}

// ---------------- BACKGROUND ----------------
void setupBackground() {
  clouds = new ArrayList<PVector>();
  for (int i = 0; i < 6; i++) {
    clouds.add(new PVector(random(width), random(50, 180)));
  }
}

void drawClouds() {
  noStroke();
  for (PVector c : clouds) {
    fill(255, 255, 255, 180);
    ellipse(c.x,     c.y,     60, 35);
    ellipse(c.x + 20, c.y + 5, 50, 30);
    ellipse(c.x - 20, c.y + 5, 50, 30);

    c.x -= cloudSpeed;
    if (c.x < -60) {
      c.x = width + random(100, 400);
      c.y = random(50, 180);
    }
  }
}

void drawGradientBackground() {
  for (int i = 0; i < height; i++) {
    float inter = map(i, 0, height, 0, 1);
    int c = lerpColor(color(135, 206, 250), color(250, 250, 255), inter);
    stroke(c);
    line(0, i, width, i);
  }
}

// ---------------- SERIAL ----------------
void readSerial() {
  if (myPort == null) return;
  if (myPort.available() <= 0) return;

  String line = myPort.readStringUntil('\n');
  if (line == null) return;
  line = trim(line);
  if (line.length() == 0) return;

  if (!line.matches("^[0-9,\\-\\.]+$")) return;
  String[] tokens = split(line, ',');
  if (tokens.length != 10) return;

  try {
    heel   = int(tokens[0]);
    mf     = int(tokens[3]);
    mm     = int(tokens[1]);
    lf     = int(tokens[2]);
    accelX = float(tokens[4]);
    accelY = float(tokens[5]);
    accelZ = float(tokens[6]);
    gyroX  = float(tokens[7]);
    gyroY  = float(tokens[8]);
    gyroZ  = float(tokens[9]);
    latestSerialMessage = line;
  } catch (Exception e) {
    println("⚠️ Parse error: " + e.getMessage());
  }

  fsrValues[0] = lf;
  fsrValues[1] = mf;
  fsrValues[2] = mm;
  fsrValues[3] = heel - 10;
}
