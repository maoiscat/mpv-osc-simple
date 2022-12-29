-- osc framework extra functions
-- by maoiscat
-- github.com/maoiscat/

require 'mp.assdraw'
require 'oscf'

-- print table, for debug
function ptb(tab, prefix)
    local fmt, str
    if prefix == nil then prefix = tostring(tab) end
    if type(tab) ~= 'table' then
        str = tostring(tab)
        string.gsub(str, '\n', '[nl]')
        print(string.format('%s = %s', prefix, str))
    else
        for k, v in pairs(tab) do
            str = prefix .. '.' .. tostring(k)
            ptb(v, str)
        end
    end
end

-- a simple clone function to help copying style table
function clone(sth)
    if type(sth) ~= 'table' then return sth end
    local copy = {}
    for k, v in pairs(sth) do
        copy[k] = clone(v)
    end
    return copy
end

-- get the outline box coordinates of an element.
-- geo: same format as element.geo
-- return: left, top, right, bottom position
function getBoxPos(geo)
    local box = {
    [1] = function(geo) return geo.x, geo.y-geo.h, geo.x+geo.w, geo.y end,
    [2] = function(geo) return geo.x-geo.w/2, geo.y-geo.h, geo.x+geo.w/2, geo.y end,
    [3] = function(geo) return geo.x-geo.w, geo.y-geo.h, geo.x, geo.y end,
    [4] = function(geo) return geo.x, geo.y-geo.h/2, geo.x+geo.w, geo.y+geo.h/2 end,
    [5] = function(geo) return geo.x-geo.w/2, geo.y-geo.h/2, geo.x+geo.w/2, geo.y+geo.h/2 end,
    [6] = function(geo) return geo.x-geo.w, geo.y-geo.h/2, geo.x, geo.y+geo.h/2 end,
    [7] = function(geo) return geo.x, geo.y, geo.x+geo.w, geo.y+geo.h end,
    [8] = function(geo) return geo.x-geo.w/2, geo.y, geo.x+geo.w/2, geo.y+geo.h end,
    [9] = function(geo) return geo.x-geo.w, geo.y, geo.x, geo.y+geo.h end,
    }
    local x1, y1, x2, y2
    if box[geo.an] then
        x1, y1, x2, y2 = box[geo.an](geo)
    end
    return x1, y1, x2, y2
end
-- get the list of tracks
-- return: tracks categorize as video, audio and sub
function getTrackList()
    local trackList = mp.get_property_native('track-list')
    local tracks = {video = {}, audio = {}, sub = {}}
    for i, v in ipairs(trackList) do
        if v.type ~= 'unknown' then
            table.insert(tracks[v.type], v)
        end
    end
    return tracks
end
-- get playlist
function getPlaylist()
    local playlist = mp.get_property_native('playlist')
    return playlist
end
-- get position on playlist
-- return: pos number start from 1
function getPlaylistPos()
    return mp.get_property_number('playlist-pos-1')
end
-- get chapter list
function getChapterList()
    return mp.get_property_native('chapter-list')
end
-- get video parameters
-- see https://mpv.io/manual/master/#command-interface-video-params
function getVideoParams()
    return mp.get_property_native('video-params')
end
-- get current track
-- name: 'video', 'audio' or 'sub'
-- return: track index, 0 for none
function getTrack(name)
    local prop = string.format('current-tracks/%s/id', name)
    local index = mp.get_property_number(prop)
    if index then return index
        else return 0 end
end

-- cycle through tracks
-- name: 'video', 'audio' or 'sub'
-- direction: optional 'next' or 'prev', default is 'next'
function cycleTrack(name, direction)
    local current = getTrack(name)
    local index
    local tracks = getTrackList()
    tracks = tracks[name]
    if not tracks then return end
    if direction == 'prev' then
        index = current - 1
    else
        index = current + 1
    end
    if index > #tracks then index = 1
        elseif index < 1 then index = #tracks
            end
    local newTrack
    
    if index == 0 then
        newTrack = 'no'
    else
        newTrack = tracks[index].id
    end
    mp.commandv('set', name, newTrack)
