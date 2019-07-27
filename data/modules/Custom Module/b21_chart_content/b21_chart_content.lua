-- b21_chart_content.lua

size = {400, 300}

components = {
	-- textureLit	{ position = {0, 0, 512, 512}, image = background }
}

local white = { 1.0, 1.0, 1.0, 1.0 }
local gray = { 0.5, 0.5, 0.5, 1.0 }
local red = { 1.0, 0.0, 0.0, 1.0 }
local green = { 0.0, 1.0, 0.0, 1.0 }
local blue = { 0.0, 0.0, 1.0, 1.0 }
local yellow = { 0.0, 1.0, 1.0, 1.0 }

-- local arial_font = sasl.gl.loadFont("Resources/plugins/B21_Soaring/data/modules/Custom Module/tachometer/arial20.fnt")
local font = sasl.gl.loadFont("resources/UbuntuMono-Regular.ttf")

local b21_total_energy_mps = globalPropertyf("b21_soaring/total_energy_mps")
local sim_time_s = globalPropertyf("sim/network/misc/network_time_sec")
local sim_speed_mps = globalPropertyf("sim/flightmodel/position/true_airspeed")

local w = size[1] -- remember Lua arrays first element is [1]
local h = size[2]
-- axis coordinates are { { value1, value2 }, {pixel1, pixel2} }
local SPEED_AXIS = { {60.0, 225.0}, { 40.0, w-20} } -- values in kph
local SINK_AXIS = { { 0.0, 4.0 }, { h-30, 10} } -- values in mps
local SPEED_MAJOR = 20
local SPEED_MINOR = 10
local SINK_MAJOR = 0.5
local SINK_MINOR = 0.25

local polar_points = { { 60,1}, {80, 2}, {100,3.5}, {200,0.2}}

local polar_line = {0,0}

local prev_time_s = 0.0

-- each mouse click into the window will switch the units
function onMouseDown(component, x, y, button, parentX, parentY)
	polar_line = {0,0}
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

function draw_speed_axis()
	--sasl.gl.drawLine(5, 200, 200, 200, white )
	-- draw major speed grid lines
	for speed = SPEED_AXIS[1][1], SPEED_AXIS[1][2], SPEED_MAJOR
	do
		local x = speed_to_x(speed)
		sasl.gl.drawLine(x, SINK_AXIS[2][1]+5, x, SINK_AXIS[2][2], gray )
		local speed_str = tostring(math.floor(speed+0.001))
		sasl.gl.drawText(font,x-5,h-15,speed_str,16,false,false,TEXT_ALIGN_LEFT,white)
	end
end

function draw_sink_axis()
	for sink = SINK_AXIS[1][1], SINK_AXIS[1][2], SINK_MAJOR
	do
		local y = sink_to_y(sink)
		sasl.gl.drawLine(SPEED_AXIS[2][1]-5, y, SPEED_AXIS[2][2], y, gray )
		local sink_str = tostring(math.floor(sink*10.0)/10.0)
		sasl.gl.drawText(font,5,y-5,sink_str,16,false,false,TEXT_ALIGN_LEFT,white)
	end
end

function draw_axes()
	draw_speed_axis()
	draw_sink_axis()
end

function draw_graph()
	sasl.gl.drawPolyLine(polar_line, yellow)
end

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

	-- append point to polar curve
	local x = speed_to_x(speed_kph)
	local y = sink_to_y(sink_mps)
	table.insert(polar_line, x)
	table.insert(polar_line, y)
	print("polar logging",x,y)
end

function draw()
	
	drawAll(components)

	--sasl.gl.drawLine(20, 20, w-20, h-20, white)

	draw_axes()

	draw_graph()

end
