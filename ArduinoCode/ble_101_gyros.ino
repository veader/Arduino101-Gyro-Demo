#include <BMI160.h>
#include <CurieImu.h>
#include <CurieBle.h>


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

// TODO: where is this defined?
int scaleFactor = 131; // used to convert raw values to degress/sec


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
  pinMode(ledPin, OUTPUT);

  CurieImu.initialize();
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
//  CurieImu.setGyroRate(BMI160_GYRO_RATE_25HZ);
//  CurieImu.setFullScaleGyroRange(BMI160_GYRO_RANGE_2000);
  
  Serial.print("Starting Gyroscope calibration...");
  CurieImu.autoCalibrateGyroOffset();
  Serial.println(" Done");
  
  Serial.print("Starting Acceleration calibration...");
  CurieImu.autoCalibrateXAccelOffset(0);
  CurieImu.autoCalibrateYAccelOffset(0);
  CurieImu.autoCalibrateZAccelOffset(1);
  Serial.println(" Done");
  
  Serial.println("Enabling Gyroscope/Acceleration offset compensation");
  CurieImu.setGyroOffsetEnabled(true);
  CurieImu.setAccelOffsetEnabled(true);
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
  ax = CurieImu.getAccelerationX();
  ay = CurieImu.getAccelerationY();
  az = CurieImu.getAccelerationZ();

  gx = CurieImu.getRotationX();
  gy = CurieImu.getRotationY();
  gz = CurieImu.getRotationZ();

  calculateAngles();
}

// convert radians to degrees
double rtod(double rads) { return(rads * 180.0 / PI); }

void calculateAngles() {
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
  // NOTE: alpha depends on sampling rate - TODO: how do you calculate this?
  float alpha = 0.96;
  angleX = (alpha * gyroX) + (1.0 - alpha) * accelX;
  angleY = (alpha * gyroY) + (1.0 - alpha) * accelY;
  angleZ = gyroZ; // accelerometer doesn't have a z-angle 

  // store for next poll
  previousReadMillis = timeNow;
  lastAngleX = angleX; 
  lastAngleY = angleY; 
  lastAngleZ = angleZ;

//  Serial.print("Angle X: ");  Serial.print(angleX);
//  Serial.print("\tY: ");      Serial.print(angleY);
//  Serial.print("\tZ: ");      Serial.print(angleZ);
//  Serial.println(".");
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

  Serial.print("BLE Update: ");
  Serial.print("X: "); Serial.print(gx);
  Serial.print("| Y: "); Serial.print(gy);
  Serial.print("| Z: "); Serial.println(gz);

  Serial.print("Orientation Update: ");
  Serial.print("Yaw: ");   Serial.print(lastAngleZ);
  Serial.print("| Pitch: "); Serial.print(lastAngleY);
  Serial.print("| Roll: "); Serial.print(lastAngleX);
  Serial.println("");
}

