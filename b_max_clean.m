function [bs, node_offsets] = b_max_clean(config_file, path_ids, lambda)

% load scenario
X = ScenarioContainerPathIDs(config_file, path_ids);
all_paths = X.get_all_paths;
all_intersections = X.get_all_intersections;
all_movements = X.get_all_movements;

cycle = X.get_common_cycle();
% constructing the cost
cost = 0;
for path_id = cell2mat(all_paths.keys)
    
    cost = cost + lambda(path_id) * all_paths(path_id).b_variable;
end

% constructing the box constraints
box_cnst = [];
for path_id = cell2mat(all_paths.keys)
    
    offset_variables = all_paths(path_id).offset_variables;
    
    for offset_variable_key = cell2mat(offset_variables.keys)
        
        box_cnst =[box_cnst; -cycle/2 <= offset_variables(offset_variable_key) <= cycle/2];
    end
    
end

% constructing the inequality constraints
ineq_cnst = [];
for path_id = cell2mat(all_paths.keys)
    
    path = all_paths(path_id);
    offset_variables = path.offset_variables;
    offset_variable_ids = cell2mat(offset_variables.keys);
    
    movements = path.movements;
    movement_node_ids = arrayfun(@(z) z.intersection.node_id, movements);
    
    if numel(offset_variable_ids) > 1
        
        for i = 1:numel(offset_variable_ids)-1
            i_ind = find(movement_node_ids == offset_variable_ids(i));
            i_movement = movements(i_ind);
            
            ineq_cnst = [ineq_cnst; path.b_variable <= ((1 - path.alpha_variable)*2*cycle + i_movement.g)];
            
            for j = i:numel(offset_variable_ids)
                j_ind = find(movement_node_ids == offset_variable_ids(j));
                j_movement = movements(j_ind);
                
                if (mod(j_movement.g,cycle)~= 0 && mod(i_movement.g,cycle)~= 0)
                    ineq_cnst = [ineq_cnst; path.b_variable <= ((1 - path.alpha_variable)*2*cycle + j_movement.g)];
                    %
                    K = offset_variables(offset_variable_ids(i)) - offset_variables(offset_variable_ids(j)) + 0.5*(i_movement.g + j_movement.g);
                    ineq_cnst = [ineq_cnst; path.b_variable <= path.alpha_variable*2*cycle];
                    ineq_cnst = [ineq_cnst; path.b_variable <= ((1 - path.alpha_variable)*2*cycle + K)];
                    
                    K = offset_variables(offset_variable_ids(j)) - offset_variables(offset_variable_ids(i)) + 0.5*(i_movement.g + j_movement.g);
                    ineq_cnst = [ineq_cnst; path.b_variable <= path.alpha_variable*2*cycle];
                    ineq_cnst = [ineq_cnst; path.b_variable <= ((1 - path.alpha_variable)*2*cycle + K)];
                end
            end
            
        end
        
    end
end


% constructing the equality constraints

eq_cnst = [];
ineq_cnst_int = [];
for intersection_id = cell2mat(all_intersections.keys)
    
    intersection = all_intersections(intersection_id);
    paths = intersection.paths;
    
    if numel(paths) > 1
        
        for i = 1:numel(paths) - 1
            
            i_path = paths(i);
            i_movements_node_ids = arrayfun(@(z) z.intersection.node_id, i_path.movements);
            i_movement_ind = find(i_movements_node_ids == intersection.node_id);
            i_movement = i_path.movements(i_movement_ind);
            
            for j = i+1:numel(paths)
                
                j_path = paths(j);
                j_movements_node_ids = arrayfun(@(z) z.intersection.node_id, j_path.movements);
                j_movement_ind = find(j_movements_node_ids == intersection.node_id);
                j_movement = j_path.movements(j_movement_ind);
                
                if (mod(j_movement.g,cycle)~= 0 && mod(i_movement.g,cycle)~= 0)
                    % compute delta
                    
                    delta = (i_movement.start_time - j_movement.start_time) + ...
                        0.5*(i_movement.g - j_movement.g);
                    
                    rhs = delta - i_path.intersection_travel_times(intersection_id) + j_path.intersection_travel_times(intersection_id);
                    % crazy mod operator
                    rhs_resid = mod(rhs, cycle);
                    rhs_resid_other_side = rhs_resid - cycle;
                    
                    if abs(rhs_resid) <= abs(rhs_resid_other_side)
                        rhs = rhs_resid;
                    else
                        rhs = rhs_resid_other_side;
                    end
                    
                    int_var_mod = intvar(1,1);
                    ineq_cnst_int = [ineq_cnst_int; -1 <= int_var_mod <= 1];
%                   
                    eq_cnst = [eq_cnst; ((i_path.offset_variables(intersection.node_id) - j_path.offset_variables(intersection.node_id)) == rhs + int_var_mod*cycle)];
                    
                end
                
            end
        end
    end
end


%% optimization problem
% cnst = [eq_cnst;box_cnst;ineq_cnst];
cnst = [eq_cnst;box_cnst;ineq_cnst;ineq_cnst_int];
% cnst = [box_cnst;ineq_cnst];
ops = sdpsettings('solver', 'gurobi');
ops = sdpsettings(ops, 'debug',1);
diagnostics = optimize(cnst,-cost,ops);
% obtaining the value of path offsets
%%
paths_bs = containers.Map('KeyType','int32','ValueType','any');
for path_key = cell2mat(all_paths.keys)
    path = all_paths(path_key);
    path_offsets = path.get_path_offsets;
%     display(path_offsets.values);
end

for path_key = cell2mat(all_paths.keys)
    path = all_paths(path_key);
    path.get_path_alpha();
    path.get_path_bandwidth();
    paths_bs(path_key) = path.b_variable;
    display(path.b_variable)
end

movement_greens = arrayfun(@(z) z.g, all_movements);
movement_nodes = arrayfun(@(z) z.intersection.node_id, all_movements);
%% returning the absolute offsets of signalized intersections
intersections_abs_offsets = containers.Map('KeyType','int32','ValueType','any');

for intersection_id = cell2mat(all_intersections.keys)

    intersection = all_intersections(intersection_id);
    movements = intersection.movements;
    movement_greens = arrayfun(@(z) z.g, movements);
    right_turn_ind = find(movement_greens == 2*cycle);
    movements_inds = 1:numel(movements);
    movements_inds(right_turn_ind) = [];
    
    if ~isempty(movements_inds)
    a_movement = movements(movements_inds(1));
    a_path = a_movement.paths(1);

    abs_movement_offset = a_path.offset_variables(a_movement.intersection.node_id) + ...
        a_path.intersection_travel_times(a_movement.intersection.node_id);

    abs_movement_start_time = abs_movement_offset - 0.5*a_movement.g;
    abs_inter_offset = abs_movement_start_time - a_movement.start_time;
    
    if abs_inter_offset <= 0
        abs_inter_offset = abs_inter_offset + cycle;
        if abs_inter_offset <= 0
            abs_inter_offset = abs_inter_offset + cycle;
        end
    end
    else
        abs_inter_offset = 0;
    end
    
    if abs(abs_inter_offset - 90) < 0.001
        abs_inter_offset = 0;
    end
    intersections_abs_offsets(intersection.node_id) = abs_inter_offset;
    
    if abs_inter_offset < 0
        error('!!!')
        break;
    end  
    bs = paths_bs;
    
end
node_offsets = intersections_abs_offsets;
