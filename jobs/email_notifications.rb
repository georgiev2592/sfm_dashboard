require 'pony'

def update_current_vals(temp, hum, table_name)
  current_temp_avg = temp
  current_hum_avg = hum
  count = 0
   
  # mysql connection
  db = Mysql2::Client.new(host: "localhost", username: "sfmuser", password: "password", database: "sfm")

  # mysql query
  sql = "SELECT * FROM " + table_name + " WHERE created_at BETWEEN NOW() - INTERVAL 30 SECOND AND NOW() ORDER BY created_at"

  # execute the query
  results = db.query(sql)

  results.map do |row|
    current_temp_avg += row['temp_f'].to_f
    current_hum_avg += row['humidity'].to_f
    count += 1
  end

  current_temp_avg /= count
  current_hum_avg /= count

  db.close

  return current_temp_avg, current_hum_avg
end

current_temp_avg, current_hum_avg = update_current_vals(0, 0, "Data")

SCHEDULER.every '1m', :first_in => 0 do |job|
  last_temp_avg = current_temp_avg
  last_hum_avg = current_hum_avg

  current_temp_avg, current_hum_avg = update_current_vals(0, 0, "Data")

  if (current_temp_avg - last_temp_avg) / last_temp_avg > 0.1
    send_email('temperature')
  end

  if (current_hum_avg - last_hum_avg) / last_hum_avg > 0.1
    send_email('humidity')
  end

end

def send_email(type)
  body =  "We've noticed that for the past 30 seconds the average " + type + "  has increased by more than 10%.\n\nPlease check make sure your location is safe!\n\nThanks,\nSFM Team"
    
  Pony.mail(
    :to => "georgiev2592@gmail.com",
    :subject => "Notification Email | SFM",
    :body => body,
    :via => :smtp,
    :via_options => {
      :address              => "smtp.gmail.com",
      :port                 => "587",
      :enable_starttls_auto => true,
      :user_name            => "sfmnotifications0@gmail.com",
      :password             => "C4Rzq9uPY4dW1ESeAof8",
      :authentication       => :plain,
      :domain               => "localhost.localdomain" 
      }
    )
end
