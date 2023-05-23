require "sinatra"
require "sinatra/reloader" if development?
# require "pry-byebug"
require "sqlite3"
# set :bind, "0.0.0.0"

DB = SQLite3::Database.new(File.join(File.dirname(__FILE__), "db/jukebox.sqlite"))
query_a = "SELECT name FROM artists WHERE id = ?"
get "/" do
  # TODO: Gather all artists to be displayed on home page
  erb :home # Will render views/home.erb file (embedded in layout.erb)
end

# Then:
# 1. Create an artist page with all the albums. Display genres as well
get "/artists/:id" do
  artist_id = params[:id].to_i
  artist = DB.execute(query_a, artist_id).flatten.first
  albums = DB.execute("
    SELECT DISTINCT albums.id, albums.title, genres.name
    FROM albums
    JOIN tracks ON albums.id = tracks.album_id
    JOIN genres ON genres.id = tracks.genre_id
    WHERE albums.artist_id = ?", artist_id)

  erb :artists, locals: { artist: artist, albums: albums }
end
# 2. Create an album pages with all the tracks
get "/albums/:id" do
  album_id = params[:id].to_i
  album = DB.execute("SELECT title, id FROM albums WHERE id = ?", album_id).flatten.first
  artist_id = DB.execute("SELECT artist_id FROM albums WHERE id = ?", album_id).flatten.first
  artist = DB.execute(query_a, artist_id).flatten.first
  tracks = DB.execute("
    SELECT tracks.id, tracks.name, genres.name
    FROM tracks
    JOIN genres ON genres.id = tracks.genre_id
    WHERE tracks.album_id = ?
    ", album_id)
  erb :albums, locals: { artist: artist, album: album, tracks: tracks }
end

# 3. Create a track page with all the track info
get "/tracks/:id" do
  track_id = params[:id].to_i
  track = DB.execute("SELECT name, id FROM tracks WHERE id = ?", track_id).flatten.first
  composer = DB.execute("SELECT composer, id FROM tracks WHERE id = ?", track_id).flatten.first
  milliseconds = DB.execute("SELECT milliseconds, id FROM tracks WHERE id = ?", track_id).flatten.first
  minutes = milliseconds / (1000 * 60)
  seconds = (milliseconds / 1000) % 60
  formatted_time = "#{minutes}:#{format('%02d', seconds)} min"
  bytes = DB.execute("SELECT ROUND((bytes / 1048576.0), 2), id FROM tracks WHERE id = ?", track_id).flatten.first
  price = DB.execute("SELECT unit_price, id FROM tracks WHERE id = ?", track_id).flatten.first
  artist = DB.execute("
    SELECT artists.name
    FROM artists
    JOIN albums ON albums.artist_id = artists.id
    JOIN tracks ON tracks.album_id = albums.id
    WHERE tracks.id = ?
  ", track_id).flatten.first
  album = DB.execute("
    SELECT albums.title
    FROM albums
    JOIN tracks ON tracks.album_id = albums.id
    WHERE tracks.id = ?
  ", track_id).flatten.first
  genre = DB.execute("
    SELECT genres.name
    FROM genres
    JOIN tracks ON tracks.genre_id = genres.id
    WHERE tracks.id = ?
  ", track_id).flatten.first
  erb :tracks, locals: { genre: genre, album: album, artist: artist, track: track, composer: composer, formatted_time: formatted_time, bytes: bytes, price: price }
end
