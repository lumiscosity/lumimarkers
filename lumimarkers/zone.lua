local tex = textures:read("b", "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAMAAAAoyzS7AAAAAXNSR0IArs4c6QAAAAZQTFRFAAAA////pdmf3QAAAApJREFUCJljYAQAAAMAAvcrHT0AAAAASUVORK5CYII=")
local ins = table.insert

local shaderListener = not client.hasShaderPack()

local aanchor = models.zanchor.World
animations.zanchor.a:play()

local taskIDOffset = 0

local Zone = {
    anchor = nil,
    aanchor = nil,
    xw = nil,
    zw = nil,
    color = nil,
    round = nil,
    targetPlayers = nil,
    targetMarkers = nil,
    a = nil,
    b = nil
}

function Zone.renderType()
    if shaderListener then
        return "cutout_emissive_solid"
    else
        return "emissive"
    end
end

function Zone.animRenderType()
    if shaderListener then
        return "translucent"
    else
        return "emissive"
    end
end

--- A horrific and probably poorly optimized mess.
function Zone:spawnZoneVisuals()
    local xw = self.xw
    local zw = self.zw
    local mult = xw*zw-1
    -- starting coordinates of the zone
    local x, y, z = self.anchor:getPos():unpack()
    local xd = x/16
    local yd = y/16
    local zd = z/16
    -- for some reason caching these like this reduces instruction count
    local f = math.floor
    local abs = math.abs
    local round = self.round
    -- magic constants for rounding
    local xc = xd+xw/4-0.25
    local zc = zd+zw/4-0.25
    -- last height; used for meshing
    local lh = nil
    -- current block count * 8 for meshing
    local bc = 0
    -- the previous tile position; used for meshing
    local lhp = nil
    -- find the last valid tile to force a redraw on for round zones
    local lvl = nil
    if round then
        for i=mult-zw/2,mult do
            local xt = i%xw
            local zt = f(i/xw)
            local pos = vec((xt/2)+xd, yd, (zt/2)+zd)
            if ((pos[1]-xc)^2)/(xw/4)^2 + ((pos[3]-zc)^2)/(zw/4)^2 <= 1 then
                lvl = i
            end
        end
        lvl = lvl + 1
    end
    for i=0, mult do
        -- calculate base subtile positions
        -- the second position will be used as an extra check;
        -- this fixes floor detection on non-full blocks
        local xt = i%xw
        local zt = f(i/xw)
        local pos = vec((xt/2)+xd, yd, (zt/2)+zd)
        if round then
            if ((pos[1]-xc)^2)/(xw/4)^2 + ((pos[3]-zc)^2)/(zw/4)^2 > 1 then
                -- fake a height change to force the line draw
                lh = -999999
                -- pass once on the final line to draw it
                if not (i == lvl) then
                    goto continue
                end
            end
        end
        local posb = pos + vec(0.25, 0, 0.25)
        -- adjust positions for raycasting
        -- the first raycast is done on the nearest corner of the block
        -- the second rayca
        local xo = xt%2
        local zo = zt%2
        local xco = pos + vec(xo*0.49, 0, zo*0.49)
        local zco = posb - vec(xo*0.10, 0, zo*0.10)
        local c = vec(0, 5.01, 0)
        local _, h = raycast:block(xco + c, xco - c)
        local _, hb = raycast:block(zco + c, zco - c)
        -- convert back to spritetask worldspace coordinates
        local hp = nil
        if h[2] > hb[2] then
            hp = vec(posb[1]*16+4-x, hb[2]*16+0.05-y, posb[3]*16+4-z)
        else
            hp = vec(pos[1]*16+8-x, h[2]*16+0.05-y, pos[3]*16+8-z)
        end
        -- check if we can't draw a connected mesh
        if lh and xt == 0 then
            -- on new line, force a restart
            ins(self.a, self.anchor:newSprite(taskIDOffset+i):setTexture(tex, bc, 8):setLight(15):setRot(90, 0, 0):setPos(lhp):setColor(self.color))
            ins(self.b, self.aanchor:newSprite(taskIDOffset+i+mult):setTexture(tex, bc, 8):setLight(15):setRot(90, 0, 0):setPos(lhp):setColor(self.color))
            lh = nil
            bc = 0
        elseif bc ~= 0 and lh ~= hp[2] and lh then
            -- on height change, force a restart
            ins(self.a, self.anchor:newSprite(taskIDOffset+i):setTexture(tex, bc, 8):setLight(15):setRot(90, 0, 0):setPos(lhp):setColor(self.color))
            ins(self.b, self.aanchor:newSprite(taskIDOffset+i+mult):setTexture(tex, bc, 8):setLight(15):setRot(90, 0, 0):setPos(lhp):setColor(self.color))
            bc = 0
        end
        lh = hp[2]
        if i == mult then
            -- once we've reached the end, force draw the remaining data
            ins(self.a, self.anchor:newSprite(taskIDOffset+i+3*mult):setTexture(tex, bc+8, 8):setLight(15):setRot(90, 0, 0):setPos(hp):setColor(self.color))
            ins(self.b, self.aanchor:newSprite(taskIDOffset+i+4*mult):setTexture(tex, bc+8, 8):setLight(15):setRot(90, 0, 0):setPos(hp):setColor(self.color))
        end
        bc = bc + 8
        lhp = hp
        ::continue::
    end
    return self
