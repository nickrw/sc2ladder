#!/usr/bin/env ruby

require 'ggtracker'
require 'action_view'
require 'sinatra'
require 'json'

module SC2Ladder

  class SC2Ladder::Settings
    attr_accessor :types, :teamtag, :teamname, :players
    def initialize
      @vardir = File.expand_path(File.join(Dir.home, ".sc2ladder"))
      @file = File.expand_path(File.join(@vardir, "settings.json"))

      @valid_types = ['1v1', '2v2', '3v3', '4v4', 'FFA']

      @types = []
      @teamtag = ''
      @teamname = ''
      @players = {}
      read
    end

    def inspect
      "#<#{self.class} #setup?=#{setup?} @types=#{@types.inspect} @team=\"[#{@teamtag}] #{@teamname}\" @players=#{@players.keys.map {|x| x.id}}"
    end

    def read
      ensure_file
      s = JSON.parse(IO.read(@file))
      s.each do |key, val|
        case key

        when "types"
          @types = []
          next if not valid_types?(val)
          @types = val

        when "teamtag"
          @teamtag = ''
          next if not valid_teamtag?(val)
          @teamtag = val

        when "teamname"
          @teamname = ''
          next if not valid_teamname?(val)
          @teamname = val

        when "players"
          @players = {}
          players_to_be = {}
          next if val.class != Hash
          val.each do |player_id, player_alias|
            player_id = player_id.to_i
            player = GGTracker::Identity.factory(player_id)
            players_to_be[player] = player_alias
            if valid_alias?(player_alias)
              player.alias = player_alias
            end
          end
          next if not valid_players?(players_to_be)
          @players = players_to_be

        end
      end
    end

    def setup?
      return false if not valid_teamname?(@teamname)
      return false if not valid_teamtag?(@teamtag)
      return false if not valid_types?(@types)
      return false if not valid_players?(@players)
      return true
    end

    def add_player(player_id, player_alias=nil)
      p = GGTracker::Identity.factory(player_id)
      return false if not valid_player?(p)
      if not player_alias.nil?
        return false if not valid_alias?(player_alias)
        p.alias = player_alias
      end
      @players[p] = player_alias
    end

    def write
      ensure_file
      p = Hash[@players.map { |player, player_alias| [player.id, player_alias] }]
      s = {
        "types"    => @types,
        "teamtag"  => @teamtag,
        "teamname" => @teamname,
        "players"  => p
      }.to_json
      IO.write(@file, s)
    end

    def valid_types?(types)
      return false if types.class != Array
      return false if types.empty?
      types.each do |type|
        return false if not @valid_types.include?(type)
      end
      return true
    end

    def valid_teamname?(name)
      return false if name.class != String
      not name.match(/^[A-Za-z0-9\s',]{3,24}$/).nil?
    end

    def valid_teamtag?(tag)
      return false if tag.class != String
      not tag.match(/^[A-Za-z0-9]{2,6}$/).nil?
    end

    def valid_player?(player)
      player.class == GGTracker::Identity
    end

    def valid_alias?(player_alias)
      player_alias.class == String
    end

    def valid_players?(players)
      return false if players.class != Hash
      return false if players.empty?
      players.each do |player,player_alias|
        return false if not valid_player?(player)
      end
      return true
    end

    private

    def ensure_file
      if not Dir.exists?(@vardir)
        Dir.mkdir(@vardir, 0755)
      end
      if not File.exists?(@file)
        IO.write(@file, "{}")
      end
    end

  end

  class SC2Ladder::App < Sinatra::Base

    include ActionView::Helpers::DateHelper
    GGTracker::API.allow_api_calls

    set :root, File.expand_path('../..', __FILE__)

    def initialize
      super
      @settings = SC2Ladder::Settings.new
      @types_available = ['1v1', '2v2', '3v3', '4v4', 'FFA']
      @blacklist = [
        4270077, # 4 minute non-game
        4366990, # Nick vs Chris, cannon rush practice
      ]
    end

    helpers do

      def h(text)
        Rack::Utils.escape_html(text)
      end

      def full_player_name(player)
        n = player.name.dup
        n << " (%s)" % player.alias if player.alias != player.name
        h n
      end
    end

    before(/^(?!\/settings)/) do
      redirect to('/settings') if not @settings.setup?
    end

    get '/' do
      redirect to('/1v1')
    end

    get '/favicon.ico' do
      404
    end

    get '/settings' do
      "<h1>this will be a settings page</h1>"
    end

    get '/:type' do
      redirect to('/1v1') if not @settings.types.include?(params[:type])
      @type = params[:type]
      chonp = GGTracker::InternalLadder.new(@type, *@settings.players.keys)
      chonp.blacklist(@blacklist)
      chonp.automatic
      @ladder = view_ladder(chonp)
      erb :index
    end

    get '/:type/:player' do
      redirect to('/1v1') if not @settings.types.include?(params[:type])
      @type = params[:type]
      if params[:player] == 'all'
        @player = nil
      else
        @player = name2id(params[:player])
        redirect to("/#{@type}") if @player.nil?
      end
      @ladder = GGTracker::InternalLadder.new(@type, *@settings.players.keys)
      @ladder.blacklist(@blacklist)
      @ladder.automatic
      @matches = {}
      @ladder.matches.sort.reverse.each do |match|
        if @player.nil?
          @matches[match] = {}
        else
          if match.player?(@player)
            @matches[match] = @ladder.players[@player][:change][match]
          end
        end
      end
      if @player.nil?
        erb :all_matches
      else
        erb :identity
      end
    end

    private

    def view_ladder(ladder)
      array = []
      pos = 1
      last_rank = 0
      last_match = ladder.matches[-1]
      ladder.ladder.each do |entry|
        pos += 1 if entry.rank < last_rank
        last_rank = entry.rank
        entry_hash = {
          :position => pos,
          :player => entry.identity,
          :change => nil,
          :id => entry.identity.id,
          :url => entry.identity.url,
          :rank => entry.rank,
          :wins => entry.wins,
          :losses => entry.losses
        }
        entry_hash[:position] = nil if entry.rank == 0
        if entry.count != 0
          entry_hash[:percent] = ((entry.wins.to_f / entry.count.to_f) * 100).round
        end
        if not ladder.players[entry.identity][:change][last_match].nil?
          entry_hash[:change] = ladder.players[entry.identity][:change][last_match]
        end
        array << entry_hash
      end
      array
    end

    def name2id(name)
      @settings.players.keys.each do |player|
        return player if player.alias == name
        return player if player.name == name
      end
      nil
    end

  end

end
