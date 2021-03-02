	
FROM	gitpod/workspace-full
USER	root
RUN	echo $(whoami)
RUN	echo $HOME
RUN	apt-get update && apt-get install -y \
	git-flow \
	&& rm -rf /var/lib/apt/lists/*
RUN	mkdir -p "/home/gitpod/gitpodDockerFileScripts"
COPY	scripts/linux/installTool.sh	"/home/gitpod/gitpodDockerFileScripts"
COPY	scripts/linux/installUpx.sh	"/home/gitpod/gitpodDockerFileScripts"
COPY	scripts/linux/installZig.sh	"/home/gitpod/gitpodDockerFileScripts"
RUN	ls -lah "/home/gitpod/gitpodDockerFileScripts"
RUN	chown gitpod:gitpod "/home/gitpod/gitpodDockerFileScripts/installTool.sh"
RUN	chmod +x "/home/gitpod/gitpodDockerFileScripts/installTool.sh"
RUN	chown gitpod:gitpod "/home/gitpod/gitpodDockerFileScripts/installUpx.sh"
RUN	chmod +x "/home/gitpod/gitpodDockerFileScripts/installUpx.sh"
RUN	chown gitpod:gitpod "/home/gitpod/gitpodDockerFileScripts/installZig.sh"
RUN	chmod +x "/home/gitpod/gitpodDockerFileScripts/installZig.sh"
USER	gitpod
RUN	echo $(whoami)
RUN	echo $HOME
RUN	"/home/gitpod/gitpodDockerFileScripts/installTool.sh" -nim_i
RUN	"/home/gitpod/gitpodDockerFileScripts/installTool.sh" -shfmt_i
RUN	"/home/gitpod/gitpodDockerFileScripts/installTool.sh" -yq
RUN	"/home/gitpod/gitpodDockerFileScripts/installUpx.sh"
RUN	"/home/gitpod/gitpodDockerFileScripts/installZig.sh"
