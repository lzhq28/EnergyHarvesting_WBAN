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
    N_Frame = 1000; %ʵ����ܳ�֡��
    ini_pos = 1; %��ʼ����������Ϊ��ֹ״̬
    % �������г�֡���������к�ÿ��ʱ϶����Ӱ˥��
    [shadow_seq, pos_seq] = shadowStatistic( N_Frame, ini_pos, pos_hold_time, par.Nodes, par.Postures, par.MAC, rand_state, slot_or_frame_state);
    
    %% ���ܷ���
    % ��ʼ�����ֲ�ͬ�Ķ���
    for ind_node = 1:par.Nodes.Num
        Queue(ind_node).tranQueue = []; %���ݰ�������У��������ݰ��������Ϣ: 
        Queue(ind_node).arrivalQueue = []; %���ݰ��ﵽ���У� [pacektID,frameID,t_gen_offset,packetType]
        Queue(ind_node).bufferQueue = [0,1,1]; %����״̬����, [frameID, beginIndex, endIndex]
    end   
    
    % ѭ��ͳ�Ʒ���
    for ind_frame = 1:N_Frame %�Գ�֡���б���
        cur_pos = pos_seq(ind_frame); %��ǰ�ڵ����������
        cur_shadow = shadow_seq(:,((ind_frame-1)*par.MAC.N_Slot+1):ind_frame*par.MAC.N_Slot); %��ǰ��֡������ʱ϶����Ӱ˥��ֵ
        for ind_node = 1:par.Nodes.Num %�Ը����ڵ���б���

            %% ���²���
            % ������ӣ����нڵ��ڲ�ͬ��֡��������Ӷ���ͬ
            rand_seed = rand_state*par.Nodes.Num*N_Frame+ (ind_node-1)*N_Frame+(ind_frame-1);
            % ��ʹ�ù̶�����Դ��������д�ڵ�����ͳ�ƺ���
            Allocate(ind_node).power = par.PHY.P_max;
            Allocate(ind_node).rate = par.PHY.RateSet(3);
            Allocate(ind_node).slot = ones(1, par.MAC.N_Slot); %�����������ԣ�ֱ�ӽ�����ʱ϶������ڵ�
            % �����ڵ�Ļ�����Ϣ
            Node(ind_node).Sigma = par.Nodes.Sigma(cur_pos,ind_node); % ��ǰ�ڵ��ڵ�ǰ���������µ���Ӱ˥��ı�׼��Sigma
            Node(ind_node).PL_Fr = par.Nodes.PL_Fr(ind_node); % PL = PL_Fr + shadow
            Node(ind_node).num_packet_buffer = par.Nodes.num_packet_buffer(ind_node); %�ڵ㻺�����ܱ������ݰ�������
            Node(ind_node).num_packet_Nor = ceil(par.Nodes.Nor_SrcRates(ind_node)*par.MAC.T_Frame/par.Nodes.packet_length(ind_node));
            Node(ind_node).packet_length = par.Nodes.packet_length(ind_node);            
            rand('state', rand_seed); %����������ӣ���ͬ��rand_state�Բ�ͬ��ind_frame�������ص����������
            Node(ind_node).num_packet_Emer = random('poiss',par.Nodes.lambda_Emer(ind_node));
            Node(ind_node).num_packet_buffer = par.Nodes.num_packet_buffer(ind_node); %�������ܴ洢�����ݰ�����
            
            %% �������ݰ��������,����ֻͳ��������
            % �������ݰ�
            tmp_arrival_Queue = zeros(Node(ind_node).num_packet_Nor,4);
            tmp_arrival_Queue(:,1) = ((1:Node(ind_node).num_packet_Nor) + size(Queue(ind_node).arrivalQueue,1))'; % ���ݰ�ID-packetID
            tmp_arrival_Queue(:,2) = ind_frame; % ��֡ID-frameID
            tmp_arrival_Queue(:,3) = ((1:Node(ind_node).num_packet_Nor)/Node(ind_node).num_packet_Nor.*par.MAC.T_Frame)'; % ���ݰ��ڵ�ǰ��֡�в�����ʱ��(��ƫ����)-t_gen_offset
            %tmp_arrival_Queue(:,4) = zeros(Node(ind_node).num_packet_Nor,1); % ���ݰ�����-packetType, ֵΪ0��ʾΪ��ͨ����ֵΪ1��ʾΪ������
            Queue(ind_node).arrivalQueue = [Queue(ind_node).arrivalQueue;tmp_arrival_Queue]
            %% ��������״̬����
            % ��Ҫ���ݻ�������������Ƿ�Խڵ���ж�����������δ�洢�����ݰ��Ƿ񳬹���������
            % ���ȷ������ݰ��Ƿ�ʱ�����ޣ��������ʱ�����޽�����
            ind_end_buffer = size(Queue(ind_node).arrivalQueue,1); %����λ��
            ind_begin_buffer = Queue(ind_node).bufferQueue(end,2); %��ȡ��һ��֡��ʣ��
            if (ind_end_buffer-ind_begin_buffer) > Node(ind_node).num_packet_buffer %�жϵ�ǰ�����е����ݰ��Ƿ���ڻ�����������������ڽ���
                ind_begin_buffer = ind_end_buffer - Node(ind_node).num_packet_buffer + 1;
                
            end
            Queue(ind_node).bufferQueue = [Queue(ind_node).bufferQueue;ind_frame,ind_begin_buffer,ind_end_buffer]; %���»������
            %% �������ݰ��������
            tran_times = floor(sum(Allocate(ind_node).slot).*par.MAC.T_Slot.*Allocate(ind_node).rate./Node(ind_node).packet_length); %�������Դ���Դ���Ĵ���
            rand('state',rand_seed)            
            rand_PLR = rand(1,tran_times); %���������������PLR�Ա���ȷ���Ƿ񶪰�
            cur_PLR = calPLR(Allocate(ind_node).power, Allocate(ind_node).rate, Node(ind_node).packet_length, Node(ind_node).PL_Fr, cur_shadow(ind_node,:), Channel);
            for ind_tran = 1:tran_times
                
                cur_ind_slot = Queue(ind_node).bufferQueue(end,);
            end
            
        end
    end
    
 
    
    % 
%     randn('state',0); 
%     X_cur = randn(1,1,'double')
%     packetSize = 1000; %��λbit
%     tranPower = 0.001:0.0001:0.01;
%     tranRate = par.PHY.RateSet(2)*6
%     plr =  calPLR(tranPower, tranRate, packetSize, par.Nodes.PL_Fr(1,1), X_cur, par.Channel.Bandwidth,par.Channel.BCH_n)
%     plot(plr)