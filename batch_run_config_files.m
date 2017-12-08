% normal params: run_times = 100, sampling_interval = 60 seconds,
% duration = 3600 seconds
function [] = batch_run_config_files(directory, run_times, sampling_interval, duration)

    xml_files = directory(arrayfun(@(z) ~isempty(strfind(z.name,'.xml')), directory));


end
