buttons = {}

GUI_BUTTONS = {}        -- global

function buttons.setButtonVisible(enumvalue)
	-- receives an enum (number) and sets the visibility of that button to true
	for k, button in pairs(GUI_BUTTONS) do
		if button.identifier == enumvalue then
			button.visible = true
			break
		end
	end
end

function buttons.setButtonInvisible(enumvalue)
	-- receives an enum (number) and sets the visibility of that button to false
	for k, button in pairs(GUI_BUTTONS) do
		if button.identifier == enumvalue then
			button.visible = false
			break
		end
	end
end

-- function buttons.buttonClicked(mx, my, button)
--
-- 	if mx >= button.x and mx <= button.x + button.width and
-- 		my >= button.y and my <= button.y + button.height then
-- 			return button.identifier
-- 	else
-- 		return nil
-- 	end
-- end

function buttons.getButtonID(rx, ry)
	-- the button table is a global table
	-- check if mouse click is inside any button
	-- mx, my = mouse click X/Y
	-- returns the identifier of the button (enum) or nil
    local currentscene = cf.CurrentScreenName(SCREEN_STACK)
    for k, button in pairs(GUI_BUTTONS) do
		if button.scene == currentscene and button.visible then
			-- print(rx, ry, button.x, button.y, button.width, button.height)
			if rx >= button.x and rx <= button.x + button.width and
				ry >= button.y and ry <= button.y + button.height then
-- print("buttons.getButtonID " .. button.identifier)
					return button.identifier
			end
		end
	end
	-- loop finished. No result. Return nil
	return nil
end

function buttons.changeButtonLabel(enumvalue, newlabel)
	for k, button in pairs(GUI_BUTTONS) do
		if button.identifier == enumvalue then
			button.label = tostring(newlabel)
			break
		end
	end
end

function buttons.drawButtons()

    -- draw buttons
    local currentscene = cf.CurrentScreenName(SCREEN_STACK)

	for k, button in pairs(GUI_BUTTONS) do
		if button.scene == currentscene and button.visible then
			-- draw the button

            -- draw the bg
            love.graphics.setColor(button.bgcolour)
            love.graphics.rectangle("fill", button.x, button.y, button.width, button.height)			-- drawx/y is the top left corner of the square

            -- draw the outline
            if button.drawOutline then
                love.graphics.setColor(button.outlineColour)
                love.graphics.rectangle("line", button.x, button.y, button.width, button.height)			-- drawx/y is the top left corner of the square
            end

			if button.image ~= nil then
                love.graphics.setColor(1,1,1,1)
				love.graphics.draw(button.image, button.x, button.y, 0, button.imagescalex, button.imagescaley, button.imageoffsetx, button.imageoffsety)
			end

			-- draw the label
			local labelxoffset = button.labelxoffset or 0
            love.graphics.setColor(button.labelcolour)
			-- love.graphics.setFont(FONT[enum.fontDefault])        --! the font should be a setting and not hardcoded here
			love.graphics.print(tostring(button.label), button.x + labelxoffset, button.y + 5)

-- print(button.label)
		end
	end

end

return buttons
