module ActiveElastic
  class Config

    cattr_writer :index_prefix, :prepend_env_in_index, :index_document_after_save, :use_background_jobs, :schema_models

    class << self

      def configure
        yield self if block_given?
      end

      def index_prefix
        "#{@@index_prefix}_" if @@index_prefix.present?
      end

      def prepend_env
       "#{Rails.env}_" if prepend_env_in_index?
      end

      def prepend_env_in_index?
        !!@@prepend_env_in_index
      end

      def index_document_after_save?
        !!@@index_document_after_save
      end

      def use_background_jobs?
        !!@@use_background_jobs
      end

      def schema_models
        @@schema_models
      end


    end
  end

  ActiveElastic::Config.prepend_env_in_index = true
  ActiveElastic::Config.index_document_after_save = false
  ActiveElastic::Config.use_background_jobs = false
  ActiveElastic::Config.schema_models = []
end