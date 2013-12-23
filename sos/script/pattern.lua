local function Next()
	pattern.index = pattern.index + 1
end

local function Schedule(timeout)
	if pattern.timer then
		eapi.CancelTimer(pattern.timer)
	end
	local function CallBack()
		pattern.timer = nil
		pattern.list[pattern.index]()
	end
	pattern.timer = eapi.AddTimer(staticBody, timeout, CallBack)
end

local function Register(PatternFn)
	pattern.list[#pattern.list + 1] = PatternFn
end

pattern = {
	Schedule = Schedule,
	Register = Register,
	Next = Next,
	list = { },	
	index = 1,
}
return pattern
