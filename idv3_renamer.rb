require 'id3tag'
require 'fileutils'

DIRECTORY = ARGV[0] || '.'
EXTENSION = ARGV[1] || 'mp3'

def build_path(tags)
  (
    [DIRECTORY] +
    [tags.artist, tags.album]
    .map{ |tag| tag.gsub('/', '|') }
    .map{ |tag| tag == '' ? nil : tag }
    .compact
  )
    .join('/')
end

files = Dir["#{DIRECTORY}/*.#{EXTENSION}"].map(&:strip)

files.each do |file_name|
  file_handle = File.open(file_name, "rb")
  tags = ID3Tag.read(file_handle)

  path = build_path(tags)
  track_nr = tags.track_nr ? tags.track_nr.split('/').first + '. ' : ''
  extension = '.' + file_name.split('.').last
  name = [track_nr, tags.title.gsub('/', '|'), extension].join('')

  file_handle.close

  FileUtils::mkdir_p(path)
  FileUtils.mv(file_name, [path, name].join('/').strip)
end
