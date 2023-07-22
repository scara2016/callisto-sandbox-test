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

Uniform_Buffer_Object :: struct #align 4 {
    model   : matrix[4, 4]f32,
    view    : matrix[4, 4]f32,
    proj    : matrix[4, 4]f32,
}
UV_Vertex :: struct #align 4 {
    position    : [3]f32,
    uv          : [2]f32,
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

sprite_uniform_data : Uniform_Buffer_Object

sprite_shader       : cg.Shader
sprite_material     : cg.Material_Instance
rect_mesh           : cg.Mesh

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

    sprite_shader_desc: cg.Shader_Description = {
        vertex_typeid           = typeid_of(UV_Vertex),
        uniform_buffer_typeid   = typeid_of(Uniform_Buffer_Object),
        vertex_shader_path      = "callisto/assets/shaders/sprite_unlit.vert.spv",
        fragment_shader_path    = "callisto/assets/shaders/sprite_unlit.frag.spv",
    }
    ok = cg.create_shader(&sprite_shader_desc, &sprite_shader); if !ok do return
    defer cg.destroy_shader(sprite_shader)

    // in progress
    ok = cg.create_material_instance(sprite_shader, &sprite_material); if !ok do return
    defer cg.destroy_material_instance(sprite_material)
    // ===========


    ok = cg.create_mesh(rect_verts, rect_indices, &rect_mesh); if !ok do return
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


    cg.upload_material_uniforms(sprite_material, &sprite_uniform_data)

    cg.cmd_record()
    cg.cmd_begin_render_pass()
    cg.cmd_bind_shader(sprite_shader) // TODO: replace with bind material
    // cg.cmd_bind_material(sprite_material)
    cg.cmd_draw(rect_mesh)
    cg.cmd_end_render_pass()
    cg.cmd_present()
    // log.infof("{:2.6f} : {:i}fps", delta_time, int(1 / delta_time))

}
