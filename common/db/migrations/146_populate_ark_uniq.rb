require_relative 'utils'

Sequel.migration do
  up do
    self.transaction do
      self[:ark_uniq_check].delete

      self[:resource].join(:ark_name, Sequel.qualify(:resource, :id) => Sequel.qualify(:ark_name, :resource_id))
        .select(:repo_id, :resource_id, :generated_value, :user_value)
        .distinct
        .each do |row|

        self[:ark_uniq_check].insert(:record_uri => "/repositories/#{row[:repo_id]}/resources/#{row[:resource_id]}",
                                     :value => row[:generated_value])

        if row[:user_value]
          self[:ark_uniq_check].insert(:record_uri => "/repositories/#{row[:repo_id]}/resources/#{row[:resource_id]}",
                                       :value => row[:user_value].sub(/^.*?ark:/i, 'ark:'))
        end
      end

      self[:archival_object].join(:ark_name, Sequel.qualify(:archival_object, :id) => Sequel.qualify(:ark_name, :archival_object_id))
        .select(:repo_id, :archival_object_id, :generated_value, :user_value)
        .distinct
        .each do |row|

        self[:ark_uniq_check].insert(:record_uri => "/repositories/#{row[:repo_id]}/archival_objects/#{row[:archival_object_id]}",
                                     :value => row[:generated_value])

        if row[:user_value]
          self[:ark_uniq_check].insert(:record_uri => "/repositories/#{row[:repo_id]}/archival_objects/#{row[:archival_object_id]}",
                                       :value => row[:user_value].sub(/^.*?ark:/i, 'ark:'))
        end
      end
    end
  end

  down do
  end
end
