classdef SensorNode < handle
    
    properties
        index
        pos, size, radius
        sensornode_handle
        sensornode_radius_handle
        protocol
        power_idle
        power_transaction
        transaction_active;
        energy_used
    end
    
    methods
        function obj = SensorNode(pos, index, protocol)
            % Constructor for SensorNode class
            % Creates a new SensorNode object with a position and assigns default values
            % Also plots the newly created sensor node
            obj.pos = pos; obj.size = 0.1; obj.radius = 15; obj.index = index;
            obj.power_idle = 4.7E-7; %470nW
            obj.energy_used = 0;
            if lower(protocol) == "zigbee"
                obj.power_transaction = 0.172;
            elseif lower(protocol) == "rf"
                obj.power_transaction = 0.5;
            elseif lower(protocol) == "bluetooth"
                obj.power_transaction = 0.128;
            elseif lower(protocol) == "wifi"
                obj.power_transaction = 0.828;
            end
        end
        
        function plot(obj)
            % Plots the sensor node
            obj.sensornode_handle = plot_circle(obj.pos, obj.size, 'fillcolor', 'black', 'edgecolor', 'black', 'alpha', 1, 'EdgeAlpha', 1);
            obj.sensornode_radius_handle = plot_circle(obj.pos, obj.radius, 'fillcolor', 'g', 'edgecolor', 'g', 'alpha', 0, 'EdgeAlpha', 1);
        end
        
        function start_transaction(obj)
            obj.transaction_active = true;
        end
        
        function end_transaction(obj)
            obj.transaction_active = false;
        end
        
        function calculate_energy_usage(obj)
            global DT;
            obj.energy_used = obj.energy_used + obj.power_idle * DT;
            if obj.transaction_active
                obj.energy_used =  obj.energy_used + obj.power_transaction * DT;
            end
        end
        
        function e = calcaulate_energy_usage_transaction(obj, tt)
            e = obj.power_transaction * tt;
        end
        
    end
end

