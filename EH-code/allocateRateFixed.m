function [AllocateRate] = allocateRateFixed(conf_srcRates,N_Nodes)
    AllocateRate = zeros(N_Nodes, 1);
    for ind_node =1:N_Nodes
        %  ±œ∂∑÷≈‰
        AllocateRate(ind_node,1) = conf_srcRates(ind_node);
    end
end