if ( C_Timer ) then return end

-- Looping animation groups accumulate elapsed time toward their duration, resetting on loop.
-- Near 2048s, float32 precision drops enough that tiny deltas (<~0.000122s) can get lost.
-- That precision loss is rare, but if it happens, the animation can stall and potentially
-- freeze the client. Splitting intervals into 30-minute chunks avoids the 2048s boundary
-- without affecting standard non-looping timers.

local _G = _G
local Type = type
local PCall = pcall
local Ceil = math.ceil
local SetMetaTable = setmetatable
local CallErrorHandler = CallErrorHandler

local MAX_CHUNK_DURATION = 1800

local C_Timer = CreateFrame("Frame")
local Pool = {}
local PoolTotal = 0

local Prototype = {
	Cancel = function(Proxy)
		local Timer = Proxy.__Timer
		if ( Timer ) then
			Proxy.__Timer = nil

			Timer:Stop()
			Timer.Chunk = nil
			Timer.Proxy = nil
			Timer.Iteration = nil
			Timer.ChunkTotal = nil

			if ( Timer.Callback ) then
				Timer.Callback = nil
				PoolTotal = PoolTotal + 1
				Pool[PoolTotal] = Timer
			end
		end
	end,

	IsCancelled = function(Proxy)
		return Proxy.__Timer == nil
	end
} Prototype.__index = Prototype

local function Process(Timer)
	local Chunk = Timer.Chunk
	if ( Chunk ) then
		if ( Chunk > 1 ) then
			Timer.Chunk = Chunk - 1
			return
		end
		Timer.Chunk = Timer.ChunkTotal
	end

	local Callback = Timer.Callback
	Timer.Callback = nil

	local Success, Err = PCall(Callback, Timer.Proxy)
	if ( not Success ) then
		CallErrorHandler(Err)
	end

	if ( Timer.Proxy ) then
		Timer.Callback = Callback

		local Iteration = Timer.Iteration
		if ( Iteration ) then
			if ( Iteration == 1 ) then
				Timer.Proxy:Cancel()
			else
				Timer.Iteration = Iteration - 1
			end
		end
	else
		PoolTotal = PoolTotal + 1
		Pool[PoolTotal] = Timer
	end
end

local function Create(Duration, Callback, Iteration, Cancellable)
	local Timer
	local Proxy
	local Looping = Cancellable and (not Iteration or Iteration > 1)

	if ( PoolTotal > 0 ) then
		Timer = Pool[PoolTotal]
		Pool[PoolTotal] = nil
		PoolTotal = PoolTotal - 1
	else
		local AG = C_Timer:CreateAnimationGroup()
		Timer = AG:CreateAnimation()
		Timer:SetScript("OnFinished", Process)
	end

	if ( Cancellable ) then
		Proxy = SetMetaTable({}, Prototype)
		Proxy.__Timer = Timer
		Timer.Proxy = Proxy
		Timer.Iteration = Iteration
	end

	if ( Looping and Duration > MAX_CHUNK_DURATION ) then
		local ChunkTotal = Ceil(Duration / MAX_CHUNK_DURATION)
		Timer.Chunk = ChunkTotal
		Timer.ChunkTotal = ChunkTotal
		Duration = Duration / ChunkTotal
	end

	Timer.Callback = Callback
	Timer:GetParent():SetLooping(Looping and "REPEAT" or "NONE")
	Timer:SetDuration(Duration > 0.01 and Duration or 0.01)
	Timer:Play()

	return Proxy
end

function C_Timer.After(Duration, Callback, _)
	if ( Type(Duration) ~= "number" ) then Duration, Callback = Callback, _ end
	Create(Duration, Callback)
end

function C_Timer.NewTimer(Duration, Callback, _)
	if ( Type(Duration) ~= "number" ) then Duration, Callback = Callback, _ end
	return Create(Duration, Callback, 1, true)
end

function C_Timer.NewTicker(Duration, Callback, Iteration, _)
	if ( Type(Duration) ~= "number" ) then Duration, Callback, Iteration = Callback, Iteration, _ end
	return Create(Duration, Callback, Iteration, true)
end

-- Global
_G.C_Timer = C_Timer
C_Timer._version = 2 -- Defined to avoid overwriting by other implementations.