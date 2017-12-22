function  analysisQoSPerformance(t_cor_EH,deltaPL,cal_alg_id,cal_myRA_id, EH_ratio)
%analysisQoSPerformance ����ϵͳ�������������������Ҫ�Ǵ��ļ��ж�ȡ
%����
%   t_cor_EH �����ɼ����ʱ��
%   deltaPL ·�����������
%   cal_alg_id �㷨��ID��
%   cal_myRA_id �����㷨��ϸ������
%   EH_ratio �����ɼ����ʵĵȱ�������ϡ��
    % ���ļ��м����м����ݽ��
    [ load_path_name ] = conPathName(t_cor_EH,deltaPL,cal_alg_id,cal_myRA_id, EH_ratio);
    load_data = load(load_path_name);
   
    %% ������ɫ
    num_nodes = size(load_data.Queue,2);
    color_set = linspecer(num_nodes);
    
    
    %% չʾ���ܱ���
    par = initialParameters(deltaPL, EH_ratio, t_cor_EH); %��ʼ��ϵͳ����
    cur_Queue = load_data.Queue;
    cur_QoS = calQosPerformance( cur_Queue, load_data.sta_AllocateSlots,par.MAC, par.Nodes.packet_length);
    plotQoSPerformance(cur_QoS , cur_Queue);
    plotAllocateResults( load_data.pos_seq, load_data.AllocatePowerRate, load_data.sta_AllocateSlots);
    
    %% չʾ��ͬ�ڵ�������ɼ��������ʱ϶����
    cur_pos_seq = load_data.pos_seq;
    cur_EH_status_seq = load_data.EH_status_seq;
    cur_EH_collect_seq = load_data.EH_collect_seq;
    max_length = size(cur_EH_status_seq,2);
    % �����ڸ���ʱ϶�������ɼ�ͼ
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

