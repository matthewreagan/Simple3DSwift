//
//  Simple3D.swift - Created by Matt Reagan | (@hmblebee) | 1/19/19
//  Copyright © 2019 Matt Reagan. ** Please see README for license and info. **

import Cocoa

let ViewSize: CGFloat = 600.0
let HalfViewSize: CGFloat = (ViewSize / 2.0)
let QuarterViewSize: CGFloat = (ViewSize / 4.0)
let FloorHeight: CGFloat = -HalfViewSize
let blueColor = NSColor(calibratedRed: 15.0 / 255.0, green: 171.0 / 255.0, blue: 1.0, alpha: 1.0)
let brownColor = NSColor(calibratedRed: 110.0 / 255.0, green: 78.0 / 255.0, blue: 33.0 / 255.0, alpha: 1.0)

enum Axis { case x,y,z }
struct Vec3 {
    let x,y,z: CGFloat
    func rotated(by a: CGFloat, around axis: Axis) -> Vec3 {
        switch axis {
        case .x: return Vec3(x: x, y: cos(a) * y - sin(a) * z, z: sin(a) * y + cos(a) * z)
        case .y: return Vec3(x: cos(a) * x + sin(a) * z, y: y, z: -(sin(a) * x) + cos(a) * z)
        case .z: return Vec3(x: cos(a) * x - sin(a) * y, y: sin(a) * x + cos(a) * y, z: z)
        }
    }
    func translated(by v: Vec3) -> Vec3 { return Vec3(x: x + v.x, y: y + v.y, z: z + v.z) }
    static prefix func -(lhs: Vec3) -> Vec3 { return Vec3(x: -lhs.x, y: -lhs.y, z: -lhs.z) }
}

func dotProd(_ v1: Vec3, _ v2: Vec3) -> CGFloat { return v1.x * v2.x + v1.y * v2.y + v1.z * v2.z }

func renderedPtFromVec3(_ vector: Vec3) -> CGPoint? {
    if vector.z < 0.0 { return nil }
    let depth = vector.z > 0.0 ? vector.z / 600.0 : 0.000001 // leastNormalMagnitude (DBL_MIN) will produce +Inf
    return CGPoint(x: vector.x / depth + HalfViewSize, y: vector.y / depth + HalfViewSize)
}

func renderedLine(from argV1: Vec3, to argV2: Vec3) -> (CGPoint, CGPoint)? {
    if argV1.z < 0.0 && argV2.z < 0.0 { return nil }
    if argV1.z >= 0.0 && argV2.z >= 0.0 { return (renderedPtFromVec3(argV1)!, renderedPtFromVec3(argV2)!) }
    
    let v1,v2: Vec3
    if argV1.z > argV2.z { v1 = argV1; v2 = argV2; } else { v1 = argV2; v2 = argV1; }
    let dVec = v2.translated(by: -v1)
    let n = Vec3(x: 0, y: 0, z: 1)
    let t = -(dotProd(v1, n)) / dotProd(dVec, n)
    let p1 = Vec3(x: v1.x + dVec.x * t, y: v1.y + dVec.y * t, z: v1.z + dVec.z * t)
    
    guard let renderP0 = renderedPtFromVec3(v1), let renderP1 = renderedPtFromVec3(p1) else { return nil }
    return (renderP0, renderP1)
}

struct Shape {
    let vectors: [Vec3]
    let lines: [(Int, Int)]
    let faces:  [(Int, Int, Int, Int)]
    let color: NSColor
    let objectCenter: Vec3
    let animates: Bool
    let bulletAngle: Vec3?
    var shootTime: CGFloat = 0
    
