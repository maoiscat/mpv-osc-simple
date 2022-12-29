-- mpv-osc-simple
-- by maoiscat
-- github/maoiscat/mpv-osc-simple

require 'elements'
local assdraw = require 'mp.assdraw'

mp.commandv('set', 'osc', 'no')

-- change this number to resize your osc
opts.scale = 2

-- styles
styles = {
    tooltip = {
        color = {'FFFFFF', '0', '0', '0'},
        border = 1,
        blur = 2,
        font = 'mpv-osd-symbols',
        fontsize = 16,
        wrap = 0,
        },
    panel = {
        color = {'f2f2f2', '0', '0', '0'},
        alpha = {10, 255, 25, 255},
        blur = 1,
        border = 0.1,
        },
    button = {
        color = {'3A3A3A', '0', '0', '0'},
        alpha = {0, 255, 255, 255},
        blur = 0,
        border = 0,
        font = 'mpv-osd-symbols',
        fontsize = 16
        },
	button2 = {
        color = {'0', '0', '0', '0'},
        alpha = {0, 255, 255, 255},
        blur = 0,
        border = 0,
        font = 'mpv-osd-symbols',
        fontsize = 16
        },
	seekbarF = {
		color = {'C7A25A', '0', '0', '0'},
		alpha = {0, 255, 255, 255},
		blur = 0,
		border = 0,
		},
	seekbarB = {
		color = {'C0C0C0', '0', '0', '0'},
		alpha = {0, 255, 255, 255},
		blur = 0,
		border = 0,
		},
	down = {
		color = {'999999', '0', '0', '0'},
		alpha = {0, 255, 255, 255},
		blur = 0,
		border = 0,
        font = 'mpv-osd-symbols',
        fontsize = 16
		},
    title = {
        color = {'ffffff', 'ffffff', '0', '0'},
        border = 0.5,
        blur = 1,
        fontsize = 16,
        wrap = 2,
        },
    top1 = {
        color = {'eeeeee', 'eeeeee', '0', '0'},
        alpha = {100, 255, 100, 255},
        border = 0,
        blur = 0,
        font = 'mpv-osd-symbols',
        fontsize = 20,
        },
	top2 = {
        color = {'ffffff', 'ffffff', '0', '0'},
        alpha = {0, 255, 0, 255},
        border = 0.5,
        blur = 1,
        font = 'mpv-osd-symbols',
        fontsize = 20,
        },
    }

-- logo
local ne
ne = addToIdleLayout('logo')
ne:init()

-- message
local msg = addToIdleLayout('message')
msg:init()

-- an enviromental variable updater
ne = newElement('updater')
ne.layer = 1000
ne.geo = nil
ne.style = nil
ne.visible = false
ne.init = function(self)
        -- event generators
        mp.register_event('file-loaded',
            function()
                player.tracks = getTrackList()
                player.playlist = getPlaylist()
                player.chapters = getChapterList()
                player.playlistPos = getPlaylistPos()
                player.duration = mp.get_property_number('duration')
                dispatchEvent('file-loaded')
            end)
        mp.observe_property('pause', 'bool',
            function(name, val)
                player.paused = val
                dispatchEvent('pause')
            end)
        mp.observe_property('fullscreen', 'bool',
            function(name, val)
                player.fullscreen = val
                dispatchEvent('fullscreen')
            end)
        mp.observe_property('current-tracks/audio/id', 'number',
            function(name, val)
                if val then player.audioTrack = val
                    else player.audioTrack = 0
                        end
                dispatchEvent('audio-changed')
            end)
        mp.observe_property('current-tracks/sub/id', 'number',
            function(name, val)
                if val then player.subTrack = val
                    else player.subTrack = 0
                        end
                dispatchEvent('sub-changed')
            end)
        mp.observe_property('loop-playlist', 'string',
            function(name, val)
                player.loopPlaylist = val
                dispatchEvent('loop-playlist')
            end)
        mp.observe_property('volume', 'number',
            function(name, val)
                player.volume = val
                dispatchEvent('volume')
            end)
    end
ne.tick = function(self)
        player.percentPos = mp.get_property_number('percent-pos')
        player.timePos = mp.get_property_number('time-pos')
        player.timeRem = mp.get_property_number('time-remaining')
        dispatchEvent('time')
        return ''
    end
ne.responder['resize'] = function(self)
		setPlayActiveArea('area1', 0, player.geo.height-100, player.geo.width, player.geo.height)
		setPlayActiveArea('area2', 0, 0, player.geo.width, 24)
		player.geo.refX = player.geo.width / 2
		player.geo.refY = player.geo.height - 25
        return false
    end
