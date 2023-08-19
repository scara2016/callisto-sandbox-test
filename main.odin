package callisto_sandbox

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
import "callisto/util"

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


geo_uniform_data : Uniform_Buffer_Object = {
    model = linalg.MATRIX4F32_IDENTITY,
    view = linalg.MATRIX4F32_IDENTITY,
    proj = linalg.MATRIX4F32_IDENTITY,
}


geo_meshes          : []cg.Mesh
matcap_shader       : cg.Shader
matcap_material     : cg.Material_Instance
matcap_texture      : cg.Texture


main :: proc(){
    
    when ODIN_DEBUG {
        context.logger = util.create_logger()
        defer util.destroy_logger(context.logger)

        track := util.create_tracking_allocator()
        context.allocator = mem.tracking_allocator(&track)
        defer util.destroy_tracking_allocator(&track)
    }

    run_app()
}

run_app :: proc() -> (ok: bool) {
    cal.init() or_return
    defer cal.shutdown()

    // TODO: auto generate at shader compile time
    matcap_shader_desc := cg.Shader_Description {
        uniform_buffer_typeid   = typeid_of(Uniform_Buffer_Object),
        vertex_shader_path      = "callisto/resources/shaders/matcap.vert.spv",
        fragment_shader_path    = "callisto/resources/shaders/matcap.frag.spv",
        cull_mode               = .NONE, // .BACK by default
    }

    geo_path := "resources/glTF-Sample-Models/2.0/Lantern/glTF-Binary/Lantern.glb"
    geo_mesh_assets, geo_material_assets := importer.import_gltf(geo_path) or_return
    defer asset.delete(&geo_mesh_assets)
    defer asset.delete(&geo_material_assets)

    geo_meshes = make([]cg.Mesh, len(geo_mesh_assets))
    defer delete(geo_meshes)

    for i in 0..<len(geo_mesh_assets) {        
        cg.create_static_mesh(&geo_mesh_assets[i], &geo_meshes[i]) or_return
    }
    defer {
        for geo_mesh in geo_meshes {
            cg.destroy_static_mesh(geo_mesh)
        }
    }

    cg.create_shader(&matcap_shader_desc, &matcap_shader) or_return
    defer cg.destroy_shader(matcap_shader)

    cg.create_material_instance(matcap_shader, &matcap_material) or_return
    defer cg.destroy_material_instance(matcap_material)

    matcap_texture_desc := cg.Texture_Description {
        image_path = "callisto/resources/textures/matcap/png/basic_1.png",
        color_space = .SRGB,
    }
    cg.create_texture(&matcap_texture_desc, &matcap_texture) or_return
    defer cg.destroy_texture(matcap_texture)

    cg.set_material_instance_texture(matcap_material, matcap_texture, 1)

    camera_transform := linalg.matrix4_translate_f32({0, 0, -50})

    aspect_ratio := f32(config.WINDOW_WIDTH) / f32(config.WINDOW_HEIGHT)
    geo_uniform_data.proj = linalg.matrix4_perspective_f32(linalg.to_radians(f32(-40)), aspect_ratio, 0.1, 1000, false)
    geo_uniform_data.view = linalg.matrix4_inverse_f32(camera_transform)

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

    return true
}

loop :: proc() {

    geo_uniform_data.model *= linalg.matrix4_rotate_f32(delta_time, linalg.VECTOR3F32_Y_AXIS)

    cg.upload_material_uniforms(matcap_material, &geo_uniform_data)
    
    cg.cmd_record()
    cg.cmd_begin_render_pass()
    cg.cmd_bind_material_instance(matcap_material)
    for geo_mesh in geo_meshes {
        cg.cmd_draw(geo_mesh)
    }
    cg.cmd_end_render_pass()
    cg.cmd_present()
    // log.infof("{:2.6f} : {:i}fps", delta_time, int(1 / delta_time))

}
