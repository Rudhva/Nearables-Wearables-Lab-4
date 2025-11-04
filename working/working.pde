void setup() {
  size(1200, 800);
  heatMapSetup();
  setupSerial();
}

void draw() {
  background(255);
  heatMapDraw();
  readSerial();
}