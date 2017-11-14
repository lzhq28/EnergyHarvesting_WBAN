function parsave(save_path_name, deltaPL, Queue, AllocatePowerRate, sta_AllocateSlots, shadow_seq, pos_seq, EH_status_seq, EH_collect_seq, EH_P_tran)
%parsave 在并行parfor中通过调用该函数实现参数保存
%输入
%   QoS 服务质量
    save(save_path_name, 'deltaPL', 'Queue', 'AllocatePowerRate', 'sta_AllocateSlots', 'shadow_seq', 'pos_seq', 'EH_status_seq', 'EH_collect_seq', 'EH_P_tran');
end

