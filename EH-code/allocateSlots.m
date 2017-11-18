function [  AllocateSlots, opti_problem, GOODSET, BADSET ] = allocateSlots(cur_pos, allocatePowerRate, residue_energy, re_num_packets, re_num_slots, EH_last_status, EH_P_tran, parameters )
%allocateSlots 给各个节点分配时隙
%输入
%   cur_pos 当前身体姿势
%   residue_energy 节点上一状态的剩余能量
%   re_num_packets 上一超帧结束后缓存中剩余数据包
%   re_num_slots 节点上一超帧所分配的时隙末尾位置到Beacon位置的时隙数
%   EH_last_status 各个节点在上一超帧的能量采集状态
%   EH_P_tran 各个节点在不同姿势下的能量采集状态转移矩阵
%   parameters 配置参数
%输出
%   AllocateSlots 给各个节点分配的时隙，每一行表示对一个节点的分配结果
%   opti_problem 优化时隙分配中返回的问题，0表示成功优化
    %% 测试
%     allocatePowerRate=AllocatePowerRate{1,cur_pos}
%     parameters = par
 %% 简化常用参数
    num_nodes = parameters.Nodes.Num; %节点个数
    tran_rate = parameters.Nodes.tranRate(1); %这里假设所有节点的传输速率都是一样的
    cur_EH_pos_min = parameters.EnergyHarvest.EH_pos_min(cur_pos,:);
    cur_EH_pos_max = parameters.EnergyHarvest.EH_pos_max(cur_pos,:);
    E_a = parameters.PHY.E_a;
    E_Pct=parameters.PHY.E_Pct;
    t_slot = parameters.MAC.T_Slot;
    P_th = parameters.Constraints.Nor_PLR_th;
    AllocateSlots = zeros(num_nodes,parameters.MAC.N_Slot); %给各个节点所分配的时隙位置
    opti_problem = zeros(1,2);%统计优化结果是否存在问题
    %% 优化分配：节点时隙的分配
    % 根据节点的剩余能量、平均采集到的能量和平均到达数据量之间的关系对节点进行分配
    GOODSET=[]; %能量充足的节点
    BADSET=[];%能量不足的节点
    for ind_node = 1:num_nodes     
        cur_node = allocatePowerRate{ind_node};
        cur_EH_mean = (cur_EH_pos_min(ind_node)+cur_EH_pos_max(ind_node))/2;     
        average_energy_cost = ((1+ E_a)*cur_node.power + E_Pct) * ceil(cur_node.src_rate * parameters.MAC.T_Frame/parameters.Nodes.packet_length(ind_node))*parameters.Nodes.packet_length(ind_node)/tran_rate;
        if residue_energy(1,ind_node) > average_energy_cost %根据剩余能量是否足够传输平均一超帧所能采集的数据量来决定节点所述集合
            GOODSET = [GOODSET,ind_node];
        else
            BADSET = [BADSET,ind_node];
        end
    end
    %% 对于不同的能量状态的节点集合采用不同的策略
    %% 对于能量不足数据包集合进行数据传输
    if ~isempty(BADSET) %先对能量不足的节点采取能量的
        num_bad_nodes = size( BADSET,2);
        average_location_nodes = ones(1,num_bad_nodes); 
        for ind_node = 1:num_bad_nodes
            actu_ind =  BADSET(1,ind_node); %节点绝对索引号，也即是ID号，而ind_node是在BADSET中的相对索引
            cur_node = allocatePowerRate{actu_ind};
            % 计算节点在各个时隙的能量采集状态为On的概率
            cur_EH_P_tran = EH_P_tran{cur_pos, actu_ind}; 
            cur_EH_mean = (cur_EH_pos_min(actu_ind)+cur_EH_pos_max(actu_ind))/2; 
            [average_location_nodes(1,ind_node)] = findAverageLocation( EH_last_status(actu_ind), cur_node.power, cur_node.src_rate, re_num_slots(actu_ind), cur_EH_P_tran, cur_EH_mean, tran_rate, parameters.EnergyHarvest.k_cor, parameters.MAC, E_a, E_Pct);
        end
        % 根据平均位置进行节点排序
        [tmp_values, order_nodes] = sort(average_location_nodes,'ascend'); 
        % 定义基本变量
        g_sdp = intvar(1,num_bad_nodes); %节点分配时隙位置与普通位置之间的间隔时隙数
        n_sdp = intvar(1,num_bad_nodes); %分配给节点的时隙数
        Cons = [];
        Obj = 0;
        %确定每个时隙的初始位置
        before_slots = {};
        for ind_node =1:num_bad_nodes 
            tmp_obj =0;
            for j = 1:(order_nodes(ind_node)-1) %确定该节点前的所有节点的时隙
                cur_ind = find(order_nodes==j);
                tmp_obj= tmp_obj + (g_sdp(1,cur_ind) + n_sdp(1,cur_ind));  
            end
            tmp_obj = tmp_obj + g_sdp(1,ind_node); 
            before_slots{1,ind_node} = tmp_obj; 
        end
        %确定约束函数
        for ind_node =1:num_bad_nodes 
            actu_ind =  BADSET(1,ind_node); %节点绝对索引号，也即是ID号，而ind_node是在BADSET中的相对索引
            cur_node = allocatePowerRate{actu_ind};
            % Cons = [Cons, ceil(tran_rate*n_sdp(1,ind_node)*t_slot/(parameters.Nodes.packet_length(1,actu_ind)))>= ceil(cur_node.src_rate*(re_num_slots(actu_ind)+before_slots{1,ind_node})*t_slot/(P_th*parameters.Nodes.packet_length(1,actu_ind)))];
            sense_time = (re_num_slots(actu_ind)+before_slots{1,ind_node} + n_sdp(1,ind_node))*t_slot - parameters.Nodes.packet_length(1,actu_ind)/tran_rate;
            Cons = [Cons, tran_rate*n_sdp(1,ind_node)*t_slot/(parameters.Nodes.packet_length(1,actu_ind))>= (cur_node.src_rate*sense_time/((1-P_th)*parameters.Nodes.packet_length(1,actu_ind))+1)];
            Cons = [Cons, n_sdp(1,ind_node)>=1, g_sdp(1,ind_node)>=0];
        end
        %确定目标函数
        for ind_node =1:num_bad_nodes 
            Obj = Obj +  before_slots{1,ind_node} - average_location_nodes(1,ind_node);
        end
        Cons = [Cons, sum(n_sdp+g_sdp)<=parameters.MAC.N_Slot];
        Ops = sdpsettings('verbose',0,'solver','cplex');
        Opti_BADSET_slot = optimize(Cons,-Obj,Ops); 
        opti_problem(1,1) = Opti_BADSET_slot.problem; 
        if Opti_BADSET_slot.problem == 0
            %disp('************* Success: success allocate slot ****************')
        else
            disp('************* Error: falied allocate slot ****************')
        end
