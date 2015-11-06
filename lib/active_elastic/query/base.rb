module ActiveElastic
  module Query
    class Base

      include ActiveElastic::Query::QueryMethods

      def initialize(model, scope, execute_default_scope=false)
        @model = model
        @scope = scope.new(self)
        initialize_defaults
        @scope.default_elastic_scope if execute_default_scope && @scope.respond_to?(:default_elastic_scope)
      end

      def initialize_defaults
        @query = {}
        @filtered_query = {}
        @filtered_filter = {must: [], must_not: []}
        @like = {}
        @order = []
        @min_score = nil
      end

      def unscoped
        initialize_defaults
        self
      end

      def related(model, fields, options = {})
        options[:min_term_freq] ||= 1
        options[:max_query_terms] ||= 12

        @min_score = options[:min_score] || 4
        @filtered_query = {
          more_like_this: {
                docs: [
                    {
                        _index: model.class.index_name,
                        _type: model.class.to_s.downcase,
                        _id: model.id
                    }
                ],
                fields: fields,
                min_term_freq: options[:min_term_freq],
                max_query_terms: options[:max_query_terms]
            }
        }

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
        filters.compact.each { |filter| self.send(filter.first, filter.last) if filter.last.present? }
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
        model.search(build)
      end

      def build_query_body
        if @filtered_filter || @filtered_query
          query_body = { filtered: {} }
          query_body[:filtered][:filter] = { bool: @filtered_filter } if @filtered_filter.any?
          query_body[:filtered][:query] = @filtered_query if @filtered_query.any?
          query_body
        end
      end

      def build
        body = build_query_body
        @query[:min_score] = @min_score if @min_score.present?
        @query[:query] = body if body.any?
        @query[:sort] = @order if @order.any?
        @query[:size] = @per if @per
        @query[:from] = @offset if @offset
        @query
      end

      def add_query

      end

      def multi_match(term, fields, options = {})
        if options[:order].present?
          order(options[:order])
        else
          @order = []
        end

        @min_score = options[:min_score] || 1

        @filtered_query[:multi_match] = {
          query: term,
          fields: fields,
          minimum_should_match: "90%"
        }

        @filtered_query[:multi_match][:type] = options[:type] if options[:type].present?

        self
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
        @filtered_filter[:must].push({nested: {
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
        @filtered_filter[:must].push({nested: {
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
        @filtered_filter[:must].push( hash ) if condition
        self
      end

      def add_not_query_condition(hash, condition)
        add_not_condition(add_query(hash), condition)
      end

      def add_not_condition(hash, condition)
        @filtered_filter[:must_not].push( hash ) if condition
        self
      end

    end
  end
end