function next_EH_state = decideNextEH_State( cur_EH_P_tran_cumsum, cur_EH_state, rand_prob )
%decideNextEH_State ������һ�����ɼ�״̬��1ΪON��2ΪOFF
    prob_cumsum = cur_EH_P_tran_cumsum(cur_EH_state,:);
    ind_tmp = find(prob_cumsum >= rand_prob);
    next_EH_state = ind_tmp(1);
end

