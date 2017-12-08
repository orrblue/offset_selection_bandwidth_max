%{
 gen_optimized_offsets.m

 Calculates optimized offsets for a configuration file and saves new configuration file at current directory 
 
 INPUTS:
 config_file - name of config_file (in current directory) to be used
 path_ids - the ids of paths to optimize
 weights - the weights of each path
 save_name - name for newly saved config file

 OUTPUT:
 None

%}





%{
TODO:
1. Find Best way to pass null value in Matlab
2. Find what bs is in b max clean
3. Test
4. Write error checks
%}

function [] = gen_optimized_offsets(config_file, path_ids, weights, save_name)
    here = fileparts(mfilename('fullpath'));
    config_file = fullfile(here, config_file);
    xml = ScenarioContainer(config_file);
    
    % if no path_ids given, use all paths in file
    if isequal(path_ids, false)
        path_ids = arrayfun(@(z) z.ATTRIBUTE.id, xml.scenario.scenario.subnetworks.subnetwork);
    end
    
    % if no weights given, use weights = 1
    if isequal(weights, false)
        weights = ones(1, numel(path_ids));
        for i = 1: numel(path_ids)
            weights(i) = 1;
        end
    end
    
    [bs, offsets] = b_max_clean(config_file, paths_ids, weights);

    % read offsets map, go into XML file and update all the offsets using the map
    for key = offsets.keys

        % list of controller_ids from config file
        controller_ids = arrayfun(@(z) z.ATTRIBUTE.id , xml.scenario.scenario.controllers.controller);

        node_id = key{1};
        offset = offsets(key{1});

        % check node_id matches and set offset on node_id
        cid = X.scenario.get_controllerid_for_nodeid(node_id);
        cind = cid==controller_ids;
        if sum(cind) ~= 1
            error('sum(cind)~=1')
        end
        xml.scenario.scenario.controllers.controller(cind).schedule.schedule_item.ATTRIBUTE.offset = offset;
    end

    xml.scenario.save(fullfile(here,save_name));
end

