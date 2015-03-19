class Schedule
  def self.read
    hostname = `hostname | tr -d "\n"`
    schedule = `curl -s #{APIURL}/schedules/unit/#{hostname}`
    File.open( '/tmp/schedule', 'w') do |file|
      file.write("#{schedule}")
    end
    status = "off"
    unless File.readlines("/tmp/schedule").grep(/\[\]/).any?
      json  = JSON.parse(File.read('/tmp/schedule'))
      json.each do |item|
        stop	= DateTime.parse(item['stop'])
        start	= DateTime.parse(item['start'])
        now	= DateTime.now
        if now < stop && now > start
          status = "on"
        else
          status = "off"
        end
      end
    end
    i = 1 
    while i <= NO_ROOMS do 
      eval "RELAY_ROOM#{i}.#{status}"
      i += 1
    end
  end
end

class Unit
  def self.report
    mac = `cat /sys/class/net/eth0/address | tr -d "\n"`
    ip = `hostname -I | tr -d " \n"`
    hostname = `hostname | tr -d "\n"`
  
    payload = {
      "ip" => "#{ip}",
      "mac" => "#{mac}",
      "unit" => "#{hostname}",
      "version" => "1.5"
    }.to_json
    `curl -s -H 'Content-Type: application/json' -d '#{payload}' #{APIURL}/units`
    
    i = 1
    while i <= NO_ROOMS do 
      relay_status = eval "RELAY_ROOM#{i}.read"
      room = "Room#{i}"
      payload = {
        "unit"		=> "#{hostname}",
        "room"		=> "#{room}",
        "relay_status"	=> "#{relay_status}"
      }.to_json
      `curl -s -H 'Content-Type: application/json' -d '#{payload}' #{APIURL}/relay`
      i += 1
    end
  end
end
