#!/bin/zsh

CLANG=../llvm/ObjRoot/Debug+Asserts/bin/clang
CLANG_ARGS=("-cc1" "-triple" "x86_64-apple-macosx10.9.0" "-fsyntax-only" "-disable-free" "-main-file-name" "namespace.m" "-mrelocation-model" "pic" "-pic-level" "2" "-mdisable-fp-elim" "-masm-verbose" "-munwind-tables" "-target-cpu" "core2" "-target-linker-version" "224.1" "-gdwarf-2" "-resource-dir" "/Users/Shared/objc-namespaces/llvm/ObjRoot/Debug+Asserts/bin/../lib/clang/3.5" "-isysroot" "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.9.sdk" "-fdebug-compilation-dir" "/Users/Shared/objc-namespaces/examples" "-ferror-limit" "19" "-fmessage-length" "204" "-stack-protector" "1" "-mstackrealign" "-fblocks" "-fobjc-runtime=macosx-10.9.0" "-fencode-extended-block-signature" "-fobjc-exceptions" "-fexceptions" "-fdiagnostics-show-option" "-fcolor-diagnostics" "-vectorize-slp" "-x" "objective-c" "$@")

if [[ "$1" == "-g" ]]; then
    exec lldb $CLANG -- $CLANG_ARGS[@]
else
    exec $CLANG $CLANG_ARGS[@]
fi
