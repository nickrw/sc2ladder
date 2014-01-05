#!/usr/bin/env ruby
$LOAD_PATH << File.join(File.expand_path(File.dirname(__FILE__)), "..", "lib")

require 'ggtracker'
require 'ggtracker/internalladder'
require 'action_view'
require 'sinatra'
include ActionView::Helpers::DateHelper

GGTracker::API.allow_api_calls

$players = {
  'Nick' => GGTracker::API.identity(1031800),
  'Kristof' => GGTracker::API.identity(1161842),
  'Victor' => GGTracker::API.identity(1313010),
  'James' => GGTracker::API.identity(1364014),
  'Josh' => GGTracker::API.identity(1391538),
  'Tiago' => GGTracker::API.identity(1399882),
  'Chris' => GGTracker::API.identity(1404374),
  'Rosario' => GGTracker::API.identity(1442802),
  'Oliver' => GGTracker::API.identity(1399883),
  'Jesper' => GGTracker::API.identity(1395994)
}
$players.each do |name,identity|
  identity.alias = name
end
$team = $players.values

def compute_ladder(type, players)
  chonp = GGTracker::InternalLadder.new(type, *players)
  players.each do |player|
    GGTracker::API.matches(player.id, false, type).all
  end
  chonp.automatic
  puts chonp.matches.count
  chonp
end

def view_ladder(ladder)
  array = []
  pos = 0
  last_match = ladder.matches[-1]
  ladder.ladder.each do |entry|
    pos += 1
    entry_hash = {
      :position => pos,
      :player => entry.identity.alias,
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

helpers do
  def h(text)
    Rack::Utils.escape_html(text)
  end
end

get '/' do
  redirect to('/1v1')
end

get '/favicon.ico' do
  404
end

get '/:type' do
  types = ['1v1', '2v2', '3v3', 'FFA']
  redirect to('/1v1') if not types.include?(params[:type])
  @type = params[:type]
  chonp = compute_ladder(@type, $team)
  @ladder = view_ladder(chonp)
  erb :index
end

get '/:type/:alias' do
  types = ['1v1', '2v2', '3v3', 'FFA']
  redirect to('/1v1') if not types.include?(params[:type])
  @type = params[:type]
  if params[:alias] == 'all'
    @player = nil
  else
    supplied_alias = params[:alias].to_s.capitalize
    if $players[supplied_alias].class == GGTracker::Identity
      @player = $players[supplied_alias]
    else
      redirect to("/#{@type}")
    end
  end
  @ladder = compute_ladder(@type, $team)
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

get '/:type/all' do
end


configure do
  set :bind, '0.0.0.0'
end
