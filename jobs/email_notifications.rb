require 'pony'

def update_current_vals(temp, hum, table_name)
  last_entry_at = nil
  current_temp_avg = temp
  current_hum_avg = hum
  count = 0
   
  # mysql connection
  db = Mysql2::Client.new(host: "localhost", username: "sfmuser", password: "password", database: "sfm")

  # mysql query
  #sql = "SELECT * FROM " + table_name + " WHERE created_at BETWEEN NOW() - INTERVAL 30 SECOND AND NOW() ORDER BY created_at"
    
  sql = "SELECT AVG(temp_f), AVG(humidity) FROM " + table_name + " WHERE created_at BETWEEN NOW() - INTERVAL 30 SECOND AND NOW()"
  # execute the query
  results = db.query(sql)

  #results.map do |row|
  #  current_temp_avg += row['temp_f'].to_f
  #  current_hum_avg += row['humidity'].to_f
  #  count += 1
  #end

  #current_temp_avg /= count
  #current_hum_avg /= count
  
  current_temp_avg = results.first['AVG(temp_f)']
  current_hum_avg = results.first['AVG(humidity)']

  # mysql query
  sql = "SELECT * FROM " + table_name + " WHERE created_at BETWEEN NOW() - INTERVAL 30 MINUTE AND NOW() ORDER BY created_at DESC LIMIT 1"

  # execute the query
  results = db.query(sql)

  results.map do |row|
    last_entry_at = row['created_at']
  end

  db.close

  return current_temp_avg, current_hum_avg, last_entry_at
end

current_temp_avg_cp, current_hum_avg_cp, last_entry_at_cp = update_current_vals(0, 0, "Data")
current_temp_avg_pr, current_hum_avg_pr, last_entry_at_pr = update_current_vals(0, 0, "PeterRoom")

SCHEDULER.every '1m', :first_in => 0 do |job|
  check_current_vals("Data", current_temp_avg_cp, current_hum_avg_cp, last_entry_at_cp, "waylinw@gmail.com")
  check_current_vals("PeterRoom", current_temp_avg_pr, current_hum_avg_pr, last_entry_at_pr, "georgiev2592@gmail.com")
end

def check_current_vals(table_name, current_temp_avg, current_hum_avg, last_entry_at, send_to)
  last_temp_avg = current_temp_avg
  last_hum_avg = current_hum_avg

  current_temp_avg, current_hum_avg = update_current_vals(current_temp_avg, current_hum_avg, table_name)
  
  puts "Cur avg temp: " + current_temp_avg.to_s + " Last avg temp: " + last_temp_avg.to_s
  puts "Cur avg hum: " +  current_hum_avg.to_s +  " Last avg temp: " +  last_hum_avg.to_s
  puts "Last etry at: " +  last_entry_at.to_s

  if (current_temp_avg - last_temp_avg) / last_temp_avg > 0.20
    send_email('temperature', send_to)
  end

  if (current_hum_avg - last_hum_avg) / last_hum_avg > 0.10
    send_email('humidity', send_to)
  end

  if !last_entry_at
    send_email('pi', send_to)
  end
end

def send_email(type, send_to)
  if type == 'pi'
    body = "We noticed that the Raspberry Pi has been offline for more 30 minutes.\n\nPlease ensure equipment integrity.\n\nThanks,\nSFM Team\n"  
  else 
    body =  "We noticed that for the past 30 seconds the average " + type + "  has increased by more than 10%.\n\nPlease check ensure environment is safe!\n\nThanks,\nSFM Team\n"
  end 
  
  Pony.mail(
    :to => send_to,
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
