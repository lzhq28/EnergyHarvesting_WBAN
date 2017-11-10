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
    pos_hold_time = 40*100; %每个姿势保持的时间，单位ms
    N_Frame = 1000; %实验的总超帧数
    ini_pos = 1; %初始化身体姿势为静止状态
    % 计算所有超帧的姿势序列和每个时隙的阴影衰落
    [shadow_seq, pos_seq] = shadowStatistic( N_Frame, ini_pos, pos_hold_time, par.Nodes, par.Postures, par.MAC, rand_state, slot_or_frame_state);
    % 初始化所有时隙的能量采集状态
    [ EH_status_seq, EH_collect_seq ] = energyHarvestStatistic( pos_seq, par.EnergyHarvest, par.MAC, rand_state);
 

    %% 性能分析
    % 初始化三种不同的队列
    for ind_node = 1:par.Nodes.Num
        Queue(ind_node).tranQueue = []; %数据包传输队列，包含数据包传输的信息:[packetID, gen_frameID, t_gen_offset, tran_frameID, t_tran_offset, t_tran_cost, tran_power, tran_rate, tran_state]
        Queue(ind_node).arrivalQueue = []; %数据包达到队列， [pacektID,frameID,t_gen_offset,packetType]
        Queue(ind_node).bufferQueue = [0,1,1,1e+7]; %缓存状态队列, [frameID, beginIndex, endIndex, residue_energy]
    end   
    Allocate ={}; %初始化资源分配
    Node={}; %初始化各个节点的基本信息
    for ind_node = 1:par.Nodes.Num %对各个节点进行遍历
        %Node(ind_node).Sigma = par.Nodes.Sigma(cur_pos,ind_node); % 当前节点在当前身子姿势下的阴影衰落的标准差Sigma
        Node(ind_node).PL_Fr = par.Nodes.PL_Fr(ind_node); % PL = PL_Fr + shadow
        Node(ind_node).num_packet_buffer = par.Nodes.num_packet_buffer(ind_node); %节点缓存所能保存数据包的数量            
        Node(ind_node).packet_length = par.Nodes.packet_length(ind_node); 
        Node(ind_node).num_packet_buffer = par.Nodes.num_packet_buffer(ind_node); %缓存所能存储的数据包数量
        Node(ind_node).Nor_SrcRate = par.Nodes.Nor_SrcRates(ind_node);
    end
        
    % 循环统计分析
    last_end_slot_ind = ones(1,par.Nodes.Num)*par.MAC.N_Slot; %上一超帧分配时隙的结束位置
    for ind_frame = 1:N_Frame %对超帧进行遍历
        cur_pos = pos_seq(ind_frame); %当前节点的身子姿势       
        for ind_node = 1:par.Nodes.Num %对各个节点进行遍历
            cur_shadow = shadow_seq(ind_node,((ind_frame-1)*par.MAC.N_Slot+1):(ind_frame*par.MAC.N_Slot)); %当前期间的阴影衰落的值
            %% 更新参数
            % 随机种子，所有节点在不同超帧的随机种子都不同
            rand_seed = rand_state*par.Nodes.Num*N_Frame+ (ind_node-1)*N_Frame+(ind_frame-1);
            % 先使用固定的资源分配来编写节点性能统计函数
            Allocate(ind_node).power = par.PHY.P_min;
            Allocate(ind_node).rate = par.PHY.RateSet(3);
            Allocate(ind_node).slot = zeros(1, par.MAC.N_Slot); %这里用来测试，直接将所有时隙分配给节点
            Allocate(ind_node).slot(1,20:40) =1;
            % 各个节点的基本信息
            Node(ind_node).Sigma = par.Nodes.Sigma(cur_pos,ind_node); % 当前节点在当前身子姿势下的阴影衰落的标准差Sigma
            [ Queue(ind_node).tranQueue, Queue(ind_node).arrivalQueue, Queue(ind_node).bufferQueue, last_end_slot_ind(ind_node)] = nodeTranPerFrame(ind_frame, cur_shadow, last_end_slot_ind(ind_node), Allocate(ind_node), Node(ind_node), par.MAC, par.Channel,par.Constraints, Queue(ind_node).tranQueue, Queue(ind_node).arrivalQueue, Queue(ind_node).bufferQueue, rand_seed);
            
        end
    end
    
    % 性能统计
    QoS = calQosPerformance( Queue, par.MAC);
    
    %% 展示性能表现
    plotQoSPerformance(QoS, Queue);
    
    
   