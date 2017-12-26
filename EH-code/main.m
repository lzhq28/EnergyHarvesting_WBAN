%%%%% 主函数：算法的函数入口 %%%%%%
%% 清零数据并配置并行
    clc
    clear all
    matlab_ver='2015';% '2012'or'2015'
    if  strcmp(matlab_ver,'2012')
        if(matlabpool('size')==0) %没有打开并行
            matlabpool local; %按照local配置的进行启动多个matlab worker
        end
    else
        if(isempty(gcp('nocreate'))==1) %没有打开并行
            parpool local; %按照local配置的进行启动多个matlab worker
        end
    end
    deltaPL_ind_min = 5;
    deltaPL_ind_max = 10;
    deltaPL_step = 2; %单位dBm
    alg_names = {'myRA','offline','online','fixed'}; 
    alg_myRA_details ={'with-rate-slot','only-with-rate','only-with-slot'};
    cal_alg_id = 1; % 配置下面要运行的算法的id号
    cal_myRA_id = 1; %配置本文方法的细节，是否采用数据速率调节策略，是否采用slot配置方法
    %parfor deltaPL_ind =deltaPL_ind_max:deltaPL_ind_max 
    %parfor cal_myRA_id =1:3
    %parfor EH_ratio = 0.1:0.2:2
    t_cor_EH_set =[40,80,150,300,500,1000];
    t_cor_EH = t_cor_EH_set(6); %能量采集相干时间，单位ms
    parfor EH_ratio_ind = 5:1:10
        EH_ratio = EH_ratio_ind * 0.1;
        %for cal_myRA_id = 1:3
            for deltaPL_ind = deltaPL_ind_min :deltaPL_ind_max
                %% 初始化系统参数
                %deltaPL_ind = deltaPL_ind_max;
                time_1 =clock;
                deltaPL = (deltaPL_ind-1)*deltaPL_step;               
                par = initialParameters(deltaPL, EH_ratio,t_cor_EH); %初始化系统参数    
                %% 配置实验所需参数
                rand_state = 1; %随机种子,建议从1开始的整数
                slot_or_frame_state =0; %阴影衰落是每个时隙不同，还是每个超帧不同，值为0表示每个时隙不同，值为1表示每个超帧不同
                pos_hold_time = 40*100; %每个姿势保持的时间，单位ms
                N_Frame = 1000; %实验的总超帧数
                ini_pos = 1; %初始化身体姿势为静止状态
                re_cal_miu_state = 0; %是否重新计算miu值，值为0表示不重新计算，而是从文件中读取，否则重新计算。
                precision = 0.0001; %在计算miu时的PLR与PLR_th之间的差值精度
                % 计算所有超帧的姿势序列和每个时隙的阴影衰落
                [shadow_seq, pos_seq] = shadowStatistic( N_Frame, ini_pos, pos_hold_time, par.Nodes, par.Postures, par.MAC, rand_state, slot_or_frame_state);
                % 初始化所有时隙的能量采集状态
                [ EH_status_seq, EH_collect_seq, EH_P_tran] = energyHarvestStatistic( pos_seq, par.EnergyHarvest, par.MAC, rand_state); 
                % 计算PLR的等效门限：平均信噪比门限miu_th
                [ miu_th ] = calEquPLRThreshold( par.Nodes, par.Channel, par.Constraints, precision, re_cal_miu_state,par.EnergyHarvest.t_cor_EH);
                %% 针对不同的算法采用不同的分配方式
                % 对传输功率、数据速率和时隙进行分配
                if cal_alg_id == 1
                    % 优化分配不同身体姿势下的传输功率和数据速率
                    disp(strcat('Info:excute the',{' '},alg_names(cal_alg_id),' method'));
                    [ AllocatePowerRate, opti_power_problems] = allocateTranPower( miu_th, par); 
                    if cal_myRA_id == 2 % 'only_with_rate'
                        [AllocateSlots] = allocateSlotsFixed(par.Nodes.Nor_SrcRates,par);
                    elseif cal_myRA_id == 3  % 'only_with_slot'
                        [AllocateRate] = allocateRateFixed(par.Nodes.Nor_SrcRates,par.Nodes.Num);
                    end
                elseif cal_alg_id == 2 % 对offline进行资源分配
                    disp(strcat('Info:excute the',{' '},alg_names(cal_alg_id),' method'));
                    offline_PLR_th = 0.01;
                    [offline_power] =compareOffline(shadow_seq, pos_seq, EH_status_seq, EH_collect_seq,offline_PLR_th, par);  
                    conf_srcRates = par.Nodes.Nor_SrcRates;
                    [AllocateRate] = allocateRateFixed(conf_srcRates,par.Nodes.Num);
                    [AllocateSlots] = allocateSlotsFixed(conf_srcRates,par);
                    [AllocatePowerRate, opti_power_problems] = allocateTranPower( miu_th, par); 
                elseif cal_alg_id ==3 % online资源分配方法
                    disp(strcat('Info:excute the',{' '},alg_names(cal_alg_id),' method'));
                    conf_powers = [0.6,0.6,0.6,0.6,0.7];%repmat(0.05,par.Nodes.Num,1);
                    conf_srcRates = par.Nodes.Nor_SrcRates;
                    [AllocatePower] = allocatePowerFixed(conf_powers,par.Nodes.Num);
                    [AllocateRate] = allocateRateFixed(conf_srcRates,par.Nodes.Num);
                    [AllocateSlots] = allocateSlotsFixed(conf_srcRates,par);
                    [ AllocatePowerRate, opti_power_problems] = allocateTranPower( miu_th, par); 
                elseif cal_alg_id ==4 % fixed固定传输功率和传输时隙的方法
                    disp(strcat('Info:excute the',{' '},alg_names(cal_alg_id),' method'));
                    conf_powers = [0.6,0.6,0.6,0.6,0.7];%repmat(0.05,par.Nodes.Num,1);
                    conf_srcRates = par.Nodes.Nor_SrcRates;
                    [AllocatePower] = allocatePowerFixed(conf_powers,par.Nodes.Num);
                    [AllocateRate] = allocateRateFixed(conf_srcRates,par.Nodes.Num);
                    [AllocateSlots] = allocateSlotsFixed(conf_srcRates,par);
                    [ AllocatePowerRate, opti_power_problems] = allocateTranPower( miu_th, par); 
                end

                %% 性能分析
                % 初始化三种不同的队列
                Queue = {};
                for ind_node = 1:par.Nodes.Num
                    Queue(ind_node).tranQueue = []; %数据包传输队列，包含数据包传输的信息:[packetID, gen_frameID, t_gen_offset, tran_frameID, t_tran_offset, t_tran_cost, tran_power, tran_rate, tran_state]
                    Queue(ind_node).arrivalQueue = []; %数据包达到队列， [pacektID,frameID,t_gen_offset,packetType]
                    Queue(ind_node).bufferQueue = [0,1,1,0]; %缓存状态队列, [frameID, beginIndex, endIndex, residue_energy]
                end   
                Allocate ={}; %初始化资源分配
                Nodes={}; %初始化各个节点的基本信息
                for ind_node = 1:par.Nodes.Num %对各个节点进行遍历
                    %Nodes(ind_node).Sigma = par.Nodes.Sigma(cur_pos,ind_node); % 当前节点在当前身子姿势下的阴影衰落的标准差Sigma
                    Nodes(ind_node).PL_Fr = par.Nodes.PL_Fr(ind_node); % PL = PL_Fr + shadow
                    Nodes(ind_node).num_packet_buffer = par.Nodes.num_packet_buffer(ind_node); %节点缓存所能保存数据包的数量            
                    Nodes(ind_node).packet_length = par.Nodes.packet_length(ind_node); 
                    Nodes(ind_node).num_packet_buffer = par.Nodes.num_packet_buffer(ind_node); %缓存所能存储的数据包数量
                    Nodes(ind_node).Nor_SrcRate = par.Nodes.Nor_SrcRates(ind_node);
                    Nodes(ind_node).tranRate = par.Nodes.tranRate(ind_node); % 固定传输速率
                    Nodes(ind_node).battery_capacity = par.EnergyHarvest.battery_capacity; % 电池容量
                end

                %% 循环统计分析
                EH_last_status = []; % 各个节点在各个超帧内分配时隙结束位置的能量残疾状态
                sta_last_EH_status = [];
                sta_re_num_slots = [];
                sta_AllocateSlots ={}; %统计每个超帧分配的时隙
                sta_opti_slots_problems = []; %统计时隙优化分配中的问题
                sta_GOODSET ={};
                sta_BADSET = {};
                last_end_slot_ind = ones(1,par.Nodes.Num)*par.MAC.N_Slot; %上一超帧分配时隙的结束位置,相对位置
                ind_absolute_slots = zeros(1,par.Nodes.Num);%上一超帧分配时隙的末尾位置在所有时隙中的绝对索引
                residue_energy = zeros(1,par.Nodes.Num); %各个节点传输时隙结束后的剩余能量 
                re_num_packets = zeros(1,par.Nodes.Num); %各个节点传输时隙结束后的缓存中剩余数据包 
                str_process ='*';
                for ind_frame = 1:N_Frame %对超帧进行遍历
                    if mod(ind_frame, N_Frame/20)==0
                        disp(strcat(str_process,' processing:',num2str(ind_frame/N_Frame*100),'%'))
                        str_process = strcat(str_process,'*');
                    end
                    cur_pos = pos_seq(ind_frame); %当前节点的身子姿势 
                    % 各个节点的基本信息
                    for tt=1:par.Nodes.Num %对各个节点进行遍历
                        Nodes(tt).Sigma = par.Nodes.Sigma(cur_pos,tt); % 当前节点在当前身子姿势下的阴影衰落的标准差Sigma
                        residue_energy(1,tt) = Queue(tt).bufferQueue(end,4); %节点剩余能量
                    end
                    %% 集结器对节点进行资源分配
                    % 确定参数：上一超帧分配时隙末尾位置与当前超帧beacon位置间的时隙数，上一超帧分配时隙末尾位置的能量采集状态
                    re_num_slots = par.MAC.N_Slot - last_end_slot_ind;
                    if ind_frame ==1 %初始化节点状态
                        EH_last_status(1,:) = EH_status_seq(:,1)';
                        re_num_packets = zeros(1,par.Nodes.Num); %各个节点传输时隙结束后的缓存中剩余数据包 
                    else 
                        ind_absolute_slots = (ind_frame-2)*par.MAC.N_Slot + last_end_slot_ind; %上一超帧分配时隙的末尾位置在所有时隙中的绝对索引
                        for ind_node = 1:par.Nodes.Num %对各个节点进行遍历
                            EH_last_status(1,ind_node) = EH_status_seq(ind_node,ind_absolute_slots(1,ind_node));
                            re_num_packets(1,ind_node) = Queue(ind_node).bufferQueue(end,3)-Queue(ind_node).bufferQueue(end,2)+1;% %各个节点传输时隙结束后的缓存中剩余数据包 
                        end   
                    end
                    sta_last_EH_status = [sta_last_EH_status;EH_last_status];
                    sta_re_num_slots = [sta_re_num_slots ; re_num_slots];
                    % 优化资源分配
                    if (cal_alg_id == 1)&&(cal_myRA_id ~= 2) %本文方法的时隙分配方法
                        [ AllocateSlots, opti_problem, sta_GOODSET{ind_frame}, sta_BADSET{ind_frame} ] = allocateSlots(cur_pos,AllocatePowerRate{1,cur_pos}, residue_energy, re_num_packets, re_num_slots, EH_last_status, EH_P_tran, par);                
                        sta_opti_slots_problems(ind_frame,1:2) = opti_problem;
