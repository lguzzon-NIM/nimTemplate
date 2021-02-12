FROM gitpod/workspace-full

RUN mkdir -p "${HOME}/gitpodDockerFileScripts"
COPY scripts/linux/installUpx.sh "${HOME}/gitpodDockerFileScripts"
COPY scripts/linux/installNim.sh "${HOME}/gitpodDockerFileScripts"
COPY scripts/linux/installZig.sh "${HOME}/gitpodDockerFileScripts"
WORKDIR "${HOME}/gitpodDockerFileScripts"
RUN chmod +x *.sh
RUN ./installUpx.sh
RUN ./installNim.sh
RUN ./installZig.sh
