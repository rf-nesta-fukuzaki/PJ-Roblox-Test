-- 数値フォーマットユーティリティ

local Format = {}

-- カンマ区切り (1234567 → "1,234,567"、小数は切り捨て)
function Format.commaNumber(n: number): string
	local s   = tostring(math.floor(math.abs(n)))
	local len = #s
	local result = ""
	for i = 1, len do
		if i > 1 and (len - i) % 3 == 2 then
			result = result .. ","
		end
		result = result .. s:sub(i, i)
	end
	return (n < 0 and "-" or "") .. result
end

-- 短縮表記 (1200 → "1.2K" / 1500000 → "1.5M" / 2300000000 → "2.3B")
function Format.shortNumber(n: number): string
	local abs  = math.abs(n)
	local sign = if n < 0 then "-" else ""
	if abs >= 1e9 then
		return sign .. string.format("%.1f", abs / 1e9) .. "B"
	elseif abs >= 1e6 then
		return sign .. string.format("%.1f", abs / 1e6) .. "M"
	elseif abs >= 1e3 then
		return sign .. string.format("%.1f", abs / 1e3) .. "K"
	else
		return sign .. tostring(math.floor(abs))
	end
end

return Format
