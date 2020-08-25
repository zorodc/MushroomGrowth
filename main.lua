-- Adds a mushroom spread mechanic to Cuberite.
-- Mushrooms will slowly duplicate themselves into neighboring tiles.
-- This is subject to certain restrictions, e.g., darkness is required.
--
-- Some background:
-- In version Beta 1.6, Minecraft added unrestricted mushroom spread.
-- In version Beta 1.8, this was severely nerfed.
-- Cuberite actually (at the time of writing) implements neither.
--
-- This plugin attempts to more-or-less mimic the 1.6 spread behavior.
-- Now, one can have proper automatic mushroom farms on Cuberite servers!
-- See the constants below for details on what parameters control growth.

-- Globals
PLUGIN = nil -- Holds the plugin object.
LOGGED = 0   -- Number of players logged in. TODO: Maybe use better heuristic?

-- Constants
Y_SEARCH_WINDOW = 32 -- Y-level around the player to search.
BLOCK_LIGHT_MAX = 12 -- Maximum light level allowed for growth.
LOOKS_PER_SWEEP = 10 -- Number of blocks to check per chunk per tick.
BASEPROBABILITY =  1 -- Base probability to grow a mushroom.

function OnDisable()
  LOG(PLUGIN:GetName() .. " is shutting down.")
end

function Initialize(Plugin)
  Plugin:SetName("MushroomGrowth")
  Plugin:SetVersion(1)
  PLUGIN = Plugin

  -- Hooks
  cPluginManager:AddHook(cPluginManager.HOOK_TICK, OnTick)

  -- Fin.
  LOG("Initialized" .. Plugin:GetName() .. " v. " .. Plugin:GetVersion())
  return true
end

function OnTick(TimeDelta)
  LOGGED = 0

  root = cRoot:Get()
  root:ForEachPlayer(function(Player) LOGGED = LOGGED + 1 end)
  root:ForEachPlayer(ChooseFromVicinity)
end

function ChooseFromVicinity(Player)
  wrealm = Player:GetWorld()
  wrealm:ForEachLoadedChunk(
      function(Cx, Cz) return SweepChunkAround_Y(wrealm, Cx, Cz, 
                                                 Player:GetEyeHeight(),
                                                 Y_SEARCH_WINDOW) end)
end

function SweepChunkAround_Y(World, Cx, Cz, Height, Window)
  Xi = Cx * 16; Xe = Xi + 15
  Zi = Cz * 16; Ze = Zi + 15
  Yi = Height - Window
  Ye = Height + Window
  if Yi < 0 then
     Ye = Ye + -Yi
     Yi = 0
  end
  
  for i=1,LOOKS_PER_SWEEP do
    -- Pick a block in the correct range.
    block = Vector3i(math.random(Xi, Xe),
                     math.random(Yi, Ye),
                     math.random(Zi, Ze))
    btype = World:GetBlock(block)

    if BlockTagIsMushroom(btype) then
      adj = block + Vector3i(math.random(-1, 1), 0, math.random(-1, 1))
      if BlockCanHostFungus(World, adj) and Probability() then
        LOG("Grew mushroom")
        World:SetBlock(adj.x, adj.y, adj.z, btype, 0)
      end
    end
  end
end

function Probability()
  return BASEPROBABILITY * (LOGGED <= 1 and 1 or 1/(0.5*LOGGED))
end

function BlockTagIsMushroom(BType)
  return BType == E_BLOCK_BROWN_MUSHROOM or BType == E_BLOCK_RED_MUSHROOM
end

function BlockCanHostFungus(World, Block)
  return World:GetBlockBlockLight(Block) <= 12 
     and World:GetBlockSkyLight  (Block) == 0
     and cBlockInfo:IsSolid(World:GetBlock(Block + Vector3i(0, -1, 0)))
     and World:GetBlock(Block) == E_BLOCK_AIR
end
