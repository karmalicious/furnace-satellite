class Schedule
  def self.read
    hostname = `hostname | tr -d "\n"`
    unless hostname == "stuga"
      schedule = `curl -s -u karma:admin #{APIURL}/schedules/unit/#{hostname}`
      if schedule
        File.open( '/tmp/schedule', 'w') do |file|
          file.write("#{schedule}")
        end
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
      while i <= $no_rooms do 
        eval "RELAY_ROOM#{i}.#{status}"
        i += 1
      end
    end
  end
end

class Unit
  def self.get_data
    hostname_local = `hostname | tr -d "\n"`
    mac = `cat /sys/class/net/eth0/address | tr -d "\n"`
    hostname_db = `curl -s -u karma:admin #{APIURL}/units/data/#{mac} | tr -d '"'`
    unless hostname_db == hostname_local
      File.open( '/etc/hostname', 'w') do |file|
        file.write("#{hostname}")
      end
      `hostname #{hostname}`
    end
  end

  def self.report
    mac = `cat /sys/class/net/eth0/address | tr -d "\n"`
    ip = `hostname -I | tr -d " \n"`
    hostname_local = `hostname | tr -d "\n"`
    hostname_db = `curl -s -u karma:admin #{APIURL}/units/data/#{mac} | tr -d '"'`
  
    payload = {
      "ip" => "#{ip}",
      "mac" => "#{mac}",
      "version" => "1.5"
    }.to_json
    `curl -s -H 'Content-Type: application/json' -u karma:admin -d '#{payload}' #{APIURL}/units`
   
    unless hostname_local == hostname_db
      $no_rooms = `curl -s -u karma:admin #{APIURL}/units/rooms/#{mac} | tr -d '"'`
      i = 1
      while i <= $no_rooms do 
        relay_status = eval "RELAY_ROOM#{i}.read"
        room = "#{i}"
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
end
