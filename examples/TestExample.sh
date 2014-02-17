#!/bin/sh

../llvm/ObjRoot/Debug+Asserts/bin/clang -isysroot `xcrun --show-sdk-path` -fsyntax-only $*
