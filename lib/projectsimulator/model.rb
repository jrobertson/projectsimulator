#!/usr/bin/env ruby

# file: projectsimulator/controller.rb


module ProjectSimulator
    
  class Model
    include AppRoutes

    def initialize(obj=nil, root: 'building1', debug: false)

      super()
      @root, @debug = root, debug
      @location = nil
      
      if obj then
        
        s = obj.strip
        
        puts 's: ' + s.inspect if @debug
        
        if s[0] == '<' or s.lines[1][0..1] == '  ' then
          
          puts 'before easydom' if @debug
          
          s2 = if s.lines[1][0..1] == '  ' then
          
            lines = s.lines.map do |line|
              line.sub(/(\w+) +is +(\w+)$/) {|x| "#{$1} {switch: #{$2}}" }
            end
            
            lines.join
            
          else
            s
          end
          
          @ed = EasyDom.new(s2)
        else
          build(s, root: root) 
        end

      end

    end

    def build(raw_requests, root: @root)

      @ed = EasyDom.new(debug: false, root: root)
      raw_requests.lines.each {|line| request(line) }

    end
    
    
    def get_thing(h)
      
      h[:thing].gsub!(/ /,'_')
      
      if not h.has_key? :location then
        location = false
        h[:location] = find_path(h[:thing]) 
      else
        location = true
      end
      
      puts 'h: ' + h.inspect if @debug
      
      a = []
      a += h[:location].split(/ /)
      a << h[:thing]
      status = a.inject(@ed) {|r,x| r.send(x)}.send(h[:action])
      
      if location then
        "The %s %s is %s." % [h[:location], h[:thing], status]
      else
        "%s is %s." % [h[:thing].capitalize, status]
      end
      
    end          

    # Object Property (op)
    # Helpful for accessing properites in dot notation 
    # e.g. op.livingroom.light.switch = 'off'
    #
    def op()
      @ed
    end

    def query(s)
      @ed.e.element(s)
    end
    
    # request accepts a string in plain english 
    # e.g. request 'switch the livingroom light on'
    #
    def request(s)

      params = {request: s}
      requests(params)
      h = find_request(s)

      method(h.first[-1]).call(h).gsub(/_/,' ')
      
    end      
    
    def set_thing(h)

      h[:thing].gsub!(/ /,'_')
      h[:location] = find_path(h[:thing]) unless h.has_key? :location
      
      a = []
      a += h[:location].split(/ /)
      a << h[:thing]
      
      a.inject(@ed) {|r,x| r.send(x)}.send(h[:action], h[:value])
      
    end       

    def to_sliml(level: 0)
      
      s = @ed.to_sliml

      return s if level.to_i > 0
      
      lines = s.lines.map do |line|
        
        line.sub(/\{[^\}]+\}/) do |x|
          
          a = x.scan(/\w+: +[^ ]+/)
          if a.length == 1 and x[/switch:/] then

            val = x[/(?<=switch: ) *["']([^"']+)/,1]
            'is ' + val
          else
            x
          end

        end
      end
      
      lines.join
      
    end

    def to_xml(options=nil)
      @ed.xml(pretty: true).gsub(' style=\'\'','')
    end
    
    alias xml to_xml
    
    # to_xml() is the preferred method

    protected      

    def requests(params) 

      # e.g. switch the livingroom gas_fire off
      #
      get /(?:switch|turn) the ([^ ]+) +([^ ]+) +(on|off)$/ do |location, device, onoff|
        {type: :set_thing, action: 'switch=', location: location, thing: device, value: onoff}
      end
      
      # e.g. switch the gas _fire off
      #
      get /(?:switch|turn) the ([^ ]+) +(on|off)$/ do |device, onoff|
        {type: :set_thing, action: 'switch=', thing: device, value: onoff}
      end            
      
      # e.g. is the livingroom gas_fire on?
      #
      get /is the ([^ ]+) +([^ ]+) +(?:on|off)\??$/ do |location, device|
        {type: :get_thing, action: 'switch', location: location, thing: device}
      end
      
      # e.g. enable airplane mode
      #
      get /((?:dis|en)able) ([^$]+)$/ do |state, service|
        {type: :set_thing, action: 'switch=', thing: service, value: state + 'd'}
      end
      
      # e.g. switch airplane mode off
      #
      get /switch (.*) (on|off)/ do |service, rawstate|        
        
        state = rawstate == 'on' ? 'enabled' : 'disabled'
        {type: :set_thing, action: 'switch=', thing: service, value: state}
        
      end               
      
      # e.g. is airplane mode enabed?
      #
      get /is (.*) +(?:(?:dis|en)abled)\??$/ do |service|
        {type: :get_thing, action: 'switch', thing: service.gsub(/ /,'_')}
      end      

      # e.g. is the gas_fire on?
      #
      get /is the ([^ ]+) +(?:on|off)\??$/ do |device|
        location = find_path(device)        
        {type: :get_thing, action: 'switch', location: location, thing: device}
      end            
      
      # e.g. fetch the livingroom temperature reading
      #
      get /fetch the ([^ ]+) +([^ ]+) +(?:reading)$/ do |location, device|
        {type: :get_thing, action: 'reading', location: location, thing: device}
      end

      # e.g. fetch the temperature reading
      #
      get /fetch the ([^ ]+) +(?:reading)$/ do |device|
        location = find_path(device)        
        {type: :get_thing, action: 'reading', location: location, thing: device}
      end          

    end
    
    private
    
    def find_path(s)
      puts 'find_path s: ' + s.inspect if @debug
      found = query('//'+ s)
      return unless found
      a = found.backtrack.to_xpath.split('/')
      a[1..-2].join(' ')            
    end
        
    alias find_request run_route    

  end
end
