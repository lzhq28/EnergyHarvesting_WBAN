%%%%% ���������㷨�ĺ������ %%%%%%
%% �������ݲ����ò���
    clc
    clear all
    matlab_ver='2015';% '2012'or'2015'
%     if  strcmp(matlab_ver,'2012')
%         if(matlabpool('size')==0) %û�д򿪲���
%             matlabpool local; %����local���õĽ����������matlab worker
%         end
%     else
%         if(isempty(gcp('nocreate'))==1) %û�д򿪲���
%             parpool local; %����local���õĽ����������matlab worker
%         end
%     end
%% ��ʼ��ϵͳ����
    par = initialParameters(); %��ʼ��ϵͳ����
%% ����ʵ���������
    rand_state = 1; %�������,�����1��ʼ������
    slot_or_frame_state =0; %��Ӱ˥����ÿ��ʱ϶��ͬ������ÿ����֡��ͬ��ֵΪ0��ʾÿ��ʱ϶��ͬ��ֵΪ1��ʾÿ����֡��ͬ
    pos_hold_time = 40*100; %ÿ�����Ʊ��ֵ�ʱ�䣬��λms
    N_Frame = 1000; %ʵ����ܳ�֡��
    ini_pos = 1; %��ʼ����������Ϊ��ֹ״̬
    re_cal_miu_state = 0; %�Ƿ����¼���miuֵ��ֵΪ0��ʾ�����¼��㣬���Ǵ��ļ��ж�ȡ���������¼��㡣
    precision = 0.0001; %�ڼ���miuʱ��PLR��PLR_th֮��Ĳ�ֵ����
    % �������г�֡���������к�ÿ��ʱ϶����Ӱ˥��
    [shadow_seq, pos_seq] = shadowStatistic( N_Frame, ini_pos, pos_hold_time, par.Nodes, par.Postures, par.MAC, rand_state, slot_or_frame_state);
    % ��ʼ������ʱ϶�������ɼ�״̬
    [ EH_status_seq, EH_collect_seq, EH_P_tran ] = energyHarvestStatistic( pos_seq, par.EnergyHarvest, par.MAC, rand_state); 
    % ����PLR�ĵ�Ч���ޣ�ƽ�����������miu_th
    [ miu_th ] = calEquPLRThreshold( par.Nodes, par.Channel, par.Constraints, precision, re_cal_miu_state);
   
    %% ���ܷ���
    % ��ʼ�����ֲ�ͬ�Ķ���
    for ind_node = 1:par.Nodes.Num
        Queue(ind_node).tranQueue = []; %���ݰ�������У��������ݰ��������Ϣ:[packetID, gen_frameID, t_gen_offset, tran_frameID, t_tran_offset, t_tran_cost, tran_power, tran_rate, tran_state]
        Queue(ind_node).arrivalQueue = []; %���ݰ��ﵽ���У� [pacektID,frameID,t_gen_offset,packetType]
        Queue(ind_node).bufferQueue = [0,1,1,1e+7]; %����״̬����, [frameID, beginIndex, endIndex, residue_energy]
    end   
    Allocate ={}; %��ʼ����Դ����
    Nodes={}; %��ʼ�������ڵ�Ļ�����Ϣ
    for ind_node = 1:par.Nodes.Num %�Ը����ڵ���б���
        %Nodes(ind_node).Sigma = par.Nodes.Sigma(cur_pos,ind_node); % ��ǰ�ڵ��ڵ�ǰ���������µ���Ӱ˥��ı�׼��Sigma
        Nodes(ind_node).PL_Fr = par.Nodes.PL_Fr(ind_node); % PL = PL_Fr + shadow
        Nodes(ind_node).num_packet_buffer = par.Nodes.num_packet_buffer(ind_node); %�ڵ㻺�����ܱ������ݰ�������            
        Nodes(ind_node).packet_length = par.Nodes.packet_length(ind_node); 
        Nodes(ind_node).num_packet_buffer = par.Nodes.num_packet_buffer(ind_node); %�������ܴ洢�����ݰ�����
        Nodes(ind_node).Nor_SrcRate = par.Nodes.Nor_SrcRates(ind_node);
        Nodes(ind_node).tranRate = par.Nodes.tranRate(ind_node); % �̶���������
    end
     
    
    %% ѭ��ͳ�Ʒ���
    sta_last_EH_status = [];
    sta_re_num_slots = [];
    sta_Allocate = {}; %ͳ�Ʒ���Ľ��
    sta_optimize_problems = []; %ͳ��ÿһ֡�Ż�����Ľ��
    last_end_slot_ind = ones(1,par.Nodes.Num)*par.MAC.N_Slot; %��һ��֡����ʱ϶�Ľ���λ��,���λ��
    for ind_frame = 1:N_Frame %�Գ�֡���б���
        cur_pos = pos_seq(ind_frame); %��ǰ�ڵ���������� 
        % �����ڵ�Ļ�����Ϣ
        for tt=1:par.Nodes.Num %�Ը����ڵ���б���
            Nodes(tt).Sigma = par.Nodes.Sigma(cur_pos,tt); % ��ǰ�ڵ��ڵ�ǰ���������µ���Ӱ˥��ı�׼��Sigma
        end
        %% �������Խڵ������Դ����
        % ȷ����������һ��֡����ʱ϶ĩβλ���뵱ǰ��֡beaconλ�ü��ʱ϶������һ��֡����ʱ϶ĩβλ�õ������ɼ�״̬
        re_num_slots = par.MAC.N_Slot - last_end_slot_ind;
        if ind_frame ==1 %��ʼ���ڵ�״̬
            EH_last_status(1,:) = EH_status_seq(:,1)';
        else 
            ind_absolute_slots = (ind_frame-2)*par.MAC.N_Slot + last_end_slot_ind; %��һ��֡����ʱ϶��ĩβλ��������ʱ϶�еľ�������
            for ind_node = 1:par.Nodes.Num %�Ը����ڵ���б���
                EH_last_status(1,ind_node) = EH_status_seq(ind_node,ind_absolute_slots(1,ind_node));
            end   
        end
        sta_last_EH_status = [sta_last_EH_status;EH_last_status];
        sta_re_num_slots = [sta_re_num_slots ; re_num_slots];
        % �Ż���Դ����
        cur_miu_th = miu_th(cur_pos,:);
        [ Allocate, optimize_problems ] = resourceAllocationScheme( cur_pos, cur_miu_th, re_num_slots, EH_last_status, EH_P_tran, par);
        sta_optimize_problems = [sta_optimize_problems; optimize_problems];
        sta_Allocate{1,ind_frame}= Allocate;
        
        %% ���������ڵ�����ݰ�����
        for ind_node = 1:par.Nodes.Num %�Ը����ڵ���б���
            cur_shadow = shadow_seq(ind_node,((ind_frame-1)*par.MAC.N_Slot+1):(ind_frame*par.MAC.N_Slot)); %��ǰ�ڼ����Ӱ˥���ֵ
            %% ���²���
            % ������ӣ����нڵ��ڲ�ͬ��֡��������Ӷ���ͬ
            rand_seed = rand_state*par.Nodes.Num*N_Frame+ (ind_node-1)*N_Frame+(ind_frame-1) ;
