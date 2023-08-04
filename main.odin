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

rect_uniform_data : Uniform_Buffer_Object = {
    model = linalg.MATRIX4F32_IDENTITY,
    view = linalg.MATRIX4F32_IDENTITY,
    proj = linalg.MATRIX4F32_IDENTITY,
}

rect_back_uniform_data : Uniform_Buffer_Object

sprite_shader       : cg.Shader
rect_mesh           : cg.Mesh
rect_back_mesh      : cg.Mesh

red_material        : cg.Material_Instance
orange_material     : cg.Material_Instance

red_texture         : cg.Texture
orange_texture      : cg.Texture

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

    red_texture_desc := cg.Texture_Description {
        image_path = "callisto/assets/textures/prototype/red_texture_11.png",
        color_space = .SRGB,
    }
    orange_texture_desc := cg.Texture_Description {
        image_path = "callisto/assets/textures/prototype/orange_texture_11.png",
        color_space = .SRGB,
    }

    ok = cg.create_shader(&sprite_shader_desc, &sprite_shader); if !ok do return
    defer cg.destroy_shader(sprite_shader)

    ok = cg.create_material_instance(sprite_shader, &red_material); if !ok do return
    defer cg.destroy_material_instance(red_material)
    ok = cg.create_material_instance(sprite_shader, &orange_material); if !ok do return
    defer cg.destroy_material_instance(orange_material)

    ok = cg.create_mesh(rect_verts, rect_indices, &rect_mesh); if !ok do return
    defer cg.destroy_mesh(rect_mesh)
    ok = cg.create_mesh(rect_verts, rect_indices, &rect_back_mesh); if !ok do return
    defer cg.destroy_mesh(rect_back_mesh)

    ok = cg.create_texture(&red_texture_desc, &red_texture); if !ok do return
    defer cg.destroy_texture(red_texture)
    ok = cg.create_texture(&orange_texture_desc, &orange_texture); if !ok do return
    defer cg.destroy_texture(orange_texture)

    cg.set_material_instance_texture(red_material, 1, red_texture)
    cg.set_material_instance_texture(orange_material, 1, orange_texture)

    camera_transform := linalg.matrix4_translate_f32({0, 0, -3})

    aspect_ratio := f32(config.WINDOW_WIDTH) / f32(config.WINDOW_HEIGHT)
    rect_uniform_data.proj = linalg.matrix4_perspective_f32(linalg.to_radians(f32(40)), aspect_ratio, 0.1, 1000, false)
    // sprite_uniform_data.proj = linalg.matrix_ortho3d_f32(-aspect_ratio, aspect_ratio, 1, -1, -10, 100)   
    rect_uniform_data.view = linalg.matrix4_inverse_f32(camera_transform)

    rect_back_uniform_data = rect_uniform_data
    rect_back_uniform_data.model *= linalg.matrix4_translate_f32({0.25, 0.25, 0.1})


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
    model_matrix := linalg.matrix4_rotate_f32(spin_speed * delta_time, linalg.VECTOR3F32_Y_AXIS)
    // rect_uniform_data.model *= model_matrix
    rect_back_uniform_data.model *= model_matrix

    // cg.upload_camera_uniforms(viewproj_matrix, &camera_uniform_buffer)
    cg.upload_material_uniforms(red_material, &rect_uniform_data)
    // cg.upload_material_uniforms(red_material, &rect_back_uniform_data)
    cg.upload_material_uniforms(orange_material, &rect_back_uniform_data)

    cg.cmd_record()
    cg.cmd_begin_render_pass()
    cg.cmd_bind_material_instance(orange_material)
    cg.cmd_draw(rect_back_mesh)
    cg.cmd_bind_material_instance(red_material)
    cg.cmd_draw(rect_mesh)
    cg.cmd_end_render_pass()
    cg.cmd_present()
    // log.infof("{:2.6f} : {:i}fps", delta_time, int(1 / delta_time))

}
