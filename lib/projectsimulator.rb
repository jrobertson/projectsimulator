#!/usr/bin/env ruby

# file: projectsimulator.rb


require 'easydom'
require 'app-routes'


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

  class Controller
    
    attr_reader :macros
    attr_accessor :title

    def initialize(mcs, debug: false)
      
      @debug = debug
      @syslog = []
            
      @macros = mcs.macros

    end        
    
    
    def trigger(name, detail={})
      
      macros = @macros.select do |macro|
        
        puts 'macro: '  + macro.inspect if @debug

        valid_trigger = macro.match?(name, detail)
        
        puts 'valid_trigger: ' + valid_trigger.inspect if @debug
        
        if valid_trigger then
          @syslog << [Time.now, :trigger, name] 
          @syslog << [Time.now, :macro, macro.title]
        end
                     
        valid_trigger
        
      end
      
      puts 'macros: ' + macros.inspect if @debug
      
      macros.flat_map(&:run)
    end

  end  
end
