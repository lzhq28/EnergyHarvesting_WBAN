function [average_location] = findAverageLocation( cur_EH_last_status, cur_tran_power, cur_src_rate, cur_re_num_slots, cur_EH_P_tran, cur_EH_mean, tran_rate, k_cor, MAC, E_a, E_Pct)
%findAverageLocation���ҵ�һ���ڵ��ƽ��λ��
%����
%   cur_EH_last_status ��һ��֡ĩβλ�õ�EH״̬
%   cur_tran_power ���书��
%   cur_src_rate ��������
%   tran_rate ��������
%   cur_re_num_slots ��һ��֡����ʱ϶ĩβλ�õ���ǰ֡Beaconλ�ü��ʱ϶��
%   cur_EH_P_tran�������ɼ�״̬ת�ƾ���
%   cur_EH_mean�������ɼ���ON״̬�µ������ɼ���
%   k_cor �����ɼ����ʱ����ά�ֵ�ʱ϶��
%   MAC MAC��ز���
%   E_a ������ز���
%   E_Pct ��·���Ĺ���

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
    energy_cost = ((1+E_a)*cur_tran_power + E_Pct)*cur_src_rate*MAC.T_Frame/tran_rate; %����һ����֡�����������ݰ������ĵ�����
   
    % �����ұ߽�
    while 1
        if cur_EH_last_status ==1
            tmp_P = cur_EH_P_tran(2,1)/tmp_Q + cur_EH_P_tran(1,2).*power((1-tmp_Q),ceil((1:(cur_re_num_slots+right))/k_cor))./tmp_Q; %��һ״̬ΪON�ĸ���
        else
            tmp_P = cur_EH_P_tran(2,1)/tmp_Q - cur_EH_P_tran(2,1).*power((1-tmp_Q),ceil((1:(cur_re_num_slots+right))/k_cor))./tmp_Q; %��һ״̬ΪOFF,��һ״̬ΪON�ĸ���
        end
        tmp_EH_cum_right = sum(tmp_P)*cur_EH_mean*MAC.T_Slot; 
        if tmp_EH_cum_right < energy_cost %�����ұ߽�
            right = 2*right;
        else 
            break;
        end
    end
    
    %����߽�
    if cur_EH_last_status ==1
        tmp_P = cur_EH_P_tran(2,1)/tmp_Q + cur_EH_P_tran(1,2).*power((1-tmp_Q),ceil((1:(cur_re_num_slots+left))/k_cor))./tmp_Q; %��һ״̬ΪON�ĸ���
    else
        tmp_P = cur_EH_P_tran(2,1)/tmp_Q - cur_EH_P_tran(2,1).*power((1-tmp_Q),ceil((1:(cur_re_num_slots+left))/k_cor))./tmp_Q; %��һ״̬ΪOFF,��һ״̬ΪON�ĸ���
    end
    tmp_EH_cum_left = sum(tmp_P)*cur_EH_mean*MAC.T_Slot;
    if tmp_EH_cum_left>= energy_cost
        average_location = left;
        return;
    end
    % �������е�ʱ϶��Χ����ƽ��λ��
    if cur_EH_last_status ==1
        for tmp_h = left:right
            tmp_P = cur_EH_P_tran(2,1)/tmp_Q + cur_EH_P_tran(1,2).*power((1-tmp_Q),ceil((1:(cur_re_num_slots+tmp_h))/k_cor))./tmp_Q; %��һ״̬ΪON�ĸ���
            tmp_EH_cum(1, tmp_h) = sum(tmp_P)*cur_EH_mean*MAC.T_Slot;
        end 
    else
        for tmp_h = left:right
            tmp_P = cur_EH_P_tran(2,1)/tmp_Q - cur_EH_P_tran(2,1).*power((1-tmp_Q),ceil((1:(cur_re_num_slots+tmp_h))/k_cor))./tmp_Q; %��һ״̬ΪOFF,��һ״̬ΪON�ĸ���
            tmp_EH_cum(1, tmp_h) = sum(tmp_P)*cur_EH_mean*MAC.T_Slot;
        end 
    end
 
    ind = find(tmp_EH_cum>=energy_cost);
    average_location = ind(1);    
    %disp(strcat(['average_location:',num2str(average_location),',(energy_cost,EH_cum):',num2str(energy_cost),',',num2str(tmp_EH_cum(average_location))]));
 
end

