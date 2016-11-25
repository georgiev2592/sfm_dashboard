require 'mysql2'

# populate the graph with some random points
temperatures = []
humidities = []

10.downto(1) do |i|
  # mysql connection
  db = Mysql2::Client.new(host: "localhost", username: "root", password: "root", database: "sfm")

  # mysql query
  sql = "SELECT * FROM Data WHERE created_at < NOW() - INTERVAL " + i.to_s + " HOUR ORDER BY created_at DESC LIMIT 1"

  # execute the query
  results = db.query(sql)
  
  results.map do |row|
    local_time = row['created_at'].to_time.strftime('%s').to_i - 8 * 60 * 60
    temperatures << {x: local_time, y: row['temp_c']}
    humidities << {x: local_time, y: row['humidity']}
  end 

  db.close()
end

SCHEDULER.every '1h', :first_in => 0 do |job|

  temperatures.shift
  humidities.shift
  
  # mysql connection
  db = Mysql2::Client.new(host: "localhost", username: "root", password: "root", database: "sfm")

  # mysql query
  sql = "SELECT * FROM Data ORDER BY created_at DESC LIMIT 1"

  # execute the query
  results = db.query(sql)
  
  db.close()
  
  # sending to List widget, so map to :label and :value
  results.map do |row|
     local_time = row['created_at'].to_time.strftime('%s').to_i - 8 * 60 * 60
     temperatures << {x: local_time, y: row['temp_c']}
     humidities << {x: local_time, y: row['humidity']}
  end
  
  send_event('temperature', points: temperatures)
  send_event('humidity', points: humidities)
end
