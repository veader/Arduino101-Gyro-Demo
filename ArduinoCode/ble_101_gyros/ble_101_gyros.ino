#include <CurieIMU.h>
#include <CurieBLE.h>

bool debuggingEnabled = true;

// ---------------------------------------------------------------------------
int sampleRate = 25; // Hz
int ledPin = 13;

unsigned long previousReadMillis = 0;
unsigned long previousBLEMillis = 0;

// accelerometer values 
int ax, ay, az;
// gyroscope values
int gx, gy, gz;
// resulting angle values
float angleX, angleY, angleZ;
// filtered angle values
float lastAngleX, lastAngleY, lastAngleZ;
// angle storage for drift detection
float lastAngleX_drift, lastAngleY_drift, lastAngleZ_drift;


// ---------------------------------------------------------------------------
BLEPeripheral blePeripheral;
// UUIDs generated with `uuidgen`
BLEService gyroService("7C27A67C-8E46-4AE6-8BC0-8A0865E7293F");

// try to use the template types found here:
// https://github.com/01org/corelibs-arduino101/blob/master/libraries/CurieBLE/src/BLETypedCharacteristic.h
// BLEUnsignedCharCharacteristic
BLEIntCharacteristic gyroXChar("FF125EA1-E5B1-4323-9913-957826EB5059", BLERead | BLENotify);
BLEIntCharacteristic gyroYChar("24676112-6E73-4159-90E1-147288DD11DD", BLERead | BLENotify);
BLEIntCharacteristic gyroZChar("593DCD1B-749B-4697-8DC3-709EED98887B", BLERead | BLENotify);
BLEIntCharacteristic yawChar("93071DD4-F234-4A05-AFE1-E31FEE32DE3C",   BLERead | BLENotify);
BLEIntCharacteristic pitchChar("3918E336-40EA-4279-BA4B-BEDFF4FE966A", BLERead | BLENotify);
BLEIntCharacteristic rollChar("B79F84F0-239E-4492-90E2-89283A45621B",  BLERead | BLENotify);


// ---------------------------------------------------------------------------
void setup() {
  Serial.begin(9600);
  while (!Serial); // wait for the serial port to open

  pinMode(ledPin, OUTPUT);

  CurieIMU.begin();
  setupIMU();
  setupBLE();
}

void loop() {
  BLECentral central = blePeripheral.central();

  if (central) {
    Serial.print("Connected to central: ");
    Serial.println(central.address()); // print the central's MAC address:
    digitalWrite(13, HIGH);

    // while central is connected...
    while (central.connected()) {
      unsigned long currentMillis = millis();

      // read gyro at sample rate : 40ms = 25Hz
      if (currentMillis - previousReadMillis >= 40) {
        readGyroValues();
      }

      // update BLE every half second
      if (currentMillis - previousBLEMillis >= 500) {
        updateBLEGyroValues();
        previousBLEMillis = currentMillis;
      }
    }

    digitalWrite(13, LOW);
    Serial.print("Disconnected from central: ");
    Serial.println(central.address());
  }
}


// ---------------------------------------------------------------------------
void setupIMU() {
//  CurieIMU.setGyroRate(BMI160_GYRO_RATE_25HZ);
//  CurieIMU.setFullScaleGyroRange(BMI160_GYRO_RANGE_2000);
  
  Serial.print("Starting Gyroscope calibration...");
  CurieIMU.autoCalibrateGyroOffset();
  Serial.println(" Done");
  
  Serial.print("Starting Acceleration calibration...");
  CurieIMU.autoCalibrateXAccelOffset(0);
  CurieIMU.autoCalibrateYAccelOffset(0);
  CurieIMU.autoCalibrateZAccelOffset(1);
  Serial.println(" Done");
  
  Serial.println("Enabling Gyroscope/Acceleration offset compensation");
  CurieIMU.setGyroOffsetEnabled(true);
  CurieIMU.setAccelOffsetEnabled(true);
}

