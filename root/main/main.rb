require './digital_ocean/do_gatekeeper.rb'
require './google_cloud/gc_gatekeeper.rb'
require './main/gatekeeper.rb'
$stdout.sync = true

gk = Gatekeeper.new

case gk.firewall_type
  
when 'DO'
  puts "Gatekeeper: init config Digital Ocean firewall"
  do_gatekeeper = DOGatekeeper.new(gk.acess_key, gk.firewall_name, gk.ports)
  
  exit 1 unless do_gatekeeper.health_check

  loop do

    if gk.time == 1
    
      do_gatekeeper.confirm_and_update_the_rules

    else

    do_gatekeeper.update_the_rules

    end

    gk.run

  end

when 'GC'
  puts "Gatekeeper: init config Google Cloud firewall"
  gc_gatekeeper = GCGatekeeper.new(gk.acess_key, gk.firewall_name, gk.ports)
  
  exit 1 unless gc_gatekeeper.health_check

  loop do

    if gk.time == 1
    
      gc_gatekeeper.confirm_and_update_the_rules

    else

      gc_gatekeeper.update_the_rules

    end

    gk.run

  end

else
  puts "Gatekeeper: error invalid_firewall_type"
end