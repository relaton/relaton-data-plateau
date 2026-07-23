# frozen_string_literal: true

require 'relaton/plateau/data_fetcher'
require 'relaton/index'
require 'pubid'
require 'zip'

FileUtils.rm Dir.glob('index-*')
FileUtils.rm_rf 'data'

# The fetcher now writes the pubid-canonical index-v2.yaml (rows are
# Pubid::Plateau::Identifier objects serialized as `_type: pubid:plateau:…`).
Relaton::Plateau::DataFetcher.fetch 'plateau-handbooks'
Relaton::Plateau::DataFetcher.fetch 'plateau-technical-reports'

# Render a canonical pubid string back to the legacy plain string that
# older/released relaton versions expect for index-v1.yaml. Assumes the current
# corpus (all TRs edition 1.0, underscore sub-numbers); an id that matches
# neither shape raises rather than leaking canonical text (e.g. `第..版`) into
# the plain-string index. If the corpus outgrows these shapes, extend the
# mapping (or freeze the last good index-v1.* as a static snapshot) instead.
def legacy_latin(pid)
  s = pid.to_s
  case s
  when /\APLATEAU Handbook (#[\d-]+) 第([\d.]+)版\z/ then "PLATEAU Handbook #{$1} #{$2}"
  when /\APLATEAU Technical Report (#[\d-]+)\z/      then "PLATEAU Technical Report #{$1.tr('-', '_')} 1.0"
  else raise "cannot map canonical id to legacy index-v1 form: #{s.inspect}"
  end
end

# Read the just-written canonical index and derive the legacy plain-string index.
type = Relaton::Index::Type.new(:plateau, nil, 'index-v2.yaml', nil, ::Pubid::Plateau::Identifier)
v1 = type.index.map { |r| { id: legacy_latin(r[:id]), file: r[:file] } }
File.write 'index-v1.yaml', v1.to_yaml

# Zip in-process (rubyzip is already a relaton/index dependency) so generation
# does not depend on an external `zip` binary. Each archive is rewritten fresh.
{ 'index-v1.zip' => 'index-v1.yaml', 'index-v2.zip' => 'index-v2.yaml' }.each do |zipfile, yamlfile|
  FileUtils.rm_f zipfile
  Zip::File.open(zipfile, create: true) { |zip| zip.add(yamlfile, yamlfile) }
end

system('git add index-v1.zip index-v1.yaml index-v2.zip index-v2.yaml') or
  warn 'warning: `git add` failed (not a git repo?); index files were still generated'
