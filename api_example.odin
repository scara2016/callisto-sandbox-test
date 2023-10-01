package callisto_sandbox

// Example of the intended API in use. Not functional yet.
/*

import "callisto"
import "callisto/config"
import "callisto/asset"
import cg "callisto/graphics"
// import "callisto/debug"
// import "callisto/time"

import "core:log"

_main :: proc() {
    // Set up odin context
    when ODIN_DEBUG {
        context.logger = debug.create_logger()
        defer debug.destroy_logger()
        
        context.allocator = debug.create_tracking_allocator()
        defer {
            debug.log_tracking_allocator()
            debug.destroy_tracking_allocator()
        }
    }
   

    callback_info := callisto.Callback_Info {
        start = start,
        update = update,
        shutdown = shutdown,

        // Optional =======
        render = render, // If not provided, don't init renderer
        fixed_update = fixed_update,
    }

    callisto.run(&callback_info)
}


start :: proc() -> (ok: bool) {
    // Load assets
}

update :: proc() -> (ok: bool) {
    
}

shutdown :: proc() {
    // Free assets
    // Todo: perhaps an asset database should manage memory?
}



render :: proc() -> (ok: bool) {
    
}

fixed_update :: proc() -> (ok: bool) {
    
}

*/
