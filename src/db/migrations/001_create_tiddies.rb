Sequel.migration do
  up do
    create_table?(:tiddies) do
      primary_key :id
      String  :url, null: false, unique: true
      Integer :size
      String  :sauce
    end

    create_table(:tags) do
      primary_key :id
      String      :key, null: false
      foreign_key :tiddy_id, :tiddies, null: false, on_delete: :cascade
    end

    create_table(:users) do
      primary_key :id
      String      :ip,      unique:  true,  null: false
      TrueClass   :blocked, default: false
    end
  end
end
