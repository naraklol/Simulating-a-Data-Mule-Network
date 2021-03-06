clear variables;
clear globals;

global time;
global DT;
global cur_protocol;

% timescale variables
protocols = ["bluetooth", "zigbee", "rf", "wifi"];
packet_size = 120;
rover_energy = [];
re_boxplot = [];
tt_boxplot = [];
sensor_energy = [];
se_boxplot = [];
tt = [];
transaction_sensor_energy = [];
tse_boxplot = [];

runs = [];
runs_boxplot = [];
stationary_time = [];
st_boxplot = [];
transaction_stationary_time = [];
tst_boxplot = [];
transactions_post_battery_depletion = [];
tpbd_boxplot = [];

for cur_protocol = 1:length(protocols) 
    clearvars -except cur_protocol cur_packet_size protocols packet_size rover_energy re_boxplot tt tt_boxplot sensor_energy se_boxplot transaction_sensor_energy tse_boxplot runs runs_boxplot stationary_time st_boxplot transaction_stationary_time tst_boxplot transactions_post_battery_depletion tpbd_boxplot
    global time;
    global DT;
    global cur_protocol;
    dT = 0.05; DT = 0.5; T = 120;
    time = DT;
    trials = 50;
    protocol = protocols(cur_protocol);
    
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
                    tt_boxplot_temp = cell(1, length(rover.transaction_array(t).transaction_time));
                    tt_boxplot_temp(:) = {protocol};
                    tt_boxplot = [tt_boxplot, tt_boxplot_temp];
                    
                    transaction_sensor_energy = [transaction_sensor_energy sensornode_array(1).calcaulate_energy_usage_transaction(rover.transaction_array(t).transaction_time)];
                    tse_boxplot_temp = cell(1);
                    tse_boxplot_temp(:) = {protocol};
                    tse_boxplot = [tse_boxplot, tse_boxplot_temp];
                end
            end
            stationary_time = [stationary_time rover.stationary_time];
            st_boxplot_temp = cell(1, length(rover.stationary_time));
            st_boxplot_temp(:) = {protocol};
            st_boxplot = [st_boxplot, st_boxplot_temp];
            if ~rover.battery_depleted
                rover.reset();
            end
            fprintf("Running simulation %d.%d/%d\n", trial, run_count, trials);
        end
        rover_energy = [rover_energy rover.energy_used];
        protocol_boxplot_temp = cell(1, length(rover.energy_used));
        protocol_boxplot_temp(:) = {protocol};
        re_boxplot = [re_boxplot, protocol_boxplot_temp];
        sensor_energy_temp = [];
        for sensornode = 1:length(sensornode_array)
            sensor_energy_temp = [sensor_energy_temp sensornode_array(sensornode).energy_used];
        end
        sensor_energy = [sensor_energy sensor_energy_temp];
        se_boxplot_temp = cell(1, length(sensor_energy_temp));
        se_boxplot_temp(:) = {protocol};
        se_boxplot = [se_boxplot, se_boxplot_temp];
        
        runs = [runs run_count];
        runs_boxplot_temp = cell(1);
        runs_boxplot_temp(:) = {protocol};
        runs_boxplot = [runs_boxplot, runs_boxplot_temp];
        
        transaction_stationary_time = [transaction_stationary_time rover.transaction_stationary_times];
        tst_boxplot_temp = cell(1, length(rover.transaction_stationary_times));
        tst_boxplot_temp(:) = {protocol};
        tst_boxplot = [tst_boxplot, tst_boxplot_temp];
        
        transactions_post_battery_depletion = [transactions_post_battery_depletion rover.transactions_post_battery_depletion];
        tpbd_boxplot_temp = cell(1, length(rover.transactions_post_battery_depletion));
        tpbd_boxplot_temp(:) = {protocol};
        tpbd_boxplot = [tpbd_boxplot, tpbd_boxplot_temp];
        
        delete(rover);
    end
    toc

    
end

% figure(1);
% boxplot(rover_energy, protocol_boxplot)
% figure(2);
%%
figure('Name',append('Rover Energy at ', num2str(packet_size)))
boxplot(rover_energy, re_boxplot);
xlabel('Protocol'); ylabel('Energy (J)');
path = 'C:\Users\Neil Arakkal\Desktop\Rover\boxplots\120';
saveas(gcf, fullfile(path, '1'), 'png');

figure('Name',append('Transaction times at ', num2str(packet_size)))
boxplot(tt, tt_boxplot);
xlabel('Protocol'); ylabel('Time (s)');
saveas(gcf, fullfile(path, '2'), 'png');

figure('Name',append('Sensor energy at ', num2str(packet_size)))
boxplot(transaction_sensor_energy, tse_boxplot);
xlabel('Protocol'); ylabel('Energy (J)');
saveas(gcf, fullfile(path, '3'), 'png');

figure('Name',append('Number of runs at ', num2str(packet_size)))
boxplot(runs, runs_boxplot);
xlabel('Protocol'); ylabel('Number of runs');
saveas(gcf, fullfile(path, '4'), 'png');

figure('Name',append('Stationary time per run at ', num2str(packet_size)))
boxplot(stationary_time, st_boxplot);
xlabel('Protocol'); ylabel('Time (s)');
saveas(gcf, fullfile(path, '5'), 'png');

figure('Name',append('Stationary time per transaction at ', num2str(packet_size)))
boxplot(transaction_stationary_time, tst_boxplot);
xlabel('Protocol'); ylabel('Time (s)');
saveas(gcf, fullfile(path, '6'), 'png');

figure('Name',append('Transactions post battery depletion at ', num2str(packet_size)))
boxplot(transactions_post_battery_depletion, tpbd_boxplot);
xlabel('Protocol'); ylabel('Time (s)');
saveas(gcf, fullfile(path, '7'), 'png');

close all

