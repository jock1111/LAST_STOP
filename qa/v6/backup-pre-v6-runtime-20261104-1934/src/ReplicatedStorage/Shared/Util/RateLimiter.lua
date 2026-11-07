local RateLimiter = {}
RateLimiter.__index = RateLimiter

function RateLimiter.new(maxCount, windowSeconds)
	return setmetatable({ maxCount = maxCount, windowSeconds = windowSeconds, buckets = {} }, RateLimiter)
end

function RateLimiter:Allow(key)
	local now = os.clock()
	local bucket = self.buckets[key]
	if not bucket or now - bucket.started >= self.windowSeconds then
		self.buckets[key] = { started = now, count = 1 }
		return true
	end
	if bucket.count >= self.maxCount then
		return false
	end
	bucket.count += 1
	return true
end

function RateLimiter:Forget(key)
	self.buckets[key] = nil
end

return RateLimiter
