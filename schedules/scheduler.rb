#!/usr/bin/ruby

scheduler = Rufus::Scheduler.new

scheduler.every '1m', :first_in => 30 do
  Schedule.read
end

scheduler.every '1m', :first_in => 10 do
  Unit.report
end

scheduler.every '1m', :first_in => 20 do
  Unit.get_data
end
scheduler.join
