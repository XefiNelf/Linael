linael :ircvers do

  attr_accessor :irc_channels, :irc_users, :irc_servers

  #The module starts and creates the IRCvers !!
  on_init do
    @irc_servers = {}
  end

  on :nick, :change_nick do
  end

  #When Linael joins a chan, creates the chan in the IRCvers.
  on :join, :channel_joined do |join| 
    #Check if the joiner is Linael
    before(join.who) {|joiner| joiner == Linael::BotNick}
    server = join.server_id
    channel = join.place
    connected_to(server)
    @irc_servers[server].channels[channel] = Linael::IrcChan.new(@irc_servers[server], channel)
  end

  on :server, :test_serv do |msg| 
    p msg
  end

  #When Linael gets a list of users, add them to the chan
  on :server, :channel_users_names do |serv|
    #Check if the server message is RPL_NAMREPLY
    before(serv.code) {|code| code == 353 }
    server = serv.server_id
    connected_to(server)
    @irc_servers[server].add_users_to_chan(serv)
  end


  on :server, :end_of_names do |serv|
    #Check if the server message is RPL_ENDOFNAMES
    before(serv.code) {|code| code == 366 }
    server = serv.server_id
    connected_to(server)
    @irc_servers[server].recieved_all_users(serv)
  end

  on :topic_server, :new_topic_server do |serv|
    #Check if the server message is RPL_TOPIC
    #before(serv.code) {|code| code == 332 }
    channel = serv.place
    server = serv.server_id
    connected_to(server)
    already_joined(server, channel)
    @irc_servers[server].new_chan_topic(serv)
  end

  on :topic, :new_topic do |topic|
    p "poire pomme chocopiu"
    channel = topic.place
    server = topic.server_id
    connected_to(server)
    already_joined(server, channel)
    @irc_servers[server].new_chan_topic(topic)
  end


  on :server, :no_topic do |serv|
    #Check if the server message is RPL_TOPIC
    before(serv.code) {|code| code == 331 }
    server = serv.server_id
    connected_to(server)
    @irc_servers[server].empty_topic(serv)
    p serv
  end

  def connected_to(server)
    unless @irc_servers[server]
      @irc_servers[server] = Linael::IrcServer.new(server)
    end
  end

  def already_joined(server, channel)
    unless @irc_servers[server].channels[channel]
      @irc_servers[server].channels[channel] = Linael::IrcChan.new(@irc_servers[server], channel)
    end
  end

  def topic(server, channel)
    irc_servers[server].channels[channel].topic
  end

end

module Linael

  class IrcServer
    include Irc::Action

    attr_accessor :name, :channels, :users

    def initialize(name)
      @name = name
      @server = self
      @channels = {}
      @users = {}
      add_new_serv_user(Linael::BotNick)
    end
  
    def recieved_all_users(message)
      @channels[message.location.match(/#\S*/).to_s].recieved_all_users
    end

    def add_new_serv_user(name, chan = nil)
      unless @users[name]
        @users[name] = IrcUser.new(@server, name, chans: [chan])
      end
    end

    def add_users_to_chan(message)
      channel = @channels[message.location.match(/#\S*/)]
      message.content.split.each do |name| 
        channel.user_found(name)
      end
    end

    def new_chan_topic(message)
      @channels[message.location.match(/#\S*/).to_s].topic = message.content
    end

    def empty_topic(message)
      @channels[message.location.match(/#\S*/).to_s].topic = ""
    end
  end

  class IrcChan 

    include Irc::Action

    ActionOnRights = { 
      "~" => ->(name) {owner_by_name(name)},
      "&" => ->(name) {sop_by_name(name)},
      "@" => ->(name) {op_by_name(name)},
      "%" => ->(name) {hop_by_name(name)},
      "+" => ->(name) {voice_by_name(name)}
    } 
  
    attr_accessor :name, :server, :chan, :topic, :users, :rights

    def initialize(server, name)
      @server = server
      @chan = self
      @name = name
      @users = {}
      @rights = {}
      @recieving_users = false
    end
 
    [:owner, :sop, :op, :hop, :voice].each do |right|
      define_method("#{right}_by_name") do |name|
        @rights[name] = right
      end
    end


    def user_found(name)
      unless @recieving_users
        @users ={}
        @recieving_users = true
      end
      add_user_called(name)
    end

    def add_user_called(name)
      match_result = name.match(/^(?<right>[~@&+%]{0,1})(?<name>\S*)/)
      add_new_user(match_result.name)
      ActionOnRights[match_result.right].call(match_result.name) unless match_result.right.empty?
    end

    def add_new_user(name)
      @server.add_new_serv_user(name, @chan)
      add_user_chan(name)
      @users[name] = @server.users[name]
    end

    def add_user_chan(name)
      unless @server.users[name].chans[@chan]
        @server.users[name].chans << @chan
      end
    end

    def recieved_all_users
      @recieving_users = false
    end

  end

  class IrcUser

    include Irc::Action

    attr_accessor :current_nick, :nicks, :chans, :mode, :server

    def initialize(server, nick, options = {})
      @server = server
      @current_nick = nick
      (@nicks = []) << nick
      @chans = options[:chans]
      @mode = []
    end

  end

end
