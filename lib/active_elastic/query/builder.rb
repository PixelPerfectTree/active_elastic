module ActiveElastic
  module Query
    class Builder
      def initialize
        @query = {}
        @filtered = {must: []}
        @order = []
      end

      def build
        query = {}
        query_body = {}
        query_body[:bool] = @filtered if @filtered[:must].any?
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
          @filtered[:must].push({match_phrase: {"#{field}" => value}}) if condition
          self
        end
      end

      def in(field, values, condition = true)
        @filtered[:must].push({terms: {"#{field}" => values}}) if condition
        self
      end

      def included_in(field, values, condition = true)
        @filtered[:must].push({terms: {"#{field}" => values, execution: :and}}) if condition
        self
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
        range_clause = {
          "#{range_type}" => value
        }
        @filtered[:must].push({range: {"#{field}" => range_clause}}) if condition
        self
      end

      private

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

    end
  end
end