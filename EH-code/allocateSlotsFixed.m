function [AllocateSlots] = allocateSlotsFixed(conf_srcRates, par)
    begin_ind = 1;
    end_ind = 0;
    AllocateSlots = zeros(par.Nodes.Num, par.MAC.N_Slot);
    for ind_node =1:par.Nodes.Num
        %  ±œ∂∑÷≈‰
        begin_ind = end_ind + 1;
        tmp_num = ceil(par.Nodes.Nor_SrcRates(ind_node)*par.MAC.T_Frame/(par.Nodes.tranRate(ind_node)*par.MAC.T_Slot));
        end_ind = begin_ind + tmp_num -1;
        AllocateSlots(ind_node,begin_ind:end_ind) = 1;
    end
end