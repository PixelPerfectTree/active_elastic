require 'rails'
module ActiceElastic
  class Railtie < Rails::Railtie
    initializer "active_elastic.configure_rails_initialization" do

      if(defined? ActiveModel::Serializers)
        class Elasticsearch::Model::Response::Results
          include ActiveModel::ArraySerializerSupport
          alias_method :read_attribute_for_serialization, :send
          alias_method :length, :size
          alias_method :total_entries, :total
        end

        class Elasticsearch::Model::Response::Result
          include ActiveModel::SerializerSupport
          alias_method :read_attribute_for_serialization, :send
        end

        class Hashie::Mash
          include ActiveModel::SerializerSupport
          alias_method :read_attribute_for_serialization, :send
        end
      end

    end

    rake_tasks do
      load "#{File.dirname(__FILE__)}/../tasks/active_elastic_schema.rake"
    end
  end
end