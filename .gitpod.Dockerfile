FROM gitpod/workspace-full

RUN echo $(whoami)
RUN echo $HOME
RUN mkdir -p "${HOME}/gitpodDockerFileScripts"
COPY scripts/linux/installUpx.sh "${HOME}/gitpodDockerFileScripts"
COPY scripts/linux/installNim.sh "${HOME}/gitpodDockerFileScripts"
COPY scripts/linux/installZig.sh "${HOME}/gitpodDockerFileScripts"
RUN ls -lah "${HOME}/gitpodDockerFileScripts"
RUN chmod +x "${HOME}/gitpodDockerFileScripts/*.sh"
RUN "${HOME}/gitpodDockerFileScripts/installUpx.sh"
RUN "${HOME}/gitpodDockerFileScripts/installNim.sh"
RUN "${HOME}/gitpodDockerFileScripts/installZig.sh"
