module ErrorHandler
  def self.handle
    Proc.new do |error|
      puts " error: #{error}"
      puts error.backtrace
    end
  end
end
