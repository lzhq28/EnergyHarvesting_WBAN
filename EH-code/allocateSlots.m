function [  AllocateSlots, opti_problem ] = allocateSlots(cur_pos, allocatePowerRate, re_num_slots, EH_last_status, EH_P_tran, parameters )
%allocateSlots 给各个节点分配时隙
%输入
%   cur_pos 当前身体姿势
%   re_num_slots 节点上一超帧所分配的时隙末尾位置到Beacon位置的时隙数
%   EH_last_status 各个节点在上一超帧的能量采集状态
%   EH_P_tran 各个节点在不同姿势下的能量采集状态转移矩阵
%   parameters 配置参数
%输出
%   AllocateSlots 给各个节点分配的时隙，每一行表示对一个节点的分配结果
%   opti_problem 优化时隙分配中返回的问题，0表示成功优化
 %% 简化常用参数
    num_nodes = parameters.Nodes.Num; %节点个数
    tran_rate = parameters.Nodes.tranRate(1); %这里假设所有节点的传输速率都是一样的
    %% 优化分配：节点时隙的分配
    % 确定各个节点的平均位置
    average_location_nodes = ones(1,num_nodes); 
    cur_EH_pos_min = parameters.EnergyHarvest.EH_pos_min(cur_pos,:);
    cur_EH_pos_max = parameters.EnergyHarvest.EH_pos_max(cur_pos,:);
    for ind_node =1:num_nodes
        cur_node = allocatePowerRate{ind_node};
        % 计算节点在各个时隙的能量采集状态为On的概率
        cur_EH_P_tran = EH_P_tran{cur_pos, ind_node};           
        cur_EH_mean = (cur_EH_pos_min(ind_node)+cur_EH_pos_max(ind_node))/2;            
        [average_location_nodes(1,ind_node)] = findAverageLocation( EH_last_status(ind_node), cur_node.power, cur_node.src_rate, re_num_slots(ind_node), cur_EH_P_tran, cur_EH_mean, tran_rate, parameters.EnergyHarvest.k_cor, parameters.MAC, parameters.PHY.E_a, parameters.PHY.E_Pct);
    end
    % 根据平均位置进行节点排序
    [tmp_values, order_nodes] = sort(average_location_nodes,'ascend'); 
    % 定义基本变量
    g_sdp = intvar(1,num_nodes); %节点分配时隙位置与普通位置之间的间隔时隙数
    n_sdp = intvar(1,num_nodes); %分配给节点的时隙数
    Cons = [];
    Obj = 0;
    %确定每个时隙的初始位置
    before_slots = {};
    for ind_node =1:num_nodes 
        tmp_obj =0;
        for j = 1:(order_nodes(ind_node)-1) %确定该节点前的所有节点的时隙
            cur_ind = find(order_nodes==j);
            tmp_obj= tmp_obj + (g_sdp(1,cur_ind) + n_sdp(1,cur_ind));  
        end
        tmp_obj = tmp_obj + g_sdp(1,ind_node); 
        before_slots{1,ind_node} = tmp_obj; 
    end
    %确定约束函数
    t_slot = parameters.MAC.T_Slot;
    P_th = parameters.Constraints.Nor_PLR_th;
    for ind_node =1:num_nodes
        cur_node = allocatePowerRate{ind_node};
        % Cons = [Cons, ceil(tran_rate*n_sdp(1,ind_node)*t_slot/(parameters.Nodes.packet_length(1,ind_node)))>= ceil(cur_node.src_rate(1,ind_node)*(re_num_slots(ind_node)+before_slots{1,ind_node})*t_slot/(P_th*parameters.Nodes.packet_length(1,ind_node)))];
        sense_time = (re_num_slots(ind_node)+before_slots{1,ind_node} + n_sdp(1,ind_node))*t_slot - parameters.Nodes.packet_length(1,ind_node)/tran_rate;
        Cons = [Cons, tran_rate*n_sdp(1,ind_node)*t_slot/(parameters.Nodes.packet_length(1,ind_node))>= (cur_node.src_rate*sense_time/((1-P_th)*parameters.Nodes.packet_length(1,ind_node))+1)];
        Cons = [Cons, n_sdp(1,ind_node)>=1, g_sdp(1,ind_node)>=0];
    end
    %确定目标函数
    for ind_node =1:num_nodes 
        Obj = Obj +  before_slots{1,ind_node} - average_location_nodes(1,ind_node);
    end
    Cons = [Cons, sum(n_sdp+g_sdp)<=parameters.MAC.N_Slot];
    Ops = sdpsettings('verbose',1,'solver','cplex');
    Opti_results_slot = optimize(Cons,-Obj,Ops); 
    opti_problem = Opti_results_slot.problem; 
    if Opti_results_slot.problem == 0
        disp('************* Success: success allocate slot ****************')
    else
        disp('************* Error: falied allocate slot ****************')
    end
    % 所分配的资源
    AllocateSlots = zeros(num_nodes,parameters.MAC.N_Slot);
    for ind_node =1:num_nodes
        begin_ind = value(before_slots{1,ind_node})+1;
        end_ind = value(before_slots{1,ind_node}) + value(n_sdp(1,ind_node));
        if end_ind > parameters.MAC.N_Slot
            disp(['error: max allocated num of slots exceed the MAC.N_slot']);
        end
        disp(strcat(['(ind_node,begin_slot,end_slot):',num2str(ind_node),',',num2str(begin_ind),',',num2str(end_ind)]));
        AllocateSlots(ind_node,begin_ind:end_ind) =  1;    
    end
end

