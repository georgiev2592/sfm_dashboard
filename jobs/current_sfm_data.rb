current_temperature_cp = 0
current_humidity_cp = 0
current_temperature_pr = 0
current_humidity_pr = 0

SCHEDULER.every '3s', :first_in => 0 do |job|
  current_temperature_cp, current_humidity_cp = update_current_vals('cp', "Data", current_temperature_cp, current_humidity_cp)
  current_temperature_pr, current_humidity_pr = update_current_vals('pr', "PeterRoom", current_temperature_pr, current_humidity_pr)
end

def update_current_vals(prefix, table_name, current_temperature, current_humidity)
  last_temperature = current_temperature
  last_humidity = current_humidity

  # mysql connection
  db = Mysql2::Client.new(host: "localhost", username: "sfmuser", password: "password", database: "sfm")

  # mysql query
  sql = "SELECT * FROM " + table_name + " ORDER BY created_at DESC LIMIT 1"

  # execute the query
  results = db.query(sql)
  
  # sending to List widget, so map to :label and :value
  results.map do |row|
     current_temperature = row['temp_f']
     current_humidity = row['humidity']
  end

  db.close()

  send_event(prefix + '_current_temperature', {current: current_temperature, last: last_temperature})
  send_event(prefix + '_current_humidity', {value: current_humidity})

  return current_temperature, current_humidity
end

