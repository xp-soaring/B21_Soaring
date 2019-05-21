-- b21_analysis_content.lua

size = {400, 300}
components = {
	-- textureLit	{ position = {0, 0, 512, 512}, image = background }
}
-- local engn_rpm = globalPropertyf("sim/cockpit2/engine/indicators/engine_speed_rpm[0]", 0)

local background	= loadImage("resources/tacho_background.png")
local needle		= loadImage("resources/tacho_needle.png")
local white = { 1.0, 1.0, 1.0, 1.0 }
local red = { 1.0, 0.0, 0.0, 1.0 }
local green = { 0.0, 1.0, 0.0, 1.0 }
local blue = { 0.0, 0.0, 1.0, 1.0 }

-- local arial_font = sasl.gl.loadFont("Resources/plugins/B21_Soaring/data/modules/Custom Module/tachometer/arial20.fnt")
local font = sasl.gl.loadFont("resources/UbuntuMono-Regular.ttf")

local sim_time_s = globalPropertyf("sim/network/misc/network_time_sec")
local b21_total_energy_m_s = globalPropertyf("b21_soaring/total_energy_m_s")
local sim_time_s = globalPropertyf("sim/network/misc/network_time_sec")
local sim_speed_m_s = globalPropertyf("sim/flightmodel/position/true_airspeed")
local sim_speedbrakes = globalPropertyf("sim/flightmodel2/controls/speedbrake_ratio")
-- local sim_cl = globalPropertyf("sim/airfoils/afl_cl")
-- local sim_cd = globalPropertyf("sim/airfoils/afl_cd")
-- local sim_cm = globalPropertyf("sim/airfoils/afl_cm")
local sim_alpha = globalPropertyf("sim/flightmodel/position/alpha")

local units = "uk" -- (knots, knots) vs. "german" (kph, mps), "metric" (mps, mps)

-- each mouse click into the window will switch the units
function onMouseDown(component, x, y, button, parentX, parentY)
	if units == "metric"
	then
		units = "german"
	elseif units == "german"
	then
		units = "uk"
	else
		units = "metric"
	end
end

function draw()
	
	drawAll(components)

	-- 4000 rpm = 270° -> 1 rpm = 0.0675°
	-- texture is vertical so 0 rpm is at -135°
	-- local angle = 2000 -- get(engn_rpm) * 0.0675 - 135
	-- drawRotatedTextureCenter(needle, angle, 256, 256, 240, 294, 32, 128, 1, 1, 1, 1)
	-- sasl.gl.drawLine(20, 20, 50, 50, green)

	local speed_m_s = get(sim_speed_m_s)

	local total_energy_m_s = get(b21_total_energy_m_s)

	local speed_str
	local sink_str
	local glide_str
	local spoilers_str

	if units == "metric"
	then
		speed_str = "Speed m/s: "..tostring(math.floor(speed_m_s * 100.0) / 100.0) -- floor/divide to set to 2 decimal places
		sink_str = "Sink m/s:  "..tostring(math.floor((-total_energy_m_s) * 100.0) / 100.0)
	elseif units == "german"
	then
		speed_str = "Speed kph: "..tostring(math.floor(speed_m_s * 3.6 * 100.0) / 100.0)
		sink_str = "Sink m/s:  "..tostring(math.floor((-total_energy_m_s) * 100.0) / 100.0)
	else -- "uk"
		speed_str = "Speed kts: "..tostring(math.floor(speed_m_s * 1.94384 * 100.0) / 100.0)
		sink_str = "Sink kts:  "..tostring(math.floor((-total_energy_m_s) * 1.94384 * 100.0) / 100.0)
	end

	-- cl_str = "CL: "..tostring(math.floor(get(sim_cl) * 1000.0) / 1000.0)
	-- cd_str = "CD: "..tostring(math.floor(get(sim_cd) * 1000.0) / 1000.0)
	-- cm_str = "CM: "..tostring(math.floor(get(sim_cm) * 1000.0) / 1000.0)
	alpha_str = "Alpha: "..tostring(math.floor(get(sim_alpha) * 10.0) / 10.0) -- (degrees) 1 decimal place
	if (total_energy_m_s < -0.2)
	then
		glide_str = "L/D ratio: "..tostring(math.floor(speed_m_s / (-total_energy_m_s) * 100.0) / 100.0)
	else
		glide_str = "L/D ratio: n/a"
	end 
	spoilers_str = "Spoilers:  "..tostring(math.floor(get(sim_speedbrakes) * 100.0) / 100.0)

	-- sasl.gl.drawText(font,30,380,cl_str,40,false,false,TEXT_ALIGN_LEFT,white)
	-- sasl.gl.drawText(font,30,330,cd_str,40,false,false,TEXT_ALIGN_LEFT,white)
	-- sasl.gl.drawText(font,30,280,cm_str,40,false,false,TEXT_ALIGN_LEFT,white)
	sasl.gl.drawText(font,30,230,alpha_str,40,false,false,TEXT_ALIGN_LEFT,white)
	sasl.gl.drawText(font,30,180,spoilers_str,40,false,false,TEXT_ALIGN_LEFT,white)
	sasl.gl.drawText(font,30,130,speed_str,40,false,false,TEXT_ALIGN_LEFT,white)
	sasl.gl.drawText(font,30,80,sink_str,40,false,false,TEXT_ALIGN_LEFT,white)
	sasl.gl.drawText(font,30,30,glide_str,40,false,false,TEXT_ALIGN_LEFT,white)
	
end
