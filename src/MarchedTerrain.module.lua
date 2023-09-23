--> Variables -------------------------------------------------------------------------------------------------
-- Settings.
local WIDTH, HEIGHT, DEPTH, SCALE, SEED, ISOVALUE = 20, 20 , 20, 5, 50, 0
local COLOR_GRASS, COLOR_DIRT, COLOR_STONE = Color3.fromRGB(155, 191, 75), Color3.fromRGB(120, 72, 31), Color3.fromRGB(121, 120, 124)
local MATERIAL = Enum.Material.Grass
local COLLISION_FIDELITY = Enum.CollisionFidelity.PreciseConvexDecomposition

-- Tables.
local LOOKUP_TABLE = require(script.LookupTable)
local MIDPOINT_PARENTS = {
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

local VALUES_AND_COLORS_LENGTH =
	(((WIDTH*SCALE)/SCALE)+1)
	* (((DEPTH*SCALE)/SCALE)+1)
	* (((HEIGHT*SCALE)/SCALE)+1)
---------------------------------------------------------------------------------------------------------------


--> Helper Functions ------------------------------------------------------------------------------------------
-- Chooses the color for a vertex.
local function ChooseVertexColor(...)
	local colorTable = {...}
	return
		table.find(colorTable, COLOR_GRASS) and COLOR_GRASS
		or table.find(colorTable, COLOR_STONE) and COLOR_STONE
		or COLOR_DIRT
end

-- Layered noise.
local function FractalNoise(x, y, z, octaves, lacunarity, persistence, scale)
	local x1, y1, z1 = x, y, z
	local value, amplitude = 0, 1
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

-- Figures out if a DynamicMesh is valid.
local function IsValidMesh(mesh:DynamicMesh)
	return pcall(function() mesh:GetTriangles() end)
end

-- Performs the marching cubes algorithm on a cube of 8 positions starting from a specified position.
local function March(startPos, values, colors, vertices, dynamicMesh:DynamicMesh)

	-- Gets the positions of the cube.
	local cubePositions = {
		startPos, startPos+OFFSET1, startPos+OFFSET2, startPos+OFFSET3,
		startPos+OFFSET4, startPos+OFFSET5, startPos+OFFSET6, startPos+OFFSET7
	}

	--[[ Calculates the index in the LOOKUP_TABLE for the cube. If index is
	     0 or 256 then we return since those indexes represent empty space ]]
	local index = (values[startPos] < ISOVALUE and 0 or 1)
		+(values[startPos+OFFSET1] < ISOVALUE and 0 or 2)
		+(values[startPos+OFFSET2] < ISOVALUE and 0 or 4)
		+(values[startPos+OFFSET3] < ISOVALUE and 0 or 8)
		+(values[startPos+OFFSET4] < ISOVALUE and 0 or 16)
		+(values[startPos+OFFSET5] < ISOVALUE and 0 or 32)
		+(values[startPos+OFFSET6] < ISOVALUE and 0 or 64)
		+(values[startPos+OFFSET7] < ISOVALUE and 0 or 128)
	if index == 0 or index == 256 then return end
	local lookupData = LOOKUP_TABLE[index+1]

	--[[ lookupData is split up into chunks of 3 (this is because triangles have 3 vertices),
		 therefore if we divide its length by 3 we get the amount of times we should iterate ]]
	for count=1,#lookupData/3 do

		-- Get the indexes for each midpoint's parents.
		local countTimes3 = count*3
		local midpoint1ParentsIndexes = MIDPOINT_PARENTS[lookupData[-2+countTimes3]+1]
		local midpoint2ParentsIndexes = MIDPOINT_PARENTS[lookupData[-1+countTimes3]+1]
		local midpoint3ParentsIndexes = MIDPOINT_PARENTS[lookupData[countTimes3]+1]
		if midpoint1ParentsIndexes == nil or midpoint2ParentsIndexes == nil or midpoint3ParentsIndexes == nil then continue end

		-- Gets The positions of each midpoint's parents.
		local positions1a, positions1b = cubePositions[midpoint1ParentsIndexes[1]+1], cubePositions[midpoint1ParentsIndexes[2]+1]
		local positions2a, positions2b = cubePositions[midpoint2ParentsIndexes[1]+1], cubePositions[midpoint2ParentsIndexes[2]+1]
		local positions3a, positions3b = cubePositions[midpoint3ParentsIndexes[1]+1], cubePositions[midpoint3ParentsIndexes[2]+1]

		--[[ Calculates the positions of each midpoint by interpolating the
		     positions of both of its parents using both of its parents values ]]
		local midpoint1Pos, midpoint2Pos, midpoint3Pos = 
			Interpolate( positions1a,values[positions1a], positions1b,values[positions1b] ),
			Interpolate( positions2a,values[positions2a], positions2b,values[positions2b] ),
			Interpolate( positions3a,values[positions3a], positions3b,values[positions3b] )

		-- Gets (or creates) a vertex at each midpoint and constructs a triangle with them.
		local vertex1, vertex2, vertex3 =
			vertices[midpoint1Pos] or CreateVertex( dynamicMesh, midpoint1Pos, ChooseVertexColor(colors[positions1a], colors[positions1b]) ),
			vertices[midpoint2Pos] or CreateVertex( dynamicMesh, midpoint2Pos, ChooseVertexColor(colors[positions2a], colors[positions2b]) ),
			vertices[midpoint3Pos] or CreateVertex( dynamicMesh, midpoint3Pos, ChooseVertexColor(colors[positions3a], colors[positions3b]) )
		dynamicMesh:AddTriangle(vertex3, vertex2, vertex1)

		-- Adds each vertex to the vertices table if they are not already in it.
		if not vertices[midpoint1Pos] then vertices[midpoint1Pos] = vertex1 end
		if not vertices[midpoint2Pos] then vertices[midpoint2Pos] = vertex2 end
		if not vertices[midpoint3Pos] then vertices[midpoint3Pos] = vertex3 end	
	end
end
---------------------------------------------------------------------------------------------------------------

-- Creates a new chunk.
return function(xOffset:number, yOffset:number, zOffset:number)
	assert(yOffset <= 0, '"yOffset" can\'t be greater than 0!')
	xOffset *= WIDTH*SCALE; yOffset *= HEIGHT*SCALE; zOffset *= DEPTH*SCALE

	local dynamicMesh = Instance.new("DynamicMesh")
	local values, colors, vertices =
		table.create(VALUES_AND_COLORS_LENGTH),
		table.create(VALUES_AND_COLORS_LENGTH),
		{}

	-- Creates data for positions and colors.
	local promises = table.create(VALUES_AND_COLORS_LENGTH)
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
