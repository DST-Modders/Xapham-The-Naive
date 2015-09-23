-- This library function allows us to use a file in a specified location.
-- Allows use to call global environment variables without initializing them in our files.
modimport("libs/env.lua")

-- Actions Initialization.
use "data/actions/init"

-- Character Initialization.
use "data/characters/init"

-- Component Initialization.
use "data/components/init"

-- Screens Initialization.
use "data/screens/init"

-- Scripts Initialization.
use "data/scripts/init"

-- Widget Initialization.
use "data/widgets/init"


local MOD_NAME = ""
local MOD_PREFIX = ""
local MOD_ID = ""
local MOD_VERSION = ""

LogHelper:SetModName(MOD_NAME)
LogHelper:PrintInfo("Loaded mod and it's LogHelper.")