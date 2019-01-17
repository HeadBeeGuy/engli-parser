# unfortunately rbenv has made this program unable to find nokogiri!
# I'll have to try again once I have internet access
require 'nokogiri'

page = Nokogiri::HTML( open('../top-level/JHS_Grammar_Review_MidReview.html') )
# page.css('a').each do |link|
page.xpath("//a[contains(@href, 'Game_')]", "//a[contains(@href, 'GAME_')]").each do |link|
  puts "http://www.obviously-fake-englipedia-url.com/#{link['href']}"
end
