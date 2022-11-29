---
sidebar_position: 5
---

# The Network

The Tink network is a direct abstraction over a remote
event. How it works is not important to the average user,
but for those that need the extra optimization, or would
like to create a structure that uses networking, this is the
guide for you.

## Network Structure

Every frame, Tink processes the two network queues. One is
the inbound queue, the other is the outbound queue. 

Each queue is basically a list of packets. A packet is a
single event fire or invoke. It is an array that contains
the event type, and the arguments.

A single packet can be seen below.

```lua
{
	"EventFire", -- The event type, we'll learn more about identifiers later
	1, -- arg 1
	2, -- arg 2
	3, -- arg 3
	4, -- etc...
}
```

However, packets are not sent individually. Instead they are
batched together into a single remote event call. To better
send packets, they are sent as a dictionary, where the key
is the remote identifier, and the value is an array of calls
to that remote.

```lua
{
	Remote1 = {
		packet1,
		packet2,
	},

	Remote2 = {
		packet3,
		packet4,
	},
}
```

### Packet Handling

When a packet is received, it is processed and placed into
the incoming queue. At the next heartbeat this queue will be
emptied.

The first check is for the Packet's type.

- **Event**<br />
This is a simple event fire. When you call `FireTo` this
is what is sent. The only data sent is what the user
provides.
- **Invoke**<br />
This is a function invoke. When you call `InvokeTo` this
is what is sent. This packet sends a call identifier to
identify the return with, as well as the user's data.
- **InvokeReturn**<br />
This is a function invoke return. It contains the call
identifier, if the function ran successfully (any errors)
and the return data.

However, these packet types are not sent as raw strings, or
even as numbers. So lets look at Identifiers.

### Packet Sending

When a packet is sent, it is first placed into the outbound
queue. At the next heartbeat, this queue will be emptied.
The events are placed in the queue in the way they will be
sent.

### Identifiers

Identifiers are used to assign the shortest possible string
to a longer string. This reduces the amount of data sent.
Identifiers are usually not actual text.

## Network API

Now that we've covered how the Network works, lets get to
the fun part: using it.

The network can be accessed from the `Network` property on
the `Tink` object.

```lua
local Tink = require(game:GetService("ReplicatedStorage").Packages.Tink)
local Network = Tink.Network
```

The Network table is made of two parts, `Event` and
`Serdes`.

## Event API

The `Event` section of the Network API is used for actually
sending and recieving events and invokes.

### Sending Events

To send events, call `Network.Event.Fire`.

```lua
Network.Event.Fire("Remote", Player, arg1, arg2, arg3)
```

::: tip
To send events to the server, put `0` in place of the player.
:::

### Invoking Callbacks

To invoke callbacks, call `Network.Event.Invoke`.

```lua
Network.Event.Invoke("Remote", Player, arg1, arg2, arg3)
```

This function returns a promise. The promise will resolve
if the call is successful, and reject if the call errors.
You can cancel this promise to cancel the call. This is
especially useful if you want to invoke a client.

### Receiving Events

As it is uncommon to disconnect from the network, there
is no way to disconnect a connected listener.

To connect a listener, call `Network.Event.RegisterConnection`.

```lua
Network.Event.RegisterConnection("Remote", function(Player?, ...)
	print(...)
end)
```

::: tip
Any errors that occur in the listener will appear on the
local machine.
:::

### Registering Callbacks

To register a callback, call `Network.Event.RegisterCallback`.

```lua
Network.Event.RegisterCallback("Remote", function(Player?, ...)
	print(...)

	return true
end)
```

::: tip
If a callback errors, the error will be sent to the caller,
and will not be shown on the machine where the error was
created.
:::

## Serdes API

The `Serdes` part of the Network API is used for
identifiers, but may be used for more in the future.

### Getting Identifiers

Getting identifiers is a very simple process. Call
`Network.Serdes.Identifier` and pass the name of the
identifier. This will return a promise that resolves with
the identifier.

```lua
Network.Serdes.Identifier("Remote"):andThen(function(identifier)
	print(identifier)
end)
```

::: info
Why does this return a promise? Because identifiers can only
be created on the server. If you try to get an identifier
from the client, it will yield until the server has created
it.
:::

### Getting Identifier Names

To get the name of an identifier, call
`Network.Serdes.Name`.

```lua
print(Network.Serdes.Name(Identifier))
```

This function doesn't return a promise, if no name can be
found for the identifier it simply returns `nil`.

## Conclusion

Directly using the network is a very powerful tool, but it
is also filled with pitfalls. I highly suggest you read the
code that powers the network before working with it
directly.