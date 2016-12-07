require 'pony'

current_temp_avg_cp = 0
current_hum_avg_cp = 0
current_temp_avg_pr = 0
current_hum_avg_pr = 0
count = 0
 
# mysql connection
db = Mysql2::Client.new(host: "localhost", username: "sfmuser", password: "password", database: "sfm")

# mysql query
sql = "SELECT * FROM Data WHERE created_at BETWEEN NOW() - INTERVAL 30 SECOND AND NOW() ORDER BY created_at"

# execute the query
results = db.query(sql)

results.map do |row|
  current_temp_avg_cp += row['temp_f'].to_f
  current_hum_avg_cp += row['humidity'].to_f
  count += 1
end

current_temp_avg_cp /= count
current_hum_avg_cp /= count

# mysql query
sql = "SELECT * FROM PeterRoom WHERE created_at BETWEEN NOW() - INTERVAL 30 SECOND AND NOW() ORDER BY created_at"

# execute the query
results = db.query(sql)
count = 0

results.map do |row|
  current_temp_avg_pr += row['temp_f'].to_f
  current_hum_avg_pr += row['humidity'].to_f
  count += 1
end

current_temp_avg_pr /= count
current_hum_avg_pr /= count

db.close

SCHEDULER.every '1m', :first_in => 0 do |job|
  last_temp_avg = current_temp_avg_cp
  last_hum_avg = current_hum_avg_cp

  # mysql connection
  db = Mysql2::Client.new(host: "localhost", username: "sfmuser", password: "password", database: "sfm")

  # mysql query
  sql = "SELECT * FROM Data WHERE created_at BETWEEN NOW() - INTERVAL 30 SECOND AND NOW() ORDER BY created_at"

  # execute the query
  results = db.query(sql)
  count = 0

  results.map do |row|
    current_temp_avg_cp += row['temp_f'].to_f
    current_hum_avg_cp += row['humidity'].to_f
    count += 1
  end
  
  current_temp_avg_cp /= count
  current_hum_avg_cp /= count
 
  db.close()

  if (current_temp_avg_cp - last_temp_avg) / last_temp_avg > 0.1
    send_email('temperature')
  end

  if (current_hum_avg_cp - last_hum_avg) / last_hum_avg > 0.1
    send_email('humidity')
  end

  puts "Current avg temp: " + current_temp_avg_cp.to_s + " VS Last avg temp: " + last_temp_avg.to_s
  puts "Current avg hum: " + current_hum_avg_cp.to_s + " VS Last avg hum: " + last_hum_avg.to_s
end

def send_email(type)
  body =  "We've noticed that for the past 30 seconds the average " + type + "  has increased by more than 10%.\n\nPlease check make sure your location is safe!\n\nThank,\nSFM Team"
    
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
