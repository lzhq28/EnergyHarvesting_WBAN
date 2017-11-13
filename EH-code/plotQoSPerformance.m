function plotQoSPerformance( QoS, Queue )
%plotQoSPerformance ��ʾQoS���ܽ��
%���룺
%   QoS �����ڵ�����ܱ���
%   Queue �����ڵ������

    %% ���ú���linespecer������Ư������ɫ
    color_set = linspecer(size(Queue,2));
    num_sample = 30; %�������ٵ���л�ͼ

     %% չʾ�ڵ�Ļ���ı仯������������ݰ��������������
    figure
    subplot(321) 
    num_frame = size(Queue(1).bufferQueue,1) -1;
    sample_step = 1;
    if num_frame>100
        sample_step = round(num_frame/num_sample);
    end
    x_range = 1:sample_step:num_frame;
    for ind_node = 1:size(Queue,2)
        hold on
        plot(x_range,Queue(ind_node).bufferQueue(x_range+1,4),'-','linewidth',2,'color',color_set(ind_node,:))
    end
    grid on
    xlabel('Index of superframe')
    ylabel('Residue energy (uJ)')
    legend('Node1','Node2','Node3','Node4','Node5')
    for ind_node = 1:size(Queue,2)
        subplot(3,2,ind_node+1)
        y = (Queue(ind_node).bufferQueue(x_range+1,3) - Queue(ind_node).bufferQueue(x_range+1,2)+1);
        b = bar(x_range,y,1);
        b.FaceColor = color_set(ind_node,:);
        grid on
        xlabel('Index of superframe')
        ylabel('Number of packets in buffer')
        title(strcat(['Node',num2str(ind_node)]))
    end

end

