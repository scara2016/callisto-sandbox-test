package cal_sandbox

import "core:log"
import "callisto"
import cr "callisto/engine/renderer"


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
    cr.cmd_draw_frame()
}
