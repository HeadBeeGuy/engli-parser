# this takes an Englipedia html file and turns it into a flat text file. 
# I was hoping to use something like nokogiri to extract text from the raw html files, 
# but they're way too messy and inconsistent to analyze directly.
require 'nokogiri' # might be unnecessary, but it makes a nice string for html2text
require 'html2text'

Dir.glob("../raw_html/*.html") do |html_file|
  puts "Current file: #{html_file}"
  game_name = html_file[/[A-Za-z0-9_]+\.html/].gsub(/\.html/, "")
  extracted_text = Html2Text.convert( Nokogiri::HTML( open(html_file) ) )
  File.write("../activity_text/#{game_name}.txt", extracted_text)
end

