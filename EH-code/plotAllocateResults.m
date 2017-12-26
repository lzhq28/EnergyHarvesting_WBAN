function  plotAllocateResults( pos_seq, AllocatePowerRate, sta_AllocateSlots)
%plotAllocateResults 将给各个节点的资源分配结果进行展示

    % 基本参数
    num_sample = 100; %采样多少点进行画图
    num_nodes = size(sta_AllocateSlots{1,1},1);    
    num_frame = size(sta_AllocateSlots,2);
    sample_step = 1;
    if num_frame>100
        sample_step = round(num_frame/num_sample);
    end
    %x_range = 1:sample_step:num_frame;
    x_range = 1:1:100;
    %% 统计为各个节点的分配时隙的开始和结束位置
    Allocate_slot = {}; %统计为各个节点的分配时隙的开始和结束位置
    Allocate_power = []; %统计各个节点的分配传输功率
    Allocate_src_rate = []; %统计分配给各个节点的数据速率
    for ind_node =1:num_nodes 
        allocate_slot_begin = [];
        allocate_slot_end = [];
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
    %% 统计各个超帧的传输功率和数据速率
    for ind_node = 1:num_nodes
        for ind_frame =1:num_frame
            cur_pos = pos_seq(1,ind_frame);
            Allocate_power(ind_node,ind_frame) = AllocatePowerRate{cur_pos}{1,ind_node}.power;
            Allocate_src_rate(ind_node,ind_frame) = AllocatePowerRate{cur_pos}{1,ind_node}.src_rate;
        end
    end
    
    %% 将分配结果展示出来      
    color_set = linspecer(num_nodes); % 调用函数linespecer来生成漂亮的颜色 
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

