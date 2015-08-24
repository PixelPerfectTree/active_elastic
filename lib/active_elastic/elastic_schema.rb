module ActiveElastic
  class ElasticSchema

    class << self

      def create(force = false)
        ActiveElastic::Config.schema_models.each { |model| model.to_s.constantize.__elasticsearch__.create_index!(force: force) }
      end

      def force_create
        create(true)
      end

      def drop
        ActiveElastic::Config.schema_models.each { |model| model.to_s.constantize.__elasticsearch__.delete_index! }
      end

    end

  end
end