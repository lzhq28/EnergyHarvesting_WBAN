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
    N_Frame = 15; %实验的总超帧数
    ini_pos = 1; %初始化身体姿势为静止状态
    % 计算所有超帧的姿势序列和每个时隙的阴影衰落
    [shadow_seq, pos_seq] = shadowStatistic( N_Frame, ini_pos, pos_hold_time, par.Nodes, par.Postures, par.MAC, rand_state, slot_or_frame_state);
    
    %% 性能分析
    % 初始化三种不同的队列
    for ind_node = 1:par.Nodes.Num
        Queue(ind_node).tranQueue = []; %数据包传输队列，包含数据包传输的信息:[packetID, gen_frameID, t_gen_offset, tran_frameID, t_tran_offset, t_tran_cost, tran_power, tran_rate, tran_state]
        Queue(ind_node).arrivalQueue = []; %数据包达到队列， [pacektID,frameID,t_gen_offset,packetType]
        Queue(ind_node).bufferQueue = [0,1,1,1e+7]; %缓存状态队列, [frameID, beginIndex, endIndex, residue_energy]
    end   
    Allocate ={}; %初始化资源分配
    Node={}; %初始化各个节点的基本信息
    
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
            Allocate(ind_node).power = par.PHY.P_max;
            Allocate(ind_node).rate = par.PHY.RateSet(3);
            Allocate(ind_node).slot = zeros(1, par.MAC.N_Slot); %这里用来测试，直接将所有时隙分配给节点
            Allocate(ind_node).slot(1,20:40) =1;
            % 各个节点的基本信息
            Node(ind_node).Sigma = par.Nodes.Sigma(cur_pos,ind_node); % 当前节点在当前身子姿势下的阴影衰落的标准差Sigma
            Node(ind_node).PL_Fr = par.Nodes.PL_Fr(ind_node); % PL = PL_Fr + shadow
            Node(ind_node).num_packet_buffer = par.Nodes.num_packet_buffer(ind_node); %节点缓存所能保存数据包的数量            
            Node(ind_node).packet_length = par.Nodes.packet_length(ind_node); 
            Node(ind_node).num_packet_buffer = par.Nodes.num_packet_buffer(ind_node); %缓存所能存储的数据包数量
            Node(ind_node).Nor_SrcRate = par.Nodes.Nor_SrcRates(ind_node);
            %rand('state', rand_seed); %生成随机种子，不同的rand_state对不同的ind_frame产生不重叠的随机序列
            %Node(ind_node).num_packet_Emer = random('poiss',par.Nodes.lambda_Emer(ind_node));
            [ Queue(ind_node).tranQueue, Queue(ind_node).arrivalQueue, Queue(ind_node).bufferQueue, last_end_slot_ind(ind_node)] = nodeTranPerFrame(ind_frame, cur_shadow, last_end_slot_ind(ind_node), Allocate(ind_node), Node(ind_node), par.MAC, par.Channel,par.Constraints, Queue(ind_node).tranQueue, Queue(ind_node).arrivalQueue, Queue(ind_node).bufferQueue, rand_seed)
