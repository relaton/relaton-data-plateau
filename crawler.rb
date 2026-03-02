# frozen_string_literal: true

require 'relaton/plateau/data_fetcher'

FileUtils.rm Dir.glob('index-*')
FileUtils.rm_rf 'data'

Relaton::Plateau::DataFetcher.fetch "plateau-handbooks"
Relaton::Plateau::DataFetcher.fetch "plateau-technical-reports"

system('zip index-v1.zip index-v1.yaml')
system('git add index-v1.zip index-v1.yaml')
