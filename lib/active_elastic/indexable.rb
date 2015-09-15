module ActiveElastic
  module Indexable

    def self.included(base)
      base.extend ClassMethods
    end

    #  Relations to be indexed after updating the model.
    #
    #  Usage:
    #
    #  def index_relations(exclude_relations: [])
    #     index_relation(:users) unless exclude_relations.include? :users
    #     index_relation(:comments) unless exclude_relations.include? :comments
    #  end
    #

    def index_relations(exclude_relations: []); end;

    def index_relation(relation, exclude_relations: [])
      relation = self.send(relation)
      if relation.respond_to? :each
        relation.each { |r| r.index_document(exclude_relations: exclude_relations) }
      else
        relation.index_document(exclude_relations: exclude_relations)
      end
    end

    def index_document(exclude_relations: [])
      ActiveElastic::Workers::Indexer.index_record(self, exclude_relations: exclude_relations)
    end

    module ClassMethods
      def refresh_index!
        __elasticsearch__.refresh_index!
      end

      def import_async
        ActiveElastic::Workers::Importer.perform_async(self)
      end

      # Relations to be eager loaded when object is imported via ElasticSeach::ModelImporter
      def elastic_relations(relations = [])
        @elastic_relations ||= relations
      end
    end
  end
end