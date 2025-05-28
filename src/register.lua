

core.register_privilege("respec_debug", {
  description = "Allows usage of the /respec_debug command to enable respec form debugging",
  give_to_singleplayer = true,
  give_to_admin = true,
})

core.register_chatcommand("respecdebug", {
    func = function(name)
      if not core.check_player_privs(name, "respec_debug") then return end
      local newPrev = not (respec.settings.debug(name))
      respec.settings.set_debug_for(name, newPrev)
      if newPrev then
        core.chat_send_player(name, "Enabled ReSpec form debugging for you "..name)
      else
        core.chat_send_player(name, "Disabled ReSpec form debugging for you "..name)
      end
    end
})
