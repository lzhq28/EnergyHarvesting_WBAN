function [average_location] = findAverageLocation( cur_EH_last_status, cur_tran_power, cur_src_rate, cur_re_num_slots, cur_EH_P_tran, cur_EH_mean, tran_rate, k_cor, MAC, E_a, E_Pct)
%findAverageLocation　找到一个节点的平均位置
%输入
%   cur_EH_last_status 上一超帧末尾位置的EH状态
%   cur_tran_power 传输功率
%   cur_src_rate 数据速率
%   tran_rate 传输速率
%   cur_re_num_slots 上一超帧分配时隙末尾位置到当前帧Beacon位置间的时隙数
%   cur_EH_P_tran　能量采集状态转移矩阵
%   cur_EH_mean　能量采集在ON状态下的能量采集率
%   k_cor 能量采集相干时间所维持的时隙数
%   MAC MAC相关参数
%   E_a 能量相关参数
%   E_Pct 电路消耗功率

%     cur_EH_last_status = EH_last_status(ind_node)
%     cur_tran_power = tran_power(ind_node)
%     cur_src_rate = src_rate(ind_node)
%     cur_re_num_slots = re_num_slots(ind_node)
%     k_cor = parameters.EnergyHarvest.k_cor
%     MAC=par.MAC
%     E_a = par.PHY.E_a
%     E_Pct = par.PHY.E_Pct 
%     cur_EH_P_tran=EH_P_tran{cur_pos, ind_node}
    
    
    left = 1;
    right = MAC.N_Slot;
    tmp_Q = cur_EH_P_tran(1,2) + cur_EH_P_tran(2,1);
    energy_cost = ((1+E_a)*cur_tran_power + E_Pct)*cur_src_rate*MAC.T_Frame/tran_rate; %传输一个超帧所产生的数据包所消耗的能量
   
    % 调整右边界
    while 1
        if cur_EH_last_status ==1
            tmp_P = cur_EH_P_tran(2,1)/tmp_Q + cur_EH_P_tran(1,2).*power((1-tmp_Q),ceil((1:(cur_re_num_slots+right))/k_cor))./tmp_Q; %下一状态为ON的概率
        else
            tmp_P = cur_EH_P_tran(2,1)/tmp_Q - cur_EH_P_tran(2,1).*power((1-tmp_Q),ceil((1:(cur_re_num_slots+right))/k_cor))./tmp_Q; %上一状态为OFF,下一状态为ON的概率
        end
        tmp_EH_cum_right = sum(tmp_P)*cur_EH_mean*MAC.T_Slot; 
        if tmp_EH_cum_right < energy_cost %调节右边界
            right = 2*right;
        else 
            break;
        end
    end
    
    %　左边界
    if cur_EH_last_status ==1
        tmp_P = cur_EH_P_tran(2,1)/tmp_Q + cur_EH_P_tran(1,2).*power((1-tmp_Q),ceil((1:(cur_re_num_slots+left))/k_cor))./tmp_Q; %下一状态为ON的概率
    else
        tmp_P = cur_EH_P_tran(2,1)/tmp_Q - cur_EH_P_tran(2,1).*power((1-tmp_Q),ceil((1:(cur_re_num_slots+left))/k_cor))./tmp_Q; %上一状态为OFF,下一状态为ON的概率
    end
    tmp_EH_cum_left = sum(tmp_P)*cur_EH_mean*MAC.T_Slot;
    if tmp_EH_cum_left>= energy_cost
        average_location = left;
        return;
    end
    % 遍历所有的时隙范围内找平均位置
    if cur_EH_last_status ==1
        for tmp_h = left:right
            tmp_P = cur_EH_P_tran(2,1)/tmp_Q + cur_EH_P_tran(1,2).*power((1-tmp_Q),ceil((1:(cur_re_num_slots+tmp_h))/k_cor))./tmp_Q; %下一状态为ON的概率
            tmp_EH_cum(1, tmp_h) = sum(tmp_P)*cur_EH_mean*MAC.T_Slot;
        end 
    else
        for tmp_h = left:right
            tmp_P = cur_EH_P_tran(2,1)/tmp_Q - cur_EH_P_tran(2,1).*power((1-tmp_Q),ceil((1:(cur_re_num_slots+tmp_h))/k_cor))./tmp_Q; %上一状态为OFF,下一状态为ON的概率
            tmp_EH_cum(1, tmp_h) = sum(tmp_P)*cur_EH_mean*MAC.T_Slot;
        end 
    end
 
    ind = find(tmp_EH_cum>=energy_cost);
    average_location = ind(1);    
    disp(strcat(['average_location:',num2str(average_location),',(energy_cost,EH_cum):',num2str(energy_cost),',',num2str(tmp_EH_cum(average_location))]))
 
end

