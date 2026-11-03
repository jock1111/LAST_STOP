"""Prepare CC0 sources for Studio. Run with Blender 4.5 in background mode."""
import bpy
import json
import runpy
from pathlib import Path
from mathutils import Matrix

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "imports"
OUT.mkdir(parents=True, exist_ok=True)

def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)

reset()
for index, source in enumerate(sorted((ROOT / "assets/vendor/kenney-space-station").glob("*.glb"))):
    bpy.ops.object.select_all(action="DESELECT")
    before = set(bpy.context.scene.objects)
    bpy.ops.import_scene.gltf(filepath=str(source))
    imported = set(bpy.context.scene.objects) - before
    meshes = [obj for obj in imported if obj.type == "MESH"]
    for obj in meshes:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    bpy.ops.object.join()
    obj = bpy.context.object
    obj.name = source.stem
    # Imported kit is meter based. Roblox's importer treats glTF units as studs.
    obj.scale *= 8
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.location.x += index * 24
    for other in list(bpy.context.scene.objects):
        if other.type == "EMPTY":
            bpy.data.objects.remove(other, do_unlink=True)
bpy.ops.export_scene.gltf(filepath=str(OUT / "Environment.glb"), export_format="GLB", export_animations=False)

clips = {}
for clip in ("Idle", "Walk", "Run"):
    reset()
    bpy.ops.import_scene.fbx(filepath=str(ROOT / f".cache-v4/monster/{clip}.fbx"))
    mesh = next(obj for obj in bpy.context.scene.objects if obj.type == "MESH")
    arm = next(mod.object for mod in mesh.modifiers if mod.type == "ARMATURE")
    action = arm.animation_data.action
    start, end = [int(value) for value in action.frame_range]
    bpy.context.scene.frame_set(start)
    # Keep source bone-local deltas. glTF uses Y-up conversion on root nodes only.
    frames = []
    for frame in range(start, end + 1, 2):
        bpy.context.scene.frame_set(frame)
        frames.append({bone.name: [round(value, 6) for row in bone.matrix_basis for value in row]
                       for bone in arm.pose.bones})
    clips[clip] = {"fps": bpy.context.scene.render.fps / 2, "frames": frames}
    if clip == "Idle":
        bpy.context.scene.frame_set(start)
        transforms = {obj: obj.matrix_world.copy() for obj in (mesh, arm)}
        arm.parent = None
        arm.matrix_world = transforms[arm]
        mesh.parent = arm
        mesh.matrix_world = transforms[mesh]
        keep = {mesh, arm}
        for obj in list(bpy.context.scene.objects):
            if obj not in keep:
                bpy.data.objects.remove(obj, do_unlink=True)
        # Blender's FBX importer has already converted the evaluated rig to Z-up.
        arm.matrix_world = Matrix.Scale(5, 4) @ transforms[arm]
        mesh.name = "StalkerSkin"
        arm.name = "StalkerRig"
        for material in mesh.data.materials:
            material.use_nodes = True
            nodes = material.node_tree.nodes
            nodes.clear()
            output = nodes.new("ShaderNodeOutputMaterial")
            shader = nodes.new("ShaderNodeBsdfPrincipled")
            shader.inputs["Roughness"].default_value = .73
            texture = nodes.new("ShaderNodeTexImage")
            texture.image = bpy.data.images.load(str(ROOT / ".cache-v4/monster/test_StingrayPBS1SG_AlbedoTransparency.png"))
            material.node_tree.links.new(texture.outputs["Color"], shader.inputs["Base Color"])
            material.node_tree.links.new(shader.outputs["BSDF"], output.inputs["Surface"])
        arm.animation_data_clear()
        bpy.context.view_layer.update()
        bpy.ops.export_scene.gltf(filepath=str(OUT / "Stalker.glb"), export_format="GLB", export_animations=False)

(OUT / "stalker-motion.json").write_text(json.dumps(clips, separators=(",", ":")))
runpy.run_path(str(ROOT / "tools/bake-stalker-motion.py"), run_name="__main__")
print("Prepared Environment.glb, Stalker.glb, and source-authored skeletal motion")
