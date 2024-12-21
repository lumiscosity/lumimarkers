mainPage = require "lumimarkers/pageholder"
---A class describing a marker.
---@class Marker
---@field publicProperty1 ModelPart
---@field publicProperty2 Page
local Marker = {
    -- The marker model.
    marker = nil,
    -- The action used to represent this marker. The title of this action is the marker's name.
    action = nil,
    -- The configuration page for this marker.
    page = nil,
    -- The TextTask used to display this marker's name.
    text = nil,
    -- The EntityTask used to disguise this marker as an entity.
    entity = nil
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
    newObject.page = action_wheel:newPage("HolderPage")
    newObject.action = mainPage.page:newAction()
        :title("Marker")
        :item("snowball")
        :onLeftClick(function() action_wheel:setPage(newObject.page) end)
    local text_anchor = models:newPart("TextAnchor", "BILLBOARD"):setPivot(0, 36, 0):moveTo(newObject.marker)
    newObject.text = text_anchor:newText("MarkerText"):setText("Marker"):setAlignment("CENTER"):setScale(0.5, 0.5, 0.5)--:setBackground(true) Uncomment this when the Iris texture atlas corruption bug is fixed!
    newObject:genMarkerPages()
    return newObject
end

function Marker:setName(name)
    self.action:title(name)
    self.text:setText(name)
end

function Marker:setSpecialColor(c)
    self.marker:setColor()
    self.marker:setPrimaryTexture("Custom", textures["lumimarkers."..c])
end

function Marker:setColor(c)
    self.marker:setColor(vectors.hexToRGB(c))
    self.marker:setPrimaryTexture("Custom", textures["lumimarkers.marker_white"])
end

function Marker:delete()
    self.marker:setVisible(false)
    self.marker:moveTo(models)
    mainPage:remove(self)
end

function Marker:genMarkerPages()
    self.page:newAction()
        :title("Back")
        :item("amethyst_cluster")
        :onLeftClick(function()
            action_wheel:setPage(mainPage.page)
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
                    self:setName(x)
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
                        self:setSpecialColor(x)
                    elseif x == "marker_teal" then
                        self:setSpecialColor(x)
                    elseif x == "marker_red" then
                        self:setSpecialColor(x)
                    elseif x == "marker_green" then
                        self:setSpecialColor(x)
                    elseif x == "marker_white" then
                        self:setSpecialColor(x)
                    else
                        self:setColor(x)
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
                self.marker:setPos(pos)
            end
        end)
    self.page:newAction()
        :title("Move to player")
        :item("lead")
        :onLeftClick(function()
            if player:isLoaded() then
                local pos = Marker.alignedPosition(player:getPos())
                if Marker.positionIsFree(pos) then
                    self.marker:setPos(pos)
                end
            end
        end)
    self.page:newAction()
        :title("Delete")
        :item("iron_pickaxe")
        :onLeftClick(function() self:delete() end)

end

---Checks if the queried position is free of markers. Position is assumed to be aligned.
---@param pos Vector3
---@return boolean
function Marker.positionIsFree(pos)
    for _, v in pairs(mainPage.markers) do
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
        local eyeEnd = eyePos + (player:getLookDir() * 20)
        local block, hitPos, side = raycast:block(eyePos, eyeEnd)
        hitPos = Marker.alignedPosition(hitPos)
        if side ~= "up" then
            hitPos = hitPos + vec(0, 16, 0)
        end
        return hitPos
    end
end

function Marker.alignedPosition(pos)
    return vec(math.floor(pos.x) + 0.5, math.floor(pos.y), math.floor(pos.z) + 0.5) * 16
end

return Marker
