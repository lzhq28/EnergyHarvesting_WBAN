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
    pos_hold_time = 40*100; %ÿ�����Ʊ��ֵ�ʱ�䣬��λms
    N_Frame = 1000; %ʵ����ܳ�֡��
    ini_pos = 1; %��ʼ����������Ϊ��ֹ״̬
    % �������г�֡���������к�ÿ��ʱ϶����Ӱ˥��
    [shadow_seq, pos_seq] = shadowStatistic( N_Frame, ini_pos, pos_hold_time, par.Nodes, par.Postures, par.MAC, rand_state, slot_or_frame_state);
    % ��ʼ������ʱ϶�������ɼ�״̬
    [EH_seq] = energyHarvestStatistic( pos_seq, par.EnergyHarvest, par.MAC, rand_state);
    
 
    
    %% ���ܷ���
    % ��ʼ�����ֲ�ͬ�Ķ���
    for ind_node = 1:par.Nodes.Num
        Queue(ind_node).tranQueue = []; %���ݰ�������У��������ݰ��������Ϣ:[packetID, gen_frameID, t_gen_offset, tran_frameID, t_tran_offset, t_tran_cost, tran_power, tran_rate, tran_state]
        Queue(ind_node).arrivalQueue = []; %���ݰ��ﵽ���У� [pacektID,frameID,t_gen_offset,packetType]
        Queue(ind_node).bufferQueue = [0,1,1,1e+7]; %����״̬����, [frameID, beginIndex, endIndex, residue_energy]
    end   
    Allocate ={}; %��ʼ����Դ����
    Node={}; %��ʼ�������ڵ�Ļ�����Ϣ
    for ind_node = 1:par.Nodes.Num %�Ը����ڵ���б���
        %Node(ind_node).Sigma = par.Nodes.Sigma(cur_pos,ind_node); % ��ǰ�ڵ��ڵ�ǰ���������µ���Ӱ˥��ı�׼��Sigma
        Node(ind_node).PL_Fr = par.Nodes.PL_Fr(ind_node); % PL = PL_Fr + shadow
        Node(ind_node).num_packet_buffer = par.Nodes.num_packet_buffer(ind_node); %�ڵ㻺�����ܱ������ݰ�������            
        Node(ind_node).packet_length = par.Nodes.packet_length(ind_node); 
        Node(ind_node).num_packet_buffer = par.Nodes.num_packet_buffer(ind_node); %�������ܴ洢�����ݰ�����
        Node(ind_node).Nor_SrcRate = par.Nodes.Nor_SrcRates(ind_node);
    end
        
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
            Allocate(ind_node).power = par.PHY.P_min;
            Allocate(ind_node).rate = par.PHY.RateSet(3);
            Allocate(ind_node).slot = zeros(1, par.MAC.N_Slot); %�����������ԣ�ֱ�ӽ�����ʱ϶������ڵ�
            Allocate(ind_node).slot(1,20:40) =1;
            % �����ڵ�Ļ�����Ϣ
            Node(ind_node).Sigma = par.Nodes.Sigma(cur_pos,ind_node); % ��ǰ�ڵ��ڵ�ǰ���������µ���Ӱ˥��ı�׼��Sigma
            [ Queue(ind_node).tranQueue, Queue(ind_node).arrivalQueue, Queue(ind_node).bufferQueue, last_end_slot_ind(ind_node)] = nodeTranPerFrame(ind_frame, cur_shadow, last_end_slot_ind(ind_node), Allocate(ind_node), Node(ind_node), par.MAC, par.Channel,par.Constraints, Queue(ind_node).tranQueue, Queue(ind_node).arrivalQueue, Queue(ind_node).bufferQueue, rand_seed);
            
        end
    end
    
    % ����ͳ��
    QoS = calQosPerformance( Queue, par.MAC);
    
    %% չʾ���ܱ���
    plotQoSPerformance(QoS, Queue);
    
    
   