require 'abuilder'

module CardSearch
	extend ActiveSupport::Concern

	included do
    include Elasticsearch::Model
    include EsCallbacks
    extend EsSettings

    settings index: default_settings do
      mapping do
        indexes :name, type: :keyword, boost: 10, fields: {
          lowercase: { type: :keyword }
        }
        indexes :card_type_id, type: :integer
        indexes :tags do
          indexes :id, type: :integer
          indexes :name, type: :keyword
        end
        indexes :location do
          indexes :canton do
            indexes :id, type: :integer
            indexes :name, type: :keyword
          end
        end
        indexes :status do
          indexes :name, type: :keyword
        end
      end
    end

    def as_indexed_json(options={})
      as_json(only: [:name, :card_type_id], include: {
        location: { only: [], include: { canton: { only: [:id, :name] } } },
        status: { only: [:name] },
        tags: { only: [:name, :id] }
      })
    end

  end

  module ClassMethods

    def search(params)
      query = Jbuilder.encode do |j|
        j.size 1000
        j.query do
          j.bool do
            unless params[:query].blank?
              j.filter do
                j.query do
                  j.multi_match do
                    j.fields ["name", "location.canton.name", "tags.name"]
                    j.query params[:query]
                  end
                end
              end
            end
            j.must(Abuilder.build do
              add({ terms: { "location.canton.id" => params[:canton_ids] }}) unless params[:canton_ids].blank?
              add({ terms: { "card_type_id" => params[:card_type_ids] }}) unless params[:card_type_ids].blank?
              add({ terms: { "tags.id" => params[:tag_ids] }}) unless params[:tag_ids].blank?
              add({ term: { "status.name" => "En ligne" }})
            end)
          end
        end
        j.sort [{ "name.lowercase" => { order: "asc" }}]
      end
      @cards = Card.__elasticsearch__.search(query).records
    end
  end

end
