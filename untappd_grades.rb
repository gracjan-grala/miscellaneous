#!/usr/bin/env ruby
# Looks for beer names on untappd.com and outputs the list including review scores for each beer

require 'csv'
require 'faraday'
require 'nokogiri'
require 'open-uri'
require 'uri'

DEFAULT_SEPARATOR            = ';'.freeze
SLEEP_DURATION               = 2 # seconds
POTENTIAL_MISMATCH_INDICATOR = 'MISMATCH'.freeze

input_file_name  = ARGV[0]
output_file_name = ARGV[1] || 'out.csv'
separator        = ARGV[2] || DEFAULT_SEPARATOR

input_file  = CSV.read(input_file_name, col_sep: separator)
output_file = File.open(output_file_name, 'a')

class BeerName
  attr_reader :full_name, :partial_name

  def initialize(name)
    @full_name    = name
    @partial_name = name
  end

  def present?
    !@partial_name.empty?
  end

  def next!
    @partial_name = @partial_name.split[0..-2].join(' ')
  end
end

class UntappdBeer
  BASE_URL   = 'https://untappd.com/'.freeze
  SEARCH_URL = URI.join(BASE_URL, '/search?q=')

  attr_reader :brewery, :name, :style

  def initialize(page)
    @abv     = page.css('.beer-item .abv').first.content
    @brewery = page.css('.beer-item .brewery').first.content
    @grade   = page.css('.beer-item .num').first.content
    @ibu     = page.css('.beer-item .ibu').first.content
    @name    = page.css('.beer-item .name').first.content
    @style   = page.css('.beer-item .style').first.content
    @uri     = page.css('.beer-item .label').first['href']
  end

  def abv
    @abv.strip!.sub(/\ ABV/, '')
  end

  def grade
    @grade.gsub(/[\(\)]/, '')
  end

  def ibu
    @ibu.strip!.sub(/\ IBU/, '')
  end

  def url
    URI.join(BASE_URL, @uri).to_s
  end

  def csv_info
    [grade, abv, "#{brewery} #{name}", url]
  end

  def self.find(name)
    page = Nokogiri::HTML(URI.open("#{SEARCH_URL}#{URI.encode_www_form_component(name)}"))
    return unless page.css('.beer-item .num').first # returns nil if beer is not found
    UntappdBeer.new(page)
  end
end

bottles = input_file.to_a
errors = []

begin
  bottles.each do |bottle_name|
    name, *rest = bottle_name

    beer_name = BeerName.new(name)
    untappd_record = nil
    steps = 0

    while untappd_record.nil? && beer_name.present?
      untappd_record = UntappdBeer.find(beer_name.partial_name)
      steps += 1
      beer_name.next! unless untappd_record
      sleep SLEEP_DURATION
    end

    output_line = [name, *rest] # fields from the input

    if untappd_record
      STDOUT.print(steps)
      output_line += untappd_record.csv_info

      puts "#{name} vs #{untappd_record.name}"
      unless name.include?(untappd_record.name)
        output_line << POTENTIAL_MISMATCH_INDICATOR
        errors << "Found record (#{untappd_record.name}) doesn't match original beer name #{name}"
      end
    else
      STDOUT.print 'X'

      errors << "#{name} - beer not found"
    end

    output_file.puts output_line.to_csv(col_sep: DEFAULT_SEPARATOR)
    STDOUT.flush
  end
ensure
  STDOUT.puts
  errors.each_with_index do |message, index|
    STDERR.puts "#{index + 1}. #{message}"
  end
  output_file.close
end
