module Database
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
