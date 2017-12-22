function  analysisQoSPerformance(t_cor_EH,deltaPL,cal_alg_id,cal_myRA_id, EH_ratio)
%analysisQoSPerformance 分析系统服务质量结果，数据主要是从文件中读取
%输入
%   t_cor_EH 能量采集相干时间
%   deltaPL 路径损耗增加量
%   cal_alg_id 算法的ID号
%   cal_myRA_id 本文算法的细节配置
%   EH_ratio 能量采集速率的等比例调节稀疏
    % 从文件中加载中间数据结果
    [ load_path_name ] = conPathName(t_cor_EH,deltaPL,cal_alg_id,cal_myRA_id, EH_ratio);
    load_data = load(load_path_name);
   
    %% 配置颜色
    num_nodes = size(load_data.Queue,2);
    color_set = linspecer(num_nodes);
    
    
    %% 展示性能表现
    par = initialParameters(deltaPL, EH_ratio, t_cor_EH); %初始化系统参数
    cur_Queue = load_data.Queue;
    cur_QoS = calQosPerformance( cur_Queue, load_data.sta_AllocateSlots,par.MAC, par.Nodes.packet_length);
    plotQoSPerformance(cur_QoS , cur_Queue);
    plotAllocateResults( load_data.pos_seq, load_data.AllocatePowerRate, load_data.sta_AllocateSlots);
    
    %% 展示不同节点的能量采集情况，与时隙对齐
    cur_pos_seq = load_data.pos_seq;
    cur_EH_status_seq = load_data.EH_status_seq;
    cur_EH_collect_seq = load_data.EH_collect_seq;
    max_length = size(cur_EH_status_seq,2);
    % 画出在各个时隙的能量采集图
    figure
    subplot(211)
    for ind_node = 1:num_nodes
        hold on
        plot(cur_EH_status_seq(ind_node,:),'-','linewidth',2,'color',color_set(ind_node,:))
    end
    xlabel('Index of slots')
    ylabel('Energy Harvest Status (1:ON, 2:OFF)')
    title('Energy Harvest Status (1:ON, 2:OFF)')
    legend('Node1','Node2','Node3','Node4','Node5')
    subplot(212)
    for ind_node = 1:num_nodes
        hold on
        plot(cur_EH_collect_seq(ind_node,:),'-','linewidth',2,'color',color_set(ind_node,:))
    end
    grid on
    xlabel('Index of slots')
    ylabel('Collected energy in each slot (uJ)')
    title('Collect energy in each slot')
    legend('Node1','Node2','Node3','Node4','Node5')
end

