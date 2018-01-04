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
    deltaPL_ind_min = 5;
    deltaPL_ind_max = 10;
    deltaPL_step = 2; %��λdBm
    alg_names = {'myRA','offline','online','fixed'}; 
    alg_myRA_details ={'with-rate-slot','only-with-rate','only-with-slot'};
    cal_alg_id = 1; % ��������Ҫ���е��㷨��id��
    cal_myRA_id = 1; %���ñ��ķ�����ϸ�ڣ��Ƿ�����������ʵ��ڲ��ԣ��Ƿ����slot���÷���
    %parfor deltaPL_ind =deltaPL_ind_max:deltaPL_ind_max 
    %parfor cal_myRA_id =1:3
    %parfor EH_ratio = 0.1:0.2:2
    t_cor_EH_set =[40,80,150,300,500,1000];
    t_cor_EH = t_cor_EH_set(6); %�����ɼ����ʱ�䣬��λms
    parfor EH_ratio_ind = 5:1:10
        EH_ratio = EH_ratio_ind * 0.1;
        %for cal_myRA_id = 1:3
            for deltaPL_ind = deltaPL_ind_min :deltaPL_ind_max
                %% ��ʼ��ϵͳ����
                %deltaPL_ind = deltaPL_ind_max;
                time_1 =clock;
                deltaPL = (deltaPL_ind-1)*deltaPL_step;               
                par = initialParameters(deltaPL, EH_ratio,t_cor_EH); %��ʼ��ϵͳ����    
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
                    if cal_myRA_id == 2 % 'only_with_rate'
                        [AllocateSlots] = allocateSlotsFixed(par.Nodes.Nor_SrcRates,par);
                    elseif cal_myRA_id == 3  % 'only_with_slot'
                        [AllocateRate] = allocateRateFixed(par.Nodes.Nor_SrcRates,par.Nodes.Num);
                    end
                elseif cal_alg_id == 2 % ��offline������Դ����
                    disp(strcat('Info:excute the',{' '},alg_names(cal_alg_id),' method'));
                    offline_PLR_th = 0.01;
                    [offline_power] =compareOffline(shadow_seq, pos_seq, EH_status_seq, EH_collect_seq,offline_PLR_th, par);  
                    conf_srcRates = par.Nodes.Nor_SrcRates;
                    [AllocateRate] = allocateRateFixed(conf_srcRates,par.Nodes.Num);
                    [AllocateSlots] = allocateSlotsFixed(conf_srcRates,par);
                    [AllocatePowerRate, opti_power_problems] = allocateTranPower( miu_th, par); 
                elseif cal_alg_id ==3 % online��Դ���䷽��
                    disp(strcat('Info:excute the',{' '},alg_names(cal_alg_id),' method'));
                    conf_powers = [0.6,0.6,0.6,0.6,0.7];%repmat(0.05,par.Nodes.Num,1);
                    conf_srcRates = par.Nodes.Nor_SrcRates;
                    [AllocatePower] = allocatePowerFixed(conf_powers,par.Nodes.Num);
                    [AllocateRate] = allocateRateFixed(conf_srcRates,par.Nodes.Num);
                    [AllocateSlots] = allocateSlotsFixed(conf_srcRates,par);
                    [ AllocatePowerRate, opti_power_problems] = allocateTranPower( miu_th, par); 
                elseif cal_alg_id ==4 % fixed�̶����书�ʺʹ���ʱ϶�ķ���
                    disp(strcat('Info:excute the',{' '},alg_names(cal_alg_id),' method'));
                    conf_powers = [0.6,0.6,0.6,0.6,0.7];%repmat(0.05,par.Nodes.Num,1);
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
                    if (cal_alg_id == 1)&&(cal_myRA_id ~= 2) %���ķ�����ʱ϶���䷽��
                        [ AllocateSlots, opti_problem, sta_GOODSET{ind_frame}, sta_BADSET{ind_frame} ] = allocateSlots(cur_pos,AllocatePowerRate{1,cur_pos}, residue_energy, re_num_packets, re_num_slots, EH_last_status, EH_P_tran, par);                
                        sta_opti_slots_problems(ind_frame,1:2) = opti_problem;
