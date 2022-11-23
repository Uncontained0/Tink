# What is Tink?

Tink is a powerful & performant networking library for
Roblox. It introduces a new way of networking, communicating
directly between instance bindings.

## Motivation

I love Knit. It's an amazing framework that has powered
some of the most amazing games there are. However, it has
some important issues that cannot be solved without breaking
changes. Getting services, creating services, the lifecycle
model, singletons, and networking are all issues that Tink
addresses.

Tink learns from not just Knit, but also from BridgeNet.
BridgeNet is extremely performant, reducing the amount of
bandwidth used by a significant amount. However, it lacks
even the most basic structure, leaving that up to the user.

Tink combines the structure of Knit with the performance of
BridgeNet, and adds a few more features to make it even
better. Tink brings a new approach to networking with
instance bindings that you'll find works far better than the
singleton model.

## Improvements

- **Client singletons no longer exist.** <br>
Instead, you create modules that return a table. These can
then be required by other modules and used as if they were
singletons.

- **The Lifecycle is dead. Long live the Lifecycle.** <br>
The lifecycle model is a great idea to work around certain
constraints that Knit imposed, but these constraints have
been abolished. However, if you wish, you can still use the
lifecycle model with just a bit of setup.

- **Services are just modules.** <br>
Forget `Lib.GetService`, now you can just return the service
from it's module, and require the module. You never have to
worry about a service not being ready for use either.

- **Everything is a RemoteFunction.** <br>
Think about it, what do you use RemoteEvents for? One way
RemoteFunctions. Under the hood Tink uses RemoteEvents, but
from the developer's perspective, they just have a
RemoteFunction without a return.

- **Networking is now instance based.** <br>
Singletons are great, and thats why Tink has them. However,
Tink also introduces a new way of networking. Instance
bindings allow you to communicate directly between instance
bound objects.