function [ tranQueue, arrivalQueue, bufferQueue ] = nodeTranPerFrame(cur_ind_frame, cur_shadow, residue_energy, Allocate, Node, MAC, Constraints, tranQueue, arrivalQueue, bufferQueue, rand_seed)
%nodeTranPerFrame ÿ���ڵ������������Դ�������µ����ݴ������
%���룺
%   cur_ind_frame ��ǰ��֡��������
%   cur_shadow ��ǰ�ڵ��ڵ�ǰ��֡����ʱ϶�ڵ���Ӱ˥��
%   residue_energy �ڵ�ʣ������
%   last_end_slot_ind ��һ��֡����ʱ϶��ĩβλ��
%   tranQueue ���ݰ�������У��������ݰ��������Ϣ
%   arrivalQueue ���ݰ��ﵽ����
%   bufferQueue ����״̬����
%   Allocation ������Ķ���Դ���������书�ʣ��������ʣ�   
%   Node �ڵ�Ļ�����Ϣ���������ݰ�������������ݰ����ȡ��ڵ���ŵ������sigma��
%   MAC MAC����ز���
%   Constraints ���ݰ���������Լ����
%   tranQueue ���ݰ��������
%   arrivalQueue ���ݰ��������
%   bufferQueue ����״̬����
%�����
%   tranQueue ���ݰ��������
%   arrivalQueue ���ݰ��������
%   bufferQueue ����״̬����  

    % ��������
    tmp_ind = find(Allocate.slot == 1);
    first_slot_ind = tmp_ind(1); %����ʱ϶�Ŀ�ʼλ�ã����ڼ������ʱ϶�Ķ�����
    end_slot_ind = tmp_ind(end); %������ʱ϶�Ľ���λ��
    % ���ݰ�ʱ�䣺����ʱ��ʹ���ʱ��
    tran_time_packet = Node.packet_length/Allocate.rate; %����һ��������Ҫ��ʱ��
    gen_time_packet = Node.packet_length/Node.Nor_SrcRate; %����һ��������Ҫ��ʱ��
    
    %% �������ݰ��������,����ֻͳ��������          
    % �������ݰ�
    cur_arrival_num_packets = ceil(Node.Nor_SrcRate*(end_slot_ind + MAC.N_Slot - last_end_slot_ind)*MAC.T_Slot/Node.packet_length);
    tmp_arrival_Queue = zeros(cur_arrival_num_packets,4);
    tmp_arrival_Queue(:,1) = ((1:cur_arrival_num_packets) + size(arrivalQueue,1))'; % ���ݰ�ID-packetID
    last_time_frame = (MAC.N_Slot - last_end_slot_ind)*MAC.T_Slot; %��һ��֡��ʣ���ʱ��
    for tmp_ind = 1:cur_arrival_num_packets 
        cur_sum_time = (gen_time_packet * tmp_ind); %Ҫ������ǰ�������۵�ʱ��
        next_frame_or_not =(cur_sum_time-last_time_frame)>0; % �ð��Ƿ��ڵ�ǰ֡����
        tmp_arrival_Queue(tmp_ind,2) = cur_ind_frame - 1 + next_frame_or_not; % ��֡ID-frameID
        tmp_arrival_Queue(tmp_ind,3) = cur_sum_time - next_frame_or_not * last_time_frame; % ���ݰ��ڵ�ǰ��֡�в�����ʱ��(��ƫ����)-t_gen_offset
        %tmp_arrival_Queue(tmp_ind,4) = 0; % ���ݰ�����-packetType, ֵΪ0��ʾΪ��ͨ����ֵΪ1��ʾΪ������
    end
    arrivalQueue = [arrivalQueue;tmp_arrival_Queue];
    
    %% ��������״̬����
    % ��Ҫ���ݻ�������������Ƿ�Խڵ���ж�����������δ�洢�����ݰ��Ƿ񳬹���������
    % ���ȷ������ݰ��Ƿ�ʱ�����ޣ��������ʱ�����޽�����
    ind_end_buffer = size(arrivalQueue,1); %����λ��
    ind_begin_buffer = bufferQueue(end,2); %��ȡ��һ��֡��ʣ��
    if (ind_end_buffer-ind_begin_buffer) > Node(ind_node).num_packet_buffer %�жϵ�ǰ�����е����ݰ��Ƿ���ڻ�����������������ڽ���
        tmp_ind_begin_buffer = ind_begin_buffer;
        ind_begin_buffer = ind_end_buffer - Node(ind_node).num_packet_buffer + 1;
        tmp_range = tmp_ind_begin_buffer:(ind_begin_buffer-1);
        tmp_len = size(tmp_range,2);
        tran_packet_state = 4; %����״̬Ϊ1����ʾ����ɹ�
        deletePackets = [arrivalQueue(tmp_range,1:3), repmat(cur_ind_frame,tmp_len,1), zeros(tmp_len,4), repmat(tran_packet_state,tmp_len,1)]; %�������
        tranQueue=[tranQueue; deletePackets];
    end
    
    %% �������ݰ��������
    tran_times = floor((end_slot_ind + MAC.N_Slot - last_end_slot_ind)*MAC.T_Slot.*Allocate(ind_node).rate./Node(ind_node).packet_length); %�������Դ���Դ���Ĵ���
    rand('state',rand_seed)            
    rand_PLR = rand(1,tran_times); %���������������PLR�Ա���ȷ���Ƿ񶪰�
    cur_PLR = calPLR(Allocate(ind_node).power, Allocate(ind_node).rate, Node(ind_node).packet_length, Node(ind_node).PL_Fr, cur_shadow, Channel); %���㵱ǰ��Դ���ڲ�ͬʱ϶����ʱ�Ķ�����     
    if sum(Allocate(ind_node).slot)<=0
        % return; %�Ƶ������н�ȡ����ע�ͣ���Ϊû�ж����ʱ϶�������ݣ���˲��ܴ������ݰ�����ֱ�ӷ���
    end
    tmp_tran_packets = [];
    for ind_tran = 1:tran_times
        cur_ind_slot = ceil(((ind_tran-1)*tran_time_packet+ first_slot_ind*MAC.T_Slot)/MAC.T_Slot);
        % �жϻ������Ƿ������ݰ�
        if ind_begin_buffer > ind_end_buffer
            break; %��������û�����ݰ�ʱ������ѭ��
        end
        %�ж����ݰ��Ƿ���ɹ�,�����洫����Ϣ
        if cur_PLR(1,cur_ind_slot)<=rand_PLR(ind_tran) % ���ݰ�����ɹ�
            tran_packet_state = 1; %����״̬Ϊ1����ʾ����ɹ�
            tmp_tran_packets = [ tmp_tran_packets; arrivalQueue(ind_begin_buffer,1:3),cur_ind_frame,cur_ind_slot*MAC.T_Slot,tran_time_packet,Allocate(ind_node).power,Allocate(ind_node).rate, tran_packet_state]; %���洫�����
            ind_begin_buffer = ind_begin_buffer+1;
        else %���ݰ�����ʧ��
            tran_packet_state = 2; %����״̬Ϊ2����ʾ��·���� 
            tmp_tran_packets = [ tmp_tran_packets; arrivalQueue(ind_begin_buffer,1:3),cur_ind_frame,cur_ind_slot*MAC.T_Slot,tran_time_packet,Allocate(ind_node).power,Allocate(ind_node).rate, tran_packet_state]; %���洫�����
        end
    end
    tranQueue = [tranQueue; tmp_tran_packets];
    bufferQueue = [bufferQueue;cur_ind_frame,ind_begin_buffer,ind_end_buffer]; %���»������
end

