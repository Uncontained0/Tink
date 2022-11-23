# Bindings

Bindings are a new networking abstraction introduced by
Tink. They are simply a object bound to an instance that
have networking capability within their own instance.

In this guide we will be creating binding that represents
a simple gun.

## Creating a Binding

Creating bindings is very simple.

```lua
local Gun = Tink.CreateBinding()
```

## Adding Functionality

This binding doesn't actually do anything on it's own. Lets
add some functionality.

```lua
function Gun:Fire(Target)
	Target.Health -= 10
end
```

## Adding Clientside Functionality

This function is great, but the client can't access it. Lets
add some clientside functionality.

```lua
function Gun.Client:Fire(Player, Target)
	self:Fire(Target)
end
```

::: tip
Once again you'll notice that `self` refers to the binding
itself. You don't need to do `self.Server` to access the
server functions.
:::

## Lifecycle Callbacks

Unlike services, bindings have two lifecycle callbacks.
These callbacks are `Start` and `Destroying`.

Our gun's fire function is lacking some sanity checks. Let's
go ahead and add an owner to the gun in the start callback.

```lua
function Gun:Start()
	self.Owner = self.Instance:FindFirstAncestorOfClass("Player")
end
```

Now we can add a check to make sure the player is the owner
of the gun before firing.

```lua
function Gun:Fire(Target)
	if self.Owner == Players.LocalPlayer then
		Target.Health -= 10
	end
end
```

## Binding Attributes

Instances have attributes, and these are a really powerful
tool to communicate between the server and client. Tink
creates a table that wraps around the attributes of the
instance. This table is called `Attributes`.

Lets use this to add ammo to our gun.

```lua
function Gun:Start()
	self.Owner = self.Instance:FindFirstAncestorOfClass("Player")
	self.Attributes.Ammo = 10
end

function Gun:Fire(Target)
	self.Attributes.Ammo -= 1
	Target.Health -= 10
end
```

## Creating a Client Binding

Now that we have our server binding, lets create a client
binding.

```lua
local ClientGun = Tink.CreateBinding()
```

Client binding functionality is almost identical to server,
so lets add some.

```lua
function ClientGun:Start()
	ContextActionService:BindAction("Fire", function()
		self:Fire()
	end, false, Enum.UserInputType.MouseButton1)
end

function ClientGun:Fire()
	local Target = Players.LocalPlayer:GetMouse().Target
	if Target and Target.Parent:FindFirstChild("Humanoid") then
		self:Invoke("Fire", Target.Parent.Humanoid)
		self.Attributes.Ammo -= 1
	end
end
```

You can see above how we used the `Invoke` method to call
a remote function. This also works on the server side.

You can also see that we modified attributes. This is 
intentional. Client side prediction is very important, and
attributes are a very convienent way to do this.

## Listening to Attribute Changes

Speaking of attributes, lets use the ammo one to render some
UI. We can use `GetAttributeChangedSignal` on the instance
to listen for changes.

```lua
function ClientGun:Start()
	...

	self.AmmoLabel -- create some UI here

	self.Instance:GetAttributeChangedSignal("Ammo"):Connect(function()
		self:UpdateAmmo()
	end)
end

function ClientGun:UpdateAmmo()
	self.AmmoLabel.Text = self.Attributes.Ammo
end
```

## Events

Bindings share almost all of the same methods as services
related to networking. The only difference is that when
fired or invoked, the event will be fired on the instance
that the binding is bound to.

If no instance is bound on the listener side, the event will
be ignored. If it is a remote function invocation, the
invocation will return an error.

## Binding to a Tag

Now that we have a functional gun, lets bind it to a
CollectionService tag.

```lua
-- Server
Tink.Bind("Gun", Gun)

-- Client
Tink.Bind("Gun", ClientGun)
```

## Full Example

### Server

```lua
local Tink = require(game:GetService("ReplicatedStorage").Packages.Tink)

local Gun = Tink.CreateBinding()

function Gun:Start()
	self.Owner = self.Instance:FindFirstAncestorOfClass("Player")
	self.Attributes.Ammo = 10
end

function Gun:Fire(Target)
	self.Attributes.Ammo -= 1
	Target.Health -= 10
end

function Gun.Client:Fire(Player, Target)
	if self.Owner == Players.LocalPlayer then
		self:Fire(Target)
	end
end
```

### Client

```lua
local Tink = require(game:GetService("ReplicatedStorage").Packages.Tink)

local ClientGun = Tink.CreateBinding()

function ClientGun:Start()
	ContextActionService:BindAction("Fire", function()
		self:Fire()
	end, false, Enum.UserInputType.MouseButton1)

	self.AmmoLabel -- create some UI here

	self.Instance:GetAttributeChangedSignal("Ammo"):Connect(function()
		self:UpdateAmmo()
	end)
end

function ClientGun:UpdateAmmo()
	self.AmmoLabel.Text = self.Attributes.Ammo
end

function ClientGun:Fire()
	local Target = Players.LocalPlayer:GetMouse().Target
	if Target and Target.Parent:FindFirstChild("Humanoid") then
		self:Invoke("Fire", Target.Parent.Humanoid)
		self.Attributes.Ammo -= 1
	end
end
```