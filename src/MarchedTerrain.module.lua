local PartTerrain = {}

--> Variables -------------------------------------------------------------------------------------------------
-- Settings.
local WIDTH, HEIGHT, DEPTH, SCALE, SEED, ISOVALUE = 20, 20 , 20, 5, 50, 0
local COLOR_GRASS, COLOR_DIRT, COLOR_STONE = Color3.fromRGB(155, 191, 75), Color3.fromRGB(120, 72, 31), Color3.fromRGB(121, 120, 124)
local MATERIAL = Enum.Material.Grass
local COLLISION_FIDELITY = Enum.CollisionFidelity.DynamicPreciseConvexDecomposition

-- Tables.
local LOOKUP_TABLE = require(script.LookupTable)
local MIDPOINTS = {
	{0,1}, {1,2}, {2,3}, {3,0},
	{4,5}, {5,6}, {6,7}, {7,4},
	{0,4}, {1,5}, {2,6}, {3,7}
}
local OFFSET1, OFFSET2, OFFSET3, OFFSET4, OFFSET5, OFFSET6, OFFSET7 = 
	Vector3.new(SCALE, 0, 0),
	Vector3.new(SCALE, 0, SCALE),
	Vector3.new(0, 0, SCALE),
	Vector3.new(0, SCALE, 0),
	Vector3.new(SCALE, SCALE, 0),
	Vector3.new(SCALE, SCALE, SCALE),
	Vector3.new(0, SCALE, SCALE)
---------------------------------------------------------------------------------------------------------------


--> Helper Functions ------------------------------------------------------------------------------------------
-- Chooses the color for a tri.
local function ChooseTriColor(...)
	local t = {...}

	if table.find(t, COLOR_GRASS) then return COLOR_GRASS end
	if table.find(t, COLOR_STONE) then return COLOR_STONE end
	return COLOR_DIRT
end

-- Layered noise.
local function FractalNoise(x, y, z, octaves, lacunarity, persistence, scale)
	local value = 0 
	local x1 = x 
	local y1 = y
	local z1 = z
	local amplitude = 1
	for i = 1, octaves, 1 do
		value += math.noise(x1 / scale, y1 / scale, z1 / scale) * amplitude
		y1 *= lacunarity
		x1 *= lacunarity
		z1 *= lacunarity
		amplitude *= persistence
	end

	return value
end

-- Interpolates between 2 positions using 2 values.
local function Interpolate(vert1,val1, vert2,val2)
	return vert1+((ISOVALUE-val1)/(val2-val1))*(vert2-vert1)
end

-- Creates a vertex.
local function CreateVertex(mesh:DynamicMesh, pos:Vector3, color:Color3)
	local vertexId = mesh:AddVertex(pos)
	mesh:SetVertexColor(vertexId, color)
	return vertexId
end

-- Figures out if a DynamicMesh is valid
local function IsValidMesh(mesh:DynamicMesh)
	local ok = pcall(function() mesh:GetTriangles() end)
	return ok
end

