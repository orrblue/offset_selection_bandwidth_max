%{
 batch_run_config_files.m

 Runs all configuration files in the given directory and returns the specified result outputs 
 
 INPUTS:
 directory_name - location of files to be run
 run_times - number of times to run each file
 sampling_interval - how often to record measurements (seconds)
 duration - length of simulation (seconds)
 output - type of data to output
    Currently supports: 'travel_time'

 OUTPUT:
 struct with info about experiment and includes 3D matrix of results

%}




%{ 
 TODO:
0. Test directory input, might not be working yet
1. Support other types of outputs and find elegant way to implement feature
2. Test function
3. Find best way to represent output data
4. Make sure it's okay to use ScenarioContainer instead of Scenario
%}



function [] = batch_run_config_files(directory_name, run_times, sampling_interval, duration, output)

    % find all .xml config files in given directory
    files = dir directory_name
    xml_files = files(arrayfun(@(z) ~isempty(strfind(z.name,'.xml')), files));

    for counter = 1:numel(xml_files)
        get_results(xml_files(counter).name, run_times, sampling_interval, duration, output);
    end 

end



function output_matrix = get_results(file_name, run_times, sampling_interval, duration, output)
    
    
    here = fileparts(mfilename('fullpath'));
    config_file = fullfile(here, file_name);

    xml = ScenarioContainer(config_file);
    num_subnetworks = numel(xml.scenario.subnetworks.subnetwork);
    subs_ids = arrayfun(@(z) z.ATTRIBUTE.id, xml.scenario.subnetworks.subnetwork);
    
    % output matrix of num subnets x num samples x num runs
    output_matrix = zeros(num_subnetworks, (duration/sampling_interval), run_times);
    beats = BeATSWrapper(config_file);
    
    for counter = 1:num_subnetworks
            if output == 'travel_time'
                beats.api.request_path_travel_time(subs_ids(counter), sampling_interval)
            end
    end
    
    for run_counter = 1:run_times

        beats.run_simple(0, duration)
        output_data = beats.api.get_output_data();
        data_iter = output_data.iterator;

        for counter = 1:num_subnetworks
            data = data_iter.next();
            for time = sampling_interval : sampling_interval : duration %begin time after one output frequency has passed
                if output == 'travel_time'
                    output_matrix(counter, (time/sampling_interval), run_counter) = data.compute_travel_time_for_start_time(time);
                end
            end
        end
    end
    
    
    result.output_matrix = output_matrix;
    result.file_name = file_name;
    result.runs = run_times;
    result.sampling_interval = sampling_interval;
    result.duration = duration;
    result.subnetwork_ids = subs_ids;
    
    
    [~,name]=fileparts(file_name);
    save([name, '_result'],'result');


end
