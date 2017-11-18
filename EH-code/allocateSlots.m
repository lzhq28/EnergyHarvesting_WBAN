function [  AllocateSlots, opti_problem, GOODSET, BADSET ] = allocateSlots(cur_pos, allocatePowerRate, residue_energy, re_num_packets, re_num_slots, EH_last_status, EH_P_tran, parameters )
%allocateSlots �������ڵ����ʱ϶
%����
%   cur_pos ��ǰ��������
%   residue_energy �ڵ���һ״̬��ʣ������
%   re_num_packets ��һ��֡�����󻺴���ʣ�����ݰ�
%   re_num_slots �ڵ���һ��֡�������ʱ϶ĩβλ�õ�Beaconλ�õ�ʱ϶��
%   EH_last_status �����ڵ�����һ��֡�������ɼ�״̬
%   EH_P_tran �����ڵ��ڲ�ͬ�����µ������ɼ�״̬ת�ƾ���
%   parameters ���ò���
%���
%   AllocateSlots �������ڵ�����ʱ϶��ÿһ�б�ʾ��һ���ڵ�ķ�����
%   opti_problem �Ż�ʱ϶�����з��ص����⣬0��ʾ�ɹ��Ż�
    %% ����
%     allocatePowerRate=AllocatePowerRate{1,cur_pos}
%     parameters = par
 %% �򻯳��ò���
    num_nodes = parameters.Nodes.Num; %�ڵ����
    tran_rate = parameters.Nodes.tranRate(1); %����������нڵ�Ĵ������ʶ���һ����
    cur_EH_pos_min = parameters.EnergyHarvest.EH_pos_min(cur_pos,:);
    cur_EH_pos_max = parameters.EnergyHarvest.EH_pos_max(cur_pos,:);
    E_a = parameters.PHY.E_a;
    E_Pct=parameters.PHY.E_Pct;
    t_slot = parameters.MAC.T_Slot;
    P_th = parameters.Constraints.Nor_PLR_th;
    AllocateSlots = zeros(num_nodes,parameters.MAC.N_Slot); %�������ڵ��������ʱ϶λ��
    opti_problem = zeros(1,2);%ͳ���Ż�����Ƿ��������
    %% �Ż����䣺�ڵ�ʱ϶�ķ���
    % ���ݽڵ��ʣ��������ƽ���ɼ�����������ƽ������������֮��Ĺ�ϵ�Խڵ���з���
    GOODSET=[]; %��������Ľڵ�
    BADSET=[];%��������Ľڵ�
    for ind_node = 1:num_nodes     
        cur_node = allocatePowerRate{ind_node};
        cur_EH_mean = (cur_EH_pos_min(ind_node)+cur_EH_pos_max(ind_node))/2;     
        average_energy_cost = ((1+ E_a)*cur_node.power + E_Pct) * ceil(cur_node.src_rate * parameters.MAC.T_Frame/parameters.Nodes.packet_length(ind_node))*parameters.Nodes.packet_length(ind_node)/tran_rate;
        if residue_energy(1,ind_node) > average_energy_cost %����ʣ�������Ƿ��㹻����ƽ��һ��֡���ܲɼ����������������ڵ���������
            GOODSET = [GOODSET,ind_node];
        else
            BADSET = [BADSET,ind_node];
        end
    end
    %% ���ڲ�ͬ������״̬�Ľڵ㼯�ϲ��ò�ͬ�Ĳ���
    %% ���������������ݰ����Ͻ������ݴ���
    if ~isempty(BADSET) %�ȶ���������Ľڵ��ȡ������
        num_bad_nodes = size( BADSET,2);
        average_location_nodes = ones(1,num_bad_nodes); 
        for ind_node = 1:num_bad_nodes
            actu_ind =  BADSET(1,ind_node); %�ڵ���������ţ�Ҳ����ID�ţ���ind_node����BADSET�е��������
            cur_node = allocatePowerRate{actu_ind};
            % ����ڵ��ڸ���ʱ϶�������ɼ�״̬ΪOn�ĸ���
            cur_EH_P_tran = EH_P_tran{cur_pos, actu_ind}; 
            cur_EH_mean = (cur_EH_pos_min(actu_ind)+cur_EH_pos_max(actu_ind))/2; 
            [average_location_nodes(1,ind_node)] = findAverageLocation( EH_last_status(actu_ind), cur_node.power, cur_node.src_rate, re_num_slots(actu_ind), cur_EH_P_tran, cur_EH_mean, tran_rate, parameters.EnergyHarvest.k_cor, parameters.MAC, E_a, E_Pct);
        end
        % ����ƽ��λ�ý��нڵ�����
        [tmp_values, order_nodes] = sort(average_location_nodes,'ascend'); 
        % �����������
        g_sdp = intvar(1,num_bad_nodes); %�ڵ����ʱ϶λ������ͨλ��֮��ļ��ʱ϶��
        n_sdp = intvar(1,num_bad_nodes); %������ڵ��ʱ϶��
        Cons = [];
        Obj = 0;
        %ȷ��ÿ��ʱ϶�ĳ�ʼλ��
        before_slots = {};
        for ind_node =1:num_bad_nodes 
            tmp_obj =0;
            for j = 1:(order_nodes(ind_node)-1) %ȷ���ýڵ�ǰ�����нڵ��ʱ϶
                cur_ind = find(order_nodes==j);
                tmp_obj= tmp_obj + (g_sdp(1,cur_ind) + n_sdp(1,cur_ind));  
            end
            tmp_obj = tmp_obj + g_sdp(1,ind_node); 
            before_slots{1,ind_node} = tmp_obj; 
        end
        %ȷ��Լ������
        for ind_node =1:num_bad_nodes 
            actu_ind =  BADSET(1,ind_node); %�ڵ���������ţ�Ҳ����ID�ţ���ind_node����BADSET�е��������
            cur_node = allocatePowerRate{actu_ind};
            % Cons = [Cons, ceil(tran_rate*n_sdp(1,ind_node)*t_slot/(parameters.Nodes.packet_length(1,actu_ind)))>= ceil(cur_node.src_rate*(re_num_slots(actu_ind)+before_slots{1,ind_node})*t_slot/(P_th*parameters.Nodes.packet_length(1,actu_ind)))];
            sense_time = (re_num_slots(actu_ind)+before_slots{1,ind_node} + n_sdp(1,ind_node))*t_slot - parameters.Nodes.packet_length(1,actu_ind)/tran_rate;
            Cons = [Cons, tran_rate*n_sdp(1,ind_node)*t_slot/(parameters.Nodes.packet_length(1,actu_ind))>= (cur_node.src_rate*sense_time/((1-P_th)*parameters.Nodes.packet_length(1,actu_ind))+1)];
            Cons = [Cons, n_sdp(1,ind_node)>=1, g_sdp(1,ind_node)>=0];
        end
        %ȷ��Ŀ�꺯��
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
         % ���������Դ
        for ind_node =1:num_bad_nodes
            begin_ind = value(before_slots{1,ind_node})+1;
            end_ind = value(before_slots{1,ind_node}) + value(n_sdp(1,ind_node));
            actu_ind = BADSET(1,ind_node); %�ڵ���������ţ�Ҳ����ID�ţ���ind_node����BADSET�е��������
            if end_ind > parameters.MAC.N_Slot
                disp(['error: max allocated num of slots exceed the MAC.N_slot']);
            end
            %disp(strcat(['(ind_node,begin_slot,end_slot):',num2str(ind_node),',',num2str(begin_ind),',',num2str(end_ind)]));
            AllocateSlots(actu_ind,begin_ind:end_ind) =  1;    
        end
    end
    %% ���������������ݰ�������Դ����
    if ~isempty(GOODSET) %�ȶ���������Ľڵ����ʱ϶���䣬��Ҫ��עʱ϶��������λ�ò�����
        remain_slots_inds = find(sum(AllocateSlots)==0); %����ʣ��ڵ������
        num_remain_slots = size(remain_slots_inds,2);%ʣ��ʱ϶��
        num_good_nodes = size(GOODSET,2);
        % ������������Ľڵ�
        n_sdp = intvar(1,num_good_nodes); %������ڵ��ʱ϶��
        Cons = [];
        Obj = 0;
        for ind_node = 1:num_good_nodes
            actu_ind =  GOODSET(1,ind_node); %�ڵ���������ţ�Ҳ����ID�ţ���ind_node����BADSET�е��������
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
        % ��GOODSET�е�ʱ϶���з���
        begin_ind = remain_slots_inds(end)+1;
        end_ind = remain_slots_inds(end);
        for ind_node = 1:num_good_nodes
            re_ind = num_good_nodes-ind_node+1;% �����ŷ���ʱ϶
            actu_ind =  GOODSET(1,re_ind); %�ڵ���������ţ�Ҳ����ID�ţ���ind_node����BADSET�е��������
            end_ind = begin_ind -1;
            begin_ind = end_ind - value(n_sdp(1,re_ind)) + 1;         
            if begin_ind <0
                disp(['error: max allocated num of slots exceed the MAC.N_slot']);
            end
            %disp(strcat(['(ind_node,begin_slot,end_slot):',num2str(actu_ind ),',',num2str(begin_ind),',',num2str(end_ind)]));
            AllocateSlots(actu_ind,begin_ind:end_ind) = 1;    
        end
    end
    
    %% ȷ�������ڵ��ƽ��λ��
