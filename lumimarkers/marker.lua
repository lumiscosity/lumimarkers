local ph = require "lumimarkers/pageholder"
local anchor = models.lumimarkers.anchor.World
animations["lumimarkers.anchor"].idle:play():setSpeed(0.3)
local marker_base = models.lumimarkers.marker.Marker:setLight(15, 15):setVisible(false)
local sneak_key = keybinds:newKeybind("Sneak", keybinds:getVanillaKey("key.sneak"), true)
local chat_consumer = nil

if models.lumimarkers.custom then
    for _, v in pairs(models.lumimarkers.custom:getChildren()) do
        v:setVisible(false)
    end
end

---A placeable, customizable marker.
---@class Marker
local Marker = {
    -- The position of this marker in the PageHolder.
    id = nil,
    -- The marker model.
    marker = nil,
    -- The action used to represent this marker. The title of this action is the marker's name.
    -- action = nil,
    -- The configuration page for this marker.
    -- page = nil,
    -- The TextTask used to display this marker's name.
    text = nil,
    -- A ModelPart with the Billboard parent type which holds the text.
    text_anchor = nil,
    -- The EntityTask used to disguise this marker as an entity. If entity mode is disabled, this is nil.
    entity = nil,
    -- The ModelPart used to disguise this marker as a model. If model mode is disabled, this is nil.
    model = nil,
    -- A name used to differentiate this part from others.
    model_name = nil,
    -- A ModelPart placed at the raw position of a marker, used to anchor the entity.
    static_anchor = nil,
    -- Color, nil if none.
    c = nil,
    -- Special marker color, nil if none.
    spc = nil,
    -- Disguise type.
    dis_type = nil,
    -- Disguise contents.
    dis_cont = nil,
    -- Set to true when the marker is due to be removed
    removed = nil
}

---Spawns a new Marker.
---@param pos Vector3
---@return Marker
function Marker:new(pos, syncing)
    local n = setmetatable({}, self)
    self.__index = self
    n.marker = marker_base:copy("MarkerModel")
        :moveTo(anchor)
        :setPos(pos)
        :setVisible(true)
    n.static_anchor = models:newPart("EntityAnchor", "World"):setPos(pos):setLight(15)
    n.page = action_wheel:newPage("HolderPage")

    n.text_anchor = models:newPart("TextAnchor", "BILLBOARD"):setPivot(0, 34, 0):moveTo(n.marker)
    n.text = n.text_anchor:newText("MarkerText"):setText("Marker"):setAlignment("CENTER"):setScale(0.5, 0.5, 0.5):setBackground(true)
    n.removed = false
    return n
end

local function getTexture(name)
    local n = ""
    if (client:compareVersions(client.getFiguraVersion(), "0.1.5") == -1) then
        n = "lumimarkers.marker."..name
    else
        n = "lumimarkers."..name
    end
    for _, v in pairs(textures:getTextures()) do
        if v.name == n then
            return v
        end
    end
end

function Marker:setName(name)
    self.text:setText(name)
end

function pings.lm_setName(name, id)
    pcall(Marker.setName, ph.markers[id], name)
end

function Marker:setSpecialColor(c)
    self.marker:setColor()
    self.marker:setPrimaryTexture("Custom", getTexture(c))
    self.spc = c
    self.c = nil
end

function pings.lm_setSpecialColor(c, id)
    pcall(Marker.setSpecialColor, ph.markers[id], c)
end

function Marker:setColor(c)
    self.marker:setColor(vectors.hexToRGB(c))
    self.marker:setPrimaryTexture("Custom", getTexture("marker_white"))
    self.spc = nil
    self.c = c
end

function pings.lm_setColor(c, id)
    pcall(Marker.setColor, ph.markers[id], c)
end

function Marker:setModelColor(c)
    self.model:setColor(vectors.hexToRGB(c))
    self.spc = nil
    self.c = c
end

function pings.lm_setModelColor(c, id)
    pcall(Marker.setModelColor, ph.markers[id], c)
end

function Marker:setScale(scale)
    self.marker:setScale(scale, scale, scale)
    self.static_anchor:setScale(scale, scale, scale)
end

function pings.lm_setScale(scale, id)
    pcall(Marker.setScale, ph.markers[id], scale)
end

function Marker:setTextHeight(height)
    self.text_anchor:setPivot(0, height, 0)
end

function pings.lm_setTextHeight(height, id)
    pcall(Marker.setTextHeight, ph.markers[id], height)
end

function Marker:setRot(rot)
    self.marker:setRot(0, rot, 0)
    self.static_anchor:setRot(0, rot, 0)
end

function pings.lm_setRot(rot, id)
    pcall(Marker.setRot, ph.markers[id], rot)
end

function Marker:setLight(light)
    self.marker:setLight(light)
    self.static_anchor:setLight(light)
end

function pings.lm_setLight(light, id)
    pcall(Marker.setLight, ph.markers[id], light)
end

