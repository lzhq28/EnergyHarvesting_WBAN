function plotQoSPerformance( cur_QoS, cur_Queue )
%plotQoSPerformance ��ʾQoS���ܽ��
%���룺
%   cur_QoS �����ڵ�����ܱ���
%   cur_Queue �����ڵ������

    %% ���ú���linespecer������Ư������ɫ
    color_set = linspecer(size(cur_Queue,2));
    num_sample = 30; %�������ٵ���л�ͼ
    %% չʾ�����ڵ�����ܱ���
    figure
    subplot(321)
    bar(cur_QoS.PLR_ave*100)
    xlabel('Node index')
    ylabel('Average PLR (%)')
    subplot(322)
    bar(cur_QoS.Delay_ave)
    xlabel('Node index')
    ylabel('Average delay (ms)')
    subplot(323)
    bar(cur_QoS.throughput)
    xlabel('Node index')
    ylabel('Throughput (bit/s)')
    subplot(324)
    bar(cur_QoS.energy_per_bit)
    xlabel('Node index')
    ylabel('Energy per bit (uJ)')
    subplot(325)
    bar(cur_QoS.bandwidth_utilization*100)
    xlabel('Node index')
    ylabel('Bandwidth utilization (%)')
    subplot(326)
    bar(cur_QoS.Energy_cost)
    xlabel('Node index')
    ylabel('Energy cost (uJ)')
    
     %% չʾ�ڵ�Ļ���ı仯������������ݰ��������������
    figure
    subplot(321) 
    num_frame = size(cur_Queue(1).bufferQueue,1) -1;
    sample_step = 1;
    if num_frame>100
        sample_step = round(num_frame/num_sample);
    end
    x_range = 1:sample_step:num_frame;
    for ind_node = 1:size(cur_Queue,2)
        hold on
        plot(x_range,cur_Queue(ind_node).bufferQueue(x_range+1,4),'-','linewidth',2,'color',color_set(ind_node,:))
    end
    grid on
    xlabel('Index of superframe')
    ylabel('Residue energy (uJ)')
    legend('Node1','Node2','Node3','Node4','Node5')
    for ind_node = 1:size(cur_Queue,2)
        subplot(3,2,ind_node+1)
        y = (cur_Queue(ind_node).bufferQueue(x_range+1,3) - cur_Queue(ind_node).bufferQueue(x_range+1,2)+1);
        b = bar(x_range,y,1);
        b.FaceColor = color_set(ind_node,:);
        grid on
        xlabel('Index of superframe')
        ylabel('Number of packets in buffer')
        title(strcat(['Node',num2str(ind_node)]))
    end    
end

