require 'nokogiri'

# "first level pages" are pages that link directly to activities
first_level_pages = ["../top-level/ES_Topic_Colors.html",
                     "../top-level/JHS_Grammar_Review_MidReview.html"]

# "second level pages" are pages that link to pages which have lists of activities
second_level_pages = ["../top-level/JHS_Grammar.html",
                      "../top-level/JHS_Textbook_2012_NewCrown02.html"]
# contains links to all activities found
activity_uris = []


# page = Nokogiri::HTML( open('../top-level/JHS_Grammar_Review_MidReview.html') )
# page.css('a').each do |link|
# page.xpath("//a[contains(@href, 'Game_')]", "//a[contains(@href, 'GAME_')]").each do |link|
#   puts "http://www.obviously-fake-englipedia-url.com/#{link['href']}"
# end

# assemble first-level pages from second-level pages
second_level_pages.each do |slp|
  slp_file = Nokogiri::HTML( open(slp) )

  # if there are more patterns other than JHS_Grammar, ES_Game, or so on, I may
  # want to programmaticaly generate them. but it's expecting a list of string
  # parameters rather than an array, so I wonder how I'd do that.
  slp_file.xpath("//a[contains(@href, 'JHS_Grammar')]").each do |link|
    first_level_pages << link['href']
  end

end

first_level_pages.uniq!

puts first_level_pages.inspect

# Now that we have a list of first-level pages, crawl them all, strip out their
# html, analyze the resulting text, and save it in a format that can be parsed
# easily later
