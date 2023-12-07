--!native

--// Module
local Ray = {}

--// Functions
local function insertCousins(params: { into: {Instance}, from: Instance, to: Instance })
    
    local lower = params.from
    local higher = params.to
    local ancestors = params.into
    
    if lower.Parent and lower == higher then return end
    insertCousins{ into=ancestors, from=lower.Parent, to=higher }
    
    for _,cousin in lower.Parent:GetChildren() do
        
        if cousin == lower then continue end
        table.insert(ancestors, cousin)
    end
end
local function removeDescendants(decomposedAncestors: {Instance}, removingDescendant: Instance)
    
    for index, ancestor in decomposedAncestors do
        
        if ancestor:IsAncestorOf(removingDescendant) then
            
            table.remove(decomposedAncestors, index)
            insertCousins{ into=decomposedAncestors, from=removingDescendant, to=ancestor }
            break
        end
    end
end
local function findAncestor(descendant: Instance, ancestors: {Instance}): Instance?
    
    for _,ancestor in ancestors do
        
        if descendant == ancestor or descendant:IsDescendantOf(ancestor) then return ancestor end
    end
    return nil
end

local function computeOffset(params: spatial_params): (number, Vector3)
    
    local range = params.range
    local direction = params.direction and params.direction.Unit
    
    local offset = (if direction then direction*assert(range, `range expected when using direction`)
        elseif params.to then params.to - params.from else Vector3.zero)
        + (params.plus or Vector3.zero)
    
    local distance = offset.Magnitude
    return distance, if range and distance > range then offset/(distance*range) else offset
end
local function computeFilter(params: filtring_params): RaycastParams
    
    local raycastParams = RaycastParams.new()
    if params.respectCanCollide ~= nil then raycastParams.RespectCanCollide = params.respectCanCollide end
    if params.ignoreCanQuery ~= nil then raycastParams.BruteForceAllSlow = params.ignoreCanQuery end
    if params.collisionGroup ~= nil then raycastParams.CollisionGroup = params.collisionGroup end
    if params.ignoreWater ~= nil then raycastParams.IgnoreWater = params.ignoreWater end
    
    if params.including then
        
        raycastParams.FilterType = Enum.RaycastFilterType.Include
        raycastParams.FilterDescendantsInstances = params.including
        
    elseif params.excluding then
        
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        raycastParams.FilterDescendantsInstances = params.excluding
    end
    
    return raycastParams
end

--// Module Functions
function Ray.cast(params: params): hit?
    
    local origin = params.from
    local distance, offset = computeOffset(params)
    local filterParams = computeFilter(params)
    
    local remainingDistance = distance
    local result = if params.thickness
        then workspace:Spherecast(origin, params.thickness, offset, filterParams)
        else workspace:Raycast(origin, offset, filterParams)
    
    if params.including and params.excluding then
        
        local decomposedInclusions = table.clone(params.including)
        
        while result and remainingDistance > 0 do
            
            local ancestorOfDenied = findAncestor(result.Instance, params.excluding)
            if not ancestorOfDenied then break end
            
            remainingDistance -= result.Distance
            offset = offset - (result.Position - origin)
            origin = result.Position
            
            removeDescendants(decomposedInclusions, ancestorOfDenied)
            result = if params.thickness
                then workspace:Spherecast(origin, params.thickness, offset, filterParams)
                else workspace:Raycast(origin, offset, filterParams)
        end
    end
    if not result then return end
    if result.Distance > remainingDistance then return end
    
    return {
        cframe = CFrame.lookAt(result.Position, result.Position + result.Normal),
        offset = result.Position - origin,
        distance = result.Distance,
        material = result.Material,
        instance = result.Instance,
    }
end

--// Types
export type hit = {
    material: Enum.Material,
    instance: BasePart,
    distance: number,
    offset: Vector3,
    cframe: CFrame,
}

export type spatial_params = { from: Vector3, thickness: number? } & (
    { direction: Vector3, range: number, plus: Vector3? }
    | { to: Vector3, range: number?, plus: Vector3? }
    | { plus: Vector3, range: number? }
)
export type filtring_params = {
    checker: (instance: Instance) -> boolean,
    including: {Instance}?,
    excluding: {Instance}?,
    respectCanCollide: boolean?,
    ignoreCanQuery: boolean?,
    collisionGroup: string?,
    ignoreWater: boolean?,
}
export type params = spatial_params & filtring_params

--// End
return Ray