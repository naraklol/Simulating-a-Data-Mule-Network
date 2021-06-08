classdef Transaction < handle
    
    properties
        sensor_node
        protocol
        connection_time, disconnect_time
        transmission_rate
        packet_size
        stationary_time
        start_time, end_time, transaction_time, started, ended
    end
    
    methods
        function obj = Transaction(protocol, sensor_node, packet_size)
            % Constructor for Transaction class
            % Creates a new transaction object based on the protocol 
            % specified and sets default parameters
            obj.started = false; obj.ended = false;
            obj.packet_size = packet_size; obj.sensor_node = sensor_node;
            obj.protocol = protocol;
            if lower(protocol) == "wifi"
                obj.connection_time = 4.36;
                obj.transmission_rate = 147.1;
                obj.disconnect_time = 0.05;
            elseif lower(protocol) == "bluetooth"
                obj.connection_time = 5.25;
                obj.transmission_rate = 73.5;
                obj.disconnect_time = 0.41;
            elseif lower(protocol) == "rf"
                obj.connection_time = 1.48;
                obj.transmission_rate = 8.81;
                obj.disconnect_time = 0;
            elseif lower(protocol) == "zigbee"
                obj.connection_time = 0.169;
                obj.transmission_rate = 3.2;
                obj.disconnect_time = 0.799;
            else
                fprintf("Undefined protocol\n");
            end
        end
        
        function transaction_time = calculate_transaction_time(obj, packet_size)
            % Calculates the total transaction time for a given packet size
            transmission_time = packet_size / obj.transmission_rate;
            transaction_time = obj.connection_time + transmission_time + obj.disconnect_time;
            obj.packet_size = packet_size;
        end
        
        function transaction_time = calculate_transaction_time_hist(obj, packet_size)
            % Calculate transaction time based on histogram data 
            tp = TransactionProbability();
            pd = tp.return_transaction_probability(obj.protocol, packet_size);
            starting_index = pd(1,1);
            increment = pd(2,1) - starting_index;
            cd = cumsum(pd(:,2)); % convert probabilities into a cumulative distribution
            
            random_number = rand; % generate random numbers
            p = @(r) (find(r<cd,1,'first') * increment) + (starting_index - increment); % find first index where r<cd(i)
            transaction_time = arrayfun(p,random_number); % apply function r to all the random numbers
            obj.packet_size = packet_size;
        end
        
        function obj = start_transaction(obj)
            global time;
            if (~obj.started) && (~obj.ended)
                obj.started = true; obj.start_time = time;
                obj.end_time = obj.start_time + obj.calculate_transaction_time_hist(obj.packet_size);
            end
        end
        
        function tf = check_transaction_end(obj)
            global time;
            if obj.started && time >= obj.end_time
                obj.ended = true; tf = true;
            else
                tf = false;
            end
        end
        
        function tt = report_transaction_time(obj)
            if obj.started && obj.ended
                tt = obj.end_time - obj.start_time;
                obj.transaction_time = tt;
            else
                tt = NaN;
                obj.transaction_time = NaN;
            end
        end
    end
end

