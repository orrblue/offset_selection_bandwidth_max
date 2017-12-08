
here = fileparts(mfilename('fullpath'));
config_file = fullfile(here, 'san_diego_beats_network_v12.xml');

n_paths = 7;
weights = ones(1, n_paths);
paths_ids = zeros(1, n_paths);


for i = 1:n_paths
    weights(i) = 1;
end


for i = 1:n_paths
    paths_ids(i) = i;
end




X = ScenarioContainer(config_file);
[bs, offsets] = b_max_clean(config_file, paths_ids, weights)

% read offsets map, go into XML file and update all the offsets using the map
for key = offsets.keys
    
    % list of node_ids from config file
    cids = arrayfun(@(z) z.ATTRIBUTE.id , X.scenario.scenario.controllers.controller);

    node_id = key{1}
    offset = offsets(key{1})
    
%     disp(key{1})
%     disp(offsets(key{1}))
    
    % check node_id matches and set offset on node_id
    cid = X.scenario.get_controllerid_for_nodeid(node_id);
    cind = cid==cids;
    if sum(cind)~=1
        error('sum(cind)~=1')
    end
    X.scenario.scenario.controllers.controller(cind).schedule.schedule_item.ATTRIBUTE.offset = offset;


end

X.scenario.save(fullfile(here,'test'));

