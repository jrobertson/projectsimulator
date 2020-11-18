#!/usr/bin/env ruby

# file: projectsimulator.rb


require 'easydom'
require 'unichron'
require 'app-routes'


module ProjectSimulator

  class Server
    
    def initialize(macros_package, drb_host: '127.0.0.1', devices: nil, 
                   debug: false)
      
      rdc = ProjectSimulator::Controller.new(macros_package, devices: devices, 
                                        debug: debug)
      @drb = OneDrb::Server.new host: drb_host, port: '5777', obj: rdc
      
    end
    
    def start
      @drb.start
    end

  end
  
  
end


require 'projectsimulator/model'
require 'projectsimulator/controller'
require 'projectsimulator/client'
