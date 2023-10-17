puts 'Event Manager Initialized!'

if File.exist?('event_attendees.csv')
  lines = File.readlines('event_attendees.csv')
  lines.each_with_index do |line, index|
    next if index == 0
    columns = line.split(",")
    name = columns[2]
    puts name
end
else
  puts 'File not found'
end