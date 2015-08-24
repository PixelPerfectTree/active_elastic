require 'spec_helper'

describe ActiveElastic::Model do

  before(:all) do
    ActiveElastic::Config.configure do |c|
      c.index_prefix = nil
      c.index_document_after_save = true
    end

    class FakeModel

      class << self
        attr_accessor :prc_save, :prc_destroy
      end

      ELASTIC_RAW_FIELDS = [:extra]

      def self.table_name
        "fake_models"
      end

      def self.model_name
        ActiveModel::Name.new(self)
      end

      def self.column_names
        [:id, :name, :date, :age, :all_star, :extra]
      end

      attr_accessor :id, :name, :date, :age, :all_star, :extra, :hobbies, :friends

      def initialize(attrs)
        @id = attrs[:id]
        @name = attrs[:name]
        @date = attrs[:date]
        @age = attrs[:age]
        @all_star = attrs[:all_star] || false
        @extra = attrs[:extra]
        @hobbies = attrs[:hobbies] || []
        @friends = attrs[:friends] || []
      end

      def as_indexed_json(options = {})
        {
          id: id,
          name: name,
          date: date,
          age: age,
          all_star: all_star,
          extra: extra,
          raw_extra: extra && extra.parameterize(' '),
          hobbies: hobbies,
          friends: friends
        }
      end

      def save
        self.class.prc_save.each{|p| self.instance_exec(&p) }
      end

      def destroy
        self.class.prc_destroy.each{|p| self.instance_exec(&p) }
      end

      def self.index_document; end;

      def self.delete_document; end;

      def self.after_save(prc)
        @prc_save ||= []
        @prc_save.push(prc)
      end

      def self.after_destroy(prc)
        @prc_destroy ||= []
        self.prc_destroy.push(prc)
      end

      include ActiveElastic::Model

      settings do
        mappings dynamic: true do
          indexes :extra_raw, type: :string, analyzer: :english, fields: { raw: { type: :string, index: :not_analyzed } }
        end
      end

      elastic_scope :all_stars, -> { where(:all_star, true) }

      # Every query method receives an extra boolean parameters which indicates if this condition should be included in the query
      elastic_scope :only_all_stars, -> (valid = true) { where(:all_star, true, valid) }

      default_elastic_scope -> { range(:age, :gt, 18) }
    end

  end

  before(:each) do
    FakeModel.__elasticsearch__.create_index!(force: true)
  end

  let(:model) { FakeModel.new(id: 1, name: "Dude", date: Date.today, age: 9000) }

  let(:model_list) {
    [
      FakeModel.new(id: 1, name: "I'm the number one Dude", date: Date.today, age: 7000, all_star: true, extra: 'Rand'),
      FakeModel.new(id: 2, name: "Dude", date: Date.today, age: 7000, all_star: true, extra: 'rand'),
      FakeModel.new(id: 3, name: "Marcos", date: Date.today, age: 7000, all_star: true, extra: 'oil'),
      FakeModel.new(id: 4, name: "Briam", date: Date.today, age: 1000, all_star: true, extra: 'gas'),
      FakeModel.new(id: 5, name: "Dude", date: Date.today, age: 5000, all_star: true, extra: 'ruby'),
      FakeModel.new(id: 6, name: "Dude", date: Date.today, age: 2000, all_star: false, extra: 'Rails'),
      FakeModel.new(id: 7, name: "I'm the lucky one", date: Date.today, age: 5000, all_star: false, extra: 'Elastic Search'),
      FakeModel.new(id: 8, name: "Dude", date: Date.today, age: 9000, all_star: false),
      FakeModel.new(id: 9, name: "Dude", date: Date.today, age: 5000, all_star: false),
      FakeModel.new(id: 10, name: "Dude", date: Date.today, age: 9000, all_star: false)

    ]
  }

  let(:full_model_list) {
    FakeModel.new(id: 1, name: "nested", date: Date.today, age: 7000, all_star: true, extra: 'rand',
      hobbies: [
        { id: 1, name: 'baseball'}, { id: 2, name: 'madden'},
      ],
      friends: [
        { id: 1, name: 'ruby'}, { id: 2, name: 'rails'},
      ])
  }

  it "can has instances" do
    expect( model ).not_to be_nil
  end

  context "query methods" do
    before(:each) do
      model_list.each{|m| m.save }
      FakeModel.refresh_index!
    end

    describe "filter_using" do
      it "applies dynamic scopes to the query from a given hash" do
        filter = {
          paginate: {page: 1, per_page: 3},
          only_all_stars: true,
        }

        documents = FakeModel.elastic_find.filter_using(filter).all

        expect(documents.size).to eq 3
        expect(documents.total).to eq 5
      end
    end

    context "pagination" do
      describe "paginate" do
        it "paginates results by indicating how many items should be per page and items from which page should be returned" do
          expect( FakeModel.elastic_find.order(:id).paginate({page: 2, per_page: 3}).all.size ).to eq 3
        end
      end

      describe "total" do
        it "indicates the total number of documents that the matching the query" do
          expect( FakeModel.elastic_find.order(:id).paginate({page: 2, per_page: 3}).all.total ).to eq 10
        end
      end

      describe "limit" do
        it "limits the number of documents matching the query criteria" do
          expect( FakeModel.elastic_find.order(:id).limit(7).all.size ).to eq 7
        end
      end

      describe "offset" do
        it "skips some documents from the beginning of the resultset" do
          expect( FakeModel.elastic_find.order(:id).offset(3).all.size ).to eq 7
        end
      end

      describe "per / page" do
        it "paginates results by indicating how many items should be per page and items from which page should be returned" do
          expect( FakeModel.elastic_find.order(:id).per(4).page(3).all.size ).to eq 2
        end
      end
    end

    describe "all" do
      it "returns a list of documents" do
        expect( FakeModel.elastic_find.all.size ).to eq 10
      end
    end

    describe "first" do
      it "returns the first item from the query" do
        expect( FakeModel.elastic_find.first ).not_to be_nil
      end
    end

    describe "find" do
      it "finds a record by it's id" do
        expect( FakeModel.elastic_find.find(7).name ).to eq "I'm the lucky one"
      end
    end

    describe "find_by" do
      it do
        expect( FakeModel.elastic_find.find_by(:name, 'Marcos').name ).to eq "Marcos"
        expect( FakeModel.elastic_find.find_by(:name, 'Briam').name ).to eq "Briam"
      end
    end

    describe "order" do
      context "defaault sorting" do
        it do
          orderded_list = FakeModel.elastic_find.order(:id).all
          expect( orderded_list.first._source.id ).to eq 1
          expect( orderded_list.to_a.last._source.id ).to eq 10
        end
      end

      context "with sorting direction" do
        it do
          orderded_list = FakeModel.elastic_find.order(id: :desc).all
          expect( orderded_list.first._source.id ).to eq 10
          expect( orderded_list.to_a.last._source.id ).to eq 1
        end
      end

      context "multiple sorting" do
        it do
          orderded_list = FakeModel.elastic_find.order([:age, :id]).all
          expect( orderded_list.first._source.id ).to eq 4
          expect( orderded_list.to_a.last._source.id ).to eq 10
          expect( orderded_list.size ).to eq 10
        end
      end
    end

    describe "where" do
      context "equals value" do
        it do
          expect( FakeModel.elastic_find.where(:all_star, false).all.size ).to eq 5
        end
      end

      context "in array of values" do
        it do
          expect( FakeModel.elastic_find.where(:age, [1000, 7000]).all.size ).to eq 4
        end
      end
    end

    describe "where_not" do
      context "not equals value" do
        it do
          expect( FakeModel.elastic_find.where_not(:all_star, false).all.size ).to eq 5
        end
      end

      context "not in array of values" do
        it do
          expect( FakeModel.elastic_find.where_not(:age, [1000, 7000]).all.size ).to eq 6
        end
      end
    end

    describe "not_null" do
      it do
        expect( FakeModel.elastic_find.not_null(:extra).all.size ).to eq 7
      end
    end

    describe "is_null" do
      it do
        expect( FakeModel.elastic_find.is_null(:extra).all.size ).to eq 3
      end
    end

    describe "in" do
      it do
        expect( FakeModel.elastic_find.in(:age, [1000, 2000, 9000]).all.size ).to eq 4
      end
    end

    describe "not_in" do
      it do
        expect( FakeModel.elastic_find.not_in(:age, [1000, 2000, 9000]).all.size ).to eq 6
      end
    end

    describe "included_in" do
      skip "TODO"
    end

    describe "not_included_in" do
      skip "TODO"
    end

    describe "nested_where" do
      skip "TODO"
    end

    describe "nested_in" do
      skip "TODO"
    end

    describe "range" do
      it do
        expect( FakeModel.elastic_find.range(:age, 'lt', 1000).all.size ).to eq 0
        expect( FakeModel.elastic_find.range(:age, 'lte', 2000).all.size ).to eq 2
        expect( FakeModel.elastic_find.range(:age, 'gt', 2000).all.size ).to eq 8
        expect( FakeModel.elastic_find.range(:age, 'gte', 2000).all.size ).to eq 9
      end
    end

    describe "query method chain" do
      it do
        expect(
          FakeModel.elastic_find.range(:age, 'gt', 2000).not_null(:extra).order(:id).all.size
          ).to eq 5
      end
    end
  end

  context "methods" do
    describe "elastic_field_for" do
      it do
        expect( FakeModel.elastic_field_for(:extra) ).to eq "extra_raw.raw"
        expect( FakeModel.elastic_field_for(:age).to_s ).to eq 'age'
      end
    end
  end

  context "configurations" do
    describe "index_name" do
      it do
        expect(FakeModel.index_name).to eq "test_fake_models"
      end
    end
  end

  context "indexing" do
    describe "index/update" do

      it "Indexes new documents and updates existing documents" do
        #index
        #"Indexes a document in ES"
        model.index_document
        FakeModel.refresh_index!
        expect( FakeModel.elastic_find.find(model.id).name ).to eq "Dude"

        #Update
        #Update the metadate of an existing document in ES
        model.name = "Big Fella"
        model.index_document
        FakeModel.refresh_index!
        expect( FakeModel.elastic_find.find(model.id).name ).to eq "Big Fella"
      end
    end

    describe "delete_document" do
      it "Deletes an indexed document" do
        model.save
        FakeModel.refresh_index!
        expect(FakeModel.elastic_find.all.size).to eq 1
        model.destroy
        FakeModel.refresh_index!
        expect(FakeModel.elastic_find.all.size).to eq 0
      end
    end
  end

  context "scopes" do
    describe "elastic_find/default scope" do
      it do
        model.save
        FakeModel.refresh_index!
        expect(FakeModel.elastic_find.all.size).to eq 1
      end
    end

    context "custom scopes" do
      it do
        model.save
        FakeModel.refresh_index!
        expect( FakeModel.elastic_find.all_stars.all.size ).to eq 0
        model.all_star = true
        model.save
        FakeModel.refresh_index!
        expect( FakeModel.elastic_find.all_stars.all.size ).to eq 1
      end
    end

    context "unscoped" do
      it "finds documents ignoring the default scope" do
        FakeModel.new(id: 2, name: "Young dude", date: Date.today, age: 15).save
        FakeModel.refresh_index!
        expect( FakeModel.elastic_find.unscoped.all.size ).to eq 1
      end
    end
  end

end