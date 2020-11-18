#!/usr/bin/env ruby

# file: projectsimulator/controller.rb


module ProjectSimulator
    
  class Controller
    
    attr_reader :macros, :model
    attr_accessor :title, :speed

    def initialize(mcs, model=nil, time: Time.now, speed: 1, debug: false)
      
      @debug = debug
      @syslog = []
            
      @macros = mcs.macros
      
      if model then
        @model = Model.new(model)
      end
      
      @state = :stop
      @speed = speed
      
      @qt = UnichronUtils::Quicktime.new time: time, speed: @speed
      @qt.start
      @qt.pause

    end

    # Object Property (op)
    # Helpful for accessing properites in dot notation 
    # e.g. op.livingroom.light.switch = 'off'
    #    
    def op()
      @model.op if @model
    end
    
    def pause()
      @state = :pause
      @qt.pause
    end
    
    def play()
      @state = :play
      @qt.play
    end
    
    def request(s)
      @model.request s
    end
    
    def start()
      

      Thread.new do
        
        old_time = @qt.time - 1
        
        loop do
          
          interval = (1 / (2.0 * @speed))
          (sleep interval; next) if @state != :play or old_time == @qt.time
          #puts Time.now.inspect if @debug
          r = self.trigger :timer, {time: @qt.time}
          
          yield(r) if r.any?
          
          puts 'r: ' + r.inspect if @debug and r.any?
          sleep interval
          old_time  = @qt.time
        end
        
      end
    end
    
    def stop()
      @state = :stop
      @qt.pause
    end
    
    def time()
      @qt.time
    end
    
    def trigger(name, detail={})
      
      macros = @macros.select do |macro|
        
        #puts 'macro: '  + macro.inspect if @debug

        # fetch the associated properties from the model if possible and 
        # merge them into the detail.
        #
        valid_trigger = macro.match?(name, detail, op())
        
        #puts 'valid_trigger: ' + valid_trigger.inspect if @debug
        
        if valid_trigger then
          @syslog << [Time.now, :trigger, name] 
          @syslog << [Time.now, :macro, macro.title]
        end
                     
        valid_trigger
        
      end
      
      #puts 'macros: ' + macros.inspect if @debug
      
      macros.flat_map(&:run)
    end

  end
end
