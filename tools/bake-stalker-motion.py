"""Retarget source FBX deformation into the imported Roblox bone coordinate frames.

Run in Blender after the Studio-normalized StalkerSkin.rbxmx has been saved.
The source and Roblox bone axes differ. Global skinning deltas preserve the
authored deformation while retaining Roblox's imported bind pose.
"""
import bpy
import json
import math
from pathlib import Path
from mathutils import Matrix, Vector
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
tree = ET.parse(ROOT / "assets/prefabs/StalkerSkin.rbxmx")
mesh = next(node for node in tree.iter("Item") if node.attrib["class"] == "MeshPart")

def cframe(element):
    values = [float(element.find(name).text) for name in
              ("X", "Y", "Z", "R00", "R01", "R02", "R10", "R11", "R12", "R20", "R21", "R22")]
    return Matrix(((values[3], values[4], values[5], values[0]),
                   (values[6], values[7], values[8], values[1]),
                   (values[9], values[10], values[11], values[2]), (0, 0, 0, 1)))

mesh_frame = cframe(mesh.find("Properties/CoordinateFrame[@name='CFrame']"))
rest_world, rest_local, parents = {}, {}, {}

def bind_bones(node, parent_name, parent_frame):
    for child in node.findall("Item[@class='Bone']"):
        name = child.find("Properties/string[@name='Name']").text
        local = cframe(child.find("Properties/CoordinateFrame[@name='CFrame']"))
        rest_local[name], rest_world[name], parents[name] = local, parent_frame @ local, parent_name
        bind_bones(child, name, rest_world[name])

bind_bones(mesh, None, mesh_frame)
axis = Matrix(((-1, 0, 0, 0), (0, 0, 1, 0), (0, 1, 0, 0), (0, 0, 0, 1)))
clips = {}
reference_rest, reference_mapping = None, None
for clip_name in ("Idle", "Walk", "Run"):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=str(ROOT / f".cache-v4/monster/{clip_name}.fbx"))
    source_mesh = next(obj for obj in bpy.context.scene.objects if obj.type == "MESH")
    arm = next(mod.object for mod in source_mesh.modifiers if mod.type == "ARMATURE")
    action = arm.animation_data.action
    start, end = (int(value) for value in action.frame_range)
    bpy.context.scene.frame_set(start)
    source_rest = {name: arm.matrix_world @ arm.data.bones[name].matrix_local for name in rest_world}
    linear = Matrix.Scale(5, 4) @ axis
    offsets = [rest_world[name].translation - (linear @ source_rest[name]).translation for name in rest_world]
    offset = sum(offsets, Vector()) / len(offsets)
    mapping = Matrix.Translation(offset) @ linear
    error = max((rest_world[name].translation - (mapping @ source_rest[name]).translation).length for name in rest_world)
    print(clip_name, "bind-position maximum error", error)
    if clip_name == "Idle":
        assert error < .01, "Source skeleton and Studio skeleton no longer match"
        reference_rest = source_rest
        reference_mapping = mapping
    # The other FBX exports have posed bind frames. Target the same imported
    # Idle mesh bind pose using their absolute animated joint frames.
    frames = []
    for frame in range(start, end + 1, 2):
        bpy.context.scene.frame_set(frame)
        posed = {}
        for name in rest_world:
            source_pose = arm.matrix_world @ arm.pose.bones[name].matrix
            deformation = reference_mapping @ source_pose @ reference_rest[name].inverted() @ reference_mapping.inverted()
            posed[name] = deformation @ rest_world[name]
        root_name = next(name for name, parent in parents.items() if parent is None)
        shift = posed[root_name].translation - rest_world[root_name].translation
        shift.y = 0
        for matrix in posed.values():
            matrix.translation -= shift
        values = {}
        for name in rest_world:
            parent = posed[parents[name]] if parents[name] else mesh_frame
            delta = rest_local[name].inverted() @ parent.inverted() @ posed[name]
            position, rotation, scale = delta.decompose()
            clean = rotation.to_matrix()
            values[name] = [round(value, 4) for value in
                            (*position, *clean[0], *clean[1], *clean[2])]
        frames.append(values)
    clips[clip_name] = {"fps": bpy.context.scene.render.fps / 2, "frames": frames}

encoded = json.dumps(clips, separators=(",", ":"))
(ROOT / "assets/imports/stalker-motion.json").write_text(encoded, encoding="utf8")
clip_folder = ROOT / "src/ReplicatedStorage/Shared/StalkerClips"
clip_folder.mkdir(exist_ok=True)
for name, clip in clips.items():
    source = 'return game:GetService("HttpService"):JSONDecode([==[' + json.dumps(clip, separators=(",", ":")) + ']==])\n'
    assert len(source) < 200000, "Roblox source size limit exceeded"
    (clip_folder / (name + ".lua")).write_text(source, encoding="utf8")
(ROOT / "src/ReplicatedStorage/Shared/StalkerMotion.lua").write_text(
    'return {\n    Idle = require(script.Parent.StalkerClips.Idle),\n'
    '    Walk = require(script.Parent.StalkerClips.Walk),\n'
    '    Run = require(script.Parent.StalkerClips.Run),\n}\n', encoding="utf8")
print("Retargeted", len(rest_world), "Roblox bones across three source-authored clips")
