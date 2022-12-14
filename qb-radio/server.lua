for channel, config in pairs(Config.RestrictedChannels) do
    exports['pma-voice']:addChannelCheck(channel, function(source)
        local Player = QBCore.Functions.GetPlayer(source)
        return config[Player.PlayerData.job.name] and Player.PlayerData.job.onduty
    end)
end

ESX.RegisterServerCallback('radio:HasRadioItem', function(src, cb)
    local xPlayer = ESX.GetPlayerFromId(src)

    if xPlayer.hasItem('radio') then
        cb(true)
    else
        cb(false)
    end
end)