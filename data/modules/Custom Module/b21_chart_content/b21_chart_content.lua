-- b21_chart_content.lua

local POLAR_WET = {{100,0.61},{125,0.7},{150,0.9},{175,1.23},{200,1.7},{225,2.31}}

components = {
	-- textureLit	{ position = {0, 0, 512, 512}, image = background }
}

local white = { 1.0, 1.0, 1.0, 1.0 }
local gray = { 0.5, 0.5, 0.5, 1.0 }
local red = { 1.0, 0.0, 0.0, 1.0 }
local green = { 0.0, 1.0, 0.0, 1.0 }
local blue = { 0.0, 0.0, 1.0, 1.0 }
local yellow = { 1.0, 1.0, 0.0, 1.0 }

-- local arial_font = sasl.gl.loadFont("Resources/plugins/B21_Soaring/data/modules/Custom Module/tachometer/arial20.fnt")
local font = sasl.gl.loadFont("resources/UbuntuMono-Regular.ttf")

local b21_total_energy_mps = globalPropertyf("b21_soaring/total_energy_mps")
local sim_time_s = globalPropertyf("sim/network/misc/network_time_sec")
local sim_speed_mps = globalPropertyf("sim/flightmodel/position/true_airspeed")
local pause = globalPropertyf("sim/time/paused") -- check if sim is paused

local w = size[1] -- remember Lua arrays first element is [1]
local h = size[2]
-- axis coordinates are { { value1, value2 }, {pixel1, pixel2} }
local SPEED_AXIS = { {60.0, 225.0}, { 40.0, w-20} } -- values in kph, pixels
local SINK_AXIS = { { 0.0, 4.0 }, { h-30, 10} } -- values in mps, pixels

local SPEED_MAJOR = 20 -- vertical lines every 20 kmh
local SPEED_MINOR_STEPS = 4
local SPEED_MINOR = SPEED_MAJOR / SPEED_MINOR_STEPS

local SINK_MAJOR = 0.5 -- horizontal lines every 0.5 m/s
local SINK_MINOR_STEPS = 5
local SINK_MINOR = SINK_MAJOR / SINK_MINOR_STEPS

local chart_line = {0} -- recognizable initial value

local polar_line = {}

local prev_time_s = 0.0

-- each mouse click into the window will switch the units
function onMouseDown(component, x, y, button, parentX, parentY)
	chart_line = {0}
end

function speed_to_x(speed)
	local x = (speed - SPEED_AXIS[1][1]) / (SPEED_AXIS[1][2] - SPEED_AXIS[1][1]) * 
				(SPEED_AXIS[2][2] - SPEED_AXIS[2][1]) + SPEED_AXIS[2][1]
	return x
end

function sink_to_y(sink)
	local y = (sink - SINK_AXIS[1][1]) / (SINK_AXIS[1][2] - SINK_AXIS[1][1]) * 
				(SINK_AXIS[2][2] - SINK_AXIS[2][1]) + SINK_AXIS[2][1]
	return y
end

-- create polar_line values
for i = 1, #POLAR_WET
do
	x = speed_to_x(POLAR_WET[i][1])
	y = sink_to_y(POLAR_WET[i][2])
	table.insert(polar_line,x)
	table.insert(polar_line,y)
end

-- Draw horizontal axis and vertical grid
function draw_speed_axis()
	sasl.gl.setLinePattern({ 5.0, -2.0 }) -- minor grid line pattern
	--sasl.gl.drawLine(5, 200, 200, 200, white )
	-- draw major speed grid lines
	local speed = SPEED_AXIS[1][1]
	while speed <= SPEED_AXIS[1][2]
	do
		local x = speed_to_x(speed)
		sasl.gl.drawLine(x, SINK_AXIS[2][1]+5, x, SINK_AXIS[2][2], white )
		local speed_str = tostring(math.floor(speed+0.001))
		sasl.gl.drawText(font,x-5,h-15,speed_str,16,false,false,TEXT_ALIGN_LEFT,white)
		for i = 1, SPEED_MINOR_STEPS-1
		do
			x = speed_to_x(speed + i * SPEED_MINOR)
			sasl.gl.drawLinePattern(x, SINK_AXIS[2][1], x, SINK_AXIS[2][2], false, gray )
		end
		speed = speed + SPEED_MAJOR
	end
end

-- Draw vertical axis and horizontal grid
function draw_sink_axis()
	sasl.gl.setLinePattern({ 5.0, -2.0 }) -- minor grid line pattern
	local sink = SINK_AXIS[1][1]
	while sink <= SINK_AXIS[1][2]
	do
		local y = sink_to_y(sink)
		sasl.gl.drawLine(SPEED_AXIS[2][1]-5, y, SPEED_AXIS[2][2], y, white )
		local sink_str = tostring(math.floor(sink*10.0)/10.0)
		sasl.gl.drawText(font,5,y-5,sink_str,16,false,false,TEXT_ALIGN_LEFT,white)
		for i = 1, SINK_MINOR_STEPS-1
		do
			y = sink_to_y(sink + i * SINK_MINOR)
			sasl.gl.drawLinePattern(SPEED_AXIS[2][1], y, SPEED_AXIS[2][2], y, false, gray )
		end
		sink = sink + SINK_MAJOR
	end
end

function draw_polar()
	sasl.gl.setLinePattern({ 5.0, -2.0 }) -- minor grid line pattern
	sasl.gl.drawPolyLinePattern(polar_line, green)
end

function draw_axes()
	draw_speed_axis()
	draw_sink_axis()
end

function draw_graph()
	-- do not draw line if chart_line still in init state
	if chart_line[1] == 0
	then
		return
	end
	-- ok have confirmed chart_line doesn't start with 0, so can draw line
	sasl.gl.drawPolyLine(chart_line, yellow)
end

-- on each update we try and append a new point to the polar chart
function update()
	local speed_kph = get(sim_speed_mps) * 3.6

	-- do nothing if speed below min polar speed (e.g. 60 kph)
	if speed_kph < SPEED_AXIS[1][1]
	then
		return
	end

	local time_s = get(sim_time_s)

	-- do nothing if less than a second since last update
	if time_s < prev_time_s + 1
	then
		return
	end

	prev_time_s = time_s

	local sink_mps = -get(b21_total_energy_mps)

	-- do nothing if aircraft isn't actually sinking
	if sink_mps < 0
	then
		return
	end

	-- don't update if paused
	if get(pause) == 1
	then
		return
	end

	-- OK speed/sink data looks ok, add to curve
	-- append point to polar curve
	local x = speed_to_x(speed_kph)
	local y = sink_to_y(sink_mps)

	-- if chart_line still {0,0} then set to {x,y}
	if chart_line[1] == 0
	then
		chart_line = { x, y }
		print("polar init",x,y)
		return
	end

	-- otherwise iterate through chart_line to get index to insert x and y
	local i = 1
	while i <= #chart_line
	do
		if chart_line[i] > x
		then
			break
		end
		i = i + 2 -- chart_line is pairs of numbers
	end
	-- now i is index of x, y we want to insert
	table.insert(chart_line, i, x)
	table.insert(chart_line, i +1, y)

	print("polar logging["..i.."/"..#chart_line.."]",x,y)
end

function draw()
	
	drawAll(components)

	--sasl.gl.drawLine(20, 20, w-20, h-20, white)

	draw_axes()
	draw_polar()
	draw_graph()

end
