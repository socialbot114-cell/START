"""Generate premium, offline SceneKit-ready START dice with Blender.

Run with:
  blender -b --python Scripts/generate_dice_assets.py -- START/Art.scnassets/Dice

The script writes one USDZ per die plus an editable Blender studio file and a
render preview. Geometry and numbering are generated deterministically.
"""

from __future__ import annotations

import math
import os
import random
import sys
from itertools import combinations

import bpy
import bmesh
from mathutils import Vector


RADIUS = 1.18
GOLDEN_RATIO = (1 + math.sqrt(5.0)) / 2
TOLERANCE = 0.0002

RESIN_COLORS = {
    4: (0.66, 0.075, 0.085, 1.0),  # ruby red
    6: (0.82, 0.77, 0.65, 1.0),    # classic ivory
    8: (0.055, 0.20, 0.50, 1.0),   # cobalt blue
    10: (0.055, 0.35, 0.21, 1.0),  # racing green
    12: (0.33, 0.105, 0.52, 1.0),  # violet
    20: (0.045, 0.13, 0.45, 1.0),  # deep blue
}


def output_directory() -> str:
    argv = sys.argv
    if "--" in argv and len(argv) > argv.index("--") + 1:
        return os.path.abspath(argv[argv.index("--") + 1])
    return os.path.abspath("START/Art.scnassets/Dice")


def clear_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for datablocks in (bpy.data.meshes, bpy.data.curves, bpy.data.materials, bpy.data.cameras, bpy.data.lights):
        for datablock in list(datablocks):
            if datablock.users == 0:
                datablocks.remove(datablock)


def sign_pairs(values):
    for a in (-1.0, 1.0):
        for b in (-1.0, 1.0):
            yield a * values[0], b * values[1]


def pentagonal_trapezohedron_vertices():
    tau = math.pi * 2
    upper = [Vector((math.cos(tau * i / 5), math.sin(tau * i / 5), 0.5)) for i in range(5)]
    lower = [Vector((math.cos(tau * (i + 0.5) / 5), math.sin(tau * (i + 0.5) / 5), -0.5)) for i in range(5)]
    polygons = [upper, list(reversed(lower))]
    for i in range(5):
        polygons.append([upper[i], upper[(i + 1) % 5], lower[i]])
        polygons.append([upper[i], lower[i], lower[(i + 4) % 5]])

    dual_vertices = []
    for polygon in polygons:
        center = sum(polygon, Vector()) / len(polygon)
        normal = (polygon[1] - polygon[0]).cross(polygon[2] - polygon[0]).normalized()
        if normal.dot(center) < 0:
            normal.negate()
        plane_distance = normal.dot(center)
        dual_vertices.append(normal / plane_distance)
    return dual_vertices


def raw_vertices(sides):
    if sides == 4:
        return [Vector(v) for v in [(1, 1, 1), (1, -1, -1), (-1, 1, -1), (-1, -1, 1)]]
    if sides == 6:
        return [Vector((x, y, z)) for x in (-1, 1) for y in (-1, 1) for z in (-1, 1)]
    if sides == 8:
        return [Vector(v) for v in [(1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1)]]
    if sides == 10:
        return pentagonal_trapezohedron_vertices()
    if sides == 12:
        phi = GOLDEN_RATIO
        inv_phi = 1 / phi
        points = [Vector((x, y, z)) for x in (-1, 1) for y in (-1, 1) for z in (-1, 1)]
        for a, b in sign_pairs((inv_phi, phi)):
            points.extend([Vector((0, a, b)), Vector((a, b, 0)), Vector((b, 0, a))])
        return points
    if sides == 20:
        phi = GOLDEN_RATIO
        points = []
        for a in (-1.0, 1.0):
            for b in (-1.0, 1.0):
                points.extend([Vector((0, a, b * phi)), Vector((a, b * phi, 0)), Vector((b * phi, 0, a))])
        return points
    raise ValueError(f"Unsupported die: D{sides}")


