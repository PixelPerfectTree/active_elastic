ActiveElastic
===============

ActiveElastic grants to an ActiveRecord models to query and index documents easily to ElasticSearch.

Requirements
----------

ActiveElastic uses the following gems to work properly:

* **ActiveRecord**
* **elasticsearch-model**
* **elasticsearch-persitence**
* **Sidekiq**: For document indexing in the background. (Future version will use ActiveJob)

Installation
-----------
Add this line to your application's Gemfile:

```ruby
gem 'active_elastic', git: 'https://github.com/PixelPerfectTree/active_elastic'
```

And then execute:

    $ bundle install


Getting Started
------------
ActiveElastic is supposed to work with an ActiveRecord model.

Include `ActiveElastic::Model` to ActiveRecord models to power it up!.

  class Post < ActiveRecord::Base
    include ActiveElastic::Model
  end
  
Configuration
-------------
ActiveElastic has a few configuration methods that can be used in an initializer.

    ActiveElastic::Config.configure do |config|
      config.index_prefix = nil                  # Prefix to be use with indexes name. By default is empty.
      config.prepend_env_in_index = true         # Prepend the current enviroment in document index name.
      config.index_document_after_save = false   # Auto index the document when the model is modified.
      config.use_background_jobs = false         # Use Background Jobs for indexing documents (Sidekiq)
      config.schema_models = [                   # Models to be imported by the schema importer.
        :Posts,
        :Comments
      ]
    end

Sidekiq Queues
----------
To use Sidekiq make sure you have this queues in the sidekiq worker: `elastic_search_indexer_worker` and
`elatic_model_importer`

Query Interface
---------
ActiveElastic adds methods to build queries for ElasticSeach.
To begin to build this queries there is a `elastic_find` method we need to use.

### .all
Execute the current query. By default returns all the documents.
    
    Post.elastic_find.all 
    
### .where(field: value)
Filters documents by a condition.

    Post.elastic_find.where(active: true)
    
We also can use a array. This is an alias to `.in`

    Post.elastic_find.where(tags: ['tag1', 'tag2'])
    
### .where_not
Same has `where` but negated.

### .first
Return the first document

### .find_by(field: value)
Find a document by a single conditions. Raises `ActiveElastic::RecordNotFound` if document is not found.

### .find(id)
Find a document by ID. Raises `ActiveElastic::RecordNotFound` if document is not found.

### .order(:field)
Add an order condition to the current query.

### limit(number)
Add a limit condition to the current query. By default is 10

### page(number)
Search document with the offset number useing the current limit.

### is_null(:field)
Check if a field is null or missing.

### not_null(:field)
Check if a field is not null or missing.


### included_in(field: values)
Add a conditions where a field has to have all values
    
    Post.elastic_find.inclued_in(tags: ['tag1', 'tags2']) # Find Post that are tagged with tag1 and tag2
    
### not_inclued_in(field: values)
Same as `inclued_in` but negated.

### filter_using(hash)
Execute all the query methods inside a hash.

    conditions = {
      where: { title "Hello World" },
      where: { active: true },
      order: title
    }
    
    Post.elaastic_find.filter_using(conditions).all
    
    
Scopes
------
We also can define scopes inside the model.

    class Post < ActiveRecord::Base
        include ActiveElastic::Model
        
        elastic_scope :started, -> { where(started: true) }
        default_scope, -> { where(active: true) }
    end
    
    Post.elastic_find.started.all
    
If we have to do a query without the default scope we can use `unscoped` method to have a query without default scope.

    Post.elastic_find.unscoped.started.all
    
Indexing
---------

### Indexing documents

The `index_document` method calls the indexer worker.
By default the worker will index the document without using a backgorund job.
If `ActiveElastic::Config.use_background_jobs` is true, it will use Sidekiq the enqueue the document for indexation in the `elastic_search_indexer_worker`.

The indexstion use the `as_indexed_json` method to serialize the object.

**Note:** Background Jobs are disable in the test enviroment.

### Indexing relations

If we want to include relations inside the indexed document. We need to define which relations will be included.

To do this we need to define a `index_relations` method inside the model and use `index_relation` method.

    class Post < ActiveRecord::Base
      include ActiveElastic::Model
      
      def index_relations(exlucluded_relations=[])
         index_relation(:comments) unless exclude_relations.include? :comments
      end
    end
    
The indexer will call the `comments` method and serialize its result. 

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/[my-github-username]/active_elastic/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
