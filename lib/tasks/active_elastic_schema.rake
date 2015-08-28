namespace :active_elastic_schema do

  desc "Creates the Schema for Elastic Search"
  task create_schema: :environment do
    ActiveElastic::ElasticSchema.create
  end

  desc "Drops the Schema for Elastic Search"
  task drop_schema: :environment do
    ActiveElastic::ElasticSchema.drop
  end

  desc "Drops and Creates the Schema for Elastic Search"
  task recreate_schema: :environment do
    ActiveElastic::ElasticSchema.force_create
  end

  desc "Imports all the models in the schema"
  task migrate: :environment do
    ActiveElastic::Config.schema_models.each{ |model| model.to_s.constantize.import_async }
  end

  desc "Imports data from a given model"
  task :import, [:model_klass]  => :environment  do |t, args|
    args[:model_klass].to_s.constantize.import_async
  end

  desc "Imports data from a given model"
  task :import_now, [:model_klass]  => :environment  do |t, args|
    ActiveElastic::ModelImporter.new(args[:model_klass].to_s.constantize).import
  end

end