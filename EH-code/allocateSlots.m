function [  AllocateSlots, opti_problem ] = allocateSlots(cur_pos, allocatePowerRate, re_num_slots, EH_last_status, EH_P_tran, parameters )
%allocateSlots �������ڵ����ʱ϶
%����
%   cur_pos ��ǰ��������
%   re_num_slots �ڵ���һ��֡�������ʱ϶ĩβλ�õ�Beaconλ�õ�ʱ϶��
%   EH_last_status �����ڵ�����һ��֡�������ɼ�״̬
%   EH_P_tran �����ڵ��ڲ�ͬ�����µ������ɼ�״̬ת�ƾ���
%   parameters ���ò���
%���
%   AllocateSlots �������ڵ�����ʱ϶��ÿһ�б�ʾ��һ���ڵ�ķ�����
%   opti_problem �Ż�ʱ϶�����з��ص����⣬0��ʾ�ɹ��Ż�
 %% �򻯳��ò���
    num_nodes = parameters.Nodes.Num; %�ڵ����
    tran_rate = parameters.Nodes.tranRate(1); %����������нڵ�Ĵ������ʶ���һ����
    %% �Ż����䣺�ڵ�ʱ϶�ķ���
    % ȷ�������ڵ��ƽ��λ��
    average_location_nodes = ones(1,num_nodes); 
    cur_EH_pos_min = parameters.EnergyHarvest.EH_pos_min(cur_pos,:);
    cur_EH_pos_max = parameters.EnergyHarvest.EH_pos_max(cur_pos,:);
    for ind_node =1:num_nodes
        cur_node = allocatePowerRate{ind_node};
        % ����ڵ��ڸ���ʱ϶�������ɼ�״̬ΪOn�ĸ���
        cur_EH_P_tran = EH_P_tran{cur_pos, ind_node};           
        cur_EH_mean = (cur_EH_pos_min(ind_node)+cur_EH_pos_max(ind_node))/2;            
        [average_location_nodes(1,ind_node)] = findAverageLocation( EH_last_status(ind_node), cur_node.power, cur_node.src_rate, re_num_slots(ind_node), cur_EH_P_tran, cur_EH_mean, tran_rate, parameters.EnergyHarvest.k_cor, parameters.MAC, parameters.PHY.E_a, parameters.PHY.E_Pct);
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
        cur_node = allocatePowerRate{ind_node};
        % Cons = [Cons, ceil(tran_rate*n_sdp(1,ind_node)*t_slot/(parameters.Nodes.packet_length(1,ind_node)))>= ceil(cur_node.src_rate(1,ind_node)*(re_num_slots(ind_node)+before_slots{1,ind_node})*t_slot/(P_th*parameters.Nodes.packet_length(1,ind_node)))];
        sense_time = (re_num_slots(ind_node)+before_slots{1,ind_node} + n_sdp(1,ind_node))*t_slot - parameters.Nodes.packet_length(1,ind_node)/tran_rate;
        Cons = [Cons, tran_rate*n_sdp(1,ind_node)*t_slot/(parameters.Nodes.packet_length(1,ind_node))>= (cur_node.src_rate*sense_time/((1-P_th)*parameters.Nodes.packet_length(1,ind_node))+1)];
        Cons = [Cons, n_sdp(1,ind_node)>=1, g_sdp(1,ind_node)>=0];
    end
    %ȷ��Ŀ�꺯��
    for ind_node =1:num_nodes 
        Obj = Obj +  before_slots{1,ind_node} - average_location_nodes(1,ind_node);
    end
    Cons = [Cons, sum(n_sdp+g_sdp)<=parameters.MAC.N_Slot];
    Ops = sdpsettings('verbose',0,'solver','cplex');
    Opti_results_slot = optimize(Cons,-Obj,Ops); 
    opti_problem = Opti_results_slot.problem; 
    if Opti_results_slot.problem == 0
        %disp('************* Success: success allocate slot ****************')
    else
        disp('************* Error: falied allocate slot ****************')
    end
    % ���������Դ
    AllocateSlots = zeros(num_nodes,parameters.MAC.N_Slot);
    for ind_node =1:num_nodes
        begin_ind = value(before_slots{1,ind_node})+1;
        end_ind = value(before_slots{1,ind_node}) + value(n_sdp(1,ind_node));
        if end_ind > parameters.MAC.N_Slot
            disp(['error: max allocated num of slots exceed the MAC.N_slot']);
        end
        %disp(strcat(['(ind_node,begin_slot,end_slot):',num2str(ind_node),',',num2str(begin_ind),',',num2str(end_ind)]));
        AllocateSlots(ind_node,begin_ind:end_ind) =  1;    
    end
end

