//
//  SVGPath.swift
//  SVGPath
//
//  Created by Tim Wood on 1/21/15.
//  Updated by Vitaly Domnikov 10/6/2015
//  Updated by Jason Rodriguez 08/29/2017
//  Copyright (c) 2015 Tim Wood, Vitaly Domnikov, Jason Rodriguez. All rights reserved.

import Foundation
import CoreGraphics

public extension CGPath {
    
    // Convert SVG path to CGPath
    static func fromSvgPath(svgPath: String) -> CGPath? {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: 0))
        let commands = SVGPath(svgPath).commands
        for command in commands {
            switch command.type {
            case .move: path.move(to: CGPoint(x: command.point.x, y: command.point.y))
            case .line: path.addLine(to: CGPoint(x: command.point.x, y: command.point.y))
            case .quadCurve: path.addQuadCurve(to: CGPoint(x: command.point.x, y: command.point.y), control: CGPoint(x: command.control1.x, y: command.control1.y))
            case .cubeCurve: path.addCurve(to: CGPoint(x: command.point.x, y: command.point.y), control1: CGPoint(x: command.control1.x, y: command.control1.y), control2: CGPoint(x: command.control2.x, y: command.control2.y))
            case .close: path.closeSubpath()
            }
        }
        return path
    }
}

// MARK: Enums

private enum Coordinates {
    case absolute
    case relative
}

// MARK: Class

public class SVGPath {
    public var commands: [SVGCommand] = []
    private var builder: SVGCommandBuilder = moveTo
    private var coords: Coordinates = .absolute
    private var strideLength: Int = 2
    private var numbers = ""
    
    public init(_ string: String) {
        commands.reserveCapacity(200)
        for char in string {
            switch char {
            case "M": use(.absolute, strideLength: 2, builder: moveTo)
            case "m": use(.relative, strideLength: 2, builder: moveTo)
            case "L": use(.absolute, strideLength: 2, builder: lineTo)
            case "l": use(.relative, strideLength: 2, builder: lineTo)
            case "V": use(.absolute, strideLength: 1, builder: lineToVertical)
            case "v": use(.relative, strideLength: 1, builder: lineToVertical)
            case "H": use(.absolute, strideLength: 1, builder: lineToHorizontal)
            case "h": use(.relative, strideLength: 1, builder: lineToHorizontal)
            case "Q": use(.absolute, strideLength: 4, builder: quadBroken)
            case "q": use(.relative, strideLength: 4, builder: quadBroken)
            case "T": use(.absolute, strideLength: 2, builder: quadSmooth)
            case "t": use(.relative, strideLength: 2, builder: quadSmooth)
            case "C": use(.absolute, strideLength: 6, builder: cubeBroken)
            case "c": use(.relative, strideLength: 6, builder: cubeBroken)
            case "S": use(.absolute, strideLength: 4, builder: cubeSmooth)
            case "s": use(.relative, strideLength: 4, builder: cubeSmooth)
            case "Z": use(.absolute, strideLength: 0, builder: close)
            case "z": use(.relative, strideLength: 0, builder: close)
            default: numbers.append(char)
            }
        }
        finishLastCommand()
    }
    
    private func use(_ coords: Coordinates, strideLength: Int, builder: @escaping SVGCommandBuilder) {
        finishLastCommand()
        self.builder = builder
        self.coords = coords
        self.strideLength = strideLength
    }
    
    private func finishLastCommand() {
        for command in take(numbers: SVGPath.parseNumbers(numbers: numbers), strideLength: strideLength, coords: coords, last: commands.last, callback: builder) {
            commands.append(coords == .relative ? command.relativeTo(commandSequence: commands) : command)
        }
        numbers = ""
    }
}

// MARK: Numbers

private let numberSet = NSCharacterSet(charactersIn: "-.0123456789eE")
private let numberFormatter = NumberFormatter()

public extension SVGPath {
    class func parseNumbers(numbers: String) -> [CGFloat] {
        numberFormatter.numberStyle = .decimal
        numberFormatter.allowsFloats = true
        numberFormatter.decimalSeparator = "."
        var all: [String] = []
        var curr = ""
        var last = ""
        var isDecimal = false
        
        for char in numbers.unicodeScalars {
            let next = String(char)
            
            if (next == "-" && last != "" && last != "E" && last != "e") || (next == "." && isDecimal) {
                if curr.utf16.count > 0 {
                    all.append(curr)
                    isDecimal = false
                }
                curr = next
            } else if numberSet.longCharacterIsMember(char.value) {
                curr += next
            } else if curr.utf16.count > 0 {
                all.append(curr)
                curr = ""
                isDecimal = false
            }
            last = next
            
            if last == "." {
                isDecimal = true
            }
        }
        
        all.append(curr)
        return all
            .filter {
                numberFormatter.number(from: $0) != nil
            }
            .map {
                CGFloat((numberFormatter.number(from: $0)?.floatValue)!)
        }
    }
}

// MARK: Commands

public struct SVGCommand {
    public var point: CGPoint
    public var control1: CGPoint
    public var control2: CGPoint
    public var type: Kind
    
    public enum Kind {
        case move
        case line
        case cubeCurve
        case quadCurve
        case close
    }
    
    public init() {
        let point = CGPoint()
        self.init(point, point, point, type: .close)
    }
    
    public init(_ x: CGFloat, _ y: CGFloat, type: Kind) {
        let point = CGPoint(x: x, y: y)
        self.init(point, point, point, type: type)
    }
    
    public init(_ cx: CGFloat, _ cy: CGFloat, _ x: CGFloat, _ y: CGFloat) {
        let control = CGPoint(x: cx, y: cy)
        self.init(control, control, CGPoint(x: x, y: y), type: .quadCurve)
    }
    
