# bench-tcp
异步io库压测仓库


# 使用单文件测试echo的完整性
```
./bench-tcp.linux -a 127.0.0.1:8080 -c 1 -d 100s --open-tmp-result --verify-file ./test_7MB.txt --save-err
```
