module ActiveElastic
  module Workers
    class Importer

      if defined? Sidekiq
        include Sidekiq::Worker
        sidekiq_options queue: :elatic_model_importer
      end

      def perform(class_name)
        ActiveElastic::ModelImporter.new(class_name.constantize).import
      end

    end
  end
end