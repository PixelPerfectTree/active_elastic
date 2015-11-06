module ActiveElastic
  class FilterParser
    attr_reader :string

    def initialize(string)
      @string = string
    end

    def query_conditions
      @query_conditions ||= string.split(';')
    end

    def conditions
      @condition ||= query_conditions.map { |c| Condition.new(c) }
    end

    def must_queries
      conditions.map { |c| c.to_h  if c.positive? }.compact
    end

    def must_not_queries
      conditions.map { |c| c.to_h  if c.negative? }.compact
    end

    class Condition
      attr_reader :operation

      def initialize(operation)
        @operation = operation
      end

      def field
        @field ||= operation.split(operator).first
      end

      def value
        @value ||= operation.split(operator).last
      end

      def operator
        regex = /\w(=|!=|<=|>=|<|>)\w/
        match = operation.gsub(regex)

        return if match.to_a.size != 1

        @operator ||= operation.match(regex)[1]
      end

      def to_h
        equals = ["=", "!="]
        range = ["=>", "<=", "<", ">"]

        if equals.include?(operator)
          h_equals
        elsif range.include?(operator)
          h_range
        end
      end

      def positive?
        !["!="].include?(operator)
      end

      def negative?
        !positive?
      end

      def valid?
        operation.present?
      end

      def field_value
        h = Hash.new
        h[field] = value
        h
      end

      def range_value
        range_map = {
          "<" => :lt,
          "<=" => :lte,
          ">" => :gt,
          ">=" => :gte,
        }

        return if !range_map.has_key?(operator)

        h = Hash.new
        h[field] = {}
        h[field][range_map[operator]] = value
        h
      end

      private

      def h_equals
        {
          query: {
            term: field_value
          }
        }
      end

      def h_range
        {
          range: range_value
        }
      end

    end
  end
end