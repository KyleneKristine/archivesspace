require 'spec_helper'

describe 'ArkName model' do

  before (:all) do
    AppConfig[:arks_enabled] = true
  end

  after (:all) do
    AppConfig[:arks_enabled] = false
  end

  it "creates a ArkName to a resource when a resource is created" do
    obj = create_resource(:title => generate(:generic_title))
    json = Resource.to_jsonmodel(obj)
    ark = ArkName.first(:resource_id => obj.id).value

    expect(ark).to eq(json['ark_name']['current'])
  end

  it "creates an ArkName to an archival object" do
    obj = ArchivalObject.create_from_json(
      build(
        :json_archival_object,
        :title => 'A new archival object'
      ),
      :repo_id => $repo_id)
    json = ArchivalObject.to_jsonmodel(obj)

    ark = ArkName.first(:archival_object_id => obj.id).value

    expect(ark).to eq(json['ark_name']['current'])
  end

  describe('with external ARKs enabled') do
    before(:all) do
      AppConfig[:arks_allow_external_arks] = true
    end

    after(:all) do
      AppConfig[:arks_allow_external_arks] = false
    end

    it "external_ark_url applies if defined on the resource" do
      external_ark_url = "http://foo.bar/ark:/123/123"

      opts = {:title => generate(:generic_title),
              external_ark_url: external_ark_url}
      resource = create_resource(opts)

      ark = ArkName.first(:resource_id => resource.id).value

      expect(ark).to eq(external_ark_url)
    end

    it "external_ark_url applies if defined on the archival object" do
      external_ark_url = "http://foo.bar/ark:/123/123"

      ao = ArchivalObject.create_from_json(
        build(
          :json_archival_object,
          :title => 'A new archival object',
          :external_ark_url => external_ark_url
        ),
        :repo_id => $repo_id)

      ark = ArkName.first(:archival_object_id => ao.id).value

      expect(ark).to eq(external_ark_url)
    end
  end

end
