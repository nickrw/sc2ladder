#!/usr/bin/env ruby
$LOAD_PATH << File.join(File.expand_path(File.dirname(__FILE__)), "..", "lib")

require 'ggtracker'
require 'ggtracker/internalladder'

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
  chonp
end


compute_ladder('1v1', $team)
compute_ladder('2v2', $team)
compute_ladder('3v3', $team)
compute_ladder('FFA', $team)
