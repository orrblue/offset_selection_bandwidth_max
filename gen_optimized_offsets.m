%{
 gen_optimized_offsets.m

 Calculates optimized offsets for a specified configuration file and saves 
 new configuration file. New file is saved in a directory on the same level 
 as the original file. Directory is called 'optimized_config_files' and is
 created if not already present.
 
 INPUTS:
 config_file - Absolute path to config file to be used
 path_ids - the ids of paths to optimize. If false or empty, all paths will
 be optimized.
 weights - the weights of each path. If false or empty, all paths will have
 same weight.

 OUTPUT:
 None

%}





%{
TODO:
1. Find Best way to pass null value in Matlab
2. Find what bs is in b_max_clean
3. Write error checks? 
4. figure out what's up with cid and cind
%}

function [] = gen_optimized_offsets(config_file, path_ids, weights)
    config_file = fullfile(config_file);
    xml = ScenarioContainer(config_file);
    
    % if no path_ids given, use all paths in file
    if isequal(path_ids, false) || isempty(path_ids)
        path_ids = arrayfun(@(z) z.ATTRIBUTE.id, xml.scenario.scenario.subnetworks.subnetwork);
    end
    
    % if no weights given, use weights = 1
    if isequal(weights, false) || isempty(weights)
        weights = ones(1, numel(path_ids));
        for i = 1: numel(path_ids)
            weights(i) = 1;
        end
    end
    
    [bs, offsets] = b_max_clean(config_file, path_ids, weights);

    % read offsets map, go into XML file and update all the offsets using the map
    for key = offsets.keys

        % list of controller_ids from config file
        controller_ids = arrayfun(@(z) z.ATTRIBUTE.id , xml.scenario.scenario.controllers.controller);

        node_id = key{1};
        offset = offsets(node_id);

        % check node_id matches and set offset on node_id
        cid = xml.scenario.get_controllerid_for_nodeid(node_id);
        cind = cid==controller_ids;
        if sum(cind) ~= 1
            error('sum(cind)~=1')
        end
        xml.scenario.scenario.controllers.controller(cind).schedule.schedule_item.ATTRIBUTE.offset = offset;
    end
    
    [path, name]=fileparts(config_file);
    [~, ~] = mkdir(path, 'optimized_config_files');
    xml.scenario.save(fullfile(path, 'optimized_config_files', ['optimized_', name]));
end

