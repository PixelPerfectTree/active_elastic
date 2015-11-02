module ActiveElastic
  module Model

    def self.included(base)
      base.class_eval do
        include Elasticsearch::Model
        include Elasticsearch::Model::Indexing

        include ActiveElastic::Callbacks
        include ActiveElastic::Indexable
        include ActiveElastic::Scopable
        extend ClassMethods

        index_name default_index_name
      end


     def more_like_me(fields = [], terms = {})
        query = ActiveElastic::MoreLikeQueryBuilder.build(self, fields, terms)
        self.class.search(query)
      end

    end

    module ClassMethods
      def default_index_name
        "#{ActiveElastic::Config.prepend_env}#{ActiveElastic::Config.index_prefix}#{table_name}"
      end

      def elastic_field_for(field)
        if self::ELASTIC_RAW_FIELDS.include?(field)
          "#{field}_raw.raw"
        else
          field if column_names.include?(field)
        end
      end
    end
  end
end