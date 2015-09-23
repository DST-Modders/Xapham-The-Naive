local function PrintWrongModName(inst)
	print("[LOG HELPER] [WARN] A mod is not setting it's MOD_NAME properly")
end

local LogHelper = Class(function(self, inst)
	self.inst = inst
    self.name = nil
end)

function LogHelper:SetModName(name)
	self.name = name
end

function LogHelper:PrintDebug(message)
	if message and self.name ~= nil then
	print("[".. (self.name).. "] ".. "[DEBUG] ".. (message))
	else 
		PrintWrongModName(inst)
	end
end

function LogHelper:PrintError(message)
	if message and self.name ~= nil then
	print("[".. (self.name).. "] ".. "[ERROR] ".. (message))
	else 
		PrintWrongModName(inst)
	end
end

function LogHelper:PrintFatal(message)
	if message and self.name ~= nil then
	print("[".. (self.name).. "] ".. "[FATAL] ".. (message))
	else 
		PrintWrongModName(inst)
	end
end

function LogHelper:PrintInfo(message)
	if message and self.name ~= nil then
	print("[".. (self.name).. "] ".. "[INFO] ".. (message))
	else 
		PrintWrongModName(inst)
	end
end

function LogHelper:PrintWarn(message)
	if message and self.name ~= nil then
	print("[".. (self.name).. "] ".. "[WARN] ".. (message))
	else 
		PrintWrongModName(inst)
	end
end

return LogHelper
