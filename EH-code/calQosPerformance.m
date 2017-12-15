function [ QoS ] = calQosPerformance( Queue, MAC, packet_length)
%calQosPerformance 计算服务质量性能
%输入
%   Queue 各个节点性能保存的各种队列信息：缓存队列bufferQueue、数据包到达队列arrivalQueue，数据包传输队列tranQueue
%   MAC 相关信息，主要是用到超帧的长度
%   packet_length 各个节点的数据包长度, bit为单位
%输出
%   QoS 各个节点的性能表现，包括丢包率PLR，时延Delay

%% 遍历的方式计算各个节点的QoS性能
    for ind_node =1:size(Queue,2)
        ind_suc = find(Queue(ind_node).tranQueue(:,9) ==1);
        ind_pathloss = find(Queue(ind_node).tranQueue(:,9) ==2);
        ind_overdelay = find(Queue(ind_node).tranQueue(:,9) ==3);
        ind_overflow = find(Queue(ind_node).tranQueue(:,9) ==4);
        suc_num = Queue(ind_node).tranQueue(end,1);
        energy_cost = sum(Queue(ind_node).tranQueue(:,6).*Queue(ind_node).tranQueue(:,7));
        % 计算丢包率：时延超限丢包和排队溢出丢包以及总的丢包
        QoS(ind_node).PLR_pathloss = size(ind_pathloss,1)/(suc_num+size(ind_pathloss,1));
        QoS(ind_node).PLR_overflow = size(ind_overflow,1)/suc_num;
        QoS(ind_node).PLR_overdelay = size(ind_overdelay,1)/suc_num;
        QoS(ind_node).PLR_ave = (size(ind_overflow,1)+size(ind_overdelay,1))/suc_num;
        % 计算平均时延
        QoS(ind_node).Delay_ave = mean((Queue(ind_node).tranQueue(:,4) - Queue(ind_node).tranQueue(:,2)).* MAC.T_Frame +  Queue(ind_node).tranQueue(:,5) -  Queue(ind_node).tranQueue(:,3));
        QoS(ind_node).Energy_cost = energy_cost;
        QoS(ind_node).total_data = size(ind_suc,1)*packet_length(ind_node);
        QoS(ind_node).energy_per_bit =  QoS(ind_node).Energy_cost/ QoS(ind_node).total_data;
    end
end