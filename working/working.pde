void setup() {
  size(1200, 850);
  heatMapSetup();
  setupSerial();
}

void draw() {
  background(255);
  heatMapDraw();
  //readSerial();
  randomInput();
}