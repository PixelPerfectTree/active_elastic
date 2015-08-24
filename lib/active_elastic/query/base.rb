module ActiveElastic
  module Query
    class Base

      include ActiveElastic::Query::QueryMethods

      def initialize(model, scope)
        @model = model
        @scope = scope.new(self)
        @query = {}
        @filtered = {must: [], must_not: []}
        @order = []
        @unscoped = false;
      end

      def unscoped
        @unscoped = true
        self
      end

      def find(id)
        find_by(:id, id)
      end

      def find_by(field, id)
        where(field, id).first or raise ActiveElastic::RecordNotFound
      end

      def method_missing(method, *args, &block)
        scope.send(method, *args, &block)
      end

      def filter_using(filters)
        filters.compact.each { |filter| self.send(filter.first, filter.last) }
        self
      end

      def paginate(options = {page: 1, per_page: 10})
        per(options[:per_page] || 10)
        page(options[:page] || 1)
      end

      def first
        per(1).page(1).all.first
      end

      def all
        execute.results
      end

      def execute
        @scope.default_elastic_scope if !@unscoped && @scope.respond_to?(:default_elastic_scope)
        model.search(build)
      end

      def build
        query = {}
        query_body = { filtered: { filter: { bool: @filtered } } }
        query[:query] = query_body if query_body.any?
        query[:sort] = @order if @order.any?
        query[:size] = @per if @per
        query[:from] = @offset if @offset
        query
      end

      def offset(value)
        @offset = value
        self
      end

      def per(value)
        @per = value
        self
      end

      def limit(value)
        per(value)
      end

      def page(value)
        offset((value - 1) * @per)
        self
      end

      def order(value)
        if value.is_a? Array
          value.each do |item|
            parse_order_condition(item)
          end
        else
          parse_order_condition(value)
        end
        self
      end

      def where(field, value, condition = true)
        if value.is_a? Array
          self.in(field, value, condition)
        else
          add_query_condition({match_phrase: {"#{field}" => value}}, condition)
        end
      end

      def where_not(field, value, condition = true)
        if value.is_a? Array
          self.not_in(field, value, condition)
        else
          add_not_query_condition({match_phrase: {"#{field}" => value}}, condition)
        end
      end

      def not_null(field, condition = true)
        add_condition({exists: {field: "#{field}"}}, condition)
      end

      def is_null(field, condition = true)
        add_condition({missing: {field: "#{field}"}}, condition)
      end

      def in(field, values, condition = true)
        add_query_condition( {terms: {"#{field}" => values}}, condition)
      end

      def not_in(field, values, condition = true)
        add_not_query_condition( {terms: {"#{field}" => values}}, condition)
      end


      def included_in(field, values, condition = true)
        add_query_condition({terms: {"#{field}" => values, execution: :and}}, condition)
      end

      def not_included_in(field, values, condition = true)
        add_not_query_condition({terms: {"#{field}" => values, execution: :and}}, condition)
      end


      def nested_where(relation, field, value, condition = true)
        @filtered[:must].push({nested: {
                path: "#{relation}",
                query: {
                    bool: {
                        must: [
                          { match: { "#{relation}.#{field}" => value }}
                        ]
                    }
                }
            }
        })
        self
      end

      def nested_in(relation, field, value, condition = true)
        @filtered[:must].push({nested: {
                path: "#{relation}",
                query: {
                    bool: {
                        must: [
                          { terms: { "#{relation}.#{field}" => value }}
                        ]
                    }
                }
            }
        })
        self
      end

      def range(field, range_type, value, condition = true)
        add_condition({range: {"#{field}" => { "#{range_type}" => value }}}, condition)
      end

      private

      attr_reader :model, :scope

      def add_order_condition(field, direction = :asc)
        @order.push("#{field}" => {order: direction})
      end

      def parse_order_condition(condition)
        if condition.is_a? Hash
          add_order_condition(condition.to_a.first.first, condition.to_a.first.last)
        else
          add_order_condition(condition)
        end
      end

      def add_query(hash)
        {query: hash}
      end

      def add_query_condition(hash, condition)
        add_condition(add_query(hash), condition)
      end

      def add_condition(hash, condition)
        @filtered[:must].push( hash ) if condition
        self
      end

      def add_not_query_condition(hash, condition)
        add_not_condition(add_query(hash), condition)
      end

      def add_not_condition(hash, condition)
        @filtered[:must_not].push( hash ) if condition
        self
      end

    end
  end
end