ne:init()
local updater = ne
addToPlayLayout('updater')

-- a shared tooltip
ne = newElement('tip', 'tooltip')
ne.layer = 50
ne.style = clone(styles.tooltip)
ne:init()
addToPlayLayout('tip')
local tooltip = ne

-- panel background
ne = newElement('panel', 'box')
ne.layer = 10
ne.style = styles.panel
ne.geo.r = 3
ne.geo.an = 5
ne.geo.h = 30
ne.responder['resize'] = function(self)
		self.geo.x = player.geo.refX
		self.geo.y = player.geo.refY
		self.geo.w = player.geo.width - 20
		self:setPos()
		self:render()
	end
ne:init()
addToPlayLayout('panel')

-- play pause button
ne = newElement('btnPlay', 'button')
ne.layer = 20
ne.geo.x = 25
ne.geo.w = 20
ne.geo.h = 20
ne.geo.an = 5
ne.styleNormal = styles.button
ne.styleActive = styles.button2
ne.styleDisabled = styles.down
ne.responder['resize'] = function(self)
        self.geo.y = player.geo.refY
        self:setPos()
        self:setHitBox()
    end
ne.responder['mbtn_left_up'] = function(self, pos)
        if self.enabled and self:isInside(pos) then
            mp.commandv('cycle', 'pause')
            return true
        end
        return false
    end
ne.responder['pause'] = function(self)
		if player.paused then
			self.text = '{\\fscx120}\238\132\129'
		else
			self.text = '{\\fscx150}\238\128\130'
		end
        self:render()
        return false
    end
ne:init()
addToPlayLayout('btnPlay')

-- play time
ne = newElement('time1', 'button')
ne.layer = 20
ne.styleNormal = styles.button
ne.styleActive = styles.button2
ne.styleDisabled = styles.down
ne.geo.w = 60
ne.geo.h = 20
ne.geo.an = 6
ne.isSet = false
ne.responder['resize'] = function(self)
        self.geo.x = 100
        self.geo.y = player.geo.refY
        self.visible = player.geo.width >= 140
        self:setPos()
        self:setHitBox()
    end
ne.responder['mbtn_left_up'] = function(self, pos)
		if self.visible and self:isInside(pos) then
			self.isSet = not self.isSet
			dispatchEvent('skip-file-buttons', self.isSet)
		end
		return false
	end
ne.responder['time'] = function(self)
        if player.timePos then
            self.pack[4] = mp.format_time(player.timePos)
        else
            self.pack[4] = '--:--:--'
        end
    end
ne:init()
addToPlayLayout('time1')

-- duration
ne = newElement('time2', 'time1')
ne.geo.an = 4
ne.isDuration = true
ne.responder['resize'] = function(self)
        self.geo.x = player.geo.width - 170
        self.geo.y = player.geo.refY
        self.visible = player.geo.width >=280
        self:setPos()
        self:setHitBox()
    end
ne.responder['time'] = function(self)
        if self.isDuration then
            val = player.duration
        else
            val = -player.timeRem
        end
        if val then
            self.pack[4] = mp.format_time(val)
        else
            self.pack[4] = '--:--:--'
        end
    end
ne.responder['mbtn_left_up'] = function(self, pos)
        if self:isInside(pos) then
            self.isDuration = not self.isDuration
            self.responder['time'](self)
            return true
        end
        return false
    end
ne:init()
addToPlayLayout('time2')

-- seekbar
ne = newElement('seekbar', 'slider')
ne.layer = 30
ne.barHeight = 2
ne.handleSize = 4
ne.style1 = styles.seekbarF
ne.style2 = styles.seekbarB
ne.responder['resize'] = function(self)
		self.geo.x = 110
		self.geo.y = player.geo.refY
		self.geo.w = player.geo.width - 290
		self.geo.h = 20
		self.geo.an = 4
		self.visible = player.geo.width >= 320
		self:setParam()
		self:setPos()
		self:render()
	end
ne.responder['time'] = function(self)
        local val = player.percentPos
        if val then
            self.value = val
            self.xValue = val/100 * self.xLength
            self:render2()
        end
        return false
	end
ne.responder['file-loaded'] = function(self)
        -- update chapter markers
        self.markers = {}
        if player.duration then
            for i, v in ipairs(player.chapters) do
                self.markers[i] = (v.time / player.duration)
            end
            self:render()
        end
        return false
    end
