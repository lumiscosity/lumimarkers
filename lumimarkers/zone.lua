local tex = textures:read("b", "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAMAAAAoyzS7AAAAAXNSR0IArs4c6QAAAAZQTFRFAAAA////pdmf3QAAAApJREFUCJljYAQAAAMAAvcrHT0AAAAASUVORK5CYII=")
local ins = table.insert

local shaderListener = not client.hasShaderPack()

local tanchor = models:newPart("lm_tanchor", "World")
local aanchor = models.lumimarkers.zanchor.World

animations["lumimarkers.zanchor"].a:play()

models.lumimarkers.ztarget:setVisible(false):setOpacity(0.1):setPrimaryRenderType("emissive"):setLight(15, 15)

local taskIDOffset = 0

---A zone highlighted on the ground.
---@class Zone
local Zone = {
    -- The position of this zone in the PageHolder.
    id = nil,
    -- Anchor models used to position the zone.
    anchor = nil,
    aanchor = nil,
    -- The width of the zone in the X and Z coordinates.
    xw = nil,
    zw = nil,
    -- The color of the zone.
    color = nil,
    -- Whether the cone is circular or not.
    round = nil,
    -- Whetver the zone targets players.
    targetPlayers = nil,
    -- Whetver the zone targets markers.
    targetMarkers = nil,
    -- Internal holders for the SpriteTasks that make up a zone.
    a = nil,
    b = nil,
    -- Set to true when the zone is due to be removed
    removed = nil
}

function Zone.renderType()
    if shaderListener then
        return "translucent"
    else
        return "emissive"
    end
end

function Zone.animRenderType()
    if shaderListener then
        return "blurry"
    else
        return "emissive"
    end
end

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
        -- the second raycast is done nearer to the center
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
    taskIDOffset = (taskIDOffset + mult + 16) % 65536
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

--table.insert(zones, Zone:new(vec(0, 0, 0), 16, 16, vec(1.0, 0.5, 0.1, 0.35), true, true))

local targets = {}

local Target = {
    -- true for player, false for marker
    kind = nil,
    -- uuid of player/marker
    target = nil,
    lastpos = nil,
    model = nil
}

function Target:new(pos, kind, target)
    local n = setmetatable({}, self)
    self.__index = self
    n.kind = kind
    n.target = target
    n.lastpos = pos
    n.model = models.lumimarkers.ztarget:copy("lm_ztarget"):setPos(pos):setVisible(true):moveTo(tanchor)
    n.lifetime = 0.1
    return n
end

local function smoothMove(id, part, opos, npos)
    local curtime = 0

    events.tick:remove(id)
    events.world_render:remove(id)

    events.tick:register(function()
        if curtime == 1 then
            if part then
                part:setPos(npos)
            end
            events.tick:remove(id)
            events.world_render:remove(id)
        end
        curtime = curtime + 1
    end, id)

    local lerp = math.lerp

    events.world_render:register(function(delta)
        part:setPos(lerp(opos, npos, delta))
    end, id)
end

local function ncontains(t, val)
    for k, v in pairs(t) do
        if v == val then
            return false
        end
    end

    return true
end

local spinAnimTimer = 0

events.tick:register(
    function()
        spinAnimTimer = (spinAnimTimer + 0.3) % 360
        zoneAnimTimer = math.max(zoneAnimTimer - 0.008, 0)
        if not host:isHost() then
            return
        end
        -- find targetted players/markers
        local ft = {}
        local min = math.min
        for _, i in pairs(ph.zones) do
            if i.targetPlayers then
                local f = i:getTargetPlayers()
                for _, pl in pairs(f) do
                    local u = pl:getUUID()
                    local t = targets[u]
                    if t then
                        local up = pl:getPos()*16
                        t.lifetime = min(t.lifetime + 0.1, 1)
                        if t.lastpos ~= up then
                            smoothMove("lm_zt_"..u, t.model, t.lastpos, up)
                        end
                        t.lastpos = up
                    else
                        targets[u] = Target:new(pl:getPos()*16, true, u)
                    end
                    ins(ft, u)
                end
            end
            --if i.targetMarkers then
            --    ...
            --end
        end
        -- clean up unused target markers
        for k, v in pairs(targets) do
            if ncontains(ft, k) then
                if v.lifetime > 0.1 then
                    local ent = world.getEntity(k)
                    -- this can happen when exiting freecam
                    if not ent then
                        return
                    end
                    local up = ent:getPos()*16
                    v.lifetime = v.lifetime - 0.1
                    smoothMove("lm_zt_"..k, v.model, v.lastpos, up)
                    v.lastpos = up
                else
                    v.model:setVisible(false)
                    v.model:remove()
                    targets[k] = nil
                end
            end
        end
    end
, "lm_ztick")

events.render:register(
    function(delta)
        local r = Zone.renderType()
        local ar = Zone.animRenderType()
        for _, i in pairs(ph.zones) do
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
        for _, i in pairs(targets) do
            i.model:setOpacity(i.lifetime)
            i.model:setRot(0, spinAnimTimer + delta*0.3, 0)
        end
    end
, "lm_zrender")