def convex_faces(vertices):
    faces_by_key = {}
    for i, j, k in combinations(range(len(vertices)), 3):
        a = vertices[i]
        normal = (vertices[j] - a).cross(vertices[k] - a)
        if normal.length < TOLERANCE:
            continue
        normal.normalize()
        distance = normal.dot(a)
        signed = [normal.dot(point) - distance for point in vertices]
        has_positive = any(v > TOLERANCE for v in signed)
        has_negative = any(v < -TOLERANCE for v in signed)
        if has_positive and has_negative:
            continue
        if has_positive:
            normal.negate()
        plane_distance = normal.dot(a)
        coplanar = [idx for idx, point in enumerate(vertices) if abs(normal.dot(point) - plane_distance) <= TOLERANCE]
        if len(coplanar) < 3:
            continue
        key = tuple(sorted(coplanar))
        if key in faces_by_key:
            continue

        center = sum((vertices[idx] for idx in coplanar), Vector()) / len(coplanar)
        u = (vertices[coplanar[0]] - center).normalized()
        v = normal.cross(u)
        ordered = sorted(coplanar, key=lambda idx: math.atan2((vertices[idx] - center).dot(v), (vertices[idx] - center).dot(u)))
        faces_by_key[key] = {"indices": ordered, "center": center, "normal": normal}

    return sorted(faces_by_key.values(), key=lambda face: (round(face["normal"].z, 5), round(face["normal"].y, 5), round(face["normal"].x, 5)))


def numbered_faces(faces, sides):
    if sides == 4 or sides % 2:
        return faces

    def negative(normal):
        for component in (normal.z, normal.y, normal.x):
            if abs(component) > 0.0001:
                return component < 0
        return False

    low = sorted((face for face in faces if negative(face["normal"])), key=lambda face: (face["normal"].z, face["normal"].y, face["normal"].x))
    high = [face for face in faces if not negative(face["normal"])]
    if len(low) != sides // 2 or len(high) != sides // 2:
        raise RuntimeError(f"D{sides} did not split into opposite faces")

    ordered = [None] * sides
    for index, face in enumerate(low):
        opposite_index = min(range(len(high)), key=lambda i: face["normal"].dot(high[i]["normal"]))
        opposite = high.pop(opposite_index)
        if face["normal"].dot(opposite["normal"]) > -0.98:
            raise RuntimeError(f"D{sides} opposite face pairing failed")
        ordered[index] = face
        ordered[sides - index - 1] = opposite
    return ordered


def principled_material(name, color, roughness=0.22, metallic=0.02, coat=0.75, micrograin=None):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = color
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    bsdf = nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = color
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["IOR"].default_value = 1.47
    coat_input = bsdf.inputs.get("Coat Weight") or bsdf.inputs.get("Clearcoat")
    coat_rough = bsdf.inputs.get("Coat Roughness") or bsdf.inputs.get("Clearcoat Roughness")
    if coat_input:
        coat_input.default_value = coat
    if coat_rough:
        coat_rough.default_value = 0.12

    if micrograin is not None:
        tex = nodes.new("ShaderNodeTexImage")
        tex.image = micrograin
        tex.interpolation = "Linear"
        tex.extension = "REPEAT"
        tex.image.colorspace_settings.name = "Non-Color"

        rough_map = nodes.new("ShaderNodeMapRange")
        rough_map.inputs["From Min"].default_value = 0.0
        rough_map.inputs["From Max"].default_value = 1.0
        rough_map.inputs["To Min"].default_value = max(0.12, roughness - 0.035)
        rough_map.inputs["To Max"].default_value = min(0.38, roughness + 0.04)
        links.new(tex.outputs["Color"], rough_map.inputs["Value"])
        links.new(rough_map.outputs["Result"], bsdf.inputs["Roughness"])

        bump = nodes.new("ShaderNodeBump")
        bump.inputs["Strength"].default_value = 0.08
        bump.inputs["Distance"].default_value = 0.0015
        links.new(tex.outputs["Color"], bump.inputs["Height"])
        links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])
    return mat


def create_micrograin_image():
    rng = random.Random(2091)
    width = height = 256
    image = bpy.data.images.new("START - Molded resin micrograin", width=width, height=height, alpha=False, float_buffer=False)
    pixels = []
    for _ in range(width * height):
        value = 0.5 + rng.uniform(-0.09, 0.09)
        pixels.extend((value, value, value, 1.0))
    image.pixels.foreach_set(pixels)
    image.colorspace_settings.name = "Non-Color"
    image.pack()
    return image


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for block_collection in (bpy.data.meshes, bpy.data.curves, bpy.data.materials, bpy.data.cameras, bpy.data.lights):
        for block in list(block_collection):
            if block.users == 0:
                block_collection.remove(block)


