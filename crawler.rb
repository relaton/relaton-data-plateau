# frozen_string_literal: true

require 'relaton/plateau'

FileUtils.rm Dir.glob('index-*')
FileUtils.rm_rf 'data'

Relaton::Plateau::Fetcher.fetch "plateau-handbooks"
Relaton::Plateau::Fetcher.fetch "plateau-technical-reports"

system('zip index-v1.zip index-v1.yaml')
system('git add index-v1.zip index-v1.yaml')
