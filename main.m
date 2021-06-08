figure(1); clf; hold on; axis equal;
clear variables;
clear globals;

% timescale variables
global time;
global DT;

dT = 0.001; DT = 0.01; T = 120;
time = DT;

protocol = "zigbee";
packet_size = 5;

% create an array of sensors (in a straight line)
sensornode_array = [];
for x = 1:1:3
%     sensornode = SensorNode([((x-1)*30)/2 + 10 1], x, protocol);
    sensornode = SensorNode([((x-1)*30*3)/4 + 10 1], x, protocol);
    sensornode.plot();
    sensornode_array = [sensornode_array sensornode]; %#ok<AGROW>
end

tt = [];

% initialize a new rover object
rover = Rover(0, 0, 0, protocol, packet_size, sensornode_array);
% run simulation
time = DT;
for sim_time = DT:DT:T
    rover.move(rover.v * DT, 0, 0);
%     rover.within_range(sensornode_array);
    rover.plot();
    for sensor = 1:length(sensornode_array)
        sensornode_array(sensor).calculate_energy_usage()
    end
    
    if ~rover.moving
        sime_time = sim_time - DT;
    end
    
    time = time + DT;
%     pause(DT/1000);
end

m = metrics(rover, sensornode_array);
fprintf(m);
fid = fopen("metrics.txt" ,'wt+');
fprintf(fid, m);
fclose(fid);
fprintf("%d - stat", rover.stationary_time);
