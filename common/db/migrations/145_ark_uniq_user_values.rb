require_relative 'utils'

Sequel.migration do
  up do
    alter_table(:ark_uniq_check) do
      rename_column(:generated_value, :value)
    end

    alter_table(:ark_name) do
      add_index([:user_value, :resource_id], :name => 'ark_name_user_value_res_idx')
      add_index([:user_value, :archival_object_id], :name => 'ark_name_user_value_ao_idx')
    end
  end

  down do
  end
end
