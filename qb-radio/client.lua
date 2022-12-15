
local PlayerData = ESX.GetPlayerData() -- Just for resource restart (same as event handler)
local radioMenu = false
local onRadio = false
local RadioChannel = 0
local RadioVolume = 50
local hasRadio = false
local radioProp = nil

--Function
local function LoadAnimDic(dict)
    if not HasAnimDictLoaded(dict) then
        RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do
            Wait(0)
        end
    end
end

local function SplitStr(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        t[#t+1] = str
    end
    return t
end

local function connecttoradio(channel)
    RadioChannel = channel
    if onRadio then
        exports["pma-voice"]:setRadioChannel(0)
    else
        onRadio = true
        exports["pma-voice"]:setVoiceProperty("radioEnabled", true)
    end
    exports["pma-voice"]:setRadioChannel(channel)
    if SplitStr(tostring(channel), ".")[2] ~= nil and SplitStr(tostring(channel), ".")[2] ~= "" then
        ESX.ShowNotification(Config.messages['joined_to_radio'] ..channel.. ' MHz', 'success')
    else
        ESX.ShowNotification(Config.messages['joined_to_radio'] ..channel.. '.00 MHz', 'success')
    end
end

local function closeEvent()
	TriggerEvent("InteractSound_CL:PlayOnOne","click",0.6)
end

local function leaveradio()
    closeEvent()
    RadioChannel = 0
    onRadio = false
    exports["pma-voice"]:setRadioChannel(0)
    exports["pma-voice"]:setVoiceProperty("radioEnabled", false)
    ESX.ShowNotification(Config.messages['you_leave'] , 'error')
end

local function toggleRadioAnimation(pState)
	LoadAnimDic("cellphone@")
	if pState then
		TriggerEvent("attachItemRadio","radio01")
		TaskPlayAnim(PlayerPedId(), "cellphone@", "cellphone_text_read_base", 2.0, 3.0, -1, 49, 0, 0, 0, 0)
		radioProp = CreateObject(`prop_cs_hand_radio`, 1.0, 1.0, 1.0, 1, 1, 0)
		AttachEntityToEntity(radioProp, PlayerPedId(), GetPedBoneIndex(PlayerPedId(), 57005), 0.14, 0.01, -0.02, 110.0, 120.0, -15.0, 1, 0, 0, 0, 2, 1)
	else
		StopAnimTask(PlayerPedId(), "cellphone@", "cellphone_text_read_base", 1.0)
		ClearPedTasks(PlayerPedId())
		if radioProp ~= 0 then
			DeleteObject(radioProp)
			radioProp = 0
		end
	end
end

local function toggleRadio(toggle)
    radioMenu = toggle
    SetNuiFocus(radioMenu, radioMenu)
    if radioMenu then
        toggleRadioAnimation(true)
        SendNUIMessage({type = "open"})
    else
        toggleRadioAnimation(false)
        SendNUIMessage({type = "close"})
    end
end

local function IsRadioOn()
    return onRadio
end

--Exports
exports("IsRadioOn", IsRadioOn)

RegisterNetEvent('qb-radio:use', function()
    toggleRadio(not radioMenu)
end)

RegisterNetEvent('qb-radio:onRadioDrop', function()
    if RadioChannel ~= 0 then
        leaveradio()
    end
end)

AddEventHandler('esx:setPlayerData', function()

    if not ESX.IsPlayerLoaded() then return end

    if Config.OXInventory then
    if exports.ox_inventory:Search('count', 'radio') < 1 and RadioChannel ~= 0 then
        exports['pma-voice']:removePlayerFromRadio()
        RadioChannel = 0
        ESX.ShowNotification(Config.messages['no_radio'])
        end
    else
        ESX.TriggerServerCallback('radio:HasRadioItem', function(cb)
            if not cb then
                exports['pma-voice']:removePlayerFromRadio()
                RadioChannel = 0
                ESX.ShowNotification(Config.messages['no_radio'])
            end
        end)
    end
end)

-- NUI
RegisterNUICallback('joinRadio', function(data, cb)
    local rchannel = tonumber(data.channel)
    if rchannel ~= nil then
        if rchannel <= Config.MaxFrequency and rchannel ~= 0 then
            if rchannel ~= RadioChannel then
                if Config.RestrictedChannels[rchannel] ~= nil then
                    if Config.RestrictedChannels[rchannel][PlayerData.job.name] and PlayerData.job.onduty then
                        connecttoradio(rchannel)
                    else
                        ESX.ShowNotification(Config.messages['restricted_channel_error'], 'error')
                    end
                else
                    connecttoradio(rchannel)
                end
            else
                ESX.ShowNotification(Config.messages['you_on_radio'] , 'error')
            end
        else
            ESX.ShowNotification(Config.messages['invalid_radio'] , 'error')
        end
    else
        ESX.ShowNotification(Config.messages['invalid_radio'] , 'error')
    end
    cb("ok")
end)

RegisterNUICallback('leaveRadio', function(_, cb)
    if RadioChannel == 0 then
        ESX.ShowNotification(Config.messages['not_on_radio'], 'error')
    else
        leaveradio()
    end
    cb("ok")
end)

RegisterNUICallback("volumeUp", function(_, cb)
	if RadioVolume <= 95 then
		RadioVolume = RadioVolume + 5
		ESX.ShowNotification(Config.messages["volume_radio"] .. RadioVolume, "success")
		exports["pma-voice"]:setRadioVolume(RadioVolume)
	else
		ESX.ShowNotification(Config.messages["decrease_radio_volume"], "error")
	end
    cb('ok')
end)

RegisterNUICallback("volumeDown", function(_, cb)
	if RadioVolume >= 10 then
		RadioVolume = RadioVolume - 5
		ESX.ShowNotification(Config.messages["volume_radio"] .. RadioVolume, "success")
		exports["pma-voice"]:setRadioVolume(RadioVolume)
	else
		ESX.ShowNotification(Config.messages["increase_radio_volume"], "error")
	end
    cb('ok')
end)

RegisterNUICallback("increaseradiochannel", function(_, cb)
    local newChannel = RadioChannel + 1
    exports["pma-voice"]:setRadioChannel(newChannel)
    ESX.ShowNotification(Config.messages["increase_decrease_radio_channel"] .. newChannel, "success")
    cb("ok")
end)

RegisterNUICallback("decreaseradiochannel", function(_, cb)
    if not onRadio then return end
    local newChannel = RadioChannel - 1
    if newChannel >= 1 then
        exports["pma-voice"]:setRadioChannel(newChannel)
        ESX.ShowNotification(
            Config.messages["increase_decrease_radio_channel"] .. newChannel, "success")
        cb("ok")
    end
end)

RegisterNUICallback('poweredOff', function(_, cb)
    leaveradio()
    cb("ok")
end)

RegisterNUICallback('escape', function(_, cb)
    toggleRadio(false)
    cb("ok")
end)

--Main Thread
CreateThread(function()
    while true do
        Wait(1000)
        if LocalPlayer.state.isLoggedIn and onRadio then
            if not hasRadio or PlayerData.metadata.isdead or PlayerData.metadata.inlaststand then
                if RadioChannel ~= 0 then
                    leaveradio()
                end
            end
        end
    end
end)
