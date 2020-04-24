#!/bin/bash
set -e
set -o pipefail
set -o xtrace

git config --global user.name "Luca Guzzon"
git config --global user.email "luca.guzzon@gmail.com"

git config --global url."https://".insteadOf git://
git config --global url."https://github.com/".insteadOf git@github.com:

git config --global --replace-all alias.lg "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative"
git config --global --replace-all alias.lg-ascii "log --graph --pretty=format:'%h -%d %s (%cr) <%an>' --abbrev-commit"

# https://githowto.com/setup
git config --global core.autocrlf true
# original --> git config --global core.safecrlf true
git config --global core.safecrlf warn

git config --global --replace-all alias.co checkout
git config --global --replace-all alias.ci commit
git config --global --replace-all alias.st status
git config --global --replace-all alias.sti status --ignored
git config --global --replace-all alias.br branch

# https://switowski.com/git/2019/01/18/7-git-functions-to-make-your-life-easier.html
git config --global --replace-all alias.aliases "config --get-regexp alias"
git config --global --replace-all alias.squash '!f(){ git reset --soft HEAD~${1} && git commit --edit -m"$(git log --format=%B --reverse HEAD..HEAD@{1})"; }; f'

# https://github.com/durdn/cfg/blob/master/.gitconfig
git config --global --replace-all alias.sqc '!f(){ git reset --soft HEAD~$1 && git commit --edit -m"$(git log --format=%B --reverse HEAD..HEAD@{1})"; }; f'

git config --global credential.helper 'cache --timeout=3600'
# See also
#   https://github.com/nvie/git-toolbelt
