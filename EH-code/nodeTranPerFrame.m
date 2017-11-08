function [ tranQueue, arrivalQueue, bufferQueue ] = nodeTranPerFrame(cur_ind_frame, cur_shadow, residue_energy, Allocate, Node, MAC, Constraints, tranQueue, arrivalQueue, bufferQueue, rand_seed)
%nodeTranPerFrame 每个节点在所分配的资源的条件下的数据传输情况
%输入：
%   cur_ind_frame 当前超帧的索引号
%   cur_shadow 当前节点在当前超帧各个时隙内的阴影衰落
%   residue_energy 节点剩余能量
%   last_end_slot_ind 上一超帧分配时隙的末尾位置
%   tranQueue 数据包传输队列，包含数据包传输的信息
%   arrivalQueue 数据包达到队列
%   bufferQueue 缓存状态队列
%   Allocation 所分配的额资源，包括传输功率，船速速率，   
%   Node 节点的基本信息，包括数据包到达情况、数据包长度、节点的信道情况（sigma）
%   MAC MAC层相关参数
%   Constraints 数据包服务质量约束等
%   tranQueue 数据包传输队列
%   arrivalQueue 数据包到达队列
%   bufferQueue 缓存状态队列
%输出：
%   tranQueue 数据包传输队列
%   arrivalQueue 数据包到达队列
%   bufferQueue 缓存状态队列  

    % 基本参数
    tmp_ind = find(Allocate.slot == 1);
    first_slot_ind = tmp_ind(1); %分配时隙的开始位置，用于计算各个时隙的丢包率
    end_slot_ind = tmp_ind(end); %所分配时隙的结束位置
    % 数据包时间：生成时间和传输时间
    tran_time_packet = Node.packet_length/Allocate.rate; %传输一个包所需要的时间
    gen_time_packet = Node.packet_length/Node.Nor_SrcRate; %生成一个包所需要的时间
    
    %% 分析数据包到达队列,这里只统计正常包          
    % 正常数据包
    cur_arrival_num_packets = ceil(Node.Nor_SrcRate*(end_slot_ind + MAC.N_Slot - last_end_slot_ind)*MAC.T_Slot/Node.packet_length);
    tmp_arrival_Queue = zeros(cur_arrival_num_packets,4);
    tmp_arrival_Queue(:,1) = ((1:cur_arrival_num_packets) + size(arrivalQueue,1))'; % 数据包ID-packetID
    last_time_frame = (MAC.N_Slot - last_end_slot_ind)*MAC.T_Slot; %上一超帧所剩余的时间
    for tmp_ind = 1:cur_arrival_num_packets 
        cur_sum_time = (gen_time_packet * tmp_ind); %要产生当前包所积累的时间
        next_frame_or_not =(cur_sum_time-last_time_frame)>0; % 该包是否在当前帧产生
        tmp_arrival_Queue(tmp_ind,2) = cur_ind_frame - 1 + next_frame_or_not; % 超帧ID-frameID
        tmp_arrival_Queue(tmp_ind,3) = cur_sum_time - next_frame_or_not * last_time_frame; % 数据包在当前超帧中产生的时间(或偏移量)-t_gen_offset
        %tmp_arrival_Queue(tmp_ind,4) = 0; % 数据包类型-packetType, 值为0表示为普通包，值为1表示为紧急包
    end
    arrivalQueue = [arrivalQueue;tmp_arrival_Queue];
    
    %% 分析缓存状态队列
    % 需要根据缓存情况来决定是否对节点进行丢弃，并分析未存储的数据包是否超过缓存容量
    % 首先分析数据包是否超时延门限，如果超过时延门限将丢包
    ind_end_buffer = size(arrivalQueue,1); %结束位置
    ind_begin_buffer = bufferQueue(end,2); %读取上一超帧所剩的
    if (ind_end_buffer-ind_begin_buffer) > Node(ind_node).num_packet_buffer %判断当前队列中的数据包是否大于缓存的最大数，如果大于将。
        tmp_ind_begin_buffer = ind_begin_buffer;
        ind_begin_buffer = ind_end_buffer - Node(ind_node).num_packet_buffer + 1;
        tmp_range = tmp_ind_begin_buffer:(ind_begin_buffer-1);
        tmp_len = size(tmp_range,2);
        tran_packet_state = 4; %传输状态为1，表示传输成功
        deletePackets = [arrivalQueue(tmp_range,1:3), repmat(cur_ind_frame,tmp_len,1), zeros(tmp_len,4), repmat(tran_packet_state,tmp_len,1)]; %队列溢出
        tranQueue=[tranQueue; deletePackets];
    end
    
    %% 分析数据包传输队列
    tran_times = floor((end_slot_ind + MAC.N_Slot - last_end_slot_ind)*MAC.T_Slot.*Allocate(ind_node).rate./Node(ind_node).packet_length); %分配的资源可以传输的次数
    rand('state',rand_seed)            
    rand_PLR = rand(1,tran_times); %产生随机数用来与PLR对比来确定是否丢包
    cur_PLR = calPLR(Allocate(ind_node).power, Allocate(ind_node).rate, Node(ind_node).packet_length, Node(ind_node).PL_Fr, cur_shadow, Channel); %计算当前资源下在不同时隙发送时的丢包率     
    if sum(Allocate(ind_node).slot)<=0
        % return; %移到函数中将取消该注释，因为没有额外的时隙发送数据，因此不能传输数据包，将直接返回
    end
    tmp_tran_packets = [];
    for ind_tran = 1:tran_times
        cur_ind_slot = ceil(((ind_tran-1)*tran_time_packet+ first_slot_ind*MAC.T_Slot)/MAC.T_Slot);
        % 判断缓存中是否还有数据包
        if ind_begin_buffer > ind_end_buffer
            break; %当缓存中没有数据包时将跳出循环
        end
        %判断数据包是否传输成功,并保存传输信息
        if cur_PLR(1,cur_ind_slot)<=rand_PLR(ind_tran) % 数据包传输成功
            tran_packet_state = 1; %传输状态为1，表示传输成功
            tmp_tran_packets = [ tmp_tran_packets; arrivalQueue(ind_begin_buffer,1:3),cur_ind_frame,cur_ind_slot*MAC.T_Slot,tran_time_packet,Allocate(ind_node).power,Allocate(ind_node).rate, tran_packet_state]; %保存传输情况
            ind_begin_buffer = ind_begin_buffer+1;
        else %数据包传输失败
            tran_packet_state = 2; %传输状态为2，表示链路丢包 
            tmp_tran_packets = [ tmp_tran_packets; arrivalQueue(ind_begin_buffer,1:3),cur_ind_frame,cur_ind_slot*MAC.T_Slot,tran_time_packet,Allocate(ind_node).power,Allocate(ind_node).rate, tran_packet_state]; %保存传输情况
        end
    end
    tranQueue = [tranQueue; tmp_tran_packets];
    bufferQueue = [bufferQueue;cur_ind_frame,ind_begin_buffer,ind_end_buffer]; %更新缓存队列
end

