require 'json'

class Gatekeeper
  
  attr_accessor :time, :firewall_type, :loop_var,
  :ports, :acess_key, :firewall_name

  def initialize 
      @time = 1
      @firewall_type = ENV['firewall_type']
      @loop_var = ENV['loop_var'].to_i
      @ports = ENV['ports'].split(",")
      @acess_key = ENV['acess_key']
      @firewall_name = ENV['firewall_name']

      if @loop_var <= 0
        @loop_var = 0
      else
        @loop_var= @loop_var * 60
      end

      @ports.each do |port| 
        if port != "0" && port < "8000" || port > "9000"
          puts "Gatekeeper: error invalid_ports"
          exit 1
        end
      end

  end

  def run
    print "Gatekeeper: run #{@time} time"
    if @time == 1
      puts "."
    else
      puts "s."
    end
    
    if @loop_var == 0
      exit 1
    else
      sleep @loop_var
    end
    
    @time += 1
  end

end