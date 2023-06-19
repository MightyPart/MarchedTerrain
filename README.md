# MarchedTerrain
A Roblox Marching Cubes Terrain System That Uses DynamicMesh

<details>
<summary>Images Of Terrain System</summary>

![image](https://github.com/MightyPart/MarchedTerrain/assets/66361859/cbe395a8-de87-45e8-b982-b2a1b483e5d6)
![image](https://github.com/MightyPart/MarchedTerrain/assets/66361859/3505eaf9-3793-465e-a15c-4ab3bbb258df)

</details>

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

- - -

*DISCLAIMER: In its current form you will need to manually enable the `DoubleSided` property on each mesh in order for the mesh to appear correctly.*