%                     elseif (cal_alg_id == 2)
%                         [ AllocateSlots, opti_problem, sta_GOODSET{ind_frame}, sta_BADSET{ind_frame} ] = allocateSlots(cur_pos,AllocatePowerRate{1,cur_pos}, residue_energy, re_num_packets, re_num_slots, EH_last_status, EH_P_tran, par);
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
                            cur_Allocate.power = repmat(AllocatePowerRate{cur_pos}{ind_node}.power,1,par.MAC.N_Slot);
                            if cal_myRA_id==1
                                cur_Allocate.src_rate = AllocatePowerRate{cur_pos}{ind_node}.src_rate;
                                cur_Allocate.slot = AllocateSlots(ind_node,:);
                            elseif cal_myRA_id == 2
                                cur_Allocate.src_rate = AllocatePowerRate{cur_pos}{ind_node}.src_rate;
                                cur_Allocate.slot = AllocateSlots(ind_node,:);
                            elseif cal_myRA_id == 3
                                cur_Allocate.src_rate = AllocateRate(ind_node);
                                cur_Allocate.slot = AllocateSlots(ind_node,:);
                            end
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
                        elseif cal_alg_id ==4 
                            [ Queue(ind_node).tranQueue, Queue(ind_node).arrivalQueue, Queue(ind_node).bufferQueue, last_end_slot_ind(ind_node)] = nodeTranPerFrame_Fixed(ind_frame, cur_shadow, cur_EH_collect, last_end_slot_ind(ind_node), cur_Allocate, Nodes(ind_node), par.MAC, par.Channel,par.Constraints, Queue(ind_node).tranQueue, Queue(ind_node).arrivalQueue, Queue(ind_node).bufferQueue, rand_seed);
                        else
                            [ Queue(ind_node).tranQueue, Queue(ind_node).arrivalQueue, Queue(ind_node).bufferQueue, last_end_slot_ind(ind_node)] = nodeTranPerFrame(ind_frame, cur_shadow, cur_EH_collect, last_end_slot_ind(ind_node), cur_Allocate, Nodes(ind_node), par.MAC, par.Channel,par.Constraints, Queue(ind_node).tranQueue, Queue(ind_node).arrivalQueue, Queue(ind_node).bufferQueue, rand_seed);
                        end
                    end
                end
                time_2 =clock;
                time_cost = etime(time_2,time_1)
                disp(['deltaPL:',num2str(deltaPL),'��������ʱ�䣺',num2str(time_cost),'s'])
                % ���������
                save_path_name = conPathName(par.EnergyHarvest.t_cor_EH,deltaPL,cal_alg_id,cal_myRA_id, EH_ratio);
                parsave(save_path_name, deltaPL, Queue, AllocatePowerRate, sta_AllocateSlots, shadow_seq, pos_seq, EH_status_seq, EH_collect_seq, EH_P_tran);
            end
        %end
    end
    
    %% �۲�ĳ��ʵ��ķ�����
    show_t_cor_EH = 40;
    show_deltaPL = 18;
    show_cal_alg_id = 1;
    show_cal_myRA_id =1;
    show_EH_ratio = 1;
    analysisQoSPerformance(show_t_cor_EH, show_deltaPL, show_cal_alg_id, show_cal_myRA_id, show_EH_ratio);
    
    %% ������ͬ�㷨�����ܺû�
    show_t_cor_EH = 40;
    show_cal_myRA_id = 1;
    EH_ratio_set=0.5:0.1:1;
    cp_PLR_ave =[];
    cp_Delay =[];
    cp_energy_per_bit =[];
    cp_bandwidth_uti =[];
    cp_throughput =[];
    for show_cal_alg_id = 1:size(alg_names,2)
        for deltaPL_ind = deltaPL_ind_min :(deltaPL_ind_max)
            show_deltaPL = (deltaPL_ind-1)*deltaPL_step;
            for show_EH_ratio_ind =1:size( EH_ratio_set,2)
                show_EH_ratio = EH_ratio_set(show_EH_ratio_ind);
                par = initialParameters(show_deltaPL, show_EH_ratio, show_t_cor_EH ); %��ʼ��ϵͳ����
                if show_cal_alg_id ==1
                    for show_cal_myRA_id =1:3
                        [ load_path_name ] = conPathName(show_t_cor_EH, show_deltaPL, show_cal_alg_id, show_cal_myRA_id, show_EH_ratio);
                        cur_data = load(load_path_name);
                        cur_QoS = calQosPerformance( cur_data.Queue,cur_data.sta_AllocateSlots, par.MAC,par.Nodes.packet_length);
                        cp_PLR_ave(show_cal_alg_id, show_cal_myRA_id, deltaPL_ind, show_EH_ratio_ind) = mean(cur_QoS.PLR_ave);
                        cp_Delay(show_cal_alg_id, show_cal_myRA_id, deltaPL_ind, show_EH_ratio_ind) = mean(cur_QoS.Delay_ave);
                        cp_energy_per_bit(show_cal_alg_id, show_cal_myRA_id, deltaPL_ind, show_EH_ratio_ind) = mean(cur_QoS.energy_per_bit);
                        cp_bandwidth_uti(show_cal_alg_id, show_cal_myRA_id, deltaPL_ind, show_EH_ratio_ind) = mean(cur_QoS.bandwidth_utilization);
                        cp_throughput(show_cal_alg_id, show_cal_myRA_id, deltaPL_ind, show_EH_ratio_ind) = mean(cur_QoS.throughput);
                    end
                else
                    show_cal_myRA_id =1;
                    [ load_path_name ] = conPathName(show_t_cor_EH, show_deltaPL, show_cal_alg_id, show_cal_myRA_id, show_EH_ratio);
                    cur_data = load(load_path_name);
                    cur_QoS = calQosPerformance( cur_data.Queue,cur_data.sta_AllocateSlots, par.MAC,par.Nodes.packet_length);
                    cp_PLR_ave(show_cal_alg_id, show_cal_myRA_id, deltaPL_ind, show_EH_ratio_ind) = mean(cur_QoS.PLR_ave);
                    cp_Delay(show_cal_alg_id, show_cal_myRA_id, deltaPL_ind, show_EH_ratio_ind) = mean(cur_QoS.Delay_ave);
                    cp_energy_per_bit(show_cal_alg_id, show_cal_myRA_id, deltaPL_ind, show_EH_ratio_ind) = mean(cur_QoS.energy_per_bit);
                    cp_bandwidth_uti(show_cal_alg_id, show_cal_myRA_id, deltaPL_ind, show_EH_ratio_ind) = mean(cur_QoS.bandwidth_utilization);
                    cp_throughput(show_cal_alg_id, show_cal_myRA_id, deltaPL_ind, show_EH_ratio_ind) = mean(cur_QoS.throughput);
                end
            end
        end
    end
    
    %% �ԱȲ�ͬ���������ܱ���
    size_4D=size(cp_PLR_ave)
    color_set = linspecer(4);
    show_EH_ratio_ind = 6;
    x_range_ind = deltaPL_ind_min:deltaPL_ind_max;
    x_range = (x_range_ind -1)*deltaPL_step;
    line_width =8;
    marker_size =20;
    %PLR����
    figure(1)
    hold on
    plot(x_range, reshape(cp_PLR_ave(1, 1,x_range_ind, show_EH_ratio_ind),1,size(x_range_ind,2))*100,'-s', 'Markersize',marker_size,'linewidth',line_width ,'color',color_set(1,:))
    hold on
    plot(x_range, reshape(cp_PLR_ave(2, 1,x_range_ind, show_EH_ratio_ind),1,size(x_range_ind,2))*100,'-<', 'Markersize',marker_size,'linewidth',line_width ,'color',color_set(2,:))
    hold on
    plot(x_range, reshape(cp_PLR_ave(3, 1,x_range_ind, show_EH_ratio_ind),1,size(x_range_ind,2))*100,'->', 'Markersize',marker_size,'linewidth',line_width ,'color',color_set(3,:))
    grid on
    box on
    xlabel('Mean \mu_{s} of shadowing (dBm)')
    ylabel('Average PLR (%)')
    h=legend('PRS-RA','Offline','Online')
    set(h,'FontSize',30)
    set(get(gca,'XLabel'),'FontSize',30,'FontName','Times New Roman')
    set(get(gca,'YLabel'),'FontSize',30,'FontName','Times New Roman');%����Y������������С������
    set(gca,'FontName','Times New Roman','FontSize',25)%���������������С�����͡�
    set(gca,'XColor','k')
    set(gca,'linewidth',3)
    set(gca,'GridLineStyle', '--')
    %Delay����
    figure(2)
    hold on
    plot(x_range, reshape(cp_Delay(1, 1,x_range_ind, show_EH_ratio_ind),1,size(x_range_ind,2)),'-s', 'Markersize',marker_size,'linewidth',line_width ,'color',color_set(1,:))
    hold on
    plot(x_range, reshape(cp_Delay(2, 1,x_range_ind, show_EH_ratio_ind),1,size(x_range_ind,2)),'-<', 'Markersize',marker_size,'linewidth',line_width ,'color',color_set(2,:))
    hold on
    plot(x_range, reshape(cp_Delay(3, 1,x_range_ind, show_EH_ratio_ind),1,size(x_range_ind,2)),'->', 'Markersize',marker_size,'linewidth',line_width ,'color',color_set(3,:))
    grid on
    box on
    xlabel('Mean \mu_{s} of shadowing (dBm)')
    ylabel('Packet Delay (ms)')
    h=legend('PRS-RA','Offline','Online')
    set(h,'FontSize',30)
    set(get(gca,'XLabel'),'FontSize',30,'FontName','Times New Roman')
    set(get(gca,'YLabel'),'FontSize',30,'FontName','Times New Roman');%����Y������������С������
    set(gca,'FontName','Times New Roman','FontSize',25)%���������������С�����͡�
    set(gca,'XColor','k')
    set(gca,'linewidth',3)
    set(gca,'GridLineStyle', '--')
    %energy efficiency����
    figure(3)
    hold on
    plot(x_range, reshape(cp_energy_per_bit(1, 1,x_range_ind, show_EH_ratio_ind),1,size(x_range_ind,2)),'-s', 'Markersize',marker_size,'linewidth',line_width ,'color',color_set(1,:))
    hold on
    plot(x_range, reshape(cp_energy_per_bit(2, 1,x_range_ind, show_EH_ratio_ind),1,size(x_range_ind,2)),'-<', 'Markersize',marker_size,'linewidth',line_width ,'color',color_set(2,:))
    hold on
    plot(x_range, reshape(cp_energy_per_bit(3, 1,x_range_ind, show_EH_ratio_ind),1,size(x_range_ind,2)),'->', 'Markersize',marker_size,'linewidth',line_width ,'color',color_set(3,:))
    grid on
    box on
    xlabel('Mean \mu_{s} of shadowing (dBm)')
    ylabel('Energy cost per bit (uJ/bit)')
    h=legend('PRS-RA','Offline','Online')
    set(h,'FontSize',30)
    set(get(gca,'XLabel'),'FontSize',30,'FontName','Times New Roman')
    set(get(gca,'YLabel'),'FontSize',30,'FontName','Times New Roman');%����Y������������С������
    set(gca,'FontName','Times New Roman','FontSize',25)%���������������С�����͡�
    set(gca,'XColor','k')
    set(gca,'linewidth',3)
    set(gca,'GridLineStyle', '--')
    % throughput����
    figure(4)
    hold on
    plot(x_range, reshape(cp_throughput(1, 1,x_range_ind, show_EH_ratio_ind),1,size(x_range_ind,2)),'-s', 'Markersize',marker_size,'linewidth',line_width ,'color',color_set(1,:))
    hold on
    plot(x_range, reshape(cp_throughput(2, 1,x_range_ind, show_EH_ratio_ind),1,size(x_range_ind,2)),'-<', 'Markersize',marker_size,'linewidth',line_width ,'color',color_set(2,:))
    hold on
    plot(x_range, reshape(cp_throughput(3, 1,x_range_ind, show_EH_ratio_ind),1,size(x_range_ind,2)),'->', 'Markersize',marker_size,'linewidth',line_width ,'color',color_set(3,:))
    grid on
    box on
    xlabel('Mean \mu_{s} of shadowing (dBm)')
    ylabel('Throughput (bit/s)')
    h=legend('PRS-RA','Offline','Online')
    set(h,'FontSize',30)
    set(get(gca,'XLabel'),'FontSize',30,'FontName','Times New Roman')
    set(get(gca,'YLabel'),'FontSize',30,'FontName','Times New Roman');%����Y������������С������
    set(gca,'FontName','Times New Roman','FontSize',25)%���������������С�����͡�
    set(gca,'XColor','k')
    set(gca,'linewidth',3)
    set(gca,'GridLineStyle', '--')
    % throughput����
    figure(5)
    hold on
    plot(x_range, reshape(cp_bandwidth_uti(1, 1,x_range_ind, show_EH_ratio_ind),1,size(x_range_ind,2))*100,'-s', 'Markersize',marker_size,'linewidth',line_width ,'color',color_set(1,:))
    hold on
    plot(x_range, reshape(cp_bandwidth_uti(2, 1,x_range_ind, show_EH_ratio_ind),1,size(x_range_ind,2))*100,'-<', 'Markersize',marker_size,'linewidth',line_width ,'color',color_set(2,:))
    hold on
    plot(x_range, reshape(cp_bandwidth_uti(3, 1,x_range_ind, show_EH_ratio_ind),1,size(x_range_ind,2))*100,'->', 'Markersize',marker_size,'linewidth',line_width ,'color',color_set(3,:))
    grid on
    box on
    xlabel('Mean \mu_{s} of shadowing (dBm)')
    ylabel('Bandwidth utilization (%)')
    h=legend('PRS-RA','Offline','Online')
    set(h,'FontSize',30)
    set(get(gca,'XLabel'),'FontSize',30,'FontName','Times New Roman')
    set(get(gca,'YLabel'),'FontSize',30,'FontName','Times New Roman');%����Y������������С������
    set(gca,'FontName','Times New Roman','FontSize',25)%���������������С�����͡�
    set(gca,'XColor','k')
    set(gca,'linewidth',3)
    set(gca,'GridLineStyle', '--')
   
    %% �������ķ�����ϸ�ڱ���
    % �۲챾�ķ��������׶ηֱ�����ܵ�Ӱ��
    x_range_ind = deltaPL_ind_min:deltaPL_ind_max;
    x_range = (0.5:0.1:1)*100;
    figure(1)
    bar(x_range,reshape(cp_PLR_ave(1, :,end, :)*100,3,6)')
    legend('PRS-RA with PRCS and QASAS','PRS-RA with PRCS','PRS-RA with QASAS')   
    xlabel('EH Efficiency ratio (%)')
    ylabel('Average PLR (%)')
    grid on
    set(get(gca,'XLabel'),'FontSize',30,'FontName','Times New Roman')
    set(get(gca,'YLabel'),'FontSize',30,'FontName','Times New Roman');%����Y������������С������
    set(gca,'FontName','Times New Roman','FontSize',25)%���������������С�����͡�
    set(gca,'XColor','k')
    set(gca,'linewidth',3)
    set(gca,'GridLineStyle', '--')
    figure(2)
    bar(x_range, reshape(cp_Delay(1, :,end, :),3,6)')
    legend('PRS-RA with PRCS and QASAS','PRS-RA with PRCS','PRS-RA with QASAS')   
    xlabel('EH Efficiency ratio (%)')
    ylabel('Packet Delay (ms)')
    grid on
    set(get(gca,'XLabel'),'FontSize',30,'FontName','Times New Roman')
    set(get(gca,'YLabel'),'FontSize',30,'FontName','Times New Roman');%����Y������������С������
    set(gca,'FontName','Times New Roman','FontSize',25)%���������������С�����͡�
    set(gca,'XColor','k')
    set(gca,'linewidth',3)
    set(gca,'GridLineStyle', '--')
    figure(3)
    bar(x_range, reshape(cp_throughput(1, :,end, :),3,6)')
    legend('PRS-RA with PRCS and QASAS','PRS-RA with PRCS','PRS-RA with QASAS')   
    xlabel('EH Efficiency ratio (%)')
    ylabel('Throughput (bit/s)')
    grid on
    set(get(gca,'XLabel'),'FontSize',30,'FontName','Times New Roman')
    set(get(gca,'YLabel'),'FontSize',30,'FontName','Times New Roman');%����Y������������С������
    set(gca,'FontName','Times New Roman','FontSize',25)%���������������С�����͡�
    set(gca,'XColor','k')
    set(gca,'linewidth',3)
    set(gca,'GridLineStyle', '--')
    figure(4)
    bar(x_range, reshape(cp_bandwidth_uti(1, :,end, :)*100,3,6)')
    legend('PRS-RA with PRCS and QASAS','PRS-RA with PRCS','PRS-RA with QASAS')   
    xlabel('EH Efficiency ratio (%)')
    ylabel('Bandwidth utilization (%)')
    grid on
    set(get(gca,'XLabel'),'FontSize',30,'FontName','Times New Roman')
    set(get(gca,'YLabel'),'FontSize',30,'FontName','Times New Roman');%����Y������������С������
    set(gca,'FontName','Times New Roman','FontSize',25)%���������������С�����͡�
    set(gca,'XColor','k')
    set(gca,'linewidth',3)
    set(gca,'GridLineStyle', '--')
    
    % �۲����ʱ������ܵ�Ӱ��
    show_deltaPL = 18;
    show_EH_ratio = 0.5;
    show_cal_alg_id = 1;
    show_cal_myRA_id = 1;
    for node_ind =1:5
        for show_t_cor_EH_ind =1:size(t_cor_EH_set,2)
            show_t_cor_EH = t_cor_EH_set(show_t_cor_EH_ind);
            par = initialParameters(show_deltaPL, show_EH_ratio, show_t_cor_EH ); %��ʼ��ϵͳ����
            [ load_path_name ] = conPathName(show_t_cor_EH, show_deltaPL, show_cal_alg_id, show_cal_myRA_id, show_EH_ratio);
            cur_data = load(load_path_name);
            cur_QoS = calQosPerformance( cur_data.Queue,cur_data.sta_AllocateSlots, par.MAC,par.Nodes.packet_length);
            cor_PLR_ave(show_cal_alg_id,node_ind, show_t_cor_EH_ind) = cur_QoS.PLR_ave(node_ind);
            cor_Delay(show_cal_alg_id, node_ind, show_t_cor_EH_ind) = cur_QoS.Delay_ave(node_ind);
            cor_energy_per_bit(show_cal_alg_id, node_ind, show_t_cor_EH_ind) = cur_QoS.energy_per_bit(node_ind);
            cor_bandwidth_uti(show_cal_alg_id, node_ind, show_t_cor_EH_ind) = cur_QoS.bandwidth_utilization(node_ind);
            cor_throughput(show_cal_alg_id, node_ind,show_t_cor_EH_ind) = cur_QoS.throughput(node_ind);
        end
    end
    figure
    bar(reshape(cor_throughput(1,:,:),5,size(t_cor_EH_set,2)))
    
    % �۲�long-term PRCS���ܱ���
    show_deltaPL = 12;
    show_EH_ratio = 0.5;
    show_cal_alg_id = 1;
    show_cal_myRA_id = 1;
    show_t_cor_EH = t_cor_EH_set(1);
    par = initialParameters(show_deltaPL, show_EH_ratio, show_t_cor_EH ); %��ʼ��ϵͳ����
    [ load_path_name ] = conPathName(show_t_cor_EH, show_deltaPL, show_cal_alg_id, show_cal_myRA_id, show_EH_ratio);
    cur_data = load(load_path_name);
    PRCS_allocate_rate =[];
    PRCS_allocate_power =[];
    for pos_ind =1:3
        for node_ind = 1:5
            PRCS_allocate_rate(pos_ind,node_ind) = cur_data.AllocatePowerRate{pos_ind}{1,node_ind}.src_rate;
            PRCS_allocate_power(pos_ind,node_ind) = cur_data.AllocatePowerRate{pos_ind}{1,node_ind}.power;
        end
    end
    figure
    bar(PRCS_allocate_rate')
    xlabel('Node index')
    ylabel('Source rate (kbps)')
    legend('Still','Walking','Running')
    grid on
    set(get(gca,'XLabel'),'FontSize',30,'FontName','Times New Roman')
    set(get(gca,'YLabel'),'FontSize',30,'FontName','Times New Roman');%����Y������������С������
    set(gca,'FontName','Times New Roman','FontSize',25)%���������������С�����͡�
    set(gca,'XColor','k')
    set(gca,'linewidth',3)
    set(gca,'GridLineStyle', '--')
    
    figure
    bar(PRCS_allocate_power')
    xlabel('Node index')
    ylabel('Transmission power (mW)')
    legend('Still','Walking','Running')
    grid on
    set(get(gca,'XLabel'),'FontSize',30,'FontName','Times New Roman')
    set(get(gca,'YLabel'),'FontSize',30,'FontName','Times New Roman');%����Y������������С������
    set(gca,'FontName','Times New Roman','FontSize',25)%���������������С�����͡�
    set(gca,'XColor','k')
    set(gca,'linewidth',3)
    set(gca,'GridLineStyle', '--')
     
    
    
    % �۲����ʱ϶����ǰ����������ݰ��仯���
    show_t_cor_EH = 40;
    show_deltaPL = 18;
    show_EH_ratio = 1;
    show_cal_alg_id = 1;
    show_node_ind =4;
    cp_Queue ={};
    for show_cal_myRA_id =1:2
        [ load_path_name ] = conPathName(show_t_cor_EH, show_deltaPL, show_cal_alg_id, show_cal_myRA_id, show_EH_ratio);   
        cur_data = load(load_path_name);
        cp_Queue{show_cal_myRA_id} = cur_data.Queue;            
    end
    num_sample = 30; %ֱ��ͼ������
    num_frame = size(cp_Queue{1}(1).bufferQueue,1) -1;
    if num_frame>num_sample
        sample_step = round(num_frame/num_sample);
    end
    x_range = 1:sample_step:num_frame;
    y1 = (cp_Queue{1}(show_node_ind).bufferQueue(x_range+1,3) - cp_Queue{1}(show_node_ind).bufferQueue(x_range+1,2)+1);
    y2 = (cp_Queue{2}(show_node_ind).bufferQueue(x_range+1,3) - cp_Queue{2}(show_node_ind).bufferQueue(x_range+1,2)+1);
    y_max = max(max(y1),max(y2))
    figure(6)
    b = bar(x_range,y1,1);
    b.FaceColor = color_set(1,:);
    xlim([1,num_frame])
    ylim([0,y_max+5])
    grid on
    xlabel('Index of superframe')
    ylabel('Number of packets in buffer') 
    box on
    set(get(gca,'XLabel'),'FontSize',30,'FontName','Times New Roman')
    set(get(gca,'YLabel'),'FontSize',30,'FontName','Times New Roman');%����Y������������С������
    set(gca,'FontName','Times New Roman','FontSize',25)%���������������С�����͡�
    set(gca,'XColor','k')
    set(gca,'linewidth',3)
    set(gca,'GridLineStyle', '--')
    figure(7)
    b = bar(x_range,y2,1);
    b.FaceColor = color_set(1,:);
    xlim([1,num_frame])
    ylim([0,y_max+5])
    grid on
    xlabel('Index of superframe')
    ylabel('Number of packets in buffer') 
        box on
    set(get(gca,'XLabel'),'FontSize',30,'FontName','Times New Roman')
    set(get(gca,'YLabel'),'FontSize',30,'FontName','Times New Roman');%����Y������������С������
    set(gca,'FontName','Times New Roman','FontSize',25)%���������������С�����͡�
    set(gca,'XColor','k')
    set(gca,'linewidth',3)
    set(gca,'GridLineStyle', '--')
    
    
    
    
    
    
    
    
    
    
    
    %% �������ķ���������
    show_t_cor_EH = 40;
    show_deltaPL = 18;
    show_cal_alg_id = 1;
    myRA_PLR_ave =[];
    myRA_Delay =[];
    myRA_energy_per_bit =[];
    myRA_bandwidth_uti =[];
    myRA_throughput =[];
    EH_ratio_set=0.5:0.1:1;%[0.5,0.6,0.7]
    for t_cor_EH_ind =1:size(t_cor_EH_set,2)-1
        show_t_cor_EH = t_cor_EH_set(t_cor_EH_ind);
        for deltaPL_ind = deltaPL_ind_min :(deltaPL_ind_max)
            show_deltaPL = (deltaPL_ind-1)*deltaPL_step;
            for show_cal_myRA_id = 1:3
                for show_EH_ratio_ind =1:size( EH_ratio_set,2)
                    show_EH_ratio = EH_ratio_set(show_EH_ratio_ind);
                    par = initialParameters(show_deltaPL, show_EH_ratio, show_t_cor_EH ); %��ʼ��ϵͳ����
                    [ load_path_name ] = conPathName(show_t_cor_EH, show_deltaPL, show_cal_alg_id, show_cal_myRA_id, show_EH_ratio);
                    cur_data = load(load_path_name);
                    cur_QoS = calQosPerformance( cur_data.Queue,cur_data.sta_AllocateSlots, par.MAC,par.Nodes.packet_length);
                    myRA_PLR_ave(t_cor_EH_ind, deltaPL_ind, show_cal_myRA_id,show_EH_ratio_ind) = mean(cur_QoS.PLR_ave);
                    myRA_Delay(t_cor_EH_ind, deltaPL_ind, show_cal_myRA_id,show_EH_ratio_ind) = mean(cur_QoS.Delay_ave);
                    myRA_energy_per_bit(t_cor_EH_ind, deltaPL_ind, show_cal_myRA_id,show_EH_ratio_ind) = mean(cur_QoS.energy_per_bit);
                    myRA_bandwidth_uti(t_cor_EH_ind, deltaPL_ind, show_cal_myRA_id,show_EH_ratio_ind) = mean(cur_QoS.bandwidth_utilization);
                    myRA_throughput(t_cor_EH_ind, deltaPL_ind, show_cal_myRA_id,show_EH_ratio_ind) = mean(cur_QoS.throughput);
                end
            end
        end
    end
    % �۲������ɼ����ʱ���ϵͳ���ܵ�Ӱ��
    size_4D=size(myRA_PLR_ave)
    x_range = deltaPL_ind_min:deltaPL_ind_max;    
    figure
    bar3(reshape(myRA_PLR_ave(:,end-1,3,:),size_4D(1),size_4D(4)))
    
    
    
    
    
    
    
    
    figure
    subplot(321)
    bar(myRA_PLR_ave'*100)
    xlabel('Algorithm index')
    ylabel('Average PLR (%)')l
    title('Average PLR')
   % legend('proposed algorithm','optimal offline ','online','fixed')
    subplot(322)
    bar(myRA_Delay')
    xlabel('Algorithm index')
    ylabel('Average Delay (ms)')
    title('Average Delay')
    %legend('proposed algorithm','optimal offline ','online','fixed')
    subplot(323)
    bar(myRA_energy_per_bit')
    xlabel('Algorithm index')
    ylabel('Average energy per bit (uJ/bit)')
    title('Average energy per bit')
    %legend('proposed algorithm','optimal offline ','online','fixed')
    subplot(324)
    bar(myRA_bandwidth_uti'*100)
    xlabel('Algorithm index')
    ylabel('Bandwidth utilization ratio')
    title('Bandwidth utilization ratio')
    %legend('proposed algorithm','optimal offline ','online','fixed')
    subplot(325)
    bar(myRA_throughput')
    xlabel('Algorithm index')
    ylabel('Average throughput')
    title('Average throughput')
    %legend('proposed algorithm','optimal offline ','online','fixed')
    
    
    
    
    
    
    %% ƽ������ͳ��
     show_deltaPL_ind =9;
     deltaPL = (show_deltaPL_ind-1)*deltaPL_step;
     par = initialParameters(0); %��ʼ��ϵͳ����  
     % �۲쵥�����Ե����ܱ���
     cal_alg_id  = 1;
     load_data = {};
     cp_PLR_ave =[];
     cp_Delay =[];
     cp_energy_per_bit =[];
     cp_bandwidth_uti =[];
     cp_throughput =[];
     for cal_alg_id = 1:4
         if cal_alg_id ==1
              for cal_myRA_id =1:3
                 [ load_path_name ] = conPathName(par.EnergyHarvest.t_cor_EH,deltaPL,cal_alg_id,cal_myRA_id, EH_ratio);
                 cur_data = load(load_path_name);
                 load_data{cal_alg_id,cal_myRA_id} = cur_data;
                 cur_QoS = calQosPerformance( cur_data.Queue,cur_data.sta_AllocateSlots, par.MAC,par.Nodes.packet_length);
                 cp_PLR_ave(cal_alg_id,cal_myRA_id) = mean(cur_QoS.PLR_ave);
                 cp_Delay(cal_alg_id,cal_myRA_id) = mean(cur_QoS.Delay_ave);
                 cp_energy_per_bit(cal_alg_id,cal_myRA_id) = mean(cur_QoS.energy_per_bit);
                 cp_bandwidth_uti(cal_alg_id,cal_myRA_id) = mean(cur_QoS.bandwidth_utilization);
                 cp_throughput(cal_alg_id,cal_myRA_id) = mean(cur_QoS.total_data)/(N_Frame * par.MAC.T_Frame*0.0001);
              end
         else
             [ load_path_name ] = conPathName(par.EnergyHarvest.t_cor_EH,deltaPL,cal_alg_id,cal_myRA_id, EH_ratio);
             cur_data = load(load_path_name);
             load_data{cal_alg_id,1} = cur_data;
             cur_QoS = calQosPerformance( cur_data.Queue,cur_data.sta_AllocateSlots, par.MAC,par.Nodes.packet_length);
             cp_PLR_ave(cal_alg_id,1) = mean(cur_QoS.PLR_ave);
             cp_Delay(cal_alg_id,1) = mean(cur_QoS.Delay_ave);
             cp_energy_per_bit(cal_alg_id,1) = mean(cur_QoS.energy_per_bit);
             cp_bandwidth_uti(cal_alg_id,1) = mean(cur_QoS.bandwidth_utilization);
             cp_throughput(cal_alg_id,1) = mean(cur_QoS.total_data)/(N_Frame * par.MAC.T_Frame*0.0001);
         end
     end
    figure
    subplot(321)
    bar(cp_PLR_ave*100)
    xlabel('Algorithm index')
    ylabel('Average PLR (%)')
    title('Average PLR')
   % legend('proposed algorithm','optimal offline ','online','fixed')
    subplot(322)
    bar(cp_Delay)
    xlabel('Algorithm index')
    ylabel('Average Delay (ms)')
    title('Average Delay')
    %legend('proposed algorithm','optimal offline ','online','fixed')
    subplot(323)
    bar(cp_energy_per_bit)
    xlabel('Algorithm index')
    ylabel('Average energy per bit (uJ/bit)')
    title('Average energy per bit')
    %legend('proposed algorithm','optimal offline ','online','fixed')
    subplot(324)
    bar(cp_bandwidth_uti*100)
    xlabel('Algorithm index')
    ylabel('Bandwidth utilization ratio')
    title('Bandwidth utilization ratio')
    %legend('proposed algorithm','optimal offline ','online','fixed')
    subplot(325)
    bar(cp_throughput)
    xlabel('Algorithm index')
    ylabel('Average throughput')
    title('Average throughput')
    %legend('proposed algorithm','optimal offline ','online','fixed')
     
    
    
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
    
    
   
    
    
    
%     %% ����������
% %     x_range = (0:deltaPL_ind_max-1)*deltaPL_step;
% %     figure
% %     subplot(221)
% %     for ind_node = 1:num_nodes
% %         hold on
% %         plot(x_range,sta_Energy(ind_node,:),'-','linewidth',2,'color',color_set(ind_node,:))
% %     end
% %     grid on
% %     xlabel('\mu_{s} of shadow')
% %     ylabel('Energy cost (uJ)')
% %     title('Energy cost')
% %     legend('Node1','Node2','Node3','Node4','Node5')
% %     subplot(222)
% %     for ind_node = 1:num_nodes
% %         hold on
% %         plot(x_range,sta_PLR_overflow(ind_node,:)*100,'-','linewidth',2,'color',color_set(ind_node,:))
% %     end
% %     grid on
% %     xlabel('\mu_{s} of shadow')
% %     ylabel('average PLR (%)')
% %     title('PLR due to overflow')
% %     legend('Node1','Node2','Node3','Node4','Node5')
% %     subplot(223)
% %     for ind_node = 1:num_nodes
% %         hold on
% %         plot(x_range,sta_PLR_overdelay(ind_node,:)*100,'-','linewidth',2,'color',color_set(ind_node,:))
% %     end
% %     grid on
% %     axis([0 20 0 6]) 
% %     xlabel('\mu_{s} of shadow')
% %     ylabel('average PLR (%)')
% %     title('PLR due to exceed delay threshold')
% %     legend('Node1','Node2','Node3','Node4','Node5')
% %     subplot(224)
% %     for ind_node = 1:num_nodes
% %         hold on
% %         plot(x_range,sta_Delay(ind_node,:),'-','linewidth',2,'color',color_set(ind_node,:))
% %     end
% %     grid on
% %     axis([0 20 0 600]) 
% %     xlabel('\mu_{s} of shadow')
% %     ylabel('Delay of packets (ms)')
% %     title('Average packet delay')
% %     legend('Node1','Node2','Node3','Node4','Node5')

    
    %     % ��������
%     sta_PLR_pathloss = []; %��·�����������������ݰ����������ڲ����ش�������ֻ��ʾ�����Ķ�������ʵ�ʴ�������ݰ��Ķ�����һ��
%     sta_PLR_overflow = [];%ͳ�����Ŷ����������
%     sta_PLR_overdelay = []; %ͳ����ʱ�ӳ��޳�������
%     sta_PLR_ave = []; %ͳ���ۺϿ����Ŷ������ʱ�ӳ��޶����µĶ����������
%     sta_Delay = []; %ͳ�Ƹ����ڵ��ƽ������
%     sta_Energy =[]; %ͳ�����ĵ�����
%     for deltaPL_ind =1:deltaPL_ind_max
%         deltaPL =  (deltaPL_ind-1)*deltaPL_step;
%         par = initialParameters(deltaPL); %��ʼ��ϵͳ����
%         cur_Queue = load_data{1,deltaPL_ind}.Queue;
%         cur_QoS = calQosPerformance( cur_Queue, load_data{1,deltaPL_ind}.sta_AllocateSlots,par.MAC,par.Nodes.packet_length);
%         for ind_node = 1:size(cur_QoS,2)
%             sta_PLR_pathloss(ind_node,deltaPL_ind) = cur_QoS(ind_node).PLR_pathloss;
%             sta_PLR_overflow(ind_node,deltaPL_ind) = cur_QoS(ind_node).PLR_overflow;
%             sta_PLR_overdelay(ind_node,deltaPL_ind) = cur_QoS(ind_node).PLR_overdelay;
%             sta_PLR_ave(ind_node,deltaPL_ind) = cur_QoS(ind_node).PLR_ave;
%             sta_Delay(ind_node,deltaPL_ind) = cur_QoS(ind_node).Delay_ave;
%             sta_Energy(ind_node,deltaPL_ind) = cur_QoS(ind_node).Energy_cost;
%         end
%     end