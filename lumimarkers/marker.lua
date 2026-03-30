local anchor = models.lumimarkers.anchor.World
animations["lumimarkers.anchor"].idle:play():setSpeed(0.3)
local marker_base = models.lumimarkers.marker.Marker:setLight(15, 15):setVisible(false)

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
    -- The TextTask used to display this marker's name.
    text = nil,
    -- A ModelPart with the Billboard parent type which holds the text.
    text_anchor = nil,
    -- A ModelPart with the World parent type.
    -- Used over static_anchor to ignore scale/rotation.
    text_static = nil,
    -- The EntityTask used to disguise this marker as an entity. If entity mode is disabled, this is nil.
    entity = nil,
    -- The ModelPart used to disguise this marker as a model. If model mode is disabled, this is nil.
    model = nil,
    -- Used to detect when the model changes.
    model_name = nil,
    -- A ModelPart placed at the raw position of a marker, used to anchor the entity.
    static_anchor = nil,
    -- Color, nil if none.
    c = nil,
    -- Special marker color, nil if none.
    spc = nil,
    -- Disguise type. One of 0 (raw NBT entity), 1 (simple entity) or 2 (model).
    dis_type = nil,
    -- Disguise contents. Exact makeup depends on type.
    dis_cont = nil,
    -- Set to true when the marker is due to be removed
    removed = nil
}

---Spawns a new Marker.
---@param pos Vector3
---@return Marker
function Marker:new(pos)
    local n = setmetatable({}, self)
    self.__index = self
    n.marker = marker_base:copy("MarkerModel")
        :moveTo(anchor)
        :setPos(pos)
        :setVisible(true)
    n.static_anchor = models:newPart("EntityAnchor", "World"):setPos(pos):setLight(15)

    n.text_static = models:newPart("TextStatic", "WORLD"):setPos(pos)
    n.text_anchor = n.text_static:newPart("TextAnchor", "BILLBOARD"):setPivot(0, 34, 0)
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
    self.marker:setScale(scale)
    self.static_anchor:setScale(scale)
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
    self.marker:setRot(rot)
    self.static_anchor:setRot(rot)
end

function pings.lm_setRot(rot, id)
    pcall(Marker.setRot, ph.markers[id], rot)
end

