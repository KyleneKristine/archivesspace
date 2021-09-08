module ThumbnailHelper
  def thumbnail_available?(record)
    file_versions = fetch_candidate_file_versions(record)

    find_representative(file_versions) || find_thumbnail_file_version(file_versions)
  end

  def find_representative(file_versions)
    ASUtils.wrap(file_versions).detect{|fv| !!fv['is_representative']}
  end

  def fetch_thumbnail(record)
    find_thumbnail_file_version(fetch_candidate_file_versions(record))
  end

  def find_thumbnail_file_version(file_versions)
      ASUtils.wrap(file_versions).detect{|fv| !!fv['is_display_thumbnail']} ||
        ASUtils.wrap(file_versions).detect{|fv| fv['use_statement'] == 'image-thumbnail'}
  end

  def file_version_is_image?(file_version)
    begin
      uri = URI(file_version['file_uri'])
      if AppConfig[:thumbnail_file_format_names].include?(file_version['file_format_name']) && FileEmbedHelper.supported_scheme?(uri.scheme)
        true
      else
        false
      end
    rescue
      false
    end
  end

  def fetch_candidate_file_versions(record)
    result = []


    if ['resource', 'archival_object', 'accession'].include?(record['jsonmodel_type'])
      record['instances'].each do |instance|
        if instance['instance_type'] == 'digital_object'
          if instance['is_representative']
            return ASUtils.wrap(instance['digital_object']['_resolved']['file_versions']).map{|fv|
              fv.clone
            }.select{|fv|
              fv['publish']
            }.map {|fv|
              fv['_digital_object_title'] = instance['digital_object']['_resolved']['title']
              fv
            }
          else
            result += ASUtils.wrap(instance['digital_object']['_resolved']['file_versions']).map{|fv|
              fv.clone
            }.select{|fv|
              fv['publish']
            }.map {|fv|
              fv['_digital_object_title'] = instance['digital_object']['_resolved']['title']
              fv
            }
          end
        end
      end
    elsif record['file_versions']
      result = ASUtils.wrap(record['file_versions']).map{|fv|
        fv.clone
      }.select{|fv|
        fv['publish']
      }.map {|fv|
        fv['_digital_object_title'] = record['title']
        fv
      }
    elsif record['jsonmodel_type'] == 'file_version'
      result << record.clone
    end

    result
  end


  def caption_for_thumbnail(record, fallback_title = 'Thumbnail')
    file_version_candidates = fetch_candidate_file_versions(record)

    return fallback_title if file_version_candidates.empty?

    # 1. take the embedded thumbnail caption or digital object title
    if (embed = find_thumbnail_file_version(file_version_candidates))
      if embed['caption']
        return embed['caption']
      elsif embed['_digital_object_title']
        return embed['_digital_object_title']
      end
    end

    # 2. take the representative caption
    if (representative = file_version_candidates.detect{|fv| fv['is_representative']})
      if representative['caption']
        return representative['caption']
      elsif representative['_digital_object_title']
        return representative['_digital_object_title']
      end
    end

    # 3. ok.. take the first digital object's title
    file_version_candidates.each do |fv|
      if fv['_digital_object_title']
        return fv['_digital_object_title']
      end
    end

    # 4. if all fails then take the fallback (current record's title)
    fallback_title
  end

  def link_for_thumbnail(record, fallback_link = nil)
    file_version_candidates = fetch_candidate_file_versions(record)

    return fallback_link if file_version_candidates.empty?

    result = find_representative(file_version_candidates)
    result ||= file_version_candidates.detect{|fv| fv['use_statement'] != 'image-thumbnail' && fv['use_statement'] != 'embed'}
    result ||= file_version_candidates.first

    if result
      result['file_uri']
    else
      fallback_link
    end
  end


  def digital_objects_in_search_results?
    @search_data && @search_data.results? && @search_data['results'].any? do |result|
      result['has_digital_objects'] || ['digital_object', 'digital_object_component'].include?(result['primary_type'])
    end
  end

  def add_thumbnail_column
    return if @force_disable_thumbnail_column

    add_column(
      "Thumbnail",
      proc {|record|
        json = ASUtils.json_parse(record['json'])
        if thumbnail_available?(json)
          render_aspace_partial(:partial => "digital_objects/thumbnail_for_file_version", :locals => {
            :thumbnail => fetch_thumbnail(json),
            :caption => caption_for_thumbnail(json, json['title'] || json['display_string'] || 'Thumbnail'),
            :link_uri => url_for(:controller => :resolver, :action => :resolve_readonly, :uri => json['uri'])
          })
        end
      },
      :sortable => false, :class => 'thumbnail-col'
    )
  end

  def iiif_viewer_url(repo_code = :default)
    AppConfig[:iiif_viewer_url].fetch(repo_code, AppConfig[:iiif_viewer_url].fetch(:default))
  end

  def iiif_enabled?
    AppConfig.has_key?(:iiif_viewer_url) &&
      AppConfig[:iiif_viewer_url].is_a?(Hash) &&
        AppConfig[:iiif_viewer_url].has_key?(:default)
  end

  def iiif_manifest?(file_version)
    file_version['file_format_name'] == AppConfig[:iiif_file_format_name] &&
      file_version['use_statement'] == AppConfig[:iiif_use_statement] &&
        file_version['xlink_show_attribute'] == AppConfig[:iiif_xlink_show_attribute]
  end
end