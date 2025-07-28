local module = {}

function module.ParseLobby(lobby)
	if not lobby then
		return {}
	end

	local c = {}
	for i, v in pairs(lobby) do
		if i ~= "__index" then
			c[i] = v
		end
	end

	return c
end

return module
