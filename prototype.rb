%w(rubygems ruby2ruby yaml).each { |lib| require lib }

class Offload

  def self.reconstitute(yaml)
    args, code = YAML.load(yaml)
    code = eval(code)
    new args, &code
  end
  
  def initialize(args, &code)
    @args, @code = args, code
  end
  
  def run!
    @code.call(@args)
  end
  
  def serialise
    YAML.dump([@args, @code.to_ruby])
  end
  
end

if __FILE__ == $0
  
  require 'test/unit'
  
  class OffloadTest < Test::Unit::TestCase
    
    def setup
      $output = []
      # ruby2ruby can't dump procs with more than one arg
      # so we have to uses hashes, instead of named vars :(
      # but that ain't too bad :)
      @job = Offload.new :name => 'Ryan', :age => 25 do |args|
        $output << "#{args[:name]}'s age is #{args[:age]}"
        true
      end
    end
    
    def test_job_can_be_run
      @result = @job.run!
      assert @result
      assert_equal ['Ryan\'s age is 25'], $output
    end
    
    def test_can_be_dumped
      assert_equal "--- \n- :name: Ryan\n  :age: 25\n- |-\n  proc { |args|\n    ($output << \"\#{args[:name]}'s age is \#{args[:age]}\")\n    true\n  }\n", @job.serialise
    end
    
    def test_can_be_loaded
      @loaded_job = Offload.reconstitute(@job.serialise)
      @result = @loaded_job.run!
      assert @result
      assert_equal ['Ryan\'s age is 25'], $output
    end
    
  end
  
end