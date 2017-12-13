function [ tranQueue, arrivalQueue, bufferQueue, last_end_slot_ind] = nodeTranPerFrame(cur_ind_frame, cur_shadow, cur_EH_collect, last_end_slot_ind, Allocate, Node, MAC, Channel, Constraints, tranQueue, arrivalQueue, bufferQueue, rand_seed)
%nodeTranPerFrame ÿ���ڵ������������Դ�������µ����ݴ������
%���룺
%   cur_ind_frame ��ǰ��֡��������
%   cur_shadow ��ǰ�ڵ��ڵ�ǰ��֡����ʱ϶�ڵ���Ӱ˥��
%   cur_EH_collect ����һ��֡����ʱ϶����λ�ú��ʱ϶��ʼ�ýڵ��ڸ���ʱ϶�е������ɼ�ֵ
%   last_end_slot_ind ��һ��֡����ʱ϶��ĩβλ��
%   tranQueue ���ݰ�������У��������ݰ��������Ϣ
%   arrivalQueue ���ݰ��ﵽ����
%   bufferQueue ����״̬����
%   Allocation ������Ķ���Դ���������书�ʣ��������ʣ�   
%   Node �ڵ�Ļ�����Ϣ���������ݰ�������������ݰ����ȡ��ڵ���ŵ������sigma��
%   MAC MAC����ز���
%   Channel �ŵ���ز���
%   Constraints ���ݰ���������Լ����
%   tranQueue ���ݰ��������
%   arrivalQueue ���ݰ��������
%   bufferQueue ����״̬����
%�����
%   tranQueue ���ݰ��������
%   arrivalQueue ���ݰ��������
%   bufferQueue ����״̬����  
%   last_end_slot_ind ��һ��֡����ʱ϶��ĩβλ��

   %% �ж��Ƿ���ʱ϶��Դ
    if sum(Allocate.slot)<=0
        first_slot_ind = MAC.N_Slot; %����ʱ϶�Ŀ�ʼλ�ã����ڼ������ʱ϶�Ķ�����
        end_slot_ind = MAC.N_Slot; %������ʱ϶�Ľ���λ��           
    else
        tmp_ind = find(Allocate.slot == 1);
        first_slot_ind = tmp_ind(1); %����ʱ϶�Ŀ�ʼλ�ã����ڼ������ʱ϶�Ķ�����
        end_slot_ind = tmp_ind(end); %������ʱ϶�Ľ���λ��  
    end       
    % ���ݰ�ʱ�䣺����ʱ��ʹ���ʱ��
    tran_time_packet = Node.packet_length/Node.tranRate; %����һ��������Ҫ��ʱ��
    gen_time_packet = Node.packet_length/Allocate.src_rate; %����һ��������Ҫ��ʱ��
    
    %% �������ݰ��������,����ֻͳ��������            
    cur_arrival_num_packets = ceil(Allocate.src_rate * (end_slot_ind + MAC.N_Slot - last_end_slot_ind)*MAC.T_Slot/Node.packet_length);
    tmp_arrival_Queue = zeros(cur_arrival_num_packets,4);
    tmp_arrival_Queue(:,1) = ((1:cur_arrival_num_packets) + size(arrivalQueue,1))'; % ���ݰ�ID-packetID
    last_time_frame = (MAC.N_Slot - last_end_slot_ind)*MAC.T_Slot; %��һ��֡��ʣ���ʱ��
    for tmp_ind = 1:cur_arrival_num_packets 
        cur_sum_time = min((gen_time_packet * tmp_ind),(end_slot_ind + MAC.N_Slot - last_end_slot_ind - tran_time_packet)*MAC.T_Slot); %Ҫ������ǰ�������۵�ʱ��     
        next_frame_or_not =(cur_sum_time-last_time_frame)>0; % �ð��Ƿ��ڵ�ǰ֡����
        tmp_arrival_Queue(tmp_ind,2) = cur_ind_frame - 1 + next_frame_or_not; % ��֡ID-frameID
        tmp_arrival_Queue(tmp_ind,3) = cur_sum_time + last_end_slot_ind*MAC.T_Slot - next_frame_or_not * MAC.T_Frame; % ���ݰ��ڵ�ǰ��֡�в�����ʱ��(��ƫ����)-t_gen_offset
        %tmp_arrival_Queue(tmp_ind,4) = 0; % ���ݰ�����-packetType, ֵΪ0��ʾΪ��ͨ����ֵΪ1��ʾΪ������
    end
    arrivalQueue = [arrivalQueue;tmp_arrival_Queue];

    %% ��������״̬����
    % ��Ҫ���ݻ�������������Ƿ�Խڵ���ж�����������δ�洢�����ݰ��Ƿ񳬹���������
    % ���ȷ������ݰ��Ƿ�ʱ�����ޣ��������ʱ�����޽�����
    ind_end_buffer = size(arrivalQueue,1); %����λ��
    ind_begin_buffer = bufferQueue(end,2); %��ȡ��һ��֡��ʣ��
    residue_energy = bufferQueue(end,4); %��ȡ��һ��֡��ʣ������
    tmp_ind_begin_buffer = ind_begin_buffer;
    if (ind_end_buffer-ind_begin_buffer) > Node.num_packet_buffer %�жϵ�ǰ�����е����ݰ��Ƿ���ڻ�����������
        ind_begin_buffer = ind_end_buffer - Node.num_packet_buffer + 1;
        tmp_range = tmp_ind_begin_buffer:(ind_begin_buffer-1);
        tmp_len = size(tmp_range,2);
        tran_packet_state = 4; %����״̬Ϊ1����ʾ����ɹ�
        deletePackets = [arrivalQueue(tmp_range,1:3), repmat(cur_ind_frame,tmp_len,1), zeros(tmp_len,4), repmat(tran_packet_state,tmp_len,1)]; %�������
        tranQueue=[tranQueue; deletePackets];
    end 
    % ����Ƿ��ж����е����ݰ���ʱ�ӳ�������
    tmp_ind_begin_buffer = ind_begin_buffer;
    count_overdelay = 0;
    for ind_overdelay = ind_begin_buffer:ind_end_buffer
        cur_delay = (cur_ind_frame - arrivalQueue(ind_overdelay,2))*MAC.T_Frame + first_slot_ind*MAC.T_Slot - arrivalQueue(ind_overdelay,3);
        if cur_delay > Constraints.Nor_Delay_th
            count_overdelay = count_overdelay +1;
        else
            break;
        end
    end
    ind_begin_buffer = ind_begin_buffer + count_overdelay;
    overdelay_range = tmp_ind_begin_buffer:(ind_begin_buffer-1);
    tmp_len = size(overdelay_range,2);
    tran_packet_state = 3; %����״̬Ϊ3����ʾʱ�ӳ������޶�����
    deletePackets = [arrivalQueue(overdelay_range,1:3),repmat(cur_ind_frame,tmp_len,1), zeros(tmp_len,4), repmat(tran_packet_state,tmp_len,1)]; %ʱ�ӳ��޶���
    tranQueue=[tranQueue; deletePackets];
    
    % ���û�з���ʱ϶��������ѭ��
    if sum(Allocate.slot)<=0
        sum_EH_collect = sum(cur_EH_collect); %���ʱ���ڲɼ���������
        residue_energy = residue_energy + sum_EH_collect; %����ʣ������
        bufferQueue = [bufferQueue;cur_ind_frame,ind_begin_buffer,ind_end_buffer,residue_energy]; %���»������
        last_end_slot_ind = end_slot_ind; %ʱ϶ĩβλ��   
        disp(['Warn��û�з���ʱ϶������������̡�'])
        return;%��Ϊû�з���ʱ϶�������ݣ���˲��ܴ������ݰ�����ֱ�ӷ���
    end
   %% �������ݰ��������
    tran_times = floor((end_slot_ind - first_slot_ind+1)*MAC.T_Slot.*Node.tranRate./Node.packet_length); %�������Դ���Դ���Ĵ���
    rand('state',rand_seed)            
    rand_PLR = rand(1,tran_times); %���������������PLR�Ա���ȷ���Ƿ񶪰�
    cur_PLR = calPLR(Allocate.power, Node.tranRate, Node.packet_length, Node.PL_Fr, cur_shadow, Channel); %���㵱ǰ��Դ���ڲ�ͬʱ϶����ʱ�Ķ�����     
    if sum(Allocate.slot)<=0
        % return; %�Ƶ������н�ȡ����ע�ͣ���Ϊû�ж����ʱ϶�������ݣ���˲��ܴ������ݰ�����ֱ�ӷ���
    end
    tmp_tran_packets = [];
    % ����ǰ�ȸ�������
    end_offset = first_slot_ind - 1 + MAC.N_Slot - last_end_slot_ind;
    sum_EH_collect = sum(cur_EH_collect(1,1:end_offset)); %���ʱ���ڲɼ���������
    residue_energy = residue_energy + sum_EH_collect; %����ʣ������
    cur_ind_slot = first_slot_ind; %��ʼ����ǰʱ�̵�ʱ϶����
    for ind_tran = 1:tran_times
        cur_ind_slot = ceil(((ind_tran-1)*tran_time_packet+ first_slot_ind*MAC.T_Slot)/MAC.T_Slot);
        % �жϻ������Ƿ������ݰ�
        if ind_begin_buffer > ind_end_buffer
            break; %��������û�����ݰ�ʱ������ѭ��
        end
        % ����ʣ������     
        cur_offset = cur_ind_slot + MAC.N_Slot - last_end_slot_ind;
        sum_EH_collect = sum(cur_EH_collect(1,(end_offset+1):(cur_offset-1))); %���ʱ���ڲɼ���������
        end_offset = cur_offset-1;
        residue_energy = residue_energy + sum_EH_collect; %����ʣ������
        % �ж�ʣ���������������Ƿ��㹻����һ�����ݰ�
        if residue_energy < Allocate.power(1,cur_ind_slot) * tran_time_packet
            continue; % ���û����������ֹͣ�˴δ��䣬�����ɼ��������ȴ��´η�������
        end
        %�ж����ݰ��Ƿ���ɹ�,�����洫����Ϣ
        if cur_PLR(1,cur_ind_slot)<=rand_PLR(ind_tran) % ���ݰ�����ɹ�
            tran_packet_state = 1; %����״̬Ϊ1����ʾ����ɹ�
            tmp_tran_packets = [ tmp_tran_packets; arrivalQueue(ind_begin_buffer,1:3),cur_ind_frame,cur_ind_slot*MAC.T_Slot,tran_time_packet,Allocate.power(1,cur_ind_slot),Node.tranRate, tran_packet_state]; %���洫�����
            ind_begin_buffer = ind_begin_buffer+1;
        else %���ݰ�����ʧ��
            tran_packet_state = 2; %����״̬Ϊ2����ʾ��·���� 
            tmp_tran_packets = [ tmp_tran_packets; arrivalQueue(ind_begin_buffer,1:3),cur_ind_frame,cur_ind_slot*MAC.T_Slot,tran_time_packet,Allocate.power(1,cur_ind_slot),Node.tranRate, tran_packet_state]; %���洫�����
        end
        residue_energy = residue_energy - Allocate.power(1,cur_ind_slot) * tran_time_packet; % ����ʣ������
    end
    sum_EH_collect = sum(cur_EH_collect(1,(end_offset+1):(end_slot_ind + MAC.N_Slot - last_end_slot_ind))); %���ʱ���ڲɼ���������
    residue_energy = residue_energy + sum_EH_collect; %����ʣ������
    tranQueue = [tranQueue; tmp_tran_packets];
    bufferQueue = [bufferQueue;cur_ind_frame,ind_begin_buffer,ind_end_buffer,residue_energy]; %���»������
    last_end_slot_ind = end_slot_ind; %ʱ϶ĩβλ��
end