% % %             % ��ʹ�ù̶�����Դ��������д�ڵ�����ͳ�ƺ���
% % %             Allocate(ind_node).power = par.PHY.P_min;
% % %             Allocate(ind_node).src_rate = par.Nodes.Nor_SrcRates(ind_node);
% % %             Allocate(ind_node).slot = zeros(1, par.MAC.N_Slot); %�����������ԣ�ֱ�ӽ�����ʱ϶������ڵ�
% % %             Allocate(ind_node).slot(1,20:40) =1;
            % ģ������ڵ�����ݰ�����
            [ Queue(ind_node).tranQueue, Queue(ind_node).arrivalQueue, Queue(ind_node).bufferQueue, last_end_slot_ind(ind_node)] = nodeTranPerFrame(ind_frame, cur_shadow, last_end_slot_ind(ind_node), Allocate(ind_node), Nodes(ind_node), par.MAC, par.Channel,par.Constraints, Queue(ind_node).tranQueue, Queue(ind_node).arrivalQueue, Queue(ind_node).bufferQueue, rand_seed);
            
        end
    end
    
    %% ����ͳ��
    QoS = calQosPerformance( Queue, par.MAC);
    
    %% չʾ���ܱ���
    plotQoSPerformance(QoS, Queue);
    
    
   