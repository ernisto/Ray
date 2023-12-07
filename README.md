# Ray
Generated by [Rojo](https://github.com/rojo-rbx/rojo) 7.4.0-rc3.

## Wally Installation
To install with wally, insert it above wally.toml [dependecies]
```toml
Ray = "ernisto/ray@0.1.1"
```

## Usage
```lua
local EXPLOSION_RANGE = 15
local EXPLOSION_DAMAGE = 100

local function explode(origin: Vector3)
    
    for _,humanoid in CollectionService:GetTagged('Humanoid') do
        
        local humanoidPos = humanoid.RootPart.Position
        local wallHit = Ray.cast{ from=origin, to=humanoidPos, range=EXPLOSION_RANGE,
            respectCanCollide=true, including={ workspace.Builds }, excluding={ workspace.Builds.Windows }
        }
        if wallHit then continue end
        humanoid:TakeDamage(EXPLOSION_DAMAGE*(hit.Distance/EXPLOSION_RANGE))
        
        local bloodHit = Ray.cast{ from=humanoidPos, direction=(origin-humanoidPos), range=hit.Distance }
        if not bloodHit then continue end
        
        local blood = New "Part" {
            Shape = Enum.PartType.Cylinder,
            CFrame = bloodHit.CFrame,
            Size = Vector3.new(5, 0, 5),
            Color = Color3.new(1.00, 0.00, 0.00),
            CanCollide = false,
            Parent = workspace,
        }
    end
end
```