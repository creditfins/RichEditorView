//
//  RichEditorToolbar.swift
//
//  Created by Caesar Wirth on 4/2/15.
//  Copyright (c) 2015 Caesar Wirth. All rights reserved.
//

import UIKit

/// RichEditorToolbarDelegate is a protocol for the RichEditorToolbar.
/// Used to receive actions that need extra work to perform (eg. display some UI)
///


public protocol AlphaRichEditorToolbarDelegate: class {
     func richEditorToolbarChangeTextColor(_ toolbar: RichEditorToolbar, optionItem: RichEditorDefaultOption)
    
    // also add remove format
}
@objc public protocol RichEditorToolbarDelegate: class {

    /// Called when the Text Color toolbar item is pressed.
    @objc optional func richEditorToolbarChangeTextColor(_ toolbar: RichEditorToolbar)


    /// Called when the Background Color toolbar item is pressed.
    @objc optional func richEditorToolbarChangeBackgroundColor(_ toolbar: RichEditorToolbar)

    /// Called when the Insert Image toolbar item is pressed.
    @objc optional func richEditorToolbarInsertImage(_ toolbar: RichEditorToolbar)

    /// Called when the Insert Link toolbar item is pressed.
    @objc optional func richEditorToolbarInsertLink(_ toolbar: RichEditorToolbar)
}

/// RichBarButtonItem is a subclass of UIBarButtonItem that takes a callback as opposed to the target-action pattern
@objcMembers open class RichBarButtonItem: UIBarButtonItem {
    open var actionHandler: (() -> Void)?
    
    public convenience init(image: UIImage? = nil, selectedImage: UIImage? = nil,tag: Int ,handler: (() -> Void)? = nil) {
        let btn = UIButton(type: UIButtonType.custom)
        btn.setImage(image, for: .normal)
        btn.setImage(selectedImage, for: .selected)
        btn.tag = tag
        self.init(customView: btn)
        
        btn.addTarget(self, action:#selector(RichBarButtonItem.buttonWasTapped) , for: .touchUpInside)
        actionHandler = handler
    }
    
    public convenience init(image: UIImage? = nil, handler: (() -> Void)? = nil) {
        self.init(image: image, style: .plain, target: nil, action: nil)
        target = self
        action = #selector(RichBarButtonItem.barButtonWasTapped)
        actionHandler = handler
    }
    
    public convenience init(title: String = "", handler: (() -> Void)? = nil) {
        self.init(title: title, style: .plain, target: nil, action: nil)
        target = self
        action = #selector(RichBarButtonItem.barButtonWasTapped)
        actionHandler = handler
    }
    
    @objc func buttonWasTapped(_ sender: Any) {
        let toggleSelection = !((sender as! UIButton).isSelected)
        (sender as! UIButton).isSelected = toggleSelection
        actionHandler?()
    }
    
    @objc func barButtonWasTapped() { // not UIbutton
        actionHandler?()
    }
}

/// RichEditorToolbar is UIView that contains the toolbar for actions that can be performed on a RichEditorView
@objcMembers open class RichEditorToolbar: UIView {

    /// The delegate to receive events that cannot be automatically completed
    open weak var delegate: RichEditorToolbarDelegate?
    open weak var alphaDelegate: AlphaRichEditorToolbarDelegate?

    /// A reference to the RichEditorView that it should be performing actions on
    open weak var editor: RichEditorView?

    /// The list of options to be displayed on the toolbar
    open var options: [RichEditorOption] = [] {
        didSet {
            updateToolbar()
        }
    }

    /// The tint color to apply to the toolbar background.
    open var barTintColor: UIColor? {
        get { return backgroundToolbar.backgroundColor }
        set { backgroundToolbar.backgroundColor = newValue }
    }
    
    private var toolbarScroll: UIScrollView
    private var toolbar: UIToolbar
    private var backgroundToolbar: UIToolbar
    
    public init(frame: CGRect, backgroundColor: UIColor) {
        toolbarScroll = UIScrollView()
        toolbar = UIToolbar()
        backgroundToolbar = UIToolbar()
        super.init(frame: frame)
        setup(backgroundColor: backgroundColor)
    }
    
    public override init(frame: CGRect) {
        toolbarScroll = UIScrollView()
        toolbar = UIToolbar()
        backgroundToolbar = UIToolbar()
        super.init(frame: frame)
        setup()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        toolbarScroll = UIScrollView()
        toolbar = UIToolbar()
        backgroundToolbar = UIToolbar()
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup(backgroundColor: UIColor? = nil) {
        autoresizingMask = .flexibleWidth
        self.backgroundColor = .clear

        backgroundToolbar.frame = bounds
        backgroundToolbar.autoresizingMask = [.flexibleHeight, .flexibleWidth]

        toolbar.autoresizingMask = .flexibleWidth
        toolbar.backgroundColor = backgroundColor ?? .clear
        toolbar.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
        toolbar.setShadowImage(UIImage(), forToolbarPosition: .any)

        toolbarScroll.frame = bounds
        toolbarScroll.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        toolbarScroll.showsHorizontalScrollIndicator = false
        toolbarScroll.showsVerticalScrollIndicator = false
        toolbarScroll.backgroundColor = .clear

        toolbarScroll.addSubview(toolbar)

        addSubview(backgroundToolbar)
        addSubview(toolbarScroll)
        updateToolbar()
    }
    
    private func updateToolbar() {
        var buttons = [UIBarButtonItem]()
        for option in options {
            let handler = { [weak self] in
                if let strongSelf = self {
                    option.action(strongSelf, optionItem: option as? RichEditorDefaultOption)
                }
            }

            if let image = option.image {
                let button = RichBarButtonItem(image: image, selectedImage: option.selectedImage, tag: option.tag, handler: handler)
             
                buttons.append(button)
            } else {
                let title = option.title
                let button = RichBarButtonItem(title: title, handler: handler)
                buttons.append(button)
            }
        }
        toolbar.items = buttons

        let defaultIconWidth: CGFloat = 50
        let barButtonItemMargin: CGFloat = 0
        let width: CGFloat = buttons.reduce(0) {sofar, new in
            if let view = new.value(forKey: "view") as? UIView {
                return sofar + view.frame.size.width + barButtonItemMargin
            } else {
                return sofar + (defaultIconWidth + barButtonItemMargin)
            }
        }
        
        if width < frame.size.width {
            toolbar.frame.size.width = frame.size.width
        } else {
            toolbar.frame.size.width = width
        }
        toolbar.frame.size.height = backgroundToolbar.frame.size.height
    
        toolbarScroll.contentSize.width = width
    }
    
}
