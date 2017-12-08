classdef Intersection < handle
    
    properties
        node_id
        controller_id
        paths
        movements
    end
    
    methods
        
        function this = Intersection(node_id)
            if nargin==0
                return
            end
            this.node_id = node_id;
            this.paths = repmat(Path,1,0);
            this.movements = repmat(Movement,1,0);
        end
        
        function this = set_controller_id(this,id)
            this.controller_id = id;
        end
        
        function this = add_path(this,p)
            this.paths(end+1) = p;
        end
        
        function this = add_movement(this,m)
            this.movements(end+1) = m;
        end

        function x = has_movement_for_link_pair(this,up_link_id,dn_link_id)
            if isempty(this.movements)
                x = false;
                return
            end
            
            up_links = arrayfun(@(z) z.up_link_id,this.movements);
            dn_links = arrayfun(@(z) z.dn_link_id,this.movements);

            ordered_up_dn_links = [up_links' dn_links'];
            
            % CHECK THIS LINE PLEASE!
            x = any(ismember(ordered_up_dn_links, [up_link_id dn_link_id],'rows'));
%             x = any( ismember(up_link_id,up_links) && ismember(dn_link_id,dn_links) );
        end
        
        function m = get_movement(this, up_link_id, dn_link_id)
            up_links = arrayfun(@(z) z.up_link_id,this.movements);
            dn_links = arrayfun(@(z) z.dn_link_id,this.movements); 
            
            ordered_up_dn_links = [up_links' dn_links'];
            
            movement_ind = find(ismember(ordered_up_dn_links, [up_link_id dn_link_id],'rows'));
%             up_link_ind = find(up_links == up_link_id);
%             dn_link_ind = find(dn_links == dn_link_id);
            
%             if (up_link_ind ~= dn_link_ind)
%                 error('up_link_ind ~= dn_link_ind');
%             end
            
            m = this.movements(movement_ind);
        end
        
        function this = set_stages(this,s)
            this.stages = s;
        end
        
        
        
    end
    
end

