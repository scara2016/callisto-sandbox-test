package cal_sandbox

import "core:log"
import "core:time"
import "core:mem"
import "core:math/linalg"
import cal "callisto"
import "callisto/input"
import cg "callisto/graphics"
import "callisto/config"

// Temp frame timer
frame_stopwatch: time.Stopwatch = {}
delta_time: f32 = {}
delta_time_f64: f64 = {}
// ================

Uniform_Buffer_Object :: struct #align 4 {
    model   : linalg.Matrix4x4f32,
    view    : linalg.Matrix4x4f32,
    proj    : linalg.Matrix4x4f32,
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

sprite_uniform_data : Uniform_Buffer_Object = {
    model = linalg.MATRIX4F32_IDENTITY,
    view = linalg.MATRIX4F32_IDENTITY,
    proj = linalg.MATRIX4F32_IDENTITY,
}

sprite_shader       : cg.Shader
sprite_material     : cg.Material_Instance
rect_mesh           : cg.Mesh
window_texture      : cg.Texture

spin_speed: f32 = 0.5 * linalg.PI

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

    // TODO: auto generate at shader compile time
    sprite_shader_desc := cg.Shader_Description {
        vertex_typeid           = typeid_of(UV_Vertex),
        uniform_buffer_typeid   = typeid_of(Uniform_Buffer_Object),
        vertex_shader_path      = "callisto/assets/shaders/sprite_unlit.vert.spv",
        fragment_shader_path    = "callisto/assets/shaders/sprite_unlit.frag.spv",
        cull_mode               = .NONE, // .BACK by default
    }

    window_texture_desc := cg.Texture_Description {
        image_path = "callisto/assets/textures/prototype/dark_texture_12.png",
        color_space = .SRGB,
    }

    ok = cg.create_shader(&sprite_shader_desc, &sprite_shader); if !ok do return
    defer cg.destroy_shader(sprite_shader)

    ok = cg.create_material_instance(sprite_shader, &sprite_material); if !ok do return
    defer cg.destroy_material_instance(sprite_material)

    ok = cg.create_mesh(rect_verts, rect_indices, &rect_mesh); if !ok do return
    defer cg.destroy_mesh(rect_mesh)

    ok = cg.create_texture(&window_texture_desc, &window_texture); if !ok do return
    defer cg.destroy_texture(window_texture)

    cg.set_material_instance_texture(sprite_material, 1, window_texture)

    aspect_ratio := f32(config.WINDOW_WIDTH) / f32(config.WINDOW_HEIGHT)
    sprite_uniform_data.proj = linalg.matrix4_perspective_f32(linalg.to_radians(f32(40)), aspect_ratio, 0.1, 1000, true)
    // sprite_uniform_data.proj = linalg.matrix_ortho3d_f32(-aspect_ratio, aspect_ratio, -1, 1, 0.1, 1000)
    sprite_uniform_data.view = linalg.matrix4_translate_f32({0, 0, -3})


    for cal.should_loop() {

        // Temp frame timer
        delta_time_f64 = time.duration_seconds(time.stopwatch_duration(frame_stopwatch))
        delta_time = f32(delta_time_f64)
        time.stopwatch_reset(&frame_stopwatch)
        time.stopwatch_start(&frame_stopwatch)
        // ================


        loop()
        // break
    }
    
}


loop :: proc() {
    sprite_uniform_data.model *= linalg.matrix4_rotate_f32(spin_speed * delta_time, linalg.VECTOR3F32_Y_AXIS)
    // cg.upload_camera_uniforms(viewproj_matrix, &camera_uniform_buffer)
    cg.upload_material_uniforms(sprite_material, &sprite_uniform_data)

    cg.cmd_record()
    cg.cmd_begin_render_pass()
    cg.cmd_bind_material_instance(sprite_material)
    cg.cmd_draw(rect_mesh)
    cg.cmd_end_render_pass()
    cg.cmd_present()
    // log.infof("{:2.6f} : {:i}fps", delta_time, int(1 / delta_time))

}
