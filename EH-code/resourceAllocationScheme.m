function [ Allocate ] = resourceAllocationScheme( cur_pos, cur_miu_th, re_num_slots, EH_last_status, EH_P_tran, parameters)
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
 
    %% ��ʼ������
    % parameters = par
    % cur_miu_th = miu_th(cur_pos,:);
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
    cur_miu_th = miu_th(cur_pos,:);
    P_miu_th = parameters.Nodes.tranRate.*power(10,(cur_miu_th+parameters.Nodes.PL_Fr+parameters.Channel.PNoise)/10)./parameters.Channel.Bandwidth; %�������㶪���ʵĵ�Ч���޴��书��
    
    %% �Ż�������ʵ�ִ��书�ʵķ����Լ������ɼ��������ܴ������������
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
    Opti_results = optimize(Cons,Obj);
    total_src_rate = value(sum(src_rate_sdp));
    tran_power=(1./value(tmp_v_sdp)-parameters.PHY.E_Pct)./(1+parameters.PHY.E_a)
    src_rate_max=value(src_rate_sdp);
    
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
     
    
    %% �Ż���������ڵ��ʱ϶
    g_sdp = intvar(1,num_nodes); %�ڵ����ʱ϶λ������ͨλ��֮��ļ��ʱ϶��
    n_sdp = intvar(1,num_nodes); %������ڵ��ʱ϶��
    Cons = [];
    Obj1 = 0;
    Obj2 = 0;
    %ȷ��Ŀ�꺯��
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
    for ind_node =1:num_nodes 
        Obj1 =  Obj1 + (num_nodes + 1 - order_nodes(ind_node))*g_sdp(1,ind_node)+ (num_nodes - order_nodes(ind_node))*n_sdp(1,ind_node);
        Obj2 = Obj2 +  before_slots{1,ind_node} - average_location_nodes(1,ind_node);
    end
    Obj1 = Obj1 - sum(average_location_nodes);
    
    
    %ȷ��Լ������
    for ind_node =1:num_nodes
        Cons = [Cons, tran_rate*n_sdp(1,ind_node)>=src_rate(1,ind_node)*(re_num_slots(ind_node)+before_slots{1,ind_node})];
        Cons = [Cons, n_sdp(1,ind_node)>=0, g_sdp(1,ind_node)>=0];
    end
    Cons = [Cons, sum(n_sdp+g_sdp)<=parameters.MAC.N_Slot];
    Ops = sdpsettings('verbose',1,'solver','cplex');
    Opti_results = optimize(Cons,-Obj1,Ops)
    value(g_sdp)
    value(n_sdp)
    
    assign(g_sdp,[0,0,0,0,0])
    assign(g_sdp,[0,0,0,0,0])
end

