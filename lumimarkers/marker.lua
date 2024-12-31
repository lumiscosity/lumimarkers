local ph = require "lumimarkers/pageholder"
local anchor = models.lumimarkers.anchor.World
animations["lumimarkers.anchor"].idle:play():setSpeed(0.3)
local marker_base = models.lumimarkers.marker.Marker:setLight(15, 15):setVisible(false)
local sneak_key = keybinds:newKeybind("Sneak", keybinds:getVanillaKey("key.sneak"), true)
local chat_consumer = nil
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
    -- A ModelPart placed at the raw position of a marker, used to anchor the entity.
    static_anchor = nil,
    -- Set to true when the marker is due to be removed
    removed = nil
}

---Spawns a new Marker.
---@param pos Vector3
---@return Marker
function Marker:new(pos)
    local newObject = setmetatable({}, self)
    self.__index = self
    newObject.marker = marker_base:copy("MarkerModel")
        :moveTo(anchor)
        :setPos(pos)
        :setVisible(true)
    newObject.static_anchor = models:newPart("EntityAnchor", "World"):setPos(pos)
    newObject.page = action_wheel:newPage("HolderPage")
    newObject.action = ph.page:newAction()
        :title("Marker")
        :item("snowball")
        :onLeftClick(function() action_wheel:setPage(newObject.page) end)
    newObject.text_anchor = models:newPart("TextAnchor", "BILLBOARD"):setPivot(0, 34, 0):moveTo(newObject.marker)
    newObject.text = newObject.text_anchor:newText("MarkerText"):setText("Marker"):setAlignment("CENTER"):setScale(0.5, 0.5, 0.5)--:setBackground(true) Uncomment this when the Iris texture atlas corruption bug is fixed!
    newObject.removed = false
    newObject:genMarkerPages()
    return newObject
end

function pings.lm_setName(name, id)
    ph.markers[id].text:setText(name)
end

function pings.lm_setSpecialColor(c, id)
    ph.markers[id].marker:setColor()
    ph.markers[id].marker:setPrimaryTexture("Custom", textures["lumimarkers."..c])
end

function pings.lm_setColor(c)
    ph.markers[id].marker:setColor(vectors.hexToRGB(c))
    ph.markers[id].marker:setPrimaryTexture("Custom", textures["lumimarkers.marker_white"])
end

function pings.lm_delete(id)
    ph.markers[id].removed = true
    ph.markers[id].static_anchor:setVisible(false)
    ph.markers[id].marker:setVisible(false)
    ph.markers[id].marker:moveTo(models)
    ph:remove()
    if chat_consumer then
        host:setActionbar("Cancelled")
        chat_consumer = nil
    end
end

function pings.lm_move(pos, id)
    ph.markers[id].marker:setPos(pos)
    ph.markers[id].static_anchor:setPos(pos)
end

function pings.lm_setScale(scale, id)
    ph.markers[id].marker:setScale(scale, scale, scale)
    ph.markers[id].static_anchor:setScale(scale, scale, scale)
end

function pings.lm_setTextHeight(height, id)
    ph.markers[id].text_anchor:setPivot(0, height, 0)
end

function pings.lm_setRot(rot, id)
    ph.markers[id].marker:setRot(0, rot,0)
    ph.markers[id].static_anchor:setRot(0, rot,0)
end

function pings.lm_disguiseAsNBT(x, id)
    local success = pcall(function()
        ph.markers[id].entity = ph.markers[id].static_anchor:newEntity("MarkerMob")
            :setNbt(x)
    end)
    if x == "disable" then
        host:setActionbar("Mob disguise disabled")
    elseif not success then
        host:setActionbar("Invalid NBT!")
    end
    if (not success) or (x == "disable") then
        ph.markers[id].marker:setVisible(true)
        if ph.markers[id].entity then
            ph.markers[id].entity:setVisible(false)
        end
        ph.markers[id].text_anchor:moveTo(ph.markers[id].marker)
        ph.markers[id].entity = nil
        return
    end
    ph.markers[id].marker:setVisible(false)
    ph.markers[id].entity:setVisible(true)
    ph.markers[id].text_anchor:moveTo(ph.markers[id].static_anchor)
end

