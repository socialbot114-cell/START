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

        func update(sides: Int, result: Int, rollToken: Int) {
            guard let view else { return }
            if currentSides != sides {
                currentSides = sides
                currentToken = nil
                let built = DiceGeometry.make(sides: sides)
                faces = built.faces
                dieNode?.removeFromParentNode()
                dieNode = built.node
                view.scene = DiceGeometry.scene(with: built.node)
            }
            guard let dieNode, let face = face(for: result) else { return }
            if currentToken == nil {
                currentToken = rollToken
                dieNode.simdOrientation = DiceGeometry.orientation(for: face)
            } else if currentToken != rollToken {
                currentToken = rollToken
                DiceGeometry.animate(dieNode, to: face)
            }
        }

        private func face(for result: Int) -> PolyFace? {
            guard !faces.isEmpty else { return nil }
            return faces[(max(1, result) - 1) % faces.count]
        }
    }
}

private struct PolyFace {
    let indices: [Int]
    let center: SIMD3<Float>
    let normal: SIMD3<Float>
}

private enum DiceGeometry {
    private static let gold = UIColor(red: 1.0, green: 0.70, blue: 0.16, alpha: 1)
    private static let faceColors: [UIColor] = [
        UIColor(red: 0.09, green: 0.20, blue: 0.15, alpha: 1),
        UIColor(red: 0.12, green: 0.26, blue: 0.18, alpha: 1),
        UIColor(red: 0.10, green: 0.23, blue: 0.17, alpha: 1),
        UIColor(red: 0.14, green: 0.28, blue: 0.19, alpha: 1)
    ]

    static func make(sides: Int) -> (node: SCNNode, faces: [PolyFace]) {
        let rawVertices = vertices(for: sides)
        let radius = rawVertices.map { simd_length($0) }.max() ?? 1
        let vertices = rawVertices.map { $0 / radius * 1.18 }
        let faces = convexFaces(vertices: vertices)
        precondition(faces.count == sides, "D\(sides) mesh generated \(faces.count) faces")
        let root = SCNNode()
        let body = makeBody(vertices: vertices, faces: faces)
        root.addChildNode(body)
        root.addChildNode(makeEdges(vertices: vertices, faces: faces))
        for (index, face) in faces.enumerated() {
            root.addChildNode(makeLabel("\(index + 1)", face: face, vertices: vertices))
        }
        root.simdScale = SIMD3<Float>(repeating: 1.0)
        return (root, faces)
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
        key.intensity = 540
        key.color = UIColor(red: 1.0, green: 0.82, blue: 0.57, alpha: 1)
        let keyNode = SCNNode()
        keyNode.light = key
        keyNode.position = SCNVector3(-3, 4, 5)
        scene.rootNode.addChildNode(keyNode)

        let fill = SCNLight()
        fill.type = .omni
        fill.intensity = 260
        fill.color = UIColor(red: 0.50, green: 0.78, blue: 1.0, alpha: 1)
        let fillNode = SCNNode()
        fillNode.light = fill
        fillNode.position = SCNVector3(4, 1, 2)
        scene.rootNode.addChildNode(fillNode)

        let rim = SCNLight()
        rim.type = .directional
        rim.intensity = 420
        rim.color = gold
        let rimNode = SCNNode()
        rimNode.light = rim
        rimNode.eulerAngles = SCNVector3(-0.6, 0.7, 0)
        scene.rootNode.addChildNode(rimNode)

        let ambient = SCNLight()
        ambient.type = .ambient
        ambient.intensity = 150
        ambient.color = UIColor(white: 0.48, alpha: 1)
        let ambientNode = SCNNode()
        ambientNode.light = ambient
        scene.rootNode.addChildNode(ambientNode)

        let shadow = SCNNode(geometry: SCNPlane(width: 2.25, height: 0.58))
        shadow.position = SCNVector3(0, -1.30, -0.38)
        shadow.eulerAngles.x = -0.10
        let shadowMaterial = SCNMaterial()
        shadowMaterial.diffuse.contents = UIColor.black.withAlphaComponent(0.50)
        shadowMaterial.lightingModel = .constant
        shadowMaterial.isDoubleSided = true
        shadow.geometry?.materials = [shadowMaterial]
        shadow.opacity = 0.55
        scene.rootNode.addChildNode(shadow)

        die.position = SCNVector3(0, 0.06, 0)
        scene.rootNode.addChildNode(die)
        return scene
    }

