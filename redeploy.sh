#!/bin/bash

# 自动重新部署脚本
# 用于快速重新安装应用到设备

echo "🚀 开始重新部署 MyTodo 应用..."

# 清理构建缓存
echo "🧹 清理构建缓存..."
xcodebuild clean -project MyTodo.xcodeproj -scheme MyTodo

# 构建并安装到连接的设备
echo "📱 构建并安装到设备..."
xcodebuild -project MyTodo.xcodeproj -scheme MyTodo -destination 'generic/platform=iOS' build

# 检查是否有连接的设备
DEVICES=$(xcrun xctrace list devices | grep "iPhone\|iPad" | grep -v "Simulator" | head -1)
if [ -n "$DEVICES" ]; then
    echo "📱 检测到设备: $DEVICES"
    echo "🔧 正在安装..."
    xcodebuild -project MyTodo.xcodeproj -scheme MyTodo -destination 'generic/platform=iOS' install
else
    echo "⚠️  未检测到连接的设备，请确保设备已连接并信任此电脑"
fi

echo "✅ 部署完成！"
echo ""
echo "📋 接下来的步骤："
echo "1. 在设备上打开 设置 > 通用 > VPN与设备管理"
echo "2. 找到你的开发者证书并点击信任"
echo "3. 打开 MyTodo 应用"
echo ""
echo "💡 提示：如果使用付费开发者账户，证书有效期会更长" 