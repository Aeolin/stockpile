require("Graphics.lua")

Window = {
    body = nil,
    header = nil,
    gBody = nil,
    gHeader = nil,
    title = ""
}

function Window:new(parent, x, y, width, height, title)
    if height < 3 then
        return nil
    end

    local header = window.create(parent, x, y, width, 2);
    local body = window.create(parent, x, y + 2, width, height - 2)

    local gHeader = Graphics:new(header)
    local gBody = Graphics:new(body)

    local self = {
        body = body,
        header = header,
        gBody = gBody,
        gHeader = gHeader,
        title = title or ""
    }
    setmetatable(self, {
        __index = Window
    })
    self:render()
    return self
end

function Window:redraw()
    local g = self.gHeader;
    g:fillBox(1, 1, g:getWidth(), 1, "0");
    g:write(1, 1, self.title, "f", "0")
    g:write(1, 2, string.rep("-", g:getWidth()))
    self.header.redraw()
    self.body.redraw()
end

function Window:reposition(x, y, width, height)
    if height < 3 then
        return false
    end

    self.header.reposition(x, y, width, 2)
    self.body.reposition(x, y + 2, width, height - 2)
    self.gBody:updateSize()
    self.gHeader:updateSize()
    self:redraw()
    return true
end

function Window:getPosition()
    return self.header.getPosition()
end

function Window:getGraphics()
    return self.gBody
end
