package cal_sandbox

import "callisto"
import "callisto/input"
import "core:log"

// temp
import "vendor:glfw"



main :: proc(){
    ok := callisto.init(); if !ok do return
    defer callisto.shutdown()
    context.logger = callisto.logger

    for callisto.should_loop() {
        loop()
    }
}

loop :: proc() {
    // gameplay code here
}
