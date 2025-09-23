//
//  UIExtensions.swift
//  SharedUI
//
//  Created by IOTClient on 2024.
//  Copyright © 2024 IOTClient. All rights reserved.
//

import UIKit
import SwiftUI

// MARK: - UIView Extensions

extension UIView {
    
    /// 添加子视图并设置约束
    func addSubviewWithConstraints(_ subview: UIView, insets: UIEdgeInsets = .zero) {
        addSubview(subview)
        subview.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            subview.topAnchor.constraint(equalTo: topAnchor, constant: insets.top),
            subview.leadingAnchor.constraint(equalTo: leadingAnchor, constant: insets.left),
            subview.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -insets.right),
            subview.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -insets.bottom)
        ])
    }
    
    /// 添加子视图并居中
    func addSubviewCentered(_ subview: UIView, size: CGSize? = nil) {
        addSubview(subview)
        subview.translatesAutoresizingMaskIntoConstraints = false
        
        var constraints = [
            subview.centerXAnchor.constraint(equalTo: centerXAnchor),
            subview.centerYAnchor.constraint(equalTo: centerYAnchor)
        ]
        
        if let size = size {
            constraints.append(contentsOf: [
                subview.widthAnchor.constraint(equalToConstant: size.width),
                subview.heightAnchor.constraint(equalToConstant: size.height)
            ])
        }
        
        NSLayoutConstraint.activate(constraints)
    }
    
    /// 设置圆角
    func setCornerRadius(_ radius: CGFloat, corners: UIRectCorner = .allCorners) {
        if corners == .allCorners {
            layer.cornerRadius = radius
        } else {
            let path = UIBezierPath(
                roundedRect: bounds,
                byRoundingCorners: corners,
                cornerRadii: CGSize(width: radius, height: radius)
            )
            let mask = CAShapeLayer()
            mask.path = path.cgPath
            layer.mask = mask
        }
    }
    
    /// 设置边框
    func setBorder(width: CGFloat, color: UIColor) {
        layer.borderWidth = width
        layer.borderColor = color.cgColor
    }
    
    /// 设置阴影
    func setShadow(
        color: UIColor = .black,
        offset: CGSize = CGSize(width: 0, height: 2),
        radius: CGFloat = 4,
        opacity: Float = 0.1
    ) {
        layer.shadowColor = color.cgColor
        layer.shadowOffset = offset
        layer.shadowRadius = radius
        layer.shadowOpacity = opacity
        layer.masksToBounds = false
    }
    
    /// 移除阴影
    func removeShadow() {
        layer.shadowOpacity = 0
    }
    
    /// 添加渐变背景
    func addGradient(
        colors: [UIColor],
        startPoint: CGPoint = CGPoint(x: 0, y: 0),
        endPoint: CGPoint = CGPoint(x: 1, y: 1)
    ) {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = colors.map { $0.cgColor }
        gradientLayer.startPoint = startPoint
        gradientLayer.endPoint = endPoint
        gradientLayer.frame = bounds
        
        layer.insertSublayer(gradientLayer, at: 0)
    }
    
    /// 截图
    func screenshot() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, UIScreen.main.scale)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        layer.render(in: context)
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    /// 查找父视图控制器
    var parentViewController: UIViewController? {
        var responder: UIResponder? = self
        while responder != nil {
            responder = responder?.next
            if let viewController = responder as? UIViewController {
                return viewController
            }
        }
        return nil
    }
    
    /// 动画显示
    func fadeIn(duration: TimeInterval = 0.3, completion: (() -> Void)? = nil) {
        alpha = 0
        isHidden = false
        UIView.animate(withDuration: duration, animations: {
            self.alpha = 1
        }) { _ in
            completion?()
        }
    }
    
    /// 动画隐藏
    func fadeOut(duration: TimeInterval = 0.3, completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: duration, animations: {
            self.alpha = 0
        }) { _ in
            self.isHidden = true
            self.alpha = 1
            completion?()
        }
    }
    
    /// 弹性动画
    func springAnimation(
        scale: CGFloat = 1.1,
        duration: TimeInterval = 0.3,
        completion: (() -> Void)? = nil
    ) {
        UIView.animate(
            withDuration: duration / 2,
            delay: 0,
            usingSpringWithDamping: 0.7,
            initialSpringVelocity: 0.5,
            options: .curveEaseInOut,
            animations: {
                self.transform = CGAffineTransform(scaleX: scale, y: scale)
            }
        ) { _ in
            UIView.animate(
                withDuration: duration / 2,
                delay: 0,
                usingSpringWithDamping: 0.7,
                initialSpringVelocity: 0.5,
                options: .curveEaseInOut,
                animations: {
                    self.transform = .identity
                }
            ) { _ in
                completion?()
            }
        }
    }
    
    /// 摇摆动画
    func shakeAnimation(duration: TimeInterval = 0.5) {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.duration = duration
        animation.values = [-20.0, 20.0, -20.0, 20.0, -10.0, 10.0, -5.0, 5.0, 0.0]
        layer.add(animation, forKey: "shake")
    }
}