%                     elseif (cal_alg_id == 2)
%                         [ AllocateSlots, opti_problem, sta_GOODSET{ind_frame}, sta_BADSET{ind_frame} ] = allocateSlots(cur_pos,AllocatePowerRate{1,cur_pos}, residue_energy, re_num_packets, re_num_slots, EH_last_status, EH_P_tran, par);
                    end
                    sta_AllocateSlots{1,ind_frame} = AllocateSlots;
                    cur_Allocate = {}; %初始化当前超帧的资源分配结果
                    %% 遍历各个节点的数据包传输
                    for ind_node = 1:par.Nodes.Num %对各个节点进行遍历
                        cur_shadow = shadow_seq(ind_node,((ind_frame-1)*par.MAC.N_Slot+1):(ind_frame*par.MAC.N_Slot)); %当前期间的阴影衰落的值
                        EH_begin_ind = ind_absolute_slots(ind_node)+1;
                        EH_end_ind = ind_frame*par.MAC.N_Slot;
                        cur_EH_collect = EH_collect_seq(ind_node, EH_begin_ind:EH_end_ind);
                       %% 统计资源分配的结果
                        if cal_alg_id ==1  %本文提出的方法
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
                        elseif cal_alg_id == 2 % online 方法
                            cur_Allocate.src_rate = AllocateRate(ind_node);
                            cur_Allocate.slot = AllocateSlots(ind_node,:);
                            cur_Allocate.power = offline_power(ind_node,((ind_frame-1)*par.MAC.N_Slot+1):(ind_frame*par.MAC.N_Slot));%配置offline方法配置的功率
                        elseif cal_alg_id == 3 % offline方法
                            cur_Allocate.src_rate = AllocateRate(ind_node);
                            cur_Allocate.slot = AllocateSlots(ind_node,:);
                            cur_Allocate.power =  repmat( AllocatePower(ind_node),1,par.MAC.N_Slot);
                        elseif cal_alg_id ==4 % fixed固定传输功率和传输时隙的方法
                            cur_Allocate.src_rate = AllocateRate(ind_node);                     
                            cur_Allocate.slot = AllocateSlots(ind_node,:);
                            cur_Allocate.power = repmat( AllocatePower(ind_node),1,par.MAC.N_Slot);
                        end
                      %% 更新参数
                        % 随机种子，所有节点在不同超帧的随机种子都不同
                        rand_seed = rand_state*par.Nodes.Num*N_Frame+(ind_node-1)*N_Frame+(ind_frame-1);
                        % 各个节点的数据包传输
                        if cal_alg_id == 3 %对online方法单独处理
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
                disp(['deltaPL:',num2str(deltaPL),'程序运行时间：',num2str(time_cost),'s'])
                % 保存仿真结果
                save_path_name = conPathName(par.EnergyHarvest.t_cor_EH,deltaPL,cal_alg_id,cal_myRA_id, EH_ratio);
                parsave(save_path_name, deltaPL, Queue, AllocatePowerRate, sta_AllocateSlots, shadow_seq, pos_seq, EH_status_seq, EH_collect_seq, EH_P_tran);
            end
        %end
    end
    
    %% 观察某次实验的仿真结果
    show_t_cor_EH = 40;
    show_deltaPL = 18;
    show_cal_alg_id = 1;
    show_cal_myRA_id =1;
    show_EH_ratio = 1;
    analysisQoSPerformance(show_t_cor_EH, show_deltaPL, show_cal_alg_id, show_cal_myRA_id, show_EH_ratio);
    
    %% 分析不同算法的性能好坏
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
                par = initialParameters(show_deltaPL, show_EH_ratio, show_t_cor_EH ); %初始化系统参数
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
    
    %% 对比不同方法的性能表现
    size_4D=size(cp_PLR_ave)
    color_set = linspecer(4);
    show_EH_ratio_ind = 6;
    x_range_ind = deltaPL_ind_min:deltaPL_ind_max;
    x_range = (x_range_ind -1)*deltaPL_step;
    line_width =8;
    marker_size =20;
    %PLR性能
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
    set(get(gca,'YLabel'),'FontSize',30,'FontName','Times New Roman');%设置Y坐标标题字体大小，字型
    set(gca,'FontName','Times New Roman','FontSize',25)%设置坐标轴字体大小，字型、
    set(gca,'XColor','k')
    set(gca,'linewidth',3)
    set(gca,'GridLineStyle', '--')
    %Delay性能
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
    set(get(gca,'YLabel'),'FontSize',30,'FontName','Times New Roman');%设置Y坐标标题字体大小，字型
    set(gca,'FontName','Times New Roman','FontSize',25)%设置坐标轴字体大小，字型、
    set(gca,'XColor','k')
    set(gca,'linewidth',3)
    set(gca,'GridLineStyle', '--')
    %energy efficiency性能
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
    set(get(gca,'YLabel'),'FontSize',30,'FontName','Times New Roman');%设置Y坐标标题字体大小，字型
    set(gca,'FontName','Times New Roman','FontSize',25)%设置坐标轴字体大小，字型、
    set(gca,'XColor','k')
    set(gca,'linewidth',3)
    set(gca,'GridLineStyle', '--')
    % throughput性能
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
    set(get(gca,'YLabel'),'FontSize',30,'FontName','Times New Roman');%设置Y坐标标题字体大小，字型
    set(gca,'FontName','Times New Roman','FontSize',25)%设置坐标轴字体大小，字型、
    set(gca,'XColor','k')
    set(gca,'linewidth',3)
    set(gca,'GridLineStyle', '--')
    % throughput性能
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
    set(get(gca,'YLabel'),'FontSize',30,'FontName','Times New Roman');%设置Y坐标标题字体大小，字型
    set(gca,'FontName','Times New Roman','FontSize',25)%设置坐标轴字体大小，字型、
    set(gca,'XColor','k')
    set(gca,'linewidth',3)
    set(gca,'GridLineStyle', '--')
   
    %% 分析本文方法的细节表现
    % 观察本文方法中两阶段分别对性能的影响
    x_range_ind = deltaPL_ind_min:deltaPL_ind_max;
    x_range = 0.5:0.1:1;
    figure(1)
    bar(x_range,reshape(cp_PLR_ave(1, :,end, :)*100,3,6)')
    legend('PRS-RA with PRCS and QASAS','PRS-RA with PRCS','PRS-RA with QASAS')   
    xlabel('EH Efficiency ratio (%)')
    ylabel('Average PLR (%)')
    grid on
    set(get(gca,'XLabel'),'FontSize',30,'FontName','Times New Roman')
    set(get(gca,'YLabel'),'FontSize',30,'FontName','Times New Roman');%设置Y坐标标题字体大小，字型
    set(gca,'FontName','Times New Roman','FontSize',25)%设置坐标轴字体大小，字型、
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
    set(get(gca,'YLabel'),'FontSize',30,'FontName','Times New Roman');%设置Y坐标标题字体大小，字型
    set(gca,'FontName','Times New Roman','FontSize',25)%设置坐标轴字体大小，字型、
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
    set(get(gca,'YLabel'),'FontSize',30,'FontName','Times New Roman');%设置Y坐标标题字体大小，字型
    set(gca,'FontName','Times New Roman','FontSize',25)%设置坐标轴字体大小，字型、
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
    set(get(gca,'YLabel'),'FontSize',30,'FontName','Times New Roman');%设置Y坐标标题字体大小，字型
    set(gca,'FontName','Times New Roman','FontSize',25)%设置坐标轴字体大小，字型、
    set(gca,'XColor','k')
    set(gca,'linewidth',3)
    set(gca,'GridLineStyle', '--')
    
    % 观察相关时间对性能的影响
    show_deltaPL = 18;
    show_EH_ratio = 0.5;
    show_cal_alg_id = 1;
    show_cal_myRA_id = 1;
    for node_ind =1:5
        for show_t_cor_EH_ind =1:size(t_cor_EH_set,2)
            show_t_cor_EH = t_cor_EH_set(show_t_cor_EH_ind);
            par = initialParameters(show_deltaPL, show_EH_ratio, show_t_cor_EH ); %初始化系统参数
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
    
    % 观察long-term PRCS性能表现
    show_deltaPL = 12;
    show_EH_ratio = 0.5;
    show_cal_alg_id = 1;
    show_cal_myRA_id = 1;
    show_t_cor_EH = t_cor_EH_set(1);
    par = initialParameters(show_deltaPL, show_EH_ratio, show_t_cor_EH ); %初始化系统参数
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
    legend('Still','Walk','Run')
    grid on
    set(get(gca,'XLabel'),'FontSize',30,'FontName','Times New Roman')
    set(get(gca,'YLabel'),'FontSize',30,'FontName','Times New Roman');%设置Y坐标标题字体大小，字型
    set(gca,'FontName','Times New Roman','FontSize',25)%设置坐标轴字体大小，字型、
    set(gca,'XColor','k')
    set(gca,'linewidth',3)
    set(gca,'GridLineStyle', '--')
    
    figure
    bar(PRCS_allocate_power')
    xlabel('Node index')
    ylabel('Transmission power (mW)')
    legend('Still','Walk','Run')
    grid on
    set(get(gca,'XLabel'),'FontSize',30,'FontName','Times New Roman')
    set(get(gca,'YLabel'),'FontSize',30,'FontName','Times New Roman');%设置Y坐标标题字体大小，字型
    set(gca,'FontName','Times New Roman','FontSize',25)%设置坐标轴字体大小，字型、
    set(gca,'XColor','k')
    set(gca,'linewidth',3)
    set(gca,'GridLineStyle', '--')
     
    
    
    
    

    
   
    % 观察采用时隙奉陪前后队列中数据包变化情况
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
    num_sample = 30; %直方图的条数
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
    set(get(gca,'YLabel'),'FontSize',30,'FontName','Times New Roman');%设置Y坐标标题字体大小，字型
    set(gca,'FontName','Times New Roman','FontSize',25)%设置坐标轴字体大小，字型、
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
    set(get(gca,'YLabel'),'FontSize',30,'FontName','Times New Roman');%设置Y坐标标题字体大小，字型
    set(gca,'FontName','Times New Roman','FontSize',25)%设置坐标轴字体大小，字型、
    set(gca,'XColor','k')
    set(gca,'linewidth',3)
    set(gca,'GridLineStyle', '--')
    
    
    
    
    
    
    
    
    
    
    
    %% 分析本文方法的性能
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
                    par = initialParameters(show_deltaPL, show_EH_ratio, show_t_cor_EH ); %初始化系统参数
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
    % 观测能量采集相关时间对系统性能的影响
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
    
    
    
    
    
    
    %% 平均性能统计
     show_deltaPL_ind =9;
     deltaPL = (show_deltaPL_ind-1)*deltaPL_step;
     par = initialParameters(0); %初始化系统参数  
     % 观察单个策略的性能表现
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
     
    
    
    %% 性能对比，对比本文提出的方法和对比方法
    show_deltaPL_ind =10;
    load_data = {}; %加载的数据
    deltaPL =  (show_deltaPL_ind-1)*deltaPL_step;
    t_cor_EH = par.EnergyHarvest.t_cor_EH;
    path_names = configurePaths(t_cor_EH); %各种路径名字
    for alg_id =1:size(alg_names,2)
        if alg_id == 1 %本文提出的方法
            load_path_name = strcat([path_names.myRA_prefix,num2str(deltaPL),'.mat']);   
        elseif alg_id == 2 % offline方法
            load_path_name = strcat([path_names.offline_prefix,num2str(deltaPL),'.mat']);
        elseif alg_id ==3 % online方法
            load_path_name = strcat([path_names.online_prefix,num2str(deltaPL),'.mat']);
        elseif alg_id == 4 % 固定的方法
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
    
    
   
    
    
    
%     %% 画出仿真结果
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

    
    %     % 分析性能
%     sta_PLR_pathloss = []; %由路径丢包而丢弃的数据包，但是由于采用重传所以它只表示物理层的丢包，与实际传输的数据包的丢包不一致
%     sta_PLR_overflow = [];%统计由排队溢出而丢包
%     sta_PLR_overdelay = []; %统计由时延超限出而丢包
%     sta_PLR_ave = []; %统计综合考虑排队溢出和时延超限而导致的丢包两种情况
%     sta_Delay = []; %统计各个节点的平均丢包
%     sta_Energy =[]; %统计消耗的能量
%     for deltaPL_ind =1:deltaPL_ind_max
%         deltaPL =  (deltaPL_ind-1)*deltaPL_step;
%         par = initialParameters(deltaPL); %初始化系统参数
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