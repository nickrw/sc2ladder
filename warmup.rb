#!/usr/bin/env ruby
$LOAD_PATH << File.join(File.expand_path(File.dirname(__FILE__)), "..", "lib")

require 'ggtracker'
require 'ggtracker/internalladder'
require './lib/sc2ladder'

GGTracker::API.allow_api_calls

$settings = SC2Ladder::Settings.new

def calculate_ladder(type)
  l = GGTracker::InternalLadder.new(type, *$settings.players.keys)
  l.blacklist($settings.blacklist_matches)
  if $settings.blacklist_before
    l.blacklist_before($settings.blacklist_before)
  end
  if $settings.blacklist_after
    l.blacklist_after($settings.blacklist_after)
  end
  $settings.blacklist_ranges.each do |tr|
    l.blacklist_time_range(tr)
  end
  l.automatic
  l
end

calculate_ladder('1v1')
calculate_ladder('FFA')

