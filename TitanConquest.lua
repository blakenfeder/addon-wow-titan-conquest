--[[
  TitanConquest: A simple Display of current Conquest value
  Author: Blakenfeder
--]]

-- Define addon base object
local TitanConquest = {
  Const = {
    Id = "Conquest",
    Name = "TitanConquest",
    DisplayName = "Titan Panel [Conquest]",
    Version = "",
    Author = "",
  },
  IsInitialized = false,
}
function TitanConquest.GetCurrencyInfo()
  local i = 0
  for i = 1, C_CurrencyInfo.GetCurrencyListSize(), 1 do
    info = C_CurrencyInfo.GetCurrencyListInfo(i)
    
    -- if (not TitanConquest.IsInitialized and DEFAULT_CHAT_FRAME) then
    --   print(info.name, tostring(info.iconFileID))
    -- end
    
    if tostring(info.iconFileID) == "1523630" then
      return info
    end
  end
end
function TitanConquest.Util_GetFormattedNumber(number)
  if number >= 1000 then
    return string.format("%d,%03d", number / 1000, number % 1000)
  else
    return string.format ("%d", number)
  end
end

-- Load metadata
TitanConquest.Const.Version = GetAddOnMetadata(TitanConquest.Const.Name, "Version")
TitanConquest.Const.Author = GetAddOnMetadata(TitanConquest.Const.Name, "Author")

-- Text colors (AARRGGBB)
local BKFD_C_BURGUNDY = "|cff993300"
local BKFD_C_GRAY = "|cff999999"
local BKFD_C_GREEN = "|cff00ff00"
local BKFD_C_ORANGE = "|cffff8000"
local BKFD_C_WHITE = "|cffffffff"
local BKFD_C_YELLOW = "|cffffcc00"

-- Text item colors (AARRGGBB)
local BKFD_C_RARE = "|cff0070dd"
local BKFD_C_EPIC = "|cffa335ee"

-- Load Library references
local LT = LibStub("AceLocale-3.0"):GetLocale("Titan", true)
local L = LibStub("AceLocale-3.0"):GetLocale(TitanConquest.Const.Id, true)

-- Currency update variables
local BKFD_RA_UPDATE_FREQUENCY = 0.0
local currencyCount = 0.0
local currencyMaximum
local seasonalCount = 0.0
local isSeasonal = false

function TitanPanelConquestButton_OnLoad(self)
  self.registry = {
    id = TitanConquest.Const.Id,
    category = "Information",
    version = TitanConquest.Const.Version,
    menuText = L["BKFD_TITAN_RA_MENU_TEXT"], 
    buttonTextFunction = "TitanPanelConquestButton_GetButtonText",
    tooltipTitle = BKFD_C_EPIC..L["BKFD_TITAN_RA_TOOLTIP_TITLE"],
    tooltipTextFunction = "TitanPanelConquestButton_GetTooltipText",
    icon = "Interface\\Icons\\achievement_legionpvp2tier3",
    iconWidth = 16,
    controlVariables = {
      ShowIcon = true,
      ShowLabelText = true,
    },
    savedVariables = {
      ShowIcon = 1,
      ShowLabelText = false,
      ShowColoredText = false,
    },
    -- frequency = 2,
  };


  self:RegisterEvent("PLAYER_ENTERING_WORLD");
  self:RegisterEvent("PLAYER_LOGOUT");
end

function TitanPanelConquestButton_GetButtonText(id)
  local currencyCountText
  if not currencyCount then
    currencyCountText = "??"
  else  
    currencyCountText = TitanConquest.Util_GetFormattedNumber(currencyCount)
  end

  return L["BKFD_TITAN_RA_BUTTON_LABEL"], TitanUtils_GetHighlightText(currencyCountText)
end

function TitanPanelConquestButton_GetTooltipText()

  -- Set which total value will be displayed
  local tooltipCurrencyCount = currencyCount
  if (isSeasonal) then
    tooltipCurrencyCount = seasonalCount
  end

  -- Set how the total value will be displayed
  local totalValue = string.format(
    "%s/%s",
    TitanConquest.Util_GetFormattedNumber(tooltipCurrencyCount),
    TitanConquest.Util_GetFormattedNumber(currencyMaximum)
  )
  if (not currencyMaximum or currencyMaximum == 0) then
    totalValue = string.format(
      "%s",
      TitanConquest.Util_GetFormattedNumber(tooltipCurrencyCount)
    )
  end
  
  local totalLabel = L["BKFD_TITAN_RA_TOOLTIP_COUNT_LABEL_TOTAL_MAXIMUM"]
  if (isSeasonal) then
    totalLabel = L["BKFD_TITAN_RA_TOOLTIP_COUNT_LABEL_TOTAL_SEASONAL"]
  elseif (not currencyMaximum or currencyMaximum == 0) then
    totalLabel = L["BKFD_TITAN_RA_TOOLTIP_COUNT_LABEL_TOTAL"]
  end

  return
    L["BKFD_TITAN_RA_TOOLTIP_DESCRIPTION"].."\r"..
    " \r"..
    totalLabel..TitanUtils_GetHighlightText(totalValue)
end

function TitanPanelConquestButton_OnUpdate(self, elapsed)
  BKFD_RA_UPDATE_FREQUENCY = BKFD_RA_UPDATE_FREQUENCY - elapsed;

  if BKFD_RA_UPDATE_FREQUENCY <= 0 then
    BKFD_RA_UPDATE_FREQUENCY = 1;

    local info = TitanConquest.GetCurrencyInfo()
    if (info) then
      currencyCount = tonumber(info.quantity)
      currencyMaximum = tonumber(info.maxQuantity)
      seasonalCount = tonumber(info.totalEarned)
      isSeasonal = info.useTotalEarnedForMaxQty
    end

    TitanPanelButton_UpdateButton(TitanConquest.Const.Id)
  end
end

function TitanPanelConquestButton_OnEvent(self, event, ...)
  if (event == "PLAYER_ENTERING_WORLD") then
    if (not TitanConquest.IsInitialized and DEFAULT_CHAT_FRAME) then
      DEFAULT_CHAT_FRAME:AddMessage(
        BKFD_C_YELLOW..TitanConquest.Const.DisplayName.." "..
        BKFD_C_GREEN..TitanConquest.Const.Version..
        BKFD_C_YELLOW.." by "..
        BKFD_C_ORANGE..TitanConquest.Const.Author)
      -- TitanConquest.GetCurrencyInfo()
      TitanPanelButton_UpdateButton(TitanConquest.Const.Id)
      TitanConquest.IsInitialized = true
    end
    return;
  end  
  if (event == "PLAYER_LOGOUT") then
    TitanConquest.IsInitialized = false;
    return;
  end
end

function TitanPanelRightClickMenu_PrepareConquestMenu()
  local id = TitanConquest.Const.Id;

  TitanPanelRightClickMenu_AddTitle(TitanPlugins[id].menuText)
  
  TitanPanelRightClickMenu_AddToggleIcon(id)
  TitanPanelRightClickMenu_AddToggleLabelText(id)
  TitanPanelRightClickMenu_AddSpacer()
  TitanPanelRightClickMenu_AddCommand(LT["TITAN_PANEL_MENU_HIDE"], id, TITAN_PANEL_MENU_FUNC_HIDE)
end