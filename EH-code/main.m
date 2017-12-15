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
    deltaPL_ind_max = 10;
    deltaPL_step = 2; %��λdBm
    alg_names = {'myRA','offline','online','fixed'}; 
    alg_myRA_details ={'without_rate',''};
    cal_alg_id = 4; % ��������Ҫ���е��㷨��id��
    parfor deltaPL_ind =deltaPL_ind_max:deltaPL_ind_max  
        %% ��ʼ��ϵͳ����
        % deltaPL_ind = deltaPL_ind_max;
        time_1 =clock;
        deltaPL = (deltaPL_ind-1)*deltaPL_step;
        par = initialParameters(deltaPL); %��ʼ��ϵͳ����    
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
        [ EH_status_seq, EH_collect_seq, EH_P_tran] = energyHarvestStatistic( pos_seq, par.EnergyHarvest, par.MAC, rand_state); 
        % ����PLR�ĵ�Ч���ޣ�ƽ�����������miu_th
        [ miu_th ] = calEquPLRThreshold( par.Nodes, par.Channel, par.Constraints, precision, re_cal_miu_state,par.EnergyHarvest.t_cor_EH);
        %% ��Բ�ͬ���㷨���ò�ͬ�ķ��䷽ʽ
        % �Դ��书�ʡ��������ʺ�ʱ϶���з���
        
        if cal_alg_id == 1
            % �Ż����䲻ͬ���������µĴ��书�ʺ���������
            disp(strcat('Info:excute the',{' '},alg_names(cal_alg_id),' method'));
            [ AllocatePowerRate, opti_power_problems] = allocateTranPower( miu_th, par); 
        elseif cal_alg_id == 2 % ��offline������Դ����
            disp(strcat('Info:excute the',{' '},alg_names(cal_alg_id),' method'));
            [offline_power] =compareOffline(shadow_seq, pos_seq, EH_status_seq, EH_collect_seq, par);  
            conf_srcRates = par.Nodes.Nor_SrcRates;
            [AllocateRate] = allocateRateFixed(conf_srcRates,par.Nodes.Num);
            [AllocateSlots] = allocateSlotsFixed(conf_srcRates,par);
            [ AllocatePowerRate, opti_power_problems] = allocateTranPower( miu_th, par); 
        elseif cal_alg_id ==3 % online��Դ���䷽��
            disp(strcat('Info:excute the',{' '},alg_names(cal_alg_id),' method'));
            conf_powers = [0.05,0.05,0.05,0.05,0.2];%repmat(0.05,par.Nodes.Num,1);
            conf_srcRates = par.Nodes.Nor_SrcRates;
            [AllocatePower] = allocatePowerFixed(conf_powers,par.Nodes.Num);
            [AllocateRate] = allocateRateFixed(conf_srcRates,par.Nodes.Num);
            [AllocateSlots] = allocateSlotsFixed(conf_srcRates,par);
            [ AllocatePowerRate, opti_power_problems] = allocateTranPower( miu_th, par); 
        elseif cal_alg_id ==4 % fixed�̶����书�ʺʹ���ʱ϶�ķ���
            disp(strcat('Info:excute the',{' '},alg_names(cal_alg_id),' method'));
            conf_powers = [0.05,0.05,0.05,0.05,0.2];%repmat(0.05,par.Nodes.Num,1);
            conf_srcRates = par.Nodes.Nor_SrcRates;
            [AllocatePower] = allocatePowerFixed(conf_powers,par.Nodes.Num);
            [AllocateRate] = allocateRateFixed(conf_srcRates,par.Nodes.Num);
            [AllocateSlots] = allocateSlotsFixed(conf_srcRates,par);
            [ AllocatePowerRate, opti_power_problems] = allocateTranPower( miu_th, par); 
        end
        
        %% ���ܷ���
        % ��ʼ�����ֲ�ͬ�Ķ���
        Queue = {};
        for ind_node = 1:par.Nodes.Num
            Queue(ind_node).tranQueue = []; %���ݰ�������У��������ݰ��������Ϣ:[packetID, gen_frameID, t_gen_offset, tran_frameID, t_tran_offset, t_tran_cost, tran_power, tran_rate, tran_state]
            Queue(ind_node).arrivalQueue = []; %���ݰ��ﵽ���У� [pacektID,frameID,t_gen_offset,packetType]
            Queue(ind_node).bufferQueue = [0,1,1,0]; %����״̬����, [frameID, beginIndex, endIndex, residue_energy]
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
            Nodes(ind_node).battery_capacity = par.EnergyHarvest.battery_capacity; % �������
        end

        %% ѭ��ͳ�Ʒ���
        EH_last_status = []; % �����ڵ��ڸ�����֡�ڷ���ʱ϶����λ�õ������м�״̬
        sta_last_EH_status = [];
        sta_re_num_slots = [];
        sta_AllocateSlots ={}; %ͳ��ÿ����֡�����ʱ϶
        sta_opti_slots_problems = []; %ͳ��ʱ϶�Ż������е�����
        sta_GOODSET ={};
        sta_BADSET = {};
        last_end_slot_ind = ones(1,par.Nodes.Num)*par.MAC.N_Slot; %��һ��֡����ʱ϶�Ľ���λ��,���λ��
        ind_absolute_slots = zeros(1,par.Nodes.Num);%��һ��֡����ʱ϶��ĩβλ��������ʱ϶�еľ�������
        residue_energy = zeros(1,par.Nodes.Num); %�����ڵ㴫��ʱ϶�������ʣ������ 
        re_num_packets = zeros(1,par.Nodes.Num); %�����ڵ㴫��ʱ϶������Ļ�����ʣ�����ݰ� 
        str_process ='*';
        for ind_frame = 1:N_Frame %�Գ�֡���б���
            if mod(ind_frame, N_Frame/20)==0
                disp(strcat(str_process,' processing:',num2str(ind_frame/N_Frame*100),'%'))
                str_process = strcat(str_process,'*');
            end
            cur_pos = pos_seq(ind_frame); %��ǰ�ڵ���������� 
            % �����ڵ�Ļ�����Ϣ
            for tt=1:par.Nodes.Num %�Ը����ڵ���б���
                Nodes(tt).Sigma = par.Nodes.Sigma(cur_pos,tt); % ��ǰ�ڵ��ڵ�ǰ���������µ���Ӱ˥��ı�׼��Sigma
                residue_energy(1,tt) = Queue(tt).bufferQueue(end,4); %�ڵ�ʣ������
            end
            %% �������Խڵ������Դ����
            % ȷ����������һ��֡����ʱ϶ĩβλ���뵱ǰ��֡beaconλ�ü��ʱ϶������һ��֡����ʱ϶ĩβλ�õ������ɼ�״̬
            re_num_slots = par.MAC.N_Slot - last_end_slot_ind;
            if ind_frame ==1 %��ʼ���ڵ�״̬
                EH_last_status(1,:) = EH_status_seq(:,1)';
                re_num_packets = zeros(1,par.Nodes.Num); %�����ڵ㴫��ʱ϶������Ļ�����ʣ�����ݰ� 
            else 
                ind_absolute_slots = (ind_frame-2)*par.MAC.N_Slot + last_end_slot_ind; %��һ��֡����ʱ϶��ĩβλ��������ʱ϶�еľ�������
                for ind_node = 1:par.Nodes.Num %�Ը����ڵ���б���
                    EH_last_status(1,ind_node) = EH_status_seq(ind_node,ind_absolute_slots(1,ind_node));
                    re_num_packets(1,ind_node) = Queue(ind_node).bufferQueue(end,3)-Queue(ind_node).bufferQueue(end,2)+1;% %�����ڵ㴫��ʱ϶������Ļ�����ʣ�����ݰ� 
                end   
            end
            sta_last_EH_status = [sta_last_EH_status;EH_last_status];
            sta_re_num_slots = [sta_re_num_slots ; re_num_slots];
            % �Ż���Դ����
            if cal_alg_id == 1 %���ķ�����ʱ϶���䷽��
                [ AllocateSlots, opti_problem, sta_GOODSET{ind_frame}, sta_BADSET{ind_frame} ] = allocateSlots(cur_pos,AllocatePowerRate{1,cur_pos}, residue_energy, re_num_packets, re_num_slots, EH_last_status, EH_P_tran, par);                
                sta_opti_slots_problems(ind_frame,1:2) = opti_problem;
            end
            sta_AllocateSlots{1,ind_frame} = AllocateSlots;
            cur_Allocate = {}; %��ʼ����ǰ��֡����Դ������
            %% ���������ڵ�����ݰ�����
            for ind_node = 1:par.Nodes.Num %�Ը����ڵ���б���
                cur_shadow = shadow_seq(ind_node,((ind_frame-1)*par.MAC.N_Slot+1):(ind_frame*par.MAC.N_Slot)); %��ǰ�ڼ����Ӱ˥���ֵ
                EH_begin_ind = ind_absolute_slots(ind_node)+1;
                EH_end_ind = ind_frame*par.MAC.N_Slot;
                cur_EH_collect = EH_collect_seq(ind_node, EH_begin_ind:EH_end_ind);
               %% ͳ����Դ����Ľ��
                if cal_alg_id ==1  %��������ķ���
                    cur_Allocate.src_rate = AllocatePowerRate{cur_pos}{ind_node}.src_rate;
                    cur_Allocate.slot = AllocateSlots(ind_node,:);
                    cur_Allocate.power = repmat(AllocatePowerRate{cur_pos}{ind_node}.power,1,par.MAC.N_Slot);
                elseif cal_alg_id == 2 % online ����
                    cur_Allocate.src_rate = AllocateRate(ind_node);
                    cur_Allocate.slot = AllocateSlots(ind_node,:);
                    cur_Allocate.power = offline_power(ind_node,((ind_frame-1)*par.MAC.N_Slot+1):(ind_frame*par.MAC.N_Slot));%����offline�������õĹ���
                elseif cal_alg_id == 3 % offline����
                    cur_Allocate.src_rate = AllocateRate(ind_node);
                    cur_Allocate.slot = AllocateSlots(ind_node,:);
                    cur_Allocate.power =  repmat( AllocatePower(ind_node),1,par.MAC.N_Slot);
                elseif cal_alg_id ==4 % fixed�̶����书�ʺʹ���ʱ϶�ķ���
                    cur_Allocate.src_rate = AllocateRate(ind_node);                     
                    cur_Allocate.slot = AllocateSlots(ind_node,:);
                    cur_Allocate.power = repmat( AllocatePower(ind_node),1,par.MAC.N_Slot);
                end
              %% ���²���
                % ������ӣ����нڵ��ڲ�ͬ��֡��������Ӷ���ͬ
                rand_seed = rand_state*par.Nodes.Num*N_Frame+(ind_node-1)*N_Frame+(ind_frame-1);
                % �����ڵ�����ݰ�����
                if cal_alg_id == 3 %��online������������
                    [ Queue(ind_node).tranQueue, Queue(ind_node).arrivalQueue, Queue(ind_node).bufferQueue, last_end_slot_ind(ind_node)] = nodeTranPerFrame_online(ind_frame, cur_shadow, cur_EH_collect, last_end_slot_ind(ind_node), cur_Allocate, Nodes(ind_node), par.MAC, par.Channel,par.Constraints, Queue(ind_node).tranQueue, Queue(ind_node).arrivalQueue, Queue(ind_node).bufferQueue, rand_seed);
                else
                    [ Queue(ind_node).tranQueue, Queue(ind_node).arrivalQueue, Queue(ind_node).bufferQueue, last_end_slot_ind(ind_node)] = nodeTranPerFrame(ind_frame, cur_shadow, cur_EH_collect, last_end_slot_ind(ind_node), cur_Allocate, Nodes(ind_node), par.MAC, par.Channel,par.Constraints, Queue(ind_node).tranQueue, Queue(ind_node).arrivalQueue, Queue(ind_node).bufferQueue, rand_seed);
                end
            end
        end
        time_2 =clock;
        time_cost = etime(time_2,time_1)
        disp(['deltaPL:',num2str(deltaPL),'��������ʱ�䣺',num2str(time_cost),'s'])
        % ���������
        path_names = configurePaths(par.EnergyHarvest.t_cor_EH); %����·������
        if cal_alg_id == 1 %��������ķ���
            save_path_name = strcat([path_names.myRA_prefix,num2str(deltaPL),'.mat']);   
        elseif cal_alg_id == 2 % offline����
            save_path_name = strcat([path_names.offline_prefix,num2str(deltaPL),'.mat']);
        elseif cal_alg_id ==3 % online����
            save_path_name = strcat([path_names.online_prefix,num2str(deltaPL),'.mat']);
        elseif cal_alg_id == 4
            save_path_name = strcat([path_names.fixed_prefix,num2str(deltaPL),'.mat']);
        end 
        parsave(save_path_name, deltaPL, Queue, AllocatePowerRate, sta_AllocateSlots, shadow_seq, pos_seq, EH_status_seq, EH_collect_seq, EH_P_tran);
    end
    
    %% ����ͳ��
     show_deltaPL_ind =10;
     par = initialParameters(0); %��ʼ��ϵͳ����  
     analysisQoSPerformance(deltaPL_step, deltaPL_ind_max, show_deltaPL_ind,par.EnergyHarvest.t_cor_EH)
    
    %% ���ܶԱȣ��Աȱ�������ķ����ͶԱȷ���
    show_deltaPL_ind =10;
    load_data = {}; %���ص�����
    deltaPL =  (show_deltaPL_ind-1)*deltaPL_step;
    t_cor_EH = par.EnergyHarvest.t_cor_EH;
    path_names = configurePaths(t_cor_EH); %����·������
     
    for alg_id =1:size(alg_names,2)
        if alg_id == 1 %��������ķ���
            load_path_name = strcat([path_names.myRA_prefix,num2str(deltaPL),'.mat']);   
        elseif alg_id == 2 % offline����
            load_path_name = strcat([path_names.offline_prefix,num2str(deltaPL),'.mat']);
        elseif alg_id ==3 % online����
            load_path_name = strcat([path_names.online_prefix,num2str(deltaPL),'.mat']);
        elseif alg_id == 4 % �̶��ķ���
             load_path_name = strcat([path_names.fixed_prefix,num2str(deltaPL),'.mat']);
        end 
        load_data = load(load_path_name);
        cur_QoS = calQosPerformance( load_data.Queue, par.MAC,par.Nodes.packet_length);
        for ind_node =1:par.Nodes.Num
            compareResults.energy_per_bit(alg_id,ind_node) = cur_QoS(ind_node).energy_per_bit;
            compareResults.PLR_pathloss(alg_id,ind_node) = cur_QoS(ind_node).PLR_pathloss;
            compareResults.PLR_overflow(alg_id,ind_node) = cur_QoS(ind_node).PLR_overflow;
            compareResults.PLR_overdelay(alg_id,ind_node) = cur_QoS(ind_node).PLR_overdelay;
            compareResults.PLR_ave(alg_id,ind_node) = cur_QoS(ind_node).PLR_ave;
            compareResults.Delay_ave(alg_id,ind_node) = cur_QoS(ind_node).Delay_ave;
            compareResults.Energy_cost(alg_id,ind_node) = cur_QoS(ind_node).Energy_cost;
            compareResults.total_data(alg_id,ind_node) = cur_QoS(ind_node).total_data;
        end
    end
    figure
    subplot(221)
    bar(compareResults.energy_per_bit')
    xlabel('Node index')
    ylabel('energy efficiency (uJ/bit)')
    title('Energy efficiency')
    legend('proposed algorithm','optimal offline ','online','fixed')
    subplot(222)
    bar(compareResults.PLR_ave'*100)
    xlabel('Node index')
    ylabel('Average PLR (%)')
    title('Average PLR')
    legend('proposed algorithm','optimal offline ','online','fixed')
    subplot(223)
    bar(compareResults.Delay_ave')
    xlabel('Node index')
    ylabel('Average Delay (ms)')
    title('Average Delay')
    legend('proposed algorithm','optimal offline ','online','fixed')
    subplot(224)
    bar(compareResults.total_data')
    xlabel('Node index')
    ylabel('Average Throughput (bit/s)')
    title('Average Delay')
    legend('proposed algorithm','optimal offline ','online','fixed')
    
    
   