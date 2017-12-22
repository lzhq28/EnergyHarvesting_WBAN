function [ AllocatePowerRate, opti_problems ] = allocateTranPower( miu_th, parameters )
%allocateTranPower ���䳤�ڵĴ��书�ʣ����ڲ�ͬ���������ƽ����ͬ
%����
%   miu_th ����PLR�ĵ�Ч���ޣ�ƽ�����������miu_th
%   parameters ���ò���
%���
%   AllocatePowerRate �������ڵ����Ĵ��书�ʺ���������
%   opti_problems �Ż�������ֵ����⣬0��ʾû������
    
    %% �򻯳��ò���
    num_nodes = parameters.Nodes.Num; %�ڵ����
    tran_rate = parameters.Nodes.tranRate(1); %����������нڵ�Ĵ������ʶ���һ����
    AllocatePowerRate = {};
    for cur_pos = 1:parameters.Postures.Num
        % ��ʼ������
        src_rate_max = zeros(1,num_nodes); %�����ɼ����ܴ���������������
        tran_power = zeros(1,num_nodes); %���书��
        % �����ɼ����
        EH_P_on = zeros(1,num_nodes); %�����ڵ��ڵ�ǰ���������µ������ɼ�״̬ΪOn�ĸ����ܶ�
        EH_pos_min = parameters.EnergyHarvest.EH_pos_min(cur_pos,:); %�����ڵ������ɼ�����
        EH_pos_max = parameters.EnergyHarvest.EH_pos_max(cur_pos,:);
        ratio = 1;
        EH_pos_mean = (1-ratio)*EH_pos_min + ratio*EH_pos_max;
        for ind_node= 1:num_nodes
            EH_P_on(1,ind_node) =  parameters.EnergyHarvest.EH_P_state{cur_pos,ind_node}(1);
        end
        P_miu_th = parameters.Nodes.tranRate.*power(10,(miu_th(cur_pos,:)+parameters.Nodes.PL_Fr+parameters.Channel.PNoise)/10)./parameters.Channel.Bandwidth; %�������㶪���ʵĵ�Ч���޴��书��
        %% �Ż�������ʵ�ִ��书�ʵķ����Լ������ɼ��������ܴ������������:�ⲿ�ֿ������ߴ���
        v_sdp = sdpvar(1,num_nodes); %�м������v=1/((1+a)Ptx+Pct) , Ptx = (1/v-Pct)/(1+a)
        src_rate_sdp = sdpvar(1,num_nodes); %�������ڵ���������Դ����
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
        %% ȷ����������,����������������[min_src_rate,normal_src_rate]֮��
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

