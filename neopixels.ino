#include <Adafruit_NeoPixel.h>
#include <Servo.h>
#include <NewPing.h>

#define LED_PIN_1 3
#define LED_PIN_2 10
#define LED_COUNT_1 97
#define LED_COUNT_2 96

//define servos
int servo_1_pin = 6;
int servo_2_pin = 5;
int last_time = 0;

int b = 100;

bool servo_1_turning = false;
bool servo_2_turning = false; 

bool edge_detect = false;
bool fade = false;
unsigned long current_time;
unsigned long turn_time;
unsigned long servo_turn_time = 5000;
unsigned long servo_1_start_time;
unsigned long servo_2_start_time;

unsigned long brightness_track_time;

Servo Servo_1;
Servo Servo_2;
byte ind = 0;

//define distance sensor
#define trig_pin  7
#define echo_pin 8
#define max_distance 400

NewPing sonar(trig_pin, echo_pin, max_distance);


Adafruit_NeoPixel strip1(LED_COUNT_1, LED_PIN_1, NEO_GRB + NEO_KHZ800);
Adafruit_NeoPixel strip2(LED_COUNT_2, LED_PIN_2, NEO_GRB + NEO_KHZ800);

uint8_t pixel_color[4];
String str;

void setup() {
 //  put your setup code here, to run once:
  Serial.begin(9600);
  Servo_1.attach(servo_1_pin);
  Servo_2.attach(servo_2_pin);
 
  strip1.begin();
  strip1.setBrightness(255);
  strip1.show();


  strip2.begin();
  strip1.setBrightness(255);
  strip2.show();
}

void loop() {
  check_for_distance(Servo_1);
  turn_second_servo(Servo_2);
  if(Serial.available() > 0) {
    if(edge_detect == true) {
      int a = Serial.read();
      edge_detection(a, 0, 0, 255);
    }
    else {
       str = Serial.readStringUntil(';');
       string_to_pixels(str);
       Serial.println(str);
    }
   }
  current_time = millis();
  if(current_time - brightness_track_time > 5000 && fade == true) {
     fade_out();
  }
}


/*void light_up(uint32_t color, int wait,int index) {
//  for(int i=0; i<strip.numPixels(); i++) { 
    strip.setPixelColor(index, color);        
    strip.show();                       
    delay(wait); 
 // }
*/
void edge_detection(int index,int r,int g,int b) {
  //indexes 75 and 46 lights behind prisms
  if(index < 3 || index > 180) {
    strip1.clear();
    strip2.clear();
  }
  else if(index < strip1.numPixels()) {
     strip1.setPixelColor(index, r, g, b); 
  }
  else {
     strip2.setPixelColor(index % 96, r, g, b); 
  }
  strip1.setPixelColor(75, 255, 255, 255); 
  strip2.setPixelColor(46, 255, 255, 255); 
  strip1.show();
  strip2.show();
}

 void show_colors(int wait,uint8_t color[]) {
    if(color[0] > 100) {
       brightness_track_time = millis();
       fade = true;
    }
    else {
      strip1.setBrightness(255);
      strip2.setBrightness(255);
      strip2.setPixelColor(color[0], color[1], color[2], color[3]); 
      strip1.setPixelColor(color[0], color[1], color[2], color[3]); 
    }
    strip1.show();
    strip2.show();
}

void string_to_pixels(String s) {
   const int len = s.length();
   char* str = new char[len + 1];
   strcpy(str, s.c_str()); 
  
   char* endptr;
   uint8_t a = strtol(str, &endptr, 10); 
   uint8_t ab = strtol(endptr, &endptr, 10); 
   uint8_t abc = strtol(endptr, &endptr, 10); 
   uint8_t abcd = strtol(endptr, NULL, 10); 
   pixel_color[0] = a;
   pixel_color[1] = ab;
   pixel_color[2] = abc;
   pixel_color[3] = abcd;
   show_colors(0, pixel_color);
}

void fade_out() {
  strip1.setBrightness(b);
  strip2.setBrightness(b);
  b-= 1;
  if(strip1.getBrightness() == 5) {
    strip1.clear();
    strip2.clear();
    fade = false;
   // brightness_track_time = millis();
    Serial.println("color.");
  }
  strip2.show();
  strip1.show();
}

void check_for_distance(Servo servo) {
 if(sonar.ping_cm() < 5 && sonar.ping_cm() > 1 && servo_1_turning == false) {
    servo_1_start_time = millis();
    servo_1_turning = true;
    edge_detect = false;
    strip1.clear();
    strip2.clear();
    strip1.show();
    strip2.show();
 }
 current_time = millis();
  if(servo_1_turning == true) {
   //Serial.println("edge.");
   int turn_value = map(current_time - servo_1_start_time, 0, 5000, 0, 180);
   servo.write(turn_value); 
   if(turn_value > 90 && servo_2_turning == false) {
    servo_2_start_time = millis();
    servo_2_turning = true;
   }
 }
 if(current_time > servo_turn_time + servo_1_start_time) {
  servo.write(0);
  servo_1_start_time = 0;
  servo_1_turning = false;
 }
}

void turn_second_servo(Servo servo) {
  if(servo_2_turning == true) {
    int turn_value = map(current_time - servo_2_start_time, 0, 5000, 0, 180);
    servo.write(turn_value); 
  }
  if(current_time > servo_turn_time + servo_2_start_time) {
    servo.write(0);
    servo_2_start_time = 0;
    servo_2_turning = false;
 }
}
