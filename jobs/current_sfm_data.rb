current_temperature = 0
current_humidity = 0

SCHEDULER.every '2s', :first_in => 0 do |job|
  last_temperature = current_temperature
  last_humidity = current_humidity

  # mysql connection
  db = Mysql2::Client.new(host: "localhost", username: "root", password: "root", database: "sfm")

  # mysql query
  sql = "SELECT * FROM Data ORDER BY created_at DESC LIMIT 1"

  # execute the query
  results = db.query(sql)
  
  db.close()
  
  # sending to List widget, so map to :label and :value
  results.map do |row|
     current_temperature = row['temp_c']
     current_humidity = row['humidity']
  end
  
  send_event('current_temperature', {current: current_temperature, last: last_temperature})
  send_event('current_humidity', {value: current_humidity})
end

