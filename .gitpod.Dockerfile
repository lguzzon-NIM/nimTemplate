FROM gitpod/workspace-full

USER root
RUN echo $(whoami)
RUN echo $HOME

RUN mkdir -p "/home/gitpod/gitpodDockerFileScripts"
COPY scripts/linux/installUpx.sh "/home/gitpod/gitpodDockerFileScripts"
COPY scripts/linux/installNim.sh "/home/gitpod/gitpodDockerFileScripts"
COPY scripts/linux/installZig.sh "/home/gitpod/gitpodDockerFileScripts"
RUN ls -lah "/home/gitpod/gitpodDockerFileScripts"

RUN chown gitpod:gitpod "/home/gitpod/gitpodDockerFileScripts/installUpx.sh"
RUN chmod +x "/home/gitpod/gitpodDockerFileScripts/installUpx.sh"
RUN chown gitpod:gitpod "/home/gitpod/gitpodDockerFileScripts/installNim.sh"
RUN chmod +x "/home/gitpod/gitpodDockerFileScripts/installNim.sh"
RUN chown gitpod:gitpod "/home/gitpod/gitpodDockerFileScripts/installZig.sh"
RUN chmod +x "/home/gitpod/gitpodDockerFileScripts/installZig.sh"

USER gitpod
RUN echo $(whoami)
RUN echo $HOME

RUN "/home/gitpod/gitpodDockerFileScripts/installUpx.sh"
RUN "/home/gitpod/gitpodDockerFileScripts/installNim.sh"
RUN "/home/gitpod/gitpodDockerFileScripts/installZig.sh"