// MARK: - UIColor Extensions

extension UIColor {
    
    /// 从十六进制字符串创建颜色
    convenience init?(hex: String) {
        let r, g, b, a: CGFloat
        
        if hex.hasPrefix("#") {
            let start = hex.index(hex.startIndex, offsetBy: 1)
            let hexColor = String(hex[start...])
            
            if hexColor.count == 8 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0
                
                if scanner.scanHexInt64(&hexNumber) {
                    r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
                    g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
                    b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
                    a = CGFloat(hexNumber & 0x000000ff) / 255
                    
                    self.init(red: r, green: g, blue: b, alpha: a)
                    return
                }
            } else if hexColor.count == 6 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0
                
                if scanner.scanHexInt64(&hexNumber) {
                    r = CGFloat((hexNumber & 0xff0000) >> 16) / 255
                    g = CGFloat((hexNumber & 0x00ff00) >> 8) / 255
                    b = CGFloat(hexNumber & 0x0000ff) / 255
                    a = 1.0
                    
                    self.init(red: r, green: g, blue: b, alpha: a)
                    return
                }
            }
        }
        
        return nil
    }
    
    /// 转换为十六进制字符串
    var hexString: String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let rgb: Int = (Int)(r * 255) << 16 | (Int)(g * 255) << 8 | (Int)(b * 255) << 0
        
        return String(format: "#%06x", rgb)
    }
    
    /// 调整亮度
    func adjustBrightness(_ amount: CGFloat) -> UIColor {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        if getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
            brightness = max(0, min(1, brightness + amount))
            return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha)
        }
        
        return self
    }
    
    /// 调整饱和度
    func adjustSaturation(_ amount: CGFloat) -> UIColor {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        if getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
            saturation = max(0, min(1, saturation + amount))
            return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha)
        }
        
        return self
    }
    
    /// 混合颜色
    func blended(with color: UIColor, ratio: CGFloat) -> UIColor {
        let ratio = max(0, min(1, ratio))
        
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        
        getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        color.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        
        return UIColor(
            red: r1 * (1 - ratio) + r2 * ratio,
            green: g1 * (1 - ratio) + g2 * ratio,
            blue: b1 * (1 - ratio) + b2 * ratio,
            alpha: a1 * (1 - ratio) + a2 * ratio
        )
    }
    
    /// 随机颜色
    static var random: UIColor {
        return UIColor(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1),
            alpha: 1.0
        )
    }
}

// MARK: - UIFont Extensions

extension UIFont {
    
    /// 创建带权重的系统字体
    static func systemFont(ofSize size: CGFloat, weight: UIFont.Weight, design: UIFontDescriptor.SystemDesign = .default) -> UIFont {
        let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
            .addingAttributes([
                .traits: [
                    UIFontDescriptor.TraitKey.weight: weight
                ]
            ])
            .withDesign(design) ?? descriptor
        
        return UIFont(descriptor: descriptor, size: size)
    }
    
