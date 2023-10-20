require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_numbers(number)
  number = number.scan(/\d/).join('')
  
  if (number.length == 11) && (number[0] == "1")
    number[1..10]
  elsif number.length == 10
    number
  else
    "Wrong number"
  end
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    legislators = civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"
  
  File.open(filename,'w') do |file|
    file.puts form_letter
  end
end

def number_to_day(number)
  days = {0 => "Sunday", 1 => "Monday", 2 => "Tuesday", 3 => "Wednesday", 4 => "Thursday", 5 => "Friday", 6 => "Saturday"}
  day = days[number]
end

puts 'EventManager initialized!'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
  )

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
times_hash = Hash.new(0)
days_hash = Hash.new(0)

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  phone_number = clean_phone_numbers(row[:homephone])
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)

  date_time = DateTime.strptime(row[:regdate], "%m/%d/%y %H:%M")
  times_hash[date_time.hour] += 1
  days_hash[date_time.wday] += 1
end

times_with_most_views = Array.new
days_with_most_views = Array.new
times_hash.each{|key, value| times_with_most_views.push(key) if value == times_hash.values.max }
days_hash.each{|key, value| days_with_most_views.push(key) if value == days_hash.values.max }

puts "The hour/s with most views is/are: #{times_with_most_views.each{|time| time}}"
puts "The day/s with the most views is/are: #{days_with_most_views.map{|day| number_to_day(day)}}"