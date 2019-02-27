require 'nokogiri'
require 'open-uri'
require 'html2text'
require 'yaml'

engli_base_url = "http://englipedia.co/www.englipedia.net/Pages/"

# "first level pages" are pages that link directly to activities
first_level_pages = ["http://englipedia.co/www.englipedia.net/Pages/JHS_Grammar_Directions.html",
                     "http://englipedia.co/www.englipedia.net/Pages/Warmup.html"]

# "second level pages" are pages that link to pages which have lists of activities
second_level_pages = ["http://englipedia.co/www.englipedia.net/Pages/JHS_Textbook_2012_NewCrown02.html"]
# contains links to all activities found
activity_uris = []


# assemble first-level pages from second-level pages
second_level_pages.each do |slp|
  puts "current second-level page: #{slp}"
  slp_file = Nokogiri::HTML( open(slp) )

  # if there are more patterns other than JHS_Grammar, ES_Game, or so on, I may
  # want to programmaticaly generate them. but it's expecting a list of string
  # parameters rather than an array, so I wonder how I'd do that.
  slp_file.xpath("//a[contains(@href, 'JHS_Grammar')]", 
                "//a[contains(@href, 'Warmup')]").each do |link|
    first_level_pages << engli_base_url + link['href']
  end

end

first_level_pages.uniq!

# Now that we have a list of first-level pages, scan them all for links to
# individual activity pages.

first_level_pages.each do |flp|
  page = Nokogiri::HTML( open(flp) )
  page.css('a').each do |link|
    page.xpath("//a[contains(@href, 'Game_')]", "//a[contains(@href, 'GAME_')]",
              "//a[contains(@href, 'Warmup_')]").each do |link|
      activity_uris << "http://englipedia.co/www.englipedia.net/Pages/" + link['href']
    end
  end
end

activity_uris.uniq!
puts "Found #{activity_uris.count} activity pages."

# Go into each activity, parse its text, and save it in a file which can be
# imported as an Englipedia Activity object.

i = 0
activity_uris.sample(70).each do |page|
  page_html = Nokogiri::HTML(open(page))

  # The title often looks like "JHS_Grammar_Game_NameOfActivity"
  # So we have to run this batch of manipulations to get the bit after the 
  # last underscore and add spaces back in
  title = page_html.css('title').text
  level_info = { warmup: title.include?("Warmup"),
                 es: title.include?("ES"),
                 jhs: title.include?("JHS"),
                 hs: title.include?("HS") && !title.include?("JHS") }
  title = title.scan(/[A-Za-z]+/).last
  unless title.nil?
    title.gsub!(/[A-Z]/) { |s| ' ' + s}.strip
  end
  puts "This activity seems to be called: #{title}"

  raw_text = Html2Text.convert(page_html)

  author = raw_text[/SUBMITTED BY:\s?\[?[a-zA-Z .\/]+\]?/]
  unless author.nil?
    author.gsub!(/SUBMITTED BY:\s?\[?/, '').chomp!("]")
  end

  outline = raw_text[/BRIEF OUTLINE:[a-zA-Z0-9 .,-\/]+\]?/]
  unless outline.nil?
    outline.gsub!(/BRIEF OUTLINE:[ ]+/, '')
  end
  estimated_time = raw_text[/[0-9\+]+\s{0,5}min/]

  submission_date = raw_text[/DATE ADDED:\s?[A-Za-z0-9, ]+/]
  unless submission_date.nil?
    submission_date.gsub!(/DATE ADDED:\s?/, '')
  end
  
  # this is gonna be a bit messy - no consistent formatting to key
  # from, unfortunately.
  # every activity appears to end with "If you have an updated attachment..."
  description = raw_text[/D(ETAILED|etailed)[\w\W]+If you have an updated/]
  unless description.nil?
    description.gsub!(/If you have an updated/, "")
  end

  # Inefficiently search the entire description four times
  # But none of these descriptions should be especially long
  learning_descriptors = {
    speaking: raw_text.include?("[Speaking]"),
    listening: raw_text.include?("[Listening]"),
    reading: raw_text.include?("[Reading]"),
    writing: raw_text.include?("[Writing]"),
  }

  # for some reason I can't get (doc|pdf) to work - it only captures those 3 letters
  # so multiple scans once more :(
  attached_files = []
  raw_text.scan(/[a-zA-Z0-9\.\/_]+\.doc/) { |a| attached_files << a }
  raw_text.scan(/[a-zA-Z0-9\.\/_]+\.docx/) { |a| attached_files << a }
  raw_text.scan(/[a-zA-Z0-9\.\/_]+\.pdf/) { |a| attached_files << a }
  raw_text.scan(/[a-zA-Z0-9\.\/_]+\.ppt/) { |a| attached_files << a }

  file_info = { title: title,
                author: author,
                submission_date: submission_date,
                estimated_time: estimated_time,
                parts_of_learning: learning_descriptors, 
                level_info: level_info,
                attached_files: attached_files,
                outline: outline,
                description: description }

  unless title.nil?
    File.write("../activity_text/for_seeding/activity_#{i}.txt", file_info.to_yaml)
  end
  i += 1
end
