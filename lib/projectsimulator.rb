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

    def initialize(e, time: nil, title: '', debug: false)

      @time, @debug = time, debug
      @title = e.text('event')
      @actions = []
      @triggers = []
      @constraints = []

      e.xpath('trigger').each do |x| 
        @triggers << Trigger.new(x.text().strip, time: time, debug: debug)\
            .to_type
      end

      e.xpath('action').each do |x|
        @actions << Action.new(x.text().strip, debug: debug).to_type
      end

      e.xpath('constraint').each do |x|
        puts 'before Constraints.new'
        @constraints << Constraint.new(x.text().strip, \
                                       time: time, debug: debug).to_type
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
    
    def to_node()
      
      e = Rexle::Element.new(:event, attributes: {title: @title})
      
      e.add node_collection(:triggers, @triggers)
      e.add node_collection(:actions, @actions)
      e.add node_collection(:constraints, @constraints)
      
      return e
    end
    
    def to_rowx()
      
      s = "event: %s\n\n" % @title
      s + [@triggers, @actions, @constraints]\
          .map {|x| x.collect(&:to_rowx).join("\n")}.join("\n")
    end
    
    private
    
    def node_collection(name, a)
      
      e = Rexle::Element.new(name)
      a.each {|x| e.add x.to_node}
      return e
      
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
      
      get /^once only|only once|once|one time|1 time$/i do |s|
        FrequencyConstraint.new(1, debug: @debug)
      end
      
      get /^twice only|only twice|twice|two times|2 times$/i do |s|
        FrequencyConstraint.new(2, debug: @debug)
      end
      
      get /^(Maximum|Max|Up to) ?three times|3 times$/i do |s|
        FrequencyConstraint.new(3, debug: @debug)
      end                    
      
      get /^(Maximum|Max|Up to) ?four times|4 times$/i do |s|
        FrequencyConstraint.new(4, debug: @debug)
      end                          

    end

    private

    alias find_constraint run_route    
  end

  class MotionTrigger

    attr_reader :location
    
    def initialize(locationx, location: locationx)
      @location = location
    end

    def match()
      @location.downcase == location.downcase
    end
    
    def to_node()
      Rexle::Element.new(:trigger, \
                         attributes: {type: :motion, location: @location})
    end
    
    def to_rowx()
      "trigger: Motion detected in the %s" %  @location
    end        

  end

  class SayAction

    def initialize(s, text: s)
      @s = s
    end
    
    def call()
      "say: %s" % @s
    end
    
    def to_node()
      Rexle::Element.new(:action, attributes: {type: :say, text: @s})
    end        
    
    def to_rowx()
      "action: say %s" %  @s
    end    

  end
  
  class WebhookAction
    
    attr_accessor :url

    def initialize(namex, name: namex, url: '127.0.0.1')
      @name = name
      @url = url
    end
    
    def call()
      "webhook: %s" % @url
    end
    
    def to_node()
      Rexle::Element.new(:action, \
                         attributes: {type: :webhook, name: @name, url: @url})
    end    
    
    def to_rowx()
      s = "action: webhook %s" %  @name
      s += "\n  url: %s" % @url
    end

  end

  class TimeConstraint    
    
    attr_accessor :time
    
    def initialize(timesx, times: timesx, time: nil)
      @times, @time = times, time
    end
    
    def match()
      ChronicBetween.new(@times).within?(@time)
    end
    
    def to_node()
      Rexle::Element.new(:constraint, \
                         attributes: {type: :time, times: @times})      
    end    
    
    def to_rowx()            
      "constraint: %s" %  @times
    end    
        
  end

  class FrequencyConstraint      
      
    def initialize(freqx, freq: freqx, debug: false)
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
      @counter = 0
    end
    
    def to_node()
      Rexle::Element.new(:constraint, \
                         attributes: {type: :frequency, freq: @freq})      
    end
    
    def to_rowx()
      
      freq = case @freq
      when 1
        'Once'
      when 2
        'Twice'
      else
        "Maximum %s times" % @freq
      end
      
      "constraint: %s" %  freq

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
    
    def to_doc()
      
      doc = Rexle.new('<events/>')      
      @events.each {|event| doc.root.add event.to_node }
      return doc
      
    end
    
    def to_rowx()
      @events.collect(&:to_rowx).join("\n\n#{'-'*50}\n\n")
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