end

-- check if a position{x, y} is inside the hitbox of an object
-- the object must contain a .hitBox = {x1, y1, x2, y2} table
-- return: true if inside
function isInside(obj, pos)
    local x, y = pos[1], pos[2]
    if obj.hitBox.x1 <= x and x <= obj.hitBox.x2
        and obj.hitBox.y1 <= y and y <= obj.hitBox.y2 then
        return true
    else
        return false
    end
end

-- stand alone version of setPos, setStyle, setAlpha function 
function getPos(geo)
	if not geo then return '' end
	return string.format('{\\pos(%f,%f)\\an%d}', geo.x, geo.y, geo.an)
end

function getAlpha(style, trans)
	if not style or not trans then return '' end
	local alpha = {0, 0, 0, 0}
	if style.alpha then
		for i = 1, 4 do
			alpha[i] = 255 - (((1-(style.alpha[i]/255)) * (1-trans)) * 255)
		end
	else
		alpha = {trans*255, trans*255, trans*255, trans*255}
	end
	return string.format('{\\1a&H%x&\\2a&H%x&\\3a&H%x&\\4a&H%x&}', alpha[1], alpha[2], alpha[3], alpha[4])
end

function getStyle(style)
	if not style then return '' end
	local fmt = {'{'}
	if style.color then
		table.insert(fmt, 
			string.format('\\1c&H%s&\\2c&H%s&\\3c&H%s&\\4c&H%s&',
				style.color[1], style.color[2], style.color[3], style.color[4]))
	end
	if style.border then
		table.insert(fmt, string.format('\\bord%.2f', style.border)) end
	if style.blur then
		table.insert(fmt, string.format('\\blur%.2f', style.blur)) end
	if style.shadow then
		table.insert(fmt, string.format('\\shad%.2f', style.shadow)) end
	if style.font then
		table.insert(fmt, string.format('\\fn%s', style.font)) end
	if style.fontsize then
		table.insert(fmt, string.format('\\fs%d', style.fontsize)) end
	if style.wrap then
		table.insert(fmt, string.format('\\q%d', style.wrap)) end
	table.insert(fmt, '}')
	return table.concat(fmt)
end

-- ass draw alias
-- draw a circle in clockwise direction
function assDrawCirCW(ass, x, y, r)
    ass:round_rect_cw(x-r, y-r, x+r, y+r, r)
end
-- draw a circle in counter-clockwise direction
function assDrawCirCCW(ass, x, y, r)
    ass:round_rect_ccw(x-r, y-r, x+r, y+r, r)
end
-- draw rectangle
function assDrawRectCW(ass, x1, y1, x2, y2)
    ass:rect_cw(x1, y1, x2, y2)
end

function assDrawRectCCW(ass, x1, y1, x2, y2)
    ass:rect_ccw(x1, y1, x2, y2)
end
-- draw round rectangle
-- r2 is optional
function assDrawRoundRectCW(ass, x1, y1, x2, y2, r1, r2)
    ass:round_rect_cw(x1, y1, x2, y2, r1, r2)
end

function assDrawRoundRectCCW(ass, x1, y1, x2, y2, r1, r2)
    ass:round_rect_ccw(x1, y1, x2, y2, r1, r2)
end
-- draw round hexagon
-- r2 is optional
function assDrawRoundHexaCW(ass, x1, y1, x2, y2, r1, r2)
    ass:hexagon_cw(x1, y1, x2, y2, r1, r2)
end

function assDrawRoundHexaCCW(ass, x1, y1, x2, y2, r1, r2)
    ass:hexagon_ccw(x1, y1, x2, y2, r1, r2)
end
-- draw lines
function assDrawLine(ass, x1, y1, x2, y2)
    ass:move_to(x1, y1)
    ass:line_to(x2, y2)
end

function assDrawLineTo(ass, x, y)
    ass:line_to(x, y)
end