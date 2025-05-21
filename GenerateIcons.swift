import SwiftUI

// 这个文件用于生成应用图标
// 运行此文件可创建一个基本的待办事项图标

@main
struct IconGenerator {
    static func main() {
        let sizes = [
            (name: "icon-20", size: 20),
            (name: "icon-20@2x", size: 40),
            (name: "icon-20@3x", size: 60),
            (name: "icon-29", size: 29),
            (name: "icon-29@2x", size: 58),
            (name: "icon-29@3x", size: 87),
            (name: "icon-40", size: 40),
            (name: "icon-40@2x", size: 80),
            (name: "icon-40@3x", size: 120),
            (name: "icon-60@2x", size: 120),
            (name: "icon-60@3x", size: 180),
            (name: "icon-76", size: 76),
            (name: "icon-76@2x", size: 152),
            (name: "icon-83.5@2x", size: 167),
            (name: "icon-1024", size: 1024)
        ]
        
        for size in sizes {
            generateIcon(name: size.name, size: size.size)
        }
        
        print("图标生成完成！请将生成的图标文件复制到Assets.xcassets/AppIcon.appiconset目录下")
    }
    
    static func generateIcon(name: String, size: Int) {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        
        let image = renderer.image { context in
            // 绘制背景
            let backgroundColor = UIColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 1.0)
            backgroundColor.setFill()
            context.fill(CGRect(x: 0, y: 0, width: size, height: size))
            
            // 绘制圆角矩形（清单卡片）
            let cardInset = CGFloat(size) * 0.2
            let cardRect = CGRect(x: cardInset, y: cardInset, 
                                 width: CGFloat(size) - cardInset * 2, 
                                 height: CGFloat(size) - cardInset * 2)
            
            let cardPath = UIBezierPath(roundedRect: cardRect, cornerRadius: CGFloat(size) * 0.1)
            UIColor.white.setFill()
            cardPath.fill()
            
            // 绘制待办项目线条
            let lineCount = 3
            let lineHeight = (cardRect.height - CGFloat(size) * 0.1) / CGFloat(lineCount + 1)
            let lineWidth = cardRect.width - CGFloat(size) * 0.1
            let startX = cardRect.origin.x + CGFloat(size) * 0.05
            
            for i in 1...lineCount {
                let y = cardRect.origin.y + lineHeight * CGFloat(i)
                
                // 小圆点
                let dotSize = CGFloat(size) * 0.05
                let dotRect = CGRect(x: startX, y: y - dotSize/2, width: dotSize, height: dotSize)
                let dotPath = UIBezierPath(ovalIn: dotRect)
                
                if i == 1 {
                    UIColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 1.0).setFill()
                } else {
                    UIColor.gray.setFill()
                }
                
                dotPath.fill()
                
                // 横线
                let lineY = y
                let lineStartX = startX + dotSize + CGFloat(size) * 0.03
                let line = UIBezierPath()
                line.move(to: CGPoint(x: lineStartX, y: lineY))
                line.addLine(to: CGPoint(x: startX + lineWidth, y: lineY))
                
                if i == 1 {
                    UIColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 1.0).setStroke()
                } else {
                    UIColor.gray.setStroke()
                }
                
                line.lineWidth = max(1, CGFloat(size) * 0.008)
                line.stroke()
            }
        }
        
        // 保存图像到文件
        if let data = image.pngData() {
            let filename = name + ".png"
            let fileURL = URL(fileURLWithPath: filename)
            try? data.write(to: fileURL)
            print("已生成图标: \(filename)")
        }
    }
} 