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

local broadcastSuperChatRemote = remotesFolder:FindFirstChild("BroadcastSuperChat") :: RemoteEvent?
if not broadcastSuperChatRemote then
    broadcastSuperChatRemote = Instance.new("RemoteEvent")
    broadcastSuperChatRemote.Name = "BroadcastSuperChat"
    broadcastSuperChatRemote.Parent = remotesFolder
end

local MarketplaceService = game:GetService("MarketplaceService")
local MULTISTREAM_GAMEPASS_ID = 99999999 -- Placeholder Gamepass ID
local VIP_GAMEPASS_ID = 88888888 -- Placeholder VIP Gamepass ID


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

local function grantRobuxProduct(player: Player, productId: string)
    local leaderstats = player:FindFirstChild("leaderstats")
    local moneyVal = leaderstats and leaderstats:FindFirstChild("Money") :: IntValue?
    local hypeVal = leaderstats and leaderstats:FindFirstChild("Hype") :: IntValue?

    if productId == "Pass_VIP" then
        if player:GetAttribute("Owned_Pass_VIP") == true then
            shopResultRemote:FireClient(player, productId, false, "VIP Pass is already owned!")
            return
        end
        player:SetAttribute("Owned_Pass_VIP", true)
        player:SetAttribute("IsVIP", true)
        recalculateBonuses(player)
        shopResultRemote:FireClient(player, productId, true, "👑 VIP Status Activated! Permanent +50% Cash & +25% Subs!")
    elseif productId == "Boost_Viral2X" then
        local now = os.time()
        local currentExpiry = math.max(now, (player:GetAttribute("ViralBoostExpiry") :: number?) or 0)
        local newExpiry = currentExpiry + 15 * 60
        player:SetAttribute("ViralBoostExpiry", newExpiry)
        shopResultRemote:FireClient(player, productId, true, "🚀 2X Viral Stream Boost Activated for 15 minutes!")
    elseif productId == "Surge_Energy" then
        player:SetAttribute("Energy", 100)
        local now = os.time()
        local currentEnergyExp = math.max(now, (player:GetAttribute("InfiniteEnergyExpiry") :: number?) or 0)
        local newExpiry = currentEnergyExp + 5 * 60
        player:SetAttribute("InfiniteEnergyExpiry", newExpiry)
        shopResultRemote:FireClient(player, productId, true, "⚡ Energy Refilled to 100% & Infinite Stamina for 5 mins!")
    elseif productId == "Alert_SuperChat" then
        if moneyVal then moneyVal.Value += 200 end
        if hypeVal then hypeVal.Value += 500 end
        broadcastSuperChatRemote:FireAllClients(player.DisplayName, 500)
        shopResultRemote:FireClient(player, productId, true, "📣 Super-Chat Broadcast Sent to entire server! +$200 & +500 Subs!")
    elseif productId == "Cash_Pack_Small" then
        if moneyVal then moneyVal.Value += 300 end
        shopResultRemote:FireClient(player, productId, true, "💵 +$300 Cash Added to your balance!")
    elseif productId == "Cash_Pack_Medium" then
        if moneyVal then moneyVal.Value += 1500 end
        shopResultRemote:FireClient(player, productId, true, "💰 +$1,500 Cash Added to your balance!")
    elseif productId == "Cash_Pack_Large" then
        if moneyVal then moneyVal.Value += 5000 end
        shopResultRemote:FireClient(player, productId, true, "💎 +$5,000 Cash Added to your balance!")
    elseif productId == "MultiStreamLicense" then
        if player:GetAttribute("Owned_MultiStreamLicense") == true then
            shopResultRemote:FireClient(player, productId, false, "Multi-Stream is already owned!")
            return
        end
        player:SetAttribute("Owned_MultiStreamLicense", true)
        recalculateBonuses(player)
        shopResultRemote:FireClient(player, productId, true, "⭐ Multi-Stream Combo (YouTube + Twitch) unlocked!")
    end
end

promptRobuxRemote.OnServerEvent:Connect(function(player: Player, productId: any)
    if typeof(productId) ~= "string" then return end

    local robuxProducts = (ShopConfig :: any).RobuxProducts
    local prod = robuxProducts and robuxProducts[productId]
    if not prod then return end

    if prod.Type == "GamePass" then
        local passId = (productId == "Pass_VIP") and VIP_GAMEPASS_ID or MULTISTREAM_GAMEPASS_ID
        local success = pcall(function()
            MarketplaceService:PromptGamePassPurchase(player, passId)
        end)
        -- Fallback for local Studio testing where pass is unlisted
        if not success or passId == 99999999 or passId == 88888888 then
            grantRobuxProduct(player, productId)
        end
    else
        -- Developer Product purchase
        local mockProductId = 12345678
        local success = pcall(function()
            MarketplaceService:PromptProductPurchase(player, mockProductId)
        end)
        -- Fallback for local Studio testing
        if not success or mockProductId == 12345678 then
            grantRobuxProduct(player, productId)
        end
    end
end)

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player: Player, passId: number, purchased: boolean)
    if purchased then
        if passId == MULTISTREAM_GAMEPASS_ID then
            grantRobuxProduct(player, "MultiStreamLicense")
        elseif passId == VIP_GAMEPASS_ID then
            grantRobuxProduct(player, "Pass_VIP")
        end
    end
end)

Players.PlayerAdded:Connect(function(player)
    player:SetAttribute("StreamMoneyBonus", 0)
    player:SetAttribute("StreamHypeBonus", 0)
    player:SetAttribute("GamesOwnedCount", 0)
    player:SetAttribute("GearOwnedCount", 0)
    player:SetAttribute("Energy", 100)
    player:SetAttribute("ViralBoostExpiry", 0)
    player:SetAttribute("InfiniteEnergyExpiry", 0)
    player:SetAttribute("IsVIP", false)
end)


