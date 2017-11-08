%%%%% ���������㷨�ĺ������ %%%%%%
%% �������ݲ����ò���
    clc
    clear all
    matlab_ver='2015';% '2012'or'2015'
    if  strcmp(matlab_ver,'2012')
        if(matlabpool('size')==0) %û�д򿪲���
            matlabpool local; %����local���õĽ����������matlab worker
        end
    else
        if(isempty(gcp('nocreate'))==1) %û�д򿪲���
            parpool local; %����local���õĽ����������matlab worker
        end
    end
%% ��ʼ��ϵͳ����
    par = initialParameters(); %��ʼ��ϵͳ����
%% ����ʵ���������
    rand_state = 1; %�������,�����1��ʼ������
    slot_or_frame_state =0; %��Ӱ˥����ÿ��ʱ϶��ͬ������ÿ����֡��ͬ��ֵΪ0��ʾÿ��ʱ϶��ͬ��ֵΪ1��ʾÿ����֡��ͬ
    pos_hold_time = 400; %ÿ�����Ʊ��ֵ�ʱ�䣬��λms
    N_Frame = 15; %ʵ����ܳ�֡��
    ini_pos = 1; %��ʼ����������Ϊ��ֹ״̬
    % �������г�֡���������к�ÿ��ʱ϶����Ӱ˥��
    [shadow_seq, pos_seq] = shadowStatistic( N_Frame, ini_pos, pos_hold_time, par.Nodes, par.Postures, par.MAC, rand_state, slot_or_frame_state);
    
    %% ���ܷ���
    % ��ʼ�����ֲ�ͬ�Ķ���
    for ind_node = 1:par.Nodes.Num
        Queue(ind_node).tranQueue = []; %���ݰ�������У��������ݰ��������Ϣ:[packetID, gen_frameID, t_gen_offset, tran_frameID, t_tran_offset, t_tran_cost, tran_power, tran_rate, tran_state]
        Queue(ind_node).arrivalQueue = []; %���ݰ��ﵽ���У� [pacektID,frameID,t_gen_offset,packetType]
        Queue(ind_node).bufferQueue = [0,1,1,1e+7]; %����״̬����, [frameID, beginIndex, endIndex, residue_energy]
    end   
    Allocate ={}; %��ʼ����Դ����
    Node={}; %��ʼ�������ڵ�Ļ�����Ϣ
    
    % ѭ��ͳ�Ʒ���
    last_end_slot_ind = ones(1,par.Nodes.Num)*par.MAC.N_Slot; %��һ��֡����ʱ϶�Ľ���λ��
    for ind_frame = 1:N_Frame %�Գ�֡���б���
        cur_pos = pos_seq(ind_frame); %��ǰ�ڵ����������       
        for ind_node = 1:par.Nodes.Num %�Ը����ڵ���б���
            cur_shadow = shadow_seq(ind_node,((ind_frame-1)*par.MAC.N_Slot+1):(ind_frame*par.MAC.N_Slot)); %��ǰ�ڼ����Ӱ˥���ֵ
            %% ���²���
            % ������ӣ����нڵ��ڲ�ͬ��֡��������Ӷ���ͬ
            rand_seed = rand_state*par.Nodes.Num*N_Frame+ (ind_node-1)*N_Frame+(ind_frame-1);
            % ��ʹ�ù̶�����Դ��������д�ڵ�����ͳ�ƺ���
            Allocate(ind_node).power = par.PHY.P_max;
            Allocate(ind_node).rate = par.PHY.RateSet(3);
            Allocate(ind_node).slot = zeros(1, par.MAC.N_Slot); %�����������ԣ�ֱ�ӽ�����ʱ϶������ڵ�
            Allocate(ind_node).slot(1,20:40) =1;
            % �����ڵ�Ļ�����Ϣ
            Node(ind_node).Sigma = par.Nodes.Sigma(cur_pos,ind_node); % ��ǰ�ڵ��ڵ�ǰ���������µ���Ӱ˥��ı�׼��Sigma
            Node(ind_node).PL_Fr = par.Nodes.PL_Fr(ind_node); % PL = PL_Fr + shadow
            Node(ind_node).num_packet_buffer = par.Nodes.num_packet_buffer(ind_node); %�ڵ㻺�����ܱ������ݰ�������            
            Node(ind_node).packet_length = par.Nodes.packet_length(ind_node); 
            Node(ind_node).num_packet_buffer = par.Nodes.num_packet_buffer(ind_node); %�������ܴ洢�����ݰ�����
            Node(ind_node).Nor_SrcRate = par.Nodes.Nor_SrcRates(ind_node);
            %rand('state', rand_seed); %����������ӣ���ͬ��rand_state�Բ�ͬ��ind_frame�������ص����������
            %Node(ind_node).num_packet_Emer = random('poiss',par.Nodes.lambda_Emer(ind_node));
            [ Queue(ind_node).tranQueue, Queue(ind_node).arrivalQueue, Queue(ind_node).bufferQueue, last_end_slot_ind(ind_node)] = nodeTranPerFrame(ind_frame, cur_shadow, last_end_slot_ind(ind_node), Allocate(ind_node), Node(ind_node), par.MAC, par.Channel,par.Constraints, Queue(ind_node).tranQueue, Queue(ind_node).arrivalQueue, Queue(ind_node).bufferQueue, rand_seed)