    /// 创建圆角字体
    static func roundedSystemFont(ofSize size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        return systemFont(ofSize: size, weight: weight, design: .rounded)
    }
    
    /// 创建等宽字体
    static func monospaceSystemFont(ofSize size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        return systemFont(ofSize: size, weight: weight, design: .monospaced)
    }
    
    /// 调整字体大小
    func withSize(_ size: CGFloat) -> UIFont {
        return UIFont(descriptor: fontDescriptor, size: size)
    }
    
    /// 调整字体权重
    func withWeight(_ weight: UIFont.Weight) -> UIFont {
        let descriptor = fontDescriptor.addingAttributes([
            .traits: [
                UIFontDescriptor.TraitKey.weight: weight
            ]
        ])
        return UIFont(descriptor: descriptor, size: pointSize)
    }
}

// MARK: - UIImage Extensions

extension UIImage {
    
    /// 从颜色创建图像
    convenience init?(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        
        color.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        
        guard let image = UIGraphicsGetImageFromCurrentImageContext(),
              let cgImage = image.cgImage else { return nil }
        
        self.init(cgImage: cgImage)
    }
    
    /// 调整图像大小
    func resized(to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }
        
        draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    /// 裁剪为圆形
    func circularImage() -> UIImage? {
        let size = min(self.size.width, self.size.height)
        let rect = CGRect(x: 0, y: 0, width: size, height: size)
        
        UIGraphicsBeginImageContextWithOptions(rect.size, false, scale)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        context.addEllipse(in: rect)
        context.clip()
        
        draw(in: rect)
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    /// 着色
    func tinted(with color: UIColor) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        context.setBlendMode(.normal)
        
        let rect = CGRect(origin: .zero, size: size)
        guard let cgImage = cgImage else { return nil }
        
        context.clip(to: rect, mask: cgImage)
        color.setFill()
        context.fill(rect)
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    /// 添加圆角
    func rounded(cornerRadius: CGFloat) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }
        
        let rect = CGRect(origin: .zero, size: size)
        let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
        path.addClip()
        
        draw(in: rect)
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

// MARK: - UIViewController Extensions

extension UIViewController {
    
    /// 显示警告对话框
    func showAlert(
        title: String?,
        message: String?,
        actions: [UIAlertAction] = [UIAlertAction(title: "确定", style: .default)]
    ) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        actions.forEach { alert.addAction($0) }
        present(alert, animated: true)
    }
    
    /// 显示操作表
    func showActionSheet(
        title: String?,
        message: String?,
        actions: [UIAlertAction],
        sourceView: UIView? = nil
    ) {
        let actionSheet = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        actions.forEach { actionSheet.addAction($0) }
        
        // iPad 支持
        if let popover = actionSheet.popoverPresentationController {
            if let sourceView = sourceView {
                popover.sourceView = sourceView
                popover.sourceRect = sourceView.bounds
            } else {
                popover.sourceView = view
                popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            }
        }
        
        present(actionSheet, animated: true)
    }
    
