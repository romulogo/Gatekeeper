require 'droplet_kit'
require 'json'
require "net/http"
require 'open-uri'

class DOGatekeeper
    def initialize(token, firewall_name, ports) 
        @client = DropletKit::Client.new(access_token: token) 
        @firewall_name = firewall_name
        @ports = ports

        @ports.each do |port| 
            if port == "0"
                @ports = ["0"]
            end
        end
    end

    def firewall
        @client.firewalls.all.find do |i| 
            i.name == @firewall_name
        end
    end

    def new_ips
        remote_ip = Net::HTTP.get(URI("https://api.ipify.org"))
        return [remote_ip]
    end
    
    def old_ips
        json_string = File.read('../immutable/ip.json')
        return JSON.parse(json_string)
    end

    def old_ports

        old_ports = firewall.inbound_rules.select do |i| 
            i.sources == {"addresses"=>old_ips}
        end

        return old_ports.uniq
    end

    def health_check

        begin
            @client.account.info()
        rescue DropletKit::Error => e
            puts "Gatekeeper: error invalid_access_token"
            return false
        end
        
        puts "Gatekeeper: confirmed_access_token"

        if firewall.nil? 
            puts "Gatekeeper: error no_firewall_named_#{@firewall_name}"
            return false
        end
        
        true
    end

    def create_rule (ips, prot, port)
        rule = DropletKit::FirewallInboundRule.new(
            protocol: prot,
            ports: port,
            sources: {
                addresses: ips
            }
        )
    end

    def remove_old_ip(prot, port)
 
        print "Gatekeeper: removing_old_ip_#{prot}_#{port}"
        rule = create_rule(old_ips, prot, port)
        @client.firewalls.remove_rules(inbound_rules: [rule], id: firewall.id)
        puts " - OK"

    end

    def add_new_ip(prot, port)
 
        print "Gatekeeper: adding_new_ip_#{prot}_#{port}"
        rule = create_rule(new_ips, prot, port)
        @client.firewalls.add_rules(inbound_rules: [rule], id: firewall.id)
        puts " - OK"

    end

    def set_new_rule

        protocol = ["tcp","udp"]

        protocol.each do |prot|
            if old_ips != [""]
                old_ports.each do |sources|
                    if sources.ports == "0"
                        sources.ports = "all"
                    end
                
                    remove_old_ip(prot, sources.ports)

                end

            end
        end

        protocol.each do |prot|
            @ports.each do |port|

                if port == "0"
                    port = "all"
                end

                add_new_ip(prot, port)

            end
        end

        File.open("../immutable/ip.json", "w") do |f|
            f.write(new_ips.to_json)
        end
    end

    def confirm_and_update_the_rules

        same_port = true

        if old_ips == new_ips

            old_ports.each do |sources|
                @ports.each do |port|
                    if sources.ports != port
                        same_port = false
                    end
                end
            end

            if same_port
                puts "Gatekeeper: your_ip_already_up"
            else
                set_new_rule
            end    

        else

            set_new_rule

        end

    end

    def update_the_rules

        if old_ips == new_ips
            puts "Gatekeeper: your_ip_already_up"    
        else
            set_new_rule
        end

    end

end
