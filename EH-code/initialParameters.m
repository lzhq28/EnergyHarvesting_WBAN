%%%%%%%%%%%%%%%%%% ��ʼ������ %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function parameters = initialParameters()
   
   %% PHY
    % ���书��
    PHY.P_dB = -30:3:0; % ���书�ʵ�ȡֵ��Χ����λdBm
    PHY.P_min_dB = min(PHY.P_dB); % ���书�ʵ���Сֵ����λdBm
    PHY.P_max_dB = max(PHY.P_dB); % ���书�ʵ����ֵ����λdBm
    PHY.P = power(10,PHY.P_dB/10); % ���书�ʵ�ȡֵ��Χ����λmw
    PHY.P_min = min(PHY.P); % ���书�ʵ���Сֵ����λmw
    PHY.P_max = max(PHY.P); % ���书�ʵ����ֵ����λmw
    % ��������
    PHY.RateSet = [121.4, 242.8, 485.6, 971.2]; % �������ʼ�
    % �ܺ�ģ�Ͳ�����Econ=(1+E_a)*Ptx*t+Pct*t
    PHY.E_a = 2.4; % ��·�ܺ��뷢���ܺ���ز���
    PHY.E_Pct = 50*0.001; % �̶��ĵ�·�ܺģ�0.5uw,0.5*0.001mw,��λΪmw
    parameters.PHY = PHY; % ����ģ����ز���
   
   %% MAC
    MAC.T_Slot = 0.5; %��λms
    MAC.T_Frame = 100; % ��֡����100ms
    MAC.N_Slot = MAC.T_Frame/MAC.T_Slot;
    parameters.MAC = MAC;
    
   %% Channel
    % �ŵ�����
    Channel.PNoise = -94; %��λdB
    Channel.Bandwidth = 1000; % ��λkbps
    Channel.Sensitivity = -85; % ���ջ������ȣ�Ӧ���ò�����
    % �ŵ�����:BCH�ŵ�����
    Channel.BCH_n = 63; % BCH�������
    Channel.BCH_k = 51; 
    Channel.BCH_t = 2; 
    parameters.Channel = Channel; 
    
    %% Nodes
    Nodes.Num = 5; % WBAN�����߽ڵ������
    Nodes.Distance = [60,36,48,34,100]; % �����ڵ���Hub֮��ľ��룬��λcm
    Nodes.PL_n = [3.11,3.23,3.35,3.45,3.11]; % �ڵ�·�����ϵ��
    Nodes.PL_P0 = [35.2,41.2,32.2,32.5,35.2];%�ο�λ�ã�10cm������·�����ֵ
    Nodes.PL_d0 =10; % �ο�����Ϊ10cm����λcm
    Nodes.PL_Fr = Nodes.PL_P0 + 10.*Nodes.PL_n.*log10(Nodes.Distance./Nodes.PL_d0); % PL = PL_Fr+X
    Nodes.Sigma = [[6.0475,	4.8124,	5.1064,	2.6247,	2.2669],
                    [4.9483, 7.2704, 4.2025,3.0444,	2.5985],
                    [5.7060	7.5404	3.8987	3.5210	1.9647]]; % ע�⣺���Ӧ����Ҫ���е�������Ϊ��ͬ�����µ��ŵ���������
    Nodes.Nor_SrcRates = [40,68,34,50,35]; % �����ڵ�����������������ʣ���λkbps
    Nodes.Emer_SrcRates = [10,10,10,10,10]; % �����ڵ�Ľ������ĵ���������,��λkbps
    Nodes.tranRate = repmat(parameters.PHY.RateSet(3), 1, Nodes.Num); % ���õĽڵ㴫������
    Nodes.packet_length = repmat(500,1,Nodes.Num);
    Nodes.buffer_size = repmat(100*1000,1,Nodes.Num); %����Ĵ�С����λbit
    Nodes.num_packet_buffer = floor(Nodes.buffer_size./Nodes.packet_length); %�ڵ㻺�����ܱ����������
    Nodes.lambda_Emer =floor(Nodes.Emer_SrcRates.*parameters.MAC.T_Frame./Nodes.packet_length);
    parameters.Nodes = Nodes; % �ڵ�Ĳ���
    % �����������
    Postures.Num = 3; 
    Postures.Name = {'still','walk','run'};
    Postures.P_state = [0.5, 0.3, 0.2]; % �����������Ƶ���̬����
    Postures.P_ini = [0.7,0.5,0.5; 0.15,0.3,0.2; 0.15,0.2,0.3;]; %��ʼ��״̬ת�ƾ���,һ�еĺ�Ϊ1
    parameters.Postures = Postures;
    
    %% Constraints
    Constraints.Nor_Delay_th = 500; % ��ͨ��ʱ�����ޣ���λms
    Constraints.Emer_Delay_th = 400; % ������ʱ�����ޣ���λms
    Constraints.Nor_PLR_th = 0.05; %��ͨ������������
    Constraints.Emer_PLR_th = 0.05; %����������������
    parameters.Constraints = Constraints;
    
    %% Energy Harvesting
    EnergyHarvest.EH_pos_min = [[0.001, 0.010, 0.05, 0.01, 0.04],
                                [0.128, 0.240, 0.15, 0.200, 0.4],
                                [0.724, 0.95, 0.8, 0.9, 0.13]]; % ��ͬ�����µ������ɼ����ʵ���Сֵ����λmw���պ�mw*ms=uJ
    EnergyHarvest.EH_pos_max = [[0.0048, 0.05,0.095, 0.02, 0.05],
                                [0.186, 0.31, 0.21, 0.28, 0.48],
                                [0.915, 1.20, 0.88, 1.15, 1.56]]; % ��ͬ�����µ������ɼ����ʵ����ֵ����λmw���պ�mw*ms=uJ
    EnergyHarvest.EH_P_state = {[0.9,0.1],[0.8,0.2],[0.9,0.1],[0.8,0.2],[0.7,0.3],
                                [0.3,0.7],[0.4,0.6],[0.3,0.7],[0.4,0.6],[0.6,0.4],
                                [0.4,0.6],[0.5,0.5], [0.45,0.55],[0.6,0.4],[0.8,0.2]}; % ��ͬ�����������ɼ�״̬ΪON�ĸ���
    EnergyHarvest.EH_P_ini = {[0.8,0.7;0.2,0.3],[0.78,0.82;0.22,0.18],[0.8,0.7;0.2,0.3],[0.78,0.82;0.22,0.18],[0.74,0.68;0.26,0.32],
                                [0.4,0.35;0.6,0.65],[0.42,0.38;0.58,0.62],[0.4,0.35;0.6,0.65], [0.42,0.38;0.58,0.62], [0.65,0.58;0.35,0.42],
                                [0.45,0.35;0.55,0.65],[0.53,0.45;0.47,0.55],[0.47,0.50;0.53,0.5],[0.65,0.58;0.35,0.42],[0.78,0.82;0.22,0.18]}; %��ʼ��״̬ת�ƾ���
    EnergyHarvest.t_cor_EH = 20; % ���������ɼ�״̬��ά�ֵ�ʱ�䣬һ������ΪT_Slot��������,��λms
    EnergyHarvest.k_cor = ceil(EnergyHarvest.t_cor_EH/MAC.T_Slot); %���ʱ϶������ͬһ�������ɼ�״̬��ά�ֵ�ʱ϶��
    parameters.EnergyHarvest = EnergyHarvest;

    
 
    
   
    
   


    
    
    