end

function Zone:new(pos, xw, zw, color, round, targetPlayers, targetMarkers)
    local n = setmetatable({}, self)
    self.__index = self
    n.anchor = models:newPart("lm_zanchor", "World"):setPos(pos)
    n.aanchor = aanchor:newPart("lm_zaanchor"):setPos(pos)
    n.xw = xw
    n.zw = zw
    n.color = color
    n.round = round
    n.targetPlayers = targetPlayers
    n.targetMarkers = targetMarkers
    n.a = {}
    n.b = {}
    n:spawnZoneVisuals()
    return n
end

local zoneAnimTimer = 0.2
function lm_animateZone()
    zoneAnimTimer = 0.2
end

function Zone:getTargetPlayers()
    local xw = self.xw
    local zw = self.zw
    local x, y, z = self.anchor:getPos():unpack()
    local xd = x/16
    local zd = z/16
    local xc = xd+xw/4-0.25
    local zc = zd+zw/4-0.25
    local round = self.round
    local ins = table.insert
    local out = {}
    for _, v in pairs(world.getPlayers()) do
        local pos = v:getPos()
        if round then
            if ((pos[1]-xc)^2)/(xw/4)^2 + ((pos[3]-zc)^2)/(zw/4)^2 <= 1 then
                ins(out, v)
            end
        else
            if x <= pos[1] and pos[1] <= x+xw/2 and z <= pos[3] and pos[3] <= z+zw/2 then
                ins(out, v)
            end
        end
    end
    return out
end

local zones = {}

table.insert(zones, Zone:new(vec(192, 0, 0), 16, 16, vec(1.0, 0.5, 0.1, 0.35), true))

function events.render()
    local r = Zone.renderType()
    local ar = Zone.animRenderType()
    for _, i in pairs(zones) do
        if shaderListener ~= client.hasShaderPack() then
            for _, j in pairs(i.a) do
                j:setRenderType(r)
            end
            for _, j in pairs(i.b) do
                j:setRenderType(ar)
            end
            shaderListener = client.hasShaderPack()
        end
        for _, j in pairs(i.b) do
            j:setColor(0.8, 0.8, 0.9, zoneAnimTimer)
        end
    end
end

local targets = {}

function events.tick()
    zoneAnimTimer = math.max(zoneAnimTimer - 0.008, 0)
    if not host:isHost() then
        return
    end
    targets = {}
    for _, i in pairs(zones) do
        if i.targetPlayers then
            ins(targets, i:getTargetPlayers())
        end
        --if i.targetMarkers then
        --    ins(targets, i:getTargetMarkers())
        --end
    end
end
