require 'yaml'

all_activities = {}

Dir.glob("../activity_text/*.txt") do |activity_filename|
  puts "I've located a file: #{activity_filename}"
  activity_file = File.read( activity_filename )

  game_name = activity_filename[/[A-Za-z0-9]+\.txt/]
    .gsub(/\.txt/, "").gsub(/[A-Z]/) { |s| ' ' + s}.strip

  author = activity_file[/SUBMITTED BY:\s?\[?[a-zA-Z .\/]+\]?/]
    .gsub(/SUBMITTED BY:\s?\[?/, '').chomp("]")

  estimated_time = activity_file[/[0-9\+]+\s{0,5}min/]

  submission_date = activity_file[/DATE ADDED:\s?[A-Za-z0-9, ]+/]
    .gsub(/DATE ADDED:\s?/, '')
  
  # this is gonna be a bit messy - no consistent formatting to key
  # from, unfortunately.
  # every activity appears to end with "If you have an updated attachment..."
  description = activity_file[/D(ETAILED|etailed)[\w\W]+If you have an updated/]
    .gsub(/If you have an updated/, "")

  # Inefficiently search the entire description four times
  # But none of these descriptions should be especially long
  learning_descriptors = {
    speaking: activity_file.include?("[Speaking]"),
    listening: activity_file.include?("[Listening]"),
    reading: activity_file.include?("[Reading]"),
    writing: activity_file.include?("[Writing]"),
  }

  # for some reason I can't get (doc|pdf) to work - it only captures those 3 letters
  # so multiple scans once more :(
  attached_files = []
  activity_file.scan(/[a-zA-Z0-9\.\/_]+\.doc/) { |a| attached_files << a }
  activity_file.scan(/[a-zA-Z0-9\.\/_]+\.pdf/) { |a| attached_files << a }
  activity_file.scan(/[a-zA-Z0-9\.\/_]+\.ppt/) { |a| attached_files << a }

  file_info = { game_name: game_name,
                author: author,
                submission_date: submission_date,
                estimated_time: estimated_time,
                parts_of_learning: learning_descriptors, 
                attached_files: attached_files,
                description: description }
  
  # puts file_info
  all_activities.merge!( { game_name => file_info })
end

File.write("../activity_info.txt", all_activities.to_yaml)


