# MarchedTerrain
A Roblox Marching Cubes Terrain System That Uses DynamicMesh

- - -

# How To Use

```lua
local MarchedTerrain = require(Put.Path.To.MarchedTerrain.Here)

MarchedTerrain(0,0,0)
MarchedTerrain(0,-1,0)
```

- - -

# API

```lua
MarchedTerrain( xOffset: number, yOffset: number, zOffset: number )
```
`yOffset` must be less than or equal to 0

- - -

# How To Get Access To The `DynamicMesh` Instance

1. Switch to the `zIntegration` branch of Roblox Studio
2. Enable the `SimEnableDynamicMesh` FFlag.

- - -

# Another Example Of How To Use It

```lua
local MarchedTerrain = require(Put.Path.To.MarchedTerrain.Here)
local size = 2

for x = 0, size do
	for y = 0, -size, -1 do
		for z = 0, size do
			MarchedTerrain(x,y,z)
		end
	end
end
```
