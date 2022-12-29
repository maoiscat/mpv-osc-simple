-- mpv osc element templetes
-- by maoiscat
-- github/maoiscat

require 'extra'
local assdraw = require 'mp.assdraw'

-- # element templates
-- logo
-- shows a logo in the center
local ne = newElement('logo')
ne.init = function(self)
        self.geo.x = player.geo.width / 2
        self.geo.y = player.geo.height / 2
        local ass = assdraw.ass_new()    
        ass:new_event()
        ass:pos(self.geo.x, self.geo.y)
        ass:append('{\\1c&H8E348D&\\3c&H0&\\3a&H60&\\blur1\\bord0.5}')
        ass:draw_start()
        assDrawCirCW(ass, 0, 0, 100)
        ass:draw_stop()

        ass:new_event()
        ass:pos(self.geo.x, self.geo.y)
        ass:append('{\\1c&H632462&\\bord0}')
        ass:draw_start()
        assDrawCirCW(ass, 6, -6, 75)
        ass:draw_stop()

        ass:new_event()
        ass:pos(self.geo.x, self.geo.y)
        ass:append('{\\1c&HFFFFFF&\\bord0}')
        ass:draw_start()
        assDrawCirCW(ass, -4, 4, 50)
        ass:draw_stop()

        ass:new_event()
        ass:pos(self.geo.x, self.geo.y)
        ass:append('{\\1c&H632462&\\bord0&}')
        ass:draw_start()
        ass:move_to(-20, -20)
        ass:line_to(23.3, 5)
        ass:line_to(-20, 35)
        ass:draw_stop()
        
        self.pack[4] = ass.text
    end
ne.responder['resize'] = function(self)
        self:init()
    end

-- msg
-- display a message in the screen
ne = newElement('message')
ne.geo.x = 40
ne.geo.y = 20
ne.geo.an = 7
ne.layer = 1000
ne.visible = false
ne.text = ''
ne.startTime = 0
ne.duration = 0
ne.style.color = {'ffffff', '0', '0', '333333'}
ne.style.border = 1
ne.style.shadow = 1
ne.render = function(self)    
        self.pack[4] = self.text
    end
ne.tick = function(self)
        if not self.visible then return '' end
        if player.now-self.startTime >= self.duration then
            self.visible = false
        end
        return table.concat(self.pack)
    end
ne.display = function(self, text, duration)
        if not duration then duration = 1 end
        self.duration = duration
        -- text too long may be slow
        text = string.sub(text, 0, 2000)
        text = string.gsub(text, '\\', '\\\\')
        self.text = text
        self:render()
        self.startTime = player.now
        self.visible = true
    end

-- box
-- draw a simple box, usually used as backgrounds
ne = newElement('box')
ne.geo.r = 0
ne.render = function(self)
        local ass = assdraw.ass_new()
        ass:new_event()
        ass:draw_start()
        assDrawRoundRectCW(ass, 0, 0, self.geo.w, self.geo.h, self.geo.r)
        ass:draw_stop()
        self.pack[4] = ass.text
    end

-- circle
-- draw a simple circle
ne = newElement('circle')
ne.geo.r = 1        -- radius
ne.render = function(self)
        local ass = assdraw.ass_new()
        local r, d = self.geo.r, 2*self.geo.r
        ass:draw_start()
        ass:round_rect_cw(0, 0, d, d, r)
        ass:draw_stop()
        self.pack[4] = ass.text
    end

-- button
-- display some content, also respond to mouse button
ne = newElement('button')
ne.enabled = true
ne.text = ''
ne.styleNormal = nil
ne.styleActive = nil
ne.styleDisabled = nil
-- responder active area, left top right bottom
ne.hitBox = {x1 = 0, y1 = 0, x2 = 0, y2 = 0}
ne.init = function(self)
        self:setPos()
        self:enable()
        self:render()
        self:setHitBox()
    end
ne.render = function(self)
        self.pack[4] = self.text
    end
ne.enable = function(self)
        self.enabled = true
        self.style = self.styleNormal
        self:setStyle()
    end
ne.disable = function(self)
        self.enabled = false
        self.style = self.styleDisabled
        self:setStyle()
    end
ne.setHitBox = function(self)
        local x1, y1, x2, y2 = getBoxPos(self.geo)
        self.hitBox = {x1 = x1, y1 = y1, x2 = x2, y2 = y2}
    end
