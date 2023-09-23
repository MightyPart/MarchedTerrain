# MarchedTerrain
A Roblox Marching Cubes Terrain System That Uses DynamicMesh

<details>
<summary>Images Of Terrain System (Please Ignore Visual Glitches)</summary>

![image](https://github.com/MightyPart/MarchedTerrain/assets/66361859/cbe395a8-de87-45e8-b982-b2a1b483e5d6)
![image](https://github.com/MightyPart/MarchedTerrain/assets/66361859/3505eaf9-3793-465e-a15c-4ab3bbb258df)
![image](https://github.com/MightyPart/MarchedTerrain/assets/66361859/ed5cbdb8-893d-43a9-b426-b4838efee2d5)



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

- - -


NOTE: You need to enable the `SimEnableDynamicMeshPhase2` FFlag to get access to DynamicMesh.

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
