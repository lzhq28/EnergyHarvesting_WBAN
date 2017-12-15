function [AllocatePower] = allocatePowerFixed(conf_powers,N_Nodes)
    AllocatePower = zeros(N_Nodes, 1);
    for ind_node =1:N_Nodes
        %  ±œ∂∑÷≈‰
        AllocatePower(ind_node,1) = conf_powers(ind_node);
    end
end