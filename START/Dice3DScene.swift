import SceneKit
import SwiftUI
import UIKit
import simd

struct Die3DView: UIViewRepresentable {
    let sides: Int
    let result: Int
    let rollToken: Int

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView(frame: .zero)
        view.backgroundColor = .clear
        view.scene = SCNScene()
        view.isPlaying = true
        view.antialiasingMode = .multisampling4X
        view.preferredFramesPerSecond = 60
        view.autoenablesDefaultLighting = false
        view.allowsCameraControl = false
        view.scene?.background.contents = UIColor.clear
        view.layer.isOpaque = false
        context.coordinator.view = view
        context.coordinator.update(sides: sides, result: result, rollToken: rollToken)
        return view
    }

    func updateUIView(_ view: SCNView, context: Context) {
        context.coordinator.view = view
        context.coordinator.update(sides: sides, result: result, rollToken: rollToken)
    }

    final class Coordinator {
        weak var view: SCNView?
        private var currentSides: Int?
        private var currentToken: Int?
        private var dieNode: SCNNode?
        private var faces: [PolyFace] = []
        private var vertices: [SIMD3<Float>] = []

        func update(sides: Int, result: Int, rollToken: Int) {
            guard let view else { return }
            if currentSides != sides {
                currentSides = sides
                currentToken = nil
                let built = DiceGeometry.make(sides: sides)
                faces = built.faces
                vertices = built.vertices
                dieNode?.removeFromParentNode()
                dieNode = built.node
                view.scene = DiceGeometry.scene(with: built.node)
            }
            guard let dieNode else { return }
            let target = DiceGeometry.orientation(sides: sides, result: result, faces: faces, vertices: vertices)
            if currentToken == nil {
                currentToken = rollToken
                dieNode.simdOrientation = target
            } else if currentToken != rollToken {
                currentToken = rollToken
                DiceGeometry.animate(dieNode, to: target)
            }
        }
    }
}

private struct PolyFace {
    let indices: [Int]
    let center: SIMD3<Float>
    let normal: SIMD3<Float>
}

private enum DiceGeometry {
    private static let warmKey = UIColor(red: 1.0, green: 0.73, blue: 0.43, alpha: 1)
    private static let faceInset: Float = 0.10
    private static let faceDepth: Float = 0.035

    static func make(sides: Int) -> (node: SCNNode, faces: [PolyFace], vertices: [SIMD3<Float>]) {
        let rawVertices = vertices(for: sides)
        let radius = rawVertices.map { simd_length($0) }.max() ?? 1
        let vertices = rawVertices.map { $0 / radius * 1.18 }
        let hull = convexFaces(vertices: vertices)
        let faces = numberedFaces(hull, sides: sides)
        precondition(faces.count == sides, "D\(sides) mesh generated \(faces.count) faces")
        let root = SCNNode()
        if let blenderAsset = loadBlenderAsset(sides: sides) {
            root.addChildNode(blenderAsset)
        } else {
            let body = makeBody(vertices: vertices, faces: faces, sides: sides)
            root.addChildNode(body)
            root.addChildNode(makeEdges(vertices: vertices, faces: faces, sides: sides))
            if sides == 4 {
                for face in faces {
                    for vertexIndex in face.indices {
                        let point = face.center + (vertices[vertexIndex] - face.center) * 0.66
                        root.addChildNode(makeLabel("\(vertexIndex + 1)", face: face, vertices: vertices, position: point, scaleMultiplier: 0.58))
                    }
                }
            } else if sides == 6 {
                for (index, face) in faces.enumerated() {
                    root.addChildNode(makePips(value: index + 1, face: face, vertices: vertices))
                }
            } else {
                for (index, face) in faces.enumerated() {
                    root.addChildNode(makeLabel("\(index + 1)", face: face, vertices: vertices))
                }
            }
        }
        root.simdScale = SIMD3<Float>(repeating: 1.0)
        return (root, faces, vertices)
    }

