"""
Low-Poly Frog Generator for Godot
==================================
Run this script inside Blender's Scripting workspace.

It will:
  1. Build a low-poly frog mesh (body, eyes, legs)
  2. Create and bind an Armature (skeleton)
  3. Generate three NLA animations:
       - "idle"   : subtle breathing bob
       - "walk"   : leg pump cycle
       - "jump"   : full leap arc + land squish
  4. Apply flat shading + a vertex-colour material

After running:
  File -> Export -> glTF 2.0  (.glb)
  Check "Include Animations" and "Armature"
  Drop the .glb into your Godot project.
"""

import bpy
import math
from mathutils import Vector, Euler

# -- helpers -------------------------------------------------------------------

def clear_scene():
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    for col in bpy.data.collections:
        bpy.data.collections.remove(col)

def new_mat(name, r, g, b):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (r, g, b, 1.0)
    bsdf.inputs["Roughness"].default_value = 1.0
    bsdf.inputs["Specular IOR Level"].default_value = 0.0
    return mat

def set_flat(obj):
    for poly in obj.data.polygons:
        poly.use_smooth = False

# -- materials -----------------------------------------------------------------

clear_scene()

mat_body  = new_mat("FrogGreen",  0.18, 0.55, 0.22)
mat_belly = new_mat("FrogBelly",  0.75, 0.90, 0.55)
mat_eye   = new_mat("FrogEye",    0.95, 0.85, 0.10)
mat_pupil = new_mat("FrogPupil",  0.05, 0.05, 0.05)

# -- body ----------------------------------------------------------------------

bpy.ops.mesh.primitive_uv_sphere_add(
    segments=8, ring_count=6,
    radius=0.5,
    location=(0, 0, 0.2)
)
body_obj = bpy.context.active_object
body_obj.name = "FrogBody"

bpy.ops.object.mode_set(mode='EDIT')
bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.transform.resize(value=(1.3, 1.0, 0.75))
bpy.ops.object.mode_set(mode='OBJECT')

body_obj.data.materials.append(mat_body)
body_obj.data.materials.append(mat_belly)

for p in body_obj.data.polygons:
    if p.normal.z < -0.2:
        p.material_index = 1

set_flat(body_obj)

# -- head bump -----------------------------------------------------------------

bpy.ops.mesh.primitive_uv_sphere_add(
    segments=6, ring_count=4,
    radius=0.32,
    location=(0.42, 0, 0.34)
)
head_obj = bpy.context.active_object
head_obj.name = "FrogHead"
head_obj.data.materials.append(mat_body)
set_flat(head_obj)

# -- eyes ----------------------------------------------------------------------

for side, x in (("L", 0.30), ("R", -0.30)):
    bpy.ops.mesh.primitive_uv_sphere_add(
        segments=6, ring_count=4, radius=0.11,
        location=(0.52, x, 0.55)
    )
    e = bpy.context.active_object
    e.name = "Eye_" + side
    e.data.materials.append(mat_eye)
    set_flat(e)

    bpy.ops.mesh.primitive_uv_sphere_add(
        segments=5, ring_count=3, radius=0.055,
        location=(0.625, x, 0.555)
    )
    p = bpy.context.active_object
    p.name = "Pupil_" + side
    p.data.materials.append(mat_pupil)
    set_flat(p)

# -- front legs ----------------------------------------------------------------

def make_limb(name, loc, rot_deg, scale, mat):
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=5, radius=0.07, depth=0.35,
        location=loc,
        rotation=tuple(math.radians(d) for d in rot_deg)
    )
    obj = bpy.context.active_object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(scale=True)
    obj.data.materials.append(mat)
    set_flat(obj)
    return obj

make_limb("FrontLeg_L", ( 0.38,  0.50, 0.02), (20, -20,  10), (1,1,1), mat_body)
make_limb("FrontLeg_R", ( 0.38, -0.50, 0.02), (20,  20, -10), (1,1,1), mat_body)

# -- back legs -----------------------------------------------------------------

make_limb("BackThigh_L",  (-0.30,  0.55, 0.10), ( 40, -50,  30), (1.1,1.1,1.3), mat_body)
make_limb("BackThigh_R",  (-0.30, -0.55, 0.10), ( 40,  50, -30), (1.1,1.1,1.3), mat_body)
make_limb("BackLower_L",  (-0.50,  0.65,-0.08), (-30, -60,  20), (0.9,0.9,1.1), mat_body)
make_limb("BackLower_R",  (-0.50, -0.65,-0.08), (-30,  60, -20), (0.9,0.9,1.1), mat_body)

# -- feet ----------------------------------------------------------------------

for side, y in (("L",  0.72), ("R", -0.72)):
    bpy.ops.mesh.primitive_cube_add(size=1, location=(-0.65, y, -0.14))
    ft = bpy.context.active_object
    ft.name = "Foot_" + side
    ft.scale = (0.22, 0.13, 0.06)
    bpy.ops.object.transform_apply(scale=True)
    ft.data.materials.append(mat_body)
    set_flat(ft)

# -- join everything into one mesh ---------------------------------------------

bpy.ops.object.select_all(action='SELECT')
bpy.context.view_layer.objects.active = body_obj
bpy.ops.object.join()
frog_mesh = bpy.context.active_object
frog_mesh.name = "Frog"
frog_mesh.location = (0, 0, 0)

# -- armature ------------------------------------------------------------------

bpy.ops.object.armature_add(location=(0, 0, 0))
arm_obj = bpy.context.active_object
arm_obj.name = "FrogArmature"
arm  = arm_obj.data
arm.name = "FrogRig"

