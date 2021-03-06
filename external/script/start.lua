
local start = {}

setSelColRow(motif.select_info.columns, motif.select_info.rows)

--not used for now
--setShowEmptyCells(motif.select_info.showemptyboxes)
--setRandomSpr(motif.selectbgdef.spr_data, motif.select_info.cell_random_spr[1], motif.select_info.cell_random_spr[2], motif.select_info.cell_random_scale[1], motif.select_info.cell_random_scale[2])
--setCellSpr(motif.selectbgdef.spr_data, motif.select_info.cell_bg_spr[1], motif.select_info.cell_bg_spr[2], motif.select_info.cell_bg_scale[1], motif.select_info.cell_bg_scale[2])

setSelCellSize(motif.select_info.cell_size[1] + motif.select_info.cell_spacing[1], motif.select_info.cell_size[2] + motif.select_info.cell_spacing[2])
setSelCellScale(motif.select_info.portrait_scale[1], motif.select_info.portrait_scale[2])

--default team count after starting the game
local p1NumTurns = 2
local p1NumSimul = 2
local p1NumTag = 2
local p1NumRatio = 1
local p2NumTurns = 2
local p2NumSimul = 2
local p2NumTag = 2
local p2NumRatio = 1
--default team mode after starting the game
local p1TeamMenu = 1
local p2TeamMenu = 1
--let cursor wrap around
local wrappingX = false
local wrappingY = false
if motif.select_info.wrapping == 1 then
	if motif.select_info.wrapping_x == 1 then
		wrappingX = true
	end
	if motif.select_info.wrapping_y == 1 then
		wrappingY = true
	end
end
--initialize other local variables
local t_roster = {}
local t_aiRamp = {}
local t_p1Selected = {}
local t_p2Selected = {}
local t_p1Cursor = {}
local t_p2Cursor = {}
local p1RestoreCursor = false
local p2RestoreCursor = false
local p1Cell = false
local p2Cell = false
local p1TeamEnd = false
local p1SelEnd = false
local p1Ratio = false
local p2TeamEnd = false
local p2SelEnd = false
local p2Ratio = false
local selScreenEnd = false
local stageEnd = false
local coopEnd = false
local restoreTeam = false
local resetgrid = false
local continueData = false
local teamMode = 0
local numChars = 0
local p1NumChars = 0
local p2NumChars = 0
local matchNo = 0
local p1SelX = 0
local p1SelY = 0
local p2SelX = 0
local p2SelY = 0
local p1FaceOffset = 0
local p2FaceOffset = 0
local p1RowOffset = 0
local p2RowOffset = 0
local winner = 0
local t_gameStats = {}
local winCnt = 0
local looseCnt = 0
local p1FaceX = 0
local p1FaceY = 0
local p2FaceX = 0
local p2FaceY = 0
local p1TeamMode = 0
local p2TeamMode = 0
local lastMatch = 0
local stageNo = 0
local stageList = 0
local timerSelect = 0
local fadeType = 'fadein'
local continue = false
local challenger = false
local cnt = motif.select_info.columns + 1
local row = 1
local col = 0
local t_grid = {}
t_grid[row] = {}
for i = 1, (motif.select_info.rows + motif.select_info.rows_scrolling) * motif.select_info.columns do
	if i == cnt then
		row = row + 1
		cnt = cnt + motif.select_info.columns
		t_grid[row] = {}
	end
	col = #t_grid[row] + 1
	t_grid[row][col] = {num = i - 1, x = (col - 1) * (motif.select_info.cell_size[1] + motif.select_info.cell_spacing[1]), y = (row - 1) * (motif.select_info.cell_size[2] + motif.select_info.cell_spacing[2])}
	if main.t_selChars[i].char ~= nil then
		t_grid[row][col].char = main.t_selChars[i].char
		t_grid[row][col].hidden = main.t_selChars[i].hidden
		main.t_selChars[i].row = row
		main.t_selChars[i].col = col
	end
end

--;===========================================================
--; COMMON FUNCTIONS
--;===========================================================
--converts '.maxmatches' style table (key = order, value = max matches) to the same structure as '.ratiomatches' (key = match number, value = subtable with char num and order data)
function start.f_unifySettings(t, t_chars)
	local ret = {}
	for i = 1, #t do --for each order number
		if t_chars[i] ~= nil then --only if there are any characters available with this order
			local infinite = false
			local num = t[i]
			if num == -1 then --infinite matches
				num = #t_chars[i] --assign max amount of characters with this order
				infinite = true
			end
			for j = 1, num do --iterate up to max amount of matches versus characters with this order
				if j * p2NumChars > #t_chars[i] and #ret > 0 then --if there are not enough characters to fill all slots and at least 1 fight is already assigned
					local stop = true
					for k = (j - 1) * p2NumChars + 1, #t_chars[i] do --loop through characters left for this match
						if main.t_selChars[t_chars[i][k] + 1].onlyme == 1 then --and allow appending if any of the remaining characters has 'onlyme' flag set
							stop = false
						end
					end
					if stop then
						break
					end
				end
				table.insert(ret, {['rmin'] = p2NumChars, ['rmax'] = p2NumChars, ['order'] = i})
			end
			if infinite then
				table.insert(ret, {['rmin'] = p2NumChars, ['rmax'] = p2NumChars, ['order'] = -1})
				break --no point in appending additional matches
			end
		end
	end
	return ret
end

