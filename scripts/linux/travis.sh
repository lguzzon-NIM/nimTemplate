#!/bin/bash
set -ev

#Before Install
if [ -z ${nim_branch+x} ]; then
  export nim_branch=master
fi
if [ -z ${useGCC+x} ]; then
  export useGCC=4.8
fi
sudo -E add-apt-repository -y ppa:ubuntu-toolchain-r/test
sudo -E apt-get -y -qq update
sudo -E apt-get -y -qq --no-install-suggests --no-install-recommends install "gcc-${useGCC}" "g++-${useGCC}" git
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-${useGCC} 10
sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-${useGCC} 10
sudo update-alternatives --set gcc "/usr/bin/gcc-${useGCC}"
sudo update-alternatives --set g++ "/usr/bin/g++-${useGCC}"
if [ ${nimTargetCPU} = "i386" ]; then
  sudo -E apt-get -y -qq --no-install-suggests --no-install-recommends install gcc-${useGCC}-multilib g++-${useGCC}-multilib
fi
sudo -E apt-get -y -qq autoremove
gcc --version

#Install
pushd .
mkdir -p toCache
export nimApp=toCache/nim-${nim_branch}-${useGCC}
if [ ! -x ${nimApp}/bin/nim ]; then
  git clone -b ${nim_branch} --depth 1 git://github.com/nim-lang/nim ${nimApp}/
  pushd ${nimApp}
  git clone --depth 1 git://github.com/nim-lang/csources csources/
  pushd csources
  sh build.sh
  popd
  rm -rf csources
  bin/nim c koch
  ./koch boot -d:release
  popd
else
  pushd ${nimApp}
  git fetch origin
  if ! git merge FETCH_HEAD | grep "Already up-to-date"; then
    bin/nim c koch
    ./koch boot -d:release
  fi
  popd
fi
popd

#Before Script
export PATH="$(pwd)/${nimApp}/bin${PATH:+:$PATH}"

#Script
echo "target OS  [${nimTargetOS}]"
echo "target CPU [${nimTargetCPU}]"
nim tasks
nim test
nim buildReleaseFromEnv
