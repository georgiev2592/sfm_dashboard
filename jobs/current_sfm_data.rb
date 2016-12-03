current_temperature_cp = 0
current_humidity_cp = 0
current_temperature_pr = 0
current_humidity_pr = 0

SCHEDULER.every '3s', :first_in => 0 do |job|
  last_temperature_cp = current_temperature_cp
  last_humidity_cp = current_humidity_cp
  last_temperature_pr = current_temperature_pr
  last_humidity_pr = current_humidity_pr


  # mysql connection
  db = Mysql2::Client.new(host: "localhost", username: "sfmuser", password: "password", database: "sfm")

  # mysql query
  sql = "SELECT * FROM Data ORDER BY created_at DESC LIMIT 1"

  # execute the query
  results = db.query(sql)
  
  # sending to List widget, so map to :label and :value
  results.map do |row|
     current_temperature_cp = row['temp_f']
     current_humidity_cp = row['humidity']
  end
  
  # mysql query
  sql = "SELECT * FROM PeterRoom ORDER BY created_at DESC LIMIT 1"

  # execute the query
  results = db.query(sql)
  
  # sending to List widget, so map to :label and :value
  results.map do |row|
     current_temperature_pr = row['temp_c']
     current_humidity_pr = row['humidity']
  end
  
  db.close()
  
  send_event('cp_current_temperature', {current: current_temperature_cp, last: last_temperature_cp})
  send_event('cp_current_humidity', {value: current_humidity_cp})
  send_event('pr_current_temperature', {current: current_temperature_pr, last: last_temperature_pr})
  send_event('pr_current_humidity', {value: current_humidity_pr})
end

