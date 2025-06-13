#!/bin/bash

# Get the absolute path of the project root
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# 定义所有需要编译的目录
TARGETS=(
    "cmd/bench-tcp"
    "lib/evio"
    "lib/netpoll"
    "lib/gnet"
    "lib/gev"
    "lib/nbio"
    "lib/uio"
    "lib/pulse"
    "lib/net-tcp"
    "lib/pulse-et"
)

# 创建输出目录
mkdir -p "$PROJECT_ROOT/bin"

# 构建函数
build_target() {
    local target=$1
    local os=$2
    local arch=$3
    local output_suffix=$4
    
    local target_name=$(basename "$target")
    local output_file="$PROJECT_ROOT/bin/${target_name}.${output_suffix}"
    
    echo "Building $target for $os/$arch..."
    
    # 检查目标目录是否存在
    if [ ! -d "$PROJECT_ROOT/$target" ]; then
        echo "Error: Target directory $target does not exist"
        return 1
    fi
    
    # 构建可执行文件
    GOOS=$os GOARCH=$arch go build -o "$output_file" "./$target"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to build $target for $os/$arch"
        return 1
    fi
    
    # 确保文件可执行
    chmod +x "$output_file"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to make $output_file executable"
        return 1
    fi
    
    echo "Successfully built $output_file"
    return 0
}

# 构建所有目标
build_all() {
    local build_failed=0
    
    for target in "${TARGETS[@]}"; do
        # 构建 Linux 版本
        build_target "$target" "linux" "amd64" "linux"
        if [ $? -ne 0 ]; then
            build_failed=1
        fi
        
        # 构建 Mac 版本
        build_target "$target" "darwin" "arm64" "mac"
        if [ $? -ne 0 ]; then
            build_failed=1
        fi
    done
    
    if [ $build_failed -eq 1 ]; then
        echo "Error: Some builds failed"
        return 1
    fi
    
    echo "All builds completed successfully"
    return 0
}

# 清理函数
clean() {
    echo "Cleaning build directory..."
    rm -rf "$PROJECT_ROOT/bin"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to clean build directory"
        return 1
    fi
    echo "Clean completed successfully"
    return 0
}

# 主函数
main() {
    # 如果没有参数，显示使用方法
    if [ $# -eq 0 ]; then
        echo "Usage: $0 {clean|build|clean build}"
        exit 1
    fi
    
    # 处理所有参数
    for arg in "$@"; do
        case "$arg" in
            "clean")
                clean
                if [ $? -ne 0 ]; then
                    echo "Error: Clean operation failed"
                    exit 1
                fi
                ;;
            "build")
                build_all
                if [ $? -ne 0 ]; then
                    echo "Error: Build operation failed"
                    exit 1
                fi
                ;;
            *)
                echo "Error: Unknown argument '$arg'"
                echo "Usage: $0 {clean|build|clean build}"
                exit 1
                ;;
        esac
    done
}

# 执行主函数
main "$@" 