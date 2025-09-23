// Copyright 2020 Raising the Floor - US, Inc.
//
// Licensed under the New BSD license. You may not use this file except in
// compliance with this License.
//
// You may obtain a copy of the License at
// https://github.com/GPII/universal/blob/master/LICENSE.txt
//
// The R&D leading to these results received funding from the:
// * Rehabilitation Services Administration, US Dept. of Education under
//   grant H421A150006 (APCP)
// * National Institute on Disability, Independent Living, and
//   Rehabilitation Research (NIDILRR)
// * Administration for Independent Living & Dept. of Education under grants
//   H133E080022 (RERC-IT) and H133E130028/90RE5003-01-00 (UIITA-RERC)
// * European Union's Seventh Framework Programme (FP7/2007-2013) grant
//   agreement nos. 289016 (Cloud4all) and 610510 (Prosperity4All)
// * William and Flora Hewlett Foundation
// * Ontario Ministry of Research and Innovation
// * Canadian Foundation for Innovation
// * Adobe Foundation
// * Consumer Electronics Association Foundation

import Cocoa

/// The view that shows a collection of MorphicBar items
public class MorphicBarView: NSView, MorphicBarWindowChildViewDelegate {
    
    // MARK: - Item Views
    
    /// The item views in order of appearance
    public private(set) var itemViews = [MorphicBarItemViewProtocol]()
    
    public var tray: MorphicBarTrayView?
    
    private var freeSpace: CGFloat = 0
    /// Add an item view to the end of the MorphicBar
    ///
    /// - parameters:
    ///   - itemView: The item view to add
    public func add(itemView: MorphicBarItemViewProtocol) {
        itemView.morphicBarView = self

        if itemView.intrinsicContentSize.height <= freeSpace {
            freeSpace -= itemView.intrinsicContentSize.height + itemSpacing
            tray?.maxSpace += itemView.intrinsicContentSize.height + itemSpacing
            itemViews.append(itemView)
            addSubview(itemView)
            invalidateIntrinsicContentSize()
        } else {
            tray?.add(itemView: itemView)
        }
    }
    
    /// Remove the item view at the given index
    ///
    /// - parameters:
    ///   - index: The index of the item to remove
    public func removeItemView(at index: Int) {
        let itemView = itemViews[index]
        itemViews.remove(at: index)
        itemView.removeFromSuperview()
        freeSpace += itemView.intrinsicContentSize.height + itemSpacing
        tray?.maxSpace -= itemView.intrinsicContentSize.height + itemSpacing
        invalidateIntrinsicContentSize()

        itemView.morphicBarView = nil
    }
    
    /// Remove all item views from the MorphicBar
    public func removeAllItemViews() {
        for i in (0..<itemViews.count).reversed() {
            removeItemView(at: i)
        }
        freeSpace = (window?.screen?.frame.height)!
        freeSpace -= (18 + 44 + 7 + 20 + 7 + 19)    //subtract space for logobutton, buffers, and closebutton
        tray?.removeAllItemViews()
        tray?.maxSpace = (18 + 44 + 7 + 7 + 19)
    }
    
    // MARK: - Layout
    
    public override var isFlipped: Bool {
        return true
    }
    
    public override func layout() {
        let itemViewsWithFrames = calculateFramesOfItemViews(itemViews, orientation: self.orientation)
        for itemViewWithFrame in itemViewsWithFrames {
            itemViewWithFrame.itemView.frame = itemViewWithFrame.frame
        }        
    }
    
    func calculateFramesOfItemViews(_ itemViews: [MorphicBarItemViewProtocol], orientation: MorphicBarOrientation) -> [(itemView: MorphicBarItemViewProtocol, frame: CGRect)] {
        var result: [(itemView: MorphicBarItemViewProtocol, frame: CGRect)] = []
        
        switch orientation {
        case .horizontal:
            var frame = CGRect(x: 0, y: 0, width: 0, height: self.bounds.size.height)
            for index in 0..<itemViews.count {
                let itemView = itemViews[index]
                let itemViewIntrinsicSize = itemView.intrinsicContentSize
                frame.size.width = itemViewIntrinsicSize.width
                frame.size.height = itemViewIntrinsicSize.height
                frame.origin.y = (self.bounds.size.height - itemViewIntrinsicSize.height) / 2.0
                result.append((itemView: itemView, frame: frame))
                //
                if index < itemViews.count - 1 {
                    let currentItemViewOrigin = NSPoint(x: frame.origin.x, y: frame.origin.y)
                    let nextItemY = (self.bounds.size.height - itemViews[index + 1].intrinsicContentSize.height) / 2.0
                    let nextItemViewOrigin = NSPoint(x: frame.origin.x + frame.size.width, y: nextItemY)
                    //
                    let horizontalSpacing = calculateHorizontalSpacingBetweenItemViews(leftOrigin: currentItemViewOrigin, leftView: itemView, leftViewClippingSize: itemViewIntrinsicSize, rightOrigin: nextItemViewOrigin, rightView: itemViews[index + 1], rightViewClippingSize: nil, logicalHorizontalSpacing: itemSpacing)
                    //
                    frame.origin.x += frame.size.width + horizontalSpacing
                }
            }
        case .vertical:
            var frame = CGRect(x: 0, y: 0, width: self.bounds.size.width, height: 0)
            for itemView in itemViews {
                let itemViewIntrinsicSize = itemView.intrinsicContentSize
                frame.size.width = itemViewIntrinsicSize.width
                frame.size.height = itemViewIntrinsicSize.height
                frame.origin.x = (self.bounds.size.width - itemViewIntrinsicSize.width) / 2.0
                result.append((itemView: itemView, frame: frame))
                //
                frame.origin.y += frame.size.height + itemSpacing
            }
        }
        
        return result
    }
    
