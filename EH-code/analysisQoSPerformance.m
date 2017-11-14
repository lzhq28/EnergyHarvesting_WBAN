function  analysisQoSPerformance(deltaPL_step, deltaPL_ind_max)
%analysisQoSPerformance ����ϵͳ�������������������Ҫ�Ǵ��ļ��ж�ȡ
%����
%   deltaPL_step deltaPL�Ĳ���
%   deltaPL_ind_max deltaPL�����ʵ�����

    % ���ļ��м����м����ݽ��
    load_data = {}; %���ص�����
    for deltaPL_ind =1:deltaPL_ind_max
        deltaPL =  (deltaPL_ind-1)*deltaPL_step;
        path_names = configurePaths(); %����·������
        load_path_name = strcat([path_names.save_prefix,num2str(deltaPL),'.mat']);
        load_data{1,deltaPL_ind}=load(load_path_name);
    end
    % ��������
    sta_PLR_pathloss = []; %��·�����������������ݰ����������ڲ����ش�������ֻ��ʾ�����Ķ�������ʵ�ʴ�������ݰ��Ķ�����һ��
    sta_PLR_overflow = [];%ͳ�����Ŷ����������
    sta_PLR_overdelay = []; %ͳ����ʱ�ӳ��޳�������
    sta_PLR_ave = []; %ͳ���ۺϿ����Ŷ������ʱ�ӳ��޶����µĶ����������
    sta_Delay = []; %ͳ�Ƹ����ڵ��ƽ������
    sta_Energy =[]; %ͳ�����ĵ�����
    for deltaPL_ind =1:deltaPL_ind_max
        deltaPL =  (deltaPL_ind-1)*deltaPL_step;
        par = initialParameters(deltaPL); %��ʼ��ϵͳ����
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
    
    %% ����������
    num_nodes = size(sta_Delay,1);
    color_set = linspecer(num_nodes);
    x_range = (0:deltaPL_ind_max-1)*deltaPL_step
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
    
    %% չʾ���ܱ���
    show_deltaPL_ind =1;
    deltaPL =  (show_deltaPL_ind -1)*deltaPL_step;
    par = initialParameters(deltaPL); %��ʼ��ϵͳ����
    cur_Queue = load_data{1,deltaPL_ind}.Queue;
    cur_QoS = calQosPerformance( cur_Queue, par.MAC);
    plotQoSPerformance(cur_QoS , cur_Queue);
    plotAllocateResults( load_data{1,deltaPL_ind}.pos_seq, load_data{1,deltaPL_ind}.AllocatePowerRate, load_data{1,deltaPL_ind}.sta_AllocateSlots);
end

