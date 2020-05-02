#!/usr/bin/env ruby

# file: projectsimulator.rb

require 'easydom'
require 'app-routes'


module ProjectSimulator

  class Model
    include AppRoutes

    def initialize()

      super() 

    end

    def build(raw_requests, root: 'building1')

      @ed = EasyDom.new(debug: false, root: root)
      raw_requests.lines.each {|line| request(line) }

    end

    def op()
      @ed
    end

    def query(s)
      @ed.e.element(s)
    end

    def to_sliml()
      @ed.to_sliml
    end

    def xml(options=nil)
      @ed.xml(pretty: true).gsub(' style=\'\'','')
    end

    protected      

    def requests(params) 

      get /(?:switch|turn) the ([^ ]+) +([^ ]+) +(on|off)$/ do |location, device, onoff|
        {action: 'switch=', location: location, device: device, value: onoff}
      end

    end
    
    private
    
    def request(s)

      params = {request: s}
      requests(@params)
      h = find_request(s)

      a = h[:location].split(/ /)
      a << h[:device]
      a.inject(@ed) {|r,x| r.send(x)}.send(h[:action], h[:value])

    end      

    alias find_request run_route
    

  end
end
