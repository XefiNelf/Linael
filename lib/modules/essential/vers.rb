linael :vers do

  on_init do
    @ircvers = mod("ircvers")
  end

  on :cmd, :tellname, /^!tellchan/ do |msg,options|
    talk(msg.where, "#{@ircvers.irc_servers[msg.server_id].channels[msg.where].name}", msg.server_id)
  end

  on :cmd, :tellserv, /^!tellserv/ do |msg,options|
    talk(msg.where, "#{@ircvers.irc_servers[msg.server_id].name}", msg.server_id)
  end

  on :cmd, :tellusers, /^!tellusers/ do |msg,options|
    talk(msg.where, "#{@ircvers.irc_servers[msg.server_id].channels[msg.where].users}", msg.server_id)
  end
 
  on :cmd, :telltopic, /^!telltopic/ do |msg,options|
    talk(msg.where, @ircvers.topic(msg.server_id, msg.where), msg.server_id)
  end




end
