%{
 gen_random_offsets.m

 Creates random offsets for a configuration file and saves new configuration file at current directory 
 
 INPUTS:
 config_file - name of config_file (in current directory) to be used
 cycle_time - cycle time of signal so random offsets are crated in [0, cycle_time - 1]
 save_name - name for newly saved config file

 OUTPUT:
 None

%}





%{
 Possible bug: 
 if target_actuator in xml has more than one id, this might not work

%}

function [] = gen_random_offsets(config_file, cycle_time, save_name)

    here = fileparts(mfilename('fullpath'));
    config_file = fullfile(here, config_file);

    xml = ScenarioContainer(config_file);
    controller_ids = arrayfun(@(z) z.ATTRIBUTE.id , xml.scenario.scenario.controllers.controller)
    node_ids = arrayfun(@(z) z.target_actuators.ATTRIBUTE.ids , xml.scenario.scenario.controllers.controller)

    % generate enough offsets for each target_actuator
    rng('shuffle');
    offsets = randi([0 cycle_time-1], 1, numel(node_ids));
    
    i = 1;
    for node_id = node_ids
        offset = offsets(i);
        i = i + 1;
        
        % check node_id matches and set offset on node_id
        cid = X.scenario.get_controllerid_for_nodeid(node_id);
        cind = cid==controller_ids;
        if sum(cind) ~= 1
            error('sum(cind)~=1')
        end
        X.scenario.scenario.controllers.controller(cind).schedule.schedule_item.ATTRIBUTE.offset = offset;
    end
    
    X.scenario.save(fullfile(here,save_name));
end

