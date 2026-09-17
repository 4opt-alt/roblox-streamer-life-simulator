--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ShopConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ShopConfig") :: ModuleScript)

-- Ensure Remotes
local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
if not remotesFolder then
    remotesFolder = Instance.new("Folder")
    remotesFolder.Name = "Remotes"
    remotesFolder.Parent = ReplicatedStorage
end

local buyItemRemote = remotesFolder:FindFirstChild("BuyShopItem") :: RemoteEvent?
if not buyItemRemote then
    buyItemRemote = Instance.new("RemoteEvent")
    buyItemRemote.Name = "BuyShopItem"
    buyItemRemote.Parent = remotesFolder
end

local shopResultRemote = remotesFolder:FindFirstChild("ShopItemPurchased") :: RemoteEvent?
if not shopResultRemote then
    shopResultRemote = Instance.new("RemoteEvent")
    shopResultRemote.Name = "ShopItemPurchased"
    shopResultRemote.Parent = remotesFolder
end

local promptRobuxRemote = remotesFolder:FindFirstChild("PromptRobuxPurchase") :: RemoteEvent?
if not promptRobuxRemote then
    promptRobuxRemote = Instance.new("RemoteEvent")
    promptRobuxRemote.Name = "PromptRobuxPurchase"
    promptRobuxRemote.Parent = remotesFolder
end

local MarketplaceService = game:GetService("MarketplaceService")
local MULTISTREAM_GAMEPASS_ID = 99999999 -- Placeholder Gamepass ID


local function recalculateBonuses(player: Player)
    local totalMoneyBonus = 0
    local totalHypeBonus = 0
    local gamesOwned = 0
    local gearOwned = 0

    for itemId, item in ShopConfig do
        if player:GetAttribute("Owned_" .. itemId) == true then
            totalMoneyBonus += item.MoneyBonusPerTick
            totalHypeBonus += item.HypeBonusPerTick
            if item.Category == "Game" then
                gamesOwned += 1
            elseif item.Category == "Gear" then
                gearOwned += 1
            end
        end
    end

    player:SetAttribute("StreamMoneyBonus", totalMoneyBonus)
    player:SetAttribute("StreamHypeBonus", totalHypeBonus)
    player:SetAttribute("GamesOwnedCount", gamesOwned)
    player:SetAttribute("GearOwnedCount", gearOwned)
end

buyItemRemote.OnServerEvent:Connect(function(player: Player, itemId: any)
    if typeof(itemId) ~= "string" then return end

    local item = ShopConfig[itemId]
    if not item then return end

    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then return end

    local moneyVal = leaderstats:FindFirstChild("Money") :: IntValue?
    if not moneyVal then return end

    -- Check balance
    if moneyVal.Value < item.Price then
        shopResultRemote:FireClient(player, itemId, false, "Not enough money!")
        return
    end

    -- Handling Food Consumables
    if item.Category == "Food" then
        moneyVal.Value -= item.Price
        local currentEnergy = (player:GetAttribute("Energy") :: number?) or 100
        local newEnergy = math.min(100, currentEnergy + item.EnergyRestore)
        player:SetAttribute("Energy", newEnergy)
        shopResultRemote:FireClient(player, itemId, true, `Consumed {item.Name}! Energy +{item.EnergyRestore}%`)
        return
    end

    -- Handling Permanent Hardware / Games / License
    if player:GetAttribute("Owned_" .. itemId) == true then
        shopResultRemote:FireClient(player, itemId, false, "Already owned!")
        return
    end

    -- Process purchase
    moneyVal.Value -= item.Price
    player:SetAttribute("Owned_" .. itemId, true)
    recalculateBonuses(player)

    shopResultRemote:FireClient(player, itemId, true, `Successfully purchased {item.Name}!`)
end)

-- Обробка запиту на купівлю ліцензії за Робукси
promptRobuxRemote.OnServerEvent:Connect(function(player: Player, itemId: any)
    if itemId == "MultiStreamLicense" then
        if player:GetAttribute("Owned_MultiStreamLicense") == true then
            shopResultRemote:FireClient(player, itemId, false, "Already owned!")
            return
        end

        local success = pcall(function()
            MarketplaceService:PromptGamePassPurchase(player, MULTISTREAM_GAMEPASS_ID)
        end)

        -- Якщо Gamepass ще не опублікований у хмарі Roblox (локальний тест), активуємо ліцензію для тестування
        if not success or MULTISTREAM_GAMEPASS_ID == 99999999 then
            player:SetAttribute("Owned_MultiStreamLicense", true)
            recalculateBonuses(player)
            shopResultRemote:FireClient(player, itemId, true, "⭐ Multi-Stream Combo unlocked via Robux!")
        end
    end
end)

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player: Player, passId: number, purchased: boolean)
    if purchased and passId == MULTISTREAM_GAMEPASS_ID then
        player:SetAttribute("Owned_MultiStreamLicense", true)
        recalculateBonuses(player)
        shopResultRemote:FireClient(player, "MultiStreamLicense", true, "⭐ Multi-Stream Combo unlocked via Robux!")
    end
end)

Players.PlayerAdded:Connect(function(player)
    player:SetAttribute("StreamMoneyBonus", 0)
    player:SetAttribute("StreamHypeBonus", 0)
    player:SetAttribute("GamesOwnedCount", 0)
    player:SetAttribute("GearOwnedCount", 0)
    player:SetAttribute("Energy", 100)
end)