def link_object(name, data, collection, parent=None):
    obj = bpy.data.objects.new(name, data)
    collection.objects.link(obj)
    if parent is not None:
        obj.parent = parent
    return obj


def assign_uvs(obj):
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(island_margin=0.015)
    bpy.ops.object.mode_set(mode="OBJECT")


def create_text(label, name, position, normal, size, material, collection, parent, font=None):
    curve = bpy.data.curves.new(name, type="FONT")
    curve.body = str(label)
    curve.size = size
    curve.extrude = 0.006
    curve.bevel_depth = 0.0015
    curve.bevel_resolution = 3
    curve.align_x = "CENTER"
    curve.align_y = "CENTER"
    if font:
        curve.font = font
    curve.materials.append(material)
    obj = link_object(name, curve, collection, parent)
    obj.location = position + normal * 0.012
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = Vector((0, 0, 1)).rotation_difference(normal)
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.convert(target="MESH")
    return bpy.context.view_layer.objects.active


def create_pip(value, face, vertices, material, collection, parent):
    center = face["center"]
    normal = face["normal"]
    edge = min(
        (vertices[face["indices"][i]] - vertices[face["indices"][(i + 1) % len(face["indices"])] ]).length
        for i in range(len(face["indices"]))
    )
    offset = edge * 0.20
    u = (vertices[face["indices"][0]] - center).normalized()
    v = normal.cross(u).normalized()
    positions = {
        1: [(0, 0)],
        2: [(-offset, -offset), (offset, offset)],
        3: [(-offset, -offset), (0, 0), (offset, offset)],
        4: [(-offset, -offset), (offset, -offset), (-offset, offset), (offset, offset)],
        5: [(-offset, -offset), (offset, -offset), (0, 0), (-offset, offset), (offset, offset)],
        6: [(-offset, -offset), (0, -offset), (offset, -offset), (-offset, offset), (0, offset), (offset, offset)]
    }[value]

    radius = min(0.057, edge * 0.049)
    for dot_index, (x, y) in enumerate(positions, 1):
        location = center + normal * 0.004 + u * x + v * y
        bpy.ops.mesh.primitive_cylinder_add(vertices=48, radius=radius, depth=0.014, location=location)
        pip = bpy.context.object
        pip.name = f"D6_Pip_{value}_{dot_index:02d}"
        pip.rotation_mode = "QUATERNION"
        pip.rotation_quaternion = Vector((0, 0, 1)).rotation_difference(normal)
        pip.data.materials.append(material)
        for polygon in pip.data.polygons:
            polygon.use_smooth = True
        bevel = pip.modifiers.new("Rounded ink edge", "BEVEL")
        bevel.width = 0.004
        bevel.segments = 3
        bpy.context.view_layer.objects.active = pip
        bpy.ops.object.modifier_apply(modifier=bevel.name)
        for owner in list(pip.users_collection):
            owner.objects.unlink(pip)
        collection.objects.link(pip)
        pip.parent = parent


