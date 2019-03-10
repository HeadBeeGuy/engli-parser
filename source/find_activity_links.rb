require 'nokogiri'
require 'open-uri'
require 'html2text'
require 'yaml'

engli_base_url = "http://englipedia.co/www.englipedia.net/Pages/"

# "first level pages" are pages that link directly to activities
first_level_pages = ["http://englipedia.co/www.englipedia.net/Pages/JHS_Grammar_Directions.html",
                     "http://englipedia.co/www.englipedia.net/Pages/Warmup.html",
                     "http://englipedia.co/www.englipedia.net/Pages/ES_Topic_GeneralGames.html",
                     "http://englipedia.co/www.englipedia.net/Pages/GeneralGame.html",
                     "http://englipedia.co/www.englipedia.net/Pages/JHS_Grammar_SelfIntros.html",
                     "http://englipedia.co/www.englipedia.net/Pages/JHS_Grammar_Review_YearEnd_Grade01.html",
                     "http://englipedia.co/www.englipedia.net/Pages/JHS_Grammar_Misc_NewHorizon.html",
                     "http://englipedia.co/www.englipedia.net/Pages/JHS_Grammar_Misc_Sunshine.html",
                     "http://englipedia.co/www.englipedia.net/Pages/JHS_Grammar_Review_MidReview.html",
                     "http://englipedia.co/www.englipedia.net/Pages/HS.html"]

# "second level pages" are pages that link to pages which have lists of activities
second_level_pages = ["http://englipedia.co/www.englipedia.net/Pages/ES_Topic.html",
                      "http://englipedia.co/www.englipedia.net/Pages/Es_HiFriends-2.html",
                      "http://englipedia.co/www.englipedia.net/Pages/JHS_Grammar.html",
                      "http://englipedia.co/www.englipedia.net/Pages/JHS_Textbook_2012_NewCrown01.html",
                      "http://englipedia.co/www.englipedia.net/Pages/JHS_Textbook_2012_NewCrown03.html",
                      "http://englipedia.co/www.englipedia.net/Pages/JHS_Textbook_2012_NewCrown02.html"]
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
                "//a[contains(@href, 'Warmup')]",
                "//a[contains(@href, 'ES_HiFriends_')]",
                "//a[contains(@href, 'ES_Topic_')]", # have to be careful that the general topic page is "ES_Topic.html"
                "//a[contains(@href, 'ES_Topics_')]").each do |link|
    first_level_pages << engli_base_url + link['href']
  end

end

first_level_pages.uniq!

# On some first-level pages, there are links for activity files with no page attached.
# I'm not quite sure what to do with these, but we may as well track them if we want
# to use them somehow later.
lone_files = []

# Now that we have a list of first-level pages, scan them all for links to
# individual activity pages.

first_level_pages.each do |flp|
  page = Nokogiri::HTML( open(flp) )
  page.css('a').each do |link|
    page.xpath("//a[contains(@href, 'Game_')]", "//a[contains(@href, 'GAME_')]",
              "//a[contains(@href, 'Warmup_')]").each do |link|
      activity_uris << "http://englipedia.co/www.englipedia.net/Pages/" + link['href']
    end
    page.xpath("//a[contains(@href, '.doc')]", "//a[contains(@href, '.docx')]",
               "//a[contains(@href, '.pdf')]").each do |link|
      lone_files << link
    end
  end
end

lone_files.uniq!
activity_uris.uniq!
# filter out anything except for .html links
activity_uris.filter!{ |link| link.include?("html") }
puts "Found #{activity_uris.count} activity pages."

# Go into each activity, parse its text, and save it in a file which can be
# imported as an Englipedia Activity object.

activity_uris.each do |page|
  begin
    page_html = Nokogiri::HTML(open(page))
  rescue OpenURI::HTTPError => ex
    puts "Encountered a 404: #{page}"
    next
  end

  # The title often looks like "JHS_Grammar_Game_NameOfActivity"
  # So we have to run this batch of manipulations to get the bit after the 
  # last underscore and add spaces back in
  original_title = page_html.css('title').text
  level_info = { warmup: original_title.include?("Warmup"),
                 es: original_title.include?("ES"),
                 jhs: original_title.include?("JHS"),
                 hs: original_title.include?("HS") && !original_title.include?("JHS") }
  title = original_title.scan(/[A-Za-z]+/).last
  unless title.nil?
    title.gsub!(/[A-Z]/) { |s| ' ' + s}
    unless title.nil?
      title.strip!
    end
  end
  # puts "This activity seems to be called: #{title}"

  raw_text = Html2Text.convert(page_html)

  author = raw_text[/SUBMITTED BY:\s?\[?[a-zA-Z .\/]+\]?/]
  unless author.nil?
    author.gsub!(/SUBMITTED BY:\s?\[?/, '').chomp!("]")
  end

  # outline = raw_text[/BRIEF OUTLINE:[a-zA-Z0-9 .,-\/]+\]?/]
  outline = raw_text[/B(RIEF|rief)[\w :,'`.-?!\/()\"]+/]
  unless outline.nil?
    outline.gsub!(/BRIEF OUTLINE:[ ]+/, '')
    unless outline.nil?
      outline.gsub!(/Brief Outline:[ ]+/, '')
    end
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
    description.gsub!(/If you have an updated/, "").rstrip!
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
                original_url: page,
                parts_of_learning: learning_descriptors, 
                level_info: level_info,
                attached_files: attached_files,
                outline: outline,
                description: description }

  unless title.nil?
    File.write("../activity_text/for_seeding/#{original_title.strip}.txt", file_info.to_yaml)
  end
end

print_to_file = ""
lone_files.each do |uri|
  print_to_file << "#{uri}\n"
end
File.write("./lone_files.txt", print_to_file)


print_to_file = ""
activity_uris.each do |uri|
  print_to_file << "#{uri}\n"
end
File.write("./activity_uris.txt", print_to_file)
