class ArchivesSpaceArkMinter < ArkMinter

  def mint!(obj, row_defaults)
    DB.open do |db|
      ark_id = db[:ark_name].insert(row_defaults)

      ark_shoulder = shoulder_for_repo(obj.repo_id)

      db[:ark_name]
        .filter(:id => ark_id)
        .update(:ark_value => build_generated_ark(ark_id, ark_shoulder))
    end
  end

  private

  def build_generated_ark(ark_id, ark_shoulder)
    ark_shoulder_with_delimiter = ''

    if ark_shoulder
      ark_shoulder_with_delimiter = "#{ark_shoulder}#{AppConfig[:ark_shoulder_delimiter]}"
    end

    "ark:/#{AppConfig[:ark_naan]}/#{ark_shoulder_with_delimiter}#{ark_id}"
  end


  ArkName.register_minter(:archivesspace_ark_minter, self)

end
