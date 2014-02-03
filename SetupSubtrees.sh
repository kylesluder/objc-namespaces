#!/bin/sh

git remote add llvm-mirror https://github.com/llvm-mirror/llvm.git
git remote add clang-mirror https://github.com/llvm-mirror/clang.git
git remote add compiler-rt-mirror https://github.com/llvm-mirror/compiler-rt.git

git subtree add --prefix=llvm llvm-mirror master
git subtree add --prefix=llvm/tools/clang clang-mirror master
git subtree add --prefix=llvm/projects/compiler-rt compiler-rt-mirror master