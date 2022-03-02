class Cancellation
  def self.hi
    puts "Hello world!"
  end

  # with_cancel evaluates 'block', and calls 'abort' in another
  # thread if the thread-local cancel event occurs before or during
  # (or possibly even shortly after) the call is complete.
  # The abort and block procedures must be safe to call concurrently.
  #
  # Use this around any potentially slow operation that
  # supports asynchronous cancellation.
  def self.with_cancel(abort, &block)
    mu = Mutex.new # TODO: does Ruby have an AtomicBoolean?
    done = false

    cancel = Thread.current[:cancel] # TODO crash if not present
    
    # The watchdog thread may be killed at any moment.
    watchdog = Thread.new do
      cancel.wait
      abort.call unless mu.synchronize { done }
    end
    block.call
  ensure
    mu.synchronize { done = true }
    watchdog.kill
    watchdog.join
  end
end