# bench-tcp
异步io库压测仓库, 收集了go生态的流行异步io库

## linux压测配置
修改 ~/.bashrc 或者~/.zshrc, 加上如下
```
ulimit -n 1024000 #修改单进程最大fd
```

## 批量压测
* 控制被压测的框架
```bash
# ./benchmark/config.sh 这个文件的头部
# 不想压测的框架，直接注释就行
ENABLED_SERVERS=(
     "net-tcp"
     "uio"
     "evio"
     "netpoll"
     "gnet"
     "gev"
     "nbio"
     "pulse"
     "pulse-et"
)
```
* 运行
```
./benchmark/benchmark-c10k.sh
```

## 单个文件测试
# 使用单文件测试echo的完整性(正确性)
```
./bench-tcp.linux -a 127.0.0.1:8080 -c 1 -d 100s --open-tmp-result --verify-file ./test_7MB.txt --save-err
```

# 单跑压测客户端
```
./bin/bench-tcp.linux -c 10000 -d 1000s --open-tmp-result -a "127.0.0.1:8080"
```
