function [ EH_status_seq, EH_collect_seq, EH_P_tran] = energyHarvestStatistic( pos_seq, EnergyHarvest, MAC, rand_state)
%energyHarvestStatistic �˴���ʾ�йش˺�����ժҪ
% ����
%   pos_seq ������֡�µ���������״̬
%   EnergyHarvest �����ɼ�״̬
%   MAC MAC��ز�����������֡�����Լ�ʱ϶���ȵ�
%   rand_state �������
% ���
%   EH_status_seq �����ڵ��ڸ���ʱ϶�µ������ɼ�״̬��1��ʾON״̬��2��ʾOFF״̬
%   EH_collect_seq �����ڵ��ڸ���ʱ϶�²ɼ���������
%   EH_P_tran �����ڵ��ڸ������������µ������ɼ�ת�ƾ���

    % EnergyHarvest = par.EnergyHarvest
    % MAC = par.MAC
    %% ����״̬�µ������ɼ�״̬
    num_pos = size(EnergyHarvest.EH_P_ini,1);
    num_node = size(EnergyHarvest.EH_P_ini,2);
    % ��ȡ�������������µ������ɼ�״̬ת�ƾ���Ptran, Ptran,ij��ʾ״̬iת�Ƶ�״̬j�ĸ���
    EH_P_tran = {}; %�������������µ�����ON��OFF��״̬ת�ƾ���Pij��ʾ״̬iת�Ƶ�״̬j�ĸ���
    EH_ini_state = ones(1,num_node); %��ʼ״̬Ϊ1
    k_cor = EnergyHarvest.k_cor;%ceil(EnergyHarvest.t_cor_EH/MAC.T_Slot); %���ʱ϶������ͬһ�������ɼ�״̬��ά�ֵ�ʱ϶��
    for ind_pos = 1:num_pos
        for ind_node = 1:num_node
            EH_P_tran{ind_pos,ind_node} = tranMatrix(EnergyHarvest.EH_P_ini{ind_pos,ind_node},EnergyHarvest.EH_P_state{ind_pos,ind_node});
            EH_P_tran_cumsum{ind_pos,ind_node} = cumsum(EH_P_tran{ind_pos,ind_node},2); %���н����ۼ�
        end
    end
    %% �������ʱ϶�µ������ɼ�״̬�� 1��ʾΪON, 2ΪOFF״̬
    num_frame =  size(pos_seq,2);    
    EH_status_seq = zeros(num_node,num_frame*MAC.N_Slot);
    EH_collect_seq = zeros(num_node,num_frame*MAC.N_Slot); %�����ɼ���״̬
    begin_static_pos = 1;
    end_static_pos = 1;
    last_pos = pos_seq(1);
    % ȷ��������������ά�ֵ�ʱ���
    pos_periods = [];
    for ind_frame = 1:num_frame 
        % �ж������Ƿ����仯
        cur_pos = pos_seq(ind_frame);
        if (cur_pos ~=last_pos) %��⵽���Ʒ����仯������һ����ά�ֵ�ʱ�䱣�棬�����µ�ǰ���ƵĻ�����Ϣ
            %disp(['(pos,begin,end):',num2str(last_pos),',',num2str(begin_static_pos),',',num2str(end_static_pos)]) 
            pos_periods = [pos_periods; last_pos, begin_static_pos, end_static_pos];
            % ������һ��
            begin_static_pos = ind_frame;
            end_static_pos = ind_frame;
            last_pos = cur_pos;
        else %����û�з����仯��ֻ��Ҫ���µ�ǰ���ƵĽ���λ��
            end_static_pos = ind_frame;            
        end
        % ����߽�����
        if ind_frame == num_frame
             %disp(['(pos,begin,end):',num2str(last_pos),',',num2str(begin_static_pos),',',num2str(end_static_pos)])
             pos_periods = [pos_periods; last_pos, begin_static_pos, end_static_pos];
        end
    end
    % ���¸����ڵ������������ɼ�״̬
    for ind_node = 1:num_node
        cur_EH_state = EH_ini_state(1,ind_node);
        max_slot_all = num_frame*MAC.N_Slot; %����ʱ϶�е����ʱ϶��
        for ind_pos_change = 1:size(pos_periods,1)
            cur_pos = pos_periods(ind_pos_change,1);
            ind_begin_pos = pos_periods(ind_pos_change,2);
            ind_end_pos = pos_periods(ind_pos_change,3);
            num_EH_change = ceil((ind_end_pos - ind_begin_pos+1) * MAC.N_Slot/k_cor);        
            rand_seed = rand_state*num_node*num_frame+ind_node*num_frame+ind_begin_pos;
            rand('state', rand_seed)
            rand_EH_prob = rand(1,num_EH_change);
            rand('state', rand_seed)
            rand_EH_collect_prob = rand(1,num_EH_change);
            % ѭ�����������ɼ�״̬ȷ��
            for ind_EH_change = 1: num_EH_change-1
                ind_begin_slot = (ind_begin_pos -1)*MAC.N_Slot + (ind_EH_change - 1)*k_cor+1;
                ind_end_slot = (ind_begin_pos -1)*MAC.N_Slot + ind_EH_change*k_cor;
                cur_EH_state = decideNextEH_State( EH_P_tran_cumsum{cur_pos,ind_node}, cur_EH_state, rand_EH_prob(1,ind_EH_change) ); %ȷ����һ�����ɼ�״̬��1ΪON��2ΪOFF״̬
                EH_status_seq(ind_node,ind_begin_slot:ind_end_slot) = cur_EH_state;
                if cur_EH_state ==1
                    EH_collect_seq(ind_node,ind_begin_slot:ind_end_slot) = (EnergyHarvest.EH_pos_max(cur_pos,ind_node) -EnergyHarvest.EH_pos_min(cur_pos,ind_node)).*rand_EH_collect_prob(1,ind_EH_change)+EnergyHarvest.EH_pos_min(cur_pos,ind_node); %�ڸ���ʱ϶���ܲɼ���������
                end
            end
            % ����߽����
            ind_EH_change = num_EH_change;
            ind_begin_slot = (ind_begin_pos -1)*MAC.N_Slot + (ind_EH_change - 1)*k_cor+1;
            ind_end_slot = (ind_begin_pos -1)*MAC.N_Slot + ind_EH_change*k_cor;        
            max_slot_ind = ind_end_pos * MAC.N_Slot;    
            ind_end_slot = min([ind_end_slot,max_slot_ind]);
            cur_EH_state = decideNextEH_State( EH_P_tran_cumsum{cur_pos,ind_node}, cur_EH_state, rand_EH_prob(1,ind_EH_change) ); %ȷ����һ�����ɼ�״̬��1ΪON��2ΪOFF״̬
            EH_status_seq(ind_node,ind_begin_slot:ind_end_slot) = cur_EH_state;
            if cur_EH_state ==1   
                EH_collect_seq(ind_node,ind_begin_slot:ind_end_slot) = (EnergyHarvest.EH_pos_max(cur_pos,ind_node) -EnergyHarvest.EH_pos_min(cur_pos,ind_node)).*rand_EH_collect_prob(1,ind_EH_change)+EnergyHarvest.EH_pos_min(cur_pos,ind_node); %�ڸ���ʱ϶���ܲɼ���������
            end
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
    %decideNextEH_State ������һ�����ɼ�״̬��1ΪON��2ΪOFF
        prob_cumsum = cur_EH_P_tran_cumsum(cur_EH_state,:);
        ind_tmp = find(prob_cumsum >= rand_prob);
        next_EH_state = ind_tmp(1);
    end
end

