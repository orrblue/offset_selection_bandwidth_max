function [] = gen_random_offsets(config_file, cycle_time)

    here = fileparts(mfilename('fullpath'));
    config_file = fullfile(here, config_file);

    xml = ScenarioContainer(configfile);
    controller_ids = arrayfun(@(z) z.ATTRIBUTE.id , xml.scenario.scenario.controllers.controller);
    path_ids = arrayfun(@(z) z.ATTRIBUTE.id , xml.scenario.scenario.subnetworks.subnetwork);
    
    
   % set all weights to 1
    weights = ones(1, numel(path_ids));

%     for i = 1:n_paths
%         weights(i) = 1;
%     end

    rng('shuffle')
    r = randi([0 cycle_time],1,numel(controller_ids));
    
    
    

end