    /// 显示加载指示器
    func showLoadingIndicator() -> UIView {
        let loadingView = LoadingView()
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(loadingView)
        NSLayoutConstraint.activate([
            loadingView.topAnchor.constraint(equalTo: view.topAnchor),
            loadingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loadingView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        loadingView.show()
        return loadingView
    }
    
    /// 隐藏加载指示器
    func hideLoadingIndicator(_ loadingView: UIView) {
        if let loadingView = loadingView as? LoadingView {
            loadingView.hide()
        }
        loadingView.removeFromSuperview()
    }
    
    /// 添加子视图控制器
    func addChild(_ childController: UIViewController, to containerView: UIView) {
        addChild(childController)
        containerView.addSubview(childController.view)
        childController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            childController.view.topAnchor.constraint(equalTo: containerView.topAnchor),
            childController.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            childController.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            childController.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        childController.didMove(toParent: self)
    }
    
    /// 移除子视图控制器
    func removeChild(_ childController: UIViewController) {
        childController.willMove(toParent: nil)
        childController.view.removeFromSuperview()
        childController.removeFromParent()
    }
}

// MARK: - UIStackView Extensions

extension UIStackView {
    
    /// 添加多个子视图
    func addArrangedSubviews(_ views: [UIView]) {
        views.forEach { addArrangedSubview($0) }
    }
    
    /// 移除所有子视图
    func removeAllArrangedSubviews() {
        arrangedSubviews.forEach {
            removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
    }
    
    /// 添加分隔符
    func addSeparator(color: UIColor = .separator, height: CGFloat = 1) {
        let separator = UIView()
        separator.backgroundColor = color
        separator.translatesAutoresizingMaskIntoConstraints = false
        
        addArrangedSubview(separator)
        
        if axis == .vertical {
            separator.heightAnchor.constraint(equalToConstant: height).isActive = true
        } else {
            separator.widthAnchor.constraint(equalToConstant: height).isActive = true
        }
    }
    
    /// 添加弹性空间
    func addSpacer() {
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: axis == .vertical ? .vertical : .horizontal)
        spacer.setContentCompressionResistancePriority(.defaultLow, for: axis == .vertical ? .vertical : .horizontal)
        addArrangedSubview(spacer)
    }
}

// MARK: - UIEdgeInsets Extensions

extension UIEdgeInsets {
    
    /// 创建相等的内边距
    init(all: CGFloat) {
        self.init(top: all, left: all, bottom: all, right: all)
    }
    
    /// 创建水平和垂直内边距
    init(horizontal: CGFloat, vertical: CGFloat) {
        self.init(top: vertical, left: horizontal, bottom: vertical, right: horizontal)
    }
    
    /// 水平内边距总和
    var horizontal: CGFloat {
        return left + right
    }
    
    /// 垂直内边距总和
    var vertical: CGFloat {
        return top + bottom
    }
}

// MARK: - CGSize Extensions

extension CGSize {
    
    /// 创建正方形尺寸
    init(square: CGFloat) {
        self.init(width: square, height: square)
    }
    
    /// 按比例缩放
    func scaled(by factor: CGFloat) -> CGSize {
        return CGSize(width: width * factor, height: height * factor)
    }
    
    /// 适应指定尺寸
    func aspectFit(in size: CGSize) -> CGSize {
        let aspectRatio = width / height
        let targetAspectRatio = size.width / size.height
        
        if aspectRatio > targetAspectRatio {
            return CGSize(width: size.width, height: size.width / aspectRatio)
        } else {
            return CGSize(width: size.height * aspectRatio, height: size.height)
        }
    }
    
    /// 填充指定尺寸
    func aspectFill(in size: CGSize) -> CGSize {
        let aspectRatio = width / height
        let targetAspectRatio = size.width / size.height
        
        if aspectRatio > targetAspectRatio {
            return CGSize(width: size.height * aspectRatio, height: size.height)
        } else {
            return CGSize(width: size.width, height: size.width / aspectRatio)
        }
    }
}

// MARK: - CGRect Extensions

extension CGRect {
    
    /// 中心点
    var center: CGPoint {
        return CGPoint(x: midX, y: midY)
    }
    
    /// 按内边距缩小
    func inset(by insets: UIEdgeInsets) -> CGRect {
        return CGRect(
            x: origin.x + insets.left,
            y: origin.y + insets.top,
            width: size.width - insets.horizontal,
            height: size.height - insets.vertical
        )
    }
    
    /// 按边距扩大
    func outset(by insets: UIEdgeInsets) -> CGRect {
        return CGRect(
            x: origin.x - insets.left,
            y: origin.y - insets.top,
            width: size.width + insets.horizontal,
            height: size.height + insets.vertical
        )
    }
}