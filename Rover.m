classdef Rover < handle
    
    properties
        pos, wheelbase, len     % rover properties
        gamma_max, gamma_min    % turning radius
        v, v_max, v_min         % velocity properties
        moving                  % rover moving status
        stop_threshold          % point at which rover stops to complete treansaction
        stationary_time
        
        in_range_of_sensornode  % sensor node currently in range (0 if none)
        rover_handle            % handle for shape of rover
        heading                 % position of heading triangle
        rover_heading_handle    % handle for heading of rover
        protocol
        packet_size
        transaction, transaction_complete
        transaction_array
        transaction_stationary_time
        transaction_stationary_times
        stop_counter
        
        sensornode_array
        sensors_passed, sensors_count;
        power_stationary, power_moving, power_transaction
        energy_used           % total energy consumed
        battery;
        battery_depleted;
        transactions_post_battery_depletion;
    end
    
    methods
        
        function obj = Rover(x, y, theta, protocol, packet_size, sensornode_array)
            % Constructor for Rover class
            % Creates a new Rover object with a position and assigns default values
            obj.wheelbase = 1;
            obj.len = 1.5;
            obj.pos = [-obj.len/2        obj.len/2         obj.len/2        -obj.len/2; 
                       -obj.wheelbase/2  -obj.wheelbase/2  obj.wheelbase/2  obj.wheelbase/2; 
                       1                 1                 1                1];
            heading_size = 0.2; 
            obj.heading = [0 0 2*heading_size; heading_size -heading_size 0; 1 1 1];
            trnsl = transl2(-heading_size, 0);                                                  % translate the heading triangle to be in the centre of the rover
            obj.heading = trnsl * obj.heading;
            obj.gamma_max = pi/4; obj.gamma_min = -pi/4;
            obj.v_max = 1; obj.v_min = 0; obj.v = obj.v_max; 
            obj.moving = true;
            obj.stop_threshold = 0.90;
            obj.sensornode_array = sensornode_array;
            obj.stationary_time = 0;
            obj.transaction_stationary_time = 0;
            obj.transaction_stationary_times = [];
            obj.transactions_post_battery_depletion = 0;
            obj.stop_counter = 0;
            
            % Power properties
            obj.power_stationary = 0.5;
            obj.power_moving = 44.3;
            if lower(protocol) == "zigbee"
                obj.power_transaction = 0.172;
            elseif lower(protocol) == "rf"
                obj.power_transaction = 0.5;
            elseif lower(protocol) == "bluetooth"
                obj.power_transaction = 0.128;
            elseif lower(protocol) == "wifi"
                obj.power_transaction = 0.828;
            end
            obj.energy_used = 0;
            obj.battery = 520000; % 20,000maH 7.2V
            obj.battery_depleted = false;
            
            % Sensor properties
            obj.in_range_of_sensornode = 0;
            obj.sensors_passed = [];
            obj.sensors_count = 0;

            % Transaction properties
            obj.transaction_array = [];
            obj.protocol = protocol;
            obj.packet_size = packet_size;
            obj.transaction_complete = false;
            
            obj.move(x, y, theta);
        end
        
        function plot(obj)
            % Plots the current position of the rover
            % Changes the color of the heading triangle if the rover is
            % within range of a sensor node
            obj.rover_handle = plot_poly(obj.pos, 'fillcolor', 'b', 'edgecolor', 'black', 'alpha', 1, 'EdgeAlpha', 1);
            if (obj.in_range_of_sensornode > 0) && (~isempty(obj.transaction))
                if obj.transaction_complete()
                    obj.rover_heading_handle = plot_poly(obj.heading, 'fillcolor', 'g', 'edgecolor', 'g', 'alpha', 1, 'EdgeAlpha', 1);
                else
                    obj.rover_heading_handle = plot_poly(obj.heading, 'fillcolor', 'y', 'edgecolor', 'y', 'alpha', 1, 'EdgeAlpha', 1);
                end
            else
                obj.rover_heading_handle = plot_poly(obj.heading, 'fillcolor', 'r', 'edgecolor', 'r', 'alpha', 1, 'EdgeAlpha', 1);
            end
        end
        
        function obj = reset(obj)
            % Reset the position of the rover to (0,0,0) with angle 0 while
            % keeping track of all other parameters
            obj.pos = [-obj.len/2        obj.len/2         obj.len/2        -obj.len/2; 
                       -obj.wheelbase/2  -obj.wheelbase/2  obj.wheelbase/2  obj.wheelbase/2; 
                       1                 1                 1                1];
            heading_size = 0.2; 
            obj.heading = [0 0 2*heading_size; heading_size -heading_size 0; 1 1 1];
            trnsl = transl2(-heading_size, 0);                                                  % translate the heading triangle to be in the centre of the rover
            obj.heading = trnsl * obj.heading;
            obj.in_range_of_sensornode = 0;
            obj.sensors_passed = [];
            obj.sensors_count = 0;
            obj.transaction_array = [];
            obj.transaction_complete = false;
            obj.transaction = [];
            obj.stationary_time = 0;
            obj.transaction_stationary_time = 0;
            obj.transaction_stationary_times = [];
            obj.stop_counter = 0;
        end
        
        function obj = move(obj, x, y, theta)
            % Moves the rover by a certain value *relative to its current position*
            % Also handles updating the position on the axes
            global DT;
            if ~obj.out_of_range()
                trnsl = transl2(x, y);           % create translation matrix
                rotat = trot2(theta);            % create rotation matrix
                T = trnsl * rotat;               % create transformation matrix
                obj.pos = T * obj.pos;           % apply transformation matrix to current position of rover
                obj.heading = T * obj.heading;   % apply transformation matrix to heading triangle of rover
                obj.moving = true;
                if obj.transaction_stationary_time ~= 0 % transaction required rover to stop
                    obj.transaction_stationary_times = [obj.transaction_stationary_times obj.transaction_stationary_time];
                    obj.transaction_stationary_time = 0;
                end
            else
                obj.moving = false;
                obj.transaction_stationary_time = obj.transaction_stationary_time + DT; % increment stationary time for transaction
                obj.stationary_time = obj.stationary_time + DT; 
            end
            if (~isempty(obj.rover_handle)) || (~isempty(obj.rover_heading_handle))
                delete(obj.rover_handle);
                delete(obj.rover_heading_handle);
            end
            obj.calculate_energy_usage();
            obj.within_range();
        end
        
        function stop = out_of_range(obj)
            % Returns true if the rover needs to stop in order to complete
            % a transaction. Returns false otherwise
            global DT;
            stop = false;
            if (obj.in_range_of_sensornode == 0) || (isempty(obj.transaction)) % if not in range of a sensornode or no transaction in progress
            else
                rover_centre = [sum(obj.pos(1,1:4))/4 sum(obj.pos(2,1:4))/4];
                sensornode = obj.sensornode_array(obj.transaction.sensor_node);
                dist_to_sensor = pdist([rover_centre; sensornode.pos]);       
                if (~obj.transaction_complete) && (dist_to_sensor > sensornode.radius * obj.stop_threshold)
                    stop = true;
                end
            end
        end
        
        function calculate_energy_usage(obj)
            global DT;
            energy = obj.power_stationary * DT;
            if obj.moving
                energy = energy + obj.power_moving * DT;
            end
            obj.energy_used = obj.energy_used + energy;
            obj.battery = obj.battery - energy;
            if obj.battery < 0
                obj.battery_depleted = true;
            end
            if (~isempty(obj.transaction)) && (~obj.transaction_complete)
                obj.energy_used = obj.energy_used + obj.power_transaction * DT;
            end
        end
        
        function obj = within_range(obj)
            % Detect whether the rover is in range of a sensor node and
            % controls the transaction with the nearest sensor node
            rover_centre = [sum(obj.pos(1,1:4))/4 sum(obj.pos(2,1:4))/4];
            prev_sensornode = obj.in_range_of_sensornode;
            obj.in_range_of_sensornode = 0;
            prev_transaction_complete = obj.transaction_complete;
            for i = 1:length(obj.sensornode_array)
                dist_to_sensor = pdist([rover_centre; obj.sensornode_array(i).pos]);
                if (dist_to_sensor <= obj.sensornode_array(i).radius)
                    obj.in_range_of_sensornode = i;
                    
                    % if transaction with smallest index node is complete,
                    % check the next nearest node
                    if ~isempty(obj.transaction_array) 
                        complete = false;
                        for t = 1:length(obj.transaction_array)
                            if obj.transaction_array(t).sensor_node == obj.in_range_of_sensornode
                                complete = true;
                            end
                        end
                        if complete
                            continue;
                        end
                    end
                    
                    % if the current node is not present in the list of
                    % nodes passed, add it to sensornode_array
                    for node = 1:length(obj.sensornode_array)
                        if obj.in_range_of_sensornode == obj.sensornode_array(i).index && ~ismember(obj.in_range_of_sensornode, obj.sensors_passed)
                        	obj.sensors_passed = [obj.sensors_passed, obj.in_range_of_sensornode];
                            obj.sensors_count = obj.sensors_count + 1;
                        end
                    end
                    break;
                
                end
                
            end
            
            % start new transaction if within presence of a sensor node
            if (obj.in_range_of_sensornode > 0) && (isempty(obj.transaction))
