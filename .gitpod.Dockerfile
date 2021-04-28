
FROM	gitpod/workspace-full
RUN \
  echo "**** install runtime dependencies ****" \
  && sudo apt-get update \
  && sudo apt-get install -y \
    git-flow \
    build-essential \
  && echo "**** clean up ****" \
  && sudo apt-get autoremove \
  && sudo apt-get clean \
  && sudo rm -rf \
    /tmp/* \
    /var/lib/apt/lists/* \
    /var/tmp/* || true

