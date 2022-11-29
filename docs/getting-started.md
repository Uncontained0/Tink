---
sidebar_position: 2
---

# Getting Started

## Installation

Tink is available on [GitHub](https://github.com/Uncontained0/Tink)
and can also be installed through wally.

```toml
[[dependencies]]
Tink = "uncontained0/tink@0.1.0" // [!code ++]
```

## Basic Usage

Tink self-starts when it is required.

```lua
local Tink = require(game:GetService("ReplicatedStorage").Packages.Tink)
```

### Creating a Singleton

Creating a service is very simple.

```lua
local MoneyService = Tink.CreateService("MoneyService")

return MoneyService
```

Now lets add some functionality to our service.

```lua
function MoneyService:GetMoney(Player)
	local money = 50 -- get money from datastore

	return money
end
```

We have a very basic money service. Lets add some networking
functionality.

```lua
function MoneyService.Client:GetMoney(Player)
	return self:GetMoney(Player)
end
```

The `self` keyword in client functions refers directly to
the service, you don't need to do self.Server, but this is
still supported.

### Creating a Binding

Bindings are much more powerful than services. Creating them
is also very simple.

```lua
local KillPart = Tink.CreateBinding()
```

This binding doesn't actually do anything on it's own. Lets
add some functionality.

```lua
function KillPart:Kill(Player)
	Player.Character.Humanoid.Health = 0
end
```

Now lets expose this function to the client.

```lua
function KillPart.Client:Kill(Player)
	self:Kill(Player)
end
```

Now that the binding is full created, lets bind it to a tag.

```lua
Tink.Bind("KillPart", KillPart)
```

Now lets create a binding on the client to use this.

```lua
local ClientKillPart = Tink.CreateBinding()
```

Bindings have one lifecycle function, `Start` which is
called once the binding is created.

```lua
function ClientKillPart:Start()
	self.Instance.Touched:Connect(function(Hit)
		if Hit.Parent == Players.LocalPlayer.Character then
			-- we could use self:Invoke or self:Fire here.
			-- because the function doesn't return anything
			-- self:Fire is the better choice
			self:Fire("Kill")
		end
	end)
end
```

Now lets bind this to the tag.

```lua
Tink.Bind("KillPart", ClientKillPart)
```