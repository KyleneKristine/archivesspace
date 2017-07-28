class AssessmentAttributeDefinitions

  extend JSONModel

  def self.apply_definitions(repo_id, json)
    # Global definitions are immutable, so drop them out here.
    definitions = json.definitions.reject {|d| d['global']}
    definitions.each do |d| d.delete('global'); end

    DB.open do |db|
      # Don't allow a label to be set if it would conflict with a label used by one of the global attributes
      definitions.each do |d|
        conflicting_labels = db[:assessment_attribute_definition]
                               .filter(:repo_id => 1, :type => d['type'], :label => d['label'])
                               .select(:label)
                               .all

        unless conflicting_labels.empty?
          raise ConflictException.new("Update would conflict with the following global labels of type #{d['type']}: " +
                                      conflicting_labels.map {|row| row[:label]}.join("; "))
        end

        conflicting_repo_labels = db[:assessment_attribute_definition]
                                    .filter(:repo_id => repo_id,
                                            :type => d['type'],
                                            :label => d['label'])
                                    .where { Sequel.~(:id => d['id']) }
                                    .select(:label)
                                    .all

        unless conflicting_repo_labels.empty?
          raise ConflictException.new("Update would conflict with the following labels of type #{d['type']}: " +
                                      conflicting_repo_labels.map {|row| row[:label]}.join("; "))
        end
      end

      # Existing definitions get updated
      definitions.each_with_index do |definition, position|
        next unless definition['id']

        db[:assessment_attribute_definition]
          .filter(:repo_id => repo_id, :id => definition['id'])
          .update(definition.merge(:position => position))
      end

      # New definitions are inserted
      definitions.each_with_index do |definition, position|
        next if definition['id']
        db[:assessment_attribute_definition].insert(definition.merge(:repo_id => repo_id, :position => position))
      end
    end
  end

  def self.get(repo_id)
    result = JSONModel(:assessment_attribute_definitions).new

    DB.open do |db|
      db[:assessment_attribute_definition]
        .filter(:repo_id => [repo_id, Repository.global_repo_id])
        .order(:repo_id, :position, :id).each do |definition|

        result.definitions << {
          :id => definition[:id],
          :label => definition[:label],
          :type => definition[:type],
          :global => (definition[:repo_id] == Repository.global_repo_id),
        }
      end
    end

    result
  end

end