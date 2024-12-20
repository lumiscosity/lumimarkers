local PageHolder = require "lumimarkers/pageholder"
--- A class describing a marker.
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
    -- The TextRenderer used to display this marker's name.
    text = nil,
    -- A ref to the main page.
    mainPage = nil
}

---@param pos Vector3
---@param action Action
---@param holder PageHolder
---@return Marker
function Marker:new(pos, action, holder)
    local newObject = setmetatable({}, self)
    self.__index = self
    newObject["mainPage"] = holder
    newObject["marker"] = marker_base:copy("MarkerModel")
        :moveTo(anchor)
        :setPos(pos)
        :setVisible(true)
    newObject["page"] = action_wheel:newPage("HolderPage")
    newObject["action"] = newObject.mainPage.page:newAction()
        :title("Marker")
        :item("snowball")
        :onLeftClick(function() action_wheel:setPage(newObject.page) end)
    local text_anchor = models:newPart("TextAnchor"):setPivot(0, 36, 0):setParentType("BILLBOARD"):moveTo(newObject.marker)

    newObject.text = text_anchor:newText("MarkerText"):setText("Marker"):setAlignment("CENTER"):setScale(0.5, 0.5, 0.5)--:setBackground(true) Uncomment this when the Iris texture atlas corruption bug is fixed!
    newObject:genMarkerPages()
    return newObject
end

function Marker:setName(name)
    self.action:title(name)
    self.text:setText(name)
end

function Marker:setActionIcon(id)
    self.action:item(id)
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
    self.mainPage:remove(self)
end

function Marker:genMarkerPages()
    self.page:newAction()
        :title("Back")
        :item("amethyst_cluster")
        :onLeftClick(function() action_wheel:setPage(self.mainPage.page) end)
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
                    self:setActionIcon(x)
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
        :title("Delete")
        :item("iron_pickaxe")
        :onLeftClick(function() self:delete() end)

end

return Marker
