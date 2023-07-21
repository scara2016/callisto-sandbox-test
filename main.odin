package cal_sandbox

import "core:log"
import "core:time"
import "core:mem"
import cal "callisto"
import "callisto/input"
import cg "callisto/graphics"

// Temp frame timer
frame_stopwatch: time.Stopwatch = {}
delta_time: f64 = {}
// ================


// Color_Vertex :: struct #align 4 {   // struct typedef.
//     position:   [3]f32,             // Align directive is just a precaution
//     color:      [3]f32,
// }

// verts: []Color_Vertex = {

//     {{0,     -0.5,   0.0},     {1, 1, 0}},
//     {{0.5,   0.5,    0.0},     {0, 1, 0}},
//     {{-0.5,  0.5,    0.0},     {0, 0, 1}},
// }

UV_Vertex :: struct #align 4 {
    position:   [3]f32,
    uv:         [2]f32,
}

rect_verts: []UV_Vertex = {
    {{-0.5,     -0.5,   0.0},       {0, 0}}, // Top left
    {{-0.5,     0.5,    0.0},       {0, 1}}, // Bottom left
    {{0.5,      0.5,    0.0},       {1, 1}}, // Bottom right
    {{0.5,      -0.5,   0.0},       {1, 0}}, // Top right
}

rect_indices: []u32 = {
    0, 1, 3,
    1, 2, 3, 
}

sprite_shader: cg.Shader
rect_mesh: cg.Mesh

// color_shader: cg.Shader
// triangle_vert_buffer: cg.Vertex_Buffer

main :: proc(){
    // Memory leak detection
    track: mem.Tracking_Allocator
    mem.tracking_allocator_init(&track, context.allocator)
    defer mem.tracking_allocator_destroy(&track)
    context.allocator = mem.tracking_allocator(&track)

    defer {
        for _, leak in track.allocation_map {
            log.errorf("%v leaked %v bytes\n", leak.location, leak.size)
        }
        for bad_free in track.bad_free_array {
            log.errorf("%v allocation %p was freed badly\n", bad_free.location, bad_free.memory)
        }
    }
    // =====================

    ok := cal.init(); if !ok do return
    defer cal.shutdown()
    context.logger = cal.logger

    // color_shader_desc: cg.Shader_Description = {
    //     vertex_typeid =         typeid_of(Color_Vertex),
    //     vertex_shader_path =    "callisto/assets/shaders/vert_color.vert.spv",
    //     fragment_shader_path =  "callisto/assets/shaders/vert_color.frag.spv",
    // }

    // ok = cg.create_shader(&color_shader_desc, &color_shader); if !ok {time.sleep(5 * time.Second); return}
    // defer cg.destroy_shader(color_shader)
    // ok = cg.create_vertex_buffer(verts, &triangle_vert_buffer); if !ok {time.sleep(5 * time.Second); return}
    // defer cg.destroy_vertex_buffer(triangle_vert_buffer)

    sprite_shader_desc: cg.Shader_Description = {
        vertex_typeid =         typeid_of(UV_Vertex),
        vertex_shader_path =    "callisto/assets/shaders/sprite_unlit.vert.spv",
        fragment_shader_path =    "callisto/assets/shaders/sprite_unlit.frag.spv",
    }
    ok = cg.create_shader(&sprite_shader_desc, &sprite_shader); if !ok {time.sleep(5 * time.Second); return }
    defer cg.destroy_shader(sprite_shader)
    ok = cg.create_mesh(rect_verts, rect_indices, &rect_mesh); if !ok {time.sleep(5 * time.Second); return }
    defer cg.destroy_mesh(rect_mesh)


    for cal.should_loop() {
        // Temp frame timer
        delta_time = time.duration_seconds(time.stopwatch_duration(frame_stopwatch))
        time.stopwatch_reset(&frame_stopwatch)
        time.stopwatch_start(&frame_stopwatch)
        // ================

        loop()
        // break
    }
    
}


loop :: proc() {
    // gameplay code here
    cg.cmd_record()
    cg.cmd_begin_render_pass()
    // cg.cmd_bind_shader(color_shader)
    // cg.cmd_draw(triangle_vert_buffer)
    cg.cmd_bind_shader(sprite_shader)
    cg.cmd_draw(rect_mesh)
    cg.cmd_end_render_pass()
    cg.cmd_present()
    // log.infof("{:2.6f} : {:i}fps", delta_time, int(1 / delta_time))

}
