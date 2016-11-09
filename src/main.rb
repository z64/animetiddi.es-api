require 'bundler/setup'
require 'sequel'
require 'json'
require 'pry'
require 'sinatra'

module Database
  # Sequel extension
  Sequel.extension :migration

  # Connect to DB
  DB = Sequel.connect('sqlite://data/tiddies.db')

  # Run migrations
  Sequel::Migrator.run(DB, 'src/db/migrations')

  # Set up models
  Dir['src/db/*.rb'].each { |mod| load mod }
end

#############
# TIDDY API #
#############

# pry before starting the api if u want
binding.pry if ARGV[0] == 'pry'

# Probably won't use many of these,
# but I had fun writing them.
ERROR = {
  201 => '201 you fucked up',
  401 => '401 unauthorized tiddies',
  403 => '403 forbidden tiddies',
  404 => '404 tiddies not found',
  500 => '500 internal tiddy error'
}

# configure sinatra
set :bind, '0.0.0.0'
set :port, 8080

# default endpoint settings
before do
  user = Database::User.find(ip: request.ip)
  user ||= Database::User.create(ip: request.ip)

  halt(401) if user.blocked?

  content_type 'application/json'
end

# top-level hello endpoint
get '/' do
  {
    url: 'http://animetiddi.es/tiddies.jpg',
    text: 'animetiddi.es',
    timestamp: Time.now.iso8601
  }.to_json
end

# random tiddy endpoint
get '/random' do
  Database::Tiddy.all.sample.to_json
end

# tiddy ID endpoint
get '/id/:id' do
  tiddy = Database::Tiddy.find(id: params[:id])
  if tiddy.nil?
    halt 404, ERROR[404]
  else
    tiddy.to_json
  end
end

# bulk tiddy fetch
get '/tiddies' do
  matchable = ['ids', 'tags', 'url', 'size', 'sauce']
  key       = params.keys.find { |k, v| matchable.include? k }

  results = case key
  when 'ids'
    if params['ids'].is_a? Array
      Database::Tiddy.where(id: params['ids'])
    else
      halt 201, ERROR[201]
    end

  when 'tags'
    if params['tags'].is_a? Array
      Database::Tiddy.all.select do |t|
        (t.tag_list & params['tags']).any?
      end.map(&:object)
    else
      halt 201, ERROR[201]
    end

  when 'url'
    Database::Tiddy.where(Sequel.ilike(:url, params['url']))

  when 'size'
    Database::Tiddy.where(size: params['size'].to_i)

  when 'sauce'
    Database::Tiddy.where(Sequel.ilike(:sauce, params['sauce']))
  end

  results ||= Database::Tiddy.all

  {
    count: results.count,
    results: results.map(&:object)
  }.to_json
end

get '/tags' do
  Database::Tag.to_json
end

get '/tags/list' do
  Database::Tag.collect(&:key).uniq.to_json
end
