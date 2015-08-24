module ActiveElastic
  class ModelImporter

    attr_reader :model
    def initialize(model)
      @model = model
    end

    def import
      model.unscoped.order(:id).includes(model.elastic_relations).import(batch_size: 100)
    end

  end
end