    static func orientation(for face: PolyFace) -> simd_quatf {
        let cameraFacing = simd_quatf(from: face.normal, to: SIMD3<Float>(0, 0, 1))
        let revealSideFaces = simd_quatf(angle: .pi / 8, axis: SIMD3<Float>(1, 0, 0))
            * simd_quatf(angle: -.pi / 8, axis: SIMD3<Float>(0, 1, 0))
        return revealSideFaces * cameraFacing
    }

    static func animate(_ node: SCNNode, to face: PolyFace) {
        let start = node.simdOrientation
        let target = orientation(for: face)
        let tumbleAxis = simd_normalize(SIMD3<Float>(0.78, 0.54, 0.31))
        let tumble = SCNAction.customAction(duration: 1.48) { node, elapsed in
            let t = min(max(Float(elapsed / 1.48), 0), 1)
            let eased = 1 - pow(1 - t, 3)
            let base = simd_slerp(start, target, eased)
            let spin = simd_quatf(angle: (1 - eased) * .pi * 10, axis: tumbleAxis)
            node.simdOrientation = spin * base
            let bounce = 1 + 0.12 * sin(t * .pi)
            node.simdScale = SIMD3<Float>(repeating: bounce)
        }
        let settle = SCNAction.scale(to: 1, duration: 0.13)
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

    private static func makeBody(vertices: [SIMD3<Float>], faces: [PolyFace]) -> SCNNode {
        let node = SCNNode()
        for (faceIndex, face) in faces.enumerated() {
            var triangleVertices: [SCNVector3] = []
            var normals: [SCNVector3] = []
            var indices: [Int32] = []
            guard face.indices.count >= 3 else { continue }
            for edge in 1..<(face.indices.count - 1) {
                let triangle = [face.indices[0], face.indices[edge], face.indices[edge + 1]]
                let start = Int32(triangleVertices.count)
                for index in triangle {
                    let vertex = vertices[index]
                    triangleVertices.append(SCNVector3(vertex.x, vertex.y, vertex.z))
                    normals.append(SCNVector3(face.normal.x, face.normal.y, face.normal.z))
                }
                indices.append(contentsOf: [start, start + 1, start + 2])
            }
            let source = SCNGeometrySource(vertices: triangleVertices)
            let normalSource = SCNGeometrySource(normals: normals)
            let element = SCNGeometryElement(indices: indices, primitiveType: .triangles)
            let geometry = SCNGeometry(sources: [source, normalSource], elements: [element])
            let material = SCNMaterial()
            material.diffuse.contents = faceColors[faceIndex % faceColors.count]
            material.metalness.contents = 0.28
            material.roughness.contents = 0.34
            material.specular.contents = UIColor.white
            material.lightingModel = .physicallyBased
            material.isDoubleSided = false
            geometry.materials = [material]
            node.addChildNode(SCNNode(geometry: geometry))
        }
        return node
    }

    private static func makeEdges(vertices: [SIMD3<Float>], faces: [PolyFace]) -> SCNNode {
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
        material.diffuse.contents = gold
        material.emission.contents = gold.withAlphaComponent(0.16)
        material.lightingModel = .constant
        geometry.materials = [material]
        let node = SCNNode(geometry: geometry)
        node.renderingOrder = 2
        return node
    }

    private static func makeLabel(_ value: String, face: PolyFace, vertices: [SIMD3<Float>]) -> SCNNode {
        let text = SCNText(string: value, extrusionDepth: 0.22)
        text.font = UIFont.systemFont(ofSize: 28, weight: .black)
        text.flatness = 0.16
        text.alignmentMode = CATextLayerAlignmentMode.center.rawValue
        text.firstMaterial?.diffuse.contents = UIColor(red: 1.0, green: 0.88, blue: 0.62, alpha: 1)
        text.firstMaterial?.emission.contents = UIColor.white.withAlphaComponent(0.14)
        text.firstMaterial?.lightingModel = .physicallyBased
        text.firstMaterial?.isDoubleSided = true
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
        let scale = min(0.034, max(0.012, shortestEdge * 0.58 / Float(glyphExtent)))
        let node = SCNNode(geometry: text)
        node.pivot = SCNMatrix4MakeTranslation(center.x, center.y, center.z)
        node.scale = SCNVector3(scale, scale, scale)
        node.simdOrientation = simd_quatf(from: SIMD3<Float>(0, 0, 1), to: face.normal)
        node.simdPosition = face.center + face.normal * 0.018
        node.renderingOrder = 3
        node.castsShadow = false
        return node
    }
}
