function [ tranQueue, arrivalQueue, bufferQueue, last_end_slot_ind] = nodeTranPerFrame(cur_ind_frame, cur_shadow, cur_EH_collect, last_end_slot_ind, Allocate, Node, MAC, Channel, Constraints, tranQueue, arrivalQueue, bufferQueue, rand_seed)
%nodeTranPerFrame 每个节点在所分配的资源的条件下的数据传输情况
%输入：
%   cur_ind_frame 当前超帧的索引号
%   cur_shadow 当前节点在当前超帧各个时隙内的阴影衰落
%   cur_EH_collect 从上一超帧分配时隙结束位置后的时隙开始该节点在各个时隙中的能量采集值
%   last_end_slot_ind 上一超帧分配时隙的末尾位置
%   tranQueue 数据包传输队列，包含数据包传输的信息
%   arrivalQueue 数据包达到队列
%   bufferQueue 缓存状态队列
%   Allocation 所分配的额资源，包括传输功率，船速速率，   
%   Node 节点的基本信息，包括数据包到达情况、数据包长度、节点的信道情况（sigma）
%   MAC MAC层相关参数
%   Channel 信道相关参数
%   Constraints 数据包服务质量约束等
%   tranQueue 数据包传输队列
%   arrivalQueue 数据包到达队列
%   bufferQueue 缓存状态队列
%输出：
%   tranQueue 数据包传输队列
%   arrivalQueue 数据包到达队列
%   bufferQueue 缓存状态队列  
%   last_end_slot_ind 上一超帧分配时隙的末尾位置

   %% 判断是否有时隙资源
    if sum(Allocate.slot)<=0
        first_slot_ind = MAC.N_Slot; %分配时隙的开始位置，用于计算各个时隙的丢包率
        end_slot_ind = MAC.N_Slot; %所分配时隙的结束位置           
    else
        tmp_ind = find(Allocate.slot == 1);
        first_slot_ind = tmp_ind(1); %分配时隙的开始位置，用于计算各个时隙的丢包率
        end_slot_ind = tmp_ind(end); %所分配时隙的结束位置  
    end       
    % 数据包时间：生成时间和传输时间
    tran_time_packet = Node.packet_length/Node.tranRate; %传输一个包所需要的时间
    gen_time_packet = Node.packet_length/Allocate.src_rate; %生成一个包所需要的时间
    
    %% 分析数据包到达队列,这里只统计正常包            
    cur_arrival_num_packets = ceil(Allocate.src_rate * (end_slot_ind + MAC.N_Slot - last_end_slot_ind)*MAC.T_Slot/Node.packet_length);
    tmp_arrival_Queue = zeros(cur_arrival_num_packets,4);
    tmp_arrival_Queue(:,1) = ((1:cur_arrival_num_packets) + size(arrivalQueue,1))'; % 数据包ID-packetID
    last_time_frame = (MAC.N_Slot - last_end_slot_ind)*MAC.T_Slot; %上一超帧所剩余的时间
    for tmp_ind = 1:cur_arrival_num_packets 
        cur_sum_time = min((gen_time_packet * tmp_ind),(end_slot_ind + MAC.N_Slot - last_end_slot_ind - tran_time_packet)*MAC.T_Slot); %要产生当前包所积累的时间     
        next_frame_or_not =(cur_sum_time-last_time_frame)>0; % 该包是否在当前帧产生
        tmp_arrival_Queue(tmp_ind,2) = cur_ind_frame - 1 + next_frame_or_not; % 超帧ID-frameID
        tmp_arrival_Queue(tmp_ind,3) = cur_sum_time + last_end_slot_ind*MAC.T_Slot - next_frame_or_not * MAC.T_Frame; % 数据包在当前超帧中产生的时间(或偏移量)-t_gen_offset
        %tmp_arrival_Queue(tmp_ind,4) = 0; % 数据包类型-packetType, 值为0表示为普通包，值为1表示为紧急包
    end
    arrivalQueue = [arrivalQueue;tmp_arrival_Queue];

    %% 分析缓存状态队列
    % 需要根据缓存情况来决定是否对节点进行丢弃，并分析未存储的数据包是否超过缓存容量
    % 首先分析数据包是否超时延门限，如果超过时延门限将丢包
    ind_end_buffer = size(arrivalQueue,1); %结束位置
    ind_begin_buffer = bufferQueue(end,2); %读取上一超帧所剩的
    residue_energy = bufferQueue(end,4); %读取上一超帧所剩的能量
    tmp_ind_begin_buffer = ind_begin_buffer;
    if (ind_end_buffer-ind_begin_buffer) > Node.num_packet_buffer %判断当前队列中的数据包是否大于缓存的最大数。
        ind_begin_buffer = ind_end_buffer - Node.num_packet_buffer + 1;
        tmp_range = tmp_ind_begin_buffer:(ind_begin_buffer-1);
        tmp_len = size(tmp_range,2);
        tran_packet_state = 4; %传输状态为1，表示传输成功
        deletePackets = [arrivalQueue(tmp_range,1:3), repmat(cur_ind_frame,tmp_len,1), zeros(tmp_len,4), repmat(tran_packet_state,tmp_len,1)]; %队列溢出
        tranQueue=[tranQueue; deletePackets];
    end 
    % 检测是否有队列中的数据包的时延超过门限
    tmp_ind_begin_buffer = ind_begin_buffer;
    count_overdelay = 0;
    for ind_overdelay = ind_begin_buffer:ind_end_buffer
        cur_delay = (cur_ind_frame - arrivalQueue(ind_overdelay,2))*MAC.T_Frame + first_slot_ind*MAC.T_Slot - arrivalQueue(ind_overdelay,3);
        if cur_delay > Constraints.Nor_Delay_th
            count_overdelay = count_overdelay +1;
        else
            break;
        end
    end
    ind_begin_buffer = ind_begin_buffer + count_overdelay;
    overdelay_range = tmp_ind_begin_buffer:(ind_begin_buffer-1);
    tmp_len = size(overdelay_range,2);
    tran_packet_state = 3; %传输状态为3，表示时延超过门限而丢弃
    deletePackets = [arrivalQueue(overdelay_range,1:3),repmat(cur_ind_frame,tmp_len,1), zeros(tmp_len,4), repmat(tran_packet_state,tmp_len,1)]; %时延超限丢弃
    tranQueue=[tranQueue; deletePackets];
    
    % 如果没有分配时隙，将跳出循环
    if sum(Allocate.slot)<=0
        sum_EH_collect = sum(cur_EH_collect); %这段时间内采集到的能量
        residue_energy = residue_energy + sum_EH_collect; %更新剩余能量
        bufferQueue = [bufferQueue;cur_ind_frame,ind_begin_buffer,ind_end_buffer,residue_energy]; %更新缓存队列
        last_end_slot_ind = end_slot_ind; %时隙末尾位置   
        disp(['Warn：没有分配时隙，跳出传输过程。'])
        return;%因为没有分配时隙发送数据，因此不能传输数据包，将直接返回
    end
   %% 分析数据包传输队列
    tran_times = floor((end_slot_ind - first_slot_ind+1)*MAC.T_Slot.*Node.tranRate./Node.packet_length); %分配的资源可以传输的次数
    rand('state',rand_seed)            
    rand_PLR = rand(1,tran_times); %产生随机数用来与PLR对比来确定是否丢包
    cur_PLR = calPLR(Allocate.power, Node.tranRate, Node.packet_length, Node.PL_Fr, cur_shadow, Channel); %计算当前资源下在不同时隙发送时的丢包率     
    if sum(Allocate.slot)<=0
        % return; %移到函数中将取消该注释，因为没有额外的时隙发送数据，因此不能传输数据包，将直接返回
    end
    tmp_tran_packets = [];
    % 传输前先更新能量
    end_offset = first_slot_ind - 1 + MAC.N_Slot - last_end_slot_ind;
    sum_EH_collect = sum(cur_EH_collect(1,1:end_offset)); %这段时间内采集到的能量
    residue_energy = residue_energy + sum_EH_collect; %更新剩余能量
    cur_ind_slot = first_slot_ind; %初始化当前时刻的时隙索引
    for ind_tran = 1:tran_times
        cur_ind_slot = ceil(((ind_tran-1)*tran_time_packet+ first_slot_ind*MAC.T_Slot)/MAC.T_Slot);
        % 判断缓存中是否还有数据包
        if ind_begin_buffer > ind_end_buffer
            break; %当缓存中没有数据包时将跳出循环
        end
        % 更新剩余能量     
        cur_offset = cur_ind_slot + MAC.N_Slot - last_end_slot_ind;
        sum_EH_collect = sum(cur_EH_collect(1,(end_offset+1):(cur_offset-1))); %这段时间内采集到的能量
        end_offset = cur_offset-1;
        residue_energy = residue_energy + sum_EH_collect; %更新剩余能量
        % 判断剩余能量传输数据是否足够传输一个数据包
        if residue_energy < Allocate.power * tran_time_packet
            continue; % 如果没有能量将会停止此次传输，继续采集能量，等待下次发送数据
        end
        %判断数据包是否传输成功,并保存传输信息
        if cur_PLR(1,cur_ind_slot)<=rand_PLR(ind_tran) % 数据包传输成功
            tran_packet_state = 1; %传输状态为1，表示传输成功
            tmp_tran_packets = [ tmp_tran_packets; arrivalQueue(ind_begin_buffer,1:3),cur_ind_frame,cur_ind_slot*MAC.T_Slot,tran_time_packet,Allocate.power,Node.tranRate, tran_packet_state]; %保存传输情况
            ind_begin_buffer = ind_begin_buffer+1;
        else %数据包传输失败
            tran_packet_state = 2; %传输状态为2，表示链路丢包 
            tmp_tran_packets = [ tmp_tran_packets; arrivalQueue(ind_begin_buffer,1:3),cur_ind_frame,cur_ind_slot*MAC.T_Slot,tran_time_packet,Allocate.power,Node.tranRate, tran_packet_state]; %保存传输情况
        end
        residue_energy = residue_energy - Allocate.power * tran_time_packet; % 更新剩余能量
    end
    sum_EH_collect = sum(cur_EH_collect(1,(end_offset+1):(end_slot_ind + MAC.N_Slot - last_end_slot_ind))); %这段时间内采集到的能量
    residue_energy = residue_energy + sum_EH_collect; %更新剩余能量
    tranQueue = [tranQueue; tmp_tran_packets];
    bufferQueue = [bufferQueue;cur_ind_frame,ind_begin_buffer,ind_end_buffer,residue_energy]; %更新缓存队列
    last_end_slot_ind = end_slot_ind; %时隙末尾位置
end

