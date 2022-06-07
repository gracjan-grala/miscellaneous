SESSION_NAMES = ['yellow', 'blue', 'red', 'green']
CSV_HEADERS = ['', 'Brewery', 'Beer', 'UT Rating', 'Check-ins', 'GG', 'MM', 'WK', 'WŚ']
PENALTY = 0.35 # how much to deduct from brewery averages if it doesn't have at least 2 beers rated on untappd
# This mapping needs to be created manually
STAND_MAPPING = {
  "3 Sons" => 4,
  "Adroit Theory" => 1,
  "AleSmith" => 1,
  "Amager" => 3,
  "Analog" => 3,
  "Apex" => 2,
  "Bad Seed" => 1,
  "Baghaven" => 4,
  "Basqueland" => 2,
  "Benchtop" => 4,
  "BlackStack" => 2,
  "Bofkont" => 4,
  "Bond Brothers" => 3,
  "Borg Brugghús" => 4,
  "Brasserie de la Sambre" => 4,
  "Brewski" => 1,
  "Buddelship" => 2,
  "Creature Comforts" => 3,
  "Crooked Moon" => 4,
  "Crossover Blendery" => 2,
  "Cycle" => 3,
  "De Dolle" => 2,
  "De Struise" => 1,
  "Dois Corvos" => 3,
  "Drekker" => 1,
  "Dugges" => 4,
  "Ebeltoft" => 1,
  "Elch-Bräu" => 2,
  "Eskilstuna Ölkultur" => 4,
  "Flying Couch" => 1,
  "Folkingebrew" => 4,
  "Forager" => 1,
  "FrauGruber" => 1,
  "Fremont" => 2,
  "Friends Company" => 2,
  "Funk Factory" => 3,
  "Funky Fluid" => 2,
  "Gaffel" => 1,
  "Garden Path" => 1,
  "Gigantic" => 4,
  "Gorilla Cervecería" => 3,
  "Halfway Crooks" => 2,
  "Humble Forager" => 1,
  "Hyllie" => 1,
  "Lawless" => 3,
  "Lervig" => 4,
  "Lua" => 3,
  "MC77" => 2,
  "Mahrs Bräu" => 3,
  "Malbygg" => 3,
  "Mikerphone" => 3,
  "Mikkeller London" => 1,
  "Mikkeller SD" => 2,
  "Mikkeller" => 4,
  "Moksa" => 1,
  "Métaphore" => 2,
  "Neon Raptor" => 1,
  "Nerdbrewing" => 3,
  "Nevel" => 3,
  "Ology" => 2,
  "Omnipollo" => 1,
  "Penyllan" => 3,
  "People Like Us" => 4,
  "Popihn" => 3,
  "Pulpit Rock" => 2,
  "Põhjala" => 4,
  "RVK" => 2,
  "Recycled" => 1,
  "Resident Culture" => 4,
  "Ruse" => 3,
  "Schneeeule" => 3,
  "Seven Island" => 4,
  "Sour Cellars" => 3,
  "Spartacus" => 4,
  "Spybrew" => 2,
  "Stockholm" => 3,
  "Sudden Death" => 1,
  "Superstition" => 1,
  "Ten Hands" => 4,
  "The Attic Meadery" => 1,
  "Timm Vladimirs" => 1,
  "To Øl" => 2,
  "Tommie Sjef" => 2,
  "Too Old To Die Young" => 4,
  "Transient" => 2,
  "Untitled Art" => 3,
  "Vinohradský" => 4,
  "Voodoo" => 2,
  "Warpigs" => 3,
  "Willibald" => 3,
  "Yankee & Kraut" => 3,
  "ÅBEN" => 2,
  "Æblerov" => 1,
  "Ārpus" => 4,
}

require 'csv'
require 'json'

def blank_if_zero(value)
  return nil if value == 0
  value
end

# Read data
input_file = File.read('latest.json') # get from https://mbcc.jonpacker.com/latest.json
parsed_json = JSON.parse(input_file)
beers = parsed_json['beers']

# Create session arrays
sessions = {}
SESSION_NAMES.each do |session_name|
  sessions[session_name] = []
end

# Add beers to sessions they're on
beers.each do |beer|
  beer_sessions = Array(beer['session']) # in most cases the value is a string, but sometimes it's an array
  beer_sessions.each do |beer_session|
    if sessions.key?(beer_session) # some beers are at events outside of MBCC sessions
      sessions[beer_session] << beer
    end
  end
end

SESSION_NAMES.each do |session_name|
  # Enrich data with average brewery ratings for session and stand numbers
  brewery_ratings = Hash.new{ |hash, key| hash[key] = [] }
  sessions[session_name].each do |beer|
    brewery_ratings[beer['brewery']] << beer['ut_rating'] if (beer['ut_rating'] && beer['ut_rating'] > 0)
  end
  sessions[session_name].each do |beer|
    the_brewery_ratings = brewery_ratings[beer['brewery']]
    brewery_avg = the_brewery_ratings.sum / [the_brewery_ratings.count, 1].max # to avoid division by 0
    brewery_avg -= PENALTY if the_brewery_ratings.count < 2
    beer['brewery_avg'] = brewery_avg
    beer['stand_number'] = STAND_MAPPING[beer['brewery']]
  end

  # Sort by average of brewery ratings, then brewery name, then beer rating
  sessions[session_name].sort! do |left, right|
    order = right['brewery_avg'] <=> left['brewery_avg']
    order = left['brewery'] <=> right['brewery'] if order == 0
    order = (right['ut_rating'] || 0) <=> (left['ut_rating'] || 0) if order == 0
    order
  end

  # Create per-session csv files
  CSV.open("#{session_name}.csv", 'wb') do |csv|
    csv << CSV_HEADERS
    sessions[session_name].each do |beer|
      csv << [beer['stand_number'], beer['brewery'], beer['name'], blank_if_zero(beer['ut_rating']), beer['ut_rating_count']]
    end
  end

  puts "#{session_name}: #{sessions[session_name].count}"
end
