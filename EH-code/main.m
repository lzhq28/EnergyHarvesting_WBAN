%%%%% 主函数：算法的函数入口 %%%%%%
%% 清零数据并配置并行
    clc
    clear all
    matlab_ver='2015';% '2012'or'2015'
    if  strcmp(matlab_ver,'2012')
        if(matlabpool('size')==0) %没有打开并行
            matlabpool local; %按照local配置的进行启动多个matlab worker
        end
    else
        if(isempty(gcp('nocreate'))==1) %没有打开并行
            parpool local; %按照local配置的进行启动多个matlab worker
        end
    end
%% 初始化系统参数
    par = initialParameters(); %初始化系统参数
%% 配置实验所需参数
    rand_state = 1; %随机种子,建议从1开始的整数
    slot_or_frame_state =0; %阴影衰落是每个时隙不同，还是每个超帧不同，值为0表示每个时隙不同，值为1表示每个超帧不同
    pos_hold_time = 400; %每个姿势保持的时间，单位ms
    N_Frame = 1000; %实验的总超帧数
    ini_pos = 1; %初始化身体姿势为静止状态
    % 计算所有超帧的姿势序列和每个时隙的阴影衰落
    [shadow_seq, pos_seq] = shadowStatistic( N_Frame, ini_pos, pos_hold_time, par.Nodes, par.Postures, par.MAC, rand_state, slot_or_frame_state);
    
    %% 性能分析
    % 初始化三种不同的队列
    for ind_node = 1:par.Nodes.Num
        Queue(ind_node).tranQueue = []; %数据包传输队列，包含数据包传输的信息: 
        Queue(ind_node).arrivalQueue = []; %数据包达到队列， [pacektID,frameID,t_gen_offset,packetType]
        Queue(ind_node).bufferQueue = [0,1,1]; %缓存状态队列, [frameID, beginIndex, endIndex]
    end   
    
    % 循环统计分析
    for ind_frame = 1:N_Frame %对超帧进行遍历
        cur_pos = pos_seq(ind_frame); %当前节点的身子姿势
        cur_shadow = shadow_seq(:,((ind_frame-1)*par.MAC.N_Slot+1):ind_frame*par.MAC.N_Slot); %当前超帧内所有时隙的阴影衰落值
        for ind_node = 1:par.Nodes.Num %对各个节点进行遍历

            %% 更新参数
            % 随机种子，所有节点在不同超帧的随机种子都不同
            rand_seed = rand_state*par.Nodes.Num*N_Frame+ (ind_node-1)*N_Frame+(ind_frame-1);
            % 先使用固定的资源分配来编写节点性能统计函数
            Allocate(ind_node).power = par.PHY.P_max;
            Allocate(ind_node).rate = par.PHY.RateSet(3);
            Allocate(ind_node).slot = ones(1, par.MAC.N_Slot); %这里用来测试，直接将所有时隙分配给节点
            % 各个节点的基本信息
            Node(ind_node).Sigma = par.Nodes.Sigma(cur_pos,ind_node); % 当前节点在当前身子姿势下的阴影衰落的标准差Sigma
            Node(ind_node).PL_Fr = par.Nodes.PL_Fr(ind_node); % PL = PL_Fr + shadow
            Node(ind_node).num_packet_buffer = par.Nodes.num_packet_buffer(ind_node); %节点缓存所能保存数据包的数量
            Node(ind_node).num_packet_Nor = ceil(par.Nodes.Nor_SrcRates(ind_node)*par.MAC.T_Frame/par.Nodes.packet_length(ind_node));
            Node(ind_node).packet_length = par.Nodes.packet_length(ind_node);            
            rand('state', rand_seed); %生成随机种子，不同的rand_state对不同的ind_frame产生不重叠的随机序列
            Node(ind_node).num_packet_Emer = random('poiss',par.Nodes.lambda_Emer(ind_node));
            Node(ind_node).num_packet_buffer = par.Nodes.num_packet_buffer(ind_node); %缓存所能存储的数据包数量
            
            %% 分析数据包到达队列,这里只统计正常包
            % 正常数据包
            tmp_arrival_Queue = zeros(Node(ind_node).num_packet_Nor,4);
            tmp_arrival_Queue(:,1) = ((1:Node(ind_node).num_packet_Nor) + size(Queue(ind_node).arrivalQueue,1))'; % 数据包ID-packetID
            tmp_arrival_Queue(:,2) = ind_frame; % 超帧ID-frameID
            tmp_arrival_Queue(:,3) = ((1:Node(ind_node).num_packet_Nor)/Node(ind_node).num_packet_Nor.*par.MAC.T_Frame)'; % 数据包在当前超帧中产生的时间(或偏移量)-t_gen_offset
            %tmp_arrival_Queue(:,4) = zeros(Node(ind_node).num_packet_Nor,1); % 数据包类型-packetType, 值为0表示为普通包，值为1表示为紧急包
            Queue(ind_node).arrivalQueue = [Queue(ind_node).arrivalQueue;tmp_arrival_Queue]
            %% 分析缓存状态队列
            % 需要根据缓存情况来决定是否对节点进行丢弃，并分析未存储的数据包是否超过缓存容量
            % 首先分析数据包是否超时延门限，如果超过时延门限将丢包
            ind_end_buffer = size(Queue(ind_node).arrivalQueue,1); %结束位置
            ind_begin_buffer = Queue(ind_node).bufferQueue(end,2); %读取上一超帧所剩的
            if (ind_end_buffer-ind_begin_buffer) > Node(ind_node).num_packet_buffer %判断当前队列中的数据包是否大于缓存的最大数，如果大于将。
                ind_begin_buffer = ind_end_buffer - Node(ind_node).num_packet_buffer + 1;
                
            end
            Queue(ind_node).bufferQueue = [Queue(ind_node).bufferQueue;ind_frame,ind_begin_buffer,ind_end_buffer]; %更新缓存队列
            %% 分析数据包传输队列
            tran_times = floor(sum(Allocate(ind_node).slot).*par.MAC.T_Slot.*Allocate(ind_node).rate./Node(ind_node).packet_length); %分配的资源可以传输的次数
            rand('state',rand_seed)            
            rand_PLR = rand(1,tran_times); %产生随机数用来与PLR对比来确定是否丢包
            cur_PLR = calPLR(Allocate(ind_node).power, Allocate(ind_node).rate, Node(ind_node).packet_length, Node(ind_node).PL_Fr, cur_shadow(ind_node,:), Channel);
            for ind_tran = 1:tran_times
                
                cur_ind_slot = Queue(ind_node).bufferQueue(end,);
            end
            
        end
    end
    
 
    
    % 
%     randn('state',0); 
%     X_cur = randn(1,1,'double')
%     packetSize = 1000; %单位bit
%     tranPower = 0.001:0.0001:0.01;
%     tranRate = par.PHY.RateSet(2)*6
%     plr =  calPLR(tranPower, tranRate, packetSize, par.Nodes.PL_Fr(1,1), X_cur, par.Channel.Bandwidth,par.Channel.BCH_n)
%     plot(plr)