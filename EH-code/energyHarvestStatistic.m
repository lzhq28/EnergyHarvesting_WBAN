function [ EH_status_seq, EH_collect_seq ] = energyHarvestStatistic( pos_seq, EnergyHarvest, MAC, rand_state)
%energyHarvestStatistic 此处显示有关此函数的摘要
% 输入
%   pos_seq 各个超帧下的身体姿势状态
%   EnergyHarvest 能量采集状态
%   MAC MAC相关参数，包含超帧长度以及时隙长度等
%   rand_state 随机种子
% 输出
%   EH_seq 在能量采集下的

    % EnergyHarvest = par.EnergyHarvest
    % MAC = par.MAC
    %% 各个状态下的能量采集状态
    % 获取各个身体姿势下的能量采集状态转移矩阵Ptran, Ptran,ij表示状态i转移到状态j的概率
    EH_P_tran = {}; %各个身子姿势下的能量ON和OFF的状态转移矩阵，Pij表示状态i转移到状态j的概率
    EH_ini_state = 1; %初始状态为1
    k_cor = EnergyHarvest.t_cor_EH/MAC.T_Slot; %相关时隙数，及同一个能量采集状态所维持的时隙数
    for ind_pos = 1:size(EnergyHarvest.EH_P_ini,2)
        EH_P_tran{1,ind_pos} = tranMatrix(EnergyHarvest.EH_P_ini{1,ind_pos},EnergyHarvest.EH_P_state{1,ind_pos});
        EH_P_tran_cumsum{1,ind_pos} = cumsum(EH_P_tran{1,ind_pos},2); %按行进行累加
    end
    %% 计算各个时隙下的能量采集状态： 1表示为ON, 2为OFF状态
    num_frame =  size(pos_seq,2);    
    EH_status_seq = zeros(1,num_frame*MAC.N_Slot);
    EH_collect_seq = zeros(1,num_frame*MAC.N_Slot); %能量采集的状态
    begin_static_pos = 1;
    end_static_pos = 1;
    last_pos = pos_seq(1);
    % 确定各个身体姿势维持的时间段
    pos_periods = [];
    for ind_frame = 1:num_frame 
        % 判断姿势是否发生变化
        cur_pos = pos_seq(ind_frame);
        if (cur_pos ~=last_pos) %检测到姿势发生变化，将上一姿势维持的时间保存，并更新当前姿势的基本信息
            %disp(['(pos,begin,end):',num2str(last_pos),',',num2str(begin_static_pos),',',num2str(end_static_pos)]) 
            pos_periods = [pos_periods; last_pos, begin_static_pos, end_static_pos];
            % 更新下一个
            begin_static_pos = ind_frame;
            end_static_pos = ind_frame;
            last_pos = cur_pos;
        else %姿势没有发生变化，只需要更新当前姿势的结束位置
            end_static_pos = ind_frame;            
        end
        % 处理边界条件
        if ind_frame == num_frame
             %disp(['(pos,begin,end):',num2str(last_pos),',',num2str(begin_static_pos),',',num2str(end_static_pos)])
             pos_periods = [pos_periods; last_pos, begin_static_pos, end_static_pos];
        end
    end
    % 更新各个节点所处的能量采集状态
    cur_EH_state = EH_ini_state;
    max_slot_all = num_frame*MAC.N_Slot; %所有时隙中的最大时隙数
    for ind_pos_change = 1:size(pos_periods,1)
        cur_pos = pos_periods(ind_pos_change,1);
        ind_begin_pos = pos_periods(ind_pos_change,2);
        ind_end_pos = pos_periods(ind_pos_change,3);
        num_EH_change = ceil((ind_end_pos - ind_begin_pos+1) * MAC.N_Slot/k_cor);        
        rand_seed = rand_state*num_frame+ind_begin_pos;
        rand('state', rand_seed)
        rand_EH_prob = rand(1,num_EH_change);
        rand('state', rand_seed)
        rand_EH_collect_prob = rand(1,num_EH_change);

        % 循环进行能量采集状态确定
        for ind_EH_change = 1: num_EH_change-1
            ind_begin_slot = (ind_begin_pos -1)*MAC.N_Slot + (ind_EH_change - 1)*k_cor+1;
            ind_end_slot = (ind_begin_pos -1)*MAC.N_Slot + ind_EH_change*k_cor;
            cur_EH_state = decideNextEH_State( EH_P_tran_cumsum{cur_pos}, cur_EH_state, rand_EH_prob(1,ind_EH_change) ); %确定下一能量采集状态，1为ON，2为OFF状态
            EH_status_seq(1,ind_begin_slot:ind_end_slot) = cur_EH_state;
            if cur_EH_state ==1
                EH_collect_seq(1,ind_begin_slot:ind_end_slot) = (EnergyHarvest.EH_pos_max(cur_pos) -EnergyHarvest.EH_pos_min(cur_pos)).*rand_EH_collect_prob(1,ind_EH_change)+EnergyHarvest.EH_pos_min(cur_pos); %在各个时隙所能采集到的能量
            end
        end
        % 处理边界情况
        ind_EH_change = num_EH_change;
        ind_begin_slot = (ind_begin_pos -1)*MAC.N_Slot + (ind_EH_change - 1)*k_cor+1;
        ind_end_slot = (ind_begin_pos -1)*MAC.N_Slot + ind_EH_change*k_cor;        
        max_slot_ind = ind_end_pos * MAC.N_Slot;    
        ind_end_slot = min([ind_end_slot,max_slot_ind]);
        cur_EH_state = decideNextEH_State( EH_P_tran_cumsum{cur_pos}, cur_EH_state, rand_EH_prob(1,ind_EH_change) ); %确定下一能量采集状态，1为ON，2为OFF状态
        EH_status_seq(1,ind_begin_slot:ind_end_slot) = cur_EH_state;
        if cur_EH_state ==1   
            EH_collect_seq(1,ind_begin_slot:ind_end_slot) = (EnergyHarvest.EH_pos_max(cur_pos) -EnergyHarvest.EH_pos_min(cur_pos)).*rand_EH_collect_prob(1,ind_EH_change)+EnergyHarvest.EH_pos_min(cur_pos); %在各个时隙所能采集到的能量
        end
    end
%     figure
%     subplot(311)
%     bar((1:size(EH_status_seq,2)),EH_status_seq)
%     subplot(312)
%     bar((1:size(EH_status_seq,2)),EH_collect_seq)
%     subplot(313)
%     bar(pos_seq)
    function next_EH_state = decideNextEH_State( cur_EH_P_tran_cumsum, cur_EH_state, rand_prob )
    %decideNextEH_State 决定下一能量采集状态，1为ON，2为OFF
        prob_cumsum = cur_EH_P_tran_cumsum(cur_EH_state,:);
        ind_tmp = find(prob_cumsum >= rand_prob);
        next_EH_state = ind_tmp(1);
    end
end

