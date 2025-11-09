import java.util.ArrayList;
import processing.core.PApplet;
import processing.core.PImage;
import processing.core.PVector;

class GameSketch extends PApplet {
  final PApplet parent;
  SketchWindowListener listener;

  int state = 0;
  float playerY;
  float playerVel;
  float gravity = 0.7f;
  float jumpPower = -12;
  float ground = 300;

  float speed = 6;
  int score = 0;
  int highScore = 0;

  ArrayList<Float> obstacles;
  float obstacleW = 30;
  float obstacleH = 50;
  float minGap = 250;
  float maxGap = 500;

  ArrayList<PVector> clouds;
  float cloudSpeed = 1;

  ArrayList<PVector> jumpTrail = new ArrayList<PVector>();
  int trailLength = 10;
  PImage dino;
  PImage cactus;

  float navHeight = 60;
  float navButtonHeight = 32;
  float navButtonMargin = 14;
  float backBtnX, backBtnY, backBtnW = 180, backBtnH = navButtonHeight;
  float quitBtnX, quitBtnY, quitBtnW = 120, quitBtnH = navButtonHeight;
  int navButtonColor;
  int quitButtonColor;

  GameSketch(PApplet parent, SketchWindowListener listener) {
    this.parent = parent;
    this.listener = listener;
  }

  public void settings() {
    size(800, 430, P2D);
  }

  public void setup() {
    frameRate(60);
    textAlign(CENTER, CENTER);
    smooth(8);

    navHeight = navButtonMargin * 2 + navButtonHeight;
    navButtonColor = color(82, 126, 255);
    quitButtonColor = color(244, 114, 117);

    dino = loadAssetImage("Dino.png");
    if (dino != null) dino.resize(60, 60);
    cactus = loadAssetImage("Cactus.png");
    if (cactus != null) cactus.resize(45, 65);

    setupBackground();
    resetGame();
  }

  public void draw() {
    drawGradientBackground();
    drawClouds();
    drawGameState();
    drawNavBar();
  }

  void drawGameState() {
    if (state == 0) {
      drawMenu();
    } else if (state == 1) {
      drawGame();
    } else {
      drawGameOver();
    }
  }

  void drawMenu() {
    fill(0, 120);
    textSize(48);
    text("SPACE JUMPER", width / 2, height / 2 - 70);
    textSize(20);
    text("Press SPACE or click to start", width / 2, height / 2);
    textSize(14);
    text("Use the navigation buttons above to go back or quit", width / 2, height / 2 + 40);
  }

  void drawGame() {
    fill(90, 180, 90);
    rect(0, ground, width, height - ground);

    fill(0, 50);
    ellipse(120, ground + 10, 60, 10);

    jumpTrail.add(new PVector(120, playerY));
    if (jumpTrail.size() > trailLength) {
      jumpTrail.remove(0);
    }

    if (dino != null) {
      for (int i = 0; i < jumpTrail.size(); i++) {
        float alpha = map(i, 0, max(1, jumpTrail.size() - 1), 10, 80);
        tint(82, 126, 255, alpha);
        PVector p = jumpTrail.get(i);
        image(dino, p.x - 20, p.y + 10);
      }
      noTint();
      image(dino, 100, playerY + 10);
    }

    playerY += playerVel;
    playerVel += gravity;
    if (playerY > ground - 60) {
      playerY = ground - 60;
      playerVel = 0;
    }

    for (int i = obstacles.size() - 1; i >= 0; i--) {
      float x = obstacles.get(i);
      if (cactus != null) image(cactus, x, ground - obstacleH - 10);

      x -= speed;
      obstacles.set(i, x);

      if (x < -obstacleW) {
        obstacles.remove(i);
        addNewObstacle();
        score++;
        if (score > highScore) highScore = score;
      }

      if (x < 140 && x + obstacleW > 100 && playerY + 60 > ground - obstacleH) {
        state = 2;
      }
    }

    fill(0, 120);
    textSize(20);
    textAlign(RIGHT, TOP);
    text("Score: " + score, width - 20, 20);
    textAlign(LEFT, TOP);
    text("High: " + highScore, 20, 20);
    textAlign(CENTER, CENTER);
  }

  void drawGameOver() {
    fill(0, 150);
    textSize(48);
    text("GAME OVER", width / 2, height / 2 - 60);
    textSize(22);
    text("Score: " + score, width / 2, height / 2);
    textSize(16);
    text("Click to restart or use Back above", width / 2, height / 2 + 40);
  }

  public void keyPressed() {
    if ((key == ' ' || key == 'w') && state == 1) {
      if (playerY >= ground - 60) playerVel = jumpPower;
    }
    if (key == ESC) {
      key = 0;
    }
  }

  public void mousePressed() {
    if (pointInRect(mouseX, mouseY, backBtnX, backBtnY, backBtnW, backBtnH)) {
      closeToDashboard();
      return;
    }
    if (pointInRect(mouseX, mouseY, quitBtnX, quitBtnY, quitBtnW, quitBtnH)) {
      quitApp();
      return;
    }

    if (state == 0 || state == 2) {
      resetGame();
    } else if (playerY >= ground - 60) {
      playerVel = jumpPower;
    }
  }

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

  PImage loadAssetImage(String filename) {
    PImage img = null;
    if (parent != null) {
      img = parent.loadImage(filename);
    }
    if (img == null) {
      String assetPath = parent != null ? parent.dataPath(filename) : dataPath(filename);
      img = loadImage(assetPath);
      if (img == null) {
        println("⚠️ Could not load " + filename + " from " + assetPath);
      }
    }
    return img;
  }

  void addNewObstacle() {
    float lastX = obstacles.get(obstacles.size() - 1);
    float newX = lastX + random(minGap, maxGap);
    obstacles.add(newX);
  }

  void setupBackground() {
    clouds = new ArrayList<PVector>();
    for (int i = 0; i < 6; i++) {
      clouds.add(new PVector(random(width), random(50, 200)));
    }
  }

  void drawClouds() {
    noStroke();
    for (PVector c : clouds) {
      fill(255, 255, 255, 180);
      ellipse(c.x, c.y, 60, 35);
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
    text("Space Jumper", width / 2, navHeight / 2);
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

  public void exit() {
    if (listener != null) {
      listener.onWindowClosed();
      listener = null;
    }
    super.exit();
  }
}