-- check if mouse event happens inside hitbox
ne.isInside = isInside
ne.responder['mouse_move'] = function(self, pos)
        if self.visible and self.enabled then
			local check = self:isInside(pos)
			if check and not self.active then
				self.active = true
				self.style = self.styleActive
				self:setStyle()
			elseif not check and self.active then
				self.active = false
				self.style = self.styleNormal
				self:setStyle()
			end
		end
		return false
    end
ne.responder['mouse_leave'] = function(self)
        if self.active then
            self.active = false
            self.style = self.styleNormal
            self:setStyle()
        end
    end

-- tooltip
ne = newElement('tooltip')
ne.visible = false
-- key is optional
-- pos is in {x, y} format
ne.show = function(self, text, pos, key)
        self.geo.x = pos[1]
        self.geo.y = pos[2]
        self.geo.an = pos[3]
        self.pack[4] = text
        self.key = key
        if not self.geo.an then
			if self.geo.x < player.geo.width*0.05 then
				self.geo.an = 1
				self.geo.x = self.geo.x - 5
			elseif self.geo.x > player.geo.width*0.95 then
				self.geo.an = 3
				self.geo.x = self.geo.x + 5
			else
				self.geo.an = 2
			end
		end
        self:setPos()
        self.visible = true
    end
-- update tooltip content regardless of visible status if key matches
ne.update = function(self, text, key)
        if self.key == key then
            self.pack[4] = text
            return true
        end
        return false
    end
-- only hides when key matches, maybe useful for shared tooltip
-- return true if key match
ne.hide = function(self, key)
        if self.key == key then
            self.visible = false
            return true
        end
        return false
    end
ne.responder['mouse_leave'] = function(self)
        self.visible = false
    end
    
-- slider
ne = newElement('slider')
ne.barHeight = 2
ne.handleSize = 10
ne.geo.bar = {}		-- will be flushed by setParam
ne.geo.handle = {}  -- will be flushed by setParam
ne.value = 0        -- 0~100
ne.xMin = 0
ne.xMax = 0         -- min/max x pos
ne.xLength = 0      -- xMax - xMin
ne.xValue = 0       -- value/100 * xLength
ne.style1 = nil		-- forground style
ne.style2 = nil		-- background style
ne.active = false
ne.hitBox = {}
ne.markers = {}
-- get corresponding slider value at a position
ne.getValueAt = function(self, pos)
        local x = pos[1]
        local val = (x - self.xMin)*100 / self.xLength
        if val < 0 then val = 0
            elseif val > 100 then val = 100 end
        return val
    end
ne.setParam = function(self)
        local x1, y1, x2, y2 = getBoxPos(self.geo)
        self.hitBox = {x1 = x1, y1 = y1, x2 = x2, y2 = y2}
        -- geo params are changed!!!!
        self.geo.x = x1
        self.geo.y = y1
        self.geo.an = 7
        
        self.xMin = x1
        self.xMax = x2
        self.xLength = x2 - x1
        self.xValue = self.value/100 * self.xLength
        
        local b = self.geo.bar
        b.x = x1
        b.y = y1 + (self.geo.h - self.barHeight) / 2
        b.w = self.geo.w
        b.h = self.barHeight
        b.an = 7
        
        local h = self.geo.handle
        h.x = x1 + self.xValue
        h.y = y1 + self.geo.h / 2
        h.w = self.handleSize
        h.h = h.w
        h.an = 7
    end
ne.init = function(self)
        self:setParam()
        self:setPos()
        self:setStyle()
        self:render()
    end
ne.setPos = function(self)
		-- bg
		self.pack[1] = getPos(self.geo.bar)
		-- fg
		self.pack[5] = self.pack[1]
		-- handle
		self.pack[9] = ''
	end
ne.setAlpha = function(self, trans)
		self.trans = trans
		-- bg
		self.pack[2] = getAlpha(self.style2, trans)
		-- fg
		self.pack[6] = getAlpha(self.style1, trans)
		-- handle
		self.pack[10] = self.pack[6]
	end
ne.setStyle = function(self)
		self:setAlpha(self.trans)
		-- bg
		self.pack[3] = getStyle(self.style2)
		-- fg
		self.pack[7] = getStyle(self.style1)
		-- handle
		self.pack[11] = self.pack[7]
	end