%         value(n_sdp)
%         value(g_sdp)
%         value(before_slots{1,3})
         % 所分配的资源
        for ind_node =1:num_bad_nodes
            begin_ind = value(before_slots{1,ind_node})+1;
            end_ind = value(before_slots{1,ind_node}) + value(n_sdp(1,ind_node));
            actu_ind = BADSET(1,ind_node); %节点绝对索引号，也即是ID号，而ind_node是在BADSET中的相对索引
            if end_ind > parameters.MAC.N_Slot
                disp(['error: max allocated num of slots exceed the MAC.N_slot']);
            end
            %disp(strcat(['(ind_node,begin_slot,end_slot):',num2str(ind_node),',',num2str(begin_ind),',',num2str(end_ind)]));
            AllocateSlots(actu_ind,begin_ind:end_ind) =  1;    
        end
    end
    %% 对于能量充足数据包进行资源分配
    if ~isempty(GOODSET) %先对能量充足的节点进行时隙分配，主要关注时隙数量，对位置不敏感
        remain_slots_inds = find(sum(AllocateSlots)==0); %所有剩余节点的索引
        num_remain_slots = size(remain_slots_inds,2);%剩余时隙数
        num_good_nodes = size(GOODSET,2);
        % 对于能量充足的节点
        n_sdp = intvar(1,num_good_nodes); %分配给节点的时隙数
        Cons = [];
        Obj = 0;
        for ind_node = 1:num_good_nodes
            actu_ind =  GOODSET(1,ind_node); %节点绝对索引号，也即是ID号，而ind_node是在BADSET中的相对索引
            cur_node = allocatePowerRate{actu_ind};
            total_bits = re_num_packets(1,actu_ind)*parameters.Nodes.packet_length(1,actu_ind) + cur_node.src_rate*parameters.MAC.T_Frame;
            x = tran_rate*n_sdp(1,ind_node)*t_slot;
            Obj = Obj + (2*total_bits*x -power(x,2))/power(total_bits,2);
            cur_EH_mean = (cur_EH_pos_min(actu_ind)+cur_EH_pos_max(actu_ind))/2; 
            Cons =[Cons, (residue_energy(1,actu_ind)+cur_EH_mean*parameters.MAC.T_Frame)>=((1+ E_a)*cur_node.power + E_Pct)*n_sdp(1,ind_node)*t_slot];
        end
        Cons =[Cons, sum(n_sdp)<=num_remain_slots];
        Ops = sdpsettings('verbose',0,'solver','cplex');
        Opti_GOODSET_slot = optimize(Cons,-Obj,Ops);
        opti_problem(1,2) = Opti_GOODSET_slot.problem ;
