#!/usr/bin/ruby

scheduler = Rufus::Scheduler.new
scheduler.every '5m', :first_in => 1 do
  Schedule.read
end

scheduler.every '5m', :first_in => 1 do
  Unit.report
end
scheduler.join