ne.render = function(self)
		-- render bg
        local ass = assdraw.ass_new()
        local w, h = self.geo.bar.w, self.geo.bar.h
        ass:draw_start()
        assDrawRectCW(ass, 0, 0, w, h)
        -- markers in bg
        for i, v in ipairs(self.markers) do
			local x = v * self.xLength
			assDrawRectCW(ass, x-0.8, -1.5, x+0.8, h+1.5)
        end
        ass:draw_stop()
        ass:new_event()
        self.pack[4] = ass.text
		-- render the handle
		ass = assdraw.ass_new()
		ass:draw_start()
		assDrawCirCW(ass, 0, 0, self.handleSize)
		ass:draw_stop()
		self.pack[12] = ass.text
		-- render fg
		self:render2()
    end
ne.render2 = function(self)
        local ass = assdraw.ass_new()
        -- render fg
        ass:draw_start()
		assDrawRectCW(ass, 0, 0, self.xValue, self.geo.bar.h)
        -- markers in fg
        for i, v in ipairs(self.markers) do
			local x = v * self.xLength
			if x > self.xValue then break end
			assDrawRectCW(ass, x-0.8, -1.5, x+0.8, self.geo.bar.h+1.5)
        end
		ass:draw_stop()
		ass:new_event()
		self.pack[8] = ass.text
		-- show handle on mouse over
		if self.active then
			self.geo.handle.x = self.xMin + self.xValue
		else
			self.geo.handle.x = -100
		end
		self.pack[9] = getPos(self.geo.handle)
	end
ne.isInside = isInside

-- a volume slider
ne = newElement('slider2')
ne.barHeight = 10
ne.geo.bar = {}		-- will be flushed by setParam
ne.value = 0        -- 0~100
ne.xMin = 0
ne.xMax = 0         -- min/max x pos
ne.xLength = 0      -- xMax - xMin
ne.xValue = 0       -- value/100 * xLength
ne.style1 = nil		-- forground style
ne.style2 = nil		-- background style
ne.active = false
ne.hitBox = {}
-- get corresponding slider value at a position
ne.getValueAt = function(self, pos)
        local x = pos[1]
        local val = (x - self.xMin)*100 / self.xLength
        if val < 0 then val = 0
            elseif val > 100 then val = 100 end
        return val
    end
ne.setParam = function(self)
        local x1, y1, x2, y2 = getBoxPos(self.geo)
        self.hitBox = {x1 = x1, y1 = y1, x2 = x2, y2 = y2}
        -- geo params are changed!!!!
        self.geo.x = x1
        self.geo.y = y1
        self.geo.an = 7
        
        self.xMin = x1
        self.xMax = x2
        self.xLength = x2 - x1
        self.xValue = self.value/100 * self.xLength
        
        local b = self.geo.bar
        b.x = x1
        b.y = y1 + (self.geo.h - self.barHeight) / 2
        b.w = self.geo.w
        b.h = self.barHeight
        b.an = 7
       
    end
ne.init = function(self)
        self:setParam()
        self:setPos()
        self:setStyle()
        self:render()
    end
ne.setPos = function(self)
		-- bg
		self.pack[1] = getPos(self.geo.bar)
		-- fg
		self.pack[5] = self.pack[1]
	end
ne.setAlpha = function(self, trans)
		self.trans = trans
		-- bg
		self.pack[2] = getAlpha(self.style2, trans)
		-- fg
		self.pack[6] = getAlpha(self.style1, trans)
	end
ne.setStyle = function(self)
		self:setAlpha(self.trans)
		-- bg
		self.pack[3] = getStyle(self.style2)
		-- fg
		self.pack[7] = getStyle(self.style1)
	end
ne.render = function(self)
		-- render bg
        local ass = assdraw.ass_new()
        local w, h = self.geo.bar.w, self.geo.bar.h
        ass:draw_start()
        ass:move_to(0, h)
        ass:line_to(w, 0)
        ass:line_to(w, h)
        ass:line_to(0, h)
        ass:draw_stop()
        ass:new_event()
        self.pack[4] = ass.text
		-- render fg
		self:render2()
    end
ne.render2 = function(self)
        -- render fg
        local ass = assdraw.ass_new()
        local w, h = self.geo.bar.w, self.geo.bar.h
        local x, y = self.xValue, self.xValue*h/w
		ass:draw_start()
        ass:move_to(0, h)
        ass:line_to(x, h-y)
        ass:line_to(x, h)
        ass:line_to(0, h)
		ass:draw_stop()
		self.pack[8] = ass.text
	end
ne.isInside = isInside