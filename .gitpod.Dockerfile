FROM gitpod/workspace-full

# Install nim
RUN curl https://nim-lang.org/choosenim/init.sh -sSf | CHOOSE_VERSION=devel sh -s -- -y \
    && export PATH="$HOME/.nimble/bin${PATH:+:$PATH}" \
    && echo "export PATH=\"\$HOME/.nimble/bin\${PATH:+:\$PATH}\"" >> "${HOME}/.bashrc" \
    && nim --version

#Install upx
RUN lUPXVersion=$( \
        git ls-remote --tags "https://github.com/upx/upx.git" \
        | awk '{print $2}' \
        | grep -v '{}' \
        | awk -F"/" '{print $3}' \
        | tail -1 \
        | sed "s/v//g" \
    ) \
    ;  curl -z upx.txz -o upx.txz -L "https://github.com/upx/upx/releases/download/v${lUPXVersion}/upx-${lUPXVersion}-amd64_linux.tar.xz" \
    && tar -xvf upx.txz \
    && rm upx.txz || true \
    && rm -rf "${HOME}/.upx" || true \
    && mv "upx-${lUPXVersion}-amd64_linux" "${HOME}/.upx" \
    && export PATH="$HOME/.upx${PATH:+:$PATH}" \
    && echo "export PATH=\"\$HOME/.upx\${PATH:+:\$PATH}\"" >> "${HOME}/.bashrc" \
    && upx --version

# Install zig
RUN curl -z zig.tar.xz -o zig.tar.xz -L $(curl -slL "https://ziglang.org/download/index.json" \
    |  jq -r ".master[\"x86_64-linux\"].tarball") \
    && tar -xvf zig.tar.xz \
    && rm zig.tar.xz || true \
    && mv zig-linux-x86_64* "$HOME/.zig" \
    && export PATH="$HOME/.zig${PATH:+:$PATH}" \
    && echo "export PATH=\"\$HOME/.zig\${PATH:+:\$PATH}\"" >> "${HOME}/.bashrc" \
    && zig version
