Namespaces in Objective-C
=====

Objective-C has lacked namespaces since its creation. Unfortunately because it wholly embraces its message-passing model of OOP, it is very difficult to retrofit existing other languages' approaches to namespacing atop Objective-C without breaking binary compatibility. A naive namespacing approach might make it impossible for code that is not namespace-aware to send meaningful selectors to namespace-aware code.

This proposal introduces a new kind of selector that carries a namespace in addition to, but distinct from, its keywords. It redefines classes, categories and protocols to be members of namespaces, and provides rules for what namespaces their methods belong to.

Work in Progress
=====

This project is a work in progress. Mainline development is occurring on the `devel` branch. Discussion is happening in [GitHub Issues](https://github.com/kylesluder/objc-namespaces/issues?state=open).