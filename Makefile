all: build-linux build-mac

# 定义所有需要编译的目录
TARGETS := cmd/bench-tcp lib/evio lib/netpoll lib/gnet lib/gev lib/nbio lib/uio lib/pulse lib/net-tcp

# 创建输出目录
$(shell mkdir -p bin)

# 为每个目标生成构建规则
define build_rules
build-linux: bin/$(notdir $(1)).linux
build-mac: bin/$(notdir $(1)).mac

bin/$(notdir $(1)).linux:
	@echo "Building $(1) for Linux..."
	GOOS=linux GOARCH=amd64 go build -o bin/$(notdir $(1)).linux ./$(1)

bin/$(notdir $(1)).mac:
	@echo "Building $(1) for Mac..."
	GOOS=darwin GOARCH=arm64 go build -o bin/$(notdir $(1)).mac ./$(1)
endef

# 为每个目标应用构建规则
$(foreach target,$(TARGETS),$(eval $(call build_rules,$(target))))

clean:
	rm -rf bin

.PHONY: all build-linux build-mac clean