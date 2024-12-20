local PageHolder = require "figuradm/pageholder"
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

    newObject.text = text_anchor:newText("MarkerText"):setText("Marker"):setAlignment("CENTER"):setBackground(true):setScale(0.5, 0.5, 0.5)
    newObject:genMarkerPages()
    return newObject
end

function Marker:setName(name)
    self.action:title(name)
    self.text:setText(name)
end

function Marker:delete()
    self.marker:setVisible(false)
    self.marker:moveTo(models)
    self.mainPage:remove(self)
end

function Marker:genMarkerPages()
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
        :title("Show name")
        :item("name_tag")
    self.page:newAction()
        :title("Set color")
        :item("white_dye")
        :onLeftClick(function() action_wheel:setPage(self.page) end)
    self.page:newAction()
        :title("Delete")
        :item("iron_pickaxe")
        :onLeftClick(function() self:delete() end)
    self.page:newAction()
        :title("Back")
        :item("amethyst_cluster")
        :onLeftClick(function() action_wheel:setPage(self.mainPage.page) end)
end

return Marker
