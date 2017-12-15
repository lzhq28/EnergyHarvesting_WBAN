%% offline方法：Optimal power allocation for outage probability minimization in fading channels with energy harvesting constraints
% 细节：
%   1. 根据能量到达情况采用定向注水法进行功率配置
%   2. 根据链路情况来确定最优的传输功率（主要是这个）
function [offline_power ] = compareOffline(shadow_seq, pos_seq, EH_status_seq, EH_collect_seq, par)
    tic
    offline_power = zeros(size(shadow_seq));
    N_frame = size( pos_seq,2);
    N_slot = size(shadow_seq,2)/N_frame;
    k_cor = par.EnergyHarvest.k_cor; %每个姿势的相关时间
    keep_time = min(k_cor,N_slot); %功率保持不变的时间长度
    PLR_th = par.Constraints.Nor_PLR_th;%丢包率门限
    power_min = par.PHY.P_min;
    power_max = par.PHY.P_max;
    precision = 0.001;
    %% 确定每个时隙的最优传输功率
    for ind_node =1:par.Nodes.Num
        packet_length = par.Nodes.packet_length(ind_node);
        tran_rate = par.Nodes.tranRate(ind_node);
        PL_Fr = par.Nodes.PL_Fr(ind_node);
        for ind_frame = 1:N_frame
            for ind_slot = 1:N_slot
                % 对每个时隙都根据功率来计算满足丢包率约束的传输功率
                cur_index = (ind_frame-1)*N_slot + ind_slot; %当前时隙的索引位置
                cur_shadow = shadow_seq(ind_node,cur_index);
                power = findPowerStaPLRth(power_min,power_max,PLR_th, tran_rate, packet_length, PL_Fr, cur_shadow, par.Channel, precision); 
                offline_power(ind_node,cur_index) = power;
            end
        end
    end
    %% 使用注水法最终确定各个传输功率
% %     for ind_node = 1:par.Nodes.Num
% %         power_sdp = sdpvar(1,N_frame*N_slot);
% %         Cons = [];
% %         Obj = [];
% %         
% %     end
    toc
end
