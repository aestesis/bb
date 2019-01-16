//
//  bb.extension.swift
//  bb framework
//
//  Created by renan jegouzo on 01/01/2018.
//  Copyright © 2018 aestesis. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

import Foundation
import UIKit
import Alib

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
extension Event {
    public func alive(_ owner: BBView, _ action: @escaping (T)->()) {
        let a=Action<T>(action)
        _lock.synced {
            self._actions.insert(a);
        }
        owner.onDetach.once {
            self._lock.synced {
                self._actions.remove(a)
            }
        }
    }
    public func pipe(to:Event<T>,owner:BBView) {
        self.alive(owner) { p in
            to.dispatch(p)
        }
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
extension Misc {
    public static func simpleDate(_ date:String) -> Date? {
        let pub = DateFormatter()
        pub.locale = Locale(identifier:"en_US_POSIX")
        pub.timeZone = TimeZone(secondsFromGMT: 0)
        pub.dateFormat="yyyy-MM-dd"
        return pub.date(from: date)
    }
    public static func simpleDate(_ date:Date) -> String {
        let pub = DateFormatter()
        pub.locale = Locale(identifier:"en_US_POSIX")
        pub.timeZone = TimeZone(secondsFromGMT: 0)
        pub.dateFormat="yyyy-MM-dd"
        return pub.string(from: date)
    }
    public static func version(greaterOrEqual:String,than:String) -> Bool {
        func versionNumber(_ version:String) -> Double {
            var v = 0.0
            for p in version.split(".") {
                v *= 100
                if let pv = Double(p) {
                    v += pv
                }
            }
            return v
        }
        return versionNumber(greaterOrEqual) >= versionNumber(than)
    }
    public static func version(greater:String,than:String) -> Bool {
        func versionNumber(_ version:String) {
            var v = 0.0
            for p in version.split(".") {
                v *= 100
                if let pv = Double(p) {
                    v += pv
                }
            }
        }
        return versionNumber(greater) > versionNumber(than)
    }
    public static func version(smallerOrEqual:String,than:String) -> Bool {
        func versionNumber(_ version:String) {
            var v = 0.0
            for p in version.split(".") {
                v *= 100
                if let pv = Double(p) {
                    v += pv
                }
            }
        }
        return versionNumber(smallerOrEqual) <= versionNumber(than)
    }
    public static func version(smaller:String,than:String) -> Bool {
        func versionNumber(_ version:String) {
            var v = 0.0
            for p in version.split(".") {
                v *= 100
                if let pv = Double(p) {
                    v += pv
                }
            }
        }
        return versionNumber(smaller) < versionNumber(than)
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
extension UIImage {
    public convenience init?(resource:String,scale:CGFloat = 1) {
        do {
            let data = try Data(contentsOf:URL(fileURLWithPath:Application.resourcePath(resource)))
            self.init(data:data,scale:scale)
        } catch {
            Debug.error("UIImage.init() not found: \(resource)")
            return nil
        }
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
extension UIScrollView {
    func scrollTo(view:UIView,animated:Bool) {
        if let superview = view.superview {
            let p = superview.convert(view.frame.origin,to:self)
            self.scrollRectToVisible(CGRect(x:0,y:p.y,width:1,height:view.frame.height),animated:animated)
        }
    }
    func scrollTo(topOf view:UIView,offset:CGFloat = 0,animated:Bool) {
        if let superview = view.superview {
            let p = superview.convert(CGPoint(x:0,y:view.frame.origin.y),to:self)
            setContentOffset(CGPoint(x:0,y:max(0,min(p.y+offset,contentSize.height-bounds.height+contentInset.bottom))),animated:animated)
        }
    }
    func scrollTo(bottomOf view:UIView,offset:CGFloat = 0,animated:Bool) {
        if let superview = view.superview {
            let p = superview.convert(CGPoint(x:0,y:view.frame.origin.y+view.frame.size.height),to:self)
            setContentOffset(CGPoint(x:0,y:max(0,min(p.y+offset,contentSize.height-bounds.height+contentInset.bottom))),animated:animated)
        }
    }
    func scrollToTop(animated:Bool) {
        setContentOffset(CGPoint(x:0,y:-contentInset.top),animated:animated)
    }
    func scrollToBottom(animated:Bool) {
        let bottomOffset = CGPoint(x:0,y:contentSize.height-bounds.size.height+contentInset.bottom)
        if(bottomOffset.y > 0) {
            setContentOffset(bottomOffset,animated:animated)
        }
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
extension UIImageView {
    public convenience init(view:UIView,frame:CGRect,image:String,tint:UIColor? = nil) {
        self.init(frame:frame)
        if let tint = tint {
            self.image = UIImage(named:image)!.withRenderingMode(.alwaysTemplate)
            self.tintColor = tint
        } else {
            self.image = UIImage(named:image)
        }
        view.addSubview(self)
    }
    public convenience init(view:UIView,frame:CGRect,image:UIImage,tint:UIColor? = nil) {
        self.init(frame:frame)
        if let tint = tint {
            self.image = image.withRenderingMode(.alwaysTemplate)
            self.tintColor = tint
        } else {
            self.image = image
        }
        view.addSubview(self)
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
extension UILabel {
    public func animate(withDuration duration: TimeInterval, text: String? = nil, color: UIColor? = nil, completion:(()->())? = nil) {
        UIView.transition(with:self, duration: duration, options: .transitionCrossDissolve, animations: { () -> Void in
            self.text = text ?? self.text
            self.textColor = color ?? self.textColor
        }) { (finish) in
            if finish { completion?() }
        }
    }
    public convenience init(view:UIView,frame:CGRect,text:String,font:UIFont,color:UIColor,align:NSTextAlignment = .left) {
        self.init(frame:frame)
        self.font = font
        self.text = text
        self.textColor = color
        self.textAlignment = align
        view.addSubview(self)
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
extension UIView {
    public var className : String {
        let m=Swift.Mirror(reflecting: self)
        return String(describing:m.subjectType)
    }
    public var hierarchy : String {
        var m = [String]()
        var v:UIView? = self
        while v != nil {
            m.append(v!.className)
            v = v!.superview
        }
        var s = ""
        while let v = m.popLast() {
            s += "/\(v)"
        }
        return s
    }
    public func setBackground(colors:[Color],direction:Double=ß.radian(degree:45),lenght:Double=1.1) {
        if let gv = self.subviews.first as? GradientView, let g=gv.gradient {
            g.colors = colors.map { $0.system.cgColor }
            g.startPoint = Point(angle:-direction+ß.π,radius:lenght*0.5).system
            g.endPoint = Point(angle:-direction,radius:lenght*0.5).system
        } else {
            let gv = GradientView(frame:bounds)
            self.insertSubview(gv,at:0)
            if let g = gv.gradient {
                g.colors = colors.map { $0.system.cgColor }
                g.startPoint = Point(angle:-direction+ß.π,radius:lenght*0.5).system
                g.endPoint = Point(angle:-direction,radius:lenght*0.5).system
            }
        }
    }
    func firstResponder() -> UIView? {
        for v in subviews {
            if v.isFirstResponder {
                return v
            } else if let vfr = v.firstResponder() {
                return vfr
            }
        }
        return nil
    }
    public func ancestor<T>() -> T? {
        var s = self.superview
        while s != nil {
            if let v=s as? T {
                return v
            }
            s = s!.superview
        }
        return nil
    }
    public func children<T>(recursive:Bool = true) -> [T] {
        var r = [T]()
        for v in self.subviews {
            if let vt = v as? T {
                r.append(vt)
            }
            if recursive {
                r.append(contentsOf:v.children())
            }
        }
        return r
    }
    public func child<T>(recursive:Bool = true) -> T? {
        for v in self.subviews {
            if let vt = v as? T {
                return vt
            }
            if recursive {
                if let vc:T = v.child() {
                    return vc
                }
            }
        }
        return nil
    }
    func find(view:UIView,label:String) -> UIView? {
        for v in view.subviews {
            if v.accessibilityLabel == label {
                return v
            }
            if let sv = find(view:v,label:label) {
                return sv
            }
        }
        return nil
    }
    public func find(label:String) -> UIView? {
        return find(view:self,label:label)
    }
    
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public class GradientView : UIView {
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
    }
    public override init(frame: CGRect) {
        super.init(frame:frame)
        self.accessibilityHint = "overlay"
        self.autoresizingMask = [.flexibleWidth,.flexibleHeight]
    }
    public override class var layerClass: AnyClass {
        return CAGradientLayer.self
    }
    public var gradient:CAGradientLayer? {
        return layer as? CAGradientLayer
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public class ScreenSync : NSObject {
    let pulse = Event<Void>()
    var displayLink:CADisplayLink?
    public override init() {
        super.init()
        displayLink = CADisplayLink(target:self,selector:#selector(synced))
        displayLink!.add(to: .current, forMode: RunLoop.Mode.default)
    }
    public func stop() {
        displayLink?.invalidate()
        displayLink = nil
    }
    @objc func synced(displayLink:CADisplayLink) {
        pulse.dispatch(())
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public class TaskMonitor {
    public class Task : Equatable {
        weak var monitor:TaskMonitor?
        var id:String
        var name:String
        init(monitor:TaskMonitor,name:String) {
            self.monitor = monitor
            self.id = ß.alphaID
            self.name=name
        }
        public func ok() {
            monitor?.remove(task:self)
        }
        public func error() {
            monitor?.remove(task:self)
        }
        public static func ==(l:Task,r:Task) -> Bool {
            return l.id == r.id
        }
    }
    let onChanged = Event<Int>()
    var tasks = [Task]()
    public func append(name:String) -> Task {
        let t = Task(monitor:self,name:name)
        DispatchQueue.main.async {
            self.tasks.append(t)
            self.onChanged.dispatch(self.tasks.count)
            Debug.warning("loadings[\(self.tasks.count)] ++ \(name)")
        }
        return t
    }
    public func remove(task:Task) {
        DispatchQueue.main.async {
            self.tasks = self.tasks.filter{ $0 != task }
            self.onChanged.dispatch(self.tasks.count)
            Debug.warning("loadings[\(self.tasks.count)] -- \(task.name)")
        }
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////

