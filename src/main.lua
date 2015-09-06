local lick = require "lib.lick"
lick.reset = true

local LightWorld, lw = require "lib.light_world"
local lf = require "lib.LoveFrames"

local lg = love.graphics

-- x/y offset, scale
local camera = {0, 0, 1}

-- data used for placing objects
local mode = "rectangle"
local clicks = {}

-- actual data to be saved / where data will be loaded
local world = {}

-- GUI objects in use (besides main)
local frames = {}

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

    --NOTE TEMPORARY LIGHT FOR TESTING
    lw:newLight(lg.getWidth()/2, lg.getHeight()/2, 255, 255, 255, 500)

    local frame = lf.Create("frame"):SetName("World Optons"):SetSize(350, 175):ShowCloseButton(false)
    local grid = lf.Create("grid", frame):SetPos(5, 30):SetCellWidth(320/2)
    grid:SetRows(4):SetColumns(2):SetItemAutoSize(true)
    local savefile = lf.Create("textinput"):SetPlaceholderText("File to save or load from.")
    grid:AddItem(savefile, 1, 1)
    local load_button = lf.Create("button", frame):SetText("Load"):SetPos(180, 35)
    local save_button = lf.Create("button", frame):SetText("Save"):SetPos(260, 35)
    local mode_text = lf.Create("text"):SetText("Object to place:")
    grid:AddItem(mode_text, 2, 1)
    local x, y = mode_text:GetPos() --these two lines of code do nothing
    mode_text:SetPos(x, y+5)        --these two lines of code do nothing
    local mode_selector = lf.Create("multichoice"):AddChoice("rectangle"):AddChoice("circle")
    mode_selector:AddChoice("polygon"):AddChoice("light"):SetChoice("rectangle")
    grid:AddItem(mode_selector, 2, 2)

    mode_selector.OnChoiceSelected = function(self, choice)
        --if we aren't done with a setup,
        -- set the choice back to the previous, and pop up an alert
    end

    load_button.OnClick = function()
        -- check that we don't have unsaved changes,
        -- check that the file exists,
        -- wipe everything and load

        --HACK TEMPORARY => wipe out lw, wipe out LF's (except this one!)
        --TODO is there a function to properly remove a LightWorld ?
        lw = LightWorld()
        for _,v in ipairs(frames) do
            v:Remove() --not sure if recursive enough? xD
        end
    end

    save_button.OnClick = function()
        -- check that we aren't overwriting (unless we loaded from there!)
        -- save tables!
    end
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

            lg.setColor(255, 255, 255, 255)
            lg.rectangle("fill", 0, 0, lg.getWidth(), lg.getHeight())

            for _,v in ipairs(world) do
                if v.color then
                    lg.setColor(v.color[1], v.color[2], v.color[3], v.color[4])
                end

                -- NOTE THESE DO NOT PROPERLY RESPECT CAMERA SETTINGS
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

    --draw current clicks
    if #clicks > 0 then
        if mode == "rectangle" then
            if clicks[1].button == "l" then
                local x, y = clicks[1].x, clicks[1].y
                local X, Y = love.mouse.getPosition()
                local w, h = X - x, Y - y
                if w < 0 then
                    X, x = x, X
                    w = -w
                end
                if h < 0 then
                    Y, y = y, Y
                    h = -h
                end
                lg.setColor(255, 255, 255, 255)
                lg.rectangle("line", x, y, w, h)
            end
        elseif mode == "circle" then
            --draw circle center at first click to radius of where mouse is
        elseif mode == "polygon" then
            --draw lines of previous points, plus line to mouse
            -- (also a note, right click to close)
        end
    end

    lf.draw()
end

function love.mousepressed(x, y, button)
    lf.mousepressed(x, y, button)

    if lf.util.GetHoverObject() == false then
        table.insert(clicks, {x=x, y=y, button=button})

        -- NOTE THESE DO NOT RESPECT CAMERA
        if mode == "rectangle" then
            -- cancel on right-click
            for _,v in ipairs(clicks) do
                if v.button == "r" then
                    clicks = {}
                    return --NOTE warning, may be a shitty place to return...
                end
            end

            if #clicks == 2 then

                -- create our reference table
                local rectangle = {
                    type = "rectangle",
                    args = {clicks[1].x + (clicks[2].x - clicks[1].x)/2, clicks[1].y + (clicks[2].y - clicks[1].y)/2, math.abs(clicks[2].x - clicks[1].x), math.abs(clicks[2].y - clicks[1].y)},
                    color = {255, 255, 255, 255}
                }

                -- check for valid width / height
                if rectangle.args[3] < 1 then
                    rectangle.args[3] = 1
                end
                if rectangle.args[4] < 1 then
                    rectangle.args[4] = 1
                end

                -- create the LightWorld rectangle
                lw:newRectangle(unpack(rectangle.args))

                -- create the LF interface
                local frame = lf.Create("frame"):SetName("rectangle"):SetSize(350, 175)
                local grid = lf.Create("grid", frame):SetPos(5, 30):SetCellWidth(320/2)
                grid:SetRows(4):SetColumns(2):SetItemAutoSize(true)
                local x_text = lf.Create("text"):SetText("X (center)")
                local y_text = lf.Create("text"):SetText("Y (center)")
                grid:AddItem(x_text, 1, 1):AddItem(y_text, 2, 1)
                local x_input = lf.Create("textinput"):SetPlaceholderText("0"):SetText(rectangle.args[1])
                local y_input = lf.Create("textinput"):SetPlaceholderText("0"):SetText(rectangle.args[2])
                grid:AddItem(x_input, 1, 2):AddItem(y_input, 2, 2)
                local w_text = lf.Create("text"):SetText("Width")
                local h_text = lf.Create("text"):SetText("Height")
                grid:AddItem(w_text, 3, 1):AddItem(h_text, 4, 1)
                local w_input = lf.Create("textinput"):SetPlaceholderText("10"):SetText(rectangle.args[3])
                local h_input = lf.Create("textinput"):SetPlaceholderText("10"):SetText(rectangle.args[4])
                grid:AddItem(w_input, 3, 2):AddItem(h_input, 4, 2)

                --TODO ADD HANDLING CODE FOR CHANGES

                -- remove the clicks
                clicks = {}

                -- add the table to our world
                table.insert(world, rectangle)
            end
        elseif mode == "circle" then
            -- if 2nd click, clear clicks, insert new circle (don't forget gui)
        elseif mode == "polygon" then
            -- if RIGHT click, clear clicks, make polygon, don't forget gui
        elseif mode == "light" then
            -- just make a light NOW, clear clicks, gui
        end
    end
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