def build_die(sides, micrograin, font):
    raw = raw_vertices(sides)
    radius = max(v.length for v in raw)
    vertices = [v / radius * RADIUS for v in raw]
    faces = numbered_faces(convex_faces(vertices), sides)
    if len(faces) != sides:
        raise RuntimeError(f"D{sides} generated {len(faces)} faces")

    collection = bpy.data.collections.new(f"D{sides}_Collection")
    bpy.context.scene.collection.children.link(collection)
    root = link_object(f"START_D{sides}_ROOT", None, collection)
    root.empty_display_type = "PLAIN_AXES"

    base_color = RESIN_COLORS[sides]
    variations = [0.96, 1.04, 0.99, 1.06]
    body_materials = []
    for index, factor in enumerate(variations):
        color = tuple(min(1.0, component * factor) for component in base_color[:3]) + (1.0,)
        mat = principled_material(f"D{sides} - Satin resin {index + 1}", color, roughness=0.22, metallic=0.025, coat=0.78, micrograin=micrograin)
        body_materials.append(mat)
    edge_color = tuple(min(1.0, c * 1.16 + 0.035) for c in base_color[:3]) + (1.0,)
    edge_material = principled_material(f"D{sides} - Molded bevel", edge_color, roughness=0.18, metallic=0.02, coat=0.62, micrograin=micrograin)

    mesh = bpy.data.meshes.new(f"D{sides}_ResinMesh")
    mesh.from_pydata([tuple(v) for v in vertices], [], [face["indices"] for face in faces])
    mesh.update()
    body = link_object(f"D{sides}_Body", mesh, collection, root)
    for mat in body_materials:
        mesh.materials.append(mat)
    mesh.materials.append(edge_material)
    for index, polygon in enumerate(mesh.polygons):
        polygon.material_index = index % len(body_materials)
        polygon.use_smooth = True
    assign_uvs(body)

    bevel = body.modifiers.new("Precision molded chamfer", "BEVEL")
    bevel.width = 0.052
    bevel.segments = 5
    bevel.profile = 0.52
    bevel.limit_method = "ANGLE"
    bevel.angle_limit = math.radians(18)
    bevel.material = len(mesh.materials) - 1
    bevel.harden_normals = True
    bpy.context.view_layer.objects.active = body
    bpy.ops.object.modifier_apply(modifier=bevel.name)
    weighted = body.modifiers.new("Weighted resin normals", "WEIGHTED_NORMAL")
    weighted.keep_sharp = True
    weighted.weight = 50
    bpy.ops.object.modifier_apply(modifier=weighted.name)

    # Numbers are printed/raised from the face surface; D4 follows real tetrahedral corner numbering.
    marking_material = principled_material(f"D{sides} - Warm ivory markings", (0.97, 0.92, 0.80, 1.0), roughness=0.27, metallic=0.0, coat=0.32)
    pip_material = principled_material(f"D6 - Ink-black pips", (0.045, 0.035, 0.027, 1.0), roughness=0.31, metallic=0.0, coat=0.24)
    if sides == 6:
        for face_index, face in enumerate(faces, 1):
            create_pip(face_index, face, vertices, pip_material, collection, root)
    elif sides == 4:
        for face_index, face in enumerate(faces, 1):
            for vertex_index in face["indices"]:
                point = face["center"] + (vertices[vertex_index] - face["center"]) * 0.66
                create_text(vertex_index + 1, f"D4_Face_{face_index:02d}_Vertex_{vertex_index + 1}", point, face["normal"], 0.34, marking_material, collection, root, font)
    else:
        face_size = {8: 0.43, 10: 0.43, 12: 0.40, 20: 0.36}[sides]
        for index, face in enumerate(faces, 1):
            create_text(index, f"D{sides}_Face_{index:02d}", face["center"], face["normal"], face_size, marking_material, collection, root, font)

    # Keep the imported die centered at origin with a consistent radial size.
    root.location = Vector((0, 0, 0))
    return root, collection, faces, vertices


def raw_vertices(sides):
    if sides == 4:
        return [Vector(v) for v in [(1, 1, 1), (1, -1, -1), (-1, 1, -1), (-1, -1, 1)]]
    if sides == 6:
        return [Vector((x, y, z)) for x in (-1, 1) for y in (-1, 1) for z in (-1, 1)]
    if sides == 8:
        return [Vector(v) for v in [(1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1)]]
    if sides == 10:
        return pentagonal_trapezohedron_vertices()
    if sides == 12:
        phi = GOLDEN_RATIO
        inverse = 1 / phi
        points = [Vector((x, y, z)) for x in (-1, 1) for y in (-1, 1) for z in (-1, 1)]
        for sign_a in (-1, 1):
            for sign_b in (-1, 1):
                points.extend([
                    Vector((0, sign_a * inverse, sign_b * phi)),
                    Vector((sign_a * inverse, sign_b * phi, 0)),
                    Vector((sign_a * phi, 0, sign_b * inverse))
                ])
        return points
    if sides == 20:
        phi = GOLDEN_RATIO
        points = []
        for a in (-1, 1):
            for b in (-1, 1):
                points.extend([Vector((0, a, b * phi)), Vector((a, b * phi, 0)), Vector((b * phi, 0, a))])
        return points
    raise ValueError(f"Unsupported D{sides}")


