%% offline������Optimal power allocation for outage probability minimization in fading channels with energy harvesting constraints
% ϸ�ڣ�
%   1. ������������������ö���עˮ�����й�������
%   2. ������·�����ȷ�����ŵĴ��书�ʣ���Ҫ�������
function [offline_power ] = compareOffline(shadow_seq, pos_seq, EH_status_seq, EH_collect_seq,PLR_th, par)
    tic
    offline_power = zeros(size(shadow_seq));
    N_frame = size( pos_seq,2);
    N_slot = size(shadow_seq,2)/N_frame;
    k_cor = par.EnergyHarvest.k_cor; %ÿ�����Ƶ����ʱ��
    keep_time = min(k_cor,N_slot); %���ʱ��ֲ����ʱ�䳤��
    %PLR_th = par.Constraints.Nor_PLR_th;%����������
    power_min = par.PHY.P_min;
    power_max = par.PHY.P_max;
    precision = 0.001;
    %% ȷ��ÿ��ʱ϶�����Ŵ��书��
    for ind_node =1:par.Nodes.Num
        packet_length = par.Nodes.packet_length(ind_node);
        tran_rate = par.Nodes.tranRate(ind_node);
        PL_Fr = par.Nodes.PL_Fr(ind_node);
        for ind_frame = 1:N_frame
            for ind_slot = 1:N_slot
                % ��ÿ��ʱ϶�����ݹ������������㶪����Լ���Ĵ��书��
                cur_index = (ind_frame-1)*N_slot + ind_slot; %��ǰʱ϶������λ��
                cur_shadow = shadow_seq(ind_node,cur_index);
                power = findPowerStaPLRth(power_min,power_max,PLR_th, tran_rate, packet_length, PL_Fr, cur_shadow, par.Channel, precision); 
                offline_power(ind_node,cur_index) = power;
            end
        end
    end
    %% ʹ��עˮ������ȷ���������书��
% %     for ind_node = 1:par.Nodes.Num
% %         power_sdp = sdpvar(1,N_frame*N_slot);
% %         Cons = [];
% %         Obj = [];
% %         
% %     end
    toc
end
