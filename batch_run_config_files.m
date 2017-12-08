%{ 
 TODO:
1. Support other types of outputs and find elegant way to implement feature
2. Test
3. Find best way to represent data
4. Make sure it's okay to use ScenarioContainer instead of Scenario


Currently supported types of outputs:
output = 
'travel_time'
%}


% normal params: run_times = 100, sampling_interval = 60 seconds,
% duration = 3600 seconds
% outputs struct, which includes 3D matrix
function [] = batch_run_config_files(directory, run_times, sampling_interval, duration, output)

    xml_files = directory(arrayfun(@(z) ~isempty(strfind(z.name,'.xml')), directory));

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
