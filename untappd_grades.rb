# Looks for beer names on untappd.com and outputs the list including review scores for each beer

require 'uri'
require 'open-uri'
require 'nokogiri'
require 'faraday'

bottles = [
  # beer list goes here
]
base_url = 'https://untappd.com/search?q='

bottles.each do |name|
  new_name = name
  grade = nil
  page = nil

  while grade == nil && new_name != '' do
    page = Nokogiri::HTML(open("#{base_url}#{URI::escape(new_name)}"))
    grade = page.css('.beer-item .num').first
    new_name = new_name.split[0..-2].join(' ') unless grade
  end

  if grade
    abv = page.css('.beer-item .abv').first.content
    style = page.css('.beer-item .style').first.content

    puts [
      new_name,
      grade.content.gsub(/[\(\)]/, ''),
      abv.strip!.sub(/\ ABV/, ''),
      style
    ].join('; ')
  else
    puts "#{name} - beer not found"
  end
end
