clear variables;
clear globals;

% timescale variables
global time;
global DT;
global cur_protocol;
global cur_packet_size;

protocols = ["bluetooth", "zigbee", "rf", "wifi"];
packet_sizes = [1, 5, 10, 20, 30, 40, 50, 60, 100, 120, 160];

for cur_protocol = 1:length(protocols)
    for cur_packet_size = 1: length(packet_sizes)
        clearvars -except cur_protocol cur_packet_size protocols packet_sizes
        global time;
        global DT;
        global cur_protocol;
        global cur_packet_size;
        dT = 0.05; DT = 0.5; T = 120;
        time = DT;
        trials = 100;
        protocol = protocols(cur_protocol);
        packet_size = packet_sizes(cur_packet_size);
        tt = [];
        runs = [];
        rover_energy = [];
        sensor_energy = [];
        stationary_time = [];
        transaction_stationary_time = [];
        transaction_sensor_energy = [];
        transactions_post_battery_depletion = [];
        tic
        for trial = 1:trials
            % create an array of sensors (in a straight line)
            sensornode_array = [];
            for x = 1:1:3
            %     sensornode = SensorNode([((x-1)*30)/2 + 10 1], x, protocol);
                sensornode = SensorNode([((x-1)*30*3)/4 + 10 1], x, protocol);
                sensornode_array = [sensornode_array sensornode]; %#ok<AGROW>
            end

            % initialize a new rover object
            rover = Rover(0, 0, 0, protocol, packet_size, sensornode_array);
            rover.reset();
            run_count = 0;
            while ~rover.battery_depleted
                % run simulation
                time = DT;
                for sim_time = DT:DT:T
                    rover.move(rover.v * DT, 0, 0);
                %     rover.within_range(sensornode_array);
                    for sensor = 1:length(sensornode_array)
                        sensornode_array(sensor).calculate_energy_usage()
                    end

                    time = time + DT;

                end
                run_count = run_count + 1;
                for t = 1:length(rover.transaction_array)
                    if rover.transaction_array(t).ended
                        tt = [tt rover.transaction_array(t).transaction_time];
                        transaction_sensor_energy = [transaction_sensor_energy sensornode_array(1).calcaulate_energy_usage_transaction(rover.transaction_array(t).transaction_time)];
                    end
                end
                stationary_time = [stationary_time rover.stationary_time];
                if ~rover.battery_depleted
                    rover.reset();
                end
                fprintf("Running simulation %d.%d/%d\n", trial, run_count, trials);
            end
            rover_energy = [rover_energy rover.energy_used];
            for sensornode = 1:length(sensornode_array)
                sensor_energy = [sensor_energy sensornode_array(sensornode).energy_used];
            end
            runs = [runs run_count];
            transaction_stationary_time = [transaction_stationary_time rover.transaction_stationary_times];
            transactions_post_battery_depletion = [transactions_post_battery_depletion rover.transactions_post_battery_depletion];
            delete(rover);
        end
        toc

        graph_tt = figure('Name','Transaction times', 'NumberTitle','off', 'visible', 'off'); histogram(tt); xlabel('Transaction time (s)'); ylabel('Count');
        graph_sec = figure('Name','Sensor energy consumed', 'NumberTitle','off', 'visible', 'off'); histogram(sensor_energy); xlabel('Energy consumed (J)'); ylabel('Count');
        graph_rec = figure('Name','Rover energy consumed', 'NumberTitle','off', 'visible', 'off'); histogram(rover_energy); xlabel('Energy Consumed (J)'); ylabel('Count');
        graph_tcabd = figure('Name','Transactions completed after battery depleted', 'NumberTitle','off', 'visible', 'off'); histogram(transactions_post_battery_depletion); xlabel('Transactrions Completed'); ylabel('Count');
        graph_secpt = figure('Name','Sensor Energy consumed per transaction', 'NumberTitle','off', 'visible', 'off'); histogram(transaction_sensor_energy); xlabel('Energy Consumed (J)'); ylabel('Count');
        graph_nor = figure('Name','Number of runs', 'NumberTitle','off', 'visible', 'off'); histogram(runs); xlabel('Number of data mule runs per simulation iteration'); ylabel('Count');
        graph_tsspr = figure('Name','Time spent stationary per run', 'NumberTitle','off', 'visible', 'off'); histogram(stationary_time); xlabel('Time spent stationary (s)'); ylabel('Count');
        graph_tsspt = figure('Name','Time spent stationary per transaction', 'NumberTitle','off', 'visible', 'off'); histogram(transaction_stationary_time); xlabel('Time spent stationary (s)'); ylabel('Count');

        path = 'C:\Users\Neil Arakkal\Desktop\Rover\Graphs';
        path = append(path, "\", protocols(cur_protocol), " ", num2str(packet_sizes(cur_packet_size)), "kb");
        saveas(graph_tt, fullfile(path, 'transaction_times'), 'png');
        saveas(graph_sec, fullfile(path, 'sensor_energy_consumed'), 'png');
        saveas(graph_rec, fullfile(path, 'rover_energy_consumed'), 'png');
        saveas(graph_tcabd, fullfile(path, 'transaction_after_battery_depleted'), 'png');
        saveas(graph_secpt, fullfile(path, 'sensor_energy_consumed_per_transaction'), 'png');
        saveas(graph_nor, fullfile(path, 'runs'), 'png');
        saveas(graph_tsspr, fullfile(path, 'stationary_time_per_run'), 'png');
        saveas(graph_tsspt, fullfile(path, 'stationary_time_per_transaction'), 'png');
    end
end
