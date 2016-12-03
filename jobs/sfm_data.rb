require 'mysql2'

# populate the graph with some random points
temperatures_cp = []
humidities_cp = []
temperatures_pr = []
humidities_pr = []


10.downto(1) do |i|
  # mysql connection
  db = Mysql2::Client.new(host: "localhost", username: "sfmuser", password: "password", database: "sfm")

  # mysql query
  sql = "SELECT * FROM Data WHERE created_at < NOW() - INTERVAL " + i.to_s + " HOUR ORDER BY created_at DESC LIMIT 1"

  # execute the query
  results = db.query(sql)
  
  results.map do |row|
    local_time = row['created_at'].to_time.strftime('%s').to_i - 8 * 60 * 60
    temperatures_cp << {x: local_time, y: row['temp_f']}
    humidities_cp << {x: local_time, y: row['humidity']}
  end 

  # mysql query
  sql = "SELECT * FROM PeterRoom WHERE created_at < NOW() - INTERVAL " + i.to_s + " HOUR ORDER BY created_at DESC LIMIT 1"

  # execute the query
  results = db.query(sql)
  
  results.map do |row|
    local_time = row['created_at'].to_time.strftime('%s').to_i - 8 * 60 * 60
    temperatures_pr << {x: local_time, y: row['temp_c']}
    humidities_pr << {x: local_time, y: row['humidity']}
  end 

  db.close()
end

SCHEDULER.every '1h', :first_in => 0 do |job|

  temperatures_cp.shift
  humidities_cp.shift
  temperatures_pr.shift
  humidities_pr.shift
  

  # mysql connection
  db = Mysql2::Client.new(host: "localhost", username: "root", password: "root", database: "sfm")

  # mysql query
  sql = "SELECT * FROM Data ORDER BY created_at DESC LIMIT 1"

  # execute the query
  results = db.query(sql)
  
  # sending to List widget, so map to :label and :value
  results.map do |row|
     local_time = row['created_at'].to_time.strftime('%s').to_i - 8 * 60 * 60
     temperatures_cp << {x: local_time, y: row['temp_f']}
     humidities_cp << {x: local_time, y: row['humidity']}
  end

  # mysql query
  sql = "SELECT * FROM PeterRoom ORDER BY created_at DESC LIMIT 1"

  # execute the query
  results = db.query(sql)
  
  # sending to List widget, so map to :label and :value
  results.map do |row|
     local_time = row['created_at'].to_time.strftime('%s').to_i - 8 * 60 * 60
     temperatures_pr << {x: local_time, y: row['temp_c']}
     humidities_pr << {x: local_time, y: row['humidity']}
  end
  
  db.close()
  
  send_event('cp_temperature', points: temperatures_cp)
  send_event('cp_humidity', points: humidities_cp)
  send_event('pr_temperature', points: temperatures_pr)
  send_event('pr_humidity', points: humidities_pr)
end
