all: build-linux build-mac

# 定义所有需要编译的目录
TARGETS := cmd/bench-tcp lib/evio lib/netpoll lib/gnet lib/gev lib/nbio

# 为每个目标生成构建规则
define build_rules
build-linux: $(1).linux
build-mac: $(1).mac

$(1).linux:
	GOOS=linux GOARCH=amd64 go build -o $(1).linux ./$(1)

$(1).mac:
	GOOS=darwin GOARCH=amd64 go build -o $(1).mac ./$(1)
endef

# 为每个目标应用构建规则
$(foreach target,$(TARGETS),$(eval $(call build_rules,$(target))))

clean:
	rm -f *.linux *.mac