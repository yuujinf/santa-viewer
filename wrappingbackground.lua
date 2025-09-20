local WrappingBackground = {}

function WrappingBackground:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    o:initialize()
    return o
end

function WrappingBackground:initialize()
    self.image = self.image or love.graphics.newImage(self.filename)
    self.canvas = love.graphics.newCanvas(self.image:getDimensions())

    self.image:setWrap("repeat", "repeat", "repeat")
    self.canvas:setWrap("repeat", "repeat", "repeat")

    self.dragging = false
    self.mouseOriginX = 0
    self.mouseOriginY = 0
    self.offsetX = 0
    self.offsetY = 0
    self.curOffsetX = 0
    self.curOffsetY = 0

    self.scaleLevel = 0
    self.scaleFactor = 1

    self.arrowSrc = nil
    self.arrowDst = nil
    self.arrowCur = nil

    self.shader = love.graphics.newShader([[
        /* for some arcane reason this epsilon is necessary */
        const float EPSILON = 0.001;

        uniform float tint;

        uniform Image wrapIm;
        uniform vec2 canvasDims;
        uniform vec2 offset;
        uniform vec2 currentOffset;
        uniform float zoom;

        vec3 hsv2rgb(vec3 c)
        {
            vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
            vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
            return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
        }

        vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
        {
            screen_coords += EPSILON;
            vec2 uv = (((screen_coords - offset -currentOffset)/zoom - love_ScreenSize.xy/2)/canvasDims);
            uv = uv-0.5;
            vec4 texturecolor = Texel(wrapIm, uv);
            vec4 rb = vec4(hsv2rgb(vec3(ceil(20*(uv.x+uv.y-0.15))/20,1,1)),1.0);
            return mix(texturecolor, rb, 0) * color * vec4(tint,tint,tint,1.0);
        }
    ]])
    self.shader:send("wrapIm", self.canvas)
    self.shader:send("canvasDims", { self.canvas:getDimensions() })
    self.shader:send("offset", { 0, 0 })
    self.shader:send("currentOffset", { 0, 0 })
    self.shader:send("zoom", 1)
    self.shader:send("tint", 0.5)
end

function WrappingBackground:screenToCanvasCoords(sx, sy)
    local px, py =
        math.fmod(
            sx / self.scaleFactor - self.offsetX - self.curOffsetX - self.canvas:getWidth() / 2 -
            love.graphics.getWidth() / 2,
            self.canvas:getWidth()),
        math.fmod(
            sy / self.scaleFactor - self.offsetY - self.curOffsetY - self.canvas:getHeight() / 2 -
            love.graphics.getHeight() / 2,
            self.canvas:getHeight())
    if px < 0 then px = px + self.canvas:getWidth() end
    if py < 0 then py = py + self.canvas:getHeight() end

    return px, py
end

function WrappingBackground:mousemoved(x, y, dx, dy, istouch)
    -- state.scene:mousemoved(x, y, dx, dy, istouch)
    if self.dragging and love.mouse.isDown(1) then
        self.curOffsetX, self.curOffsetY = x - self.mouseOriginX, y - self.mouseOriginY
    end

    if self.arrowSrc then
        local px, py = self:screenToCanvasCoords(love.mouse.getPosition())

        local bestDist, bestX, bestY
        for ddx = -1, 2 do
            for ddy = -1, 2 do
                local cx, cy = px + ddx * self.canvas:getWidth(), py + ddy * self.canvas:getHeight()
                local dist = math.sqrt((cx - self.arrowSrc[1]) ^ 2 + (cy - self.arrowSrc[2]) ^ 2)
                if not bestDist or dist < bestDist then
                    bestDist, bestX, bestY = dist, cx, cy
                end
            end
        end
        assert(bestX and bestY)
        self.arrowCur = { bestX, bestY }
    end
end

function WrappingBackground:mousepressed(x, y, button, istouch, presses)
    -- self.scene:mousepressed(x, y, button, istouch, presses)
    if button == 1 then
        if love.keyboard.isDown("lshift") then
            local px, py = self:screenToCanvasCoords(love.mouse.getPosition())
            self.arrowSrc = { px, py }
            self.arrowCur = { px, py }
        else
            self.dragging = true
            self.mouseOriginX = x
            self.mouseOriginY = y
            self.curOffsetX = 0
            self.curOffsetY = 0
        end
    end
end

function WrappingBackground:mousereleased(x, y, button, istouch, presses)
    -- self.scene:mousereleased(x, y, button, istouch, presses)
    if button == 1 then
        self.dragging = false
        self.offsetX = self.offsetX + self.curOffsetX
        self.offsetY = self.offsetY + self.curOffsetY
        self.curOffsetX = 0
        self.curOffsetY = 0
    end
end

function WrappingBackground:keypressed(key, scancode, isrepeat)
    -- self.scene:keypressed(key, scancode, isrepeat)
end

function WrappingBackground:wheelmoved(dx, dy)
    if dy < 0 then
        self.scaleLevel = self.scaleLevel - 1
    elseif dy > 0 then
        self.scaleLevel = self.scaleLevel + 1
    end
    self.scaleFactor = 2 ^ self.scaleLevel
    self.shader:send("zoom", self.scaleFactor)
end

function WrappingBackground:update(dt)
    -- self.scene:update(dt)
end

function WrappingBackground:draw()
    love.graphics.setCanvas(self.canvas)
    love.graphics.clear()
    love.graphics.setColor(1, 1, 1)
    love.graphics.setLineWidth(1)
    love.graphics.draw(self.image, 0, 0)
    love.graphics.rectangle("line", 0, 0, self.canvas:getDimensions())
    if self.arrowSrc then
        for dx = -1, 1 do
            for dy = -1, 1 do
                love.graphics.push()
                love.graphics.translate(dx * self.canvas:getWidth(), dy * self.canvas:getHeight())
                love.graphics.circle("fill", self.arrowSrc[1], self.arrowSrc[2], 5)
                if self.arrowCur then
                    love.graphics.circle("fill", self.arrowCur[1], self.arrowCur[2], 5)
                    local ddx, ddy = self.arrowCur[1] - self.arrowSrc[1], self.arrowCur[2] - self.arrowSrc[2]
                    love.graphics.line(
                        self.arrowSrc[1], self.arrowSrc[2],
                        self.arrowSrc[1] + ddx, self.arrowSrc[2] + ddy
                    )
                end
                love.graphics.pop()
            end
        end
    end
    love.graphics.setCanvas()
    self.shader:send("offset", { self.offsetX, self.offsetY })
    self.shader:send("currentOffset", { self.curOffsetX, self.curOffsetY })
    love.graphics.setShader(self.shader)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getDimensions())
    love.graphics.setShader()

    love.graphics.push()
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", 0, 0, 200, 50)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(string.format("offset %d %d", self.offsetX, self.offsetY))
    love.graphics.translate(0, 20)

    local px, py = self:screenToCanvasCoords(love.mouse.getPosition())
    love.graphics.print(string.format("mouse %d %d", px, py))
    love.graphics.pop()
end

return WrappingBackground
