module ActiveElastic
  module Scopable
    def self.included(base)
      base.extend ClassMethods
      base.class_eval do

        class << self
          attr_accessor :query_scope_class
          attr_accessor :elastic_query_scope
        end

        self.query_scope_class = Class.new do
          attr_accessor :query_scope

          def initialize(query_scope)
            @query_scope = query_scope
          end

          def self.define_scope(name, body)
            self.send(:define_method, name) do |*args|
              self.instance_exec(*args) do
                query_scope.instance_exec(*args, &body)
              end
            end
          end
        end

      end
    end

    module ClassMethods
      def elastic_find
        self.elastic_query_scope = ActiveElastic::Query::Base.new(self, self.query_scope_class, true)
      end

      def elastic_scope(name, body)
        query_scope_class.define_scope(name, body)
      end

      def default_elastic_scope(body)
        query_scope_class.define_scope(:default_elastic_scope, body)
      end

    end
  end
end
