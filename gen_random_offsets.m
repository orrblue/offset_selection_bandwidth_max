%{
 gen_random_offsets.m

 Calculates randomized offsets for a specified configuration file and saves 
 new configuration file. New file is saved in a directory on the same level 
 as the original file. Directory is called 'randomized_config_files' and is
 created if not already present. 
 
 INPUTS:
 config_file - Absolute path to config file to be used
 cycle_time - the cycle time of the signal. Required so that random offsets 
    are created in [0, cycle_time - 1]

 OUTPUT:
 None

%}





%{
 Possible bug?: 
 If target_actuator in xml can have more than one target_actuator id, or 
 multiple schedule items (for different nodes?), then this might not work.
 If there are multiple schedule items, do they have different start times?

%}

function [] = gen_random_offsets(config_file, cycle_time)
    config_file = fullfile(config_file);    
    xml = ScenarioContainer(config_file);
    controller_ids = arrayfun(@(z) z.ATTRIBUTE.id, xml.scenario.scenario.controllers.controller);
    node_ids = arrayfun(@(z) z.target_actuators.ATTRIBUTE.ids, xml.scenario.scenario.controllers.controller);

    % generate enough offsets for each target_actuator
    rng('shuffle');
    offsets = randi([0 cycle_time-1], 1, numel(node_ids));
    
    i = 1;
    for node_id = node_ids
        offset = offsets(i);
        
        
        % check node_id matches and set offset on node_id
        cid = xml.scenario.get_controllerid_for_nodeid(node_id);
        cind = cid==controller_ids;
        if sum(cind) ~= 1
            error('sum(cind)~=1')
        end
        
        i = i + 1;
        xml.scenario.scenario.controllers.controller(cind).schedule.schedule_item.ATTRIBUTE.offset = offset;
    end
    
    [path, name]=fileparts(config_file);
    [~, ~] = mkdir(path, 'randomized_config_files');
    xml.scenario.save(fullfile(path, 'randomized_config_files', ['rand_', name]));
end