bpy.ops.object.mode_set(mode='EDIT')
bones = arm.edit_bones

def add_bone(name, head, tail, parent=None):
    b = bones.new(name)
    b.head = Vector(head)
    b.tail = Vector(tail)
    if parent:
        b.parent = bones[parent]
        b.use_connect = False
    return b

add_bone("root",       (0,0,0),       (0,0,0.1))
add_bone("spine",      (0,0,0.2),     (0.4,0,0.28),  "root")
add_bone("head",       (0.4,0,0.28),  (0.7,0,0.36),  "spine")
add_bone("front_leg_L",(0.3, 0.45,0.05), (0.35, 0.72,-0.05), "spine")
add_bone("front_leg_R",(0.3,-0.45,0.05), (0.35,-0.72,-0.05), "spine")
add_bone("hip_L",      (-0.2, 0.40, 0.10), (-0.30, 0.58, 0.12), "root")
add_bone("hip_R",      (-0.2,-0.40, 0.10), (-0.30,-0.58, 0.12), "root")
add_bone("lower_leg_L",(-0.30, 0.58, 0.12), (-0.52, 0.68,-0.05), "hip_L")
add_bone("lower_leg_R",(-0.30,-0.58, 0.12), (-0.52,-0.68,-0.05), "hip_R")
add_bone("foot_L",     (-0.52, 0.68,-0.05), (-0.70, 0.72,-0.14), "lower_leg_L")
add_bone("foot_R",     (-0.52,-0.68,-0.05), (-0.70,-0.72,-0.14), "lower_leg_R")

bpy.ops.object.mode_set(mode='OBJECT')

# -- parent mesh to armature ---------------------------------------------------

frog_mesh.select_set(True)
arm_obj.select_set(True)
bpy.context.view_layer.objects.active = arm_obj
bpy.ops.object.parent_set(type='ARMATURE_AUTO')

# -- animation helper ----------------------------------------------------------

arm_obj.animation_data_create()

def use_action(name):
    act = bpy.data.actions.get(name) or bpy.data.actions.new(name)
    arm_obj.animation_data.action = act
    return act

def kf(bone_name, frame, loc=(0,0,0), rot_deg=(0,0,0)):
    pb = arm_obj.pose.bones.get(bone_name)
    if pb is None:
        return
    pb.location = Vector(loc)
    pb.rotation_mode = 'XYZ'
    pb.rotation_euler = Euler([math.radians(r) for r in rot_deg], 'XYZ')
    pb.keyframe_insert("location",       frame=frame)
    pb.keyframe_insert("rotation_euler", frame=frame)

# -- IDLE (40 frames) ----------------------------------------------------------

use_action("idle")
for f in (1, 20, 40):
    z = 0.015 if f == 20 else 0.0
    kf("spine", f, loc=(0, 0, z))
    kf("head",  f, rot_deg=(0, 2 if z else -2, 0))

# -- WALK (24 frames loop) -----------------------------------------------------

use_action("walk")
for f, fwd in ((1, 0.0), (12, 0.25), (24, 0.5)):
    kf("root", f, loc=(fwd, 0, 0))

for side, sign in (("L", 1), ("R", -1)):
    for f, ang in ((1, sign*25), (12, sign*-25), (24, sign*25)):
        kf("hip_" + side,       f, rot_deg=(ang, 0, 0))
        kf("lower_leg_" + side, f, rot_deg=(-abs(ang)*0.6, 0, 0))
        kf("foot_" + side,      f, rot_deg=(ang*0.3, 0, 0))

for f, ang in ((1,0),(6,3),(12,0),(18,-3),(24,0)):
    kf("spine", f, rot_deg=(0, 0, ang))

# -- JUMP (36 frames) ----------------------------------------------------------

use_action("jump")
# frame, root_z, spine_rot, hip_ang, lower_ang
jump_keys = [
    ( 1,  0.00,   0,  15, -20),
    ( 6, -0.08, -15,  45, -55),
    (12,  0.35,  10, -50,  30),
    (20,  0.70,   5, -35,  20),
    (28,  0.00,  -5,  30, -35),
    (32, -0.06, -12,  40, -50),
    (36,  0.00,   0,  15, -20),
]
for (fr, rz, sr, ha, la) in jump_keys:
    kf("root",  fr, loc=(0, 0, rz))
    kf("spine", fr, rot_deg=(sr, 0, 0))
    for side in ("L", "R"):
        kf("hip_" + side,       fr, rot_deg=(ha, 0, 0))
        kf("lower_leg_" + side, fr, rot_deg=(la, 0, 0))

# -- NLA strips ----------------------------------------------------------------

nla = arm_obj.animation_data.nla_tracks
for act_name in ("idle", "walk", "jump"):
    act = bpy.data.actions[act_name]
    track = nla.new()
    track.name = act_name
    strip = track.strips.new(act_name, 1, act)
    strip.name = act_name

arm_obj.animation_data.action = bpy.data.actions["idle"]

# -- scene settings ------------------------------------------------------------

bpy.context.scene.render.fps = 30
bpy.context.scene.frame_start = 1
bpy.context.scene.frame_end   = 40

frog_mesh.rotation_euler = (0, 0, math.radians(180))
arm_obj.rotation_euler   = (0, 0, math.radians(180))

print("=" * 55)
print("Low-poly frog generated!")
print("  Animations: idle (40f) | walk (24f) | jump (36f)")
print()
print("EXPORT:")
print("  File -> Export -> glTF 2.0 (.glb)")
print("  [x] Include Armature")
print("  [x] Include Animations")
print("  [x] NLA Strips")
print("  Save as: frog.glb")
print("=" * 55)
