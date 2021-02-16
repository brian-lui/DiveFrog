local love = _G.love

local colors = require 'colors'
local fonts = require 'fonts'
local images = require 'images'
local json = require 'dkjson'
local music = require 'music' -- background music


require 'settings'

local title = {}

-- Default selections
title.default_selections = {
	title = 1,
	player1P = 1,
	AI1P = 1,
	player12P = 1,
	player22P = 2,
}

if love.filesystem.getInfo("choices.txt") then
	local choices_string = love.filesystem.read("choices.txt")
	title.default_selections = json.decode(choices_string)
else
	love.filesystem.write("choices.txt", json.encode(title.default_selections))
end

-- Select menu
local function charSelect()
	music.setBGM("CharSelect.ogg")

	char_text = {
		{"Hyper Jump", "Hyper Kick", "+40%", "Double Jump"},
		{"Wire Sea", "Frog On Land", "+20%, Wire Ocean", "Dandy Frog (Wire Sea OK)\n— Pile Bonquer (Wire Sea OK)"},
		{"Hotflame (Wire Sea OK)", "Riot Kick", "Frog Install", "Small Head"},
		{"Anti-Gravity Frog", "Wow!", "+40%", "Jackson/Bison Stances"},
	}

	if game.format == "1P" then
		p1_char = title.default_selections.player1P
		p2_char = title.default_selections.AI1P
	elseif game.format == "2P" then
		p1_char = title.default_selections.player12P
		p2_char = title.default_selections.player22P
	else
		print("Invalid game mode selected.")
	end

	game.current_screen = "charselect"
end

local function select1P()
	game.format = "1P"
	title.default_selections.title = 1
	love.filesystem.write("choices.txt", json.encode(title.default_selections))
	charSelect()
end

local function select2P()
	game.format = "2P"
	title.default_selections.title = 2
	love.filesystem.write("choices.txt", json.encode(title.default_selections))
	charSelect()
end


title.choices = {
	menu = {"1 Player", "2 Player", "Settings"},
	action = {select1P, select2P, settingsMenu},
	option = title.default_selections.title
}

-- Replays
function replays()
	game.current_screen = "replays"
	--[[
	Scan folder for all valid folders
	Output list of all files to a table -- https://love2d.org/wiki/love.filesystem.getDirectoryItems
	Sort table by filename -- table.sort(table)
	Show all files with 'round 0' as the end part
	Each segment is from 'round 0' until (1 - next 'round 0')

	Operations: select files, or back to main menu
	Select file: play file, delete file
	Play file --
		9th char in string is P1, 11th is P2
		Disable user input
		Allow enter key to popup "return to main menu?" (can continue playing in background for simplicity)
		For i = 1 to #-1: decode .txt into keybuffer
	Delete file -- https://love2d.org/wiki/love.filesystem.remove
	]]
end


return title