local NumberUtil = {}

function NumberUtil.formatInteger(value)
	value = math.floor(tonumber(value) or 0)

	local sign = ""
	if value < 0 then
		sign = "-"
		value = math.abs(value)
	end

	local text = tostring(value)
	local result = text

	while true do
		local changed
		result, changed = string.gsub(result, "^(-?%d+)(%d%d%d)", "%1,%2")
		if changed == 0 then
			break
		end
	end

	return sign .. result
end

return NumberUtil
