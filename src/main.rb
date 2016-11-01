require 'bundler/setup'
require 'sequel'
require 'json'
require 'pry'
require 'sinatra'

module Database
  # Connect to DB
  DB = Sequel.connect('sqlite://data/tiddies.db')

  ##########
  # TABLES #
  ##########

  DB.create_table?(:tiddies) do
    primary_key :id
    String  :url, null: false, unique: true
    Integer :size
    String  :sauce
  end

  DB.create_table?(:tags) do
    primary_key :id
    String :key, null: false
    foreign_key :tiddy_id, :tiddies, null: false, on_delete: :cascade
  end

  ##########
  # MODELS #
  ##########

  class Tiddy < Sequel::Model
    one_to_many :tags

    def tag_list
      tags.collect(&:key)
    end

    def object
      {
        id:    id,
        url:   url,
        size:  size,
        sauce: sauce,
        tags:  tag_list
      }
    end

    def to_json
      object.to_json
    end

    def self.to_json
      all.map(&:object).to_json
    end
  end

  class Tag < Sequel::Model
    many_to_one :tiddies

    def object
      {
        key: key,
        count: tiddies.count
      }
    end

    def to_json
      object.to_json
    end

    def self.to_json
      all.collect(&:key).uniq.collect do |k|
        {
          tag: k,
          count: where(key: k).count
        }
      end.to_json
    end
  end
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

# random tiddy endpoint
get '/' do
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
