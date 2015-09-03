local lick = require "lib.lick"
lick.reset = true

local LightWorld, lw = require "lib.light_world"
local lf = require "lib.LoveFrames"

local lg = love.graphics

local camera = {0, 0, 1}

local world = {}

--[[
{
    type = "light",
    args = {"x", "y", "red", "green", "blue", "range"} --center x/y
},
{
    type = "rectangle",
    args = {"x", "y", "w", "h"} --center at x/y
    color = {r, g, b, a}
},
{
    type = "circle",
    args = {"x", "y", "r"}
    color = {r, g, b, a}
},
{
    type = "polygon",
    args = {"x1", "y1"} --repeating x's and y's
    color = {r, g, b, a}
},
{
    type = "image",
    args = {"image", "x", "y", "w", "h", "ox", "oy"} --center is based on offsets?
    image
}
--]]
--for now do not support AnimationGrids, refractions, or reflections

function love.load()
    lw = LightWorld()

    lf.Create("frame")
end

function love.update(dt)
    lw:update(dt)
    lw:setTranslation(camera[1], camera[2], camera[3])

    lf.update(dt)
end

function love.draw()
    lg.push()
        lg.translate(camera[1], camera[2])
        lg.scale(camera[3])
        lw:draw(function()
            for _,v in ipairs(world) do
                if v.color then
                    lg.setColor(v.color[1], v.color[2], v.color[3], v.color[4])
                end

                if v.type == "rectangle" then
                    lg.rectangle("fill", v.args[1] - v.args[3]/2, v.args[2] - v.args[4]/2, v.args[3], v.args[4])
                elseif v.type == "circle" then
                    lg.circle("fill", v.args[1], v.args[2], v.args[3])
                elseif v.type == "polygon" then
                    lg.polygon("fill", v.args)
                elseif v.type == "image" then
                    lg.draw(v.image, v.args[2], v.args[3], 0, camera[3], camera[3], v.args[6], v.args[7])
                end
            end
        end)
    lg.pop()

    lf.draw()
end

function love.mousepressed(x, y, button)
    lf.mousepressed(x, y, button)
end

function love.mousereleased(x, y, button)
    lf.mousereleased(x, y, button)
end

function love.keypressed(key, unicode)
    -- temporary quick exit
    if key == "escape" then
        love.event.quit()
    end

    lf.keypressed(key, unicode)
end

function love.keyreleased(key)
    lf.keyreleased(key)
end

function love.textinput(text)
    lf.textinput(text)
end
