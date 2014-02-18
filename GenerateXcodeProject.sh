#!/bin/zsh
cmake -G "Xcode" /Users/Shared/objc-namespaces/llvm -UCMAKE_OSX_SYSROOT -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX=/Users/Shared/objc-namespaces/llvm/DstRoot -DLLVM_TARGETS_TO_BUILD="X86"
