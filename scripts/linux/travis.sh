#!/bin/bash
set -ev

readonly aptGetCmd="sudo -E apt-get -y -qq"
readonly aptGetInstallCmd="${aptGetCmd} --no-install-suggests --no-install-recommends install"

#Before Install
if [ -z ${nim_branch+x} ]; then
	export nim_branch=master
fi
if [ -z ${useGCC+x} ]; then
	export useGCC=4.8
fi
sudo -E add-apt-repository -y ppa:ubuntu-toolchain-r/test
${aptGetCmd} update
${aptGetInstallCmd} "gcc-${useGCC}" "g++-${useGCC}" git
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-${useGCC} 10
sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-${useGCC} 10
sudo update-alternatives --set gcc "/usr/bin/gcc-${useGCC}"
sudo update-alternatives --set g++ "/usr/bin/g++-${useGCC}"
${aptGetCmd} autoremove
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

if [ ${nimTargetOS} = "windows" ]; then
	${aptGetInstallCmd} mingw-w64 wine
	if [ ${nimTargetCPU} = "i386" ]; then
		dpkg --add-architecture i386
		${aptGetCmd} update
		${aptGetInstallCmd} wine32
		export WINEARCH=win32
		{
			echo i386.windows.gcc.path = \"/usr/bin\"
			echo i386.windows.gcc.exe = \"i686-w64-mingw32-gcc\"
			echo i386.windows.gcc.linkerexe = \"i686-w64-mingw32-gcc\"
			echo gcc.options.linker = \"\"
		} >nim.cfg
	else
		export WINEARCH=win64
		if [ ${nimTargetCPU} = "amd64" ]; then
			{
				echo amd64.windows.gcc.path = \"/usr/bin\"
				echo amd64.windows.gcc.exe = \"x86_64-w64-mingw32-gcc\"
				echo amd64.windows.gcc.linkerexe = \"x86_64-w64-mingw32-gcc\"
				echo gcc.options.linker = \"\"
			} >nim.cfg
		fi
	fi
	wine hostname
else
	if [ ${nimTargetCPU} = "i386" ]; then
		${aptGetInstallCmd} gcc-${useGCC}-multilib g++-${useGCC}-multilib
	fi
fi

#Before Script
export PATH="$(pwd)/${nimApp}/bin${PATH:+:$PATH}"

#Script
echo "target OS  [${nimTargetOS}]"
echo "target CPU [${nimTargetCPU}]"
# nim tasks
# nim test
nim buildReleaseFromEnv