%         value(n_sdp);
        if Opti_GOODSET_slot.problem == 0
            %disp('************* Success: success allocate slot ****************')
        else
            disp('************* Error: falied allocate slot ****************')
        end
        % 对GOODSET中的时隙进行分配
        begin_ind = remain_slots_inds(end)+1;
        end_ind = remain_slots_inds(end);
        for ind_node = 1:num_good_nodes
            re_ind = num_good_nodes-ind_node+1;% 倒序着分配时隙
            actu_ind =  GOODSET(1,re_ind); %节点绝对索引号，也即是ID号，而ind_node是在BADSET中的相对索引
            end_ind = begin_ind -1;
            begin_ind = end_ind - value(n_sdp(1,re_ind)) + 1;         
            if begin_ind <0
                disp(['error: max allocated num of slots exceed the MAC.N_slot']);
            end
            %disp(strcat(['(ind_node,begin_slot,end_slot):',num2str(actu_ind ),',',num2str(begin_ind),',',num2str(end_ind)]));
            AllocateSlots(actu_ind,begin_ind:end_ind) = 1;    
        end
    end
    
    %% 确定各个节点的平均位置
% %     average_location_nodes = ones(1,num_nodes); 
% %     for ind_node =1:num_nodes
% %         cur_node = allocatePowerRate{ind_node};
% %         % 计算节点在各个时隙的能量采集状态为On的概率
% %         cur_EH_P_tran = EH_P_tran{cur_pos, ind_node};           
% %         cur_EH_mean = (cur_EH_pos_min(ind_node)+cur_EH_pos_max(ind_node))/2;            
% %         [average_location_nodes(1,ind_node)] = findAverageLocation( EH_last_status(ind_node), cur_node.power, cur_node.src_rate, re_num_slots(ind_node), cur_EH_P_tran, cur_EH_mean, tran_rate, parameters.EnergyHarvest.k_cor, parameters.MAC, E_a, E_Pct);
% %     end
% %     % 根据平均位置进行节点排序
% %     [tmp_values, order_nodes] = sort(average_location_nodes,'ascend'); 
% %     % 定义基本变量
% %     g_sdp = intvar(1,num_nodes); %节点分配时隙位置与普通位置之间的间隔时隙数
% %     n_sdp = intvar(1,num_nodes); %分配给节点的时隙数
% %     Cons = [];
% %     Obj = 0;
% %     %确定每个时隙的初始位置
% %     before_slots = {};
% %     for ind_node =1:num_nodes 
% %         tmp_obj =0;
% %         for j = 1:(order_nodes(ind_node)-1) %确定该节点前的所有节点的时隙
% %             cur_ind = find(order_nodes==j);
% %             tmp_obj= tmp_obj + (g_sdp(1,cur_ind) + n_sdp(1,cur_ind));  
% %         end
% %         tmp_obj = tmp_obj + g_sdp(1,ind_node); 
% %         before_slots{1,ind_node} = tmp_obj; 
% %     end
% %     %确定约束函数
% %     t_slot = parameters.MAC.T_Slot;
% %     P_th = parameters.Constraints.Nor_PLR_th;
% %     for ind_node =1:num_nodes
% %         cur_node = allocatePowerRate{ind_node};
% %         % Cons = [Cons, ceil(tran_rate*n_sdp(1,ind_node)*t_slot/(parameters.Nodes.packet_length(1,ind_node)))>= ceil(cur_node.src_rate(1,ind_node)*(re_num_slots(ind_node)+before_slots{1,ind_node})*t_slot/(P_th*parameters.Nodes.packet_length(1,ind_node)))];
% %         sense_time = (re_num_slots(ind_node)+before_slots{1,ind_node} + n_sdp(1,ind_node))*t_slot - parameters.Nodes.packet_length(1,ind_node)/tran_rate;
% %         Cons = [Cons, tran_rate*n_sdp(1,ind_node)*t_slot/(parameters.Nodes.packet_length(1,ind_node))>= (cur_node.src_rate*sense_time/((1-P_th)*parameters.Nodes.packet_length(1,ind_node))+1)];
% %         Cons = [Cons, n_sdp(1,ind_node)>=1, g_sdp(1,ind_node)>=0];
% %     end
% %     %确定目标函数
% %     for ind_node =1:num_nodes 
% %         Obj = Obj +  before_slots{1,ind_node} - average_location_nodes(1,ind_node);
% %     end
% %     Cons = [Cons, sum(n_sdp+g_sdp)<=parameters.MAC.N_Slot];
% %     Ops = sdpsettings('verbose',0,'solver','cplex');
% %     Opti_results_slot = optimize(Cons,-Obj,Ops); 
% %     opti_problem = Opti_results_slot.problem; 
% %     if Opti_results_slot.problem == 0
% %         %disp('************* Success: success allocate slot ****************')
% %     else
% %         disp('************* Error: falied allocate slot ****************')
% %     end
% %     % 所分配的资源
% %     AllocateSlots = zeros(num_nodes,parameters.MAC.N_Slot);
% %     for ind_node =1:num_nodes
% %         begin_ind = value(before_slots{1,ind_node})+1;
% %         end_ind = value(before_slots{1,ind_node}) + value(n_sdp(1,ind_node));
% %         if end_ind > parameters.MAC.N_Slot
% %             disp(['error: max allocated num of slots exceed the MAC.N_slot']);
% %         end
% %         %disp(strcat(['(ind_node,begin_slot,end_slot):',num2str(ind_node),',',num2str(begin_ind),',',num2str(end_ind)]));
% %         AllocateSlots(ind_node,begin_ind:end_ind) =  1;    
% %     end
end