    public init(_ cx1: CGFloat, _ cy1: CGFloat, _ cx2: CGFloat, _ cy2: CGFloat, _ x: CGFloat, _ y: CGFloat) {
        self.init(CGPoint(x: cx1, y: cy1), CGPoint(x: cx2, y: cy2), CGPoint(x: x, y: y), type: .cubeCurve)
    }
    
    public init(_ control1: CGPoint, _ control2: CGPoint, _ point: CGPoint, type: Kind) {
        self.point = point
        self.control1 = control1
        self.control2 = control2
        self.type = type
    }
    
    fileprivate func relativeTo(commandSequence: [SVGCommand]) -> SVGCommand {
        if let lastOp = commandSequence.last {
            if lastOp.type == .close {
                //we need to offset from the last Move command, not the current point if we have a relative Move after a Close
                var lastMove: SVGCommand?
                
                for i in (1...commandSequence.count).reversed() {
                    lastMove = commandSequence[i - 1]
                    if lastMove?.type == .move {
                        break;
                    }
                }
                
                if lastMove != nil {
                    return SVGCommand(control1 + lastMove!.point, control2 + lastMove!.point, point + lastMove!.point, type: type)
                }
            } else {
                //return relative to the point on the last operation
                return SVGCommand(control1 + lastOp.point, control2 + lastOp.point, point + lastOp.point, type: type)
            }
        }
        
        return self
    }
}

// MARK: CGPoint helpers

fileprivate func +(a: CGPoint, b: CGPoint) -> CGPoint {
    return CGPoint(x: a.x + b.x, y: a.y + b.y)
}

fileprivate func -(a: CGPoint, b: CGPoint) -> CGPoint {
    return CGPoint(x: a.x - b.x, y: a.y - b.y)
}

// MARK: Command Builders

fileprivate typealias SVGCommandBuilder = ([CGFloat], SVGCommand?, Coordinates) -> SVGCommand

fileprivate func take(numbers: [CGFloat], strideLength: Int, coords: Coordinates, last: SVGCommand?, callback: SVGCommandBuilder) -> [SVGCommand] {
    var out: [SVGCommand] = []
    var lastCommand: SVGCommand? = last
    var nums: [CGFloat] = [0, 0, 0, 0, 0, 0]
    if strideLength == 0 {
        lastCommand = callback(nums, lastCommand, coords)
        out.append(lastCommand!)
    } else {
        let count = (numbers.count / strideLength) * strideLength
        for i in stride(from: 0, to: count, by: strideLength) {
            for j in 0..<strideLength {
                nums[j] = numbers[i + j]
            }
            lastCommand = callback(nums, lastCommand, coords)
            out.append(lastCommand!)
        }
    }
    return out
}

// MARK: Mm - Move

private func moveTo(numbers: [CGFloat], last: SVGCommand?, coords: Coordinates) -> SVGCommand {
    return SVGCommand(numbers[0], numbers[1], type: .move)
}

// MARK: Ll - Line

private func lineTo(numbers: [CGFloat], last: SVGCommand?, coords: Coordinates) -> SVGCommand {
    return SVGCommand(numbers[0], numbers[1], type: .line)
}

// MARK: Vv - Vertical Line

private func lineToVertical(numbers: [CGFloat], last: SVGCommand?, coords: Coordinates) -> SVGCommand {
    return SVGCommand(coords == .absolute ? last?.point.x ?? 0 : 0, numbers[0], type: .line)
}

// MARK: Hh - Horizontal Line

private func lineToHorizontal(numbers: [CGFloat], last: SVGCommand?, coords: Coordinates) -> SVGCommand {
    return SVGCommand(numbers[0], coords == .absolute ? last?.point.y ?? 0 : 0, type: .line)
}

// MARK: Qq - Quadratic Curve To

private func quadBroken(numbers: [CGFloat], last: SVGCommand?, coords: Coordinates) -> SVGCommand {
    return SVGCommand(numbers[0], numbers[1], numbers[2], numbers[3])
}

// MARK: Tt - Smooth Quadratic Curve To

private func quadSmooth(numbers: [CGFloat], last: SVGCommand?, coords: Coordinates) -> SVGCommand {
    var lastControl = last?.control1 ?? CGPoint()
    let lastPoint = last?.point ?? CGPoint()
    if (last?.type ?? .line) != .quadCurve {
        lastControl = lastPoint
    }
    var control = lastPoint - lastControl
    if coords == .absolute {
        control = control + lastPoint
    }
    return SVGCommand(control.x, control.y, numbers[0], numbers[1])
}

// MARK: Cc - Cubic Curve To

private func cubeBroken(numbers: [CGFloat], last: SVGCommand?, coords: Coordinates) -> SVGCommand {
    return SVGCommand(numbers[0], numbers[1], numbers[2], numbers[3], numbers[4], numbers[5])
}

// MARK: Ss - Smooth Cubic Curve To

private func cubeSmooth(numbers: [CGFloat], last: SVGCommand?, coords: Coordinates) -> SVGCommand {
    var lastControl = last?.control2 ?? CGPoint()
    let lastPoint = last?.point ?? CGPoint()
    if (last?.type ?? .line) != .cubeCurve {
        lastControl = lastPoint
    }
    var control = lastPoint - lastControl
    if coords == .absolute {
        control = control + lastPoint
    }
    return SVGCommand(control.x, control.y, numbers[0], numbers[1], numbers[2], numbers[3])
}

// MARK: Zz - Close Path

private func close(numbers: [CGFloat], last: SVGCommand?, coords: Coordinates) -> SVGCommand {
    return SVGCommand()
}
