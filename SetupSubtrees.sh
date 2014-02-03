#!/bin/sh

COMMAND="$1"

case $COMMAND in
  "setup")
    git subtree add --prefix=llvm https://github.com/llvm-mirror/llvm.git master
    git subtree add --prefix=llvm/tools/clang https://github.com/llvm-mirror/clang.git master
    git subtree add --prefix=llvm/projects/compiler-rt https://github.com/llvm-mirror/compiler-rt.git master
  ;;
  "pull")
    git subtree merge --prefix=llvm master
    git subtree merge --prefix=llvm/tools/clang master
    git subtree merge --prefix=llvm/projects/compiler-rt master
  ;;
  *)
    echo >&2 "usage: `basename $0` [setup|pull]"
    exit 1
  ;;
esac
  