-- Performs the marching cubes algorithm on a cube made from 8 vertex positions starting from a specified position.
local function March(startPos, values, colors, vertices, dynamicMesh:DynamicMesh, triCount)

	-- Gets the positions of the cube.
	local currPositions = {
		startPos, startPos+OFFSET1, startPos+OFFSET2, startPos+OFFSET3,
		startPos+OFFSET4, startPos+OFFSET5, startPos+OFFSET6, startPos+OFFSET7
	}

	-- Calculates the TRIANGULATION_TABLE index for the cube.
	local index = (values[startPos] < ISOVALUE and 0 or 1)
		+(values[startPos+OFFSET1] < ISOVALUE and 0 or 2)
		+(values[startPos+OFFSET2] < ISOVALUE and 0 or 4)
		+(values[startPos+OFFSET3] < ISOVALUE and 0 or 8)
		+(values[startPos+OFFSET4] < ISOVALUE and 0 or 16)
		+(values[startPos+OFFSET5] < ISOVALUE and 0 or 32)
		+(values[startPos+OFFSET6] < ISOVALUE and 0 or 64)
		+(values[startPos+OFFSET7] < ISOVALUE and 0 or 128)
	index = LOOKUP_TABLE[index+1]
	if index == 0 or index == 256 then return end

	for count=1,#index/3 do
		-- gets the indexes for the algorithm.
		local index1 = MIDPOINTS[index[(1-3)+(3*count)]+1]
		local index2 = MIDPOINTS[index[(2-3)+(3*count)]+1]
		local index3 = MIDPOINTS[index[(3-3)+(3*count)]+1]
		if index1 == nil or index2 == nil or index3 == nil then continue end

		-- Gets The positions for the algorithm.
		local positions1a, positions1b = currPositions[index1[1]+1], currPositions[index1[2]+1]
		local positions2a, positions2b = currPositions[index2[1]+1], currPositions[index2[2]+1]
		local positions3a, positions3b = currPositions[index3[1]+1], currPositions[index3[2]+1]

		-- Gets the positions of the vertices.
		local vert1Pos, vert2Pos, vert3Pos = 
			Interpolate( positions1a,values[positions1a], positions1b,values[positions1b] ),
			Interpolate( positions2a,values[positions2a], positions2b,values[positions2b] ),
			Interpolate( positions3a,values[positions3a], positions3b,values[positions3b] )

		-- Gets (or creates) each vertex and constructs a triangle with them.
		local vert1, vert2, vert3 =
			vertices[vert1Pos] or CreateVertex( dynamicMesh, vert1Pos, ChooseTriColor(colors[positions1a], colors[positions1b]) ),
			vertices[vert2Pos] or CreateVertex( dynamicMesh, vert2Pos, ChooseTriColor(colors[positions2a], colors[positions2b]) ),
			vertices[vert3Pos] or CreateVertex( dynamicMesh, vert3Pos, ChooseTriColor(colors[positions3a], colors[positions3b]) )
		dynamicMesh:AddTriangle(vert1, vert2, vert3)

		-- Adds the vertices to the vertices table if they are not already in it.
		if not vertices[vert1Pos] then vertices[vert1Pos] = vert1 end
		if not vertices[vert2Pos] then vertices[vert2Pos] = vert2 end
		if not vertices[vert3Pos] then vertices[vert3Pos] = vert3 end	
	end
end
---------------------------------------------------------------------------------------------------------------

-- Creates a new chunk.
return function(xOffset:number, yOffset:number, zOffset:number)
	assert(yOffset <= 0, '"yOffset" can\'t be greater than 0!')
	xOffset *= WIDTH*SCALE; yOffset *= HEIGHT*SCALE; zOffset *= DEPTH*SCALE

	local dynamicMesh = Instance.new("DynamicMesh")
	local values, colors, vertices = {}, {}, {}

	-- Creates data of vertex positions and colors. 
	for x=xOffset,(WIDTH*SCALE)+xOffset,SCALE do
		for z=zOffset,(DEPTH*SCALE)+zOffset,SCALE do
			for y=yOffset,(HEIGHT*SCALE)+yOffset,SCALE do
				local pos = Vector3.new(x,y,z)

				local value, color = FractalNoise(x, z, SEED,
					8,  -- Octaves.
					10, -- Lacunarity.
					0,  -- Persistence.
					200 -- Scale.
				) +(y*0.02)-ISOVALUE, COLOR_GRASS

				-- If below the surface.
				if value < ISOVALUE then
					local caveValue = FractalNoise(x, y, z,
						8,  -- Octaves.
						10, -- Lacunarity.
						0,  -- Persistence.
						20  -- Scale.
					)

					color = value <  -.6 and COLOR_STONE or value < ISOVALUE and COLOR_DIRT or color
					value = caveValue > value and caveValue or value	
				end

				values[pos] = value
				colors[pos] = color
			end
		end
	end

	-- Marches through the vertices and constructs the mesh.
	for x=xOffset,(WIDTH*SCALE)+xOffset,SCALE do
		if x > ((WIDTH*SCALE)+xOffset)-SCALE then continue end

		for z=zOffset,(DEPTH*SCALE)+zOffset,SCALE do
			if z > ((DEPTH*SCALE)+zOffset)-SCALE then continue end

			for y=yOffset,(HEIGHT*SCALE)+yOffset,SCALE do
				if y > ((HEIGHT*SCALE)+yOffset)-SCALE then continue end
				local pos = Vector3.new(x,y,z)
				March(pos, values, colors, vertices, dynamicMesh)
			end
		end
	end
	
	if not IsValidMesh(dynamicMesh) then return end

	-- loads the DynamicMesh's data into a MeshPart.
	dynamicMesh.Parent = workspace
	local meshPart = dynamicMesh:CreateMeshPartAsync(COLLISION_FIDELITY)
	meshPart.Name = `Terrain [{xOffset}, {yOffset}, {zOffset}]`
	meshPart.Material = MATERIAL
	meshPart.Anchored = true
	meshPart.Parent = workspace
	dynamicMesh:Destroy()
end