ne.responder['mouse_move'] = function(self, pos)
		if not self.visible then return false end
        local seekTo = self:getValueAt(pos)
        if self.allowDrag then
            mp.commandv('seek', seekTo, 'absolute-percent')
        end
        if self:isInside(pos) then
            local tipText
            if player.duration then
                local seconds = seekTo/100 * player.duration
                if #player.chapters > 0 then
                    local ch = #player.chapters
                    for i, v in ipairs(player.chapters) do
                        if seconds < v.time then
                            ch = i - 1
                            break
                        end
                    end
                    if ch == 0 then
                        tipText = string.format('[0/%d][unknown]\\N%s',
                            #player.chapters, mp.format_time(seconds))
                    else
                        local title = player.chapters[ch].title
                        if not title then title = 'unknown' end
                        tipText = string.format('[%d/%d][%s]\\N%s',
                            ch, #player.chapters, title,
                            mp.format_time(seconds))
                    end
                else
                    tipText = mp.format_time(seconds)
                end
            else
                tipText = '--:--:--'
            end
            tooltip:show(tipText, {pos[1], self.geo.y+3}, self)
            self.active = true
            return true
        else
            tooltip:hide(self)
            self.active = false
            return false
        end
    end
ne.responder['mbtn_left_down'] = function(self, pos)
		if not self.visible then return false end
        if self:isInside(pos) then
            self.allowDrag = true
            local seekTo = self:getValueAt(pos)
            if seekTo then
                mp.commandv('seek', seekTo, 'absolute-percent')
                return true
            end
        end
        return false
    end
ne.responder['mbtn_left_up'] = function(self, pos)
		if self.allowDrag then
			self.allowDrag = false
			self.lastSeek = nil
			return true
		end
    end
ne:init()
addToPlayLayout('seekbar')

-- volume bar
ne = newElement('volumeBar', 'slider2')
ne.layer = 30
ne.barHeight = 12
ne.style1 = styles.button
ne.style2 = styles.seekbarB
ne.responder['resize'] = function(self)
		self.geo.x = player.geo.width - 45
		self.geo.y = player.geo.refY
		self.geo.w = 50
		self.geo.h = 20
		self.geo.an = 6
		self.visible = player.geo.width >= 200
		self:setParam()
		self:setPos()
		self:render()
	end
ne.responder['volume'] = function(self)
        local val = player.volume
        if val then
			if val > 140 then val = 140
				elseif val < 0 then val = 0 end
            self.value = val/1.4
            self.xValue = val/140 * self.xLength
            self:render()
        end
        return false
    end
ne.responder['mouse_move'] = function(self, pos)
        if not self.visible then return false end
        local vol = self:getValueAt(pos)
        if self.allowDrag then
            if vol then
                mp.commandv('set', 'volume', vol*1.4)
            end
        end
        if self:isInside(pos) then
            local tipText
            if vol then
				tipText = string.format('%d', vol*1.4)
            else
                tipText = 'N/A'
            end
            tooltip:show(tipText, {pos[1], self.geo.y}, self)
            return true
        else
            tooltip:hide(self)
            return false
        end
    end
ne.responder['mbtn_left_down'] = function(self, pos)
        if not self.visible then return false end
        if self:isInside(pos) then
            self.allowDrag = true
            local vol = self:getValueAt(pos)
            if vol then
                mp.commandv('set', 'volume', vol*1.4)
                return true
            end
        end
        return false
    end
ne.responder['mbtn_left_up'] = function(self, pos)
		if self.allowDrag then
			self.allowDrag = false
			self.lastSeek = nil
			return true
		end
    end
ne:init()
addToPlayLayout('volumeBar')


-- toggle fullscreen
ne = newElement('btnFullscreen', 'button')
ne.layer = 20
ne.styleNormal = styles.button
ne.styleActive = styles.button2
ne.styleDisabled = styles.down
ne.geo.an = 5
ne.geo.w = 20
ne.geo.h = 20
ne.responder['resize'] = function(self)
		self.geo.x = player.geo.width - 25
        self.geo.y = player.geo.refY
        self:setPos()
        self:setHitBox()
    end
ne.responder['mbtn_left_up'] = function(self, pos)
        if self.enabled and self.visible and self:isInside(pos) then
            mp.commandv('cycle', 'fullscreen')
            return true
        end
        return false
    end
ne.responder['fullscreen'] = function(self)
		if player.fullscreen then
			self.text = '{\\fscx125\\fscy125}\xee\x84\x89'
		else
			self.text = '{\\fscx125\\fscy125}\xee\x84\x88'
		end
		self:render()
	end
ne:init()
addToPlayLayout('btnFullscreen')

-- cycle audio
ne = newElement('btnAudio', 'button')
ne.layer = 20
ne.styleNormal = styles.top1
ne.styleActive = styles.top2
ne.styleDisabled = nil
ne.geo.an = 5
ne.geo.w = 20
ne.geo.h = 20
ne.text = '\xee\x84\x86'
ne.responder['resize'] = function(self)
        self.geo.x = 25
        self.geo.y = player.geo.refY - 50
        self:setPos()
        self:setHitBox()
    end
ne.responder['file-loaded'] = function(self)
        if #player.tracks.audio > 1 then
            self.visible = true
        else
            self.visible = false
        end
        return false
    end
ne.responder['mbtn_left_up'] = function(self, pos)
        if self.visible and self:isInside(pos) then
            cycleTrack('audio')
            return true
        end
        return false
    end
ne.responder['mbtn_right_up'] = function(self, pos)
        if self.visible and self:isInside(pos) then
            cycleTrack('audio', 'prev')
            return true
        end
        return false
    end
ne.responder['audio-changed'] = function(self)
        if player.tracks then
            local title
            if player.audioTrack == 0 then
                title = 'OFF'
            else
                title = player.tracks.audio[player.audioTrack].title
            end
            if not title then title = 'unknown' end
            self.tipText = string.format('[%s/%s][%s]',
                player.audioTrack, #player.tracks.audio, title)
                tooltip:update(self.tipText, self)
        end
        return false
    end
ne.responder['mouse_move'] = function(self, pos)
        if not self.visible then return false end
		local check = self:isInside(pos)
		if check and not self.active then
			self.active = true
			self.style = self.styleActive
			self:setStyle()
			tooltip:show(self.tipText, {self.geo.x+10, self.geo.y, 4}, self)
		elseif not check and self.active then
			self.active = false
			self.style = self.styleNormal
			self:setStyle()
			tooltip:hide(self)
		end
		return false
    end
ne:init()
addToPlayLayout('btnAudio')


-- cycle sub
ne = newElement('btnSub', 'button')
ne.layer = 20
ne.styleNormal = styles.top1
ne.styleActive = styles.top2
ne.styleDisabled = nil
ne.geo.an = 5
ne.geo.w = 20
ne.geo.h = 20
ne.text = '\xee\x84\x87'
ne.responder['resize'] = function(self)
        self.geo.x = 25
        self.geo.y = player.geo.refY - 31
        self:setPos()
        self:setHitBox()
    end
ne.responder['file-loaded'] = function(self)
        if #player.tracks.sub > 0 then
            self.visible = true
        else
            self.visible = false
        end
        return false
    end
ne.responder['mbtn_left_up'] = function(self, pos)
        if self.visible and self:isInside(pos) then
            cycleTrack('sub')
            return true
        end
        return false
    end
ne.responder['mbtn_right_up'] = function(self, pos)
        if self.visible and self:isInside(pos) then
            cycleTrack('sub', 'prev')
            return true
        end
        return false
    end
ne.responder['sub-changed'] = function(self)
        if player.tracks then
            local title
            if player.subTrack == 0 then
                title = 'OFF'
            else
                title = player.tracks.sub[player.subTrack].title
            end
            if not title then title = 'unknown' end
            self.tipText = string.format('[%s/%s][%s]',
                player.subTrack, #player.tracks.sub, title)
                tooltip:update(self.tipText, self)
        end
        return false
    end
ne.responder['mouse_move'] = function(self, pos)
        if not self.visible then return false end
		local check = self:isInside(pos)
		if check and not self.active then
			self.active = true
			self.style = self.styleActive
			self:setStyle()
			tooltip:show(self.tipText, {self.geo.x+10, self.geo.y, 4}, self)
		elseif not check and self.active then
			self.active = false
			self.style = self.styleNormal
			self:setStyle()
			tooltip:hide(self)
		end
		return false
    end
ne:init()
addToPlayLayout('btnSub')

-- previous file button
ne = newElement('btnPrev', 'button')
ne.layer = 20
ne.styleNormal = styles.top1
ne.styleActive = styles.top2
ne.styleDisabled = styles.top1
ne.geo.an = 5
ne.geo.w = 20
ne.geo.h = 20
ne.visible = false
ne.render = function(self)
        local s, w = 10, 2
        local ass = assdraw.ass_new()
        ass:draw_start()
        -- rect
        ass:rect_cw(0, s*0.1, w, s*0.9)
        -- triangle1
        ass:move_to(w+1, s/2)
        ass:line_to(s, 0)
        ass:line_to(s, s)
        ass:line_to(w+1, s/2)
        ass:draw_stop()
        self.pack[4] = ass.text
    end
ne.responder['resize'] = function(self)
		self.geo.x = 55
        self.geo.y = player.geo.refY - 30
        self:setPos()
        self:setHitBox()
    end
ne.responder['file-loaded'] = function(self)
        if not player.playlist then return false end
        if player.playlistPos <= 1 and player.loopPlaylist == 'no' then
            self:disable()
        else
            self:enable()
        end
        return false
    end
ne.responder['loop-playlist'] = ne.responder['file-loaded']
ne.responder['mbtn_left_up'] = function(self, pos)
        if self.enabled and self.visible and self:isInside(pos) then
            mp.commandv('playlist-prev', 'weak')
            return true
        end
        return false
    end
ne.responder['skip-file-buttons'] = function(self, arg)
		self.visible = arg
	end
ne:init()
addToPlayLayout('btnPrev')

-- next file button
ne = newElement('btnNext', 'button')
ne.layer = 20
ne.styleNormal = styles.top1
ne.styleActive = styles.top2
ne.styleDisabled = styles.top1
ne.geo.an = 5
ne.geo.w = 20
ne.geo.h = 20
ne.visible = false
ne.render = function(self)
        local s, w = 10, 2
        local ass = assdraw.ass_new()
        ass:draw_start()
        -- rect
        ass:rect_cw(s-w, s*0.1, s, s*0.9)
        -- triangle1
        ass:move_to(0, 0)
        ass:line_to(s-w-1, s/2)
        ass:line_to(0, s)
        ass:line_to(0, 0)
        ass:draw_stop()
        self.pack[4] = ass.text
    end
ne.responder['resize'] = function(self)
		self.geo.x = 85
        self.geo.y = player.geo.refY - 30
        self:setPos()
        self:setHitBox()
    end
ne.responder['file-loaded'] = function(self)
        if not player.playlist then return false end
        if player.playlistPos >= #player.playlist
            and player.loopPlaylist == 'no' then
            self:disable()
        else
            self:enable()
        end
        return false
    end
ne.responder['loop-playlist'] = ne.responder['file-loaded']
ne.responder['mbtn_left_up'] = function(self, pos)
        if self.enabled and self.visible and self:isInside(pos) then
            mp.commandv('playlist-next', 'weak')
            return true
        end
        return false
    end
ne.responder['skip-file-buttons'] = function(self, arg)
		self.visible = arg
	end
ne:init()
addToPlayLayout('btnNext')

-- close button on title bar
ne = newElement('winClose', 'button')
ne.layer = 20
ne.geo.w = 20
ne.geo.h = 20
ne.geo.an = 5
ne.styleNormal = styles.top1
ne.styleActive = styles.top2
ne.styleDisabled = nil
ne.text = '\238\132\149'
ne.responder['resize'] = function(self)
        self.geo.x = player.geo.width - 20
        self.geo.y = 12
        self:setPos()
        self:setHitBox()
        return false
    end
ne.responder['fullscreen'] = function(self)
		self.visible = player.fullscreen
        return false
    end
ne.responder['mbtn_left_up'] = function(self, pos)
        if self.visible and self:isInside(pos) then
            mp.commandv('quit')
        end
        return false
    end
ne:init()
addToPlayLayout('winClose')

-- max/restore button on title bar
ne = newElement('winMax', 'winClose')
ne.responder['resize'] = function(self)
        self.geo.x = player.geo.width - 50
        self.geo.y = 12
        if player.fullscreen then
            self.text = '\238\132\148'
        else
            self.text = '\238\132\147'
        end
        self:render()
        self:setPos()
        self:setHitBox()
        return false
    end
ne.responder['mbtn_left_up'] = function(self, pos)
        if self:isInside(pos) then
            mp.commandv('cycle', 'fullscreen')
            return true
        end
        return false
    end
ne:init()
addToPlayLayout('winMax')

-- minimize button
ne = newElement('winMin', 'winClose')
ne.text = '\238\132\146'
ne.responder['resize'] = function(self)
        self.geo.x = player.geo.width - 75
        self.geo.y = 12
        self:setPos()
        self:setHitBox()
        return false
    end
ne.responder['mbtn_left_up'] = function(self, pos)
        if self:isInside(pos) then
            mp.commandv('cycle', 'window-minimized')
            return true
        end
        return false
    end
ne:init()
addToPlayLayout('winMin')
