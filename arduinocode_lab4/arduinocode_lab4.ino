#include <Wire.h>
#include <MPU6050.h>

MPU6050 mpu;

// ---------- Pins (as you specified) ----------
const int ledPins[4] = {3, 5, 6, 9};  // LEDs for FSR0..FSR3
const int fsrPins[4] = {A0, A1, A2, A3}; // FSR0..FSR3

// ---------- FSR filtering + baseline ----------
static const float LPF_ALPHA = 0.25f;     // 0..1 (higher = snappier)
static const int   BASELINE_SAMPLES = 400;
static const int   BASELINE_MARGIN  = 10; // fixed noise guard

int   baseline[4] = {0,0,0,0};
float fsrLPF[4]   = {0,0,0,0};

// Per-channel extra deadband (counts above baseline before lighting)
int THRESH[4] = {15, 15, 15, 15};

// LED curve (maps force->PWM)
int   MAX_DELTA = 700;   // “heavy press” scale (ADC counts)
float GAMMA     = 1.6f;  // 1.0 linear; >1 keeps small forces dimmer
// Optional per-channel caps (to match your old behavior)
int   MAX_PWM[4] = {200, 245, 255, 255};

// ---------- IMU ----------
int16_t ax, ay, az, gx, gy, gz;
float ax_g, ay_g, az_g, gx_dps, gy_dps, gz_dps; // for printing

// ---------- Helpers ----------
static inline uint8_t clamp8(int v){ return (v<0)?0:(v>255?255:v); }
static inline float   clamp01(float x){ return (x<0)?0.0f:((x>1.0f)?1.0f:x); }

void doBaseline(unsigned samples) {
  long acc[4] = {0,0,0,0};
  for (unsigned n=0; n<samples; n++){
    for (int i=0; i<4; i++) acc[i] += analogRead(fsrPins[i]);
    delay(5); // ~200 Hz baseline capture
  }
  for (int i=0; i<4; i++){
    baseline[i] = (int)(acc[i] / (long)samples);
    fsrLPF[i]   = baseline[i];
  }
  Serial.print("OK BASELINE ");
  for (int i=0; i<4; i++){ Serial.print(baseline[i]); Serial.print(i<3?' ':'\n'); }
}

void maybeHandleSerialCommand() {
  if (!Serial.available()) return;
  String line = Serial.readStringUntil('\n');
  line.trim();
  String upper = line; upper.toUpperCase();

  if (upper.startsWith("BASE")) {
    int sp = line.indexOf(' ');
    int N = (sp>0) ? line.substring(sp+1).toInt() : BASELINE_SAMPLES;
    if (N <= 0) N = BASELINE_SAMPLES;
    doBaseline((unsigned)N);
  }
}

void setup() {
  Serial.begin(115200);
  Wire.begin();

  // MPU6050
  Serial.println("Initializing MPU6050...");
  mpu.initialize();
  if (!mpu.testConnection()) {
    Serial.println("Error: MPU6050 not connected!");
    while (1);
  }
  Serial.println("MPU6050 connected.");

  // LEDs
  for (int i = 0; i < 4; i++) {
    pinMode(ledPins[i], OUTPUT);
    analogWrite(ledPins[i], 0);
  }

  // Auto-baseline on boot (try to hold foot off the ground ~2s)
  doBaseline(BASELINE_SAMPLES);

  Serial.println("Setup successful.\n");
}

void loop() {
  maybeHandleSerialCommand();  // allows "BASE N" from Processing/Serial

  // ---- Read & filter FSRs ----
  for (int i=0; i<4; i++) {
    int raw = analogRead(fsrPins[i]);
    fsrLPF[i] = fsrLPF[i] + LPF_ALPHA * (raw - fsrLPF[i]);
  }

  // ---- Compute delta above baseline + deadband; set LED brightness ----
  for (int i=0; i<4; i++) {
    int db = BASELINE_MARGIN + THRESH[i];
    int d  = (int)fsrLPF[i] - baseline[i];
    if (d < db) d = 0; else d -= db;

    float norm   = clamp01((float)d / (float)MAX_DELTA);
    float curved = pow(norm, GAMMA);
    int   pwm    = (int)(curved * MAX_PWM[i]);
    analogWrite(ledPins[i], clamp8(pwm));
  }

  // ---- IMU ----
  mpu.getMotion6(&ax, &ay, &az, &gx, &gy, &gz);
  ax_g = ax / 16384.0;  // ±2g default
  ay_g = ay / 16384.0;
  az_g = az / 16384.0;
  gx_dps = gx / 131.0;  // ±250 dps default
  gy_dps = gy / 131.0;
  gz_dps = gz / 131.0;

  // ---- CSV (same order as your original code) ----
  Serial.print((int)fsrLPF[0]); Serial.print(",");
  Serial.print((int)fsrLPF[1]); Serial.print(",");
  Serial.print((int)fsrLPF[2]); Serial.print(",");
  Serial.print((int)fsrLPF[3]); Serial.print(",");
  Serial.print(ax_g); Serial.print(",");
  Serial.print(ay_g); Serial.print(",");
  Serial.print(az_g); Serial.print(",");
  Serial.print(gx_dps); Serial.print(",");
  Serial.print(gy_dps); Serial.print(",");
  Serial.println(gz_dps);

  delay(100); // 10 Hz sampling (keep as your original)
}

