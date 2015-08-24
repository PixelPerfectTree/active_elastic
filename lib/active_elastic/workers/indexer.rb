module ActiveElastic
  module Workers
    class Indexer

      if defined? Sidekiq
        include Sidekiq::Worker
        sidekiq_options queue: :elastic_search_indexer_worker
      end

      def self.index_record(record, exclude_relations: [])
        if (use_background_job?)
          self.perform_async(record.id, record.class, exclude_relations)
        else
          self.index!(record, exclude_relations: exclude_relations)
        end
      end

      def perform(id, klass_name, exclude_relations=[])
        record = Module.const_get(klass_name).unscoped.find(id)
        self.class.index! record, exclude_relations: exclude_relations
      end

      def self.index!(record, exclude_relations: [])
        record.__elasticsearch__.index_document
        record.index_relations(exclude_relations: exclude_relations)
      end

      private
        def self.use_background_job?
          defined?(Sidekiq) && ActiveElastic::Config.use_background_jobs? && (Rails.env.production? || Rails.env.development?)
        end
    end
  end
end