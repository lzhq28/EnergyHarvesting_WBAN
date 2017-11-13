function [ Allocate, optimize_problems ] = resourceAllocationScheme( cur_pos, cur_miu_th, re_num_slots, EH_last_status, EH_P_tran, parameters)
%resourceAllocationScheme 集结器端资源分配策略
%输入：
%   cur_pos 当前身体姿势
%   cur_miu_th 各个节点在当前姿势下的平均信噪比门限
%   re_num_slots 节点上一超帧所分配的时隙末尾位置到Beacon位置的时隙数
%   EH_last_status 各个节点在上一超帧的能量采集状态
%   EH_P_tran 各个节点在不同姿势下的能量采集状态转移矩阵
%   parameters 全局配置的参数，包括：Nodes 各个节点的基本信息，PHY 物理层参数，MAC MAC参数，Channel
%   信道参数，Constraints 服务质量约束， EnergyHarvest 能量采集相关参数
%输出：
%   Allocate 分配给各个节点的资源：[power,src_rate,slot_ind]
%   optimize_problems 优化分配功率和优化分配时隙中的问题，0表示没有问题[opt_power_problem,opt_slot_problem]
 
    %% 初始化参数
    % parameters = par
    % cur_miu_th = miu_th(cur_pos,:);
    optimize_problems = zeros(1,2);
    num_nodes = parameters.Nodes.Num; %节点个数
    tran_rate = parameters.Nodes.tranRate(1); %这里假设所有节点的传输速率都是一样的
    src_rate_max = zeros(1,num_nodes); %能量采集所能传输的最大数据速率
    tran_power = zeros(1,num_nodes); %传输功率
    EH_P_on = zeros(1,num_nodes); %各个节点在当前身体姿势下的能量采集状态为On的概率密度
    EH_pos_min = parameters.EnergyHarvest.EH_pos_min(cur_pos,:); %各个节点能量采集速率
    EH_pos_max = parameters.EnergyHarvest.EH_pos_max(cur_pos,:);
    for ind_node= 1:num_nodes
        EH_P_on(1,ind_node) =  parameters.EnergyHarvest.EH_P_state{cur_pos,ind_node}(1);
    end
    P_miu_th = parameters.Nodes.tranRate.*power(10,(cur_miu_th+parameters.Nodes.PL_Fr+parameters.Channel.PNoise)/10)./parameters.Channel.Bandwidth; %计算满足丢包率的等效门限传输功率
    
    %% 优化问题来实现传输功率的分配以及能量采集到能量能传输的数据速率:这部分可以离线处理
    tmp_v_sdp = sdpvar(1,num_nodes); %中间变量，v=1/((1+a)Ptx+Pct) , Ptx = (1/v-Pct)/(1+a)
    src_rate_sdp = sdpvar(1,num_nodes); %给各个节点分配的数据源速率
    Cons = [];
    for ind_node = 1:num_nodes      
       Cons = [Cons, EH_P_on(1,ind_node)*EH_pos_min(1,ind_node)*tran_rate>=src_rate_sdp(1,ind_node)/tmp_v_sdp(1,ind_node)]; 
       Cons = [Cons, src_rate_sdp(1,ind_node)>=0];
       Cons = [Cons, tmp_v_sdp(ind_node)<=1./((1+parameters.PHY.E_a)*P_miu_th(ind_node)+parameters.PHY.E_Pct)];
       Cons = [Cons, 1/((1+parameters.PHY.E_a)*parameters.PHY.P_min+parameters.PHY.E_Pct) >=tmp_v_sdp(ind_node)>=1/((1+parameters.PHY.E_a)*parameters.PHY.P_max+parameters.PHY.E_Pct)];
    end
    Obj =  -sum(src_rate_sdp);
   % Ops = sdpsettings('verbose',1,'solver','fmincon');
    Opti_results_power = optimize(Cons,Obj);
    optimize_problems(1,1) = Opti_results_power.problem;
    if Opti_results_power.problem == 0
        disp('************* Success: success allocate power ****************')
    else
        disp('************* Error: falied allocate power ****************')
    end
    total_src_rate = value(sum(src_rate_sdp));
    tran_power=(1./value(tmp_v_sdp)-parameters.PHY.E_Pct)./(1+parameters.PHY.E_a)
    src_rate_max=value(src_rate_sdp)
 
    %% 确定数据速率
    src_rate = min(parameters.Nodes.Nor_SrcRates, src_rate_max);
    
    %% 优化分配：节点时隙的分配
    % 确定各个节点的平均位置
    average_location_nodes = ones(1,num_nodes); 
    cur_EH_pos_min = parameters.EnergyHarvest.EH_pos_min(cur_pos,:);
    cur_EH_pos_max = parameters.EnergyHarvest.EH_pos_max(cur_pos,:);
    for ind_node =1:num_nodes
        % 计算节点在各个时隙的能量采集状态为On的概率
        cur_EH_P_tran = EH_P_tran{cur_pos, ind_node};           
        cur_EH_mean = (cur_EH_pos_min(ind_node)+cur_EH_pos_max(ind_node))/2;            
        [average_location_nodes(1,ind_node)] = findAverageLocation( EH_last_status(ind_node), tran_power(ind_node), src_rate(ind_node), re_num_slots(ind_node), cur_EH_P_tran, cur_EH_mean, tran_rate, parameters.EnergyHarvest.k_cor, parameters.MAC, parameters.PHY.E_a, parameters.PHY.E_Pct);
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
        % Cons = [Cons, ceil(tran_rate*n_sdp(1,ind_node)*t_slot/(parameters.Nodes.packet_length(1,ind_node)))>= ceil(src_rate(1,ind_node)*(re_num_slots(ind_node)+before_slots{1,ind_node})*t_slot/(P_th*parameters.Nodes.packet_length(1,ind_node)))];
        sense_time = (re_num_slots(ind_node)+before_slots{1,ind_node} + n_sdp(1,ind_node))*t_slot - parameters.Nodes.packet_length(1,ind_node)/tran_rate;
        Cons = [Cons, tran_rate*n_sdp(1,ind_node)*t_slot/(parameters.Nodes.packet_length(1,ind_node))>= (src_rate(1,ind_node)*sense_time/((1-P_th)*parameters.Nodes.packet_length(1,ind_node))+1)];
        Cons = [Cons, n_sdp(1,ind_node)>=1, g_sdp(1,ind_node)>=0];
    end
    %确定目标函数
    for ind_node =1:num_nodes 
        Obj = Obj +  before_slots{1,ind_node} - average_location_nodes(1,ind_node);
    end
    Cons = [Cons, sum(n_sdp+g_sdp)<=parameters.MAC.N_Slot];
    Ops = sdpsettings('verbose',1,'solver','cplex');
    Opti_results_slot = optimize(Cons,-Obj,Ops); 
    optimize_problems(1,1) = Opti_results_slot.problem; 
    if Opti_results_slot.problem == 0
        disp('************* Success: success allocate slot ****************')
    else
        disp('************* Error: falied allocate slot ****************')
    end
%     value(g_sdp)
%     value(n_sdp)
%     check(Cons)
    % 所分配的资源
    for ind_node =1:num_nodes
        Allocate(ind_node).power = tran_power(1,ind_node);
        Allocate(ind_node).src_rate = src_rate(1,ind_node);
        Allocate(ind_node).src_rate_max = src_rate_max(1,ind_node);
        begin_ind = value(before_slots{1,ind_node})+1;
        end_ind = value(before_slots{1,ind_node}) + value(n_sdp(1,ind_node));
        if end_ind > parameters.MAC.N_Slot
            disp(['error: max allocated num of slots exceed the MAC.N_slot']);
        end
        disp(strcat(['(ind_node,begin_slot,end_slot):',num2str(ind_node),',',num2str(begin_ind),',',num2str(end_ind)]));
        Allocate(ind_node).slot =  zeros(1,parameters.MAC.N_Slot);
        Allocate(ind_node).slot(1,begin_ind:end_ind) = 1;        
    end
end

