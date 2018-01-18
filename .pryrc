$:.unshift '/app'

def reload!
  require 'sipo-email'
  files = Dir['/app/lib/*.rb']
  files.each {|file| require file }
  p "Loaded #{files.count} files."
end

reload!