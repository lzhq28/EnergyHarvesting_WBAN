function [ QoS ] = calQosPerformance( Queue, MAC, packet_length)
%calQosPerformance ���������������
%����
%   Queue �����ڵ����ܱ���ĸ��ֶ�����Ϣ���������bufferQueue�����ݰ��������arrivalQueue�����ݰ��������tranQueue
%   MAC �����Ϣ����Ҫ���õ���֡�ĳ���
%   packet_length �����ڵ�����ݰ�����, bitΪ��λ
%���
%   QoS �����ڵ�����ܱ��֣�����������PLR��ʱ��Delay

%% �����ķ�ʽ��������ڵ��QoS����
    for ind_node =1:size(Queue,2)
        ind_suc = find(Queue(ind_node).tranQueue(:,9) ==1);
        ind_pathloss = find(Queue(ind_node).tranQueue(:,9) ==2);
        ind_overdelay = find(Queue(ind_node).tranQueue(:,9) ==3);
        ind_overflow = find(Queue(ind_node).tranQueue(:,9) ==4);
        suc_num = Queue(ind_node).tranQueue(end,1);
        energy_cost = sum(Queue(ind_node).tranQueue(:,6).*Queue(ind_node).tranQueue(:,7));
        % ���㶪���ʣ�ʱ�ӳ��޶������Ŷ���������Լ��ܵĶ���
        QoS(ind_node).PLR_pathloss = size(ind_pathloss,1)/(suc_num+size(ind_pathloss,1));
        QoS(ind_node).PLR_overflow = size(ind_overflow,1)/suc_num;
        QoS(ind_node).PLR_overdelay = size(ind_overdelay,1)/suc_num;
        QoS(ind_node).PLR_ave = (size(ind_overflow,1)+size(ind_overdelay,1))/suc_num;
        % ����ƽ��ʱ��
        QoS(ind_node).Delay_ave = mean((Queue(ind_node).tranQueue(:,4) - Queue(ind_node).tranQueue(:,2)).* MAC.T_Frame +  Queue(ind_node).tranQueue(:,5) -  Queue(ind_node).tranQueue(:,3));
        QoS(ind_node).Energy_cost = energy_cost;
        QoS(ind_node).total_data = size(ind_suc,1)*packet_length(ind_node);
        QoS(ind_node).energy_per_bit =  QoS(ind_node).Energy_cost/ QoS(ind_node).total_data;
    end
end