    static func cube(width: CGFloat, height: CGFloat, at center: Vec3, animated: Bool = false, color: NSColor = brownColor, bulletAngle: Vec3? = nil) -> Shape {
        let halfW = width / 2.0; let halfH = height / 2.0
        let vec = [Vec3(x: -halfW, y: halfH, z: -halfW), Vec3(x: -halfW, y: -halfH, z: -halfW),
                   Vec3(x: halfW, y: -halfH, z: -halfW), Vec3(x: halfW, y: halfH, z: -halfW),
                   Vec3(x: -halfW, y: halfH, z: halfW), Vec3(x: -halfW, y: -halfH, z: halfW),
                   Vec3(x: halfW, y: -halfH, z: halfW), Vec3(x: halfW, y: halfH, z: halfW)]
        let translatedVec = vec.map({ return $0.translated(by: center) })
        return Shape(vectors: translatedVec,
                     lines: [(0, 1), (1, 2), (2, 3), (3, 0), (4, 5), (5, 6), (6, 7), (7, 4), (0, 4), (1, 5), (2, 6), (3, 7)],
                     faces: [(0, 1, 2, 3), (7, 6, 5, 4), (4, 5, 1, 0), (3, 2, 6, 7), (4, 0, 3, 7), (1, 5, 6, 2)],
                     color: color, objectCenter: center, animates: animated, bulletAngle: bulletAngle, shootTime: 0)
    }
    
    static func pyramid(size: CGFloat, at center: Vec3, animated: Bool = false, color: NSColor = NSColor.green) -> Shape {
        let halfSize = size / 2.0
        let vec = [Vec3(x: -halfSize, y: -halfSize, z: halfSize), Vec3(x: -halfSize, y: -halfSize, z: -halfSize),
                   Vec3(x: halfSize, y: -halfSize, z: -halfSize), Vec3(x: halfSize, y: -halfSize, z: halfSize),
                   Vec3(x: 0.0, y: halfSize, z: 0.0)]
        let translatedVec = vec.map({ return $0.translated(by: center) })
        return Shape(vectors: translatedVec,
                     lines: [(0, 1), (1, 2), (2, 3), (3, 0), (0, 4), (1, 4), (2, 4), (3, 4)],
                     faces: [(0, 1, 4, 0), (1, 2, 4, 1), (2, 3, 4, 2), (3, 0, 4, 3),],
                     color: color, objectCenter: center, animates: animated, bulletAngle: nil, shootTime: 0)
    }
    
    static func gridFloor(of size: Int, squareSize: CGFloat) -> Shape {
        var vectors = [Vec3]()
        var lines = [(Int, Int)]()
        let halfGridSize = CGFloat(size) * squareSize / 2.0
        for xi in 0..<size {
            for zi in 0..<size {
                let x = CGFloat(xi) * squareSize - halfGridSize
                let z = CGFloat(zi) * squareSize - halfGridSize
                vectors.append(Vec3(x: x, y: FloorHeight, z: z))
            }
        }
        
        for x in 0..<size {
            lines.append((x, size * size - size + x))
            lines.append((x * size, x * size + (size - 1)))
        }
        
        return Shape(vectors: vectors, lines: lines, faces: [],
                     color: NSColor(calibratedRed: 0.0, green: 0.5, blue: 0.0, alpha: 1.0),
                     objectCenter: Vec3(x: 0.0, y: 0.0, z: 0.0), animates: false, bulletAngle: nil, shootTime: 0)
    }
}

var worldShapes = [Shape.gridFloor(of: 20, squareSize: QuarterViewSize),
                   Shape.cube(width: HalfViewSize, height: HalfViewSize, at: Vec3(x: 0.0, y: 0.0, z: ViewSize), animated: true, color: blueColor),
                   Shape.pyramid(size: ViewSize, at: Vec3(x: -1200.0, y: ViewSize, z: 800.0)),
                   Shape.cube(width: QuarterViewSize, height: ViewSize, at: Vec3(x: -1200.0, y: 0.0, z: 800.0)),
                   Shape.pyramid(size: ViewSize, at: Vec3(x: -1300.0, y: ViewSize, z: -500.0)),
                   Shape.cube(width: QuarterViewSize, height: ViewSize, at: Vec3(x: -1300.0, y: 0.0, z: -500.0)),
                   Shape.pyramid(size: ViewSize, at: Vec3(x: 600.0, y: ViewSize, z: 1300.0)),
                   Shape.cube(width: QuarterViewSize, height: ViewSize, at: Vec3(x: 600.0, y: 0.0, z: 1300.0)),
                   Shape.pyramid(size: ViewSize * 0.6, at: Vec3(x: 1200.0, y: 260, z: 600.0)),
                   Shape.cube(width: QuarterViewSize * 0.6, height: 380.0, at: Vec3(x: 1200.0, y: -100.0, z: 600.0))]