def pentagonal_trapezohedron_vertices():
    tau = math.pi * 2
    upper = [Vector((math.cos(tau * i / 5), math.sin(tau * i / 5), 0.5)) for i in range(5)]
    lower = [Vector((math.cos(tau * (i + 0.5) / 5), math.sin(tau * (i + 0.5) / 5), -0.5)) for i in range(5)]
    faces = [upper, list(reversed(lower))]
    for i in range(5):
        faces.append([upper[i], upper[(i + 1) % 5], lower[i]])
        faces.append([upper[i], lower[i], lower[(i + 4) % 5]])
    dual = []
    for polygon in faces:
        center = sum(polygon, Vector()) / len(polygon)
        normal = (polygon[1] - polygon[0]).cross(polygon[2] - polygon[0]).normalized()
        if normal.dot(center) < 0:
            normal.negate()
        dual.append(normal / normal.dot(center))
    return dual


def convex_faces(vertices):
    result = {}
    for i, j, k in combinations(range(len(vertices)), 3):
        anchor = vertices[i]
        normal = (vertices[j] - anchor).cross(vertices[k] - anchor)
        if normal.length < TOLERANCE:
            continue
        normal.normalize()
        plane = normal.dot(anchor)
        distances = [normal.dot(v) - plane for v in vertices]
        positive = any(value > TOLERANCE for value in distances)
        negative = any(value < -TOLERANCE for value in distances)
        if positive and negative:
            continue
        if positive:
            normal.negate()
        coplanar = [index for index, v in enumerate(vertices) if abs(normal.dot(v) - normal.dot(anchor)) <= TOLERANCE]
        if len(coplanar) < 3:
            continue
        key = tuple(sorted(coplanar))
        if key in result:
            continue
        center = sum((vertices[index] for index in coplanar), Vector()) / len(coplanar)
        u = (vertices[coplanar[0]] - center).normalized()
        v_axis = normal.cross(u)
        ordered = sorted(coplanar, key=lambda index: math.atan2((vertices[index] - center).dot(v_axis), (vertices[index] - center).dot(u)))
        result[key] = {"indices": ordered, "center": center, "normal": normal}
    return sorted(result.values(), key=lambda f: (round(f["normal"].z, 5), round(f["normal"].y, 5), round(f["normal"].x, 5)))


def numbered_faces(faces, sides):
    if sides == 4 or sides % 2:
        return faces

    def negative(normal):
        for component in (normal.z, normal.y, normal.x):
            if abs(component) > 1e-4:
                return component < 0
        return False

    low = sorted((face for face in faces if negative(face["normal"])), key=lambda f: (f["normal"].z, f["normal"].y, f["normal"].x))
    high = [face for face in faces if not negative(face["normal"])]
    if len(low) != sides // 2 or len(high) != sides // 2:
        raise RuntimeError(f"D{sides}: opposite face sets do not match")
    ordered = [None] * sides
    for index, face in enumerate(low):
        opposite_index = min(range(len(high)), key=lambda i: face["normal"].dot(high[i]["normal"]))
        opposite = high.pop(opposite_index)
        if face["normal"].dot(opposite["normal"]) > -0.98:
            raise RuntimeError(f"D{sides}: could not pair opposite faces")
        ordered[index] = face
        ordered[sides - index - 1] = opposite
    return ordered


def make_world_material():
    mat = bpy.data.materials.new("START - Dark walnut studio floor")
    mat.diffuse_color = (0.08, 0.038, 0.016, 1)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    bsdf = nodes.get("Principled BSDF")
    bsdf.inputs["Roughness"].default_value = 0.38
    noise = nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = 4.0
    noise.inputs["Detail"].default_value = 3.0
    ramp = nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].position = 0.18
    ramp.color_ramp.elements[0].color = (0.035, 0.014, 0.006, 1)
    ramp.color_ramp.elements[1].position = 0.82
    ramp.color_ramp.elements[1].color = (0.24, 0.092, 0.03, 1)
    links.new(noise.outputs["Fac"], ramp.inputs["Fac"])
    links.new(ramp.outputs["Color"], bsdf.inputs["Base Color"])
    bump = nodes.new("ShaderNodeBump")
    bump.inputs["Strength"].default_value = 0.11
    bump.inputs["Distance"].default_value = 0.08
    links.new(noise.outputs["Fac"], bump.inputs["Height"])
    links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])
    return mat


