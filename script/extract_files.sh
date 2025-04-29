#!/bin/bash

# 源文件
input_file="test.txt"

# 检查源文件是否存在
if [ ! -f "$input_file" ]; then
    echo "错误: 文件 $input_file 不存在！"
    exit 1
fi

# 定义要提取的大小（字节）
sizes=(1024 $((10*1024)) $((100*1024)) $((1*1024*1024)) \
       $((2*1024*1024)) $((3*1024*1024)) $((4*1024*1024)) $((7*1024*1024)))

# 遍历每个大小
for size in "${sizes[@]}"; do
    if (( size < 1024 * 1024 )); then
        # KB 单位处理，转换成更可读的形式（如 1KB, 10KB, 100KB）
        kb_size=$(( size / 1024 ))
        suffix="${kb_size}KB.txt"
    else
        mb_size=$(( size / 1024 / 1024 ))
        suffix="${mb_size}MB.txt"
    fi

    output_file="test_${suffix}"

    echo "提取前 $size 字节到 $output_file ..."

    # 使用 head -c 提取指定大小
    head -c "$size" "$input_file" > "$output_file"

    if [ $? -eq 0 ]; then
        echo "已成功创建文件: $output_file"
    else
        echo "提取失败: $output_file"
    fi
done

echo "完成提取。"