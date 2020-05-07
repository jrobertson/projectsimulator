#!/usr/bin/env ruby

# file: projectsimulator.rb

require 'rowx'
require 'easydom'
require 'app-routes'
require 'chronic_between'


module ProjectSimulator

  class Model
    include AppRoutes

    def initialize(obj=nil, root: 'building1')

      super()
      @root = root
      @location = nil
      build(obj, root: root) if obj

    end

    def build(raw_requests, root: @root)

      @ed = EasyDom.new(debug: false, root: root)
      raw_requests.lines.each {|line| request(line) }

    end
    
    def get_device(h)
      
      a = h[:location].split(/ /)
      a << h[:device]
      status = a.inject(@ed) {|r,x| r.send(x)}.send(h[:action])
      "The %s %s is %s." % [h[:location], h[:device], status]
      
    end    

    def op()
      @ed
    end

    def query(s)
      @ed.e.element(s)
    end
    
    def request(s)

      params = {request: s}
      requests(params)
      h = find_request(s)

      method(h.first[-1]).call(h)
      
    end      
    
    def set_device(h)
      
      a = h[:location].split(/ /)
      a << h[:device]
      a.inject(@ed) {|r,x| r.send(x)}.send(h[:action], h[:value])
      
    end

    def to_sliml()
      @ed.to_sliml
    end

    def xml(options=nil)
      @ed.xml(pretty: true).gsub(' style=\'\'','')
    end

    protected      

    def requests(params) 

      # e.g. switch the livingroom gas_fire off
      #
      get /(?:switch|turn) the ([^ ]+) +([^ ]+) +(on|off)$/ do |location, device, onoff|
        {type: :set_device, action: 'switch=', location: location, device: device, value: onoff}
      end
      
      # e.g. switch the gas _fire off
      #
      get /(?:switch|turn) the ([^ ]+) +(on|off)$/ do |device, onoff|
        location = dev_location(device)
        {type: :set_device, action: 'switch=', location: location, device: device, value: onoff}
      end      
      
      # e.g. is the livingroom gas_fire on?
      #
      get /is the ([^ ]+) +([^ ]+) +(?:on|off)\??$/ do |location, device|
        {type: :get_device, action: 'switch', location: location, device: device}
      end

      # e.g. is the gas_fire on?
      #
      get /is the ([^ ]+) +(?:on|off)\??$/ do |device|
        location = dev_location(device)        
        {type: :get_device, action: 'switch', location: location, device: device}
      end            
      
      # e.g. fetch the livingroom temperature reading
      #
      get /fetch the ([^ ]+) +([^ ]+) +(?:reading)$/ do |location, device|
        {type: :get_device, action: 'reading', location: location, device: device}
      end

      # e.g. fetch the temperature reading
      #
      get /fetch the ([^ ]+) +(?:reading)$/ do |device|
        location = dev_location(device)        
        {type: :get_device, action: 'reading', location: location, device: device}
      end          

    end
    
    private
    
    def dev_location(device)
      a = query('//'+ device).backtrack.to_xpath.split('/')
      a[1..-2].join(' ')            
    end
        
    alias find_request run_route    

  end
  
  
  class Event

    attr_accessor :title
    attr_reader :triggers, :actions, :constraints, :messages

    def initialize(e, time: nil, debug: false)    

      @time, @debug = time, debug
      @title = e.text('event')
      @actions = []
      @triggers = []
      @constraints = []

      e.xpath('trigger/text()').each do |x| 
        @triggers << Trigger.new(x, time: time, debug: debug).to_type
      end

      e.xpath('action/text()').each do |x|
        @actions << Action.new(x, debug: debug).to_type
      end

      e.xpath('constraint/text()').each do |x|
        puts 'before Constraints.new'
        @constraints << Constraint.new(x, time: time, debug: debug).to_type
      end

    end
    
    def match(trigger: nil, location: '')
      
      @messages = []
      
      h = {motion: MotionTrigger}
      
      if @triggers.any? {|x| x.is_a? h[trigger.to_sym] and x.match } then
        
        if @constraints.all?(&:match) then
        
          @messages = @actions.map(&:call)
          
        else
          
          puts 'else reset?' if @debug
          a = @constraints.select {|x| x.is_a? FrequencyConstraint }
          puts 'a:' + a.inspect if @debug
          a.each {|x| x.reset if x.counter > 0 }
          return false
        end
        
      end
      
    end
    
    def time=(val)
      @time = val
      @constraints.each {|x| x.time = val if x.is_a? TimeConstraint }
    end
    
  end

  class Action
    include AppRoutes

    attr_reader :to_type

    def initialize(s, event: '', debug: false)

      super()
      @debug = debug
      params = {s: s, event: event}
      actions(params)
      @to_type = find_action(s) || {}

    end

    protected

    def actions(params) 

      puts 'inside actions'
      # e.g. Say 'Good morning'
      #
      get /say ['"]([^'"]+)/i do |s|
        puts 's: ' + s.inspect if @debug
        SayAction.new(s)
      end
      
      # e.g. webhook entered_kitchen
      #
      get /webhook (.*)/i do |name|
        WebhookAction.new(name)
      end      
      
      get /.*/ do
        puts 'action unknown' if @debug
        {}
      end

    end

    private

    alias find_action run_route

  end

  class Trigger
    include AppRoutes

    attr_reader :to_type

    def initialize(s, time: nil, debug: false)

      super()
      @time, @debug = time, debug
      params = {s: s}
      puts 'inside Trigger'
      puts 'params: ' + params.inspect
      triggers(params)
      @to_type = find_trigger(s)

    end

    protected

    def triggers(params) 
      
      puts 'inside triggers'

      # e.g. Motion detected in the kitchen
      #
      get /motion detected in the (.*)/i do |location|
        puts 'motion detection trigger'
        MotionTrigger.new(location)
      end

    end

    private

    alias find_trigger run_route

  end
  
  class Constraint
    include AppRoutes
    
    attr_reader :to_type
    
    def initialize(s, time: nil, debug: false)
      
      super()
      @time, @debug = time, debug
      
      params = {s: s }
      constraints(params)
      @to_type = find_constraint(s)
      
    end
    
    protected

    def constraints(params) 

      puts 'inside constraints' if @debug
      # e.g. Between 8am and 10am
      #
      get /^between (.*)/i do |s|
        TimeConstraint.new(s, time: @time)
      end
      
      get /^on a (.*)/i do |s|
        TimeConstraint.new(s, time: @time)
      end
      
      get /^(after .*)/i do |s|
        TimeConstraint.new(s, time: @time)
      end      
      
      get /^once only/i do |s|
        FrequencyConstraint.new(1, debug: @debug)
      end        

    end

    private

    alias find_constraint run_route    
  end

  class MotionTrigger

    attr_reader :location
    
    def initialize(location)
      @location = location
    end

    def match()
      @location.downcase == location.downcase
    end

  end

  class SayAction

    def initialize(s)
      @s = s
    end
    
    def call()
      "say: %s" % @s
    end

  end
  
  class WebhookAction
    
    attr_accessor :url

    def initialize(name)
      @name = name
      @url = '127.0.0.1'
    end
    
    def call()
      "webhook: %s" % @url
    end

  end

  class TimeConstraint    
    
    attr_accessor :time
    
    def initialize(times, time: nil)
      @times, @time = times, time
    end
    
    def match()
      ChronicBetween.new(@times).within?(@time)
    end
        
  end

  class FrequencyConstraint      
      
    def initialize(freq, debug: false)
      @freq, @debug = freq, debug
      @counter = 0
    end
    
    def counter()
      @counter
    end
    
    def increment()
      @counter += 1
    end
    
    def match()
      @counter < @freq
    end
    
    def reset()
      puts 'resetting' if @debug
@foo = 0      
@counter = 0
    end
    
  end

  class Controller
    
    attr_reader :events
    attr_accessor :time

    def initialize(s, time: Time.now, debug: false)
      
      @time, @debug = time, debug

      doc = Rexle.new(RowX.new(s).to_xml)

      @events = doc.root.xpath('item')\
          .map {|e| Event.new(e, time: @time, debug: debug) }

    end
    
    def time=(val)
      @time = val
      @events.each {|event| event.time = val }
    end
    
    def trigger(name, location: '')
      
      events = @events.select do |event|
        
        puts 'event: '  + event.inspect if @debug

        event.match(trigger: 'motion', location: location)
        
      end
      
      puts 'events: ' + events.inspect if @debug
      
      events.each do |event|
        c = event.constraints.select {|x| x.is_a? FrequencyConstraint }
        puts 'c:' + c.inspect
        c.each(&:increment)
      end
      
      events.flat_map(&:messages)
      
    end

  end  
end
