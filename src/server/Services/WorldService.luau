local Players = game:GetService("Players")

local WorldService = {}

function WorldService:Start()
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			player:SetAttribute("CurrentStuds", 0)
			player:SetAttribute("CurrentFloor", 0)
			player:SetAttribute("RunBestStuds", 0)
			player:SetAttribute("LastReward", 0)
			player:SetAttribute("Insanity", 0)
			player:SetAttribute("InsanityActive", false)
			player:SetAttribute("InsanityCollapsed", false)
		end)
	end)
end

return WorldService