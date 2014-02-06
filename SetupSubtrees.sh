#!/bin/sh

COMMAND="$1"

case $COMMAND in
  "setup")
    git remote add -f llvm-mirror http://llvm.org/git/llvm.git
    git subtree add --prefix=llvm llvm-mirror/master

    git remote add -f clang-mirror http://llvm.org/git/clang.git
    git subtree add --prefix=llvm/tools/clang https://github.com/llvm-mirror/clang.git master

    git remote add -f compiler-rt-mirror http://llvm.org/git/compiler-rt.git
    git subtree add --prefix=llvm/projects/compiler-rt https://github.com/llvm-mirror/compiler-rt.git master

    git config remotes.llvm-mirrors "llvm-mirror clang-mirror compiler-rt-mirror"
    ;;
  "pull")
    git remote update llvm-mirrors
    git subtree merge --prefix=llvm llvm-mirror/master
    git subtree merge --prefix=llvm/tools/clang clang-mirror/master
    git subtree merge --prefix=llvm/projects/compiler-rt compiler-rt-mirror/master
  ;;
  *)
    echo >&2 "usage: `basename $0` [setup|pull]"
    exit 1
  ;;
esac
  