    func calculateHorizontalSpacingBetweenItemViews(leftOrigin: CGPoint, leftView: MorphicBarItemViewProtocol, leftViewClippingSize: CGSize?, rightOrigin: CGPoint, rightView: MorphicBarItemViewProtocol, rightViewClippingSize: CGSize?, logicalHorizontalSpacing: CGFloat) -> CGFloat {
        let addOriginsToRects: (_ rects: [CGRect], _ origin: CGPoint) -> [CGRect] = {
            rects, origin in
            
            var result: [CGRect] = []
            for rect in rects {
                result.append(CGRect(x: rect.minX + origin.x, y: rect.minY + origin.y, width: rect.width, height: rect.height))
            }
            return result
        }
        
        let clipContentRectsToControlSize: (_ contentRects: [CGRect], _ controlSize: CGSize?) -> [CGRect] = {
            contentRects, controlSize in
        
            var mutableControlSize: CGSize
            if let controlSize = controlSize {
                mutableControlSize = controlSize
            } else {
                mutableControlSize = CGSize(width: 0, height: 0)
                for contentRect in contentRects {
                    mutableControlSize.width = max(mutableControlSize.width, contentRect.maxX)
                    mutableControlSize.height = max(mutableControlSize.height, contentRect.maxY)
                }
            }
            
            var result: [CGRect] = []
            for contentRect in contentRects {
                let xOffset: CGFloat = (contentRect.minX < 0) ? -contentRect.minX : 0
                let yOffset: CGFloat = (contentRect.minY < 0) ? -contentRect.minY : 0

                let newRect = CGRect(x: max(contentRect.minX, 0), y: max(contentRect.minY, 0), width: min(contentRect.width - xOffset, mutableControlSize.width), height: min(contentRect.height - yOffset, mutableControlSize.height))
                result.append(newRect)
            }
            return result
        }

        var leftViewContentRects = addOriginsToRects(leftView.contentFrames, leftOrigin)
        leftViewContentRects = clipContentRectsToControlSize(leftViewContentRects, leftViewClippingSize)
        var rightViewContentRects = addOriginsToRects(rightView.contentFrames, rightOrigin)
        // NOTE: the caller must pass in leftViewIntrinsicSize IF the contents need to be clipped
        rightViewContentRects = clipContentRectsToControlSize(rightViewContentRects, rightViewClippingSize)

        var result: CGFloat = 0
        
        if leftViewContentRects.count == 0 || rightViewContentRects.count == 0 {
            // if one of the views has no elements, then return the logical spacing
            return logicalHorizontalSpacing
        }
        
        // calculate the minimum spacing necessary to keep any elements from the leftView from overlapping with the rightView
        for leftRect in leftViewContentRects {
            for rightRect in rightViewContentRects {
                // determine if the rectangles are in the same vertical space
                var viewsAreInSameVerticalSpace: Bool = false
                if (rightRect.minY >= leftRect.minY && rightRect.minY <= leftRect.maxY) ||
                    (rightRect.maxY >= leftRect.minY && rightRect.maxY <= leftRect.maxY) {
                    viewsAreInSameVerticalSpace = true
                }
                
                if viewsAreInSameVerticalSpace == true {
                    if rightRect.minX < leftRect.maxX + logicalHorizontalSpacing {
                        let extraHorizontalSpacingRequired = logicalHorizontalSpacing - (rightRect.minX - leftRect.maxX)
                        if extraHorizontalSpacingRequired > result {
                            result = extraHorizontalSpacingRequired
                        }
                    }
                }
            }
        }

        return result
    }
    
    /// The orientation of the list of items
    public var orientation: MorphicBarOrientation = .horizontal {
        didSet {
            needsLayout = true
            invalidateIntrinsicContentSize()
            tray?.orientation = orientation
        }
    }

    /// The desired spacing between each item
    public var itemSpacing: CGFloat = 18.0 {
        didSet {
            needsLayout = true
            invalidateIntrinsicContentSize()
        }
    }
    
    public var minimumWidthInVerticalOrientation: CGFloat = 100
    
    public override var intrinsicContentSize: NSSize {
        let itemViewsWithFrames = calculateFramesOfItemViews(itemViews, orientation: self.orientation)

        var size: NSSize
        switch orientation {
        case .horizontal:
            size = .zero
            for itemViewWithFrame in itemViewsWithFrames {
                let itemViewFrame = itemViewWithFrame.frame
                size.width = max(size.width, itemViewFrame.maxX)
                size.height = max(size.height, itemViewFrame.height)
            }
        case .vertical:
            size = NSSize(width: minimumWidthInVerticalOrientation, height: itemSpacing * CGFloat(max(itemViews.count - 1, 0)))
            for itemViewWithFrame in itemViewsWithFrames {
                let itemViewFrame = itemViewWithFrame.frame
                size.width = max(size.width, itemViewFrame.width)
                size.height += itemViewFrame.height
            }
        }
        return size
    }
    
    public override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        // accept first mouse so the event propagates up to the window and we
        // can intercept mouseUp to snap the window to a corner
        return true
    }
    
    public func childViewBecomeFirstResponder(sender: NSView) {
        guard let window = window as? MorphicBarWindow else {
            assertionFailure("This view controller must be hosted in a MorphicBarWindow")
            return
        }
        window.currentFirstResponderChildView = sender
    }
    
    public func childViewResignFirstResponder() {
        guard let window = window as? MorphicBarWindow else {
            assertionFailure("This view controller must be hosted in a MorphicBarWindow")
            return
        }
        window.currentFirstResponderChildView = nil
    }
}

extension NSSize {
    
    public func roundedUp() -> NSSize {
        return NSSize(width: ceil(width), height: ceil(height))
    }
    
}
