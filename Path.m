classdef Path < handle
    
    properties
        id
        link_ids
        intersections
        movements
        b_variable
        alpha_variable
        intersection_travel_times 
        offset_variables
    end
    
    methods
        
        function this = Path(subnet)
            if nargin==0
                return
            end
            this.id = subnet.ATTRIBUTE.id;
            this.link_ids = subnet.CONTENT;
            this.intersections = repmat(Intersection,1,0);
            this.movements = repmat(Movement,1,0);
            this.b_variable = sdpvar(1,1);
            this.alpha_variable = binvar(1,1);
%             this.alpha_variable = sdpvar(1,1);
            this.intersection_travel_times = containers.Map('KeyType','int32','ValueType','any');
            this.offset_variables = containers.Map('KeyType','int32','ValueType','any');
        end
        
        function this = add_intersection(this,i)
            this.intersections(end+1) = i;
        end
        
        function this = add_movement(this,m)
            this.movements(end+1) = m;
        end
        
        function X = get_intersections_ids(this)
            X = arrayfun(@(z)z.node_id,this.intersections);
        end
        
        function X = get_path_offsets(this)
            for offset_key = cell2mat(this.offset_variables.keys)
               this.offset_variables(offset_key) = value(this.offset_variables(offset_key));
            end
            
            X = this.offset_variables;
        end
        
        function X = get_path_bandwidth(this)
            this.b_variable = value(this.b_variable);
            X = this.b_variable;
        end
        
        function X = get_path_alpha(this)
            this.alpha_variable = value(this.alpha_variable);
            X = this.alpha_variable;
        end
        
        function X = getId(this)
            X = this.id;
        end
        
        function X = add_intersection_TT(this, node_id, t)
            this.intersection_travel_times(node_id) = t;
        end
        
        function X = add_offset_variable(this, node_id)
            this.offset_variables(node_id) = sdpvar(1,1);
        end

    end
    
end

