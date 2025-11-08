void setup() {
  size(1200, 850);
  heatMapSetup();
  setupSerial();
}

void draw() {
  background(255);
  heatMapDraw();

  // draw simple toggle circle
  fill(useFakeData ? color(254, 157, 74) : color(82, 126, 255)); // orange = fake, blue = real
  noStroke();
  ellipse(width - 20, height - 20, 16, 16);

  // run whichever data mode is active
  if (useFakeData) randomInput();
  else readSerial();
}