function pings.lm_disguiseAsMob(x, id)
    local success = pcall(function()
        ph.markers[id].entity = ph.markers[id].static_anchor:newEntity("MarkerMob")
            :setNbt('{id:"'..x..'"}')
    end)

    if x == "disable" then
        host:setActionbar("Mob disguise disabled")
    elseif not success then
        host:setActionbar("Invalid mob!")
    end
    if (not success) or (x == "disable") then
        ph.markers[id].marker:setVisible(true)
        if ph.markers[id].entity then
            ph.markers[id].entity:setVisible(false)
        end
        ph.markers[id].text_anchor:moveTo(ph.markers[id].marker)
        ph.markers[id].entity = nil
        return
    end
    ph.markers[id].marker:setVisible(false)
    ph.markers[id].entity:setVisible(true)
    ph.markers[id].text_anchor:moveTo(ph.markers[id].static_anchor)
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
                if x ~= "stop" then
                    self.action:title(name)
                    pings.lm_setName(x, self.id)
                    host:setActionbar("Set marker name to " .. x)
                else
                    host:setActionbar("Cancelled")
                end
            end
            host:setActionbar("Type the new name in chat, or 'stop' to cancel:")
        end)
    self.page:newAction()
        :title("Change icon")
        :item("item_frame")
        :onLeftClick(function()
            chat_consumer = function(x)
                if x ~= "stop" then
                    if not pcall(world.newItem, x) then
                        host:setActionbar("Invalid item!")
                        return
                    end
                    self.action:item(x)
                    host:setActionbar("Set icon to " .. x)
                else
                    host:setActionbar("Cancelled")
                end
            end
            host:setActionbar("Type the item ID for the new icon in chat, or 'stop' to cancel:")
        end)
    self.page:newAction()
        :title("Set color")
        :item("white_dye")
        :onLeftClick(function()
            chat_consumer = function(x)
                if x ~= "stop" then
                    -- TODO: figure out and handwrite a better blending algorithm so we can move 100% to pure setcolor
                    if not vectors.hexToRGB(x) then
                        host:setActionbar("Invalid color!")
                        return
                    elseif x == "marker_blue" then
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
                    host:setActionbar("Set marker color to " .. x)
                else
                    host:setActionbar("Cancelled")
                end
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
                if x ~= "stop" then
                    local new_scale = tonumber(x)
                    if not new_scale then
                        host:setActionbar("Not a number!")
                        return
                    end
                    pings.lm_setScale(new_scale, self.id)
                    host:setActionbar("Set scale to " .. x)
                else
                    host:setActionbar("Cancelled")
                end
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
                    if x ~= "stop" then
                        pings.lm_disguiseAsNBT(x, self.id)
                        host:setActionbar("Disguised as mob")
                    else
                        host:setActionbar("Cancelled")
                    end
                end
                host:setActionbar("Type the new mob NBT in chat, 'disable' to disable disguise or 'stop' to cancel:")
            else
                -- Mob ID mode
                chat_consumer = function(x)
                    if x ~= "stop" then
                        pings.lm_disguiseAsMob(x, self.id)
                        host:setActionbar("Disguised as mob " .. x)
                    else
                        host:setActionbar("Cancelled")
                    end
                end
                host:setActionbar("Type the new mob ID in chat, 'disable' to disable disguise or 'stop' to cancel:")
            end
        end)
    self.page:newAction()
        :title("Set text height")
        :item("wheat")
        :onLeftClick(function()
        chat_consumer = function(x)
        if x ~= "stop" then
            local new_height = tonumber(x)
            if not new_height then
                host:setActionbar("Not a number!")
                return
                end
                pings.lm_setTextHeight(new_height, self.id)
                host:setActionbar("Set text height to " .. x)
                else
                    host:setActionbar("Cancelled")
                    end
                    end
                    host:setActionbar("Type the new text height (34 is default, 16 is one block), or 'stop' to cancel:")
                    end)
    self.page:newAction()
        :title("Rotate")
        :item("compass")
        :onLeftClick(function()
            chat_consumer = function(x)
                if x ~= "stop" then
                    local new_rot = tonumber(x)
                    if not new_rot then
                        host:setActionbar("Not a number!")
                        return
                    end
                    pings.lm_setRot(new_rot, self.id)
                    host:setActionbar("Set rotation to " .. x)
                else
                    host:setActionbar("Cancelled")
                end
            end
            host:setActionbar("Type the new rotation or 'stop' to cancel:")
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
        chat_consumer(msg)
        chat_consumer = nil
        return nil
    else
        return msg
    end
end

return Marker
