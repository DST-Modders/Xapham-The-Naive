local function IsValidOwner(inst, owner)
	local self = inst.components.characterlocked
	return owner:HasTag(self.ownertag)
end

local function OwnerAlreadyHasItem(inst, owner)
	local self = inst.components.characterlocked
    local equip = owner.components.inventory:GetEquippedItem(self.equipslot)
    return equip ~= inst
        and equip ~= nil
        and equip.components.characterlocked ~= nil
        and equip
        or owner.components.inventory:FindItem(function(item)
                return item.components.characterlocked ~= nil and item ~= inst
        end)
end

local function OnCheckOwner(inst, self)
    self.checkownertask = nil
    local owner = inst.components.inventoryitem:GetGrandOwner()
    if owner == nil or owner.components.inventory == nil then
        return
    elseif not IsValidOwner(inst, owner) then
        self:Drop()
        inst:PushEvent("itemrejectedowner", owner)
    else
        local other = OwnerAlreadyHasItem(inst, owner)
        if other ~= nil then
            self:Drop()
            other:PushEvent("itemrejectedself", inst)
        elseif owner:HasTag("player") then
            self:LinkToPlayer(owner)
        end
    end
end

local function OnChangeOwner(inst, owner)
    local self = inst.components.characterlocked
    if self.currentowner == owner then
        return
    elseif self.currentowner ~= nil and self.oncontainerpickedup ~= nil then
        inst:RemoveEventCallback("onputininventory", self.oncontainerpickedup, self.currentowner)
        self.oncontainerpickedup = nil
    end

    if self.checkownertask ~= nil then
        self.checkownertask:Cancel()
        self.checkownertask = nil
    end

    self.currentowner = owner

    if owner == nil then
        return
    elseif owner.components.inventoryitem ~= nil then
        self.oncontainerpickedup = function()
            if self.checkownertask ~= nil then
                self.checkownertask:Cancel()
            end
            self.checkownertask = inst:DoTaskInTime(0, OnCheckOwner, self)
        end
        inst:ListenForEvent("onputininventory", self.oncontainerpickedup, owner)
    end
    self.checkownertask = inst:DoTaskInTime(0, OnCheckOwner, self)
end

local CharacterLocked = Class(function(self, inst)
    self.inst = inst

    self.player = nil --player link even if the item is dropped
    self.userid = nil --userid even if player link disconnects
    self.currentowner = nil --inventoryitem owner
    self.oncontainerpickedup = nil
    self.checkownertask = nil
    self.waittask = nil
    self.waittotime = nil
	self.ownertag = nil
	self.equipslot = nil

    self.onplayerdied = function() self:WaitForPlayer(nil, 3) end
    self.onplayerremoved = function() self:WaitForPlayer(self.userid) end
    self.onplayerjoined = function(world, player)
        if player.userid == self.userid then
            if IsValidOwner(inst, player) and OwnerAlreadyHasItem(inst, player) == nil then
                self:LinkToPlayer(player)
            end
        end
    end

    inst:ListenForEvent("onputininventory", OnChangeOwner)
    inst:ListenForEvent("ondropped", OnChangeOwner)
end)

local function OnEndWait(inst, self)
    self.waittask = nil
    self.waittotime = nil
end

function CharacterLocked:SetItemSlot(equipslot)
	self.equipslot = equipslot
end

function CharacterLocked:SetOwnerTag(ownertag)
	self.ownertag = ownertag
end

function CharacterLocked:WaitForPlayer(userid, delay)
    self:LinkToPlayer(nil)
    self.userid = userid
    if self.waittask ~= nil then
        self.waittask:Cancel()
        if userid == nil then
            self.inst:RemoveEventCallback("ms_playerjoined", self.onplayerjoined, TheWorld)
        end
    elseif userid ~= nil then
        self.inst:ListenForEvent("ms_playerjoined", self.onplayerjoined, TheWorld)
    end
    delay = delay or TUNING.LUCY_REVERT_TIME
    self.waittask = self.inst:DoTaskInTime(delay, OnEndWait, self)
    self.waittotime = GetTime() + delay
end

function CharacterLocked:StopWaitingForPlayer()
    if self.waittask == nil then
        return
    end
    self.waittask:Cancel()
    self.waittask = nil
    self.waittotime = nil
    if self.userid ~= nil then
        self.userid = nil
        self.inst:RemoveEventCallback("ms_playerjoined", self.onplayerjoined, TheWorld)
    end
end

function CharacterLocked:LinkToPlayer(player)
    self:StopWaitingForPlayer()

    if self.player == player then
        return
    elseif self.player ~= nil then
        self.inst:RemoveEventCallback("onremove", self.onplayerremoved, self.player)
    end

    self.player = player
    if player == nil then
        self.userid = nil
        self.inst:PushEvent("itempossessedbyplayer", nil)
        return
    end
    self.userid = player.userid

    player:PushEvent("characterlocked", self.inst)
    self.inst:ListenForEvent("onremove", self.onplayerremoved, player)
    self.inst:PushEvent("itempossessedbyplayer", player)
end

function CharacterLocked:Drop()
    local owner = self.inst.components.inventoryitem:GetGrandOwner()
    if owner ~= nil and owner.components.inventory ~= nil then
        owner.components.inventory:DropItem(self.inst, true, true)
    end
end

function CharacterLocked:OnSave()
    local data =
    {
        userid = self.userid,
        waittimeremaining = self.waittotime ~= nil and self.waittotime - GetTime() or nil,
    }
    return next(data) ~= nil and data or nil
end

function CharacterLocked:OnLoad(data)
    if data ~= nil then
        if self.player == nil
            and (data.waittimeremaining ~= nil
                or (data.userid ~= nil and data.userid ~= self.userid)) then
            self:LinkToPlayer(nil)
            self:WaitForPlayer(data.userid, data.waittimeremaining ~= nil and math.max(0, data.waittimeremaining) or nil)
        end
    end
end

function CharacterLocked:GetDebugString()
    return "held: "..tostring(self.currentowner)
        .." player: "..tostring(self.player)
        ..string.format(" timeout: %2.2f", self.waittotime ~= nil and self.waittotime - GetTime() or 0)
end

return CharacterLocked
