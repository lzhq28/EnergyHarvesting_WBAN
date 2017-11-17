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
    deltaPL_ind_max = 10;
    deltaPL_step = 2; %��λdBm
    parfor deltaPL_ind =1:deltaPL_ind_max
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
        [ miu_th ] = calEquPLRThreshold( par.Nodes, par.Channel, par.Constraints, precision, re_cal_miu_state);
        % �Ż����䲻ͬ���������µĴ��书�ʺ���������
        [ AllocatePowerRate, opti_power_problems] = allocateTranPower( miu_th, par);

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
        end

        %% ѭ��ͳ�Ʒ���
        EH_last_status = []; % �����ڵ��ڸ�����֡�ڷ���ʱ϶����λ�õ������м�״̬
        sta_last_EH_status = [];
        sta_re_num_slots = [];
        sta_AllocateSlots ={}; %ͳ��ʱ϶����Ľ��
        sta_opti_slots_problems = []; %ͳ��ʱ϶�Ż������е�����
        last_end_slot_ind = ones(1,par.Nodes.Num)*par.MAC.N_Slot; %��һ��֡����ʱ϶�Ľ���λ��,���λ��
        ind_absolute_slots = zeros(1,par.Nodes.Num);%��һ��֡����ʱ϶��ĩβλ��������ʱ϶�еľ�������
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
            [ AllocateSlots, opti_problem  ] = allocateSlots(cur_pos,AllocatePowerRate{1,cur_pos}, re_num_slots, EH_last_status, EH_P_tran, par);
            sta_opti_slots_problems(1,ind_frame) = opti_problem;
            sta_AllocateSlots{1,ind_frame} = AllocateSlots;
            cur_Allocate = {}; %��ʼ����ǰ��֡����Դ������
            %% ���������ڵ�����ݰ�����
            for ind_node = 1:par.Nodes.Num %�Ը����ڵ���б���
                cur_shadow = shadow_seq(ind_node,((ind_frame-1)*par.MAC.N_Slot+1):(ind_frame*par.MAC.N_Slot)); %��ǰ�ڼ����Ӱ˥���ֵ
                EH_begin_ind = ind_absolute_slots(ind_node)+1;
                EH_end_ind = ind_frame*par.MAC.N_Slot;
                cur_EH_collect = EH_collect_seq(ind_node, EH_begin_ind:EH_end_ind);
               %% ͳ����Դ����Ľ��
                cur_Allocate.power =  AllocatePowerRate{cur_pos}{ind_node}.power;
                cur_Allocate.src_rate = AllocatePowerRate{cur_pos}{ind_node}.src_rate;
                cur_Allocate.slot = AllocateSlots(ind_node,:);
              %% ���²���
                % ������ӣ����нڵ��ڲ�ͬ��֡��������Ӷ���ͬ
                rand_seed = rand_state*par.Nodes.Num*N_Frame+ (ind_node-1)*N_Frame+(ind_frame-1);
                % �����ڵ�����ݰ�����
                [ Queue(ind_node).tranQueue, Queue(ind_node).arrivalQueue, Queue(ind_node).bufferQueue, last_end_slot_ind(ind_node)] = nodeTranPerFrame(ind_frame, cur_shadow, cur_EH_collect, last_end_slot_ind(ind_node), cur_Allocate, Nodes(ind_node), par.MAC, par.Channel,par.Constraints, Queue(ind_node).tranQueue, Queue(ind_node).arrivalQueue, Queue(ind_node).bufferQueue, rand_seed);
            end
        end
        time_2 =clock;
        time_cost = etime(time_2,time_1)
        disp(['deltaPL:',num2str(deltaPL),'��������ʱ�䣺',num2str(time_cost),'s'])
        % ���������
        path_names = configurePaths(); %����·������
        save_path_name = strcat([path_names.save_prefix,num2str(deltaPL),'.mat']);   
        parsave(save_path_name, deltaPL, Queue, AllocatePowerRate, sta_AllocateSlots, shadow_seq, pos_seq, EH_status_seq, EH_collect_seq, EH_P_tran)
    end

    %% ����ͳ��
     show_deltaPL_ind =1;
     analysisQoSPerformance(deltaPL_step, deltaPL_ind_max, show_deltaPL_ind)
    

   