// -------------------------
// Main sketch
// -------------------------
GameSketch activeGame = null;
Foot3DSketch activeFoot = null;

interface SketchWindowListener {
  void onWindowClosed();
}

void setup() {
  size(1200, 825, P3D);
  frameRate(60);

  heatMapSetup();       // existing function
  setupSerial();        // serial initialization
}

void draw() {
  background(255);
  heatMapDraw();        // existing function

  fill(useFakeData ? color(254, 157, 74) : color(82, 126, 255));
  noStroke();
  ellipse(width - 20, 20, 16, 16);

  if (useFakeData) randomInput();
  else readSerial();

  // Pass latest sensor values to 3D foot if it's active
  if (activeFoot != null) {
    activeFoot.updateSensorValues(
      accelX, accelY, accelZ,
      fsrValues,
      latestSerialMessage
    );
  }
}

void launchGameWindow() {
  if (activeGame != null) return;

  activeGame = new GameSketch(this, new SketchWindowListener() {
    public void onWindowClosed() {
      activeGame = null;
    }
  });

  PApplet.runSketch(new String[] { "Space Jumper" }, activeGame);
}

void launchFoot3DWindow() {
  if (activeFoot != null) return;

  activeFoot = new Foot3DSketch(this, new SketchWindowListener() {
    public void onWindowClosed() {
      activeFoot = null;
    }
  });

  PApplet.runSketch(new String[] { "Foot 3D Viewer" }, activeFoot);
}
