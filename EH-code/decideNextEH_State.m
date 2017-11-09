function next_EH_state = decideNextEH_State( cur_EH_P_tran_cumsum, cur_EH_state, rand_prob )
%decideNextEH_State 决定下一能量采集状态，1为ON，2为OFF
    prob_cumsum = cur_EH_P_tran_cumsum(cur_EH_state,:);
    ind_tmp = find(prob_cumsum >= rand_prob);
    next_EH_state = ind_tmp(1);
end

