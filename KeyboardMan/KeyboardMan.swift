//
//  KeyboardMan.swift
//  Messages
//
//  Created by NIX on 15/7/25.
//  Copyright (c) 2015年 nixWork. All rights reserved.
//

import UIKit

public class KeyboardMan: NSObject {

    var keyboardObserver: NSNotificationCenter? {
        didSet {
            oldValue?.removeObserver(self)

            keyboardObserver?.addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
            keyboardObserver?.addObserver(self, selector: "keyboardWillChangeFrame:", name: UIKeyboardWillChangeFrameNotification, object: nil)
            keyboardObserver?.addObserver(self, selector: "keyboardDidShow:", name: UIKeyboardDidShowNotification, object: nil)
            keyboardObserver?.addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
            keyboardObserver?.addObserver(self, selector: "keyboardDidHide:", name: UIKeyboardDidHideNotification, object: nil)
        }
    }

    public var keyboardObserveEnabled = false {
        willSet {
            if newValue != keyboardObserveEnabled {
                keyboardObserver = newValue ? NSNotificationCenter.defaultCenter() : nil
            }
        }
    }

    deinit {
        // willSet and didSet are not called when deinit, so...
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    public struct KeyboardInfo {

        public let animationDuration: NSTimeInterval
        public let animationCurve: UInt

        public let frameBegin: CGRect
        public let frameEnd: CGRect
        public var height: CGFloat {
            return frameEnd.height
        }
        public let heightIncrement: CGFloat

        public enum Action {
            case Show
            case Hide
        }
        public let action: Action
        let isSameAction: Bool
    }

    public var appearPostIndex = 0

    var keyboardInfo: KeyboardInfo? {
        willSet {
            guard UIApplication.sharedApplication().applicationState == .Active else {
                return
            }

            if let info = newValue {
                if !info.isSameAction || info.heightIncrement != 0 {
                    
                    // do convenient animation
                    
                    let duration = info.animationDuration
                    let curve = info.animationCurve
                    let options = UIViewAnimationOptions(rawValue: curve << 16 | UIViewAnimationOptions.BeginFromCurrentState.rawValue)
                    
                    UIView.animateWithDuration(duration, delay: 0, options: options, animations: {
                        
                        switch info.action {
                            
                        case .Show:
                            self.animateWhenKeyboardAppear?(appearPostIndex: self.appearPostIndex, keyboardHeight: info.height, keyboardHeightIncrement: info.heightIncrement)
                            
                            self.appearPostIndex++
                            
                        case .Hide:
                            self.animateWhenKeyboardDisappear?(keyboardHeight: info.height)
                            
                            self.appearPostIndex = 0
                        }
                        
                        }, completion: nil)
                    
                    // post full info
                    
                    postKeyboardInfo?(keyboardMan: self, keyboardInfo: info)
                }
            }
        }
    }

    public var animateWhenKeyboardAppear: ((appearPostIndex: Int, keyboardHeight: CGFloat, keyboardHeightIncrement: CGFloat) -> Void)? {
        didSet {
            keyboardObserveEnabled = true
        }
    }

    public var animateWhenKeyboardDisappear: ((keyboardHeight: CGFloat) -> Void)? {
        didSet {
            keyboardObserveEnabled = true
        }
    }

    public var keyboardWillShow: (() -> Void)? {
        didSet {
            keyboardObserveEnabled = true
        }
    }

    public var keyboardDidShow: (() -> Void)? {
        didSet {
            keyboardObserveEnabled = true
        }
    }

    public var keyboardWillHide: (() -> Void)? {
        didSet {
            keyboardObserveEnabled = true
        }
    }

    public var keyboardDidHide: (() -> Void)? {
        didSet {
            keyboardObserveEnabled = true
        }
    }

    
    public var postKeyboardInfo: ((keyboardMan: KeyboardMan, keyboardInfo: KeyboardInfo) -> Void)? {
        didSet {
            keyboardObserveEnabled = true
        }
    }

    // MARK: - Actions

    private func handleKeyboard(notification: NSNotification, _ action: KeyboardInfo.Action) {

        if let userInfo = notification.userInfo {

            let animationDuration: NSTimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
            let animationCurve = (userInfo[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber).unsignedLongValue
            let frameBegin = (userInfo[UIKeyboardFrameBeginUserInfoKey] as! NSValue).CGRectValue()
            let frameEnd = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()

            let currentHeight = frameEnd.height
            let previousHeight = keyboardInfo?.height ?? 0
            let heightIncrement = currentHeight - previousHeight

            let isSameAction: Bool
            if let previousAction = keyboardInfo?.action {
                isSameAction = action == previousAction
            } else {
                isSameAction = false
            }

            keyboardInfo = KeyboardInfo(
                animationDuration: animationDuration,
                animationCurve: animationCurve,
                frameBegin: frameBegin,
                frameEnd: frameEnd,
                heightIncrement: heightIncrement,
                action: action,
                isSameAction: isSameAction
            )
        }
    }

    func keyboardWillShow(notification: NSNotification) {

        keyboardWillShow?()
        handleKeyboard(notification, .Show)
    }
    
    func keyboardWillChangeFrame(notification: NSNotification) {

        if let keyboardInfo = keyboardInfo {

            if keyboardInfo.action == .Show {
                handleKeyboard(notification, .Show)
            }
        }
    }

    func keyboardDidShow(notification: NSNotification) {
        
        keyboardDidShow?()
    }
    
    func keyboardWillHide(notification: NSNotification) {

        keyboardWillHide?()
        handleKeyboard(notification, .Hide)
    }

    func keyboardDidHide(notification: NSNotification) {

        keyboardDidHide?()
        keyboardInfo = nil
    }
}

