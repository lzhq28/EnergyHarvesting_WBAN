function  analysisQoSPerformance(deltaPL_step, deltaPL_ind_max, show_deltaPL_ind, t_cor_EH)
%analysisQoSPerformance 分析系统服务质量结果，数据主要是从文件中读取
%输入
%   deltaPL_step deltaPL的步长
%   deltaPL_ind_max deltaPL的最大实验次数
%   t_cor_EH 能量采集相关时间
    % 从文件中加载中间数据结果
    %t_cor_EH = par.EnergyHarvest.t_cor_EH
    load_data = {}; %加载的数据
    for deltaPL_ind =1:deltaPL_ind_max
        deltaPL =  (deltaPL_ind-1)*deltaPL_step;
        path_names = configurePaths(t_cor_EH); %各种路径名字
        load_path_name = strcat([path_names.save_prefix,num2str(deltaPL),'.mat']);
        load_data{1,deltaPL_ind}=load(load_path_name);
    end
    % 分析性能
    sta_PLR_pathloss = []; %由路径丢包而丢弃的数据包，但是由于采用重传所以它只表示物理层的丢包，与实际传输的数据包的丢包不一致
    sta_PLR_overflow = [];%统计由排队溢出而丢包
    sta_PLR_overdelay = []; %统计由时延超限出而丢包
    sta_PLR_ave = []; %统计综合考虑排队溢出和时延超限而导致的丢包两种情况
    sta_Delay = []; %统计各个节点的平均丢包
    sta_Energy =[]; %统计消耗的能量
    for deltaPL_ind =1:deltaPL_ind_max
        deltaPL =  (deltaPL_ind-1)*deltaPL_step;
        par = initialParameters(deltaPL); %初始化系统参数
        cur_Queue = load_data{1,deltaPL_ind}.Queue;
        cur_QoS = calQosPerformance( cur_Queue, par.MAC);
        for ind_node = 1:size(cur_QoS,2)
            sta_PLR_pathloss(ind_node,deltaPL_ind) = cur_QoS(ind_node).PLR_pathloss;
            sta_PLR_overflow(ind_node,deltaPL_ind) = cur_QoS(ind_node).PLR_overflow;
            sta_PLR_overdelay(ind_node,deltaPL_ind) = cur_QoS(ind_node).PLR_overdelay;
            sta_PLR_ave(ind_node,deltaPL_ind) = cur_QoS(ind_node).PLR_ave;
            sta_Delay(ind_node,deltaPL_ind) = cur_QoS(ind_node).Delay_ave;
            sta_Energy(ind_node,deltaPL_ind) = cur_QoS(ind_node).Energy_cost;
        end
    end
    
    %% 配置颜色
    num_nodes = size(sta_Delay,1);
    color_set = linspecer(num_nodes);
    
    %% 画出仿真结果
    x_range = (0:deltaPL_ind_max-1)*deltaPL_step;
    figure
    subplot(221)
    for ind_node = 1:num_nodes
        hold on
        plot(x_range,sta_Energy(ind_node,:),'-','linewidth',2,'color',color_set(ind_node,:))
    end
    grid on
    xlabel('\mu_{s} of shadow')
    ylabel('Energy cost (uJ)')
    title('Energy cost')
    legend('Node1','Node2','Node3','Node4','Node5')
    subplot(222)
    for ind_node = 1:num_nodes
        hold on
        plot(x_range,sta_PLR_overflow(ind_node,:)*100,'-','linewidth',2,'color',color_set(ind_node,:))
    end
    grid on
    xlabel('\mu_{s} of shadow')
    ylabel('average PLR (%)')
    title('PLR due to overflow')
    legend('Node1','Node2','Node3','Node4','Node5')
    subplot(223)
    for ind_node = 1:num_nodes
        hold on
        plot(x_range,sta_PLR_overdelay(ind_node,:)*100,'-','linewidth',2,'color',color_set(ind_node,:))
    end
    grid on
    axis([0 20 0 6]) 
    xlabel('\mu_{s} of shadow')
    ylabel('average PLR (%)')
    title('PLR due to exceed delay threshold')
    legend('Node1','Node2','Node3','Node4','Node5')
    subplot(224)
    for ind_node = 1:num_nodes
        hold on
        plot(x_range,sta_Delay(ind_node,:),'-','linewidth',2,'color',color_set(ind_node,:))
    end
    grid on
    axis([0 20 0 600]) 
    xlabel('\mu_{s} of shadow')
    ylabel('Delay of packets (ms)')
    title('Average packet delay')
    legend('Node1','Node2','Node3','Node4','Node5')
    
    %% 展示性能表现
    %show_deltaPL_ind =10;
    deltaPL =  (show_deltaPL_ind -1)*deltaPL_step;
    par = initialParameters(deltaPL); %初始化系统参数
    cur_Queue = load_data{1,show_deltaPL_ind}.Queue;
    cur_QoS = calQosPerformance( cur_Queue, par.MAC);
    plotQoSPerformance(cur_QoS , cur_Queue);
    plotAllocateResults( load_data{1,show_deltaPL_ind}.pos_seq, load_data{1,show_deltaPL_ind}.AllocatePowerRate, load_data{1,show_deltaPL_ind}.sta_AllocateSlots);
    
    % 展示不同节点的能量采集情况，与时隙对齐
    cur_pos_seq = load_data{1,show_deltaPL_ind}.pos_seq;
    cur_EH_status_seq = load_data{1,show_deltaPL_ind}.EH_status_seq;
    cur_EH_collect_seq = load_data{1,show_deltaPL_ind}.EH_collect_seq;
    % 画出在各个时隙的能量采集图
    figure
    subplot(211)
    for ind_node = 1:num_nodes
        hold on
        plot(cur_EH_status_seq(ind_node,12000:15800),'-','linewidth',2,'color',color_set(ind_node,:))
    end
    xlabel('Index of slots')
    ylabel('Energy Harvest Status (1:ON, 2:OFF)')
    title('Energy Harvest Status (1:ON, 2:OFF)')
    legend('Node1','Node2','Node3','Node4','Node5')
    subplot(212)
    for ind_node = 1:num_nodes
        hold on
        plot(cur_EH_collect_seq(ind_node,12000:15800),'-','linewidth',2,'color',color_set(ind_node,:))
    end
    grid on
    xlabel('Index of slots')
    ylabel('Collected energy in each slot (uJ)')
    title('Collect energy in each slot')
    legend('Node1','Node2','Node3','Node4','Node5')
end

