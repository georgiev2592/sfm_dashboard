require 'mysql2'

# populate the graph with some random points
temperatures_cp = []
humidities_cp = []
temperatures_pr = []
humidities_pr = []

def initialize_arr(table_name, units, temperatures, humidities)
  10.downto(1) do |i|
    # mysql connection
    db = Mysql2::Client.new(host: "localhost", username: "sfmuser", password: "password", database: "sfm")

    # mysql query
    sql = "SELECT * FROM " + table_name + " WHERE created_at < NOW() - INTERVAL " + i.to_s + " HOUR ORDER BY created_at DESC LIMIT 1"

    # execute the query
    results = db.query(sql)
    
    results.map do |row|
      local_time = row['created_at'].to_time.strftime('%s').to_i - 8 * 60 * 60
      temperatures << {x: local_time, y: row['temp_' + units]}
      humidities << {x: local_time, y: row['humidity']}
    end 
    db.close()
  end
  return temperatures, humidities
end

temperatures_cp, humidities_cp = initialize_arr("Data", 'f', temperatures_cp, humidities_cp)
temperatures_pr, humidities_pr = initialize_arr("PeterRoom", 'c', temperatures_pr, humidities_pr)

SCHEDULER.every '1h', :first_in => 0 do |job|

  temperatures_cp.shift
  humidities_cp.shift
  temperatures_pr.shift
  humidities_pr.shift
  
  temperatures_cp, humidities_cp = update_arr("Data", 'f', temperatures_cp, humidities_cp)
  temperatures_pr, humidities_pr = update_arr("PeterRoom", 'c', temperatures_pr, humidities_pr)
  
  send_event('cp_temperature', points: temperatures_cp)
  send_event('cp_humidity', points: humidities_cp)
  send_event('pr_temperature', points: temperatures_pr)
  send_event('pr_humidity', points: humidities_pr)
end

def update_arr(table_name, units, temperatures, humidities)
  # mysql connection
  db = Mysql2::Client.new(host: "localhost", username: "sfmuser", password: "password", database: "sfm")

  # mysql query
  sql = "SELECT * FROM " + table_name + " ORDER BY created_at DESC LIMIT 1"

  # execute the query
  results = db.query(sql)
  
  # sending to List widget, so map to :label and :value
  results.map do |row|
     local_time = row['created_at'].to_time.strftime('%s').to_i - 8 * 60 * 60
     temperatures << {x: local_time, y: row['temp_' + units]}
     humidities << {x: local_time, y: row['humidity']}
  end
  
  db.close()

  return temperatures, humidities
end