void setupBLE() {
  blePeripheral.setLocalName("101_Gyro");
  blePeripheral.setAdvertisedServiceUuid(gyroService.uuid());
  blePeripheral.addAttribute(gyroService);

  blePeripheral.addAttribute(gyroXChar);
  blePeripheral.addAttribute(gyroYChar);
  blePeripheral.addAttribute(gyroZChar);
  
  blePeripheral.addAttribute(yawChar);
  blePeripheral.addAttribute(pitchChar);
  blePeripheral.addAttribute(rollChar);

  blePeripheral.begin();
  Serial.println("Bluetooth device active, waiting for connections...");
}


// ---------------------------------------------------------------------------
void readGyroValues() {
  ax = CurieIMU.getAccelerationX();
  ay = CurieIMU.getAccelerationY();
  az = CurieIMU.getAccelerationZ();

  gx = CurieIMU.getRotationX();
  gy = CurieIMU.getRotationY();
  gz = CurieIMU.getRotationZ();

  calculateAngles();
}

// convert radians to degrees
double rtod(double rads) { return(rads * 180.0 / PI); }

void calculateAngles() {
  // a lot of good info found here original: https://forum.arduino.cc/index.php?topic=378779.0
  static int scaleFactor = 131; // used to convert raw values to degress/sec

  unsigned long timeNow = millis();
 
  // convert raw gyro values to degrees/sec
  float gyroX_dps = gx / scaleFactor;
  float gyroY_dps = gy / scaleFactor;
  float gyroZ_dps = gz / scaleFactor;

  // compute accel angles
  float accelX = rtod(atan(ay / sqrt(pow(ax, 2) + pow(az, 2))));
  float accelY = rtod(-1 * atan(ax / sqrt(pow(ay, 2) + pow(az, 2))));

  // compute filtered gyro angles
  float timeDelta = (timeNow - previousReadMillis) / 1000.0;
  float gyroX = (gyroX_dps * timeDelta) + lastAngleX;
  float gyroY = (gyroY_dps * timeDelta) + lastAngleY;
  float gyroZ = (gyroZ_dps * timeDelta) + lastAngleZ;

  // compute the drifting gyro angles
  lastAngleX_drift = (gyroX_dps * timeDelta) + lastAngleX_drift;
  lastAngleY_drift = (gyroY_dps * timeDelta) + lastAngleY_drift;
  lastAngleZ_drift = (gyroZ_dps * timeDelta) + lastAngleZ_drift;

  // apply complementary filter to determine change in angle
  // NOTE: alpha depends on sampling rate
  float alpha = 0.96;
  angleX = (alpha * gyroX) + ((1.0 - alpha) * accelX);
  angleY = (alpha * gyroY) + ((1.0 - alpha) * accelY);
  angleZ = gyroZ; // accelerometer doesn't have a z-angle 

  // store for next poll
  previousReadMillis = timeNow;
  lastAngleX = angleX; 
  lastAngleY = angleY; 
  lastAngleZ = angleZ;
}

void updateBLEGyroValues() {
  gyroXChar.setValue(gx);
  gyroYChar.setValue(gy);
  gyroZChar.setValue(gz);

  // multiply by 100 to make them an "int"
  int yaw   = lastAngleZ * 100;
  int pitch = lastAngleY * 100;
  int roll  = lastAngleX * 100;
  yawChar.setValue(yaw);
  pitchChar.setValue(pitch);
  rollChar.setValue(roll);

  printDebuggingInfo();
}

void printDebuggingInfo() {
  if (!debuggingEnabled) { return; }
 
  // mostly for debugging purposes
  Serial.print("[Raw Gyro] ");
  Serial.print("X: ");   Serial.print(gx);
  Serial.print("| Y: "); Serial.print(gy);
  Serial.print("| Z: "); Serial.println(gz);

  Serial.print("[Orientation]");
  Serial.print("  Roll: ");  Serial.print(lastAngleX);
  Serial.print("\tPitch: "); Serial.print(lastAngleY);
  Serial.print("\tYaw: ");   Serial.print(lastAngleZ);
  Serial.println(".");

  Serial.print("[Drift] ");
  Serial.print("  Roll: ");  Serial.print(lastAngleX_drift);
  Serial.print("\tPitch: "); Serial.print(lastAngleY_drift);
  Serial.print("\tYaw: ");   Serial.print(lastAngleZ_drift);
  Serial.println(".");
}

