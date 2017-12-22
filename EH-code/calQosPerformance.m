function  QoS  = calQosPerformance( Queue, sta_AllocateSlots, MAC, packet_length)
%calQosPerformance ���������������
%����
%   Queue �����ڵ����ܱ���ĸ��ֶ�����Ϣ���������bufferQueue�����ݰ��������arrivalQueue�����ݰ��������tranQueue
%   MAC �����Ϣ����Ҫ���õ���֡�ĳ���
%   ͳ��ÿ����֡����ʱ϶�����
%   packet_length �����ڵ�����ݰ�����, bitΪ��λ

%���
%   QoS �����ڵ�����ܱ��֣�����������PLR��ʱ��Delay

%% �����ķ�ʽ��������ڵ��QoS����
    num_Frames = size(sta_AllocateSlots,2);
    total_sim_time = num_Frames * MAC.T_Frame * 0.001; %������ʱ������λΪs
    for ind_node =1:size(Queue,2)
        % �������������
        sum_num_slot = 0;
        for ind_frame =1:size(sta_AllocateSlots,2)
            sum_num_slot = sum_num_slot + sum(sta_AllocateSlots{ind_frame}(ind_node,:));
        end
        sum_allocate_time = sum_num_slot *MAC.T_Slot;
        sum_use_time = sum(Queue(ind_node).tranQueue(:,6));

        QoS.bandwidth_utilization(ind_node) = sum_use_time/(sum_allocate_time+0.0001)
        ind_suc = find(Queue(ind_node).tranQueue(:,9) ==1);
        ind_pathloss = find(Queue(ind_node).tranQueue(:,9) ==2);
        ind_overdelay = find(Queue(ind_node).tranQueue(:,9) ==3);
        ind_overflow = find(Queue(ind_node).tranQueue(:,9) ==4);
        suc_num = Queue(ind_node).tranQueue(end,1);
        energy_cost = sum(Queue(ind_node).tranQueue(:,6).*Queue(ind_node).tranQueue(:,7));
        % ���㶪���ʣ�ʱ�ӳ��޶������Ŷ���������Լ��ܵĶ���
        QoS.PLR_pathloss(ind_node) = size(ind_pathloss,1)/(suc_num+size(ind_pathloss,1));
        QoS.PLR_overflow(ind_node) = size(ind_overflow,1)/suc_num;
        QoS.PLR_overdelay(ind_node) = size(ind_overdelay,1)/suc_num;
        QoS.PLR_ave(ind_node) = (size(ind_overflow,1)+size(ind_overdelay,1))/suc_num;
        % ����ƽ��ʱ��
        QoS.Delay_ave(ind_node) = mean((Queue(ind_node).tranQueue(:,4) - Queue(ind_node).tranQueue(:,2)).* MAC.T_Frame +  Queue(ind_node).tranQueue(:,5) -  Queue(ind_node).tranQueue(:,3));
        QoS.Energy_cost(ind_node) = energy_cost;
        QoS.total_data(ind_node) = size(ind_suc,1)*packet_length(ind_node);
        QoS.energy_per_bit(ind_node) =  QoS.Energy_cost(ind_node)/ QoS.total_data(ind_node);
        QoS.throughput(ind_node) = QoS.total_data(ind_node)/total_sim_time;
    end
end