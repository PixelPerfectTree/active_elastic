require 'sidekiq'

module ActiveElastic
  module Workers
    class Importer

      include Sidekiq::Worker
      sidekiq_options queue: :elatic_model_importer

      def perform(class_name)
        ActiveElastic::ModelImporter.new(class_name.constantize).import
      end

    end
  end
end