function [ AllocatePowerRate, opti_problems ] = allocateTranPower( miu_th, parameters )
%allocateTranPower 分配长期的传输功率，对于不同的身体姿势结果不同
%输入
%   miu_th 计算PLR的等效门限：平均信噪比门限miu_th
%   parameters 配置参数
%输出
%   AllocatePowerRate 给各个节点分配的传输功率和数据速率
%   opti_problems 优化问题出现的问题，0表示没有问题
    
    %% 简化常用参数
    num_nodes = parameters.Nodes.Num; %节点个数
    tran_rate = parameters.Nodes.tranRate(1); %这里假设所有节点的传输速率都是一样的
    AllocatePowerRate = {};
    for cur_pos = 1:parameters.Postures.Num
        % 初始化参数
        src_rate_max = zeros(1,num_nodes); %能量采集所能传输的最大数据速率
        tran_power = zeros(1,num_nodes); %传输功率
        % 能量采集相关
        EH_P_on = zeros(1,num_nodes); %各个节点在当前身体姿势下的能量采集状态为On的概率密度
        EH_pos_min = parameters.EnergyHarvest.EH_pos_min(cur_pos,:); %各个节点能量采集速率
        EH_pos_max = parameters.EnergyHarvest.EH_pos_max(cur_pos,:);
        ratio = 1;
        EH_pos_mean = (1-ratio)*EH_pos_min + ratio*EH_pos_max;
        for ind_node= 1:num_nodes
            EH_P_on(1,ind_node) =  parameters.EnergyHarvest.EH_P_state{cur_pos,ind_node}(1);
        end
        P_miu_th = parameters.Nodes.tranRate.*power(10,(miu_th(cur_pos,:)+parameters.Nodes.PL_Fr+parameters.Channel.PNoise)/10)./parameters.Channel.Bandwidth; %计算满足丢包率的等效门限传输功率
        %% 优化问题来实现传输功率的分配以及能量采集到能量能传输的数据速率:这部分可以离线处理
        v_sdp = sdpvar(1,num_nodes); %中间变量，v=1/((1+a)Ptx+Pct) , Ptx = (1/v-Pct)/(1+a)
        src_rate_sdp = sdpvar(1,num_nodes); %给各个节点分配的数据源速率
        PLR_th = parameters.Constraints.Nor_PLR_th;
        Cons = [];
        for ind_node = 1:num_nodes      
           Cons = [Cons, EH_P_on(1,ind_node)*(EH_pos_mean(1,ind_node))*tran_rate>=src_rate_sdp(1,ind_node)/(v_sdp(1,ind_node)*(1-PLR_th))]; 
           Cons = [Cons, src_rate_sdp(1,ind_node)>=0];
           Cons = [Cons, v_sdp(ind_node)<=1./((1+parameters.PHY.E_a)*P_miu_th(ind_node)+parameters.PHY.E_Pct)];
           Cons = [Cons, 1/((1+parameters.PHY.E_a)*parameters.PHY.P_min+parameters.PHY.E_Pct) >=v_sdp(ind_node)>=1/((1+parameters.PHY.E_a)*parameters.PHY.P_max+parameters.PHY.E_Pct)];
        end
        Obj =  -sum(src_rate_sdp);
       % Ops = sdpsettings('verbose',1,'solver','fmincon');
        Opti_results_power = optimize(Cons,Obj);
        opti_problems(1,cur_pos) = Opti_results_power.problem;
        if Opti_results_power.problem == 0
            disp('************* Success: success allocate power ****************')
        else
            disp('************* Error: falied allocate power ****************')
        end
        total_src_rate = value(sum(src_rate_sdp));
        tran_power=(1./value(v_sdp)-parameters.PHY.E_Pct)./(1+parameters.PHY.E_a)
        src_rate_max=value(src_rate_sdp)
        %% 确定数据速率,将数据速率限制在[min_src_rate,normal_src_rate]之间
        src_rate = min(parameters.Nodes.Nor_SrcRates, src_rate_max);
        src_rate = max(src_rate, parameters.Nodes.min_SrcRates);
        tmp_allocate={};
        for ind_node =1:num_nodes
            tmp_allocate{1,ind_node}.power = tran_power(1,ind_node);
            tmp_allocate{1,ind_node}.src_rate = src_rate(1,ind_node);
            tmp_allocate{1,ind_node}.src_rate_max = src_rate_max(1,ind_node);    
        end
        AllocatePowerRate{1,cur_pos} = tmp_allocate;
    end
end

