//
//  Utilities.swift
//  PointCloudTriangulation
//
//  Created by Eugene Bokhan on 12/8/17.
//  Copyright © 2017 Eugene Bokhan. All rights reserved.
//

import UIKit

public func animationWithKeyPath(_ keyPath: String, damping: CGFloat = 10, initialVelocity: CGFloat = 0, stiffness: CGFloat) -> CABasicAnimation {
    guard #available(iOS 9, *) else {
        let basic            = CABasicAnimation(keyPath: keyPath)
        basic.duration       = 0.16
        basic.fillMode       = kCAFillModeForwards
        basic.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionDefault)
        
        return basic
    }
    
    let spring             = CASpringAnimation(keyPath: keyPath)
    spring.duration        = spring.settlingDuration
    spring.damping         = damping
    spring.initialVelocity = initialVelocity
    spring.stiffness       = stiffness
    spring.fillMode        = kCAFillModeForwards
    spring.timingFunction  = CAMediaTimingFunction(name: kCAMediaTimingFunctionDefault)
    
    return spring
}

public func animationWithKeyPath(_ keyPath: String, damping: CGFloat = 10, initialVelocity: CGFloat = 0, stiffness: CGFloat, duration: Double) -> CABasicAnimation {
    guard #available(iOS 9, *) else {
        let basic            = CABasicAnimation(keyPath: keyPath)
        basic.duration       = duration
        basic.fillMode       = kCAFillModeForwards
        basic.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionDefault)
        
        return basic
    }
    
    let spring             = CASpringAnimation(keyPath: keyPath)
    spring.duration        = spring.settlingDuration
    spring.damping         = damping
    spring.initialVelocity = initialVelocity
    spring.stiffness       = stiffness
    spring.fillMode        = kCAFillModeForwards
    spring.timingFunction  = CAMediaTimingFunction(name: kCAMediaTimingFunctionDefault)
    
    return spring
}

public func getButtonTransfromForPresentation(button: UIButton, presentationDirection: PresentationDirection) -> (CGAffineTransform, CGAffineTransform) {
    
    var initialButtonTransform: CGAffineTransform!
    let finalButtonTransform = button.transform
    
    switch presentationDirection {
    case .down:
        initialButtonTransform = CGAffineTransform(translationX: 0, y: -button.frame.maxY)
    case .up:
        initialButtonTransform = CGAffineTransform(translationX: 0, y: button.frame.maxY)
    case .left:
        initialButtonTransform = CGAffineTransform(translationX: button.frame.maxX, y: 0)
    case .right:
        initialButtonTransform = CGAffineTransform(translationX: -button.frame.maxX, y: 0)
    }
    
    return (initialButtonTransform, finalButtonTransform)
}

public func getViewTransfromForPresentation(view: UIView, presentationDirection: PresentationDirection) -> (CGAffineTransform, CGAffineTransform) {
    
    var initialViewTransform: CGAffineTransform!
    let finalViewTransform = view.transform
    
    switch presentationDirection {
    case .down:
        initialViewTransform = CGAffineTransform(translationX: 0, y: -view.frame.maxY)
    case .up:
        initialViewTransform = CGAffineTransform(translationX: 0, y: view.frame.maxY)
    case .left:
        initialViewTransform = CGAffineTransform(translationX: view.frame.maxX, y: 0)
    case .right:
        initialViewTransform = CGAffineTransform(translationX: -view.frame.maxX, y: 0)
    }
    return (initialViewTransform, finalViewTransform)
}

public func degreesToRadians(degrees: CGFloat) -> CGFloat {
    return degrees * .pi / 180
}
public func radiansToDegress(radians: CGFloat) -> CGFloat {
    return radians * 180 / .pi
}

public enum PresentationDirection {
    case right
    case left
    case up
    case down
}

extension MutableCollection {
    /// Shuffle the elements of `self` in-place.
    mutating func shuffle() {
        // empty and single-element collections don't shuffle
        if count < 2 { return }
        
        for i in indices.dropLast() {
            let diff = distance(from: i, to: endIndex)
            let j = index(i, offsetBy: numericCast(arc4random_uniform(numericCast(diff))))
            swapAt(i, j)
        }
    }
}

extension Sequence {
    /// Returns an array with the contents of this sequence, shuffled.
    func shuffled() -> [Element] {
        var result = Array(self)
        result.shuffle()
        return result
    }
}
