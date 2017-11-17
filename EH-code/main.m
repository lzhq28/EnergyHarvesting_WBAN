%%%%% 主函数：算法的函数入口 %%%%%%
%% 清零数据并配置并行
    clc
    clear all
    matlab_ver='2015';% '2012'or'2015'
%     if  strcmp(matlab_ver,'2012')
%         if(matlabpool('size')==0) %没有打开并行
%             matlabpool local; %按照local配置的进行启动多个matlab worker
%         end
%     else
%         if(isempty(gcp('nocreate'))==1) %没有打开并行
%             parpool local; %按照local配置的进行启动多个matlab worker
%         end
%     end
    deltaPL_ind_max = 10;
    deltaPL_step = 2; %单位dBm
    parfor deltaPL_ind =1:deltaPL_ind_max
        %% 初始化系统参数
        % deltaPL_ind = deltaPL_ind_max;
        time_1 =clock;
        deltaPL = (deltaPL_ind-1)*deltaPL_step;
        par = initialParameters(deltaPL); %初始化系统参数    
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
        [ miu_th ] = calEquPLRThreshold( par.Nodes, par.Channel, par.Constraints, precision, re_cal_miu_state);
        % 优化分配不同身体姿势下的传输功率和数据速率
        [ AllocatePowerRate, opti_power_problems] = allocateTranPower( miu_th, par);

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
        end

        %% 循环统计分析
        EH_last_status = []; % 各个节点在各个超帧内分配时隙结束位置的能量残疾状态
        sta_last_EH_status = [];
        sta_re_num_slots = [];
        sta_AllocateSlots ={}; %统计时隙分配的结果
        sta_opti_slots_problems = []; %统计时隙优化分配中的问题
        last_end_slot_ind = ones(1,par.Nodes.Num)*par.MAC.N_Slot; %上一超帧分配时隙的结束位置,相对位置
        ind_absolute_slots = zeros(1,par.Nodes.Num);%上一超帧分配时隙的末尾位置在所有时隙中的绝对索引
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
            end
            %% 集结器对节点进行资源分配
            % 确定参数：上一超帧分配时隙末尾位置与当前超帧beacon位置间的时隙数，上一超帧分配时隙末尾位置的能量采集状态
            re_num_slots = par.MAC.N_Slot - last_end_slot_ind;
            if ind_frame ==1 %初始化节点状态
                EH_last_status(1,:) = EH_status_seq(:,1)';
            else 
                ind_absolute_slots = (ind_frame-2)*par.MAC.N_Slot + last_end_slot_ind; %上一超帧分配时隙的末尾位置在所有时隙中的绝对索引
                for ind_node = 1:par.Nodes.Num %对各个节点进行遍历
                    EH_last_status(1,ind_node) = EH_status_seq(ind_node,ind_absolute_slots(1,ind_node));
                end   
            end
            sta_last_EH_status = [sta_last_EH_status;EH_last_status];
            sta_re_num_slots = [sta_re_num_slots ; re_num_slots];
            % 优化资源分配
            [ AllocateSlots, opti_problem  ] = allocateSlots(cur_pos,AllocatePowerRate{1,cur_pos}, re_num_slots, EH_last_status, EH_P_tran, par);
            sta_opti_slots_problems(1,ind_frame) = opti_problem;
            sta_AllocateSlots{1,ind_frame} = AllocateSlots;
            cur_Allocate = {}; %初始化当前超帧的资源分配结果
            %% 遍历各个节点的数据包传输
            for ind_node = 1:par.Nodes.Num %对各个节点进行遍历
                cur_shadow = shadow_seq(ind_node,((ind_frame-1)*par.MAC.N_Slot+1):(ind_frame*par.MAC.N_Slot)); %当前期间的阴影衰落的值
                EH_begin_ind = ind_absolute_slots(ind_node)+1;
                EH_end_ind = ind_frame*par.MAC.N_Slot;
                cur_EH_collect = EH_collect_seq(ind_node, EH_begin_ind:EH_end_ind);
               %% 统计资源分配的结果
                cur_Allocate.power =  AllocatePowerRate{cur_pos}{ind_node}.power;
                cur_Allocate.src_rate = AllocatePowerRate{cur_pos}{ind_node}.src_rate;
                cur_Allocate.slot = AllocateSlots(ind_node,:);
              %% 更新参数
                % 随机种子，所有节点在不同超帧的随机种子都不同
                rand_seed = rand_state*par.Nodes.Num*N_Frame+ (ind_node-1)*N_Frame+(ind_frame-1);
                % 各个节点的数据包传输
                [ Queue(ind_node).tranQueue, Queue(ind_node).arrivalQueue, Queue(ind_node).bufferQueue, last_end_slot_ind(ind_node)] = nodeTranPerFrame(ind_frame, cur_shadow, cur_EH_collect, last_end_slot_ind(ind_node), cur_Allocate, Nodes(ind_node), par.MAC, par.Channel,par.Constraints, Queue(ind_node).tranQueue, Queue(ind_node).arrivalQueue, Queue(ind_node).bufferQueue, rand_seed);
            end
        end
        time_2 =clock;
        time_cost = etime(time_2,time_1)
        disp(['deltaPL:',num2str(deltaPL),'程序运行时间：',num2str(time_cost),'s'])
        % 保存仿真结果
        path_names = configurePaths(); %各种路径名字
        save_path_name = strcat([path_names.save_prefix,num2str(deltaPL),'.mat']);   
        parsave(save_path_name, deltaPL, Queue, AllocatePowerRate, sta_AllocateSlots, shadow_seq, pos_seq, EH_status_seq, EH_collect_seq, EH_P_tran)
    end

    %% 性能统计
     show_deltaPL_ind =1;
     analysisQoSPerformance(deltaPL_step, deltaPL_ind_max, show_deltaPL_ind)
    

   