def configure_studio(roots, collections, output_dir):
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 32
    scene.cycles.use_denoising = True
    scene.render.resolution_x = 1800
    scene.render.resolution_y = 1080
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.film_transparent = False
    scene.view_settings.view_transform = "AgX"

    world = bpy.data.worlds.new("START - Warm dark studio") if not bpy.data.worlds else bpy.data.worlds[0]
    scene.world = world
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.12, 0.075, 0.045, 1)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.28

    floor_mesh = bpy.data.meshes.new("Walnut floor")
    floor_mesh.from_pydata([(-100, -100, -1.34), (100, -100, -1.34), (100, 100, -1.34), (-100, 100, -1.34)], [], [(0, 1, 2, 3)])
    floor_mesh.materials.append(make_world_material())
    floor = link_object("Studio walnut surface", floor_mesh, bpy.context.scene.collection)

    def area(name, location, energy, size, color, target):
        data = bpy.data.lights.new(name, type="AREA")
        data.energy = energy
        data.shape = "DISK"
        data.size = size
        data.color = color
        obj = link_object(name, data, bpy.context.scene.collection)
        obj.location = location
        obj.rotation_euler = (Vector(target) - obj.location).to_track_quat("-Z", "Y").to_euler()
        return obj

    area("Large warm softbox", (-3.5, -4.5, 7.0), 1100, 5.0, (1.0, 0.78, 0.53), (0, 0, 0))
    area("Cool fill strip", (5.0, -1.0, 4.0), 740, 3.5, (0.47, 0.68, 1.0), (0, 0, 0))
    area("Amber rim", (0.5, 4.0, 5.5), 1250, 3.0, (1.0, 0.54, 0.19), (0, 0, 0))

    camera_data = bpy.data.cameras.new("START Dice Studio Camera")
    camera = link_object("START Dice Studio Camera", camera_data, bpy.context.scene.collection)
    camera.location = (7.4, -11.6, 8.0)
    camera.rotation_euler = (Vector((0, -0.5, 0.15)) - camera.location).to_track_quat("-Z", "Y").to_euler()
    camera_data.type = "ORTHO"
    camera_data.ortho_scale = 12.8
    scene.camera = camera

    for index, root in enumerate(roots):
        col = index % 3
        row = index // 3
        root.location = Vector(((col - 1) * 3.6, (0.5 - row) * 3.7, 0))
    scene.render.filepath = os.path.join(output_dir, "START-dice-studio.png")
    scene.camera.data.lens = 50


def export_asset(sides, root, collection, out_dir):
    bpy.ops.object.select_all(action="DESELECT")
    for obj in collection.objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = root
    filepath = os.path.join(out_dir, f"D{sides}.usdz")
    bpy.ops.wm.usd_export(
        filepath=filepath,
        selected_objects_only=True,
        export_animation=False,
        export_materials=True,
        generate_preview_surface=True,
        generate_materialx_network=False,
        export_textures_mode="NEW",
        export_global_forward_selection="NEGATIVE_Y",
        export_global_up_selection="Z",
        export_lights=False,
        export_cameras=False,
        export_curves=False,
    )
    print(f"Exported {filepath}")


def main():
    out_dir = output_directory()
    os.makedirs(out_dir, exist_ok=True)
    project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    studio_dir = os.path.join(project_root, "Blender")
    os.makedirs(studio_dir, exist_ok=True)
    clear_scene()

    font_path = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
    font = bpy.data.fonts.load(font_path) if os.path.exists(font_path) else None
    if font:
        font.pack()
    roots = []
    collections = []
    grain = create_micrograin_image()
    for sides in (4, 6, 8, 10, 12, 20):
        root, collection, _, _ = build_die(sides, grain, font)
        roots.append(root)
        collections.append(collection)
        export_asset(sides, root, collection, out_dir)

    configure_studio(roots, collections, out_dir)
    blend_path = os.path.join(studio_dir, "START-dice-studio.blend")
    bpy.ops.wm.save_as_mainfile(filepath=blend_path)
    bpy.context.scene.render.resolution_x = 1600
    bpy.context.scene.render.resolution_y = 900
    bpy.context.scene.cycles.samples = 32
    bpy.context.scene.render.filepath = os.path.join(studio_dir, "START-dice-studio.png")
    bpy.ops.render.render(write_still=True)
    print(f"Saved editable Blender scene: {blend_path}")


if __name__ == "__main__":
    main()