% % %            %% ���ò���
% % %             tmp_ind = find(Allocate(ind_node).slot == 1);
% % %             first_slot_ind = tmp_ind(1); %����ʱ϶�Ŀ�ʼλ�ã����ڼ������ʱ϶�Ķ�����
% % %             end_slot_ind = tmp_ind(end); %������ʱ϶�Ľ���λ��            
% % %             % ���ݰ�ʱ�䣺����ʱ��ʹ���ʱ��
% % %             tran_time_packet = Node(ind_node).packet_length/Allocate(ind_node).rate; %����һ��������Ҫ��ʱ��
% % %             gen_time_packet = Node(ind_node).packet_length/Node(ind_node).Nor_SrcRate; %����һ��������Ҫ��ʱ��
% % %             
% % %             %% �������ݰ��������,����ֻͳ��������            
% % %             % �������ݰ�
% % %             cur_arrival_num_packets = ceil(Node(ind_node).Nor_SrcRate*(end_slot_ind + par.MAC.N_Slot - last_end_slot_ind(ind_node))*par.MAC.T_Slot/Node(ind_node).packet_length);
% % %             tmp_arrival_Queue = zeros(cur_arrival_num_packets,4);
% % %             tmp_arrival_Queue(:,1) = ((1:cur_arrival_num_packets) + size(Queue(ind_node).arrivalQueue,1))'; % ���ݰ�ID-packetID
% % %             last_time_frame = (par.MAC.N_Slot - last_end_slot_ind(ind_node))*par.MAC.T_Slot; %��һ��֡��ʣ���ʱ��
% % %             for tmp_ind = 1:cur_arrival_num_packets 
% % %                 cur_sum_time = (gen_time_packet * tmp_ind); %Ҫ������ǰ�������۵�ʱ��
% % %                 next_frame_or_not =(cur_sum_time-last_time_frame)>0; % �ð��Ƿ��ڵ�ǰ֡����
% % %                 tmp_arrival_Queue(tmp_ind,2) = ind_frame - 1 + next_frame_or_not; % ��֡ID-frameID
% % %                 tmp_arrival_Queue(tmp_ind,3) = cur_sum_time + last_end_slot_ind(ind_node)*par.MAC.T_Slot - next_frame_or_not * par.MAC.T_Frame; % ���ݰ��ڵ�ǰ��֡�в�����ʱ��(��ƫ����)-t_gen_offset
% % %                 %tmp_arrival_Queue(tmp_ind,4) = 0; % ���ݰ�����-packetType, ֵΪ0��ʾΪ��ͨ����ֵΪ1��ʾΪ������
% % %             end
% % %             Queue(ind_node).arrivalQueue = [Queue(ind_node).arrivalQueue;tmp_arrival_Queue];
% % %             %% ��������״̬����
% % %             % ��Ҫ���ݻ�������������Ƿ�Խڵ���ж�����������δ�洢�����ݰ��Ƿ񳬹���������
% % %             % ���ȷ������ݰ��Ƿ�ʱ�����ޣ��������ʱ�����޽�����
% % %             ind_end_buffer = size(Queue(ind_node).arrivalQueue,1); %����λ��
% % %             ind_begin_buffer = Queue(ind_node).bufferQueue(end,2); %��ȡ��һ��֡��ʣ��
% % %             residue_energy = Queue(ind_node).bufferQueue(end,4); %��ȡ��һ��֡��ʣ������
% % %             if (ind_end_buffer-ind_begin_buffer) > Node(ind_node).num_packet_buffer %�жϵ�ǰ�����е����ݰ��Ƿ���ڻ�����������������ڽ���
% % %                 tmp_ind_begin_buffer = ind_begin_buffer;
% % %                 ind_begin_buffer = ind_end_buffer - Node(ind_node).num_packet_buffer + 1;
% % %                 tmp_range = tmp_ind_begin_buffer:(ind_begin_buffer-1);
% % %                 tmp_len = size(tmp_range,2);
% % %                 tran_packet_state = 4; %����״̬Ϊ1����ʾ����ɹ�
% % %                 deletePackets = [Queue(ind_node).arrivalQueue(tmp_range,1:3), repmat(ind_frame,tmp_len,1), zeros(tmp_len,4), repmat(tran_packet_state,tmp_len,1)]; %�������
% % %                 Queue(ind_node).tranQueue=[Queue(ind_node).tranQueue; deletePackets];
% % %             end 
% % %            %% �������ݰ��������
% % %             tran_times = floor((end_slot_ind - first_slot_ind+1)*par.MAC.T_Slot.*Allocate(ind_node).rate./Node(ind_node).packet_length); %�������Դ���Դ���Ĵ���
% % %             rand('state',rand_seed)            
% % %             rand_PLR = rand(1,tran_times); %���������������PLR�Ա���ȷ���Ƿ񶪰�
% % %             cur_PLR = calPLR(Allocate(ind_node).power, Allocate(ind_node).rate, Node(ind_node).packet_length, Node(ind_node).PL_Fr, cur_shadow, par.Channel); %���㵱ǰ��Դ���ڲ�ͬʱ϶����ʱ�Ķ�����     
% % %             if sum(Allocate(ind_node).slot)<=0
% % %                 % return; %�Ƶ������н�ȡ����ע�ͣ���Ϊû�ж����ʱ϶�������ݣ���˲��ܴ������ݰ�����ֱ�ӷ���
% % %             end
% % %             tmp_tran_packets = [];
% % %             for ind_tran = 1:tran_times
% % %                 cur_ind_slot = ceil(((ind_tran-1)*tran_time_packet+ first_slot_ind*par.MAC.T_Slot)/par.MAC.T_Slot);
% % %                 % �жϻ������Ƿ������ݰ�
% % %                 if ind_begin_buffer > ind_end_buffer
% % %                     break; %��������û�����ݰ�ʱ������ѭ��
% % %                 end
% % %                 % �ж��Ƿ���������������
% % %                 if residue_energy < 0
% % %                     break; % ���û����������ֹͣ�������ݰ�
% % %                 end
% % %                 %�ж����ݰ��Ƿ���ɹ�,�����洫����Ϣ
% % %                 if cur_PLR(1,cur_ind_slot)<=rand_PLR(ind_tran) % ���ݰ�����ɹ�
% % %                     tran_packet_state = 1; %����״̬Ϊ1����ʾ����ɹ�
% % %                     tmp_tran_packets = [ tmp_tran_packets; Queue(ind_node).arrivalQueue(ind_begin_buffer,1:3),ind_frame,cur_ind_slot*par.MAC.T_Slot,tran_time_packet,Allocate(ind_node).power,Allocate(ind_node).rate, tran_packet_state]; %���洫�����
% % %                     ind_begin_buffer = ind_begin_buffer+1;
% % %                 else %���ݰ�����ʧ��
% % %                     tran_packet_state = 2; %����״̬Ϊ2����ʾ��·���� 
% % %                     tmp_tran_packets = [ tmp_tran_packets; Queue(ind_node).arrivalQueue(ind_begin_buffer,1:3),ind_frame,cur_ind_slot*par.MAC.T_Slot,tran_time_packet,Allocate(ind_node).power,Allocate(ind_node).rate, tran_packet_state]; %���洫�����
% % %                 end
% % %                 residue_energy = residue_energy - Allocate(ind_node).power * tran_time_packet; % ����ʣ������
% % %             end
% % %             Queue(ind_node).tranQueue = [Queue(ind_node).tranQueue; tmp_tran_packets];
% % %             Queue(ind_node).bufferQueue = [Queue(ind_node).bufferQueue;ind_frame,ind_begin_buffer,ind_end_buffer,residue_energy]; %���»������
% % %             last_end_slot_ind(ind_node) = end_slot_ind; 
        end
    end
   