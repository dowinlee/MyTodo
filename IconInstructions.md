# 待办事项应用图标使用指南

## 方法一：使用SVG文件生成图标

1. 我已创建了一个`TodoIcon.svg`文件，这是一个矢量格式的图标。
2. 您可以使用以下工具将SVG转换为所需的各种大小的PNG图标：
   - 在线工具：https://appicon.co/ 或 https://iconify.design/
   - 上传SVG文件，工具会自动生成iOS所需的所有图标尺寸

3. 将生成的PNG文件放到`Assets.xcassets/AppIcon.appiconset/`目录下

## 方法二：使用Xcode内置功能

1. 在Xcode中打开项目
2. 如果项目中没有Asset Catalog，创建一个：
   - 右键点击项目导航器中的项目文件夹
   - 选择New File... > Asset Catalog > 命名为"Assets"（默认会创建为Assets.xcassets）

3. 在Assets.xcassets中添加应用图标：
   - 右键点击Assets.xcassets
   - 选择"New App Icon"
   - 将会创建AppIcon设置

4. 使用`TodoIcon.svg`作为源文件：
   - 可以使用图像编辑软件（如Sketch、Figma、Photoshop等）打开SVG文件
   - 导出为1024x1024 PNG图像
   - 拖放到Xcode的AppIcon中，Xcode会自动生成所有所需尺寸

## 注意事项

- App Store要求图标必须是1024x1024像素的PNG格式
- 图标不应包含透明部分
- 图标应有圆角，但不要手动添加圆角，iOS会自动应用圆角效果 