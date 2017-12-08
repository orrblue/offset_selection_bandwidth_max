classdef Movement < handle
    
    properties
        intersection @Intersection
        up_link_id
        dn_link_id
        paths
        g
        start_time
    end
    
    methods
        
        function this = Movement(intersection,up_link_id,dn_link_id)
            if nargin==0
                return
            end
            this.intersection = intersection;
            this.up_link_id = up_link_id;
            this.dn_link_id=dn_link_id;
            this.paths = repmat(Path,1,0);
            this.g = 0;
            this.start_time = 0;
        end
        
        function this = add_path(this,p)
            this.paths(end+1) = p;
        end
        
        function this = set_movement_absolute_offset(this, abs_o)
            this.offset = abs_o;
        end
        
        
    end
    
end

