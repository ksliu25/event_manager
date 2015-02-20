require "csv"
require "sunlight/congress"
require "erb"
require "date"

Sunlight::Congress.api_key = "e179a6973728c4dd3fb1204283aaccb5"

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def clean_phone(phone)
	phone = phone.to_s.delete("(" + ")" + "-" + ".")
	if phone.length < 10 || phone.length > 11
		phone = "N/A"
	elsif phone.length == 11 && phone[0] == "1"
		phone = phone[1..11]
	elsif phone.length == 11 && !(phone[0] == "1")
		phone = "N/A"
	else
		phone
	end
end

#leave this in for now since we are unfamilir with the API
#it simply references the API for us!
def legislators_by_zipcode(zipcode)
    Sunlight::Congress::Legislator.by_zipcode(zipcode)
end

#this is the letter generation step!
def save_thank_you_letters(id, form_letter)
    Dir.mkdir("output") unless Dir.exists? "output"
	
    filename = "output/thanks_#{id}.html"
  
    File.open(filename, 'w') do |file|
	file.puts form_letter
      end
  end
  	  
puts "EventManager initialized."

contents = CSV.open "event_attendees.csv", headers: true, header_converters: :symbol

template_letter = File.read "form_letter.erb"
erb_template = ERB.new template_letter

contents.each do |row|
    #letter generation 
    id = row[0]
    name = row[:first_name]
    zipcode = clean_zipcode(row[:zipcode])
    phone = clean_phone(row[:homephone])
    legislators = legislators_by_zipcode(zipcode)
    form_letter = erb_template.result(binding)
    save_thank_you_letters(id, form_letter)
  end



#Iteration 2 and 3
#this creates our data in a readable format for our boss into html/erb
  def peak_gen(data)
	  Dir.mkdir("output") unless Dir.exists? "output"
	  
	  filename = "output/peakdata.html"
	  
	  File.open(filename, 'w') do |file|
		  file.puts data
	  end
  end

  #here's my actual date_time
  def date_time(dt_str)
	#strptime parses and turns the string into a ruby time object
	#stfr is the format which matches the string we are given
	#finally, we are looking for the hour at which the date and time is given
	format = "%D %H" 
	dt = DateTime.strptime(dt_str, format)
	return dt.hour
end

def standard_time(num)
	if num < 12
		num.to_s + " AM"
	elsif num == 12
		num.to_s + " PM"
	elsif num > 12
		(num - 12).to_s + " PM"
	end
end


def date_day(dt_str)
	format = "%D %H" 
	dt = DateTime.strptime(dt_str, format)
	return dt.wday
end

def date_w(num)
	day_hash = { "0" => "Sunday", "1" => "Monday", "2" => "Tuesday", "3" => "Wednesday", "4" => "Thursday", "5" => "Friday", "6" => "Saturday"}
	return day_hash[num.to_s]
end



def median(array)
  sorted = array.sort
  len = sorted.length
  #accounts for odd and even numbers -- thanks stackoverflow!
  return (sorted[(len - 1) / 2] + sorted[len / 2]) / 2
end

time_arr = []
day_arr = []

contents.each do |row|
    #data gathering
    time_arr << date_time(row[:regdate])
    day_arr << date_day(row[:regdate])
end

avg_time = standard_time(time_arr.inject{|product, value| product + value} / time_arr.size)
sorted_time = time_arr.sort
median_time = standard_time(median(time_arr))

raw_day = day_arr.inject {|product, value| product + value} / day_arr.size
avg_day = date_w(raw_day)
sorted_day = day_arr.sort
median_day = date_w(median(day_arr))


peak_hours = File.read "peakhours.erb"
peak_erb_template = ERB.new peak_hours
peak = peak_erb_template.result(binding)
peak_gen(peak)

