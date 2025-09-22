#!/bin/bash

# 清理项目
echo "清理项目..."
xcodebuild -workspace IOTClient.xcworkspace -scheme IOTClient -configuration Debug clean

# 构建项目
echo "构建项目..."
xcodebuild -workspace IOTClient.xcworkspace -scheme IOTClient -configuration Debug build

# 检查构建是否成功
if [ $? -eq 0 ]; then
    echo "项目构建成功！"
    echo "您现在可以在Xcode中打开IOTClient.xcworkspace并运行项目"
else
    echo "项目构建失败，请检查错误信息"
fi