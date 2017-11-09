function  [shadow_seq, pos_seq]= shadowStatistic( N_Frame, ini_pos, hold_time, Nodes, Postures, MAC, rand_state, slot_or_frame_state)
%shadowStatistic 统计得到所有超帧的阴影衰落
%输入：
%   N_frame 所要运行的超帧的次数
%   ini_pos 初始化的身体姿势
%   hold_time  每个状态的保持时间
%   Nodes, Postures, MAC   相关参数，由初始化获得
%   rand_state 随机生成种子
%   slot_or_frame_state 阴影衰落是每个时隙不同，还是每个超帧不同，值为0表示每个时隙不同，值为1表示每个超帧不同

    cur_pos = ini_pos; %当前姿势状态
    % 纠正每个状态的保持时间
    hold_Num_Frames = round(hold_time/MAC.T_Frame); %如果hold_time不是超帧的整数倍，将进行四舍五入进行去整
    if mod(hold_time, MAC.T_Frame)~=0
        hold_time = hold_Num_Frames*MAC.T_Frame; 
    end
    % 纠正最大的超帧数
    pos_change_times = ceil(N_Frame/hold_Num_Frames);
    if mod(N_Frame, hold_Num_Frames)~=0
        N_Frame_tmp = pos_change_times *hold_Num_Frames;
    else
        N_Frame_tmp = N_Frame;
    end
    % 初始化参数
    MAC.N_Slot = MAC.T_Frame/MAC.T_Slot; %单个超帧内的时隙数
    total_num_slots = N_Frame_tmp*MAC.N_Slot; %总共的时隙数
    P_tran = tranMatrix(Postures.P_ini,Postures.P_state); % P_tran  身体姿势的状态转移矩阵：Pij表示由状态i转移到状态j的概率
    P_tran_cumsum = cumsum(P_tran,2); %按行进行累加
    pos_seq = zeros(1, N_Frame_tmp); %初始化身体姿势序列
    shadow_seq = zeros(Nodes.Num, total_num_slots);
    rand('state',rand_state);
    rand_pos_prob = rand(1, pos_change_times);
    randn('state',rand_state);
    rand_shadow_prob = randn(Nodes.Num*Postures.Num, total_num_slots); 
    shadow_seq_all =  repmat(reshape(Nodes.Sigma',Nodes.Num*Postures.Num,1),1,total_num_slots).*rand_shadow_prob;
    % 分析每个超帧下的身体姿势
    for i=1:hold_Num_Frames:N_Frame_tmp
        begin_ind = i;
        end_ind = begin_ind + hold_Num_Frames - 1;
        pos_seq(1,begin_ind:end_ind) = cur_pos;
        cur_pos = decideNextPos(P_tran_cumsum,cur_pos,rand_pos_prob(floor(end_ind/hold_Num_Frames)));
    end
    % 分析每个超帧的阴影衰落情况
    for i=1:N_Frame_tmp
        begin_pos_ind = (pos_seq(1,i)-1) * Nodes.Num +1;
        end_pos_ind = pos_seq(1,i) * Nodes.Num;
        begin_slot_ind = (i-1)*MAC.N_Slot+1;
        end_slot_ind = i*MAC.N_Slot;
        if slot_or_frame_state ==0 % 阴影衰落在每个时隙的值不同
            shadow_seq(:, begin_slot_ind:end_slot_ind) = shadow_seq_all(begin_pos_ind:end_pos_ind,begin_slot_ind:end_slot_ind);    
        else  %每个超帧内的阴影衰落值不同
            shadow_seq(:, begin_slot_ind:end_slot_ind) = repmat(shadow_seq_all(begin_pos_ind:end_pos_ind,begin_slot_ind),1,MAC.N_Slot);                  
        end
    end
    
    %% 功能函数
    % 确定下一个身体姿势
    function next_pos = decideNextPos(P_tran_cumsum,cur_pos,rand_prob)
        prob_cumsum = P_tran_cumsum(cur_pos,:);
        ind = find(prob_cumsum >= rand_prob); %rand_prob
        next_pos = ind(1);
    end
end

