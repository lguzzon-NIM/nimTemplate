
FROM	gitpod/workspace-full
RUN \
  echo "**** install runtime dependencies ****" && \
  sudo apt-get update && \
  sudo apt-get install -y \
	git-flow \
  echo "**** clean up ****" && \
  apt-get clean && \
  rm -rf \
    /tmp/* \
    /var/lib/apt/lists/* \
    /var/tmp/*
    
