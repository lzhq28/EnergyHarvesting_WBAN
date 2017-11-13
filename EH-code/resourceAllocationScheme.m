function [ Allocate, optimize_problems ] = resourceAllocationScheme( cur_pos, cur_miu_th, re_num_slots, EH_last_status, EH_P_tran, parameters)
%resourceAllocationScheme ����������Դ�������
%���룺
%   cur_pos ��ǰ��������
%   cur_miu_th �����ڵ��ڵ�ǰ�����µ�ƽ�����������
%   re_num_slots �ڵ���һ��֡�������ʱ϶ĩβλ�õ�Beaconλ�õ�ʱ϶��
%   EH_last_status �����ڵ�����һ��֡�������ɼ�״̬
%   EH_P_tran �����ڵ��ڲ�ͬ�����µ������ɼ�״̬ת�ƾ���
%   parameters ȫ�����õĲ�����������Nodes �����ڵ�Ļ�����Ϣ��PHY ����������MAC MAC������Channel
%   �ŵ�������Constraints ��������Լ���� EnergyHarvest �����ɼ���ز���
%�����
%   Allocate ����������ڵ����Դ��[power,src_rate,slot_ind]
%   optimize_problems �Ż����书�ʺ��Ż�����ʱ϶�е����⣬0��ʾû������[opt_power_problem,opt_slot_problem]
 
    %% ��ʼ������
    % parameters = par
    % cur_miu_th = miu_th(cur_pos,:);
    optimize_problems = zeros(1,2);
    num_nodes = parameters.Nodes.Num; %�ڵ����
    tran_rate = parameters.Nodes.tranRate(1); %����������нڵ�Ĵ������ʶ���һ����
    src_rate_max = zeros(1,num_nodes); %�����ɼ����ܴ���������������
    tran_power = zeros(1,num_nodes); %���书��
    EH_P_on = zeros(1,num_nodes); %�����ڵ��ڵ�ǰ���������µ������ɼ�״̬ΪOn�ĸ����ܶ�
    EH_pos_min = parameters.EnergyHarvest.EH_pos_min(cur_pos,:); %�����ڵ������ɼ�����
    EH_pos_max = parameters.EnergyHarvest.EH_pos_max(cur_pos,:);
    for ind_node= 1:num_nodes
        EH_P_on(1,ind_node) =  parameters.EnergyHarvest.EH_P_state{cur_pos,ind_node}(1);
    end
    P_miu_th = parameters.Nodes.tranRate.*power(10,(cur_miu_th+parameters.Nodes.PL_Fr+parameters.Channel.PNoise)/10)./parameters.Channel.Bandwidth; %�������㶪���ʵĵ�Ч���޴��书��
    
    %% �Ż�������ʵ�ִ��书�ʵķ����Լ������ɼ��������ܴ������������:�ⲿ�ֿ������ߴ���
    tmp_v_sdp = sdpvar(1,num_nodes); %�м������v=1/((1+a)Ptx+Pct) , Ptx = (1/v-Pct)/(1+a)
    src_rate_sdp = sdpvar(1,num_nodes); %�������ڵ���������Դ����
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
 
    %% ȷ����������
    src_rate = min(parameters.Nodes.Nor_SrcRates, src_rate_max);
    
    %% �Ż����䣺�ڵ�ʱ϶�ķ���
    % ȷ�������ڵ��ƽ��λ��
    average_location_nodes = ones(1,num_nodes); 
    cur_EH_pos_min = parameters.EnergyHarvest.EH_pos_min(cur_pos,:);
    cur_EH_pos_max = parameters.EnergyHarvest.EH_pos_max(cur_pos,:);
    for ind_node =1:num_nodes
        % ����ڵ��ڸ���ʱ϶�������ɼ�״̬ΪOn�ĸ���
        cur_EH_P_tran = EH_P_tran{cur_pos, ind_node};           
        cur_EH_mean = (cur_EH_pos_min(ind_node)+cur_EH_pos_max(ind_node))/2;            
        [average_location_nodes(1,ind_node)] = findAverageLocation( EH_last_status(ind_node), tran_power(ind_node), src_rate(ind_node), re_num_slots(ind_node), cur_EH_P_tran, cur_EH_mean, tran_rate, parameters.EnergyHarvest.k_cor, parameters.MAC, parameters.PHY.E_a, parameters.PHY.E_Pct);
    end
    % ����ƽ��λ�ý��нڵ�����
    [tmp_values, order_nodes] = sort(average_location_nodes,'ascend'); 
    % �����������
    g_sdp = intvar(1,num_nodes); %�ڵ����ʱ϶λ������ͨλ��֮��ļ��ʱ϶��
    n_sdp = intvar(1,num_nodes); %������ڵ��ʱ϶��
    Cons = [];
    Obj = 0;
    %ȷ��ÿ��ʱ϶�ĳ�ʼλ��
    before_slots = {};
    for ind_node =1:num_nodes 
        tmp_obj =0;
        for j = 1:(order_nodes(ind_node)-1) %ȷ���ýڵ�ǰ�����нڵ��ʱ϶
            cur_ind = find(order_nodes==j);
            tmp_obj= tmp_obj + (g_sdp(1,cur_ind) + n_sdp(1,cur_ind));  
        end
        tmp_obj = tmp_obj + g_sdp(1,ind_node); 
        before_slots{1,ind_node} = tmp_obj; 
    end
    %ȷ��Լ������
    t_slot = parameters.MAC.T_Slot;
    P_th = parameters.Constraints.Nor_PLR_th;
    for ind_node =1:num_nodes
        % Cons = [Cons, ceil(tran_rate*n_sdp(1,ind_node)*t_slot/(parameters.Nodes.packet_length(1,ind_node)))>= ceil(src_rate(1,ind_node)*(re_num_slots(ind_node)+before_slots{1,ind_node})*t_slot/(P_th*parameters.Nodes.packet_length(1,ind_node)))];
        sense_time = (re_num_slots(ind_node)+before_slots{1,ind_node} + n_sdp(1,ind_node))*t_slot - parameters.Nodes.packet_length(1,ind_node)/tran_rate;
        Cons = [Cons, tran_rate*n_sdp(1,ind_node)*t_slot/(parameters.Nodes.packet_length(1,ind_node))>= (src_rate(1,ind_node)*sense_time/((1-P_th)*parameters.Nodes.packet_length(1,ind_node))+1)];
        Cons = [Cons, n_sdp(1,ind_node)>=1, g_sdp(1,ind_node)>=0];
    end
    %ȷ��Ŀ�꺯��
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
    % ���������Դ
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

