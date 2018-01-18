$:.unshift '/app'

def reload!
  files = Dir['/app/lib/*.rb']
  files.each {|file| require file }
  p "Loaded #{files.count} files."
end

reload!