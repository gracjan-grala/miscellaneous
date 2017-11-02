# Looks for beer names on untappd.com and outputs the list including review scores for each beer

require 'uri'
require 'open-uri'
require 'nokogiri'
require 'faraday'

beers = [
  # beer list goes here
]
base_url = 'https://untappd.com/search?q='

beers.each do |name|
  new_name = name
  grade = nil

  while grade == nil && new_name != '' do
    page = Nokogiri::HTML(open("#{base_url}#{URI::escape(new_name)}"))
    grade = page.css('.beer-item .num').first
    new_name = new_name.split[0..-2].join(' ') unless grade
  end

  if grade
    puts "#{new_name}, #{grade.content.gsub(/[\(\)]/, '')}"
  else
    puts "#{name}, n/a"
  end
end
