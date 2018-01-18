class Timer
  def self.elapsed(&block)
    start = Time.now
    yield(block)
    finish = Time.now
    e = (finish - start) * 1000
    p "Elapsed time: #{e} ms"
  end
end