function Marker:disguise(x, dis_type, silent)
    local m = self
    local success = nil
    if not dis_type then return end
    if dis_type == 0 then
        success = pcall(function()
            m.entity = m.static_anchor
                :newEntity("MarkerMob")
                :setNbt(x)
        end)
    elseif dis_type == 1 then
        success = pcall(function()
            m.entity = m.static_anchor
                :newEntity("MarkerMob")
                :setNbt('{id:"'..x..'"}')
        end)
    else
        if m.model and (x == m.model_name) then return end
        success = pcall(function()
            if m.model then
                m.static_anchor.MarkerDisguise:setVisible(false)
                m.model:setVisible(false)
                m.model = nil
            end
            m.model = models.lumimarkers.custom[x]:copy("MarkerDisguise")
                :moveTo(m.static_anchor)
                :setVisible(true)
            m.model_name = x
        end)
    end
    if not silent then
        if x == "disable" then
            host:setActionbar("Disguise disabled")
        elseif not success then
            local msg = nil
            if dis_type == 0 then
                msg = "Invalid NBT!"
            elseif dis_type == 1 then
                msg = "Invalid mob!"
            else
                msg = "Invalid model!"
            end
            host:setActionbar(msg)
        end
    end
    if dis_type == 2 then
        if m.entity then
            m.entity:setVisible(false)
            m.entity = nil
        end
    else
        if m.model then
            m.static_anchor.MarkerDisguise:setVisible(false)
            m.model:setVisible(false)
            m.model = nil
        end
    end
    if (not success) or (x == "disable") then
        local m = ph.markers[id]
        m.marker:setVisible(true)
        if m.entity then
            m.entity:setVisible(false)
        end
        if m.model then
            m.model:setVisible(false)
        end
        m.text_anchor:moveTo(m.marker)
        m.entity = nil
        m.model = nil
        m.dis_type = nil
        m.dis_cont = nil
        return
    end
    m.marker:setVisible(false)
    m.text_anchor:moveTo(m.static_anchor)
    m.dis_type = dis_type
    m.dis_cont = x
    if not silent then
        local msg = nil
        if dis_type == 0 then
            msg = "Disguised as mob"
        elseif dis_type == 1 then
            msg = "Disguised as mob "..x
        else
            msg = "Disguised as model "..x
        end
        host:setActionbar(msg)
    end
end

function pings.lm_disguise(x, id, dis_type)
    pcall(Marker.setTextHeight, ph.markers[id], x, dis_type)
end

function pings.lm_delete(id)
    local m = ph.markers[id]
    if m then
        m.removed = true
        m.static_anchor:setVisible(false)
        m.marker:setVisible(false)
        m.marker:moveTo(models)
        ph:gc()
        if chat_consumer then
            host:setActionbar("Cancelled")
            chat_consumer = nil
        end
    end
end

function pings.lm_move(pos, id)
    local m = ph.markers[id]
    if m then
        m.marker:setPos(pos)
        m.static_anchor:setPos(pos)
    end
end

function pings.lm_reconstruct(name, c, spc, pos, scale, height, rot, light, dis_type, dis_cont, id)
    if not ph.markers[id] then
        marker = Marker:new(pos, true)
        ph.syncMarker(marker, id)
    else
        marker = ph.markers[id]
    end

    if spc then
        marker:setSpecialColor(spc)
    elseif c then
        if disguise_type == 2 then
            marker:setModelColor(c)
        else
            marker:setColor(c)
        end
    end
    marker:setName(name)
    marker:setScale(scale)
    marker:setTextHeight(height)
    marker:setRot(rot)
    marker:setLight(light)
    marker:disguise(dis_cont, dis_type, 1)
end

---Checks if the queried position is free of markers. Position is assumed to be aligned.
---@param pos Vector3
---@return boolean
function Marker.positionIsFree(pos)
    for _, v in pairs(ph.markers) do
        if v.marker:getPos() == pos then
            host:setActionbar("There is already a marker at this position!")
            return false
        end
    end
    return true
end

---Performs a raycast to the cursor position and returns the adjusted marker position.
---@return Vector3
function Marker.positionFromRaycast()
    if player:isLoaded() then
        local eyePos = player:getPos() + vec(0, player:getEyeHeight(), 0)
        local block, hitPos, side = raycast:block(eyePos, eyePos + (player:getLookDir() * 20))
        hitPos = Marker.alignedPosition(hitPos)
        if side == "down" then
            hitPos = hitPos - vec(0, 2, 0)
        end
        while world.getBlockState(hitPos):hasCollision() do
            hitPos = hitPos + vec(0, 1, 0)
        end
        return hitPos * 16
    end
end

---Block-aligns a marker position.
---@param pos Vector3
---@return Vector3
function Marker.alignedPosition(pos)
    return vec(math.floor(pos.x) + 0.5, math.floor(pos.y), math.floor(pos.z) + 0.5)
end

function events.chat_send_message(msg)
    if chat_consumer then
        if msg ~= "stop" then
            chat_consumer(msg)
        else
            host:setActionbar("Cancelled")
        end
        chat_consumer = nil
        return nil
    else
        return msg
    end
end

return Marker