function Marker:setLight(light)
    if light == 255 then
        light = nil
    elseif type(light) == Number then
        light = vec(light, light)
    end
    self.marker:setLight(light)
    self.static_anchor:setLight(light)
    if self.model then
        self.model:setLight(light)
    end
    if self.entity then
        self.entity:setLight(light)
    end
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
                :setLight(m.static_anchor:getLight())
        end)
    elseif dis_type == 1 then
        success = pcall(function()
            m.entity = m.static_anchor
                :newEntity("MarkerMob")
                :setNbt('{id:"'..x..'"}')
                :setLight(m.static_anchor:getLight())
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
                :setLight(m.static_anchor:getLight())
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
        m.marker:setVisible(true)
        if m.entity then
            m.entity:setVisible(false)
        end
        if m.model then
            m.model:setVisible(false)
        end
        m.entity = nil
        m.model = nil
        m.dis_type = nil
        m.dis_cont = nil
        return
    end
    m.marker:setVisible(false)
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
    pcall(Marker.disguise, ph.markers[id], x, dis_type)
end

function pings.lm_delete(id)
    local m = ph.markers[id]
    if m then
        m.removed = true
        m.static_anchor:setVisible(false)
        m.text_static:setVisible(false)
        m.marker:setVisible(false)
        m.marker = nil
        m.static_anchor = nil
        m.text_static = nil
        m.text_anchor = nil
        m.text = nil
        m.model = nil
        ph:gc()
        if lm_chatConsumer then
            host:setActionbar("Cancelled")
            lm_chatConsumer = nil
        end
    end
end

function pings.lm_move(pos, id)
    local m = ph.markers[id]
    if m then
        m.marker:setPos(pos)
        m.static_anchor:setPos(pos)
        m.text_static:setPos(pos)
    end
end

function pings.lm_reconstructMarker(name, c, spc, pos, scale, height, rot, light, dis_type, dis_cont, id)
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

local convhelper = data:createBuffer()

local function writeLen(f, i)
    f:write(bit32.extract(i, 8, 8))
    f:write(bit32.extract(i, 0, 8))
end

local function writeData(f,l)
    writeLen(f,l)
    for i=0,l-1 do
        convhelper:setPosition(i)
        f:write(convhelper:read())
    end
    convhelper:setPosition(0)
    convhelper:clear()
end

local function writeString(f, i)
    local l = convhelper:writeString(i)
    writeData(f,l)
end

local function writeInt(f, i)
    convhelper:writeInt(i)
    writeData(f,4)
end

local function writeDouble(f, i)
    convhelper:writeDouble(i)
    writeData(f,8)
end

local function writeVec3(f, i)
    convhelper:writeDouble(i[1])
    convhelper:writeDouble(i[2])
    convhelper:writeDouble(i[3])
    writeData(f,24)
end

function Marker:saveToLMP(filename)
    if not file:exists("../data") then
        file:mkdir("../data")
    end
    if not file:isDirectory("lumimarkers") then
        file:delete("lumimarkers")
    end
    if not file:exists("lumimarkers") then
        file:mkdir("lumimarkers")
    end
    local path = "lumimarkers/"..filename..".lmp"
    if file:exists(path) then
        file:delete(path)
    end
    local f = file:openWriteStream(path)
    -- LMP header
    f:write(76)
    f:write(77)
    f:write(80)
    if self.text:getText() then
        f:write(0)
        writeString(f, self.text:getText())
    end
    if self.c then
        f:write(1)
        writeString(f, self.c)
    end
    if self.spc then
        f:write(2)
        writeString(f, self.spc)
    end
    f:write(3)
    writeVec3(f, self.static_anchor:getPos())
    if self.static_anchor:getScale() ~= vec(1, 1, 1) then
        f:write(4)
        writeVec3(f, self.static_anchor:getScale())
    end
    if self.text_anchor:getPivot()[2] ~= 34 then
        f:write(5)
        writeDouble(f, self.text_anchor:getPivot()[2])
    end
    if self.static_anchor:getRot() ~= vec(0, 0, 0) then
        f:write(6)
        writeVec3(f, self.static_anchor:getRot())
    end
    if self.static_anchor:getLight() then
        if self.static_anchor:getLight() ~= vec(15, 15) then
            f:write(7)
            writeInt(f, self.static_anchor:getLight()[1])
        end
    else
        f:write(7)
        writeLen(f,1)
        f:write(255)
    end
    if self.dis_type then
        f:write(8)
        writeInt(f, self.dis_type)
    end
    if self.dis_cont then
        f:write(9)
        writeString(f, self.dis_cont)
    end
    f:close()
end

local function streamToBuf(s, b, i)
    b:clear()
    for j=0,i-1 do
        b:write(s:read())
    end
    b:setPosition(0)
end

local function readVec3(b)
    local o = vec(b:readDouble(), 0, 0)
    b:setPosition(8)
    o[2] = b:readDouble()
    b:setPosition(16)
    o[3] = b:readDouble()
    return o
end

---Loads the LMP data into this marker.
---@param String filename
---@param boolean pos (whether to load the position)
---@return String (error code) or nil (success)
function Marker:loadFromLMP(filename, pos)
    local path = "lumimarkers/"..filename..".lmp"
    if not file:exists(path) then
        return "File at "..path.." not found!"
    end
    local cnr = "Could not read file at "..path
    local st = file:openReadStream(path)
    local buf = data:createBuffer()
    -- Header check
    if not pcall(streamToBuf, st, buf, 3) then
        return cnr..": file is corrupted"
    end
    local hc = buf:readString(3)
    if hc ~= "LMP" then
        return cnr..": header mismatch: expected LMP, got "..hc
    end
    local m = Marker:new(self.pos)
    m.marker:setVisible(false)
    m.static_anchor:setVisible(false)
    while st:available() > 0 do
        local id, l = 0
        if not pcall(function()
            id = st:read()
            l = st:read() * 256 + st:read()
        end) then
            return cnr..": dangling chunk "..id
        end
        if not pcall(streamToBuf, st, buf, l) then
            return cnr..": reached EOF while reading chunk "..id
        end
        if id == 0 then
            m:setName(buf:readString(l))
        elseif id == 1 then
            m:setColor(buf:readString(l))
        elseif id == 2 then
            m:setSpecialColor(buf:readString(l))
        elseif id == 3 and pos then
            m:setPos(readVec3(buf))
        elseif id == 4 then
            m:setScale(readVec3(buf))
        elseif id == 5 then
            m:setTextHeight(buf:readDouble())
        elseif id == 6 then
            m:setRot(readVec3(buf))
        elseif id == 7 then
            m:setLight(buf:readInt())
        elseif id == 8 then
            m.dis_type = buf:readInt()
        elseif id == 9 then
            m.dis_cont = buf:readString(l)
        end
    end
    pings.lm_reconstructMarker(
        m.text:getText(),
        m.c,
        m.spc,
        m.marker:getPos(),
        m.marker:getScale(),
        m.text_anchor:getPivot()[2],
        m.marker:getRot(),
        m.marker:getLight(),
        m.dis_type,
        m.dis_cont,
        self.id
    )
    ph.onMarkerPresetLoad(m, self.id)
    m.static_anchor = nil
    m.text_static:setVisible(false)
    m.text_static = nil
    m = nil
    st:close()
    buf:close()
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

return Marker
