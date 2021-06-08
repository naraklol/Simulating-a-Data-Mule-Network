function m = metrics(rover, sensornode_array)
    global time;
    
    dist = time * rover.v;
    transactions_completed = 0;
    
    for i = 1:length(rover.transaction_array)
        if rover.transaction_array(i).ended
            transactions_completed = transactions_completed + 1;
        end
    end
    
    m = "\n*******\n";
    m = m + "METRICS\n";
    m = m + "*******\n\n";
    m = m + "Simulation time: " + num2str(time) + "\n";
    m = m + "Distance travelled: " + num2str(dist) + "\n";
    m = m + "Protocol used: " + rover.protocol + "\n";
    m = m + "Packet size: " + rover.packet_size + "kB\n";
    m = m + "\n";
    
    m = m + "Vehicle Metrics\n";
    m = m + "---------------\n\n";
    m = m + "Number of sensors passed: " + num2str(rover.sensors_count) + "\n";
    m = m + "Successful transactions: " + num2str(transactions_completed) + "\n";
    m = m + "Sensors passed: [";
    for i = 1:length(rover.sensors_passed)
        m = m + " " + num2str(i);
    end
    m = m + "]\n";
    m = m + "\n";

    m = m + "Transaction Metrics\n";
    m = m + "-------------------\n\n";
    for i = 1:length(rover.transaction_array)
        m = m + "Sensor number: " + num2str(rover.transaction_array(i).sensor_node) + "\n";
        m = m + "Transaction completed: " + num2str(rover.transaction_array(i).ended) + "\n";
        m = m + "Transaction start: " + num2str(rover.transaction_array(i).start_time) + "\n";
        if rover.transaction_array(i).ended
            m = m + "Transaction time: " + num2str(rover.transaction_array(i).transaction_time) + "\n";
            m = m + "Transaction end: " + num2str(rover.transaction_array(i).end_time) + "\n";
        else
            m = m + "Transaction time: NaN\n";
            m = m + "Transaction end: NaN\n";
        end
    end
    m = m + "\n";
    
    m = m + "Power Metrics\n";
    m = m + "-------------\n\n";
    m = m + "Vehicle stationary power: " + num2str(rover.power_stationary) + "W\n";
    m = m + "Vehicle moving power: " + num2str(rover.power_moving) + "W\n";
    m = m + "Vehicle transaction power: " + num2str(rover.power_transaction) + "W\n";
    m = m + "Sensor idle power: " + num2str(sensornode_array(1).power_idle) + "W\n";
    m = m + "Sensor transaction power: " + num2str(sensornode_array(1).power_transaction) + "W\n"; 
    m = m + "Total vehicle energy used: " + num2str(rover.energy_used) + "J\n";
    for i = 1:length(sensornode_array)
        m = m + "Sensor " + num2str(i) + " energy used: " + num2str(sensornode_array(i).energy_used) + "J\n";
    end
    
    
end