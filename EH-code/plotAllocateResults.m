function  plotAllocateResults( sta_Allocate )
%plotAllocateResults ���������ڵ����Դ����������չʾ

    % ��������
    num_sample = 30; %�������ٵ���л�ͼ
    num_nodes = size(sta_Allocate{1,2},2);    
    num_frame = size(sta_Allocate,2);
    sample_step = 1;
    if num_frame>100
        sample_step = round(num_frame/num_sample);
    end
    x_range = 1:sample_step:num_frame;
    %% ͳ��Ϊ�����ڵ�ķ���ʱ϶�Ŀ�ʼ�ͽ���λ��
    Allocate_slot = {}; %ͳ��Ϊ�����ڵ�ķ���ʱ϶�Ŀ�ʼ�ͽ���λ��
    Allocate_power = {}; %ͳ�Ƹ����ڵ�ķ��䴫�书��
    Allocate_src_rate = {}; %ͳ�Ʒ���������ڵ����������
    for ind_node =1:num_nodes 
        allocate_slot_begin = []
        allocate_slot_end = []
        tmp_power = [];
        tmp_src_rate = [];
        for ind_frame = 1: num_frame       
            ind = find(sta_Allocate{1, ind_frame}(1,ind_node).slot==1);
            allocate_slot_begin(ind_frame) = ind(1);
            allocate_slot_end(ind_frame) = ind(end);    
            tmp_power(ind_frame) = sta_Allocate{1, ind_frame}(1,ind_node).power;
            tmp_src_rate(ind_frame) = sta_Allocate{1, ind_frame}(1,ind_node).src_rate;
        end
        Allocate_slot{1,ind_node}.begin_slot = allocate_slot_begin;
        Allocate_slot{1,ind_node}.end_slot = allocate_slot_end;
        Allocate_power{1,ind_node} = tmp_power;
        Allocate_src_rate{1,ind_node} = tmp_src_rate;
    end
    
    %% ��������չʾ����      
    color_set = linspecer(num_nodes); % ���ú���linespecer������Ư������ɫ 
    
    figure
    subplot(311)
    for ind_node = 1:num_nodes
        hold on 
        plot(x_range, Allocate_slot{1,ind_node}.begin_slot(1,x_range),'--','linewidth',2,'color',color_set(ind_node,:))
        hold on
        plot(x_range, Allocate_slot{1,ind_node}.end_slot(1,x_range),'-','linewidth',2,'color',color_set(ind_node,:))
        hold on
    end
    xlabel('Index of superframe')
    ylabel('Index of slots in current superframe')
    subplot(312)
    for ind_node = 1:num_nodes
        hold on 
        plot(x_range, Allocate_power{1,ind_node}(1,x_range),'-','linewidth',2,'color',color_set(ind_node,:))
    end
    xlabel('Index of superframe')
    ylabel('Allocated transmission power(mw)')
    legend('Node1','Node2','Node3','Node4','Node5')
    subplot(313)
    for ind_node = 1:num_nodes
        hold on 
        plot(x_range, Allocate_src_rate{1,ind_node}(1,x_range),'-','linewidth',2,'color',color_set(ind_node,:))
    end
    xlabel('Index of superframe')
    ylabel('Source rate (Kbps)')
    legend('Node1','Node2','Node3','Node4','Node5')
end

