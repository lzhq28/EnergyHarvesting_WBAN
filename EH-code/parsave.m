function parsave(save_path_name, deltaPL, Queue, AllocatePowerRate, sta_AllocateSlots, shadow_seq, pos_seq, EH_status_seq, EH_collect_seq, EH_P_tran)
%parsave �ڲ���parfor��ͨ�����øú���ʵ�ֲ�������
%����
%   QoS ��������
    save(save_path_name, 'deltaPL', 'Queue', 'AllocatePowerRate', 'sta_AllocateSlots', 'shadow_seq', 'pos_seq', 'EH_status_seq', 'EH_collect_seq', 'EH_P_tran');
end

