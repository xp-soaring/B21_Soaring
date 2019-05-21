-- B21_soaring Total Energy calculation

-- DataRefs out
--    b21_soaring/total_energy_m_s
--    b21_soaring/total_energy_fpm
--    b21_soaring/total_energy_kts

components = {}

-- Vario calculations using only time, aircraft altitude and speed (i.e. not relying on TE calculations inside X-Plane)
-- 
-- Assuming 'TIME' is time between updates. Units: time=seconds, height=meters, speeds=meters/second, g=9.81
--
-- TOTAL ENERGY CLIMB RATE = (PLAIN CLIMB RATE) + (ENERGY GAIN/LOSS ADJUSTMENT)
-- PLAIN CLIMB RATE = (HEIGHT NOW - HEIGHT BEFORE) / TIME
-- ENERGY GAIN/LOSS ADJUSTMENT = ((SPEED NOW)^2 - (SPEED BEFORE)^2) / (2 * g * TIME)

-- ----------------------------------------------
-- DATAREFS

-- the datarefs we will READ to get time, altitude and speed from the sim
local sim_time_s = globalPropertyf("sim/network/misc/network_time_sec")
local sim_alt_ft = globalPropertyf("sim/cockpit2/gauges/indicators/altitude_ft_pilot")
local sim_alt_m = globalPropertyf("sim/flightmodel/position/elevation")
local sim_speed_kts = globalPropertyf("sim/cockpit2/gauges/indicators/airspeed_kts_pilot")
local sim_speed_m_s = globalPropertyf("sim/flightmodel/position/true_airspeed")
-- create global DataRefs we will WRITE (name, default, isNotPublished, isShared, isReadOnly)
dataref_te_m_s = createGlobalPropertyf("b21_soaring/total_energy_m_s", 0.0, false, true, true)
dataref_te_fpm = createGlobalPropertyf("b21_soaring/total_energy_fpm", 0.0, false, true, true)
dataref_te_kts = createGlobalPropertyf("b21_soaring/total_energy_kts", 0.0, false, true, true)

--
-- ----------------------------------------------

-- ----------------------------------------------
-- GLOBALS used between each iteration
-- previous update time (float seconds)
local prev_time_s = 0

-- previous altitude (float meters)
local prev_alt_m = 0

-- previous speed squared (float (m/s)^2 )
local prev_speed_m_s_2 = 0

function update()
	
	-- calculate time (float seconds) since previous update
	local time_delta_s = get(sim_time_s) - prev_time_s
	
	-- only update max 20 times per second (i.e. time delta > 0.05 seconds)
	if time_delta_s > 0.05
	then
		-- get current speed in m/s
		-- local speed_m_s = get(sim_speed_kts) * 0.514444
		local speed_m_s = get(sim_speed_m_s)

		-- calculate current speed squared (m/s)^2
		local speed_m_s_2 = speed_m_s * speed_m_s
		
		-- TE speed adjustment (m/s)
		local te_adj_m_s = (speed_m_s_2 - prev_speed_m_s_2) / (2 * 9.81 * time_delta_s)
		
		-- calculate altitude delta (meters) since last update
		-- local alt_delta_m = get(sim_alt_ft) * 0.3048 - prev_alt_m
		local alt_delta_m = get(sim_alt_m) - prev_alt_m
		
		-- calculate plain climb rate
		local climb_m_s = alt_delta_m / time_delta_s
		
		-- calculate new vario compensated reading using 50% current and 50% new (for smoothing)
		local te_m_s = get(dataref_te_m_s) * 0.5 + (climb_m_s + te_adj_m_s) * 0.5
		
		-- limit the reading to 7 m/s max to avoid a long recovery time from the smoothing
		if te_m_s > 7
		then
			te_m_s = 7
		end
		
		-- all good, transfer value to the needle
        -- write value to datarefs
        set(dataref_te_m_s, te_m_s) -- meters per second

        set(dataref_te_fpm, te_m_s * 196.85) -- feet per minute

        set(dataref_te_kts, te_m_s * 1.94384) -- knots
		
		-- store time, altitude and speed^2 as starting values for next iteration
		prev_time_s = get(sim_time_s)
		-- prev_alt_m = get(sim_alt_ft) * 0.3048
		prev_alt_m = get(sim_alt_m)
		prev_speed_m_s_2 = speed_m_s_2
	end
		
end -- function