class MyView: NSView {
    var shapeSpinAnimationAngle: CGFloat = 0.0
    var cameraAngle = Vec3(x: 0.0, y: 0.0, z: 0.0)
    var cameraPosition = Vec3(x: 0.0, y: 0.0, z: 1500.0)
    var turnAmount: CGFloat = 0.0
    var moveAmount: CGFloat = 0.0
    
    override func viewDidMoveToWindow() {
        Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] timer in self?.timer() }
        DispatchQueue.main.async { self.window?.makeFirstResponder(self) }
    }
    
    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 123: turnAmount = 0.05 //left
        case 124: turnAmount = -0.05 //right
        case 126: moveAmount = -40.0 //up
        case 125: moveAmount = 40.0 //down
        case 49: shootBox()
        default: return
        }
    }
    override func keyUp(with event: NSEvent) {
        switch event.keyCode {
        case 123, 124: turnAmount = 0.0
        case 125, 126: moveAmount = 0.0
        default: return
        }
    }
    
    func timer() {
        shapeSpinAnimationAngle += 0.014
        updateCamera()
        setNeedsDisplay(bounds)
    }
    
    func updateCamera() {
        cameraAngle = Vec3(x: cameraAngle.x, y: cameraAngle.y + turnAmount, z: cameraAngle.z)
        let move = Vec3(x: 0.0, y: 0.0, z: moveAmount).rotated(by: cameraAngle.y, around: .y)
        cameraPosition = Vec3(x: cameraPosition.x - move.x, y: cameraPosition.y - move.y, z: cameraPosition.z + move.z)
    }
    
    let boxSize: CGFloat = 100.0
    func shootBox() {
        let angle = Vec3(x: cameraAngle.x, y: cameraAngle.y + CGFloat.random(in: -0.25...0.25), z: cameraAngle.z)
        let cube = Shape.cube(width: boxSize, height: boxSize, at: -cameraPosition, animated: true,
                              color: NSColor.magenta.blended(withFraction: CGFloat.random(in: 0...1.0), of: NSColor.yellow)!, bulletAngle: angle)
        worldShapes.append(cube)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        NSColor.black.set(); bounds.fill()
        
        for (shapeIndex, shape) in worldShapes.enumerated() {
            let shapeVec = shape.vectors.map { v -> Vec3 in
                var vec = v
                vec = shape.animates ? vec.translated(by: -shape.objectCenter).rotated(by: shapeSpinAnimationAngle, around: .y).translated(by: shape.objectCenter) : vec
                
                if let bang = shape.bulletAngle {
                    vec = vec.translated(by: Vec3(x: 0.0, y:-pow(shape.shootTime / 2.0, 3.0), z: 10.0 * pow(shape.shootTime, 2.0)).rotated(by: -bang.y, around: .y))
                    if vec.y > FloorHeight + boxSize / 2.0 {
                        var updatedShape = shape
                        updatedShape.shootTime += 0.84
                        worldShapes.remove(at: shapeIndex); worldShapes.insert(updatedShape, at: shapeIndex)
                    }
                }
                
                return vec.translated(by: cameraPosition).rotated(by: cameraAngle.y, around: .y)
            }
            
            shape.color.set()
            for line in shape.lines {
                guard let points = renderedLine(from: shapeVec[line.0], to: shapeVec[line.1]) else { continue }
                NSBezierPath.strokeLine(from: points.0, to: points.1)
            }
            
            shape.color.withAlphaComponent(0.20).set()
            for face in shape.faces {
                let points = [shapeVec[face.0], shapeVec[face.1], shapeVec[face.2], shapeVec[face.3]].compactMap { renderedPtFromVec3($0) }
                guard points.count == 4 else { continue }
                let path = NSBezierPath()
                path.move(to: points[0]); path.line(to: points[1]); path.line(to: points[2]); path.line(to: points[3])
                path.fill()
            }
            
            NSColor.green.set()
            for vector in shapeVec {
                guard let pt = renderedPtFromVec3(vector) else { continue }
                CGRect(x: pt.x, y: pt.y, width: 0.0, height: 0.0).insetBy(dx: -1.0, dy: -1.0).fill()
            }
        }
    }
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate { }
