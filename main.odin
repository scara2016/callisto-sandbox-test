package cal_sandbox

import "core:log"
import "core:time"
import "core:mem"
import "core:math/linalg"
import cal "callisto"
import "callisto/input"
import cg "callisto/graphics"
import "callisto/config"
import "callisto/importer"
import "callisto/asset"

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


box_uniform_data : Uniform_Buffer_Object = {
    model = linalg.MATRIX4F32_IDENTITY,
    view = linalg.MATRIX4F32_IDENTITY,
    proj = linalg.MATRIX4F32_IDENTITY,
}

sprite_shader       : cg.Shader

box_model           : cg.Model

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
        vertex_shader_path      = "callisto/resources/shaders/sprite_unlit.vert.spv",
        fragment_shader_path    = "callisto/resources/shaders/sprite_unlit.frag.spv",
        cull_mode               = .NONE, // .BACK by default
    }

    // box_model_desc := cg.Model_Description {
    //     model_path              = "assets/glTF-Sample-Models/2.0/Triangle/glTF-Embedded/Triangle.gltf",
    // }
    box_mesh: asset.Mesh
    box_material: asset.Material
    box_mesh, box_material, ok = importer.import_gltf("callisto/resources/models/cube.gltf")
    log.info(box_mesh)
    defer asset.delete(&box_mesh)
    defer asset.delete(&box_material)

    ok = cg.create_shader(&sprite_shader_desc, &sprite_shader); if !ok do return
    defer cg.destroy_shader(sprite_shader)

    // cg.create_model(&box_model_desc, &box_model)
    // defer cg.destroy_model(box_model)

    camera_transform := linalg.matrix4_translate_f32({0, 0, -3})

    aspect_ratio := f32(config.WINDOW_WIDTH) / f32(config.WINDOW_HEIGHT)
    box_uniform_data.proj = linalg.matrix4_perspective_f32(linalg.to_radians(f32(40)), aspect_ratio, 0.1, 1000, false)
    box_uniform_data.view = linalg.matrix4_inverse_f32(camera_transform)



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

    // cg.upload_material_uniforms(red_material, &rect_back_uniform_data)

    cg.cmd_record()
    cg.cmd_begin_render_pass()
    // cg.cmd_bind_material_instance(red_material)
    // cg.cmd_draw(rect_mesh)
    cg.cmd_end_render_pass()
    cg.cmd_present()
    // log.infof("{:2.6f} : {:i}fps", delta_time, int(1 / delta_time))

}
