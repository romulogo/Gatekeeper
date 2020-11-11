require 'googleauth'
require 'google/apis/compute_v1'
require 'json'

class GCGatekeeper
    def initialize(acess_key, firewall_name, ports) 

        @client =  Google::Apis::ComputeV1::ComputeService.new
        @ports = ports
        @acess_key = acess_key
        @firewall_name = firewall_name

        @ports.each do |port| 
            if port == "0"
                @ports = nil
            end
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

    def health_check

        begin
            @client.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
                json_key_io: File.open('../immutable/gc_authentication.json'),
                scope: 'https://www.googleapis.com/auth/compute')
        rescue 
            puts "Gatekeeper: error invalid_gc_authentication_json"
            return false
        end

        puts "Gatekeeper: confirmed_gc_authentication_json"


        begin
            @client.fetch_all do |token|
                @client.list_firewalls(@acess_key, page_token: token)
            end
        rescue 
            puts "Gatekeeper: error invalid_project_id"
            return false
        end

        puts "Gatekeeper: confirmed_project_id"

        if old_ips == [""]
            
            firewalls = @client.fetch_all do |token|
                @client.list_firewalls(@acess_key, page_token: token)
            end
            
            firewalls.each do |firewall|

                if firewall.name == @firewall_name
                    puts "Gatekeeper: error this_firewall_name_already_exists"
                    return false
                end

            end

        else

            letters = @firewall_name.split(//)

            letters = ['X'] if letters[letters.length - 1] == '-'

            letters.each do |x|

                unless x >= 'a' && x <= 'z' || x == '-' || x >= '0' && x <= '9' 
                    puts "Gatekeeper: error invalid_firewall_name"
                    puts "The firewall name can only contain lowercase letters, numbers, or hyphens, and cannot end with a hyphen."
                    return false
                end

            end

        end

        puts "Gatekeeper: confirmed_firewall_name"

        true
    end

    def diferent_ports

        firewalls = @client.fetch_all do |token|
            @client.list_firewalls(@acess_key, page_token: token)
        end
        
        firewalls.each do |firewall|
            if firewall.allowed[0].ports != @port
                return true
            end
        end

        return false
    end

    def request_body (ips)
        Google::Apis::ComputeV1::Firewall.new(
            kind: "compute#firewall",
            name: @firewall_name,
            self_link: "projects/#{@acess_key}/global/firewalls/#{@firewall_name}",
            network: "projects/#{@acess_key}/global/networks/default",
            direction: "INGRESS",
            priority: 1000,
            description: "This rule was created automatically by Gatekeeper.",
            allowed: [
            ],
            source_ranges: ips
            )
    end

    def remove_old_rule
        
        begin
            @client.delete_firewall(@acess_key, @firewall_name)
            print "Gatekeeper: removing_old_rule"
            sleep 10
            puts " - OK"
        rescue
        end

    end

    def set_new_rule

        remove_old_rule

        request_body = request_body (new_ips)

        print "Gatekeeper: adding_new_ip_tcp_udp_"

        if @ports == nil
            print "all_ports"
        else
            print "#{@ports}_ports"
        end

        if @ports == nil
            request_body.allowed[0] = {ip_protocol: "tcp"}
            request_body.allowed[1] = {ip_protocol: "udp"}
        else
            request_body.allowed[0] = {ip_protocol: "tcp", ports: @ports}
            request_body.allowed[1] = {ip_protocol: "udp", ports: @ports}
        end

        @client.insert_firewall(@acess_key, request_body)

        File.open("../immutable/ip.json", "w") do |f|
            f.write(new_ips.to_json)
        end

        puts " - OK"

    end

    def confirm_and_update_the_rules

        if old_ips == new_ips

            if diferent_ports
                set_new_rule
            else
                puts "Gatekeeper: your_ip_already_up"
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