%                 if ~isempty(obj.transaction_array) 
%                         for t = 1:length(obj.transaction_array)
%                             if obj.transaction_array(t).sensor_node == obj.in_range_of_sensornode
%                             end
%                         end
%                 end
                obj.sensornode_array(obj.in_range_of_sensornode).start_transaction();
                obj.transaction = Transaction(obj.protocol, obj.in_range_of_sensornode, obj.packet_size);
                obj.transaction.start_transaction();
                if obj.battery_depleted
                    obj.transactions_post_battery_depletion = obj.transactions_post_battery_depletion + 1;
                end
            end
            
            if (prev_sensornode > 0)                                                                                                % if rover was within range in previous iteration
                obj.transaction_complete = obj.transaction.check_transaction_end();                                                 % check for transaction complete
                if (prev_sensornode ~= obj.in_range_of_sensornode) && (obj.transaction_complete) && obj.in_range_of_sensornode == 0
                    obj.transaction = [];                                                                                           % delete transaction since complete
                    obj.transaction_array = [obj.transaction_array obj.transaction];
                    obj.sensornode_array(prev_sensornode).end_transaction();
                elseif (obj.transaction_complete) && ~prev_transaction_complete      % check for completed transaction within range of sensor node
                    obj.transaction.report_transaction_time();
%                                         fprintf("Transaction with sensor node %d complete in %f seconds\n", obj.in_range_of_sensornode, x);     
                    obj.transaction_array = [obj.transaction_array obj.transaction];
                    obj.sensornode_array(obj.in_range_of_sensornode).end_transaction();
                elseif (prev_sensornode ~= obj.in_range_of_sensornode) && (~isempty(obj.transaction))                               % check if out of range with current sensor node 
%                     fprintf("Transaction with sensor node %d incomplete\n", obj.in_range_of_sensornode);
                    obj.transaction = [];                                                                                           % delete transaction since incomplete
                    obj.transaction_array = [obj.transaction_array obj.transaction];
                    obj.sensornode_array(obj.in_range_of_sensornode).end_transaction();
                end
            end          
        end
        
        
    end
end