--generates roster table
function start.f_makeRoster(t_ret)
	t_ret = t_ret or {}
	--prepare correct settings tables
	local t = {}
	local t_static = {}
	local t_removable = {}
	--Arcade
	if gameMode('arcade') or gameMode('teamcoop') or gameMode('netplayteamcoop') then
		t_static = main.t_orderChars
		if p2Ratio then --Ratio
			if main.t_selChars[t_p1Selected[1].cel + 1].ratiomatches ~= nil and main.t_selOptions[main.t_selChars[t_p1Selected[1].cel + 1].ratiomatches .. "_arcaderatiomatches"] ~= nil then --custom settings exists as char param
				t = main.t_selOptions[main.t_selChars[t_p1Selected[1].cel + 1].ratiomatches .. "_arcaderatiomatches"]
			else --default settings
				t = main.t_selOptions.arcaderatiomatches
			end
		elseif p2TeamMode == 0 then --Single
			if main.t_selChars[t_p1Selected[1].cel + 1].maxmatches ~= nil and main.t_selOptions[main.t_selChars[t_p1Selected[1].cel + 1].maxmatches .. "_arcademaxmatches"] ~= nil then --custom settings exists as char param
				t = start.f_unifySettings(main.t_selOptions[main.t_selChars[t_p1Selected[1].cel + 1].maxmatches .. "_arcademaxmatches"], t_static)
			else --default settings
				t = start.f_unifySettings(main.t_selOptions.arcademaxmatches, t_static)
			end
		else --Simul / Turns / Tag
			if main.t_selChars[t_p1Selected[1].cel + 1].maxmatches ~= nil and main.t_selOptions[main.t_selChars[t_p1Selected[1].cel + 1].maxmatches .. "_teammaxmatches"] ~= nil then --custom settings exists as char param
				t = start.f_unifySettings(main.t_selOptions[main.t_selChars[t_p1Selected[1].cel + 1].maxmatches .. "_teammaxmatches"], t_static)
			else --default settings
				t = start.f_unifySettings(main.t_selOptions.teammaxmatches, t_static)
			end
		end
	--Survival
	elseif gameMode('survival') or gameMode('survivalcoop') or gameMode('netplaysurvivalcoop') then
		t_static = main.t_orderSurvival
		if main.t_selChars[t_p1Selected[1].cel + 1].maxmatches ~= nil and main.t_selOptions[main.t_selChars[t_p1Selected[1].cel + 1].maxmatches .. "_survivalmaxmatches"] ~= nil then --custom settings exists as char param
			t = start.f_unifySettings(main.t_selOptions[main.t_selChars[t_p1Selected[1].cel + 1].maxmatches .. "_survivalmaxmatches"], t_static)
		else --default settings
			t = start.f_unifySettings(main.t_selOptions.survivalmaxmatches, t_static)
		end
	--Boss Rush
	elseif gameMode('bossrush') then
		t_static = {main.t_bossChars}
		for i = 1, math.ceil(#main.t_bossChars / p2NumChars) do --generate ratiomatches style table
			table.insert(t, {['rmin'] = p2NumChars, ['rmax'] = p2NumChars, ['order'] = 1})
		end
	--VS 100 Kumite
	elseif gameMode('100kumite') then
		t_static = {main.t_randomChars}
		for i = 1, 100 do --generate ratiomatches style table for 100 matches
			table.insert(t, {['rmin'] = p2NumChars, ['rmax'] = p2NumChars, ['order'] = 1})
		end
	else
		print('LUA ERROR: ' .. gameMode() .. ' game mode unrecognized by start.f_makeRoster()') --TODO: add function for printing panic errors via go
		os.exit()
	end
	--generate roster
	t_removable = main.f_copyTable(t_static) --copy into editable order table
	for i = 1, #t do --for each match number
		if t[i].order == -1 then --infinite matches for this order detected
			table.insert(t_ret, {-1}) --append infinite matches flag at the end
			break
		end
		if t_removable[t[i].order] ~= nil then
			if #t_removable[t[i].order] == 0 and gameMode('100kumite') then
				t_removable = main.f_copyTable(t_static) --ensure that there will be at least 100 matches in VS 100 Kumite mode
			end
			if #t_removable[t[i].order] >= 1 then --there is at least 1 character with this order available
				local remaining = t[i].rmin - #t_removable[t[i].order]
				table.insert(t_ret, {}) --append roster table with new subtable
				for j = 1, math.random(math.min(t[i].rmin, #t_removable[t[i].order]), math.min(t[i].rmax, #t_removable[t[i].order])) do --for randomized characters count
					local rand = math.random(1, #t_removable[t[i].order]) --randomize which character will be taken
					table.insert(t_ret[#t_ret], t_removable[t[i].order][rand]) --add such character into roster subtable
					table.remove(t_removable[t[i].order], rand) --and remove it from the available character pool
				end
				--fill the remaining slots randomly if there are not enough players available with this order
				while remaining > 0 do
					table.insert(t_ret[#t_ret], t_static[t[i].order][math.random(1, #t_static[t[i].order])])
					remaining = remaining - 1
				end
			end
		end
	end
	main.f_printTable(t_ret, 'debug/t_roster.txt')
	return t_ret
end

--generates AI ramping table
function start.f_aiRamp(currentMatch)
	local start_match = 0
	local start_diff = 0
	local end_match = 0
	local end_diff = 0
	if currentMatch == 1 then
		t_aiRamp = {}
	end
	--Arcade
	if gameMode('arcade') or gameMode('teamcoop') or gameMode('netplayteamcoop') then
		if p2TeamMode == 0 then --Single
			start_match = main.t_selOptions.arcadestart.wins
			start_diff = main.t_selOptions.arcadestart.offset
			end_match =  main.t_selOptions.arcadeend.wins
			end_diff = main.t_selOptions.arcadeend.offset
		elseif p2Ratio then --Ratio
			start_match = main.t_selOptions.ratiostart.wins
			start_diff = main.t_selOptions.ratiostart.offset
			end_match =  main.t_selOptions.ratioend.wins
			end_diff = main.t_selOptions.ratioend.offset
		else --Simul / Turns / Tag
			start_match = main.t_selOptions.teamstart.wins
			start_diff = main.t_selOptions.teamstart.offset
			end_match =  main.t_selOptions.teamend.wins
			end_diff = main.t_selOptions.teamend.offset
		end
	elseif gameMode('survival') or gameMode('survivalcoop') or gameMode('netplaysurvivalcoop') then
		start_match = main.t_selOptions.survivalstart.wins
		start_diff = main.t_selOptions.survivalstart.offset
		end_match =  main.t_selOptions.survivalend.wins
		end_diff = main.t_selOptions.survivalend.offset
	end
	local startAI = config.Difficulty + start_diff
	if startAI > 8 then
		startAI = 8
	elseif startAI < 1 then
		startAI = 1
	end
	local endAI = config.Difficulty + end_diff
	if endAI > 8 then
		endAI = 8
	elseif endAI < 1 then
		endAI = 1
	end
	for i = currentMatch, lastMatch do
		if i - 1 <= start_match then
			table.insert(t_aiRamp, startAI)
		elseif i - 1 <= end_match then
			local curMatch = i - (start_match + 1)
			table.insert(t_aiRamp, math.floor(curMatch * (endAI - startAI) / (end_match - start_match) + startAI))
		else
			table.insert(t_aiRamp, endAI)
		end
	end
	main.f_printTable(t_aiRamp, 'debug/t_aiRamp.txt')
end

--returns bool depending of rivals match validity
function start.f_rivalsMatch(param, value)
	if main.t_selChars[t_p1Selected[1].cel + 1].rivals ~= nil and main.t_selChars[t_p1Selected[1].cel + 1].rivals[matchNo] ~= nil then
		if param == nil then --check only if rivals assignment for this match exists at all
			return true
		elseif main.t_selChars[t_p1Selected[1].cel + 1].rivals[matchNo][param] ~= nil then
			if value == nil then --check only if param is assigned for this rival
				return true
			else --check if param equals value
				return main.t_selChars[t_p1Selected[1].cel + 1].rivals[matchNo][param] == value
			end
		end
	end
	return false
end

--calculates AI level
function start.f_difficulty(player, offset)
	local t = {}
	if player % 2 ~= 0 then --odd value (Player1 side)
		local pos = math.floor(player / 2 + 0.5)
		t = main.t_selChars[t_p1Selected[pos].cel + 1]
	else --even value (Player2 side)
		local pos = math.floor(player / 2)
		if pos == 1 and start.f_rivalsMatch('ai') then --player2 team leader and arcade mode and ai rivals param exists
			t = main.t_selChars[t_p1Selected[1].cel + 1].rivals[matchNo]
		else
			t = main.t_selChars[t_p2Selected[pos].cel + 1]
		end
	end
	if t.ai ~= nil then
		return t.ai
	else
		return config.Difficulty + offset
	end
end

--assigns AI level
function start.f_remapAI()
	--Offset
	local offset = 0
	if config.AIRamping and (gameMode('arcade') or gameMode('teamcoop') or gameMode('netplayteamcoop') or gameMode('survival') or gameMode('survivalcoop') or gameMode('netplaysurvivalcoop')) then
		offset = t_aiRamp[matchNo] - config.Difficulty
	end
	--Player 1
	if main.coop then
		remapInput(3, 2) --P3 character uses P2 controls
		setCom(1, 0)
		setCom(3, 0)
	elseif p1TeamMode == 0 then --Single
		if main.p1In == 1 and not main.aiFight then
			setCom(1, 0)
		else
			setCom(1, start.f_difficulty(1, offset))
		end
	elseif p1TeamMode == 1 and config.SimulMode then --Simul
		if main.p1In == 1 and not main.aiFight then
			setCom(1, 0)
		else
			setCom(1, start.f_difficulty(1, offset))
		end
		for i = 3, p1NumChars * 2 do
			if i % 2 ~= 0 then --odd value
				remapInput(i, 1) --P3/5/7 character uses P1 controls
				setCom(i, start.f_difficulty(i, offset))
			end
		end
	elseif p1TeamMode == 2 then --Turns
		for i = 1, p1NumChars * 2 do
			if i % 2 ~= 0 then --odd value
				if main.p1In == 1 and not main.aiFight then
					remapInput(i, 1) --P1/3/5/7 character uses P1 controls
					setCom(i, 0)
				else
					setCom(i, start.f_difficulty(i, offset))
				end
			end
		end
	else --p1TeamMode == 3 or (p1TeamMode == 1 and not config.SimulMode) --Tag
		for i = 1, p1NumChars * 2 do
			if i % 2 ~= 0 then --odd value
				if main.p1In == 1 and not main.aiFight then
					remapInput(i, 1) --P1/3/5/7 character uses P1 controls
					setCom(i, 0)
				else
					setCom(i, start.f_difficulty(i, offset))
				end
			end
		end
	end
	--Player 2
	if p2TeamMode == 0 then --Single
		if main.p2In == 2 and not main.aiFight and not main.coop then
			setCom(2, 0)
		else
			setCom(2, start.f_difficulty(2, offset))
		end
	elseif p2TeamMode == 1 and config.SimulMode then --Simul
		if main.p2In == 2 and not main.aiFight and not main.coop then
			setCom(2, 0)
		else
			setCom(2, start.f_difficulty(2, offset))
		end
		for i = 4, p2NumChars * 2 do
			if i % 2 == 0 then --even value
				remapInput(i, 2) --P4/6/8 character uses P2 controls
				setCom(i, start.f_difficulty(i, offset))
			end
		end
	elseif p2TeamMode == 2 then --Turns
		for i = 2, p2NumChars * 2 do
			if i % 2 == 0 then --even value
				if main.p2In == 2 and not main.aiFight and not main.coop then
					remapInput(i, 2) --P2/4/6/8 character uses P2 controls
					setCom(i, 0)
				else
					setCom(i, start.f_difficulty(i, offset))
				end
			end
		end
	else --p2TeamMode == 3 or (p2TeamMode == 1 and not config.SimulMode) --Tag
		for i = 2, p2NumChars * 2 do
			if i % 2 == 0 then --even value
				if main.p2In == 2 and not main.aiFight and not main.coop then
					remapInput(i, 2) --P2/4/6/8 character uses P2 controls
					setCom(i, 0)
				else
					setCom(i, start.f_difficulty(i, offset))
				end
			end
		end
	end
end

--sets lifebar, round time, rounds to win
local lifebar = motif.files.fight
function start.f_setRounds()
	--lifebar
	if main.t_charparam.lifebar and main.t_charparam.rivals and start.f_rivalsMatch('lifebar') then --lifebar assigned as rivals param
		lifebar = main.t_selChars[t_p1Selected[1].cel + 1].rivals[matchNo].lifebar:gsub('\\', '/')
	elseif main.t_charparam.lifebar and main.t_selChars[t_p2Selected[1].cel + 1].lifebar ~= nil then --lifebar assigned as character param
		lifebar = main.t_selChars[t_p2Selected[1].cel + 1].lifebar:gsub('\\', '/')
	else --default lifebar
		lifebar = motif.files.fight
	end
	if lifebar:lower() ~= main.currentLifebar:lower() then
		main.currentLifebar = lifebar
		loadLifebar(lifebar)
	end
	--round time
	if gameMode('training') then
		setRoundTime(-1)
	elseif main.t_charparam.time and main.t_charparam.rivals and start.f_rivalsMatch('time') then --round time assigned as rivals param
		setRoundTime(math.max(-1, main.t_selChars[t_p1Selected[1].cel + 1].rivals[matchNo].time * getFramesPerCount()))
	elseif main.t_charparam.time and main.t_selChars[t_p2Selected[1].cel + 1].time ~= nil then --round time assigned as character param
		setRoundTime(math.max(-1, main.t_selChars[t_p2Selected[1].cel + 1].time * getFramesPerCount()))
	else --default round time
		setRoundTime(math.max(-1, config.RoundTime * getFramesPerCount()))
	end
	--rounds to win
	if gameMode('survival') or gameMode('survivalcoop') or gameMode('netplaysurvivalcoop') or gameMode('100kumite') then --always 1 round to win in these modes
		setMatchWins(1)
		setMatchMaxDrawGames(0)
	else
		if main.t_charparam.rounds and main.t_charparam.rivals and start.f_rivalsMatch('rounds') then --round num assigned as rivals param
			setMatchWins(main.t_selChars[t_p1Selected[1].cel + 1].rivals[matchNo].rounds)
		elseif main.t_charparam.rounds and main.t_selChars[t_p2Selected[1].cel + 1].rounds ~= nil then --round num assigned as character param
			setMatchWins(main.t_selChars[t_p2Selected[1].cel + 1].rounds)
		elseif p2TeamMode == 0 then --default rounds num (Single mode)
			setMatchWins(options.roundsNumSingle)
		else --default rounds num (Team mode)
			setMatchWins(options.roundsNumTeam)
		end
		setMatchMaxDrawGames(options.maxDrawGames)
	end
end

--sets stage
function start.f_setStage(num)
	num = num or 0
	--stage
	if not main.stageMenu and not continueData then
		if main.t_charparam.stage and main.t_charparam.rivals and start.f_rivalsMatch('stage') then --stage assigned as rivals param
			num = math.random(1, #main.t_selChars[t_p1Selected[1].cel + 1].rivals[matchNo].stage)
			num = main.t_selChars[t_p1Selected[1].cel + 1].rivals[matchNo].stage[num]
		elseif main.t_charparam.stage and main.t_selChars[t_p2Selected[1].cel + 1].stage ~= nil then --stage assigned as character param
			num = math.random(1, #main.t_selChars[t_p2Selected[1].cel + 1].stage)
			num = main.t_selChars[t_p2Selected[1].cel + 1].stage[num]
		elseif (gameMode('arcade') or gameMode('teamcoop') or gameMode('netplayteamcoop')) and main.t_orderStages[main.t_selChars[t_p2Selected[1].cel + 1].order] ~= nil then --stage assigned as stage order param
			num = math.random(1, #main.t_orderStages[main.t_selChars[t_p2Selected[1].cel + 1].order])
			num = main.t_orderStages[main.t_selChars[t_p2Selected[1].cel + 1].order][num]
		else --stage randomly selected
			num = main.t_includeStage[1][math.random(1, #main.t_includeStage[1])]
		end
	end
	setStage(num)
	selectStage(num)
	--zoom
	local zoom = config.ZoomActive
	local zoomMin = config.ZoomMin
	local zoomMax = config.ZoomMax
	local zoomSpeed = config.ZoomSpeed
	if main.t_charparam.zoom and main.t_charparam.rivals and start.f_rivalsMatch('zoom') then --zoom assigned as rivals param
		if main.t_selChars[t_p1Selected[1].cel + 1].rivals[matchNo].zoom == 1 then
			zoom = true
		else
			zoom = false
		end
	elseif main.t_charparam.zoom and main.t_selChars[t_p2Selected[1].cel + 1].zoom ~= nil then --zoom assigned as character param
		if main.t_selChars[t_p2Selected[1].cel + 1].zoom == 1 then
			zoom = true
		else
			zoom = false
		end
	elseif main.t_selStages[num] ~= nil and main.t_selStages[num].zoom ~= nil then --zoom assigned as stage param
		if main.t_selStages[num].zoom == 1 then
			zoom = true
		else
			zoom = false
		end
	end
	if main.t_selStages[num] ~= nil then
		if main.t_selStages[num].zoommin ~= nil then
			zoomMin = main.t_selStages[num].zoommin
		end
		if main.t_selStages[num].zoommax ~= nil then
			zoomMax = main.t_selStages[num].zoommax
		end
		if main.t_selStages[num].zoomspeed ~= nil then
			zoomSpeed = main.t_selStages[num].zoomspeed
		end
	end
	setZoom(zoom)
	setZoomMin(zoomMin)
	setZoomMax(zoomMax)
	setZoomSpeed(zoomSpeed)
	--music
	local t = {'music', 'musicalt', 'musiclife'}
	for i = 1, #t do
		local track = 0
		local music = ''
		local volume = 100
		local loopstart = 0
		local loopend = 0
		if main.stageMenu then --game modes with stage selection screen
			if main.t_selStages[num] ~= nil and main.t_selStages[num][t[i]] ~= nil then --music assigned as stage param
				track = math.random(1, #main.t_selStages[num][t[i]])
				music = main.t_selStages[num][t[i]][track].bgmusic
				volume = main.t_selStages[num][t[i]][track].bgmvolume
				loopstart = main.t_selStages[num][t[i]][track].bgmloopstart
				loopend = main.t_selStages[num][t[i]][track].bgmloopend
			end
		elseif not gameMode('demo') or motif.demo_mode.fight_playbgm == 1 then --game modes other than demo (or demo with stage BGM param enabled)
			if main.t_charparam.music and main.t_charparam.rivals and start.f_rivalsMatch(t[i]) then --music assigned as rivals param
				track = math.random(1, #main.t_selChars[t_p1Selected[1].cel + 1].rivals[matchNo][t[i]])
				music = main.t_selChars[t_p1Selected[1].cel + 1].rivals[matchNo][t[i]][track].bgmusic
				volume = main.t_selChars[t_p1Selected[1].cel + 1].rivals[matchNo][t[i]][track].bgmvolume
				loopstart = main.t_selChars[t_p1Selected[1].cel + 1].rivals[matchNo][t[i]][track].bgmloopstart
				loopend = main.t_selChars[t_p1Selected[1].cel + 1].rivals[matchNo][t[i]][track].bgmloopend
			elseif main.t_charparam.music and main.t_selChars[t_p2Selected[1].cel + 1][t[i]] ~= nil then --music assigned as character param
				track = math.random(1, #main.t_selChars[t_p2Selected[1].cel + 1][t[i]])
				music = main.t_selChars[t_p2Selected[1].cel + 1][t[i]][track].bgmusic
				volume = main.t_selChars[t_p2Selected[1].cel + 1][t[i]][track].bgmvolume
				loopstart = main.t_selChars[t_p2Selected[1].cel + 1][t[i]][track].bgmloopstart
				loopend = main.t_selChars[t_p2Selected[1].cel + 1][t[i]][track].bgmloopend
			elseif main.t_selStages[num] ~= nil and main.t_selStages[num][t[i]] ~= nil then --music assigned as stage param
				track = math.random(1, #main.t_selStages[num][t[i]])
				music = main.t_selStages[num][t[i]][track].bgmusic
				volume = main.t_selStages[num][t[i]][track].bgmvolume
				loopstart = main.t_selStages[num][t[i]][track].bgmloopstart
				loopend = main.t_selStages[num][t[i]][track].bgmloopend
			end
		end
		if music ~= '' then
			setStageBGM(i - 1, music, volume, loopstart, loopend)
		end
	end
	return num
end

--remaps palette based on button press and character's keymap settings
function start.f_reampPal(cell, num)
	if main.t_selChars[cell + 1].pal_keymap[num] ~= nil then
		return main.t_selChars[cell + 1].pal_keymap[num]
	end
	return num
end

--returns palette number
function start.f_selectPal(cell)
	--prepare palette tables
	local t_assignedVals = {} --values = pal numbers already assigned
	local t_assignedKeys = {} --keys = pal numbers already assigned
	for i = 1, #t_p1Selected do
		if t_p1Selected[i].cel == cell then
			table.insert(t_assignedVals, start.f_reampPal(cell, t_p1Selected[i].pal))
			t_assignedKeys[t_assignedVals[#t_assignedVals]] = ''
		end
	end
	for i = 1, #t_p2Selected do
		if t_p2Selected[i].cel == cell then
			table.insert(t_assignedVals, start.f_reampPal(cell, t_p2Selected[i].pal))
			t_assignedKeys[t_assignedVals[#t_assignedVals]] = ''
		end
	end
	--return random palette
	if config.AIRandomColor then
		local t_uniqueVals = {} --values = pal numbers not assigned yet (or all if there are not enough pals for unique appearance of all characters)
		for i = 1, #main.t_selChars[cell + 1].pal do
			if t_assignedKeys[main.t_selChars[cell + 1].pal[i]] == nil or #t_assignedVals >= #main.t_selChars[cell + 1].pal then
				table.insert(t_uniqueVals, main.t_selChars[cell + 1].pal[i])
			end
		end
		if #t_uniqueVals > 0 then --return random unique palette
			return start.f_reampPal(cell, t_uniqueVals[math.random(1, #t_uniqueVals)])
		else --no unique palettes available, randomize from all palettes
			return main.t_selChars[cell + 1].pal[math.random(1, #main.t_selChars[cell + 1].pal)]
		end
	end
	--return first available default palette
	for i = 1, #main.t_selChars[cell + 1].pal_defaults do
		local d = main.t_selChars[cell + 1].pal_defaults[i]
		if t_assignedKeys[d] == nil then
			return start.f_reampPal(cell, d)
		end
	end
	--no default palettes available, force first default palette
	return start.f_reampPal(cell, main.t_selChars[cell + 1].pal_defaults[1])
end

--returns ratio level
local t_ratioArray = {
	{2, 1, 1},
	{1, 2, 1},
	{1, 1, 2},
	{2, 2},
	{3, 1},
	{1, 3},
	{4}
}
function start.f_setRatio(player)
	if player == 1 then
		if not p1Ratio then
			return nil
		end
		return t_ratioArray[p1NumRatio][#t_p1Selected + 1]
	end
	if not p2Ratio then
		return nil
	end
	if not continueData and not main.p2SelectMenu and #t_p2Selected == 0 then
		if p2NumChars == 3 then
			p2NumRatio = math.random(1, 3)
		elseif p2NumChars == 2 then
			p2NumRatio = math.random(4, 6)
		else
			p2NumRatio = 7
		end
	end
	return t_ratioArray[p2NumRatio][#t_p2Selected + 1]
end

--team modes enabling based on various factors
function start.f_getTeamMenu()
	local t = {}
	--Single mode
	if config.SingleTeamMode or (not gameMode('arcade') and not gameMode('versus')) or (gameMode('arcade') and motif.title_info.menu_itemname_arcade == '') or (gameMode('versus') and motif.title_info.menu_itemname_versus == '') then
		table.insert(t, {data = textImgNew(), itemname = 'single', displayname = motif.select_info.teammenu_itemname_single})
	end
	if config.SimulMode then --Simul mode enabled
		--Simul mode
		if config.NumSimul > 1 then
			table.insert(t, {data = textImgNew(), itemname = 'simul', displayname = motif.select_info.teammenu_itemname_simul})
		end
		--Tag mode
		if config.NumTag > 1 then
			table.insert(t, {data = textImgNew(), itemname = 'tag', displayname = motif.select_info.teammenu_itemname_tag})
		end
	elseif config.NumTag > 1 then --Legacy Tag mode enabled
		table.insert(t, {data = textImgNew(), itemname = 'simul', displayname = motif.select_info.teammenu_itemname_tag})
	end
	--Turns mode
	if config.NumTurns > 1 then
		table.insert(t, {data = textImgNew(), itemname = 'turns', displayname = motif.select_info.teammenu_itemname_turns})
	end
	--Ratio mode
	table.insert(t, {data = textImgNew(), itemname = 'ratio', displayname = motif.select_info.teammenu_itemname_ratio})
	return main.f_cleanTable(t, main.t_sort.select_info)
end

--sets life recovery and ratio level
function start.f_overrideCharData()
	--round 2+ in survival mode
	if matchNo >= 2 and (gameMode('survival') or gameMode('survivalcoop') or gameMode('netplaysurvivalcoop')) then
		local lastRound = #t_gameStats.chars
		local removedNum = 0
		local p1Count = 0
		--Turns
		if p1TeamMode == 2 then
			local t_p1Keys = {}
			--for each round in the last match
			for round = 1, #t_gameStats.chars do
				--remove character from team if he/she has been defeated
				if not t_gameStats.chars[round][1].win or t_gameStats.chars[round][1].ko then
					table.remove(t_p1Selected, t_gameStats.chars[round][1].memberNo + 1 - removedNum)
					removedNum = removedNum + 1
					p1NumChars = p1NumChars - 1
				--otherwise override character's next match life (done after all rounds have been checked)
				else
					t_p1Keys[t_gameStats.chars[round][1].memberNo] = t_gameStats.chars[round][1].life
				end
			end
			for k, v in pairs(t_p1Keys) do
				p1Count = p1Count + 1
				overrideCharData(p1Count, {['life'] = v})
			end
		--Single / Simul / Tag
		else
			--for each player data in the last round
			for player = 1, #t_gameStats.chars[lastRound] do
				--only check P1 side characters
				if player % 2 ~= 0 and player <= (p1NumChars + removedNum) * 2 then --odd value, team size check just in case
					--remove character from team if he/she has been defeated
					if not t_gameStats.chars[lastRound][player].win or t_gameStats.chars[lastRound][player].ko then
						table.remove(t_p1Selected, t_gameStats.chars[lastRound][player].memberNo + 1 - removedNum)
						removedNum = removedNum + 1
						p1NumChars = p1NumChars - 1
					--otherwise override character's next match life
					else
						if p1Count == 0 then
							p1Count = 1
						else
							p1Count = p1Count + 2
						end
						overrideCharData(p1Count, {['life'] = t_gameStats.chars[lastRound][player].life})
					end
				end
			end
		end
		if removedNum > 0 then
			setTeamMode(1, p1TeamMode, p1NumChars)
		end
	end
	--ratio level
	if p1Ratio then
		for i = 1, #t_p1Selected do
			setRatioLevel(i * 2 - 1, t_p1Selected[i].ratio)
			overrideCharData(i * 2 - 1, {['lifeRatio'] = config.LifeRatio[t_p1Selected[i].ratio]})
			overrideCharData(i * 2 - 1, {['attackRatio'] = config.AttackRatio[t_p1Selected[i].ratio]})
		end
	end
	if p2Ratio then
		for i = 1, #t_p2Selected do
			setRatioLevel(i * 2, t_p2Selected[i].ratio)
			overrideCharData(i * 2, {['lifeRatio'] = config.LifeRatio[t_p2Selected[i].ratio]})
			overrideCharData(i * 2, {['attackRatio'] = config.AttackRatio[t_p2Selected[i].ratio]})
		end
	end
end

--draws character names
function start.f_drawName(t, data, font, offsetX, offsetY, scaleX, scaleY, spacingX, spacingY, active_font, active_row)
	for i = 1, #t do
		local x = offsetX
		local f = font
		if active_font ~= nil and active_row ~= nil then
			if i == active_row then
				f = active_font
			else
				f = font
			end
		end
		if motif.font_data[f[1]] ~= -1 then
			main.f_updateTextImg(
				data,
				motif.font_data[f[1]],
				f[2],
				f[3],
				main.f_getName(t[i].cel),
				x + (i - 1) * spacingX,
				offsetY + (i - 1) * spacingY,
				scaleX,
				scaleY,
				f[4],
				f[5],
				f[6],
				f[7],
				f[8]
			)
			textImgDraw(data)
		end
	end
end

--returns correct cell position after moving the cursor
function start.f_cellMovement(selX, selY, cmd, faceOffset, rowOffset, snd)
	local tmpX = selX
	local tmpY = selY
	local tmpFace = faceOffset
	local tmpRow = rowOffset
	local found = false
	if commandGetState(cmd, 'u') then
		for i = 1, motif.select_info.rows + motif.select_info.rows_scrolling do
			selY = selY - 1
			if selY < 0 then
				if wrappingY then
					faceOffset = motif.select_info.rows_scrolling * motif.select_info.columns
					rowOffset = motif.select_info.rows_scrolling
					selY = motif.select_info.rows + motif.select_info.rows_scrolling - 1
				else
					faceOffset = tmpFace
					rowOffset = tmpRow
					selY = tmpY
				end
			elseif selY < rowOffset then
				faceOffset = faceOffset - motif.select_info.columns
				rowOffset = rowOffset - 1
			end
			if (t_grid[selY + 1][selX + 1].char ~= nil and t_grid[selY + 1][selX + 1].hidden ~= 2) or motif.select_info.moveoveremptyboxes == 1 then
				break
			elseif motif.select_info.searchemptyboxesup ~= 0 then
				found, selX = start.f_searchEmptyBoxes(motif.select_info.searchemptyboxesup, selX, selY)
				if found then
					break
				end
			end
		end
	elseif commandGetState(cmd, 'd') then
		for i = 1, motif.select_info.rows + motif.select_info.rows_scrolling do
			selY = selY + 1
			if selY >= motif.select_info.rows + motif.select_info.rows_scrolling then
				if wrappingY then
					faceOffset = 0
					rowOffset = 0
					selY = 0
				else
					faceOffset = tmpFace
					rowOffset = tmpRow
					selY = tmpY
				end
			elseif selY >= motif.select_info.rows + rowOffset then
				faceOffset = faceOffset + motif.select_info.columns
				rowOffset = rowOffset + 1
			end
			if (t_grid[selY + 1][selX + 1].char ~= nil and t_grid[selY + 1][selX + 1].hidden ~= 2) or motif.select_info.moveoveremptyboxes == 1 then
				break
			elseif motif.select_info.searchemptyboxesdown ~= 0 then
				found, selX = start.f_searchEmptyBoxes(motif.select_info.searchemptyboxesdown, selX, selY)
				if found then
					break
				end
			end
		end
	elseif commandGetState(cmd, 'l') then
		for i = 1, motif.select_info.columns do
			selX = selX - 1
			if selX < 0 then
				if wrappingX then
					selX = motif.select_info.columns - 1
				else
					selX = tmpX
				end
			end
			if (t_grid[selY + 1][selX + 1].char ~= nil and t_grid[selY + 1][selX + 1].hidden ~= 2) or motif.select_info.moveoveremptyboxes == 1 then
				break
			end
		end
	elseif commandGetState(cmd, 'r') then
		for i = 1, motif.select_info.columns do
			selX = selX + 1
			if selX >= motif.select_info.columns then
				if wrappingX then
					selX = 0
				else
					selX = tmpX
				end
			end
			if (t_grid[selY + 1][selX + 1].char ~= nil and t_grid[selY + 1][selX + 1].hidden ~= 2) or motif.select_info.moveoveremptyboxes == 1 then
				break
			end
		end
	end
	if tmpX ~= selX or tmpY ~= selY then
		resetgrid = true
		--if tmpRow ~= rowOffset then
			--start.f_resetGrid()
		--end
		sndPlay(motif.files.snd_data, snd[1], snd[2])
	end
	return selX, selY, faceOffset, rowOffset
end

--used by above function to find valid cell in case of dummy character entries
function start.f_searchEmptyBoxes(direction, x, y)
	local selX = x
	local selY = y
	local tmpX = x
	local found = false
	if direction > 0 then --right
		while true do
			x = x + 1
			if x >= motif.select_info.columns then
				x = tmpX
				break
			elseif t_grid[y + 1][x + 1].char ~= nil and t_grid[selY + 1][selX + 1].hidden ~= 2 then
				found = true
				break
			end
		end
	elseif direction < 0 then --left
		while true do
			x = x - 1
			if x < 0 then
				x = tmpX
				break
			elseif t_grid[y + 1][x + 1].char ~= nil and t_grid[selY + 1][selX + 1].hidden ~= 2 then
				found = true
				break
			end
		end
	end
	return found, x
end

--unlocks characters on select screen
function start.f_unlockChar(char, flag)
	--setHiddenFlag(char, flag) --not used for now
	main.t_selChars[char + 1].hidden = flag
	t_grid[main.t_selChars[char + 1].row][main.t_selChars[char + 1].col].hidden = flag
	start.f_resetGrid()
end

--generates table with cell coordinates
function start.f_resetGrid()
	start.t_drawFace = {}
	for row = 1, motif.select_info.rows do
		for col = 1, motif.select_info.columns do
			-- Note to anyone editing this function:
			-- The "elseif" chain is important if a "end" is added in the middle it could break the character icon display.
			
			--1Pのランダムセル表示位置 / 1P random cell display position
			if t_grid[row + p1RowOffset][col].char == 'randomselect' or t_grid[row + p1RowOffset][col].hidden == 3 then
				table.insert(start.t_drawFace, {d = 1, p1 = t_grid[row + p1RowOffset][col].num, p2 = t_grid[row + p2RowOffset][col].num, x1 = p1FaceX + t_grid[row][col].x, x2 = p2FaceX + t_grid[row][col].x, y1 = p1FaceY + t_grid[row][col].y, y2 = p2FaceY + t_grid[row][col].y})
			--1Pのキャラ表示位置 / 1P character display position
			elseif t_grid[row + p1RowOffset][col].char ~= nil and t_grid[row + p1RowOffset][col].hidden == 0 then
				table.insert(start.t_drawFace, {d = 2, p1 = t_grid[row + p1RowOffset][col].num, p2 = t_grid[row + p2RowOffset][col].num, x1 = p1FaceX + t_grid[row][col].x, x2 = p2FaceX + t_grid[row][col].x, y1 = p1FaceY + t_grid[row][col].y, y2 = p2FaceY + t_grid[row][col].y})
			--Empty boxes display position
			elseif motif.select_info.showemptyboxes == 1 then
				table.insert(start.t_drawFace, {d = 0, p1 = t_grid[row + p1RowOffset][col].num, p2 = t_grid[row + p2RowOffset][col].num, x1 = p1FaceX + t_grid[row][col].x, x2 = p2FaceX + t_grid[row][col].x, y1 = p1FaceY + t_grid[row][col].y, y2 = p2FaceY + t_grid[row][col].y})
			end
			
			--2Pのランダムセル表示位置 / 2P random cell display position
			if t_grid[row + p2RowOffset][col].char == 'randomselect' or t_grid[row + p2RowOffset][col].hidden == 3 then
				table.insert(start.t_drawFace, {d = 11, p1 = t_grid[row + p1RowOffset][col].num, p2 = t_grid[row + p2RowOffset][col].num, x1 = p1FaceX + t_grid[row][col].x, x2 = p2FaceX + t_grid[row][col].x, y1 = p1FaceY + t_grid[row][col].y, y2 = p2FaceY + t_grid[row][col].y}		)
			--2Pのキャラ表示位置 / 2P character display position
			elseif t_grid[row + p2RowOffset][col].char ~= nil and t_grid[row + p2RowOffset][col].hidden == 0 then
				table.insert(start.t_drawFace, {d = 12, p1 = t_grid[row + p1RowOffset][col].num, p2 = t_grid[row + p2RowOffset][col].num, x1 = p1FaceX + t_grid[row][col].x, x2 = p2FaceX + t_grid[row][col].x, y1 = p1FaceY + t_grid[row][col].y, y2 = p2FaceY + t_grid[row][col].y})
			--Empty boxes display position
			elseif motif.select_info.showemptyboxes == 1 then
				table.insert(start.t_drawFace, {d = 10, p1 = t_grid[row + p1RowOffset][col].num, p2 = t_grid[row + p2RowOffset][col].num, x1 = p1FaceX + t_grid[row][col].x, x2 = p2FaceX + t_grid[row][col].x, y1 = p1FaceY + t_grid[row][col].y, y2 = p2FaceY + t_grid[row][col].y})
			end
		end
	end
	main.f_printTable(start.t_drawFace, 'debug/t_drawFace.txt')
end

--sets correct start cell
function start.startCell()
	--starting row
	if motif.select_info.p1_cursor_startcell[1] < motif.select_info.rows then
		p1SelY = motif.select_info.p1_cursor_startcell[1]
	else
		p1SelY = 0
	end
	if motif.select_info.p2_cursor_startcell[1] < motif.select_info.rows then
		p2SelY = motif.select_info.p2_cursor_startcell[1]
	else
		p2SelY = 0
	end
	--starting column
	if motif.select_info.p1_cursor_startcell[2] < motif.select_info.columns then
		p1SelX = motif.select_info.p1_cursor_startcell[2]
	else
		p1SelX = 0
	end
	if motif.select_info.p2_cursor_startcell[2] < motif.select_info.columns then
		p2SelX = motif.select_info.p2_cursor_startcell[2]
	else
		p2SelX = 0
	end
end

--resets various data
function start.f_selectReset()
	if main.p2Faces and motif.select_info.double_select == 1 then
		p1FaceX = motif.select_info.pos_p1_double_select[1]
		p1FaceY = motif.select_info.pos_p1_double_select[2]
		p2FaceX = motif.select_info.pos_p2_double_select[1]
		p2FaceY = motif.select_info.pos_p2_double_select[2]
	else
		p1FaceX = motif.select_info.pos[1]
		p1FaceY = motif.select_info.pos[2]
		p2FaceX = motif.select_info.pos[1]
		p2FaceY = motif.select_info.pos[2]
	end
	start.f_resetGrid()
	if gameMode('netplayversus') or gameMode('netplayteamcoop') or gameMode('netplaysurvivalcoop') then
		p1TeamMode = 0
		p2TeamMode = 0
		stageNo = 0
		stageList = 0
	end
	start.t_p1TeamMenu = start.f_getTeamMenu()
	start.t_p2TeamMenu = start.f_getTeamMenu()
	p1Cell = nil
	p2Cell = nil
	t_p1Selected = {}
	t_p2Selected = {}
	p1TeamEnd = false
	p1SelEnd = false
	p1Ratio = false
	p2TeamEnd = false
	p2SelEnd = false
	p2Ratio = false
	if main.p2In == 1 then
		p2TeamEnd = true
		p2SelEnd = true
	elseif main.coop then
		p1TeamEnd = true
		p2TeamEnd = true
	end
	if not main.p2SelectMenu then
		p2SelEnd = true
	end
	selScreenEnd = false
	stageEnd = false
	coopEnd = false
	restoreTeam = false
	continueData = false
	p1NumChars = 1
	p2NumChars = 1
	winner = 0
	matchNo = 0
	setMatchNo(matchNo)
	resetRemapInput()
end

--;===========================================================
--; SIMPLE LOOP (VS MODE, TEAM VERSUS, TRAINING, WATCH, BONUS GAMES)
--;===========================================================
function start.f_selectSimple()
	start.startCell()
	t_p1Cursor = {}
	t_p2Cursor = {}
	p1RestoreCursor = false
	p2RestoreCursor = false
	p1TeamMenu = 1
	p2TeamMenu = 1
	p1FaceOffset = 0
	p2FaceOffset = 0
	p1RowOffset = 0
	p2RowOffset = 0
	stageList = 0
	main.f_cmdInput()
	while true do
		main.f_menuReset(motif.selectbgdef.bg, motif.music.select_bgm, motif.music.select_bgm_loop, motif.music.select_bgm_volume, motif.music.select_bgm_loopstart, motif.music.select_bgm_loopend)
		fadeType = 'fadein'
		start.f_selectReset()
		selectStart()
		timerSelect = 0
		while not selScreenEnd do
			if esc() then
				sndPlay(motif.files.snd_data, motif.select_info.cancel_snd[1], motif.select_info.cancel_snd[2])
				if not challenger then
					main.f_menuReset(motif.titlebgdef.bg, motif.music.title_bgm, motif.music.title_bgm_loop, motif.music.title_bgm_volume, motif.music.title_bgm_loopstart, motif.music.title_bgm_loopend)
					resetRemapInput()
				end
				return
			end
			start.f_selectScreen()
		end
		--fight initialization
		start.f_overrideCharData()
		start.f_remapAI()
		start.f_setRounds()
		stageNo = start.f_setStage(stageNo)
		start.f_selectVersus()
		if esc() then break end
		clearColor(motif.selectbgdef.bgclearcolor[1], motif.selectbgdef.bgclearcolor[2], motif.selectbgdef.bgclearcolor[3])
		loadStart()
		winner, t_gameStats = game()
		main.f_printTable(t_gameStats, 'debug/t_gameStats.txt')
		--victory screen
		if motif.victory_screen.vs_enabled == 1 and winner >= 1 and (gameMode('versus') or gameMode('netplayversus')) then
			start.f_selectVictory()
		end
		if challenger then
			break
		end
		main.f_cmdInput()
		refresh()
	end
end

--;===========================================================
--; ARRANGED LOOP (SURVIVAL, SURVIVAL CO-OP, VS 100 KUMITE, BOSS RUSH)
--;===========================================================
function start.f_selectArranged()
	start.startCell()
	t_p1Cursor = {}
	t_p2Cursor = {}
	p1RestoreCursor = false
	p2RestoreCursor = false
	challenger = false
	p1TeamMenu = 1
	p2TeamMenu = 1
	p1FaceOffset = 0
	p2FaceOffset = 0
	p1RowOffset = 0
	p2RowOffset = 0
	winCnt = 0
	looseCnt = 0
	stageList = 0
	main.f_cmdInput()
	start.f_selectReset()
	while true do
		main.f_menuReset(motif.selectbgdef.bg, motif.music.select_bgm, motif.music.select_bgm_loop, motif.music.select_bgm_volume, motif.music.select_bgm_loopstart, motif.music.select_bgm_loopend)
		fadeType = 'fadein'
		if winner == -1 then --player exit the match via ESC
			start.f_selectReset()
		end
		selectStart()
		timerSelect = 0
		while not selScreenEnd do
			if esc() then
				sndPlay(motif.files.snd_data, motif.select_info.cancel_snd[1], motif.select_info.cancel_snd[2])
				main.f_menuReset(motif.titlebgdef.bg, motif.music.title_bgm, motif.music.title_bgm_loop, motif.music.title_bgm_volume, motif.music.title_bgm_loopstart, motif.music.title_bgm_loopend)
				resetRemapInput()
				return
			end
			start.f_selectScreen()
		end
		--first match
		if matchNo == 0 then
			--coop swap
			if main.coop then
				p1TeamMode = 1
				p1NumChars = 2
				setTeamMode(1, p1TeamMode, p1NumChars)
				t_p1Selected[2] = {cel = t_p2Selected[1].cel, pal = t_p2Selected[1].pal}
				t_p2Selected = {}
			end
			--generate roster
			t_roster = start.f_makeRoster()
			lastMatch = #t_roster
			matchNo = 1
			--generate AI ramping table
			start.f_aiRamp(1)
		--player exit the match via ESC in VS 100 Kumite mode
		--[[elseif winner == -1 and gameMode('100kumite') then
			--counter
			looseCnt = looseCnt + 1
			--result
			start.f_result()
			--game over
			if motif.game_over_screen.enabled == 1 and main.f_fileExists(motif.game_over_screen.storyboard) then
				storyboard.f_storyboard(motif.game_over_screen.storyboard)
			end
			--intro
			if motif.files.intro_storyboard ~= '' then
				storyboard.f_storyboard(motif.files.intro_storyboard)
			end
			main.f_menuReset(motif.titlebgdef.bg, motif.music.title_bgm, motif.music.title_bgm_loop, motif.music.title_bgm_volume, motif.music.title_bgm_loopstart, motif.music.title_bgm_loopend)
			resetRemapInput()
			return]]
		--player won in any mode or lost/draw in VS 100 Kumite mode
		elseif winner == 1 or gameMode('100kumite') then
			--counter
			if winner == 1 then
				winCnt = winCnt + 1
			else
				looseCnt = looseCnt + 1
			end
			--infinite matches flag detected
			if t_roster[matchNo + 1] ~= nil and t_roster[matchNo + 1][1] == -1 then
				--remove flag
				table.remove(t_roster, matchNo + 1)
				--append entries to existing roster table
				t_roster = start.f_makeRoster(t_roster)
				local lastMatchRamp = lastMatch + 1
				lastMatch = #t_roster
				--append new entries to existing AI ramping table
				start.f_aiRamp(lastMatchRamp)
			end
			--no more matches left
			if matchNo == lastMatch then
				--result
				start.f_result()
				--credits
				if motif.end_credits.enabled == 1 and main.f_fileExists(motif.end_credits.storyboard) then
					storyboard.f_storyboard(motif.end_credits.storyboard)
				end
				--game over
				if motif.game_over_screen.enabled == 1 and main.f_fileExists(motif.game_over_screen.storyboard) then
					storyboard.f_storyboard(motif.game_over_screen.storyboard)
				end
				--intro
				if motif.files.intro_storyboard ~= '' then
					storyboard.f_storyboard(motif.files.intro_storyboard)
				end
				main.f_menuReset(motif.titlebgdef.bg, motif.music.title_bgm, motif.music.title_bgm_loop, motif.music.title_bgm_volume, motif.music.title_bgm_loopstart, motif.music.title_bgm_loopend)
				resetRemapInput()
				return
			--next match available
			else
				matchNo = matchNo + 1
				t_p2Selected = {}
			end
		--player lost
		else
			--counter
			looseCnt = looseCnt + 1
			--result
			start.f_result()
			--game over
			if motif.game_over_screen.enabled == 1 and main.f_fileExists(motif.game_over_screen.storyboard) then
				storyboard.f_storyboard(motif.game_over_screen.storyboard)
			end
			--intro
			if motif.files.intro_storyboard ~= '' then
				storyboard.f_storyboard(motif.files.intro_storyboard)
			end
			main.f_menuReset(motif.titlebgdef.bg, motif.music.title_bgm, motif.music.title_bgm_loop, motif.music.title_bgm_volume, motif.music.title_bgm_loopstart, motif.music.title_bgm_loopend)
			resetRemapInput()
			return
		end
		--assign enemy team
		--t_p2Selected = {}
		if #t_p2Selected == 0 then
			local shuffle = true
			for i = 1, #t_roster[matchNo] do
				p2Cell = t_roster[matchNo][i]
				table.insert(t_p2Selected, {cel = p2Cell, pal = start.f_selectPal(p2Cell), ratio = start.f_setRatio(2)})
				if shuffle then
					main.f_shuffleTable(t_p2Selected)
				end
			end
		end
		--fight initialization
		setMatchNo(matchNo)
		start.f_overrideCharData()
		start.f_remapAI()
		start.f_setRounds()
		stageNo = start.f_setStage(stageNo)
		start.f_selectVersus()
		if esc() then
			winner = -1
		else
			clearColor(motif.selectbgdef.bgclearcolor[1], motif.selectbgdef.bgclearcolor[2], motif.selectbgdef.bgclearcolor[3])
			loadStart()
			winner, t_gameStats = game()
			main.f_printTable(t_gameStats, 'debug/t_gameStats.txt')
		end
		resetRemapInput()
		main.f_cmdInput()
		refresh()
	end
end

--;===========================================================
--; ARCADE LOOP (ARCADE, TEAM ARCADE, TEAM CO-OP)
--;===========================================================
function start.f_selectArcade()
	start.startCell()
	t_p1Cursor = {}
	t_p2Cursor = {}
	p1RestoreCursor = false
	p2RestoreCursor = false
	challenger = false
	p1TeamMenu = 1
	p2TeamMenu = 1
	p1FaceOffset = 0
	p2FaceOffset = 0
	p1RowOffset = 0
	p2RowOffset = 0
	winCnt = 0
	looseCnt = 0
	main.f_cmdInput()
	start.f_selectReset()
	stageEnd = true
	local t_enemySelected = {}
	while true do
		main.f_menuReset(motif.selectbgdef.bg, motif.music.select_bgm, motif.music.select_bgm_loop, motif.music.select_bgm_volume, motif.music.select_bgm_loopstart, motif.music.select_bgm_loopend)
		fadeType = 'fadein'
		if winner == -1 then --player exit the match via ESC
			start.f_selectReset()
		end
		selectStart()
		timerSelect = 0
		while not selScreenEnd do
			if esc() then
				sndPlay(motif.files.snd_data, motif.select_info.cancel_snd[1], motif.select_info.cancel_snd[2])
				main.f_menuReset(motif.titlebgdef.bg, motif.music.title_bgm, motif.music.title_bgm_loop, motif.music.title_bgm_volume, motif.music.title_bgm_loopstart, motif.music.title_bgm_loopend)
				resetRemapInput()
				return
			end
			start.f_selectScreen()
		end
		--if last match was not against a challenger
		if not challenger then
			--first match
			if matchNo == 0 then
				--coop swap
				if main.coop then
					p1TeamMode = 1
					p1NumChars = 2
					setTeamMode(1, p1TeamMode, p1NumChars)
					t_p1Selected[2] = {cel = t_p2Selected[1].cel, pal = t_p2Selected[1].pal}
					t_p2Selected = {}
				end
				--generate roster
				t_roster = start.f_makeRoster()
				lastMatch = #t_roster
				matchNo = 1
				--generate AI ramping table
				start.f_aiRamp(1)
				--intro
				local tPos = main.t_selChars[t_p1Selected[1].cel + 1]
				if tPos.intro ~= nil and main.f_fileExists(tPos.intro) then
					storyboard.f_storyboard(tPos.intro)
				end
			--player won
			elseif winner == 1 then
				--counter
				winCnt = winCnt + 1
				--victory screen
				if motif.victory_screen.enabled == 1 then
					start.f_selectVictory()
				end
				--no more matches left
				if matchNo == lastMatch then
					--ending
					local tPos = main.t_selChars[t_p1Selected[1].cel + 1]
					if tPos.ending ~= nil and main.f_fileExists(tPos.ending) then
						storyboard.f_storyboard(tPos.ending)
					elseif motif.default_ending.enabled == 1 and main.f_fileExists(motif.default_ending.storyboard) then
						storyboard.f_storyboard(motif.default_ending.storyboard)
					end
					--credits
					if motif.end_credits.enabled == 1 and main.f_fileExists(motif.end_credits.storyboard) then
						storyboard.f_storyboard(motif.end_credits.storyboard)
					end
					--game over
					if motif.game_over_screen.enabled == 1 and main.f_fileExists(motif.game_over_screen.storyboard) then
						storyboard.f_storyboard(motif.game_over_screen.storyboard)
					end
					--intro
					if motif.files.intro_storyboard ~= '' then
						storyboard.f_storyboard(motif.files.intro_storyboard)
					end
					main.f_menuReset(motif.titlebgdef.bg, motif.music.title_bgm, motif.music.title_bgm_loop, motif.music.title_bgm_volume, motif.music.title_bgm_loopstart, motif.music.title_bgm_loopend)
					resetRemapInput()
					return
				--next match available
				else
					matchNo = matchNo + 1
					continueData = false
					t_p2Selected = {}
				end
			--player lost and doesn't have any credits left
			elseif main.credits == 0 then
				--counter
				looseCnt = looseCnt + 1
				--victory screen
				if motif.victory_screen.cpu_enabled == 1 and winner >= 2 then
					start.f_selectVictory()
				end
				--game over
				if motif.game_over_screen.enabled == 1 and main.f_fileExists(motif.game_over_screen.storyboard) then
					storyboard.f_storyboard(motif.game_over_screen.storyboard)
				end
				--intro
				if motif.files.intro_storyboard ~= '' then
					storyboard.f_storyboard(motif.files.intro_storyboard)
				end
				main.f_menuReset(motif.titlebgdef.bg, motif.music.title_bgm, motif.music.title_bgm_loop, motif.music.title_bgm_volume, motif.music.title_bgm_loopstart, motif.music.title_bgm_loopend)
				resetRemapInput()
				return
			--player lost but can continue
			else
				--counter
				looseCnt = looseCnt + 1
				--victory screen
				if motif.victory_screen.cpu_enabled == 1 and winner >= 2 then
					start.f_selectVictory()
				end
				--continue screen
				start.f_continue()
				if not continue then
					--game over
					if motif.continue_screen.external_gameover == 1 and main.f_fileExists(motif.game_over_screen.storyboard) then
						storyboard.f_storyboard(motif.game_over_screen.storyboard)
					end
					--intro
					if motif.files.intro_storyboard ~= '' then
						storyboard.f_storyboard(motif.files.intro_storyboard)
					end
					main.f_menuReset(motif.titlebgdef.bg, motif.music.title_bgm, motif.music.title_bgm_loop, motif.music.title_bgm_volume, motif.music.title_bgm_loopstart, motif.music.title_bgm_loopend)
					resetRemapInput()
					return
				end
				if not config.QuickContinue then --true if 'Quick Continue' option is disabled
					t_p1Selected = {}
					p1SelEnd = false
					if main.coop then
						p1NumChars = 1
						numChars = p2NumChars
						p2NumChars = 1
						t_p2Selected = {}
						p2SelEnd = false
					end
					fadeType = 'fadein'
					timerSelect = 0
					selScreenEnd = false
					while not selScreenEnd do
						if esc() then
							sndPlay(motif.files.snd_data, motif.select_info.cancel_snd[1], motif.select_info.cancel_snd[2])
							main.f_menuReset(motif.titlebgdef.bg, motif.music.title_bgm, motif.music.title_bgm_loop, motif.music.title_bgm_volume, motif.music.title_bgm_loopstart, motif.music.title_bgm_loopend)
							resetRemapInput()
							return
						end
						start.f_selectScreen()
					end
				elseif esc() then
					sndPlay(motif.files.snd_data, motif.select_info.cancel_snd[1], motif.select_info.cancel_snd[2])
					main.f_menuReset(motif.titlebgdef.bg, motif.music.title_bgm, motif.music.title_bgm_loop, motif.music.title_bgm_volume, motif.music.title_bgm_loopstart, motif.music.title_bgm_loopend)
					resetRemapInput()
					return
				end
				continueData = true
			end
			--coop swap
			if main.coop then
				if --[[winner == -1 or]] winner == 2 then
					p1NumChars = 2
					p2NumChars = numChars
					t_p1Selected[2] = {cel = t_p2Selected[1].cel, pal = t_p2Selected[1].pal}
					t_p2Selected = t_enemySelected
				end
			end
			--assign enemy team
			--t_p2Selected = {}
			if #t_p2Selected == 0 then
				if p2NumChars ~= #t_roster[matchNo] then
					p2NumChars = #t_roster[matchNo]
					setTeamMode(2, p2TeamMode, p2NumChars)
				end
				local shuffle = true
				for i = 1, #t_roster[matchNo] do
					if i == 1 and start.f_rivalsMatch('char_ref') then --enemy assigned as rivals param
						p2Cell = main.t_selChars[t_p1Selected[1].cel + 1].rivals[matchNo].char_ref
						shuffle = false
					else
						p2Cell = t_roster[matchNo][i]
					end
					table.insert(t_p2Selected, {cel = p2Cell, pal = start.f_selectPal(p2Cell), ratio = start.f_setRatio(2)})
					if shuffle then
						main.f_shuffleTable(t_p2Selected)
					end
				end
				t_enemySelected = main.f_copyTable(t_p2Selected)
			end
			--Team conversion to Single match if onlyme paramvalue on any opponents is detected
			if p2NumChars > 1 then
				for i = 1, #t_p2Selected do
					local onlyme = false
					if start.f_rivalsMatch('char_ref') and start.f_rivalsMatch('onlyme', 1) then --team conversion assigned as rivals param
						p2Cell = main.t_selChars[t_p1Selected[1].cel + 1].rivals[matchNo].char_ref
						onlyme = true
					elseif main.t_selChars[t_p2Selected[i].cel + 1].onlyme == 1 then --team conversion assigned as character param
						p2Cell = main.t_selChars[t_p2Selected[i].cel + 1].char_ref
						onlyme = true
					end
					if onlyme then
						teamMode = p2TeamMode
						numChars = p2NumChars
						p2TeamMode = 0
						p2NumChars = 1
						setTeamMode(2, p2TeamMode, p2NumChars)
						t_p2Selected = {}
						t_p2Selected[1] = {cel = p2Cell, pal = start.f_selectPal(p2Cell)}
						restoreTeam = true
						break
					end
				end
			end
		end
		--fight initialization
		challenger = false
		setMatchNo(matchNo)
		start.f_overrideCharData()
		start.f_remapAI()
		start.f_setRounds()
		stageNo = start.f_setStage(stageNo)
		start.f_selectVersus()
		if esc() then
			winner = -1
		else
			clearColor(motif.selectbgdef.bgclearcolor[1], motif.selectbgdef.bgclearcolor[2], motif.selectbgdef.bgclearcolor[3])
			loadStart()
			winner, t_gameStats = game()
			main.f_printTable(t_gameStats, 'debug/t_gameStats.txt')
			--here comes a new challenger
			if t_gameStats.challenger > 0 then
				start.f_challenger()
			end
			--restore P2 Team settings if needed
			if restoreTeam then
				p2TeamMode = teamMode
				p2NumChars = numChars
				setTeamMode(2, p2TeamMode, p2NumChars)
				restoreTeam = false
			end
		end
		resetRemapInput()
		main.f_cmdInput()
		refresh()
	end
end

function start.f_challenger()
	refresh() --needed to clean inputs
	challenger = true
	--save values
	local t_p1Selected_sav = main.f_copyTable(t_p1Selected)
	local t_p2Selected_sav = main.f_copyTable(t_p2Selected)
	local p1TeamMenu_sav = main.f_copyTable(main.p1TeamMenu)
	local p2TeamMenu_sav = main.f_copyTable(main.p2TeamMenu)
	local t_charparam_sav = main.f_copyTable(main.t_charparam)
	local p1Ratio_sav = p1Ratio
	local p2Ratio_sav = p2Ratio
	local p1NumRatio_sav = p1NumRatio
	local p2NumRatio_sav = p2NumRatio
	local p1Cell_sav = p1Cell
	local p2Cell_sav = p2Cell
	local matchNo_sav = matchNo
	local stageNo_sav = stageNo
	local restoreTeam_sav = restoreTeam
	local p1TeamMode_sav = p1TeamMode
	local p1NumChars_sav = p1NumChars
	local p2TeamMode_sav = p2TeamMode
	local p2NumChars_sav = p2NumChars
	local gameMode = gameMode()
	--temp mode data
	textImgSetText(main.txt_mainSelect, motif.select_info.title_text_teamversus)
	setHomeTeam(1)
	main.p2In = 2
	main.drawScore = {true, true}
	main.p2SelectMenu = true
	main.stageMenu = true
	main.p2Faces = true
	main.p1TeamMenu = nil
	main.p2TeamMenu = nil
	main.f_resetCharparam()
	setGameMode('teamversus')
	--start challenger match
	start.f_selectSimple()
	--restore mode data
	textImgSetText(main.txt_mainSelect, motif.select_info.title_text_arcade)
	setHomeTeam(2)
	main.p2In = 1
	main.drawScore = {true, false}
	main.p2SelectMenu = false
	main.stageMenu = false
	main.p2Faces = false
	main.p1TeamMenu = p1TeamMenu_sav
	main.p2TeamMenu = p2TeamMenu_sav
	main.t_charparam = t_charparam_sav
	setGameMode(gameMode)
	if esc() then
		challenger = false
		start.f_selectReset()
		return
	end
	if winner == 2 then
		--TODO: when player1 team loose continue playing the arcade mode as player2 team
	end
	--restore values
	p1TeamEnd = true
	p2TeamEnd = true
	p1SelEnd = true
	p2SelEnd = true
	t_p1Selected = t_p1Selected_sav
	t_p2Selected = t_p2Selected_sav
	p1Ratio = p1Ratio_sav
	p2Ratio = p2Ratio_sav
	p1NumRatio = p1NumRatio_sav
	p2NumRatio = p2NumRatio_sav
	p1Cell = p1Cell_sav
	p2Cell = p2Cell_sav
	matchNo = matchNo_sav
	stageNo = stageNo_sav
	restoreTeam = restoreTeam_sav
	p1TeamMode = p1TeamMode_sav
	p1NumChars = p1NumChars_sav
	setTeamMode(1, p1TeamMode, p1NumChars)
	p2TeamMode = p2TeamMode_sav
	p2NumChars = p2NumChars_sav
	setTeamMode(2, p2TeamMode, p2NumChars)
	continueData = true
end

--;===========================================================
--; TOURNAMENT LOOP
--;===========================================================
function start.f_selectTournament(size)
	start.startCell()
	t_p1Cursor = {}
	t_p2Cursor = {}
	p1RestoreCursor = false
	p2RestoreCursor = false
	challenger = false
	p1TeamMenu = 1
	p2TeamMenu = 1
	p1FaceOffset = 0
	p2FaceOffset = 0
	p1RowOffset = 0
	p2RowOffset = 0
	stageList = 0
	main.f_cmdInput()
	while true do
		main.f_menuReset(motif.tournamentbgdef.bg, motif.music.tournament_bgm, motif.music.tournament_bgm_loop, motif.music.tournament_bgm_volume, motif.music.tournament_bgm_loopstart, motif.music.tournament_bgm_loopend)
		fadeType = 'fadein'
		start.f_selectReset()
		while not selScreenEnd do
			if esc() then
				sndPlay(motif.files.snd_data, motif.select_info.cancel_snd[1], motif.select_info.cancel_snd[2])
				main.f_menuReset(motif.titlebgdef.bg, motif.music.title_bgm, motif.music.title_bgm_loop, motif.music.title_bgm_volume, motif.music.title_bgm_loopstart, motif.music.title_bgm_loopend)
				resetRemapInput()
				return
			end
			start.f_selectTournamentScreen(size)
		end
		--fight initialization
		start.f_overrideCharData()
		start.f_remapAI()
		start.f_setRounds()
		stageNo = start.f_setStage(stageNo)
		start.f_selectVersus()
		clearColor(motif.selectbgdef.bgclearcolor[1], motif.selectbgdef.bgclearcolor[2], motif.selectbgdef.bgclearcolor[3])
		loadStart()
		winner, t_gameStats = game()
		main.f_cmdInput()
		refresh()
	end
end

--;===========================================================
--; TOURNAMENT SCREEN
--;===========================================================
function start.f_selectTournamentScreen(size)
	--draw clearcolor
	clearColor(motif.tournamentbgdef.bgclearcolor[1], motif.tournamentbgdef.bgclearcolor[2], motif.tournamentbgdef.bgclearcolor[3])
	--draw layerno = 0 backgrounds
	bgDraw(motif.tournamentbgdef.bg, false)
	
	--draw layerno = 1 backgrounds
	bgDraw(motif.tournamentbgdef.bg, true)
	--draw fadein / fadeout
	main.fadeActive = fadeScreen(
		fadeType,
		main.fadeStart,
		motif.vs_screen[fadeType .. '_time'],
		motif.vs_screen[fadeType .. '_col'][1],
		motif.vs_screen[fadeType .. '_col'][2],
		motif.vs_screen[fadeType .. '_col'][3]
	)
	--frame transition
	if main.fadeActive then
		commandBufReset(main.p1Cmd)
	elseif fadeType == 'fadeout' then
		commandBufReset(main.p1Cmd)
		return --skip last frame rendering
	else
		main.f_cmdInput()
	end
	refresh()
end

--;===========================================================
--; SELECT SCREEN
--;===========================================================
local txt_timerSelect = main.f_createTextImg(
	motif.font_data[motif.select_info.timer_font[1]],
	motif.select_info.timer_font[2],
	motif.select_info.timer_font[3],
	'',
	motif.select_info.timer_offset[1],
	motif.select_info.timer_offset[2],
	motif.select_info.timer_font_scale[1],
	motif.select_info.timer_font_scale[2],
	motif.select_info.timer_font[4],
	motif.select_info.timer_font[5],
	motif.select_info.timer_font[6],
	motif.select_info.timer_font[7],
	motif.select_info.timer_font[8]
)
local txt_p1Name = main.f_createTextImg(
	motif.font_data[motif.select_info.p1_name_font[1]],
	motif.select_info.p1_name_font[2],
	motif.select_info.p1_name_font[3],
	'',
	0,
	0,
	motif.select_info.p1_name_font_scale[1],
	motif.select_info.p1_name_font_scale[2],
	motif.select_info.p1_name_font[4],
	motif.select_info.p1_name_font[5],
	motif.select_info.p1_name_font[6],
	motif.select_info.p1_name_font[7],
	motif.select_info.p1_name_font[8]
)
local p1RandomCount = 0
local p1RandomPortrait = 0
p1RandomPortrait = main.t_randomChars[math.random(1, #main.t_randomChars)]
local txt_p2Name = main.f_createTextImg(
	motif.font_data[motif.select_info.p2_name_font[1]],
	motif.select_info.p2_name_font[2],
	motif.select_info.p2_name_font[3],
	'',
	0,
	0,
	motif.select_info.p2_name_font_scale[1],
	motif.select_info.p2_name_font_scale[2],
	motif.select_info.p2_name_font[4],
	motif.select_info.p2_name_font[5],
	motif.select_info.p2_name_font[6],
	motif.select_info.p2_name_font[7],
	motif.select_info.p2_name_font[8]
)
local p2RandomCount = 0
local p2RandomPortrait = 0
p2RandomPortrait = main.t_randomChars[math.random(1, #main.t_randomChars)]

function start.f_alignOffset(align)
	if align == -1 then
		return 1 --fix for wrong offset after flipping sprites
	end
	return 0
end

function start.f_selectScreen()
	--draw clearcolor
	clearColor(motif.selectbgdef.bgclearcolor[1], motif.selectbgdef.bgclearcolor[2], motif.selectbgdef.bgclearcolor[3])
	--draw layerno = 0 backgrounds
	bgDraw(motif.selectbgdef.bg, false)
	--draw title
	textImgDraw(main.txt_mainSelect)
	if p1Cell then
		--draw p1 portrait
		local t_portrait = {}
		if #t_p1Selected < p1NumChars then
			if main.t_selChars[p1Cell + 1].char == 'randomselect' or main.t_selChars[p1Cell + 1].hidden == 3 then
				if p1RandomCount < motif.select_info.cell_random_switchtime then
					p1RandomCount = p1RandomCount + 1
				else
					p1RandomPortrait = main.t_randomChars[math.random(1, #main.t_randomChars)]
					p1RandomCount = 0
				end
				sndPlay(motif.files.snd_data, motif.select_info.p1_random_move_snd[1], motif.select_info.p1_random_move_snd[2])
				t_portrait[1] = p1RandomPortrait
			elseif main.t_selChars[p1Cell + 1].hidden ~= 2 then
				t_portrait[1] = p1Cell
			end
		end
		for i = #t_p1Selected, 1, -1 do
			if #t_portrait < motif.select_info.p1_face_num then
				table.insert(t_portrait, t_p1Selected[i].cel)
			end
		end
		t_portrait = main.f_reversedTable(t_portrait)
		for n = #t_portrait, 1, -1 do
			drawPortrait(
				t_portrait[n],
				motif.select_info.p1_face_offset[1] + motif.select_info['p1_c' .. n .. '_face_offset'][1] + (n - 1) * motif.select_info.p1_face_spacing[1] + start.f_alignOffset(motif.select_info.p1_face_facing),
				motif.select_info.p1_face_offset[2] + motif.select_info['p1_c' .. n .. '_face_offset'][2] + (n - 1) * motif.select_info.p1_face_spacing[2],
				motif.select_info.p1_face_facing * motif.select_info.p1_face_scale[1] * motif.select_info['p1_c' .. n .. '_face_scale'][1],
				motif.select_info.p1_face_scale[2] * motif.select_info['p1_c' .. n .. '_face_scale'][2]
			)
		end
	end
	if p2Cell then
		--draw p2 portrait
		local t_portrait = {}
		if #t_p2Selected < p2NumChars then
			if main.t_selChars[p2Cell + 1].char == 'randomselect' or main.t_selChars[p2Cell + 1].hidden == 3 then
				if p2RandomCount < motif.select_info.cell_random_switchtime then
					p2RandomCount = p2RandomCount + 1
				else
					p2RandomPortrait = main.t_randomChars[math.random(1, #main.t_randomChars)]
					p2RandomCount = 0
				end
				sndPlay(motif.files.snd_data, motif.select_info.p2_random_move_snd[1], motif.select_info.p2_random_move_snd[2])
				t_portrait[1] = p2RandomPortrait
			elseif main.t_selChars[p2Cell + 1].hidden ~= 2 then
				t_portrait[1] = p2Cell
			end
		end
		for i = #t_p2Selected, 1, -1 do
			if #t_portrait < motif.select_info.p2_face_num then
				table.insert(t_portrait, t_p2Selected[i].cel)
			end
		end
		t_portrait = main.f_reversedTable(t_portrait)
		for n = #t_portrait, 1, -1 do
			drawPortrait(
				t_portrait[n],
				motif.select_info.p2_face_offset[1] + motif.select_info['p2_c' .. n .. '_face_offset'][1] + (n - 1) * motif.select_info.p2_face_spacing[1] + start.f_alignOffset(motif.select_info.p2_face_facing),
				motif.select_info.p2_face_offset[2] + motif.select_info['p2_c' .. n .. '_face_offset'][2] + (n - 1) * motif.select_info.p2_face_spacing[2],
				motif.select_info.p2_face_facing * motif.select_info.p2_face_scale[1] * motif.select_info['p2_c' .. n .. '_face_scale'][1],
				motif.select_info.p2_face_scale[2] * motif.select_info['p2_c' .. n .. '_face_scale'][2]
			)
		end
	end
	--draw cell art (slow for large rosters, this will be likely moved to 'drawFace' function in future)
	for i = 1, #start.t_drawFace do
		-- Let's check if is on the P1 side before drawing the background.
		if start.t_drawFace[i].d == 1 or start.t_drawFace[i].d == 2 or start.t_drawFace[i].d == 0 then
			main.f_animPosDraw(motif.select_info.cell_bg_data, start.t_drawFace[i].x1, start.t_drawFace[i].y1) --draw cell background
		end
		
		if start.t_drawFace[i].d == 1 then --draw random cell
			main.f_animPosDraw(motif.select_info.cell_random_data, start.t_drawFace[i].x1, start.t_drawFace[i].y1)
		elseif start.t_drawFace[i].d == 2 then --draw face cell
			drawSmallPortrait(start.t_drawFace[i].p1, start.t_drawFace[i].x1, start.t_drawFace[i].y1, motif.select_info.portrait_scale[1], motif.select_info.portrait_scale[2])
		end
		--P2 side grid enabled
		if main.p2Faces and motif.select_info.double_select == 1 then
			-- Let's check if is on the P2 side before drawing the background.
			if start.t_drawFace[i].d == 11 or start.t_drawFace[i].d == 12 or start.t_drawFace[i].d == 10 then 
				main.f_animPosDraw(motif.select_info.cell_bg_data, start.t_drawFace[i].x2, start.t_drawFace[i].y2) --draw cell background
			end

			if start.t_drawFace[i].d == 11 then --draw random cell
				main.f_animPosDraw(motif.select_info.cell_random_data, start.t_drawFace[i].x2, start.t_drawFace[i].y2)
			elseif start.t_drawFace[i].d == 12 then --draw face cell
				drawSmallPortrait(start.t_drawFace[i].p2, start.t_drawFace[i].x2, start.t_drawFace[i].y2, motif.select_info.portrait_scale[1], motif.select_info.portrait_scale[2])
			end
		end
	end
	--drawFace(p1FaceX, p1FaceY, p1FaceOffset)
	--if main.p2Faces and motif.select_info.double_select == 1 then
	--	drawFace(p2FaceX, p2FaceY, p2FaceOffset)
	--end
	--draw p1 done cursor
	for i = 1, #t_p1Selected do
		if t_p1Selected[i].cursor ~= nil then
			main.f_animPosDraw(motif.select_info.p1_cursor_done_data, t_p1Selected[i].cursor[1], t_p1Selected[i].cursor[2])
		end
	end
	--draw p2 done cursor
	for i = 1, #t_p2Selected do
		if t_p2Selected[i].cursor ~= nil then
			main.f_animPosDraw(motif.select_info.p2_cursor_done_data, t_p2Selected[i].cursor[1], t_p2Selected[i].cursor[2])
		end
	end
	--Player1 team menu
	if not p1TeamEnd then
		start.f_p1TeamMenu()
	--Player1 select
	elseif main.p1In > 0 or main.p1Char ~= nil then
		start.f_p1SelectMenu()
	end
	--Player2 team menu
	if not p2TeamEnd then
		start.f_p2TeamMenu()
	--Player2 select
	elseif main.p2In > 0 or main.p2Char ~= nil then
		start.f_p2SelectMenu()
	end
	if p1Cell then
		--draw p1 name
		if #t_p1Selected < p1NumChars then
			textImgSetText(txt_p1Name, main.f_getName(p1Cell))
			main.f_textImgPosDraw(
				txt_p1Name,
				motif.select_info.p1_name_offset[1] + #t_p1Selected * motif.select_info.p1_name_spacing[1],
				motif.select_info.p1_name_offset[2] + #t_p1Selected * motif.select_info.p1_name_spacing[2],
				motif.select_info.p1_name_font[3]
			)
		end
		start.f_drawName(
			t_p1Selected,
			txt_p1Name,
			motif.select_info.p1_name_font,
			motif.select_info.p1_name_offset[1],
			motif.select_info.p1_name_offset[2],
			motif.select_info.p1_name_font_scale[1],
			motif.select_info.p1_name_font_scale[2],
			motif.select_info.p1_name_spacing[1],
			motif.select_info.p1_name_spacing[2]
		)
	end
	if p2Cell then
		--draw p2 name
		if #t_p2Selected < p2NumChars then
			textImgSetText(txt_p2Name, main.f_getName(p2Cell))
			main.f_textImgPosDraw(
				txt_p2Name,
				motif.select_info.p2_name_offset[1] + #t_p2Selected * motif.select_info.p2_name_spacing[1],
				motif.select_info.p2_name_offset[2] + #t_p2Selected * motif.select_info.p2_name_spacing[2],
				motif.select_info.p2_name_font[3]
			)
		end
		start.f_drawName(
			t_p2Selected,
			txt_p2Name,
			motif.select_info.p2_name_font,
			motif.select_info.p2_name_offset[1],
			motif.select_info.p2_name_offset[2],
			motif.select_info.p2_name_font_scale[1],
			motif.select_info.p2_name_font_scale[2],
			motif.select_info.p2_name_spacing[1],
			motif.select_info.p2_name_spacing[2]
		)
	end
	--draw timer
	if motif.select_info.timer_enabled == 1 and p1TeamEnd and (p2TeamEnd or not main.p2SelectMenu) then
		local num = math.floor((motif.select_info.timer_count * motif.select_info.timer_framespercount - timerSelect + motif.select_info.timer_displaytime) / motif.select_info.timer_framespercount + 0.5)
		if num <= -1 then
			timerSelect = -1
			textImgSetText(txt_timerSelect, 0)
		else
			timerSelect = timerSelect + 1
			textImgSetText(txt_timerSelect, math.max(0, num))
		end
		if timerSelect >= motif.select_info.timer_displaytime then
			textImgDraw(txt_timerSelect)
		end
	end
	--team and character selection complete
	if p1SelEnd and p2SelEnd and p1TeamEnd and p2TeamEnd then
		p1RestoreCursor = true
		p2RestoreCursor = true
		if main.stageMenu and not stageEnd then --Stage select
			start.f_stageMenu()
		elseif main.coop and not coopEnd then
			coopEnd = true
			p2TeamEnd = false
		elseif fadeType == 'fadein' then
			main.fadeStart = getFrameCount()
			fadeType = 'fadeout'
		elseif not main.fadeActive then
			selScreenEnd = true
		end
	end
	--draw layerno = 1 backgrounds
	bgDraw(motif.selectbgdef.bg, true)
	--draw fadein / fadeout
	main.fadeActive = fadeScreen(
		fadeType,
		main.fadeStart,
		motif.select_info[fadeType .. '_time'],
		motif.select_info[fadeType .. '_col'][1],
		motif.select_info[fadeType .. '_col'][2],
		motif.select_info[fadeType .. '_col'][3]
	)
	--frame transition
	if main.fadeActive then
		commandBufReset(main.p1Cmd)
	elseif fadeType == 'fadeout' then
		commandBufReset(main.p1Cmd)
		return --skip last frame rendering
	else
		main.f_cmdInput()
	end
	refresh()
end

--;===========================================================
--; PLAYER 1 TEAM MENU
--;===========================================================
local txt_p1TeamSelfTitle = main.f_createTextImg(
	motif.font_data[motif.select_info.p1_teammenu_selftitle_font[1]],
	motif.select_info.p1_teammenu_selftitle_font[2],
	motif.select_info.p1_teammenu_selftitle_font[3],
	motif.select_info.p1_teammenu_selftitle_text,
	motif.select_info.p1_teammenu_pos[1] + motif.select_info.p1_teammenu_selftitle_offset[1],
	motif.select_info.p1_teammenu_pos[2] + motif.select_info.p1_teammenu_selftitle_offset[2],
	motif.select_info.p1_teammenu_selftitle_font_scale[1],
	motif.select_info.p1_teammenu_selftitle_font_scale[2],
	motif.select_info.p1_teammenu_selftitle_font[4],
	motif.select_info.p1_teammenu_selftitle_font[5],
	motif.select_info.p1_teammenu_selftitle_font[6],
	motif.select_info.p1_teammenu_selftitle_font[7],
	motif.select_info.p1_teammenu_selftitle_font[8]
)
local txt_p1TeamEnemyTitle = main.f_createTextImg(
	motif.font_data[motif.select_info.p1_teammenu_enemytitle_font[1]],
	motif.select_info.p1_teammenu_enemytitle_font[2],
	motif.select_info.p1_teammenu_enemytitle_font[3],
	motif.select_info.p1_teammenu_enemytitle_text,
	motif.select_info.p1_teammenu_pos[1] + motif.select_info.p1_teammenu_enemytitle_offset[1],
	motif.select_info.p1_teammenu_pos[2] + motif.select_info.p1_teammenu_enemytitle_offset[2],
	motif.select_info.p1_teammenu_enemytitle_font_scale[1],
	motif.select_info.p1_teammenu_enemytitle_font_scale[2],
	motif.select_info.p1_teammenu_enemytitle_font[4],
	motif.select_info.p1_teammenu_enemytitle_font[5],
	motif.select_info.p1_teammenu_enemytitle_font[6],
	motif.select_info.p1_teammenu_enemytitle_font[7],
	motif.select_info.p1_teammenu_enemytitle_font[8]
)

local p1TeamActiveCount = 0
local p1TeamActiveFont = 'p1_teammenu_item_active_font'

function start.f_p1TeamMenu()
	if #t_p1Cursor > 0 then
		t_p1Cursor = {}
	end
	if main.p1TeamMenu ~= nil then --Predefined team
		p1TeamMode = main.p1TeamMenu.mode
		p1NumChars = main.p1TeamMenu.chars
		setTeamMode(1, p1TeamMode, p1NumChars)
		if main.p1TeamMenu.ratio ~= nil and p1TeamMode == 2 then
			p1NumRatio = main.p1TeamMenu.ratio
			p1Ratio = true
		end
		p1TeamEnd = true
	else
		--Calculate team cursor position
		if commandGetState(main.p1Cmd, 'u') then
			if p1TeamMenu > 1 then
				sndPlay(motif.files.snd_data, motif.select_info.p1_teammenu_move_snd[1], motif.select_info.p1_teammenu_move_snd[2])
				p1TeamMenu = p1TeamMenu - 1
			elseif motif.select_info.teammenu_move_wrapping == 1 then
				sndPlay(motif.files.snd_data, motif.select_info.p1_teammenu_move_snd[1], motif.select_info.p1_teammenu_move_snd[2])
				p1TeamMenu = #start.t_p1TeamMenu
			end
		elseif commandGetState(main.p1Cmd, 'd') then
			if p1TeamMenu < #start.t_p1TeamMenu then
				sndPlay(motif.files.snd_data, motif.select_info.p1_teammenu_move_snd[1], motif.select_info.p1_teammenu_move_snd[2])
				p1TeamMenu = p1TeamMenu + 1
			elseif motif.select_info.teammenu_move_wrapping == 1 then
				sndPlay(motif.files.snd_data, motif.select_info.p1_teammenu_move_snd[1], motif.select_info.p1_teammenu_move_snd[2])
				p1TeamMenu = 1
			end
		elseif start.t_p1TeamMenu[p1TeamMenu].itemname == 'simul' then
			if commandGetState(main.p1Cmd, 'l') then
				if p1NumSimul > 2 then
					sndPlay(motif.files.snd_data, motif.select_info.p1_teammenu_value_snd[1], motif.select_info.p1_teammenu_value_snd[2])
					p1NumSimul = p1NumSimul - 1
				end
			elseif commandGetState(main.p1Cmd, 'r') then
				if p1NumSimul < config.NumSimul then
					sndPlay(motif.files.snd_data, motif.select_info.p1_teammenu_value_snd[1], motif.select_info.p1_teammenu_value_snd[2])
					p1NumSimul = p1NumSimul + 1
				end
			end
		elseif start.t_p1TeamMenu[p1TeamMenu].itemname == 'turns' then
			if commandGetState(main.p1Cmd, 'l') then
				if p1NumTurns > 1 then
					sndPlay(motif.files.snd_data, motif.select_info.p1_teammenu_value_snd[1], motif.select_info.p1_teammenu_value_snd[2])
					p1NumTurns = p1NumTurns - 1
				end
			elseif commandGetState(main.p1Cmd, 'r') then
				if p1NumTurns < config.NumTurns then
					sndPlay(motif.files.snd_data, motif.select_info.p1_teammenu_value_snd[1], motif.select_info.p1_teammenu_value_snd[2])
					p1NumTurns = p1NumTurns + 1
				end
			end
		elseif start.t_p1TeamMenu[p1TeamMenu].itemname == 'tag' then
			if commandGetState(main.p1Cmd, 'l') then
				if p1NumTag > 2 then
					sndPlay(motif.files.snd_data, motif.select_info.p1_teammenu_value_snd[1], motif.select_info.p1_teammenu_value_snd[2])
					p1NumTag = p1NumTag - 1
				end
			elseif commandGetState(main.p1Cmd, 'r') then
				if p1NumTag < config.NumTag then
					sndPlay(motif.files.snd_data, motif.select_info.p1_teammenu_value_snd[1], motif.select_info.p1_teammenu_value_snd[2])
					p1NumTag = p1NumTag + 1
				end
			end
		elseif start.t_p1TeamMenu[p1TeamMenu].itemname == 'ratio' then
			if commandGetState(main.p1Cmd, 'l') then
				sndPlay(motif.files.snd_data, motif.select_info.p1_teammenu_value_snd[1], motif.select_info.p1_teammenu_value_snd[2])
				if p1NumRatio > 1 then
					p1NumRatio = p1NumRatio - 1
				else
					p1NumRatio = 7
				end
			elseif commandGetState(main.p1Cmd, 'r') then
				sndPlay(motif.files.snd_data, motif.select_info.p1_teammenu_value_snd[1], motif.select_info.p1_teammenu_value_snd[2])
				if p1NumRatio < 7 then
					p1NumRatio = p1NumRatio + 1
				else
					p1NumRatio = 1
				end
			end
		end
		--Draw team background
		animUpdate(motif.select_info.p1_teammenu_bg_data)
		animDraw(motif.select_info.p1_teammenu_bg_data)
		--Draw team active element background
		animUpdate(motif.select_info['p1_teammenu_bg_' .. start.t_p1TeamMenu[p1TeamMenu].itemname .. '_data'])
		animDraw(motif.select_info['p1_teammenu_bg_' .. start.t_p1TeamMenu[p1TeamMenu].itemname .. '_data'])
		--Draw team cursor
		main.f_animPosDraw(
			motif.select_info.p1_teammenu_item_cursor_data,
			(p1TeamMenu - 1) * motif.select_info.p1_teammenu_item_spacing[1],
			(p1TeamMenu - 1) * motif.select_info.p1_teammenu_item_spacing[2]
		)
		--Draw team title
		animUpdate(motif.select_info.p1_teammenu_selftitle_data)
		animDraw(motif.select_info.p1_teammenu_selftitle_data)
		textImgDraw(txt_p1TeamSelfTitle)
		for i = 1, #start.t_p1TeamMenu do
			if i == p1TeamMenu then
				if p1TeamActiveCount < 2 then --delay change
					p1TeamActiveCount = p1TeamActiveCount + 1
				elseif p1TeamActiveFont == 'p1_teammenu_item_active_font' then
					p1TeamActiveFont = 'p1_teammenu_item_active2_font'
					p1TeamActiveCount = 0
				else
					p1TeamActiveFont = 'p1_teammenu_item_active_font'
					p1TeamActiveCount = 0
				end
				--Draw team active font
				textImgDraw(main.f_updateTextImg(
					start.t_p1TeamMenu[i].data,
					motif.font_data[motif.select_info[p1TeamActiveFont][1]],
					motif.select_info[p1TeamActiveFont][2],
					motif.select_info[p1TeamActiveFont][3], --p1_teammenu_item_font (winmugen ignores active font facing? Fixed in mugen 1.0)
					start.t_p1TeamMenu[i].displayname,
					motif.select_info.p1_teammenu_pos[1] + motif.select_info.p1_teammenu_item_offset[1] + motif.select_info.p1_teammenu_item_font_offset[1] + motif.select_info.p1_teammenu_item_spacing[1] * (i - 1),
					motif.select_info.p1_teammenu_pos[2] + motif.select_info.p1_teammenu_item_offset[2] + motif.select_info.p1_teammenu_item_font_offset[2] + motif.select_info.p1_teammenu_item_spacing[2] * (i - 1),
					motif.select_info[p1TeamActiveFont .. '_scale'][1],
					motif.select_info[p1TeamActiveFont .. '_scale'][2],
					motif.select_info[p1TeamActiveFont][4],
					motif.select_info[p1TeamActiveFont][5],
					motif.select_info[p1TeamActiveFont][6],
					motif.select_info[p1TeamActiveFont][7],
					motif.select_info[p1TeamActiveFont][8]
				))
			else
				--Draw team not active font
				textImgDraw(main.f_updateTextImg(
					start.t_p1TeamMenu[i].data,
					motif.font_data[motif.select_info.p1_teammenu_item_font[1]],
					motif.select_info.p1_teammenu_item_font[2],
					motif.select_info.p1_teammenu_item_font[3],
					start.t_p1TeamMenu[i].displayname,
					motif.select_info.p1_teammenu_pos[1] + motif.select_info.p1_teammenu_item_offset[1] + motif.select_info.p1_teammenu_item_font_offset[1] + motif.select_info.p1_teammenu_item_spacing[1] * (i - 1),
					motif.select_info.p1_teammenu_pos[2] + motif.select_info.p1_teammenu_item_offset[2] + motif.select_info.p1_teammenu_item_font_offset[2] + motif.select_info.p1_teammenu_item_spacing[2] * (i - 1),
					motif.select_info.p1_teammenu_item_font_scale[1],
					motif.select_info.p1_teammenu_item_font_scale[2],
					motif.select_info.p1_teammenu_item_font[4],
					motif.select_info.p1_teammenu_item_font[5],
					motif.select_info.p1_teammenu_item_font[6],
					motif.select_info.p1_teammenu_item_font[7],
					motif.select_info.p1_teammenu_item_font[8]
				))
			end
			--Draw team icons
			if start.t_p1TeamMenu[i].itemname == 'simul' then
				for j = 1, config.NumSimul do
					if j <= p1NumSimul then
						main.f_animPosDraw(
							motif.select_info.p1_teammenu_value_icon_data,
							(i - 1) * motif.select_info.p1_teammenu_item_spacing[1] + (j - 1) * motif.select_info.p1_teammenu_value_spacing[1],
							(i - 1) * motif.select_info.p1_teammenu_item_spacing[2] + (j - 1) * motif.select_info.p1_teammenu_value_spacing[2]
						)
					else
						main.f_animPosDraw(
							motif.select_info.p1_teammenu_value_empty_icon_data,
							(i - 1) * motif.select_info.p1_teammenu_item_spacing[1] + (j - 1) * motif.select_info.p1_teammenu_value_spacing[1],
							(i - 1) * motif.select_info.p1_teammenu_item_spacing[2] + (j - 1) * motif.select_info.p1_teammenu_value_spacing[2]
						)
					end
				end
			elseif start.t_p1TeamMenu[i].itemname == 'turns' then
				for j = 1, config.NumTurns do
					if j <= p1NumTurns then
						main.f_animPosDraw(
							motif.select_info.p1_teammenu_value_icon_data,
							(i - 1) * motif.select_info.p1_teammenu_item_spacing[1] + (j - 1) * motif.select_info.p1_teammenu_value_spacing[1],
							(i - 1) * motif.select_info.p1_teammenu_item_spacing[2] + (j - 1) * motif.select_info.p1_teammenu_value_spacing[2]
						)
					else
						main.f_animPosDraw(
							motif.select_info.p1_teammenu_value_empty_icon_data,
							(i - 1) * motif.select_info.p1_teammenu_item_spacing[1] + (j - 1) * motif.select_info.p1_teammenu_value_spacing[1],
							(i - 1) * motif.select_info.p1_teammenu_item_spacing[2] + (j - 1) * motif.select_info.p1_teammenu_value_spacing[2]
						)
					end
				end
			elseif start.t_p1TeamMenu[i].itemname == 'tag' then
				for j = 1, config.NumTag do
					if j <= p1NumTag then
						main.f_animPosDraw(
							motif.select_info.p1_teammenu_value_icon_data,
							(i - 1) * motif.select_info.p1_teammenu_item_spacing[1] + (j - 1) * motif.select_info.p1_teammenu_value_spacing[1],
							(i - 1) * motif.select_info.p1_teammenu_item_spacing[2] + (j - 1) * motif.select_info.p1_teammenu_value_spacing[2]
						)
					else
						main.f_animPosDraw(
							motif.select_info.p1_teammenu_value_empty_icon_data,
							(i - 1) * motif.select_info.p1_teammenu_item_spacing[1] + (j - 1) * motif.select_info.p1_teammenu_value_spacing[1],
							(i - 1) * motif.select_info.p1_teammenu_item_spacing[2] + (j - 1) * motif.select_info.p1_teammenu_value_spacing[2]
						)
					end
				end
			elseif start.t_p1TeamMenu[i].itemname == 'ratio' and p1TeamMenu == i then
				animUpdate(motif.select_info['p1_teammenu_ratio' .. p1NumRatio .. '_icon_data'])
				animDraw(motif.select_info['p1_teammenu_ratio' .. p1NumRatio .. '_icon_data'])
			end
		end
		--Confirmed team selection
		if main.f_btnPalNo(main.p1Cmd) > 0 then
			sndPlay(motif.files.snd_data, motif.select_info.p1_teammenu_done_snd[1], motif.select_info.p1_teammenu_done_snd[2])
			if start.t_p1TeamMenu[p1TeamMenu].itemname == 'single' then
				p1TeamMode = 0
				p1NumChars = 1
			elseif start.t_p1TeamMenu[p1TeamMenu].itemname == 'simul' then
				p1TeamMode = 1
				p1NumChars = p1NumSimul
			elseif start.t_p1TeamMenu[p1TeamMenu].itemname == 'turns' then
				p1TeamMode = 2
				p1NumChars = p1NumTurns
			elseif start.t_p1TeamMenu[p1TeamMenu].itemname == 'tag' then
				p1TeamMode = 3
				p1NumChars = p1NumTag
			elseif start.t_p1TeamMenu[p1TeamMenu].itemname == 'ratio' then
				p1TeamMode = 2
				if p1NumRatio <= 3 then
					p1NumChars = 3
				elseif p1NumRatio <= 6 then
					p1NumChars = 2
				else
					p1NumChars = 1
				end
				p1Ratio = true
			end
			setTeamMode(1, p1TeamMode, p1NumChars)
			p1TeamEnd = true
			main.f_cmdInput()
		end
	end
end

--;===========================================================
--; PLAYER 2 TEAM MENU
--;===========================================================
local txt_p2TeamSelfTitle = main.f_createTextImg(
	motif.font_data[motif.select_info.p2_teammenu_selftitle_font[1]],
	motif.select_info.p2_teammenu_selftitle_font[2],
	motif.select_info.p2_teammenu_selftitle_font[3],
	motif.select_info.p2_teammenu_selftitle_text,
	motif.select_info.p2_teammenu_pos[1] + motif.select_info.p2_teammenu_selftitle_offset[1],
	motif.select_info.p2_teammenu_pos[2] + motif.select_info.p2_teammenu_selftitle_offset[2],
	motif.select_info.p2_teammenu_selftitle_font_scale[1],
	motif.select_info.p2_teammenu_selftitle_font_scale[2],
	motif.select_info.p2_teammenu_selftitle_font[4],
	motif.select_info.p2_teammenu_selftitle_font[5],
	motif.select_info.p2_teammenu_selftitle_font[6],
	motif.select_info.p2_teammenu_selftitle_font[7],
	motif.select_info.p2_teammenu_selftitle_font[8]
)
local txt_p2TeamEnemyTitle = main.f_createTextImg(
	motif.font_data[motif.select_info.p2_teammenu_enemytitle_font[1]],
	motif.select_info.p2_teammenu_enemytitle_font[2],
	motif.select_info.p2_teammenu_enemytitle_font[3],
	motif.select_info.p2_teammenu_enemytitle_text,
	motif.select_info.p2_teammenu_pos[1] + motif.select_info.p2_teammenu_enemytitle_offset[1],
	motif.select_info.p2_teammenu_pos[2] + motif.select_info.p2_teammenu_enemytitle_offset[2],
	motif.select_info.p2_teammenu_enemytitle_font_scale[1],
	motif.select_info.p2_teammenu_enemytitle_font_scale[2],
	motif.select_info.p2_teammenu_enemytitle_font[4],
	motif.select_info.p2_teammenu_enemytitle_font[5],
	motif.select_info.p2_teammenu_enemytitle_font[6],
	motif.select_info.p2_teammenu_enemytitle_font[7],
	motif.select_info.p2_teammenu_enemytitle_font[8]
)

local p2TeamActiveCount = 0
local p2TeamActiveFont = 'p2_teammenu_item_active_font'

function start.f_p2TeamMenu()
	if #t_p2Cursor > 0 then
		t_p2Cursor = {}
	end
	if main.p2TeamMenu ~= nil then --Predefined team
		p2TeamMode = main.p2TeamMenu.mode
		p2NumChars = main.p2TeamMenu.chars
		setTeamMode(2, p2TeamMode, p2NumChars)
		if main.p2TeamMenu.ratio ~= nil and p2TeamMode == 2 then
			p2NumRatio = main.p2TeamMenu.ratio
			p2Ratio = true
		end
		p2TeamEnd = true
	else
		--Command swap
		local cmd = main.p2Cmd
		if main.coop then
			cmd = main.p1Cmd
		end
		--Calculate team cursor position
		if commandGetState(cmd, 'u') then
			if p2TeamMenu > 1 then
				sndPlay(motif.files.snd_data, motif.select_info.p2_teammenu_move_snd[1], motif.select_info.p2_teammenu_move_snd[2])
				p2TeamMenu = p2TeamMenu - 1
			elseif motif.select_info.teammenu_move_wrapping == 1 then
				sndPlay(motif.files.snd_data, motif.select_info.p2_teammenu_move_snd[1], motif.select_info.p2_teammenu_move_snd[2])
				p2TeamMenu = #start.t_p2TeamMenu
			end
		elseif commandGetState(cmd, 'd') then
			if p2TeamMenu < #start.t_p2TeamMenu then
				sndPlay(motif.files.snd_data, motif.select_info.p2_teammenu_move_snd[1], motif.select_info.p2_teammenu_move_snd[2])
				p2TeamMenu = p2TeamMenu + 1
			elseif motif.select_info.teammenu_move_wrapping == 1 then
				sndPlay(motif.files.snd_data, motif.select_info.p2_teammenu_move_snd[1], motif.select_info.p2_teammenu_move_snd[2])
				p2TeamMenu = 1
			end
		elseif start.t_p2TeamMenu[p2TeamMenu].itemname == 'simul' then
			if commandGetState(cmd, 'r') then
				if p2NumSimul > 2 then
					sndPlay(motif.files.snd_data, motif.select_info.p2_teammenu_value_snd[1], motif.select_info.p2_teammenu_value_snd[2])
					p2NumSimul = p2NumSimul - 1
				end
			elseif commandGetState(cmd, 'l') then
				if p2NumSimul < config.NumSimul then
					sndPlay(motif.files.snd_data, motif.select_info.p2_teammenu_value_snd[1], motif.select_info.p2_teammenu_value_snd[2])
					p2NumSimul = p2NumSimul + 1
				end
			end
		elseif start.t_p2TeamMenu[p2TeamMenu].itemname == 'turns' then
			if commandGetState(cmd, 'r') then
				if p2NumTurns > 1 then
					sndPlay(motif.files.snd_data, motif.select_info.p2_teammenu_value_snd[1], motif.select_info.p2_teammenu_value_snd[2])
					p2NumTurns = p2NumTurns - 1
				end
			elseif commandGetState(cmd, 'l') then
				if p2NumTurns < config.NumTurns then
					sndPlay(motif.files.snd_data, motif.select_info.p2_teammenu_value_snd[1], motif.select_info.p2_teammenu_value_snd[2])
					p2NumTurns = p2NumTurns + 1
				end
			end
		elseif start.t_p2TeamMenu[p2TeamMenu].itemname == 'tag' then
			if commandGetState(cmd, 'r') then
				if p2NumTag > 2 then
					sndPlay(motif.files.snd_data, motif.select_info.p2_teammenu_value_snd[1], motif.select_info.p2_teammenu_value_snd[2])
					p2NumTag = p2NumTag - 1
				end
			elseif commandGetState(cmd, 'l') then
				if p2NumTag < config.NumTag then
					sndPlay(motif.files.snd_data, motif.select_info.p2_teammenu_value_snd[1], motif.select_info.p2_teammenu_value_snd[2])
					p2NumTag = p2NumTag + 1
				end
			end
		elseif start.t_p2TeamMenu[p2TeamMenu].itemname == 'ratio' then
			if commandGetState(cmd, 'l') and main.p2SelectMenu then
				sndPlay(motif.files.snd_data, motif.select_info.p2_teammenu_value_snd[1], motif.select_info.p2_teammenu_value_snd[2])
				if p2NumRatio > 1 then
					p2NumRatio = p2NumRatio - 1
				else
					p2NumRatio = 7
				end
			elseif commandGetState(cmd, 'r') and main.p2SelectMenu then
				sndPlay(motif.files.snd_data, motif.select_info.p2_teammenu_value_snd[1], motif.select_info.p2_teammenu_value_snd[2])
				if p2NumRatio < 7 then
					p2NumRatio = p2NumRatio + 1
				else
					p2NumRatio = 1
				end
			end
		end
		--Draw team background
		animUpdate(motif.select_info.p2_teammenu_bg_data)
		animDraw(motif.select_info.p2_teammenu_bg_data)
		--Draw team active element background
		animUpdate(motif.select_info['p2_teammenu_bg_' .. start.t_p2TeamMenu[p2TeamMenu].itemname .. '_data'])
		animDraw(motif.select_info['p2_teammenu_bg_' .. start.t_p2TeamMenu[p2TeamMenu].itemname .. '_data'])
		--Draw team cursor
		main.f_animPosDraw(
			motif.select_info.p2_teammenu_item_cursor_data,
			(p2TeamMenu - 1) * motif.select_info.p2_teammenu_item_spacing[1],
			(p2TeamMenu - 1) * motif.select_info.p2_teammenu_item_spacing[2]
		)
		--Draw team title
		if main.coop or main.p2In == 1 then
			animUpdate(motif.select_info.p2_teammenu_enemytitle_data)
			animDraw(motif.select_info.p2_teammenu_enemytitle_data)
			textImgDraw(txt_p2TeamEnemyTitle)
		else
			animUpdate(motif.select_info.p2_teammenu_selftitle_data)
			animDraw(motif.select_info.p2_teammenu_selftitle_data)
			textImgDraw(txt_p2TeamSelfTitle)
		end
		for i = 1, #start.t_p2TeamMenu do
			if i == p2TeamMenu then
				if p2TeamActiveCount < 2 then --delay change
					p2TeamActiveCount = p2TeamActiveCount + 1
				elseif p2TeamActiveFont == 'p2_teammenu_item_active_font' then
					p2TeamActiveFont = 'p2_teammenu_item_active2_font'
					p2TeamActiveCount = 0
				else
					p2TeamActiveFont = 'p2_teammenu_item_active_font'
					p2TeamActiveCount = 0
				end
				--Draw team active font
				textImgDraw(main.f_updateTextImg(
					start.t_p2TeamMenu[i].data,
					motif.font_data[motif.select_info[p2TeamActiveFont][1]],
					motif.select_info[p2TeamActiveFont][2],
					motif.select_info[p2TeamActiveFont][3], --p2_teammenu_item_font (winmugen ignores active font facing? Fixed in mugen 1.0)
					start.t_p2TeamMenu[i].displayname,
					motif.select_info.p2_teammenu_pos[1] + motif.select_info.p2_teammenu_item_offset[1] + motif.select_info.p2_teammenu_item_font_offset[1] + motif.select_info.p2_teammenu_item_spacing[1] * (i - 1),
					motif.select_info.p2_teammenu_pos[2] + motif.select_info.p2_teammenu_item_offset[2] + motif.select_info.p2_teammenu_item_font_offset[2] + motif.select_info.p2_teammenu_item_spacing[2] * (i - 1),
					motif.select_info[p2TeamActiveFont .. '_scale'][1],
					motif.select_info[p2TeamActiveFont .. '_scale'][2],
					motif.select_info[p2TeamActiveFont][4],
					motif.select_info[p2TeamActiveFont][5],
					motif.select_info[p2TeamActiveFont][6],
					motif.select_info[p2TeamActiveFont][7],
					motif.select_info[p2TeamActiveFont][8]
				))
			else
				--Draw team not active font
				textImgDraw(main.f_updateTextImg(
					start.t_p2TeamMenu[i].data,
					motif.font_data[motif.select_info.p2_teammenu_item_font[1]],
					motif.select_info.p2_teammenu_item_font[2],
					motif.select_info.p2_teammenu_item_font[3],
					start.t_p2TeamMenu[i].displayname,
					motif.select_info.p2_teammenu_pos[1] + motif.select_info.p2_teammenu_item_offset[1] + motif.select_info.p2_teammenu_item_font_offset[1] + motif.select_info.p2_teammenu_item_spacing[1] * (i - 1),
					motif.select_info.p2_teammenu_pos[2] + motif.select_info.p2_teammenu_item_offset[2] + motif.select_info.p2_teammenu_item_font_offset[2] + motif.select_info.p2_teammenu_item_spacing[2] * (i - 1),
					motif.select_info.p2_teammenu_item_font_scale[1],
					motif.select_info.p2_teammenu_item_font_scale[2],
					motif.select_info.p2_teammenu_item_font[4],
					motif.select_info.p2_teammenu_item_font[5],
					motif.select_info.p2_teammenu_item_font[6],
					motif.select_info.p2_teammenu_item_font[7],
					motif.select_info.p2_teammenu_item_font[8]
				))
			end
			--Draw team icons
			if start.t_p2TeamMenu[i].itemname == 'simul' then
				for j = 1, config.NumSimul do
					if j <= p2NumSimul then
						main.f_animPosDraw(
							motif.select_info.p2_teammenu_value_icon_data,
							(i - 1) * motif.select_info.p2_teammenu_item_spacing[1] + (j - 1) * motif.select_info.p2_teammenu_value_spacing[1],
							(i - 1) * motif.select_info.p2_teammenu_item_spacing[2] + (j - 1) * motif.select_info.p2_teammenu_value_spacing[2]
						)
					else
						main.f_animPosDraw(
							motif.select_info.p2_teammenu_value_empty_icon_data,
							(i - 1) * motif.select_info.p2_teammenu_item_spacing[1] + (j - 1) * motif.select_info.p2_teammenu_value_spacing[1],
							(i - 1) * motif.select_info.p2_teammenu_item_spacing[2] + (j - 1) * motif.select_info.p2_teammenu_value_spacing[2]
						)
					end
				end
			elseif start.t_p2TeamMenu[i].itemname == 'turns' then
				for j = 1, config.NumTurns do
					if j <= p2NumTurns then
						main.f_animPosDraw(
							motif.select_info.p2_teammenu_value_icon_data,
							(i - 1) * motif.select_info.p2_teammenu_item_spacing[1] + (j - 1) * motif.select_info.p2_teammenu_value_spacing[1],
							(i - 1) * motif.select_info.p2_teammenu_item_spacing[2] + (j - 1) * motif.select_info.p2_teammenu_value_spacing[2]
						)
					else
						main.f_animPosDraw(
							motif.select_info.p2_teammenu_value_empty_icon_data,
							(i - 1) * motif.select_info.p2_teammenu_item_spacing[1] + (j - 1) * motif.select_info.p2_teammenu_value_spacing[1],
							(i - 1) * motif.select_info.p2_teammenu_item_spacing[2] + (j - 1) * motif.select_info.p2_teammenu_value_spacing[2]
						)
					end
				end
			elseif start.t_p2TeamMenu[i].itemname == 'tag' then
				for j = 1, config.NumTag do
					if j <= p2NumTag then
						main.f_animPosDraw(
							motif.select_info.p2_teammenu_value_icon_data,
							(i - 1) * motif.select_info.p2_teammenu_item_spacing[1] + (j - 1) * motif.select_info.p2_teammenu_value_spacing[1],
							(i - 1) * motif.select_info.p2_teammenu_item_spacing[2] + (j - 1) * motif.select_info.p2_teammenu_value_spacing[2]
						)
					else
						main.f_animPosDraw(
							motif.select_info.p2_teammenu_value_empty_icon_data,
							(i - 1) * motif.select_info.p2_teammenu_item_spacing[1] + (j - 1) * motif.select_info.p2_teammenu_value_spacing[1],
							(i - 1) * motif.select_info.p2_teammenu_item_spacing[2] + (j - 1) * motif.select_info.p2_teammenu_value_spacing[2]
						)
					end
				end
			elseif start.t_p2TeamMenu[i].itemname == 'ratio' and p2TeamMenu == i and main.p2SelectMenu then
				animUpdate(motif.select_info['p2_teammenu_ratio' .. p2NumRatio .. '_icon_data'])
				animDraw(motif.select_info['p2_teammenu_ratio' .. p2NumRatio .. '_icon_data'])
			end
		end
		--Confirmed team selection
		if main.f_btnPalNo(cmd) > 0 then
			sndPlay(motif.files.snd_data, motif.select_info.p2_teammenu_done_snd[1], motif.select_info.p2_teammenu_done_snd[2])
			if start.t_p2TeamMenu[p2TeamMenu].itemname == 'single' then
				p2TeamMode = 0
				p2NumChars = 1
			elseif start.t_p2TeamMenu[p2TeamMenu].itemname == 'simul' then
				p2TeamMode = 1
				p2NumChars = p2NumSimul
			elseif start.t_p2TeamMenu[p2TeamMenu].itemname == 'turns' then
				p2TeamMode = 2
				p2NumChars = p2NumTurns
			elseif start.t_p2TeamMenu[p2TeamMenu].itemname == 'tag' then
				p2TeamMode = 3
				p2NumChars = p2NumTag
			elseif start.t_p2TeamMenu[p2TeamMenu].itemname == 'ratio' then
				p2TeamMode = 2
				if p2NumRatio <= 3 then
					p2NumChars = 3
				elseif p2NumRatio <= 6 then
					p2NumChars = 2
				else
					p2NumChars = 1
				end
				p2Ratio = true
			end
			setTeamMode(2, p2TeamMode, p2NumChars)
			p2TeamEnd = true
			main.f_cmdInput()
		end
	end
end

--;===========================================================
--; PLAYER 1 SELECT MENU
--;===========================================================
function start.f_p1SelectMenu()
	--predefined selection
	if main.p1Char ~= nil then
		local t = {}
		for i = 1, #main.p1Char do
			if t[main.p1Char[i]] == nil then
				t[main.p1Char[i]] = ''
			end
			t_p1Selected[i] = {cel = main.p1Char[i], pal = start.f_selectPal(main.p1Char[i])}
		end
		p1SelEnd = true
		return
	--manual selection
	elseif not p1SelEnd then
		resetgrid = false
		--cell movement
		if p1RestoreCursor and t_p1Cursor[p1NumChars - #t_p1Selected] ~= nil then --restore saved position
			p1SelX = t_p1Cursor[p1NumChars - #t_p1Selected][1]
			p1SelY = t_p1Cursor[p1NumChars - #t_p1Selected][2]
			p1FaceOffset = t_p1Cursor[p1NumChars - #t_p1Selected][3]
			p1RowOffset = t_p1Cursor[p1NumChars - #t_p1Selected][4]
			t_p1Cursor[p1NumChars - #t_p1Selected] = nil
		else --calculate current position
			p1SelX, p1SelY, p1FaceOffset, p1RowOffset = start.f_cellMovement(p1SelX, p1SelY, main.p1Cmd, p1FaceOffset, p1RowOffset, motif.select_info.p1_cursor_move_snd)
		end
		p1Cell = p1SelX + motif.select_info.columns * p1SelY
		--draw active cursor
		local cursorX = p1FaceX + p1SelX * (motif.select_info.cell_size[1] + motif.select_info.cell_spacing[1])
		local cursorY = p1FaceY + (p1SelY - p1RowOffset) * (motif.select_info.cell_size[2] + motif.select_info.cell_spacing[2])
		if resetgrid == true then
			start.f_resetGrid()
		end
		if main.t_selChars[p1Cell + 1].hidden ~= 1 then
			main.f_animPosDraw(motif.select_info.p1_cursor_active_data, cursorX, cursorY)
		end
		--cell selected
		if main.f_btnPalNo(main.p1Cmd) > 0 and main.t_selChars[p1Cell + 1].char ~= nil and main.t_selChars[p1Cell + 1].hidden ~= 2 then
			sndPlay(motif.files.snd_data, motif.select_info.p1_cursor_done_snd[1], motif.select_info.p1_cursor_done_snd[2])
			local selected = p1Cell
			if main.t_selChars[selected + 1].char == 'randomselect' or main.t_selChars[selected + 1].hidden == 3 then
				selected = main.t_randomChars[math.random(1, #main.t_randomChars)]
			end
			table.insert(t_p1Selected, {cel = selected, pal = main.f_btnPalNo(main.p1Cmd), cursor = {cursorX, cursorY, p1RowOffset}, ratio = start.f_setRatio(1)})
			t_p1Cursor[p1NumChars - #t_p1Selected + 1] = {p1SelX, p1SelY, p1FaceOffset, p1RowOffset}
			if #t_p1Selected == p1NumChars then --if all characters have been chosen
				if main.p2In == 1 and matchNo == 0 then --if player1 is allowed to select p2 characters
					p2TeamEnd = false
					p2SelEnd = false
					--commandBufReset(main.p2Cmd)
				end
				p1SelEnd = true
			end
			main.f_cmdInput()
		--select screen timer reached 0
		elseif motif.select_info.timer_enabled == 1 and timerSelect == -1 then
			sndPlay(motif.files.snd_data, motif.select_info.p1_cursor_done_snd[1], motif.select_info.p1_cursor_done_snd[2])
			local selected = p1Cell
			local rand = false
			for i = #t_p1Selected + 1, p1NumChars do
				if rand or main.t_selChars[selected + 1].char == 'randomselect' or main.t_selChars[selected + 1].hidden == 3 then
					selected = main.t_randomChars[math.random(1, #main.t_randomChars)]
				end
				rand = true
				table.insert(t_p1Selected, {cel = selected, pal = math.random(1, 12), cursor = {cursorX, cursorY, p1RowOffset}, ratio = start.f_setRatio(1)})
				t_p1Cursor[p1NumChars - #t_p1Selected + 1] = {p1SelX, p1SelY, p1FaceOffset, p1RowOffset}
			end
			if main.p2SelectMenu and main.p2In == 1 and matchNo == 0 then --if player1 is allowed to select p2 characters
				p2TeamMode = p1TeamMode
				p2NumChars = p1NumChars
				setTeamMode(2, p2TeamMode, p2NumChars)
				p2Cell = p1Cell
				p2SelX = p1SelX
				p2SelY = p1SelY
				p2FaceOffset = p1FaceOffset
				p2RowOffset = p1RowOffset
				for i = 1, p2NumChars do
					table.insert(t_p2Selected, {cel = main.t_randomChars[math.random(1, #main.t_randomChars)], pal = math.random(1, 12), cursor = {cursorX, cursorY, p2RowOffset}, ratio = start.f_setRatio(2)})
					t_p2Cursor[p2NumChars - #t_p2Selected + 1] = {p2SelX, p2SelY, p2FaceOffset, p2RowOffset}
				end
			end
			if main.stageMenu then
				stageNo = main.t_includeStage[2][math.random(1, #main.t_includeStage[2])]
				stageEnd = true
			end
			p1SelEnd = true
		end
	end
end

--;===========================================================
--; PLAYER 2 SELECT MENU
--;===========================================================
function start.f_p2SelectMenu()
	--predefined selection
	if main.p2Char ~= nil then
		local t = {}
		for i = 1, #main.p2Char do
			if t[main.p2Char[i]] == nil then
				t[main.p2Char[i]] = ''
			end
			t_p2Selected[i] = {cel = main.p2Char[i], pal = start.f_selectPal(main.p2Char[i])}
		end
		p2SelEnd = true
		return
	--p2 selection disabled
	elseif not main.p2SelectMenu then
		p2SelEnd = true
		return
	--manual selection
	elseif not p2SelEnd then
		resetgrid = false
		--cell movement
		if p2RestoreCursor and t_p2Cursor[p2NumChars - #t_p2Selected] ~= nil then --restore saved position
			p2SelX = t_p2Cursor[p2NumChars - #t_p2Selected][1]
			p2SelY = t_p2Cursor[p2NumChars - #t_p2Selected][2]
			p2FaceOffset = t_p2Cursor[p2NumChars - #t_p2Selected][3]
			p2RowOffset = t_p2Cursor[p2NumChars - #t_p2Selected][4]
			t_p2Cursor[p2NumChars - #t_p2Selected] = nil
		else --calculate current position
			p2SelX, p2SelY, p2FaceOffset, p2RowOffset = start.f_cellMovement(p2SelX, p2SelY, main.p2Cmd, p2FaceOffset, p2RowOffset, motif.select_info.p2_cursor_move_snd)
		end
		p2Cell = p2SelX + motif.select_info.columns * p2SelY
		--draw active cursor
		local cursorX = p2FaceX + p2SelX * (motif.select_info.cell_size[1] + motif.select_info.cell_spacing[1])
		local cursorY = p2FaceY + (p2SelY - p2RowOffset) * (motif.select_info.cell_size[2] + motif.select_info.cell_spacing[2])
		if resetgrid == true then
			start.f_resetGrid()
		end
		main.f_animPosDraw(motif.select_info.p2_cursor_active_data, cursorX, cursorY)
		--cell selected
		if main.f_btnPalNo(main.p2Cmd) > 0 and main.t_selChars[p2Cell + 1].char ~= nil and main.t_selChars[p2Cell + 1].hidden ~= 2 then
			sndPlay(motif.files.snd_data, motif.select_info.p2_cursor_done_snd[1], motif.select_info.p2_cursor_done_snd[2])
			local selected = p2Cell
			if main.t_selChars[selected + 1].char == 'randomselect' or main.t_selChars[selected + 1].hidden == 3 then
				selected = main.t_randomChars[math.random(1, #main.t_randomChars)]
			end
			table.insert(t_p2Selected, {cel = selected, pal = main.f_btnPalNo(main.p2Cmd), cursor = {cursorX, cursorY, p2RowOffset}, ratio = start.f_setRatio(2)})
			t_p2Cursor[p2NumChars - #t_p2Selected + 1] = {p2SelX, p2SelY, p2FaceOffset, p2RowOffset}
			if #t_p2Selected == p2NumChars then
				p2SelEnd = true
			end
			main.f_cmdInput()
		--select screen timer reached 0
		elseif motif.select_info.timer_enabled == 1 and timerSelect == -1 then
			sndPlay(motif.files.snd_data, motif.select_info.p2_cursor_done_snd[1], motif.select_info.p2_cursor_done_snd[2])
			local selected = p2Cell
			local rand = false
			for i = #t_p2Selected + 1, p2NumChars do
				if rand or main.t_selChars[selected + 1].char == 'randomselect' or main.t_selChars[selected + 1].hidden == 3 then
					selected = main.t_randomChars[math.random(1, #main.t_randomChars)]
				end
				rand = true
				table.insert(t_p2Selected, {cel = selected, pal = math.random(1, 12), cursor = {cursorX, cursorY, p2RowOffset}, ratio = start.f_setRatio(2)})
				t_p2Cursor[p2NumChars - #t_p2Selected + 1] = {p2SelX, p2SelY, p2FaceOffset, p2RowOffset}
			end
			p2SelEnd = true
		end
	end
end

--;===========================================================
--; STAGE MENU
--;===========================================================
local txt_selStage = textImgNew()

local stageActiveCount = 0
local stageActiveFont = 'stage_active_font'

function start.f_stageMenu()
	if commandGetState(main.p1Cmd, 'l') then
		sndPlay(motif.files.snd_data, motif.select_info.stage_move_snd[1], motif.select_info.stage_move_snd[2])
		stageList = stageList - 1
		if stageList < 0 then stageList = #main.t_includeStage[2] end
	elseif commandGetState(main.p1Cmd, 'r') then
		sndPlay(motif.files.snd_data, motif.select_info.stage_move_snd[1], motif.select_info.stage_move_snd[2])
		stageList = stageList + 1
		if stageList > #main.t_includeStage[2] then stageList = 0 end
	elseif commandGetState(main.p1Cmd, 'u') then
		sndPlay(motif.files.snd_data, motif.select_info.stage_move_snd[1], motif.select_info.stage_move_snd[2])
		for i = 1, 10 do
			stageList = stageList - 1
			if stageList < 0 then stageList = #main.t_includeStage[2] end
		end
	elseif commandGetState(main.p1Cmd, 'd') then
		sndPlay(motif.files.snd_data, motif.select_info.stage_move_snd[1], motif.select_info.stage_move_snd[2])
		for i = 1, 10 do
			stageList = stageList + 1
			if stageList > #main.t_includeStage[2] then stageList = 0 end
		end
	end
	if stageList == 0 then --draw random stage portrait loaded from screenpack SFF
		animUpdate(motif.select_info.stage_portrait_random_data)
		animDraw(motif.select_info.stage_portrait_random_data)	
	else --draw stage portrait loaded from stage SFF
		drawStagePortrait(
			stageList,
			motif.select_info.stage_pos[1] + motif.select_info.stage_portrait_offset[1],
			motif.select_info.stage_pos[2] + motif.select_info.stage_portrait_offset[2],
			--[[motif.select_info.stage_portrait_facing * ]]motif.select_info.stage_portrait_scale[1],
			motif.select_info.stage_portrait_scale[2]
		)
	end
	if main.f_btnPalNo(main.p1Cmd) > 0 then
		sndPlay(motif.files.snd_data, motif.select_info.stage_done_snd[1], motif.select_info.stage_done_snd[2])
		if stageList == 0 then
			stageNo = main.t_includeStage[2][math.random(1, #main.t_includeStage[2])]
		else
			stageNo = main.t_includeStage[2][stageList]
		end
		stageActiveFont = 'stage_done_font'
		stageEnd = true
		main.f_cmdInput()
	else
		if stageActiveCount < 2 then --delay change
			stageActiveCount = stageActiveCount + 1
		elseif stageActiveFont == 'stage_active_font' then
			stageActiveFont = 'stage_active2_font'
			stageActiveCount = 0
		else
			stageActiveFont = 'stage_active_font'
			stageActiveCount = 0
		end
	end
	local t_txt = {}
	if stageList == 0 then
		t_txt[1] = motif.select_info.stage_random_text
	else
		t_txt = main.f_extractText(motif.select_info.stage_text, stageList, getStageName(main.t_includeStage[2][stageList]))
	end
	for i = 1, #t_txt do
		textImgDraw(main.f_updateTextImg(
			txt_selStage,
			motif.font_data[motif.select_info[stageActiveFont][1]],
			motif.select_info[stageActiveFont][2],
			motif.select_info[stageActiveFont][3],
			t_txt[i],
			motif.select_info.stage_pos[1],
			motif.select_info.stage_pos[2] + (motif.font_def[motif.select_info[stageActiveFont][1]].Size[2] + motif.font_def[motif.select_info[stageActiveFont][1]].Spacing[2]) * (i - 1),
			motif.select_info[stageActiveFont .. '_scale'][1],
			motif.select_info[stageActiveFont .. '_scale'][2],
			motif.select_info[stageActiveFont][4],
			motif.select_info[stageActiveFont][5],
			motif.select_info[stageActiveFont][6],
			motif.select_info[stageActiveFont][7],
			motif.select_info[stageActiveFont][8]
		))
	end
end

--;===========================================================
--; VERSUS SCREEN
--;===========================================================
local txt_p1NameVS = main.f_createTextImg(
	motif.font_data[motif.vs_screen.p1_name_font[1]],
	motif.vs_screen.p1_name_font[2],
	motif.vs_screen.p1_name_font[3],
	'',
	0,
	0,
	motif.vs_screen.p1_name_font_scale[1],
	motif.vs_screen.p1_name_font_scale[2],
	motif.vs_screen.p1_name_font[4],
	motif.vs_screen.p1_name_font[5],
	motif.vs_screen.p1_name_font[6],
	motif.vs_screen.p1_name_font[7],
	motif.vs_screen.p1_name_font[8]
	
)
local txt_p2NameVS = main.f_createTextImg(
	motif.font_data[motif.vs_screen.p2_name_font[1]],
	motif.vs_screen.p2_name_font[2],
	motif.vs_screen.p2_name_font[3],
	'',
	0,
	0,
	motif.vs_screen.p2_name_font_scale[1],
	motif.vs_screen.p2_name_font_scale[2],
	motif.vs_screen.p2_name_font[4],
	motif.vs_screen.p2_name_font[5],
	motif.vs_screen.p2_name_font[6],
	motif.vs_screen.p2_name_font[7],
	motif.vs_screen.p2_name_font[8]
)
local txt_matchNo = main.f_createTextImg(
	motif.font_data[motif.vs_screen.match_font[1]],
	motif.vs_screen.match_font[2],
	motif.vs_screen.match_font[3],
	'',
	motif.vs_screen.match_offset[1],
	motif.vs_screen.match_offset[2],
	motif.vs_screen.match_font_scale[1],
	motif.vs_screen.match_font_scale[2],
	motif.vs_screen.match_font[4],
	motif.vs_screen.match_font[5],
	motif.vs_screen.match_font[6],
	motif.vs_screen.match_font[7],
	motif.vs_screen.match_font[8]
)

function start.f_selectChar(player, t)
	for i = 1, #t do
		selectChar(player, t[i].cel, t[i].pal)
	end
end

function start.f_selectVersus()
	if not main.versusScreen or not main.t_charparam.vsscreen or (main.t_charparam.rivals and start.f_rivalsMatch('vsscreen', 0)) or main.t_selChars[t_p1Selected[1].cel + 1].vsscreen == 0 then
		start.f_selectChar(1, t_p1Selected)
		start.f_selectChar(2, t_p2Selected)
		return
	else
		local text = main.f_extractText(motif.vs_screen.match_text, matchNo)
		textImgSetText(txt_matchNo, text[1])
		main.f_menuReset(motif.versusbgdef.bg, motif.music.vs_bgm, motif.music.vs_bgm_loop, motif.music.vs_bgm_volume, motif.music.vs_bgm_loopstart, motif.music.vs_bgm_loopend)
		local p1Confirmed = false
		local p2Confirmed = false
		local p1Row = 1
		local p2Row = 1
		local t_tmp = {}
		local orderTime = 0
		if main.p1In == 1 and main.p2In == 2 and (#t_p1Selected > 1 or #t_p2Selected > 1) and not main.coop then
			orderTime = math.max(#t_p1Selected, #t_p2Selected) - 1 * motif.vs_screen.time_order
			if #t_p1Selected == 1 then
				start.f_selectChar(1, t_p1Selected)
				p1Confirmed = true
			end
			if #t_p2Selected == 1 then
				start.f_selectChar(2, t_p2Selected)
				p2Confirmed = true
			end
		elseif #t_p1Selected > 1 and not main.coop then
			orderTime = #t_p1Selected - 1 * motif.vs_screen.time_order
		else
			start.f_selectChar(1, t_p1Selected)
			p1Confirmed = true
			start.f_selectChar(2, t_p2Selected)
			p2Confirmed = true
		end
		main.f_cmdInput()
		main.fadeStart = getFrameCount()
		local counter = 0 - motif.vs_screen.fadein_time
		fadeType = 'fadein'
		while true do
			if esc() then
				sndPlay(motif.files.snd_data, motif.select_info.cancel_snd[1], motif.select_info.cancel_snd[2])
				main.f_menuReset(motif.titlebgdef.bg, motif.music.title_bgm, motif.music.title_bgm_loop, motif.music.title_bgm_volume, motif.music.title_bgm_loopstart, motif.music.title_bgm_loopend)
				resetRemapInput()
				break
			elseif p1Confirmed and p2Confirmed then
				if fadeType == 'fadein' and (counter >= motif.vs_screen.time or main.f_btnPalNo(main.p1Cmd) > 0) then
					main.fadeStart = getFrameCount()
					fadeType = 'fadeout'
				end
			elseif counter >= motif.vs_screen.time + orderTime then
				if not p1Confirmed then
					start.f_selectChar(1, t_p1Selected)
					p1Confirmed = true
				end
				if not p2Confirmed then
					start.f_selectChar(2, t_p2Selected)
					p2Confirmed = true
				end
			else
				--if Player1 has not confirmed the order yet
				if not p1Confirmed then
					if main.f_btnPalNo(main.p1Cmd) > 0 then
						if not p1Confirmed then
							sndPlay(motif.files.snd_data, motif.vs_screen.p1_cursor_done_snd[1], motif.vs_screen.p1_cursor_done_snd[2])
							start.f_selectChar(1, t_p1Selected)
							p1Confirmed = true
						end
						if main.p2In ~= 2 then
							if not p2Confirmed then
								start.f_selectChar(2, t_p2Selected)
								p2Confirmed = true
							end
						end
					elseif commandGetState(main.p1Cmd, 'u') then
						if #t_p1Selected > 1 then
							sndPlay(motif.files.snd_data, motif.vs_screen.p1_cursor_move_snd[1], motif.vs_screen.p1_cursor_move_snd[2])
							p1Row = p1Row - 1
							if p1Row == 0 then p1Row = #t_p1Selected end
						end
					elseif commandGetState(main.p1Cmd, 'd') then
						if #t_p1Selected > 1 then
							sndPlay(motif.files.snd_data, motif.vs_screen.p1_cursor_move_snd[1], motif.vs_screen.p1_cursor_move_snd[2])
							p1Row = p1Row + 1
							if p1Row > #t_p1Selected then p1Row = 1 end
						end
					elseif commandGetState(main.p1Cmd, 'l') then
						if p1Row - 1 > 0 then
							sndPlay(motif.files.snd_data, motif.vs_screen.p1_cursor_move_snd[1], motif.vs_screen.p1_cursor_move_snd[2])
							p1Row = p1Row - 1
							t_tmp = {}
							t_tmp[p1Row] = t_p1Selected[p1Row + 1]
							for i = 1, #t_p1Selected do
								for j = 1, #t_p1Selected do
									if t_tmp[j] == nil and i ~= p1Row + 1 then
										t_tmp[j] = t_p1Selected[i]
										break
									end
								end
							end
							t_p1Selected = t_tmp
						end
					elseif commandGetState(main.p1Cmd, 'r') then
						if p1Row + 1 <= #t_p1Selected then
							sndPlay(motif.files.snd_data, motif.vs_screen.p1_cursor_move_snd[1], motif.vs_screen.p1_cursor_move_snd[2])
							p1Row = p1Row + 1
							t_tmp = {}
							t_tmp[p1Row] = t_p1Selected[p1Row - 1]
							for i = 1, #t_p1Selected do
								for j = 1, #t_p1Selected do
									if t_tmp[j] == nil and i ~= p1Row - 1 then
										t_tmp[j] = t_p1Selected[i]
										break
									end
								end
							end
							t_p1Selected = t_tmp
						end
					end
				end
				--if Player2 has not confirmed the order yet and is not controlled by Player1
				if not p2Confirmed and main.p2In ~= 1 then
					if main.f_btnPalNo(main.p2Cmd) > 0 then
						if not p2Confirmed then
							sndPlay(motif.files.snd_data, motif.vs_screen.p2_cursor_done_snd[1], motif.vs_screen.p2_cursor_done_snd[2])
							start.f_selectChar(2, t_p2Selected)
							p2Confirmed = true
						end
					elseif commandGetState(main.p2Cmd, 'u') then
						if #t_p2Selected > 1 then
							sndPlay(motif.files.snd_data, motif.vs_screen.p2_cursor_move_snd[1], motif.vs_screen.p2_cursor_move_snd[2])
							p2Row = p2Row - 1
							if p2Row == 0 then p2Row = #t_p2Selected end
						end
					elseif commandGetState(main.p2Cmd, 'd') then
						if #t_p2Selected > 1 then
							sndPlay(motif.files.snd_data, motif.vs_screen.p2_cursor_move_snd[1], motif.vs_screen.p2_cursor_move_snd[2])
							p2Row = p2Row + 1
							if p2Row > #t_p2Selected then p2Row = 1 end
						end
					elseif commandGetState(main.p2Cmd, 'l') then
						if p2Row + 1 <= #t_p2Selected then
							sndPlay(motif.files.snd_data, motif.vs_screen.p2_cursor_move_snd[1], motif.vs_screen.p2_cursor_move_snd[2])
							p2Row = p2Row + 1
							t_tmp = {}
							t_tmp[p2Row] = t_p2Selected[p2Row - 1]
							for i = 1, #t_p2Selected do
								for j = 1, #t_p2Selected do
									if t_tmp[j] == nil and i ~= p2Row - 1 then
										t_tmp[j] = t_p2Selected[i]
										break
									end
								end
							end
							t_p2Selected = t_tmp
						end
					elseif commandGetState(main.p2Cmd, 'r') then
						if p2Row - 1 > 0 then
							sndPlay(motif.files.snd_data, motif.vs_screen.p2_cursor_move_snd[1], motif.vs_screen.p2_cursor_move_snd[2])
							p2Row = p2Row - 1
							t_tmp = {}
							t_tmp[p2Row] = t_p2Selected[p2Row + 1]
							for i = 1, #t_p2Selected do
								for j = 1, #t_p2Selected do
									if t_tmp[j] == nil and i ~= p2Row + 1 then
										t_tmp[j] = t_p2Selected[i]
										break
									end
								end
							end
							t_p2Selected = t_tmp
						end
					end
				end
			end
			counter = counter + 1
			--draw clearcolor
			clearColor(motif.versusbgdef.bgclearcolor[1], motif.versusbgdef.bgclearcolor[2], motif.versusbgdef.bgclearcolor[3])
			--draw layerno = 0 backgrounds
			bgDraw(motif.versusbgdef.bg, false)
			--draw p1 portraits
			local t_portrait = {}
			for i = #t_p1Selected, 1, -1 do
				if #t_portrait < motif.vs_screen.p1_num then
					table.insert(t_portrait, t_p1Selected[i].cel)
				end
			end
			t_portrait = main.f_reversedTable(t_portrait)
			for n = #t_portrait, 1, -1 do
				drawVersusPortrait(
					t_portrait[n],
					motif.vs_screen.p1_pos[1] + motif.vs_screen.p1_offset[1] + motif.vs_screen['p1_c' .. n .. '_offset'][1] + (n - 1) * motif.vs_screen.p1_spacing[1] + start.f_alignOffset(motif.vs_screen.p1_facing),
					motif.vs_screen.p1_pos[2] + motif.vs_screen.p1_offset[2] + motif.vs_screen['p1_c' .. n .. '_offset'][2] + (n - 1) * motif.vs_screen.p1_spacing[2],
					motif.vs_screen.p1_facing * motif.vs_screen.p1_scale[1] * motif.vs_screen['p1_c' .. n .. '_scale'][1],
					motif.vs_screen.p1_scale[2] * motif.vs_screen['p1_c' .. n .. '_scale'][2]
				)
			end
			--draw p2 portraits
			t_portrait = {}
			for i = #t_p2Selected, 1, -1 do
				if #t_portrait < motif.vs_screen.p2_num then
					table.insert(t_portrait, t_p2Selected[i].cel)
				end
			end
			t_portrait = main.f_reversedTable(t_portrait)
			for n = #t_portrait, 1, -1 do
				drawVersusPortrait(
					t_portrait[n],
					motif.vs_screen.p2_pos[1] + motif.vs_screen.p2_offset[1] + motif.vs_screen['p2_c' .. n .. '_offset'][1] + (n - 1) * motif.vs_screen.p2_spacing[1] + start.f_alignOffset(motif.vs_screen.p2_facing),
					motif.vs_screen.p2_pos[2] + motif.vs_screen.p2_offset[2] + motif.vs_screen['p2_c' .. n .. '_offset'][2] + (n - 1) * motif.vs_screen.p2_spacing[2],
					motif.vs_screen.p2_facing * motif.vs_screen.p2_scale[1] * motif.vs_screen['p2_c' .. n .. '_scale'][1],
					motif.vs_screen.p2_scale[2] * motif.vs_screen['p2_c' .. n .. '_scale'][2]
				)
			end
			--draw names
			start.f_drawName(
				t_p1Selected,
				txt_p1NameVS,
				motif.vs_screen.p1_name_font,
				motif.vs_screen.p1_name_pos[1] + motif.vs_screen.p1_name_offset[1],
				motif.vs_screen.p1_name_pos[2] + motif.vs_screen.p1_name_offset[2],
				motif.vs_screen.p1_name_font_scale[1],
				motif.vs_screen.p1_name_font_scale[2],
				motif.vs_screen.p1_name_spacing[1],
				motif.vs_screen.p1_name_spacing[2],
				motif.vs_screen.p1_name_active_font,
				p1Row
			)
			start.f_drawName(
				t_p2Selected,
				txt_p2NameVS,
				motif.vs_screen.p2_name_font,
				motif.vs_screen.p2_name_pos[1] + motif.vs_screen.p2_name_offset[1],
				motif.vs_screen.p2_name_pos[2] + motif.vs_screen.p2_name_offset[2],
				motif.vs_screen.p2_name_font_scale[1],
				motif.vs_screen.p2_name_font_scale[2],
				motif.vs_screen.p2_name_spacing[1],
				motif.vs_screen.p2_name_spacing[2],
				motif.vs_screen.p2_name_active_font,
				p2Row
			)
			--draw match counter
			if matchNo > 0 then
				textImgDraw(txt_matchNo)
			end
			--draw layerno = 1 backgrounds
			bgDraw(motif.versusbgdef.bg, true)
			--draw fadein / fadeout
			main.fadeActive = fadeScreen(
				fadeType,
				main.fadeStart,
				motif.vs_screen[fadeType .. '_time'],
				motif.vs_screen[fadeType .. '_col'][1],
				motif.vs_screen[fadeType .. '_col'][2],
				motif.vs_screen[fadeType .. '_col'][3]
			)
			--frame transition
			if main.fadeActive then
				commandBufReset(main.p1Cmd)
				commandBufReset(main.p2Cmd)
			elseif fadeType == 'fadeout' then
				commandBufReset(main.p1Cmd)
				commandBufReset(main.p2Cmd)
				clearColor(motif.versusbgdef.bgclearcolor[1], motif.versusbgdef.bgclearcolor[2], motif.versusbgdef.bgclearcolor[3]) --skip last frame rendering
				break
			else
				main.f_cmdInput()
			end
			refresh()
		end
	end
end

--;===========================================================
--; RESULT SCREEN
--;===========================================================
local txt_resultSurvival = main.f_createTextImg(
	motif.font_data[motif.survival_results_screen.winstext_font[1]],
	motif.survival_results_screen.winstext_font[2],
	motif.survival_results_screen.winstext_font[3],
	'',
	motif.survival_results_screen.winstext_offset[1],
	motif.survival_results_screen.winstext_offset[2],
	motif.survival_results_screen.winstext_font_scale[1],
	motif.survival_results_screen.winstext_font_scale[2],
	motif.survival_results_screen.winstext_font[4],
	motif.survival_results_screen.winstext_font[5],
	motif.survival_results_screen.winstext_font[6],
	motif.survival_results_screen.winstext_font[7],
	motif.survival_results_screen.winstext_font[8]
)
local txt_resultVS100 = main.f_createTextImg(
	motif.font_data[motif.vs100kumite_results_screen.winstext_font[1]],
	motif.vs100kumite_results_screen.winstext_font[2],
	motif.vs100kumite_results_screen.winstext_font[3],
	'',
	motif.vs100kumite_results_screen.winstext_offset[1],
	motif.vs100kumite_results_screen.winstext_offset[2],
	motif.vs100kumite_results_screen.winstext_font_scale[1],
	motif.vs100kumite_results_screen.winstext_font_scale[2],
	motif.vs100kumite_results_screen.winstext_font[4],
	motif.vs100kumite_results_screen.winstext_font[5],
	motif.vs100kumite_results_screen.winstext_font[6],
	motif.vs100kumite_results_screen.winstext_font[7],
	motif.vs100kumite_results_screen.winstext_font[8]
)

function start.f_result()
	local t = {}
	local t_resultText = {}
	local txt = ''
	if gameMode('bossrush') then
		return
	elseif gameMode('survival') or gameMode('survivalcoop') or gameMode('netplaysurvivalcoop') then
		t = motif.survival_results_screen
		t_resultText = main.f_extractText(t.winstext_text, winCnt)
		txt = txt_resultSurvival
	elseif gameMode('100kumite') then
		t = motif.vs100kumite_results_screen
		t_resultText = main.f_extractText(t.winstext_text, winCnt, looseCnt)
		txt = txt_resultVS100
	end
	main.f_menuReset(motif.resultsbgdef.bg, motif.music.results_bgm, motif.music.results_bgm_loop, motif.music.results_bgm_volume, motif.music.results_bgm_loopstart, motif.music.results_bgm_loopend)
	main.f_cmdInput()
	main.fadeStart = getFrameCount()
	local counter = 0 - t.fadein_time
	fadeType = 'fadein'
	while true do
		if esc() then
			main.f_menuReset(motif.titlebgdef.bg, motif.music.title_bgm, motif.music.title_bgm_loop, motif.music.title_bgm_volume, motif.music.title_bgm_loopstart, motif.music.title_bgm_loopend)
			resetRemapInput()
			break
		elseif fadeType == 'fadein' and (counter >= t.show_time or main.f_btnPalNo(main.p1Cmd) > 0) then
			main.fadeStart = getFrameCount()
			fadeType = 'fadeout'
		end
		counter = counter + 1
		--draw clearcolor (disabled to not cover game screen)
		--clearColor(motif.resultsbgdef.bgclearcolor[1], motif.resultsbgdef.bgclearcolor[2], motif.resultsbgdef.bgclearcolor[3])
		--draw layerno = 0 backgrounds
		bgDraw(motif.resultsbgdef.bg, false)
		--draw text
		for i = 1, #t_resultText do
			textImgSetText(txt, t_resultText[i])
			textImgSetPos(
				txt,
				t.winstext_offset[1],
				t.winstext_offset[2] + (motif.font_def[t.winstext_font[1]].Size[2] + motif.font_def[t.winstext_font[1]].Spacing[2]) * (i - 1)
			)
			textImgDraw(txt)
		end
		--draw layerno = 1 backgrounds
		bgDraw(motif.resultsbgdef.bg, true)
		--draw fadein / fadeout
		main.fadeActive = fadeScreen(
			fadeType,
			main.fadeStart,
			t[fadeType .. '_time'],
			t[fadeType .. '_col'][1],
			t[fadeType .. '_col'][2],
			t[fadeType .. '_col'][3]
		)
		--frame transition
		if main.fadeActive then
			commandBufReset(main.p1Cmd)
		elseif fadeType == 'fadeout' then
			commandBufReset(main.p1Cmd)
			clearColor(motif.resultsbgdef.bgclearcolor[1], motif.resultsbgdef.bgclearcolor[2], motif.resultsbgdef.bgclearcolor[3]) --skip last frame rendering
			break
		else
			main.f_cmdInput()
		end
		refresh()
	end
end

--;===========================================================
--; VICTORY SCREEN
--;===========================================================
local txt_winquote = main.f_createTextImg(
	motif.font_data[motif.victory_screen.winquote_font[1]],
	motif.victory_screen.winquote_font[2],
	motif.victory_screen.winquote_font[3],
	'',
	0,
	0,
	motif.victory_screen.winquote_font_scale[1],
	motif.victory_screen.winquote_font_scale[2],
	motif.victory_screen.winquote_font[4],
	motif.victory_screen.winquote_font[5],
	motif.victory_screen.winquote_font[6],
	motif.victory_screen.winquote_font[7],
	motif.victory_screen.winquote_font[8]
)
local txt_p1_winquoteName = main.f_createTextImg(
	motif.font_data[motif.victory_screen.p1_name_font[1]],
	motif.victory_screen.p1_name_font[2],
	motif.victory_screen.p1_name_font[3],
	'',
	motif.victory_screen.p1_name_offset[1],
	motif.victory_screen.p1_name_offset[2],
	motif.victory_screen.p1_name_font_scale[1],
	motif.victory_screen.p1_name_font_scale[2],
	motif.victory_screen.p1_name_font[4],
	motif.victory_screen.p1_name_font[5],
	motif.victory_screen.p1_name_font[6],
	motif.victory_screen.p1_name_font[7],
	motif.victory_screen.p1_name_font[8]
)
local txt_p2_winquoteName = main.f_createTextImg(
	motif.font_data[motif.victory_screen.p2_name_font[1]],
	motif.victory_screen.p2_name_font[2],
	motif.victory_screen.p2_name_font[3],
	'',
	motif.victory_screen.p2_name_offset[1],
	motif.victory_screen.p2_name_offset[2],
	motif.victory_screen.p2_name_font_scale[1],
	motif.victory_screen.p2_name_font_scale[2],
	motif.victory_screen.p2_name_font[4],
	motif.victory_screen.p2_name_font[5],
	motif.victory_screen.p2_name_font[6],
	motif.victory_screen.p2_name_font[7],
	motif.victory_screen.p2_name_font[8]
)

function start.f_teamOrder(teamNo, allow_ko)
	local allow_ko = allow_ko or 0
	local playerNo = -1
	local selectNo = -1
	local t = {}
	local done = false
	for k, v in pairs(t_gameStats.chars[t_gameStats.lastRound]) do --loop through all last round participants
		if k % 2 ~= teamNo then --only if character belongs to selected team
			if v.win then --win team
				if not v.ko and not done then --first not KOed win team member
					playerNo = k
					selectNo = v.selectNo
					done = true
				elseif not v.ko or allow_ko == 1 then --other win team members
					table.insert(t, v.selectNo)
				end
			elseif not done then --first loose team member
				playerNo = k
				selectNo = v.selectNo
				done = true
			else --other loose team members
				table.insert(t, v.selectNo)
			end
		end
	end
	return playerNo, selectNo, t
end

function start.f_selectVictory()
	local wpn = -1
	local wsn = -1
	local lpn = -1
	local lsn = -1
	local t = {}
	local t2 = {}
	for i = 0, 1 do
		if i == t_gameStats.winTeam then
			wpn, wsn, t = start.f_teamOrder(i, motif.victory_screen.winner_teamko_enabled)
		else
			lpn, lsn, t2 = start.f_teamOrder(i, true)
		end
	end
	if wpn == -1 or wsn == -1 then
		return
	elseif not main.t_charparam.winscreen then
		return
	elseif main.t_charparam.rivals and start.f_rivalsMatch('winscreen', 0) then --winscreen assigned as rivals param
		return
	elseif main.t_selChars[wsn + 1].winscreen == 0 then --winscreen assigned as character param
		return
	end
	if motif.music.victory_bgm == '' then
		main.f_menuReset(motif.victorybgdef.bg)
	else
		main.f_menuReset(motif.victorybgdef.bg, motif.music.victory_bgm, motif.music.victory_bgm_loop, motif.music.victory_bgm_volume, motif.music.victory_bgm_loopstart, motif.music.victory_bgm_loopend)
	end
	local winquote = getCharVictoryQuote(wpn)
	if winquote == '' then
		winquote = motif.victory_screen.winquote_text
	end
	textImgSetText(txt_p1_winquoteName, main.f_getName(wsn))
	textImgSetText(txt_p2_winquoteName, main.f_getName(lsn))
	local i = 0
	main.f_cmdInput()
	main.fadeStart = getFrameCount()
	local counter = 0 - motif.victory_screen.fadein_time
	fadeType = 'fadein'
	while true do
		if esc() then
			main.f_cmdInput()
			break
		elseif fadeType == 'fadein' and (counter >= motif.victory_screen.time or main.f_btnPalNo(main.p1Cmd) > 0) then
			main.fadeStart = getFrameCount()
			fadeType = 'fadeout'
		end
		counter = counter + 1
		--draw clearcolor
		clearColor(motif.victorybgdef.bgclearcolor[1], motif.victorybgdef.bgclearcolor[2], motif.victorybgdef.bgclearcolor[3])
		--draw layerno = 0 backgrounds
		bgDraw(motif.victorybgdef.bg, false)
		--draw portraits
		-- looser team portraits
		for n = 1, #t2 do
			if n > motif.victory_screen.p2_num then
				break
			end
			drawVictoryPortrait(
				t[n],
				motif.victory_screen.p2_pos[1] + motif.victory_screen.p2_offset[1] + motif.victory_screen['p2_c' .. n + 1 .. '_offset'][1] + start.f_alignOffset(motif.victory_screen.p2_facing),
				motif.victory_screen.p2_pos[2] + motif.victory_screen.p2_offset[2] + motif.victory_screen['p2_c' .. n + 1 .. '_offset'][2],
				motif.victory_screen.p2_facing * motif.victory_screen.p2_scale[1] * motif.victory_screen['p2_c' .. n + 1 .. '_scale'][1],
				motif.victory_screen.p2_scale[2] * motif.victory_screen['p2_c' .. n + 1 .. '_scale'][2]
			)
		end
		-- looser portrait
		if motif.victory_screen.p2_num > 0 then
			drawVictoryPortrait(
				lsn,
				motif.victory_screen.p2_pos[1] + motif.victory_screen.p2_offset[1] + motif.victory_screen.p2_c1_offset[1] + start.f_alignOffset(motif.victory_screen.p2_facing),
				motif.victory_screen.p2_pos[2] + motif.victory_screen.p2_offset[2] + motif.victory_screen.p2_c1_offset[2],
				motif.victory_screen.p2_facing * motif.victory_screen.p2_scale[1] * motif.victory_screen.p2_c1_scale[1],
				motif.victory_screen.p2_scale[2] * motif.victory_screen.p2_c1_scale[2]
			)
		end
		-- winner team portraits
		for n = 1, #t do
			if n > motif.victory_screen.p1_num then
				break
			end
			drawVictoryPortrait(
				t[n],
				motif.victory_screen.p1_pos[1] + motif.victory_screen.p1_offset[1] + motif.victory_screen['p1_c' .. n + 1 .. '_offset'][1] + start.f_alignOffset(motif.victory_screen.p1_facing),
				motif.victory_screen.p1_pos[2] + motif.victory_screen.p1_offset[2] + motif.victory_screen['p1_c' .. n + 1 .. '_offset'][2],
				motif.victory_screen.p1_facing * motif.victory_screen.p1_scale[1] * motif.victory_screen['p1_c' .. n + 1 .. '_scale'][1],
				motif.victory_screen.p1_scale[2] * motif.victory_screen['p1_c' .. n + 1 .. '_scale'][2]
			)
		end
		-- winner portrait
		drawVictoryPortrait(
			wsn,
			motif.victory_screen.p1_pos[1] + motif.victory_screen.p1_offset[1] + motif.victory_screen.p1_c1_offset[1] + start.f_alignOffset(motif.victory_screen.p1_facing),
			motif.victory_screen.p1_pos[2] + motif.victory_screen.p1_offset[2] + motif.victory_screen.p1_c1_offset[2],
			motif.victory_screen.p1_facing * motif.victory_screen.p1_scale[1] * motif.victory_screen.p1_c1_scale[1],
			motif.victory_screen.p1_scale[2] * motif.victory_screen.p1_c1_scale[2]
		)
		--draw winner name
		textImgDraw(txt_p1_winquoteName)
		--draw looser name
		if motif.victory_screen.looser_name_enabled == 1 then
			textImgDraw(txt_p2_winquoteName)
		end
		--draw winquote
		i = i + 1
		main.f_textRender(
			txt_winquote,
			winquote,
			i,
			motif.victory_screen.winquote_offset[1],
			motif.victory_screen.winquote_offset[2],
			motif.font_def[motif.victory_screen.winquote_font[1]],
			motif.victory_screen.winquote_delay,
			motif.victory_screen.winquote_length
		)
		--draw layerno = 1 backgrounds
		bgDraw(motif.victorybgdef.bg, true)
		--draw fadein / fadeout
		main.fadeActive = fadeScreen(
			fadeType,
			main.fadeStart,
			motif.victory_screen[fadeType .. '_time'],
			motif.victory_screen[fadeType .. '_col'][1],
			motif.victory_screen[fadeType .. '_col'][2],
			motif.victory_screen[fadeType .. '_col'][3]
		)
		--frame transition
		if main.fadeActive then
			commandBufReset(main.p1Cmd)
		elseif fadeType == 'fadeout' then
			commandBufReset(main.p1Cmd)
			clearColor(motif.victorybgdef.bgclearcolor[1], motif.victorybgdef.bgclearcolor[2], motif.victorybgdef.bgclearcolor[3]) --skip last frame rendering
			break
		else
			main.f_cmdInput()
		end
		refresh()
	end
end

--;===========================================================
--; CONTINUE SCREEN
--;===========================================================
local txt_credits = main.f_createTextImg(
	motif.font_data[motif.continue_screen.credits_font[1]],
	motif.continue_screen.credits_font[2],
	motif.continue_screen.credits_font[3],
	'',
	motif.continue_screen.credits_offset[1],
	motif.continue_screen.credits_offset[2],
	motif.continue_screen.credits_font_scale[1],
	motif.continue_screen.credits_font_scale[2],
	motif.continue_screen.credits_font[4],
	motif.continue_screen.credits_font[5],
	motif.continue_screen.credits_font[6],
	motif.continue_screen.credits_font[7],
	motif.continue_screen.credits_font[8]
	--motif.defaultContinue
)

function start.f_continue()
	main.f_menuReset(motif.continuebgdef.bg, motif.music.continue_bgm, motif.music.continue_bgm_loop, motif.music.continue_bgm_volume, motif.music.continue_bgm_loopstart, motif.music.continue_bgm_loopend)
	animReset(motif.continue_screen.continue_anim_data)
	animUpdate(motif.continue_screen.continue_anim_data)
	continue = false
	local text = main.f_extractText(motif.continue_screen.credits_text, main.credits)
	textImgSetText(txt_credits, text[1])
	main.f_cmdInput()
	main.fadeStart = getFrameCount()
	local counter = 0-- - motif.victory_screen.fadein_time
	fadeType = 'fadein'
	while true do
		--draw clearcolor (disabled to not cover area)
		--clearColor(motif.continuebgdef.bgclearcolor[1], motif.continuebgdef.bgclearcolor[2], motif.continuebgdef.bgclearcolor[3])
		--draw layerno = 0 backgrounds
		bgDraw(motif.continuebgdef.bg, false)
		--continue screen state
		if esc() then
			main.f_cmdInput()
			break
		elseif fadeType == 'fadein' and (counter > motif.continue_screen.endtime or continue) then
			main.fadeStart = getFrameCount()
			fadeType = 'fadeout'
		elseif counter < motif.continue_screen.continue_end_skiptime then
			if commandGetState(main.p1Cmd, 'holds') then
				continue = true
				main.credits = main.credits - 1
				text = main.f_extractText(motif.continue_screen.credits_text, main.credits)
				textImgSetText(txt_credits, text[1])
			elseif main.f_btnPalNo(main.p1Cmd) > 0 and counter >= motif.continue_screen.continue_starttime + motif.continue_screen.continue_skipstart then
				local cnt = 0
				if counter < motif.continue_screen.continue_9_skiptime then
					cnt = motif.continue_screen.continue_9_skiptime
				elseif counter <= motif.continue_screen.continue_8_skiptime then
					cnt = motif.continue_screen.continue_8_skiptime
				elseif counter < motif.continue_screen.continue_7_skiptime then
					cnt = motif.continue_screen.continue_7_skiptime
				elseif counter < motif.continue_screen.continue_6_skiptime then
					cnt = motif.continue_screen.continue_6_skiptime
				elseif counter < motif.continue_screen.continue_5_skiptime then
					cnt = motif.continue_screen.continue_5_skiptime
				elseif counter < motif.continue_screen.continue_4_skiptime then
					cnt = motif.continue_screen.continue_4_skiptime
				elseif counter < motif.continue_screen.continue_3_skiptime then
					cnt = motif.continue_screen.continue_3_skiptime
				elseif counter < motif.continue_screen.continue_2_skiptime then
					cnt = motif.continue_screen.continue_2_skiptime
				elseif counter < motif.continue_screen.continue_1_skiptime then
					cnt = motif.continue_screen.continue_1_skiptime
				elseif counter < motif.continue_screen.continue_0_skiptime then
					cnt = motif.continue_screen.continue_0_skiptime
				end
				while counter < cnt do
					counter = counter + 1
					animUpdate(motif.continue_screen.continue_anim_data)
				end
			end
			if counter == motif.continue_screen.continue_9_skiptime then
				sndPlay(motif.files.continue_snd_data, motif.continue_screen.continue_9_snd[1], motif.continue_screen.continue_9_snd[2])
			elseif counter == motif.continue_screen.continue_8_skiptime then
				sndPlay(motif.files.continue_snd_data, motif.continue_screen.continue_8_snd[1], motif.continue_screen.continue_8_snd[2])
			elseif counter == motif.continue_screen.continue_7_skiptime then
				sndPlay(motif.files.continue_snd_data, motif.continue_screen.continue_7_snd[1], motif.continue_screen.continue_7_snd[2])
			elseif counter == motif.continue_screen.continue_6_skiptime then
				sndPlay(motif.files.continue_snd_data, motif.continue_screen.continue_6_snd[1], motif.continue_screen.continue_6_snd[2])
			elseif counter == motif.continue_screen.continue_5_skiptime then
				sndPlay(motif.files.continue_snd_data, motif.continue_screen.continue_5_snd[1], motif.continue_screen.continue_5_snd[2])
			elseif counter == motif.continue_screen.continue_4_skiptime then
				sndPlay(motif.files.continue_snd_data, motif.continue_screen.continue_4_snd[1], motif.continue_screen.continue_4_snd[2])
			elseif counter == motif.continue_screen.continue_3_skiptime then
				sndPlay(motif.files.continue_snd_data, motif.continue_screen.continue_3_snd[1], motif.continue_screen.continue_3_snd[2])
			elseif counter == motif.continue_screen.continue_2_skiptime then
				sndPlay(motif.files.continue_snd_data, motif.continue_screen.continue_2_snd[1], motif.continue_screen.continue_2_snd[2])
			elseif counter == motif.continue_screen.continue_1_skiptime then
				sndPlay(motif.files.continue_snd_data, motif.continue_screen.continue_1_snd[1], motif.continue_screen.continue_1_snd[2])
			elseif counter == motif.continue_screen.continue_0_skiptime then
				sndPlay(motif.files.continue_snd_data, motif.continue_screen.continue_0_snd[1], motif.continue_screen.continue_0_snd[2])
			end
		elseif counter == motif.continue_screen.continue_end_skiptime then
			playBGM(motif.music.continue_end_bgm, true, motif.music.continue_end_bgm_loop, motif.music.continue_end_bgm_volume, motif.music.continue_end_bgm_loopstart, motif.music.continue_end_bgm_loopend)
			sndPlay(motif.files.continue_snd_data, motif.continue_screen.continue_end_snd[1], motif.continue_screen.continue_end_snd[2])
		end
		--draw credits text
		if counter >= motif.continue_screen.continue_skipstart then --show when counter starts counting down
			textImgDraw(txt_credits)
		end
		counter = counter + 1
		--draw counter
		animUpdate(motif.continue_screen.continue_anim_data)
		animDraw(motif.continue_screen.continue_anim_data)
		--draw layerno = 1 backgrounds
		bgDraw(motif.continuebgdef.bg, true)
		--draw fadein / fadeout
		main.fadeActive = fadeScreen(
			fadeType,
			main.fadeStart,
			motif.continue_screen[fadeType .. '_time'],
			motif.continue_screen[fadeType .. '_col'][1],
			motif.continue_screen[fadeType .. '_col'][2],
			motif.continue_screen[fadeType .. '_col'][3]
		)
		--frame transition
		if main.fadeActive then
			commandBufReset(main.p1Cmd)
		elseif fadeType == 'fadeout' then
			commandBufReset(main.p1Cmd)
			clearColor(motif.continuebgdef.bgclearcolor[1], motif.continuebgdef.bgclearcolor[2], motif.continuebgdef.bgclearcolor[3]) --skip last frame rendering
			if continue then
				main.f_menuReset(motif.selectbgdef.bg, motif.music.select_bgm, motif.music.select_bgm_loop, motif.music.select_bgm_volume, motif.music.select_bgm_loopstart, motif.music.select_bgm_loopend)
			end
			break
		else
			main.f_cmdInput()
		end
		refresh()
	end
end

return start