% % %            %% 配置参数
% % %             tmp_ind = find(Allocate(ind_node).slot == 1);
% % %             first_slot_ind = tmp_ind(1); %分配时隙的开始位置，用于计算各个时隙的丢包率
% % %             end_slot_ind = tmp_ind(end); %所分配时隙的结束位置            
% % %             % 数据包时间：生成时间和传输时间
% % %             tran_time_packet = Node(ind_node).packet_length/Allocate(ind_node).rate; %传输一个包所需要的时间
% % %             gen_time_packet = Node(ind_node).packet_length/Node(ind_node).Nor_SrcRate; %生成一个包所需要的时间
% % %             
% % %             %% 分析数据包到达队列,这里只统计正常包            
% % %             % 正常数据包
% % %             cur_arrival_num_packets = ceil(Node(ind_node).Nor_SrcRate*(end_slot_ind + par.MAC.N_Slot - last_end_slot_ind(ind_node))*par.MAC.T_Slot/Node(ind_node).packet_length);
% % %             tmp_arrival_Queue = zeros(cur_arrival_num_packets,4);
% % %             tmp_arrival_Queue(:,1) = ((1:cur_arrival_num_packets) + size(Queue(ind_node).arrivalQueue,1))'; % 数据包ID-packetID
% % %             last_time_frame = (par.MAC.N_Slot - last_end_slot_ind(ind_node))*par.MAC.T_Slot; %上一超帧所剩余的时间
% % %             for tmp_ind = 1:cur_arrival_num_packets 
% % %                 cur_sum_time = (gen_time_packet * tmp_ind); %要产生当前包所积累的时间
% % %                 next_frame_or_not =(cur_sum_time-last_time_frame)>0; % 该包是否在当前帧产生
% % %                 tmp_arrival_Queue(tmp_ind,2) = ind_frame - 1 + next_frame_or_not; % 超帧ID-frameID
% % %                 tmp_arrival_Queue(tmp_ind,3) = cur_sum_time + last_end_slot_ind(ind_node)*par.MAC.T_Slot - next_frame_or_not * par.MAC.T_Frame; % 数据包在当前超帧中产生的时间(或偏移量)-t_gen_offset
% % %                 %tmp_arrival_Queue(tmp_ind,4) = 0; % 数据包类型-packetType, 值为0表示为普通包，值为1表示为紧急包
% % %             end
% % %             Queue(ind_node).arrivalQueue = [Queue(ind_node).arrivalQueue;tmp_arrival_Queue];
% % %             %% 分析缓存状态队列
% % %             % 需要根据缓存情况来决定是否对节点进行丢弃，并分析未存储的数据包是否超过缓存容量
% % %             % 首先分析数据包是否超时延门限，如果超过时延门限将丢包
% % %             ind_end_buffer = size(Queue(ind_node).arrivalQueue,1); %结束位置
% % %             ind_begin_buffer = Queue(ind_node).bufferQueue(end,2); %读取上一超帧所剩的
% % %             residue_energy = Queue(ind_node).bufferQueue(end,4); %读取上一超帧所剩的能量
% % %             if (ind_end_buffer-ind_begin_buffer) > Node(ind_node).num_packet_buffer %判断当前队列中的数据包是否大于缓存的最大数，如果大于将。
% % %                 tmp_ind_begin_buffer = ind_begin_buffer;
% % %                 ind_begin_buffer = ind_end_buffer - Node(ind_node).num_packet_buffer + 1;
% % %                 tmp_range = tmp_ind_begin_buffer:(ind_begin_buffer-1);
% % %                 tmp_len = size(tmp_range,2);
% % %                 tran_packet_state = 4; %传输状态为1，表示传输成功
% % %                 deletePackets = [Queue(ind_node).arrivalQueue(tmp_range,1:3), repmat(ind_frame,tmp_len,1), zeros(tmp_len,4), repmat(tran_packet_state,tmp_len,1)]; %队列溢出
% % %                 Queue(ind_node).tranQueue=[Queue(ind_node).tranQueue; deletePackets];
% % %             end 
% % %            %% 分析数据包传输队列
% % %             tran_times = floor((end_slot_ind - first_slot_ind+1)*par.MAC.T_Slot.*Allocate(ind_node).rate./Node(ind_node).packet_length); %分配的资源可以传输的次数
% % %             rand('state',rand_seed)            
% % %             rand_PLR = rand(1,tran_times); %产生随机数用来与PLR对比来确定是否丢包
% % %             cur_PLR = calPLR(Allocate(ind_node).power, Allocate(ind_node).rate, Node(ind_node).packet_length, Node(ind_node).PL_Fr, cur_shadow, par.Channel); %计算当前资源下在不同时隙发送时的丢包率     
% % %             if sum(Allocate(ind_node).slot)<=0
% % %                 % return; %移到函数中将取消该注释，因为没有额外的时隙发送数据，因此不能传输数据包，将直接返回
% % %             end
% % %             tmp_tran_packets = [];
% % %             for ind_tran = 1:tran_times
% % %                 cur_ind_slot = ceil(((ind_tran-1)*tran_time_packet+ first_slot_ind*par.MAC.T_Slot)/par.MAC.T_Slot);
% % %                 % 判断缓存中是否还有数据包
% % %                 if ind_begin_buffer > ind_end_buffer
% % %                     break; %当缓存中没有数据包时将跳出循环
% % %                 end
% % %                 % 判断是否有能量传输数据
% % %                 if residue_energy < 0
% % %                     break; % 如果没有能量将会停止传输数据包
% % %                 end
% % %                 %判断数据包是否传输成功,并保存传输信息
% % %                 if cur_PLR(1,cur_ind_slot)<=rand_PLR(ind_tran) % 数据包传输成功
% % %                     tran_packet_state = 1; %传输状态为1，表示传输成功
% % %                     tmp_tran_packets = [ tmp_tran_packets; Queue(ind_node).arrivalQueue(ind_begin_buffer,1:3),ind_frame,cur_ind_slot*par.MAC.T_Slot,tran_time_packet,Allocate(ind_node).power,Allocate(ind_node).rate, tran_packet_state]; %保存传输情况
% % %                     ind_begin_buffer = ind_begin_buffer+1;
% % %                 else %数据包传输失败
% % %                     tran_packet_state = 2; %传输状态为2，表示链路丢包 
% % %                     tmp_tran_packets = [ tmp_tran_packets; Queue(ind_node).arrivalQueue(ind_begin_buffer,1:3),ind_frame,cur_ind_slot*par.MAC.T_Slot,tran_time_packet,Allocate(ind_node).power,Allocate(ind_node).rate, tran_packet_state]; %保存传输情况
% % %                 end
% % %                 residue_energy = residue_energy - Allocate(ind_node).power * tran_time_packet; % 更新剩余能量
% % %             end
% % %             Queue(ind_node).tranQueue = [Queue(ind_node).tranQueue; tmp_tran_packets];
% % %             Queue(ind_node).bufferQueue = [Queue(ind_node).bufferQueue;ind_frame,ind_begin_buffer,ind_end_buffer,residue_energy]; %更新缓存队列
% % %             last_end_slot_ind(ind_node) = end_slot_ind; 
        end
    end
   