#include "app_main.h"

#include <iostream>
#include <vector>
#include <sstream>


using namespace scr;
using namespace std;

GPIO button(USER_Btn_GPIO_Port, USER_Btn_Pin);
GPIO green_led(LD1_GPIO_Port, LD1_Pin);
GPIO blue_led(LD2_GPIO_Port, LD2_Pin);
GPIO red_led(LD3_GPIO_Port, LD3_Pin);


void setup(void) {
    
}

void loop0(void) {
    static int t = 300;
    red_led.write(Low);
    green_led.write(High);
    delay(t);
    green_led.write(Low);
    blue_led.write(High);
    delay(t);
    blue_led.write(Low);
    red_led.write(High);
    delay(t);
}


void loop1(void) {

}

