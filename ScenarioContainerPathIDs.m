classdef ScenarioContainerPathIDs
    
    properties
        scenario @Scenario
        path_ids
        intersections  % map
        movements      % map
        paths          % map
        cycle
    end
    
    methods
        
        function this = ScenarioContainerPathIDs(configfile, path_ids)
            
            % load the config file
            this.scenario = Scenario(configfile);
            this.path_ids = path_ids;
            
            % create list of signal actuators
            signal_node_ids = [];
            for i=1:numel(this.scenario.scenario.actuators.actuator)
                act = this.scenario.scenario.actuators.actuator(i);
                if strcmp(act.ATTRIBUTE.type,'signal')
                    signal_node_ids(end+1) = act.actuator_target.ATTRIBUTE.id;
                end
            end
            
            % create all paths
            this.paths = containers.Map('KeyType','int32','ValueType','any');
            num_paths = numel(this.scenario.scenario.subnetworks.subnetwork);
            for i=1:num_paths
                subnet = this.scenario.scenario.subnetworks.subnetwork(i);
                id = subnet.ATTRIBUTE.id;
                if ~isempty(ismember(this.path_ids, id))
                    this.paths(id) = Path(subnet);
                end
            end
            
            
            % extract intersections from paths
            this.intersections = containers.Map('KeyType','int32','ValueType','any');
            path_ids = cell2mat(this.paths.keys);
            for path_id=path_ids
                
                path = this.paths(path_id);
                
                for j=1:numel(path.link_ids)-1
                    
                    link_id = path.link_ids(j);
                    dn_link_id = path.link_ids(j+1);
                    
                    conn = this.scenario.get_link_connections(link_id);
                    
                    if ~ismember(dn_link_id,conn.dn_links)
                        error('~ismember(dn_link,conn.dn_links)')
                    end
                    
                    dn_node_id = conn.end_node;
                    
                    if ismember(dn_node_id,signal_node_ids)
                        
                        % create a new intersection, or get existing
                        if ~this.intersections.isKey(dn_node_id)
                            this_intersection = Intersection(dn_node_id);
                            this.intersections(dn_node_id) = this_intersection;
                        else
                            this_intersection = this.intersections(dn_node_id);
                        end
                        
                        % add it to the path
                        path.add_intersection(this_intersection);
                        this_intersection.add_path(path);
                        
                    end
                    
                end
                
            end
            
            
            % assign controller ids to intersections
            for key=keys(this.intersections)
                intersection = this.intersections(key{1});
                controller_id = this.scenario.get_controllerid_for_nodeid(intersection.node_id);
                intersection.set_controller_id(controller_id);
            end
            
            % obtaining the cycle time
            intersection_ids = this.intersections.keys;
            % assuming that all intersections have a common cycle time:
            intersection = this.intersections(cell2mat(intersection_ids(1)));
            pretimed_control_info = this.scenario.get_pretimed_controller_info_with_controllerid(intersection.controller_id);
            cycle = pretimed_control_info.cycle;
            this.cycle = cycle;
            
            % assign the travel times along paths to the intersections
            for path_id = path_ids
                path = this.paths(path_id);
                link_ids = path.link_ids;
                travel_time = 0;
                
                for i = 1:numel(link_ids)
                    link_length = this.scenario.get_links(link_ids(i)).ATTRIBUTE.length;
                    end_node_id = this.scenario.get_links(link_ids(i)).ATTRIBUTE.end_node_id;
                    %
                    road_params = this.scenario.get_roadparam_for_linkid(link_ids(i));
                    speed = road_params.speed;
                    speed = (speed/3.6); % m/s
                    %                     travel_time = travel_time + cycle;
                    travel_time = travel_time + link_length/speed;
                    if any(ismember(signal_node_ids, end_node_id))
                        path.add_intersection_TT(end_node_id,travel_time);
                    end
                end
                
            end
            %             for path_id = path_ids;
            %                path = this.paths(path_id);
            %                link_ids = path.link_ids;
            %                travel_time = 0;
            %
            %                for i = 1:numel(link_ids)
            %                    link_length = this.scenario.get_links(link_ids(i)).ATTRIBUTE.length;
            %                    end_node_id = this.scenario.get_links(link_ids(i)).ATTRIBUTE.end_node_id;
            %
            %                    road_params = this.scenario.get_roadparan_for_linkid(link_ids(i));
            %                    speed = road_params.speed;
            %                    speed = (speed/3.6); % m/s
            %                    travel_time = travel_time + link_length/speed;
            %                    path.add_intersection_TT(end_node_id,travel_time);
            %                end
            %
            %             end
            
            % create all movements
            this.movements = repmat(Movement,1,0); %containers.Map('KeyType','int32','ValueType','any');
            for path_id=path_ids
                path = this.paths(path_id);
                
                intersection_ids = path.get_intersections_ids;
                
                for i=1:numel(intersection_ids)
                    
                    intersection = this.intersections(intersection_ids(i));
                    conn = this.scenario.get_node_connections(intersection.node_id);
                    
                    up_link_id = intersect(path.link_ids,conn.in_links);
                    dn_link_id = intersect(path.link_ids,conn.out_links);
                    
                    if numel(up_link_id)~=1 || numel(dn_link_id)~=1
                        error('numel(up_link_id)~=1 || numel(dn_link_id)~=1')
                    end
                    
                    % HAVE TO CHECK THE ELSE PART AS THE FOR THE CURRENT
                    % CONFIG FILE THERE EXISTS NO SUCH CONDITION
                    if ~intersection.has_movement_for_link_pair(up_link_id,dn_link_id)
                        
                        % create the movement
                        this_movement = Movement(intersection,up_link_id,dn_link_id);
                        
                        % links
                        intersection.add_movement(this_movement);
                        
                        % store
                        this.movements(end+1) = this_movement;
                        
                    else
                        this_movement = intersection.get_movement(up_link_id, dn_link_id);
                    end
                    
                    path.add_movement(this_movement);
                    path.add_offset_variable(this_movement.intersection.node_id);
                    this_movement.add_path(path);
                    
                end
                
            end
            
            
            % assigning the green durations to each movement
            
            intersections = this.intersections;
            %             road_connections_matrix = this.scenario.get_roadconnection_matrix;
            %             road_connections_matrix = road_connections_matrix(:,2:3);
            
            for intersection_id = cell2mat(intersections.keys)
                
                intersection = intersections(intersection_id);
                movements = intersection.movements;
                
                pretimed_control_info = this.scenario.get_pretimed_controller_info_with_controllerid(intersection.controller_id);
                phase_table = pretimed_control_info.phase_table;
                
                for movement = movements
                    
                    up_link_inds = find(phase_table.InLink == movement.up_link_id);
                    dn_link_inds = find(phase_table.OutLink == movement.dn_link_id);
                    
                    movement_ind = intersect(up_link_inds, dn_link_inds);
                    
                    if isempty(movement_ind)
%                         warning('These path ids have no supporting movement in intersection %d: %d',intersection_id, arrayfun(@(z) z.id,movement.paths))
                        movement.g = 2*this.cycle;
                    else
                        
                        if numel(movement_ind) > 1
                            warning('multiple actuations')
                        end
                        movement.g = sum(phase_table.Duration(movement_ind));
%                         movement.g = 120;
                        movement.start_time = phase_table.StartTime(movement_ind(1));
                    end
                end
                
            end
            
        end
        
        function paths = get_all_paths(this)
            paths = this.paths;
        end
        
        function paths = get_all_intersections(this)
            paths = this.intersections;
        end
        
        function paths = get_all_movements(this)
            paths = this.movements;
        end
        
        % ADDING THE REAL CYCLE LENGTH
        function cycle = get_common_cycle(this)
            cycle = this.cycle;
        end
        
    end
    
end

