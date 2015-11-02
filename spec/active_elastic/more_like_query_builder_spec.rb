require 'spec_helper'

describe ActiveElastic::MoreLikeQueryBuilder do

  let(:model) {
    Struct.new(:id, :source_id) do

      def class
        Struct.new(:index_name) do
          def self.index_name
            "test"
          end

          def self.to_s
            "test"
          end
        end
      end
    end
  }

  let(:query_hash) do
    {
      query: {
        filtered: {
            query: {
                more_like_this: {
                    fields: [:title],
                    docs: [
                        {
                            _index: "test",
                            _type: "test",
                            _id: 1
                        }
                    ],
                    min_term_freq: 1,
                    max_query_terms: 12
                }
            },
            filter: {
              term: { source_id: 1 }
            }
        }
      }
    }
  end

  let(:query_array) do
    {
      query: {
        filtered: {
            query: {
                more_like_this: {
                    fields: [:title],
                    docs: [
                        {
                            _index: "test",
                            _type: "test",
                            _id: 5
                        }
                    ],
                    min_term_freq: 1,
                    max_query_terms: 12
                }
            },
            filter: {
              term: { source_id: 5 }
            }
        }
      }
    }
  end

  context "using a Hash as terms" do
    it "should return a valid query" do
      query = described_class.build(model.new(1), [:title], {source_id: 1})
      expect(query).to include(query_hash)
    end
  end

  context "using a Array as terms" do
    it "should return a valid query" do
      query = described_class.build(model.new(5, 5), [:title], [:source_id])
      expect(query).to include(query_array)
    end
  end

end