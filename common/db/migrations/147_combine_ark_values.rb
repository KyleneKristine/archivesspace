require_relative 'utils'

Sequel.migration do
  up do
    alter_table(:ark_name) do
      add_column(:ark_value, String, :null => true)
      add_column(:is_external_url, Integer, :default => 0)
    end

    self.transaction do
      self[:ark_name]
        .filter(Sequel.~(:user_value => nil))
        .update(:ark_value => :user_value, :is_external_url => 1)

      self[:ark_name]
        .filter(:user_value => nil)
        .update(:ark_value => :generated_value, :is_external_url => 0)
    end

    alter_table(:ark_name) do
      drop_column(:user_value)
      drop_column(:generated_value)

      set_column_not_null(:ark_value)
    end
  end
end
