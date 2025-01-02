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

---A class describing a marker.
---@class Marker
---@field publicProperty1 ModelPart
---@field publicProperty2 Page
local Marker = {
    -- The position of this marker in the PageHolder.
    id = nil,
    -- The marker model.
    marker = nil,
    -- The action used to represent this marker. The title of this action is the marker's name.
    action = nil,
    -- The configuration page for this marker.
    page = nil,
    -- The TextTask used to display this marker's name.
    text = nil,
    -- A ModelPart with the Billboard parent type which holds the text.
    text_anchor = nil,
    -- The EntityTask used to disguise this marker as an entity. If entity mode is disabled, this is nil.
    entity = nil,
    -- The ModelPart used to disguise this marker as a model. If model mode is disabled, this is nil.
    model = nil,
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
    local newObject = setmetatable({}, self)
    self.__index = self
    newObject.marker = marker_base:copy("MarkerModel")
        :moveTo(anchor)
        :setPos(pos)
        :setVisible(true)
    newObject.static_anchor = models:newPart("EntityAnchor", "World"):setPos(pos):setLight(15)
    newObject.page = action_wheel:newPage("HolderPage")

    newObject.text_anchor = models:newPart("TextAnchor", "BILLBOARD"):setPivot(0, 34, 0):moveTo(newObject.marker)
    newObject.text = newObject.text_anchor:newText("MarkerText"):setText("Marker"):setAlignment("CENTER"):setScale(0.5, 0.5, 0.5)--:setBackground(true) Uncomment this when the Iris texture atlas corruption bug is fixed!
    newObject.removed = false
    if not syncing then
        newObject.action = ph.page:newAction()
            :title("Marker")
            :item("snowball")
            :onLeftClick(function() action_wheel:setPage(newObject.page) end)
        newObject:genMarkerPages()
    end
    return newObject
end

local function getTexture(name)
    for _, v in pairs(textures:getTextures()) do
        if v.name == name then
            return v
        end
    end
end

function lm_setName(name, id)
    ph.markers[id].text:setText(name)
end

function pings.lm_setName(name, id)
    if ph.markers[id] then
        lm_setName(name, id)
    end
end

function lm_setSpecialColor(c, id)
    local m = ph.markers[id]
    m.marker:setColor()
    m.marker:setPrimaryTexture("Custom", getTexture("lumimarkers.marker."..c))
    m.spc = c
    m.c = nil
end

function pings.lm_setSpecialColor(c, id)
    if ph.markers[id] then
        lm_setSpecialColor(c, id)
    end
end

function lm_setColor(c, id)
    local m = ph.markers[id]
    m.marker:setColor(vectors.hexToRGB(c))
    m.marker:setPrimaryTexture("Custom", getTexture("lumimarkers.marker.marker_white"))
    m.spc = nil
    m.c = c
end

function pings.lm_setColor(c, id)
    if ph.markers[id] then
        lm_setColor(c, id)
    end
end

function lm_setModelColor(c, id)
    local m = ph.markers[id]
    m.model:setColor(vectors.hexToRGB(c))
    m.spc = nil
    m.c = c
end

function pings.lm_setModelColor(c, id)
    if ph.markers[id] then
        lm_setModelColor(c, id)
    end
end

function pings.lm_delete(id)
    local m = ph.markers[id]
    if m then
        m.removed = true
        m.static_anchor:setVisible(false)
        m.marker:setVisible(false)
        m.marker:moveTo(models)
        ph:remove()
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

function lm_setScale(scale, id)
    local m = ph.markers[id]
    m.marker:setScale(scale, scale, scale)
    m.static_anchor:setScale(scale, scale, scale)
end

function pings.lm_setScale(scale, id)
    if ph.markers[id] then
        lm_setScale(scale, id)
    end
end

function lm_setTextHeight(height, id)
    ph.markers[id].text_anchor:setPivot(0, height, 0)
end

function pings.lm_setTextHeight(height, id)
    if ph.markers[id] then
        lm_setTextHeight(height, id)
    end
end

function lm_setRot(rot, id)
    local m = ph.markers[id]
    m.marker:setRot(0, rot, 0)
    m.static_anchor:setRot(0, rot, 0)
end

function pings.lm_setRot(rot, id)
    if ph.markers[id] then
        lm_setRot(rot, id)
    end
end

function lm_setLight(light, id)
    local m = ph.markers[id]
    m.marker:setLight(light)
    m.static_anchor:setLight(light)
end

function pings.lm_setLight(light, id)
    if ph.markers[id] then
        lm_setLight(light, id)
    end
end

function lm_disguise(x, id, dis_type, silent)
    local m = ph.markers[id]
    local success = nil
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
        success = pcall(function()
            m.model = models.lumimarkers.custom[x]:copy("MarkerDisguise")
                :moveTo(m.static_anchor)
                :setVisible(true)
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
    m.entity:setVisible(true)
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
    if ph.markers[id] then
        lm_disguise(x, id, dis_type)
    end
end

function pings.lm_reconstruct(name, c, spc, pos, scale, height, rot, light, dis_type, dis_cont, id)
    if not ph.markers[id] then
        marker = Marker:new(pos, true)
        ph.sync(marker, id)
    end

    if spc then
        lm_setSpecialColor(spc, id)
    elseif c then
        if disguise_type == 2 then
            lm_setModelColor(c, id)
        else
            lm_setColor(c, id)
        end
    end
    lm_setName(name, id)
    lm_setScale(scale, id)
    lm_setTextHeight(height, id)
    lm_setRot(rot, id)
    lm_setLight(light, id)
    lm_disguise(dis_cont, id, dis_type, 1)
end

function Marker:genMarkerPages()
    self.page:newAction()
        :title("Back")
        :item("amethyst_cluster")
        :onLeftClick(function()
            action_wheel:setPage(ph.page)
            if chat_consumer then
                host:setActionbar("Cancelled")
                chat_consumer = nil
            end
        end)
    self.page:newAction()
        :title("Rename")
        :item("name_tag")
        :onLeftClick(function()
            chat_consumer = function(x)
                self.action:title(x)
                pings.lm_setName(x, self.id)
                host:setActionbar("Set marker name to " .. x)
            end
            host:setActionbar("Type the new name in chat, or 'stop' to cancel:")
        end)
    self.page:newAction()
        :title("Change icon")
        :item("item_frame")
        :onLeftClick(function()
            chat_consumer = function(x)
                if not pcall(world.newItem, x) then
                    host:setActionbar("Invalid item!")
                    return
                end
                self.action:item(x)
                host:setActionbar("Set icon to " .. x)
            end
            host:setActionbar("Type the item ID for the new icon in chat, or 'stop' to cancel:")
        end)
    self.page:newAction()
        :title("Set color")
        :item("white_dye")
        :onLeftClick(function()
            if self.entity ~= nil then
                host:setActionbar("Entity disguise cannot be dyed!")
                chat_consumer = nil
                return
            end
            chat_consumer = function(x)
                -- TODO: figure out and handwrite a better blending algorithm so we can move 100% to pure setcolor
                if not vectors.hexToRGB(x) then
                    host:setActionbar("Invalid color!")
                    return
                end
                if self.model == nil then
                    if x == "marker_blue" then
                        pings.lm_setSpecialColor(x, self.id)
                    elseif x == "marker_teal" then
                        pings.lm_setSpecialColor(x, self.id)
                    elseif x == "marker_red" then
                        pings.lm_setSpecialColor(x, self.id)
                    elseif x == "marker_green" then
                        pings.lm_setSpecialColor(x, self.id)
                    elseif x == "marker_white" then
                        pings.lm_setSpecialColor(x, self.id)
                    else
                        pings.lm_setColor(x, self.id)
                    end
                else
                    pings.lm_setModelColor(x, self.id)
                end
                host:setActionbar("Set marker color to " .. x)
            end
            host:setActionbar("Type the hex code of the color in chat, or 'stop' to cancel:")
        end)
    self.page:newAction()
        :title("Move to cursor")
        :item("ender_pearl")
        :onLeftClick(function()
            local pos = Marker.positionFromRaycast()
            if Marker.positionIsFree(pos) then
                pings.lm_move(pos, self.id)
            end
        end)
    self.page:newAction()
        :title("Move to player")
        :item("lead")
        :onLeftClick(function()
            if player:isLoaded() then
                local pos = Marker.alignedPosition(player:getPos()) * 16
                if Marker.positionIsFree(pos) then
                    pings.lm_move(pos, self.id)
                end
            end
        end)
    self.page:newAction()
        :title("Set scale")
        :item("wheat")
        :onLeftClick(function()
            chat_consumer = function(x)
                local new_scale = tonumber(x)
                if not new_scale then
                    host:setActionbar("Not a number!")
                    return
                end
                pings.lm_setScale(new_scale, self.id)
                host:setActionbar("Set scale to " .. x)
            end
            host:setActionbar("Type the new scale (1 is default), or 'stop' to cancel:")
        end)
    self.page:newAction()
        :title("Delete")
        :item("iron_pickaxe")
        :onLeftClick(function() pings.lm_delete(self.id) end)
    self.page:newAction()
        :title("Disguise as mob")
        :item("ghast_spawn_egg")
        :onLeftClick(function()
            if sneak_key:isPressed() then
                -- NBT mode
                chat_consumer = function(x)
                    pings.lm_disguise(x, self.id, 0)
                end
                host:setActionbar("Type the new mob NBT in chat, 'disable' to disable disguise or 'stop' to cancel:")
            else
                -- Mob ID mode
                chat_consumer = function(x)
                    pings.lm_disguise(x, self.id, 1)
                end
                host:setActionbar("Type the new mob ID in chat, 'disable' to disable disguise or 'stop' to cancel:")
            end
        end)
    self.page:newAction()
        :title("Disguise as model")
        :item("blaze_spawn_egg")
        :onLeftClick(function()
            chat_consumer = function(x)
                pings.lm_disguise(x, self.id, 2)
            end
            host:setActionbar("Type the model name in chat, 'disable' to disable disguise or 'stop' to cancel:")
        end)
    self.page:newAction()
        :title("Set text height")
        :item("wheat")
        :onLeftClick(function()
            chat_consumer = function(x)
                local new_height = tonumber(x)
                if not new_height then
                    host:setActionbar("Not a number!")
                    return
                end
                pings.lm_setTextHeight(new_height, self.id)
                host:setActionbar("Set text height to " .. x)
            end
            host:setActionbar("Type the new text height (34 is default, 16 is one block), or 'stop' to cancel:")
        end)
    self.page:newAction()
        :title("Rotate")
        :item("compass")
        :onLeftClick(function()
            chat_consumer = function(x)
                local new_rot = tonumber(x)
                if not new_rot then
                    host:setActionbar("Not a number!")
                    return
                end
                pings.lm_setRot(new_rot, self.id)
                host:setActionbar("Set rotation to "..x.."°")
            end
            host:setActionbar("Type the new rotation or 'stop' to cancel:")
        end)
    self.page:newAction()
        :title("Set light level")
        :item("daylight_detector")
        :onLeftClick(function()
            chat_consumer = function(x)
                if x == "disable" then
                    pings.lm_setLight(nil, self.id)
                    host:setActionbar("Light override disabled!")
                    return
                end
                local new_light = tonumber(x)
                if not new_light then
                    host:setActionbar("Not a number!")
                    return
                end
                if new_light > 15 or new_light < 0 then
                    host:setActionbar("Out of range! Valid values are 0-15.")
                    return
                end
                pings.lm_setLight(new_light, self.id)
                host:setActionbar("Set light level to " .. x)
            end
            host:setActionbar("Type the new light level (fullbright is 15), 'disable' to disable or 'stop' to cancel:")
        end)
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
