#!/bin/sh

COMMAND="$1"

case $COMMAND in
  "setup-remotes")
    git remote add -f llvm-mirror http://llvm.org/git/llvm.git
    git remote add -f clang-mirror http://llvm.org/git/clang.git
    git remote add -f compiler-rt-mirror http://llvm.org/git/compiler-rt.git

    git config remotes.llvm-mirrors "llvm-mirror clang-mirror compiler-rt-mirror"
  ;;
  "setup-subtree")
    git subtree add --prefix=llvm llvm-mirror/master
    git subtree add --prefix=llvm/tools/clang https://github.com/llvm-mirror/clang.git master
    git subtree add --prefix=llvm/projects/compiler-rt https://github.com/llvm-mirror/compiler-rt.git master
  ;;
  "pull")
    git remote update llvm-mirrors
    git subtree merge --prefix=llvm llvm-mirror/master
    git subtree merge --prefix=llvm/tools/clang clang-mirror/master
    git subtree merge --prefix=llvm/projects/compiler-rt compiler-rt-mirror/master
  ;;
  *)
    echo >&2 "usage: `basename $0` [setup-remotes|setup-subtree|pull]"
    exit 1
  ;;
esac
  
