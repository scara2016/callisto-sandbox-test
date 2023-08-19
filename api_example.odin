package callisto_sandbox

// Example of the intended API in use. Not functional yet.

/*
import "callisto"
import "callisto/config"
import "callisto/asset"
import cg "callisto/graphics"
// import "callisto/util"
// import "callisto/time"

import "core:log"



_main :: proc() {
    // Set up odin context
    when ODIN_DEBUG {
        context.logger = util.create_logger()
        defer util.destroy_logger()
        
        context.allocator = util.create_tracking_allocator()
        defer {
            util.log_tracking_allocator()
            util.destroy_tracking_allocator()
        }
    }

    run_app() // Allow `or_return` in game setup code by wrapping in a proc with a return value
}


run_app :: proc() -> (ok: bool) {

    callisto.init() or_return
    defer callisto.shutdown()

    // Load assets
    asset.load_mesh() or_return

    // Game loop
    for callisto.should_loop() {
        loop()
    }
}

loop :: proc() -> (ok: bool) {
    // Game logic

    // Render - note: callisto graphics procedures are no-op when compiled in headless mode, though compute shaders will still work.

}
*/