    private static func loadBlenderAsset(sides: Int) -> SCNNode? {
        let isUITesting = ProcessInfo.processInfo.arguments.contains("-ui-testing")
        guard let url = Bundle.main.url(
            forResource: "D\(sides)",
            withExtension: "usdz",
            subdirectory: "Art.scnassets/Dice"
        ) else {
            if isUITesting { fatalError("Missing Blender USDZ asset for D\(sides)") }
            return nil
        }
        let assetScene: SCNScene
        do {
            assetScene = try SCNScene(url: url, options: [.convertToYUp: false])
        } catch {
            if isUITesting { fatalError("SceneKit could not load D\(sides).usdz") }
            print("[START] USDZ load failed for D\(sides): \(error)")
            return nil
        }

        let model = SCNNode()
        model.name = "Blender_D\(sides)"
        for child in assetScene.rootNode.childNodes {
            model.addChildNode(child.clone())
        }
        guard !model.childNodes.isEmpty else {
            if isUITesting { fatalError("D\(sides).usdz contains no SceneKit nodes") }
            return nil
        }

        var minimum = SCNVector3Zero
        var maximum = SCNVector3Zero
        guard model.getBoundingBoxMin(&minimum, max: &maximum) else {
            if isUITesting { fatalError("Could not measure Blender D\(sides).usdz") }
            return nil
        }
        let center = SCNVector3((minimum.x + maximum.x) / 2, (minimum.y + maximum.y) / 2, (minimum.z + maximum.z) / 2)
        let maxExtent = max(max(maximum.x - minimum.x, maximum.y - minimum.y), maximum.z - minimum.z)
        guard maxExtent > 0.001 else {
            if isUITesting { fatalError("Blender D\(sides).usdz has invalid bounds") }
            return nil
        }
        model.pivot = SCNMatrix4MakeTranslation(center.x, center.y, center.z)
        let fitScale = 2.36 / maxExtent
        model.simdScale = SIMD3<Float>(repeating: fitScale)
        print("[START] Loaded Blender USDZ D\(sides)")
        return model
    }

    static func scene(with die: SCNNode) -> SCNScene {
        let scene = SCNScene()
        scene.background.contents = UIColor.clear

        let camera = SCNCamera()
        camera.fieldOfView = 35
        camera.wantsHDR = true
        let cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 0, 5.8)
        scene.rootNode.addChildNode(cameraNode)

        let key = SCNLight()
        key.type = .omni
        key.intensity = 460
        key.color = UIColor(red: 1.0, green: 0.82, blue: 0.57, alpha: 1)
        key.castsShadow = true
        key.shadowMode = .deferred
        key.shadowRadius = 7
        key.shadowSampleCount = 12
        key.shadowColor = UIColor.black.withAlphaComponent(0.48)
        let keyNode = SCNNode()
        keyNode.light = key
        keyNode.position = SCNVector3(-3, 4, 5)
        scene.rootNode.addChildNode(keyNode)

        let fill = SCNLight()
        fill.type = .omni
        fill.intensity = 190
        fill.color = UIColor(red: 0.50, green: 0.78, blue: 1.0, alpha: 1)
        let fillNode = SCNNode()
        fillNode.light = fill
        fillNode.position = SCNVector3(4, 1, 2)
        scene.rootNode.addChildNode(fillNode)

        let rim = SCNLight()
        rim.type = .directional
        rim.intensity = 360
        rim.color = warmKey
        let rimNode = SCNNode()
        rimNode.light = rim
        rimNode.eulerAngles = SCNVector3(-0.6, 0.7, 0)
        scene.rootNode.addChildNode(rimNode)

        let ambient = SCNLight()
        ambient.type = .ambient
        ambient.intensity = 110
        ambient.color = UIColor(white: 0.48, alpha: 1)
        let ambientNode = SCNNode()
        ambientNode.light = ambient
        scene.rootNode.addChildNode(ambientNode)

