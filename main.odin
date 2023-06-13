package cal_sandbox

import "callisto"
import "core:log"

main :: proc(){
    callisto.init()
    defer callisto.shutdown()

    context.logger = callisto.logger

    for callisto.should_loop() {
        loop()
    }
}

loop :: proc() {
    // gameplay code here
}
