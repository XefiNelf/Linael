# -*- encoding : utf-8 -*-

module Linael

  class AdminChan < ActiveRecord::Base

    scope :joined, -> {where(joined: true)}

    def self.new_chan server_id, chan      
      create(name: chan, server_id: server_id.to_s)
    end

    def self.find_or_create(server_id, chan)
      chan = chan.downcase
      unless result_chan = find_by_server_id_and_name(server_id, chan)
        result_chan = new_chan(server_id, chan)
      end
      result_chan
    end

    def self.join server_id, chan
      chan = find_or_create(server_id, chan)
      chan.join_date = Time.now
      chan.joined = true
      chan.save
    end

    def self.part server_id,chan
      chan = find_or_create(server_id, chan)
      chan.part_date = Time.now
      chan.joined = false
      chan.save
    end

  end
end

#A module for adminsitration
linael :admin, require_auth: true do

  help [
    t.admin.help.description,
    t.help.helper.line.white,
    t.help.helper.line.admin,
    t.admin.help.function.join,
    t.admin.help.function.part,
    t.admin.help.function.kick,
    t.admin.help.function.die,
    t.admin.help.function.mode,
    t.admin.help.function.reload
  ]

  on_init do
    Linael::AdminChan.joined.each do |chan|
      join_channel chan.server_id, :dest => chan.name
    end
  end

  def join_act server_id, chan
    Linael::AdminChan.join(server_id, chan)
    join_channel server_id, :dest => chan
  end

  def part_act server_id, chan
    talk(chan,t.admin.act.part.message,server_id)
    Linael::AdminChan.part(server_id, chan)
    part_channel server_id, :dest => chan
  end

  def die_act server_id
    quit_channel server_id, :msg => t.admin.act.die.message
    exit! 0
  end

  def kick_act server_id, who,chan,reason
    talk(chan,t.admin.act.kick.message(who),server_id)
    kick_channel server_id, :dest => chan,
                 :who  => who, 
                 :msg  => reason
  end

  def mode_act server_id, chan,what,args
    mode_channel  server_id,
                  :dest => chan,
                  :what => what,
                  :args => args
  end

  #join chan
  on :cmd_auth, :join, /^!admin_join\s|^!join\s|^!j\s/ do |msg,options|
    answer(msg,t.admin.act.join.answer(options.chan))	
    join_act msg.server_id, options.chan
  end

  #part chan
  on :cmd_auth, :part, /^!admin_part\s|^!part\s/ do |msg,options|
    answer(msg,t.admin.act.part.answer(options.chan))	
    part_act msg.server_id, options.chan
  end

  #exit 0
  on :cmd_auth, :die, /^!admin_die\s/ do |msg,options|
    answer(msg,t.admin.act.die.answer)
    die_act msg.server_id
  end

  #kick
  on :cmd_auth, :kick, /^!admin_kick\s|^!kick\s|^!k\s/ do |msg,options|
    answer(msg,t.admin.act.kick.answer(options.who,options.chan))	
    kick_act msg.server_id, options.who, options.chan, options.reason
  end

  #(re)load a file
  on :cmd_auth, :reload, /^!admin_reload\s/ do |msg,options|
    answer(msg,t.admin.act.reload.answer(options.what)) if load options.what
  end

  #change mode on a chan
  on :cmd_auth, :mode, /^!admin_mode\s|^!mode\s/ do |msg,options|
    answer(msg,t.admin.act.mode.answer("#{options.what} #{options.reason+" " unless options.reason.empty?}",options.chan))
    mode_act msg.server_id, options.chan, options.what, options.reason
  end

end