        let shadow = SCNNode(geometry: SCNPlane(width: 2.10, height: 0.52))
        shadow.position = SCNVector3(0, -1.32, -0.38)
        shadow.eulerAngles.x = -0.10
        let shadowMaterial = SCNMaterial()
        shadowMaterial.diffuse.contents = UIColor.black
        shadowMaterial.transparent.contents = makeSoftShadowTexture()
        shadowMaterial.lightingModel = .constant
        shadowMaterial.isDoubleSided = true
        shadowMaterial.transparencyMode = .aOne
        shadowMaterial.writesToDepthBuffer = false
        shadow.geometry?.materials = [shadowMaterial]
        shadow.opacity = 0.42
        scene.rootNode.addChildNode(shadow)

        die.position = SCNVector3(0, 0.06, 0)
        scene.rootNode.addChildNode(die)
        return scene
    }

    private static func makeSoftShadowTexture() -> UIImage {
        let size = CGSize(width: 256, height: 128)
        return UIGraphicsImageRenderer(size: size).image { renderer in
            let colors = [
                UIColor.black.withAlphaComponent(0.46).cgColor,
                UIColor.black.withAlphaComponent(0.18).cgColor,
                UIColor.clear.cgColor
            ] as CFArray
            let locations: [CGFloat] = [0, 0.55, 1]
            guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: locations) else { return }
            renderer.cgContext.drawRadialGradient(
                gradient,
                startCenter: CGPoint(x: size.width / 2, y: size.height / 2),
                startRadius: 2,
                endCenter: CGPoint(x: size.width / 2, y: size.height / 2),
                endRadius: size.width / 2,
                options: []
            )
        }
    }

    static func orientation(sides: Int, result: Int, faces: [PolyFace], vertices: [SIMD3<Float>]) -> simd_quatf {
        let chosenDirection: SIMD3<Float>
        if sides == 4 {
            chosenDirection = simd_normalize(vertices[(max(1, result) - 1) % vertices.count])
        } else {
            chosenDirection = faces[(max(1, result) - 1) % faces.count].normal
        }
        let cameraFacing = simd_quatf(from: chosenDirection, to: SIMD3<Float>(0, 0, 1))
        let revealSideFaces = simd_quatf(angle: .pi / 8, axis: SIMD3<Float>(1, 0, 0))
            * simd_quatf(angle: -.pi / 8, axis: SIMD3<Float>(0, 1, 0))
        return revealSideFaces * cameraFacing
    }

    static func animate(_ node: SCNNode, to target: simd_quatf) {
        let start = node.simdOrientation
        let axisA = simd_normalize(SIMD3<Float>(0.78, 0.54, 0.31))
        let axisB = simd_normalize(SIMD3<Float>(-0.28, 0.85, 0.44))
        let axisC = simd_normalize(SIMD3<Float>(0.38, -0.22, 0.90))
        let restingY = node.position.y
        let restingX = node.position.x
        let duration: Float = 2.25
        let tumble = SCNAction.customAction(duration: TimeInterval(duration)) { node, elapsed in
            let t = min(max(Float(elapsed) / duration, 0), 1)
            let eased = t < 0.76 ? 0.90 * (1 - pow(1 - t / 0.76, 2)) : 0.90 + 0.10 * ((t - 0.76) / 0.24)
            let base = simd_slerp(start, target, eased)
            let decay = 1 - eased
            let spin = simd_quatf(angle: decay * .pi * 10, axis: axisC)
                * simd_quatf(angle: decay * .pi * 8, axis: axisB)
                * simd_quatf(angle: decay * .pi * 12, axis: axisA)
            node.simdOrientation = spin * base

            let launch = t < 0.48 ? 0.46 * sin(.pi * t / 0.48) : 0
            let contactTime = max(0, t - 0.48)
            let impacts = t > 0.48 ? 0.16 * exp(-contactTime * 12) * abs(sin(contactTime * 36)) : 0
            node.position.y = restingY + launch + impacts
            node.position.x = restingX + 0.16 * sin(t * .pi * 1.3) * decay
            let bounce = 1 + 0.06 * sin(t * .pi) + 0.025 * impacts
            node.simdScale = SIMD3<Float>(repeating: bounce)
        }
        let settle = SCNAction.group([SCNAction.scale(to: 1, duration: 0.16), SCNAction.move(to: SCNVector3(restingX, restingY, node.position.z), duration: 0.16)])
        settle.timingMode = .easeOut
        node.removeAllActions()
        node.runAction(.sequence([tumble, settle]))
    }

    private static func vertices(for sides: Int) -> [SIMD3<Float>] {
        switch sides {
        case 4:
            return [
                SIMD3(1, 1, 1), SIMD3(1, -1, -1),
                SIMD3(-1, 1, -1), SIMD3(-1, -1, 1)
            ]
        case 6:
            return [
                SIMD3(-1, -1, -1), SIMD3(-1, -1, 1), SIMD3(-1, 1, -1), SIMD3(-1, 1, 1),
                SIMD3(1, -1, -1), SIMD3(1, -1, 1), SIMD3(1, 1, -1), SIMD3(1, 1, 1)
            ]
        case 8:
            return [SIMD3(1, 0, 0), SIMD3(-1, 0, 0), SIMD3(0, 1, 0), SIMD3(0, -1, 0), SIMD3(0, 0, 1), SIMD3(0, 0, -1)]
        case 10:
            return pentagonalTrapezohedronVertices()
        case 12:
            let phi = (1 + sqrt(5.0 as Float)) / 2
            let a = 1 / phi
            var points: [SIMD3<Float>] = []
            for x: Float in [-1, 1] {
                for y: Float in [-1, 1] {
                    for z: Float in [-1, 1] { points.append(SIMD3(x, y, z)) }
                }
            }
            for first: Float in [-1, 1] {
                for second: Float in [-1, 1] {
                    points.append(SIMD3(0, first * a, second * phi))
                    points.append(SIMD3(first * a, second * phi, 0))
                    points.append(SIMD3(first * phi, 0, second * a))
                }
            }
            return points
        default: // D20: regular icosahedron
            let phi = (1 + sqrt(5.0 as Float)) / 2
            var points: [SIMD3<Float>] = []
            for a: Float in [-1, 1] {
                for b: Float in [-1, 1] {
                    points.append(SIMD3(0, a, b * phi))
                    points.append(SIMD3(a, b * phi, 0))
                    points.append(SIMD3(b * phi, 0, a))
                }
            }
            return points
        }
    }

    private static func pentagonalTrapezohedronVertices() -> [SIMD3<Float>] {
        let tau = Float.pi * 2
        let upper = (0..<5).map { index -> SIMD3<Float> in
            let angle = tau * Float(index) / 5
            return SIMD3(cos(angle), sin(angle), 0.5)
        }
        let lower = (0..<5).map { index -> SIMD3<Float> in
            let angle = tau * (Float(index) + 0.5) / 5
            return SIMD3(cos(angle), sin(angle), -0.5)
        }
        var antiprismFaces: [[SIMD3<Float>]] = [upper, Array(lower.reversed())]
        for index in 0..<5 {
            let next = (index + 1) % 5
            let previousLower = (index + 4) % 5
            antiprismFaces.append([upper[index], upper[next], lower[index]])
            antiprismFaces.append([upper[index], lower[index], lower[previousLower]])
        }

        return antiprismFaces.compactMap { polygon in
            guard polygon.count >= 3 else { return nil }
            let center = polygon.reduce(SIMD3<Float>(repeating: 0), +) / Float(polygon.count)
            var normal = simd_normalize(simd_cross(polygon[1] - polygon[0], polygon[2] - polygon[0]))
            if simd_dot(normal, center) < 0 { normal = -normal }
            let distance = simd_dot(normal, center)
            guard distance > 0.0001 else { return nil }
            return normal / distance
        }
    }

    private static func convexFaces(vertices: [SIMD3<Float>]) -> [PolyFace] {
        var found: [String: PolyFace] = [:]
        let tolerance: Float = 0.0002
        guard vertices.count >= 4 else { return [] }

        for i in 0..<(vertices.count - 2) {
            for j in (i + 1)..<(vertices.count - 1) {
                for k in (j + 1)..<vertices.count {
                    let a = vertices[i]
                    var normal = simd_cross(vertices[j] - a, vertices[k] - a)
                    let length = simd_length(normal)
                    guard length > tolerance else { continue }
                    normal /= length
                    let distance = simd_dot(normal, a)
                    let signed = vertices.map { simd_dot(normal, $0) - distance }
                    let hasPositive = signed.contains { $0 > tolerance }
                    let hasNegative = signed.contains { $0 < -tolerance }
                    if hasPositive && hasNegative { continue }
                    if hasPositive {
                        normal = -normal
                    }
                    let planeDistance = simd_dot(normal, a)
                    let coplanar = vertices.indices.filter { abs(simd_dot(normal, vertices[$0]) - planeDistance) <= tolerance }
                    guard coplanar.count >= 3 else { continue }
                    let key = coplanar.sorted().map(String.init).joined(separator: ",")
                    guard found[key] == nil else { continue }

                    let center = coplanar.reduce(SIMD3<Float>(repeating: 0)) { $0 + vertices[$1] } / Float(coplanar.count)
                    let u = simd_normalize(vertices[coplanar[0]] - center)
                    let v = simd_cross(normal, u)
                    let ordered = coplanar.sorted { lhs, rhs in
                        let left = vertices[lhs] - center
                        let right = vertices[rhs] - center
                        return atan2(simd_dot(left, v), simd_dot(left, u)) < atan2(simd_dot(right, v), simd_dot(right, u))
                    }
                    found[key] = PolyFace(indices: ordered, center: center, normal: normal)
                }
            }
        }

        return found.values.sorted { lhs, rhs in
            if abs(lhs.normal.z - rhs.normal.z) > 0.0001 { return lhs.normal.z < rhs.normal.z }
            if abs(lhs.normal.y - rhs.normal.y) > 0.0001 { return lhs.normal.y < rhs.normal.y }
            return lhs.normal.x < rhs.normal.x
        }
    }

    private static func numberedFaces(_ faces: [PolyFace], sides: Int) -> [PolyFace] {
        guard sides != 4, sides.isMultiple(of: 2), faces.count == sides else { return faces }

        func belongsToNegativeHemisphere(_ normal: SIMD3<Float>) -> Bool {
            for component in [normal.z, normal.y, normal.x] where abs(component) > 0.0001 {
                return component < 0
            }
            return false
        }

        let negative = faces.filter { belongsToNegativeHemisphere($0.normal) }.sorted { lhs, rhs in
            if abs(lhs.normal.z - rhs.normal.z) > 0.0001 { return lhs.normal.z < rhs.normal.z }
            if abs(lhs.normal.y - rhs.normal.y) > 0.0001 { return lhs.normal.y < rhs.normal.y }
            return lhs.normal.x < rhs.normal.x
        }
        var positive = faces.filter { !belongsToNegativeHemisphere($0.normal) }
        guard negative.count == sides / 2, positive.count == sides / 2 else { return faces }

        var numbered = Array<PolyFace?>(repeating: nil, count: sides)
        for (index, face) in negative.enumerated() {
            guard let oppositeIndex = positive.indices.min(by: { left, right in
                simd_dot(face.normal, positive[left].normal) < simd_dot(face.normal, positive[right].normal)
            }) else { return faces }
            let opposite = positive.remove(at: oppositeIndex)
            guard simd_dot(face.normal, opposite.normal) < -0.98 else { return faces }
            numbered[index] = face
            numbered[sides - index - 1] = opposite
        }
        return numbered.compactMap { $0 }
    }

    private static func makeBody(vertices: [SIMD3<Float>], faces: [PolyFace], sides: Int) -> SCNNode {
        let node = SCNNode()
        for (faceIndex, face) in faces.enumerated() {
            let panel = face.indices.map { insetPoint(vertices[$0], toward: face.center, normal: face.normal) }
            let material = enamelMaterial(sides: sides, variation: faceIndex)
            node.addChildNode(makePolygon(points: panel, normal: face.normal, material: material))
        }

        // Fine, body-colored chamfers give the resin a molded and polished edge.
        var visitedEdges = Set<String>()
        let bevel = bevelMaterial(sides: sides)
        for face in faces {
            for index in face.indices.indices {
                let a = face.indices[index]
                let b = face.indices[(index + 1) % face.indices.count]
                let key = "\(min(a, b))-\(max(a, b))"
                guard visitedEdges.insert(key).inserted else { continue }
                let adjacent = faces.filter { $0.indices.contains(a) && $0.indices.contains(b) }
                guard adjacent.count == 2 else { continue }
                let first = adjacent[0]
                let second = adjacent[1]
                let strip = [
                    insetPoint(vertices[a], toward: first.center, normal: first.normal),
                    insetPoint(vertices[b], toward: first.center, normal: first.normal),
                    insetPoint(vertices[b], toward: second.center, normal: second.normal),
                    insetPoint(vertices[a], toward: second.center, normal: second.normal)
                ]
                node.addChildNode(makePolygon(points: strip, normal: first.normal + second.normal, material: bevel))
            }
        }

        // Small polished corner caps close the bevel seams at the polyhedron vertices.
        let capMaterial = bevel
        for vertex in vertices {
            let cap = SCNSphere(radius: 0.045)
            cap.segmentCount = 12
            cap.materials = [capMaterial]
            let capNode = SCNNode(geometry: cap)
            capNode.simdPosition = vertex * 0.975
            capNode.renderingOrder = 2
            node.addChildNode(capNode)
        }
        return node
    }

    private static func insetPoint(_ vertex: SIMD3<Float>, toward center: SIMD3<Float>, normal: SIMD3<Float>) -> SIMD3<Float> {
        center + (vertex - center) * (1 - faceInset) - normal * faceDepth
    }

    private static func makePolygon(points: [SIMD3<Float>], normal: SIMD3<Float>, material: SCNMaterial) -> SCNNode {
        guard points.count >= 3 else { return SCNNode() }
        let safeNormal = simd_length(normal) > 0.001 ? simd_normalize(normal) : SIMD3<Float>(0, 0, 1)
        var triangleVertices: [SCNVector3] = []
        var normals: [SCNVector3] = []
        var indices: [Int32] = []
        for edge in 1..<(points.count - 1) {
            let triangle = [points[0], points[edge], points[edge + 1]]
            let start = Int32(triangleVertices.count)
            for point in triangle {
                triangleVertices.append(SCNVector3(point.x, point.y, point.z))
                normals.append(SCNVector3(safeNormal.x, safeNormal.y, safeNormal.z))
            }
            indices.append(contentsOf: [start, start + 1, start + 2])
        }
        let geometry = SCNGeometry(
            sources: [SCNGeometrySource(vertices: triangleVertices), SCNGeometrySource(normals: normals)],
            elements: [SCNGeometryElement(indices: indices, primitiveType: .triangles)]
        )
        geometry.materials = [material]
        return SCNNode(geometry: geometry)
    }

    private static func resinColor(sides: Int) -> (CGFloat, CGFloat, CGFloat) {
        switch sides {
        case 4: return (0.66, 0.075, 0.085) // ruby red resin
        case 6: return (0.82, 0.77, 0.65) // classic ivory resin
        case 8: return (0.055, 0.20, 0.50) // cobalt resin
        case 10: return (0.055, 0.35, 0.21) // racing green resin
        case 12: return (0.33, 0.105, 0.52) // violet resin
        default: return (0.045, 0.13, 0.45) // deep blue resin
        }
    }

    private static func enamelMaterial(sides: Int, variation: Int) -> SCNMaterial {
        let base = resinColor(sides: sides)
        let variations: [CGFloat] = [0.96, 1.04, 0.99, 1.06]
        let factor = variations[variation % variations.count]
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(red: min(1, base.0 * factor), green: min(1, base.1 * factor), blue: min(1, base.2 * factor), alpha: 1)
        material.metalness.contents = 0.025
        material.roughness.contents = 0.22
        material.clearCoat.contents = 0.78
        material.clearCoatRoughness.contents = 0.10
        material.specular.contents = UIColor(white: 0.98, alpha: 1)
        material.lightingModel = .physicallyBased
        material.isDoubleSided = false
        return material
    }

    private static func bevelMaterial(sides: Int) -> SCNMaterial {
        let base = resinColor(sides: sides)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(
            red: min(1, base.0 * 1.30 + 0.035),
            green: min(1, base.1 * 1.30 + 0.035),
            blue: min(1, base.2 * 1.30 + 0.035),
            alpha: 1
        )
        material.metalness.contents = 0.02
        material.roughness.contents = 0.18
        material.clearCoat.contents = 0.62
        material.clearCoatRoughness.contents = 0.11
        material.specular.contents = UIColor(white: 0.96, alpha: 1)
        material.lightingModel = .physicallyBased
        material.isDoubleSided = true
        return material
    }

    private static func makeEdges(vertices: [SIMD3<Float>], faces: [PolyFace], sides: Int) -> SCNNode {
        var edgePairs = Set<String>()
        var lineVertices: [SCNVector3] = []
        var indices: [Int32] = []
        for face in faces {
            for index in face.indices.indices {
                let a = face.indices[index]
                let b = face.indices[(index + 1) % face.indices.count]
                let low = min(a, b)
                let high = max(a, b)
                let key = "\(low)-\(high)"
                guard edgePairs.insert(key).inserted else { continue }
                let start = Int32(lineVertices.count)
                for vertexIndex in [a, b] {
                    let vertex = vertices[vertexIndex] * 1.001
                    lineVertices.append(SCNVector3(vertex.x, vertex.y, vertex.z))
                }
                indices.append(contentsOf: [start, start + 1])
            }
        }
        let geometry = SCNGeometry(
            sources: [SCNGeometrySource(vertices: lineVertices)],
            elements: [SCNGeometryElement(indices: indices, primitiveType: .line)]
        )
        let material = SCNMaterial()
        let base = resinColor(sides: sides)
        material.diffuse.contents = UIColor(red: base.0 * 0.62, green: base.1 * 0.62, blue: base.2 * 0.62, alpha: 1)
        material.emission.contents = UIColor(red: base.0, green: base.1, blue: base.2, alpha: 0.025)
        material.lightingModel = .constant
        geometry.materials = [material]
        let node = SCNNode(geometry: geometry)
        node.renderingOrder = 2
        return node
    }

    private static func makePips(value: Int, face: PolyFace, vertices: [SIMD3<Float>]) -> SCNNode {
        let u = simd_normalize(vertices[face.indices[0]] - face.center)
        let v = simd_normalize(simd_cross(face.normal, u))
        var shortestEdge = Float.greatestFiniteMagnitude
        for index in face.indices.indices {
            let a = vertices[face.indices[index]]
            let b = vertices[face.indices[(index + 1) % face.indices.count]]
            shortestEdge = min(shortestEdge, simd_distance(a, b))
        }
        let offset = shortestEdge * 0.20
        let pipPositions: [SIMD2<Float>]
        switch value {
        case 1:
            pipPositions = [SIMD2(0, 0)]
        case 2:
            pipPositions = [SIMD2(-offset, -offset), SIMD2(offset, offset)]
        case 3:
            pipPositions = [SIMD2(-offset, -offset), SIMD2(0, 0), SIMD2(offset, offset)]
        case 4:
            pipPositions = [SIMD2(-offset, -offset), SIMD2(offset, -offset), SIMD2(-offset, offset), SIMD2(offset, offset)]
        case 5:
            pipPositions = [SIMD2(-offset, -offset), SIMD2(offset, -offset), SIMD2(0, 0), SIMD2(-offset, offset), SIMD2(offset, offset)]
        default:
            pipPositions = [
                SIMD2(-offset, -offset), SIMD2(0, -offset), SIMD2(offset, -offset),
                SIMD2(-offset, offset), SIMD2(0, offset), SIMD2(offset, offset)
            ]
        }

        let material = SCNMaterial()
        material.diffuse.contents = UIColor(red: 0.09, green: 0.075, blue: 0.06, alpha: 1)
        material.metalness.contents = 0.02
        material.roughness.contents = 0.34
        material.specular.contents = UIColor(white: 0.34, alpha: 1)
        material.lightingModel = .physicallyBased

        let root = SCNNode()
        let radius = CGFloat(min(0.057, shortestEdge * 0.049))
        for point in pipPositions {
            let pip = SCNSphere(radius: radius)
            pip.segmentCount = 24
            pip.materials = [material]
            let pipNode = SCNNode(geometry: pip)
            pipNode.simdPosition = face.center - face.normal * (faceDepth + Float(radius) * 0.52) + face.normal * 0.001 + u * point.x + v * point.y
            pipNode.castsShadow = false
            root.addChildNode(pipNode)
        }
        return root
    }

    private static func makeLabel(
        _ value: String,
        face: PolyFace,
        vertices: [SIMD3<Float>],
        position: SIMD3<Float>? = nil,
        scaleMultiplier: Float = 1
    ) -> SCNNode {
        let text = SCNText(string: value, extrusionDepth: 0.22)
        text.font = UIFont.systemFont(ofSize: 28, weight: .black)
        text.flatness = 0.16
        text.alignmentMode = CATextLayerAlignmentMode.center.rawValue
        text.firstMaterial?.diffuse.contents = UIColor(red: 1.0, green: 0.93, blue: 0.82, alpha: 1)
        text.firstMaterial?.emission.contents = UIColor.white.withAlphaComponent(0.035)
        text.firstMaterial?.lightingModel = .physicallyBased
        text.firstMaterial?.isDoubleSided = true
        text.firstMaterial?.metalness.contents = 0
        text.firstMaterial?.roughness.contents = 0.30
        let (minimum, maximum) = text.boundingBox
        let width = maximum.x - minimum.x
        let height = maximum.y - minimum.y
        let center = SCNVector3((minimum.x + maximum.x) / 2, (minimum.y + maximum.y) / 2, 0)
        var shortestEdge = Float.greatestFiniteMagnitude
        for index in face.indices.indices {
            let a = vertices[face.indices[index]]
            let b = vertices[face.indices[(index + 1) % face.indices.count]]
            shortestEdge = min(shortestEdge, simd_distance(a, b))
        }
        let glyphExtent = max(max(width, height), 1)
        let scale = min(0.032, max(0.012, shortestEdge * 0.53 / Float(glyphExtent))) * scaleMultiplier
        let node = SCNNode(geometry: text)
        node.pivot = SCNMatrix4MakeTranslation(center.x, center.y, center.z)
        node.scale = SCNVector3(scale, scale, scale)
        node.simdOrientation = simd_quatf(from: SIMD3<Float>(0, 0, 1), to: face.normal)
        node.simdPosition = (position ?? face.center) - face.normal * faceDepth + face.normal * 0.009
        node.renderingOrder = 3
        node.castsShadow = false
        return node
    }
}
