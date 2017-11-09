function  [shadow_seq, pos_seq]= shadowStatistic( N_Frame, ini_pos, hold_time, Nodes, Postures, MAC, rand_state, slot_or_frame_state)
%shadowStatistic ͳ�Ƶõ����г�֡����Ӱ˥��
%���룺
%   N_frame ��Ҫ���еĳ�֡�Ĵ���
%   ini_pos ��ʼ������������
%   hold_time  ÿ��״̬�ı���ʱ��
%   Nodes, Postures, MAC   ��ز������ɳ�ʼ�����
%   rand_state �����������
%   slot_or_frame_state ��Ӱ˥����ÿ��ʱ϶��ͬ������ÿ����֡��ͬ��ֵΪ0��ʾÿ��ʱ϶��ͬ��ֵΪ1��ʾÿ����֡��ͬ

    cur_pos = ini_pos; %��ǰ����״̬
    % ����ÿ��״̬�ı���ʱ��
    hold_Num_Frames = round(hold_time/MAC.T_Frame); %���hold_time���ǳ�֡���������������������������ȥ��
    if mod(hold_time, MAC.T_Frame)~=0
        hold_time = hold_Num_Frames*MAC.T_Frame; 
    end
    % �������ĳ�֡��
    pos_change_times = ceil(N_Frame/hold_Num_Frames);
    if mod(N_Frame, hold_Num_Frames)~=0
        N_Frame_tmp = pos_change_times *hold_Num_Frames;
    else
        N_Frame_tmp = N_Frame;
    end
    % ��ʼ������
    MAC.N_Slot = MAC.T_Frame/MAC.T_Slot; %������֡�ڵ�ʱ϶��
    total_num_slots = N_Frame_tmp*MAC.N_Slot; %�ܹ���ʱ϶��
    P_tran = tranMatrix(Postures.P_ini,Postures.P_state); % P_tran  �������Ƶ�״̬ת�ƾ���Pij��ʾ��״̬iת�Ƶ�״̬j�ĸ���
    P_tran_cumsum = cumsum(P_tran,2); %���н����ۼ�
    pos_seq = zeros(1, N_Frame_tmp); %��ʼ��������������
    shadow_seq = zeros(Nodes.Num, total_num_slots);
    rand('state',rand_state);
    rand_pos_prob = rand(1, pos_change_times);
    randn('state',rand_state);
    rand_shadow_prob = randn(Nodes.Num*Postures.Num, total_num_slots); 
    shadow_seq_all =  repmat(reshape(Nodes.Sigma',Nodes.Num*Postures.Num,1),1,total_num_slots).*rand_shadow_prob;
    % ����ÿ����֡�µ���������
    for i=1:hold_Num_Frames:N_Frame_tmp
        begin_ind = i;
        end_ind = begin_ind + hold_Num_Frames - 1;
        pos_seq(1,begin_ind:end_ind) = cur_pos;
        cur_pos = decideNextPos(P_tran_cumsum,cur_pos,rand_pos_prob(floor(end_ind/hold_Num_Frames)));
    end
    % ����ÿ����֡����Ӱ˥�����
    for i=1:N_Frame_tmp
        begin_pos_ind = (pos_seq(1,i)-1) * Nodes.Num +1;
        end_pos_ind = pos_seq(1,i) * Nodes.Num;
        begin_slot_ind = (i-1)*MAC.N_Slot+1;
        end_slot_ind = i*MAC.N_Slot;
        if slot_or_frame_state ==0 % ��Ӱ˥����ÿ��ʱ϶��ֵ��ͬ
            shadow_seq(:, begin_slot_ind:end_slot_ind) = shadow_seq_all(begin_pos_ind:end_pos_ind,begin_slot_ind:end_slot_ind);    
        else  %ÿ����֡�ڵ���Ӱ˥��ֵ��ͬ
            shadow_seq(:, begin_slot_ind:end_slot_ind) = repmat(shadow_seq_all(begin_pos_ind:end_pos_ind,begin_slot_ind),1,MAC.N_Slot);                  
        end
    end
    
    %% ���ܺ���
    % ȷ����һ����������
    function next_pos = decideNextPos(P_tran_cumsum,cur_pos,rand_prob)
        prob_cumsum = P_tran_cumsum(cur_pos,:);
        ind = find(prob_cumsum >= rand_prob); %rand_prob
        next_pos = ind(1);
    end
end