% %     average_location_nodes = ones(1,num_nodes); 
% %     for ind_node =1:num_nodes
% %         cur_node = allocatePowerRate{ind_node};
% %         % ����ڵ��ڸ���ʱ϶�������ɼ�״̬ΪOn�ĸ���
% %         cur_EH_P_tran = EH_P_tran{cur_pos, ind_node};           
% %         cur_EH_mean = (cur_EH_pos_min(ind_node)+cur_EH_pos_max(ind_node))/2;            
% %         [average_location_nodes(1,ind_node)] = findAverageLocation( EH_last_status(ind_node), cur_node.power, cur_node.src_rate, re_num_slots(ind_node), cur_EH_P_tran, cur_EH_mean, tran_rate, parameters.EnergyHarvest.k_cor, parameters.MAC, E_a, E_Pct);
% %     end
% %     % ����ƽ��λ�ý��нڵ�����
% %     [tmp_values, order_nodes] = sort(average_location_nodes,'ascend'); 
% %     % �����������
% %     g_sdp = intvar(1,num_nodes); %�ڵ����ʱ϶λ������ͨλ��֮��ļ��ʱ϶��
% %     n_sdp = intvar(1,num_nodes); %������ڵ��ʱ϶��
% %     Cons = [];
% %     Obj = 0;
% %     %ȷ��ÿ��ʱ϶�ĳ�ʼλ��
% %     before_slots = {};
% %     for ind_node =1:num_nodes 
% %         tmp_obj =0;
% %         for j = 1:(order_nodes(ind_node)-1) %ȷ���ýڵ�ǰ�����нڵ��ʱ϶
% %             cur_ind = find(order_nodes==j);
% %             tmp_obj= tmp_obj + (g_sdp(1,cur_ind) + n_sdp(1,cur_ind));  
% %         end
% %         tmp_obj = tmp_obj + g_sdp(1,ind_node); 
% %         before_slots{1,ind_node} = tmp_obj; 
% %     end
% %     %ȷ��Լ������
% %     t_slot = parameters.MAC.T_Slot;
% %     P_th = parameters.Constraints.Nor_PLR_th;
% %     for ind_node =1:num_nodes
% %         cur_node = allocatePowerRate{ind_node};
% %         % Cons = [Cons, ceil(tran_rate*n_sdp(1,ind_node)*t_slot/(parameters.Nodes.packet_length(1,ind_node)))>= ceil(cur_node.src_rate(1,ind_node)*(re_num_slots(ind_node)+before_slots{1,ind_node})*t_slot/(P_th*parameters.Nodes.packet_length(1,ind_node)))];
% %         sense_time = (re_num_slots(ind_node)+before_slots{1,ind_node} + n_sdp(1,ind_node))*t_slot - parameters.Nodes.packet_length(1,ind_node)/tran_rate;
% %         Cons = [Cons, tran_rate*n_sdp(1,ind_node)*t_slot/(parameters.Nodes.packet_length(1,ind_node))>= (cur_node.src_rate*sense_time/((1-P_th)*parameters.Nodes.packet_length(1,ind_node))+1)];
% %         Cons = [Cons, n_sdp(1,ind_node)>=1, g_sdp(1,ind_node)>=0];
% %     end
% %     %ȷ��Ŀ�꺯��
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
% %     % ���������Դ
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

