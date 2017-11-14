function  plotAllocateResults( pos_seq, AllocatePowerRate, sta_AllocateSlots)
%plotAllocateResults ���������ڵ����Դ����������չʾ

    % ��������
    num_sample = 100; %�������ٵ���л�ͼ
    num_nodes = size(sta_AllocateSlots{1,1},1);    
    num_frame = size(sta_AllocateSlots,2);
    sample_step = 1;
    if num_frame>100
        sample_step = round(num_frame/num_sample);
    end
    x_range = 1:sample_step:num_frame;
    %% ͳ��Ϊ�����ڵ�ķ���ʱ϶�Ŀ�ʼ�ͽ���λ��
    Allocate_slot = {}; %ͳ��Ϊ�����ڵ�ķ���ʱ϶�Ŀ�ʼ�ͽ���λ��
    Allocate_power = []; %ͳ�Ƹ����ڵ�ķ��䴫�书��
    Allocate_src_rate = []; %ͳ�Ʒ���������ڵ����������
    for ind_node =1:num_nodes 
        allocate_slot_begin = []
        allocate_slot_end = []
        tmp_power = [];
        tmp_src_rate = [];
        for ind_frame = 1: num_frame       
            ind = find(sta_AllocateSlots{1, ind_frame}(ind_node,:)==1);
            allocate_slot_begin(ind_frame) = ind(1);
            allocate_slot_end(ind_frame) = ind(end);    
        end
        Allocate_slot{1,ind_node}.begin_slot = allocate_slot_begin;
        Allocate_slot{1,ind_node}.end_slot = allocate_slot_end;
    end
    %% ͳ�Ƹ�����֡�Ĵ��书�ʺ���������
    for ind_node = 1:num_nodes
        for ind_frame =1:num_frame
            cur_pos = pos_seq(1,ind_frame);
            Allocate_power(ind_node,ind_frame) = AllocatePowerRate{cur_pos}{1,ind_node}.power;
            Allocate_src_rate(ind_node,ind_frame) = AllocatePowerRate{cur_pos}{1,ind_node}.src_rate;
        end
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
        plot(x_range, Allocate_power(ind_node,x_range),'-','linewidth',2,'color',color_set(ind_node,:))
    end
    xlabel('Index of superframe')
    ylabel('Allocated transmission power(mw)')
    legend('Node1','Node2','Node3','Node4','Node5')
    subplot(313)
    for ind_node = 1:num_nodes
        hold on 
        plot(x_range, Allocate_src_rate(ind_node,x_range),'-','linewidth',2,'color',color_set(ind_node,:))
    end
    xlabel('Index of superframe')
    ylabel('Source rate (Kbps)')
    legend('Node1','Node2','Node3','Node4','Node5')
end

