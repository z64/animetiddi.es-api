module Database
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
end
