
FROM	gitpod/workspace-full

RUN	./scripts/linux/installTool.sh -upx_i -shfmt_i -yq_i -zig_i -nim_i \
    && sudo apt-get update && sudo apt-get install -y \
	git-flow \
	&& sudo rm -rf /var/lib/apt/lists/*
