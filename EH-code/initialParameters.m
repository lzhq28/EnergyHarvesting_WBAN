%%%%%%%%%%%%%%%%%% 初始化参数 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function parameters = initialParameters()
   
   %% PHY
    % 传输功率
    PHY.P_dB = -30:3:0; % 传输功率的取值范围，单位dBm
    PHY.P_min_dB = min(PHY.P_dB); % 传输功率的最小值，单位dBm
    PHY.P_max_dB = max(PHY.P_dB); % 传输功率的最大值，单位dBm
    PHY.P = power(10,PHY.P_dB/10); % 传输功率的取值范围，单位mw
    PHY.P_min = min(PHY.P); % 传输功率的最小值，单位mw
    PHY.P_max = max(PHY.P); % 传输功率的最大值，单位mw
    % 传输速率
    PHY.RateSet = [121.4, 242.8, 485.6, 971.2]; % 传输速率集
    % 能耗模型参数：Econ=(1+E_a)*Ptx*t+Pct*t
    PHY.E_a = 2.4; % 电路能耗与发射能耗相关参数
    PHY.E_Pct = 0.5*0.001; % 固定的电路能耗，0.5uw,0.5*0.001mw,单位为mw
    parameters.PHY = PHY; % 能量模型相关参数
   
   %% MAC
    MAC.T_Slot = 0.5; %单位ms
    MAC.T_Frame = 100; % 超帧长度100ms
    MAC.N_Slot = MAC.T_Frame/MAC.T_Slot;
    parameters.MAC = MAC;
    
   %% Channel
    % 信道参数
    Channel.PNoise = -94; %单位dB
    Channel.Bandwidth = 1000; % 单位kbps
    Channel.Sensitivity = -85; % 接收机灵敏度（应该用不到）
    % 信道编码:BCH信道编码
    Channel.BCH_n = 63; % BCH编码参数
    Channel.BCH_k = 51; 
    Channel.BCH_t = 2; 
    parameters.Channel = Channel; 
    
    %% Nodes
    Nodes.Num = 5; % WBAN中无线节点的数量
    Nodes.Distance = [60,36,48,34,100]; % 各个节点与Hub之间的距离，单位cm
    Nodes.PL_n = [3.11,3.23,3.35,3.45,3.11]; % 节点路径损耗系数
    Nodes.PL_P0 = [35.2,41.2,32.2,32.5,35.2];%参考位置（10cm）出的路径损耗值
    Nodes.PL_d0 =10; % 参考距离为10cm，单位cm
    Nodes.PL_Fr = Nodes.PL_P0 + 10.*Nodes.PL_n.*log10(Nodes.Distance./Nodes.PL_d0); % PL = PL_Fr+X
    Nodes.Sigma = [[6.0475,	4.8124,	5.1064,	2.6247,	2.2669],
                    [4.9483, 7.2704, 4.2025,3.0444,	2.5985],
                    [5.7060	7.5404	3.8987	3.5210	1.9647]]; % 注意：这个应该需要进行调整，因为不同姿势下的信道参数相差不大
    Nodes.Nor_SrcRates = [40,68,34,50,35]; % 各个节点的正常包的数据速率，单位kbps
    Nodes.Emer_SrcRates = [10,10,10,10,10]; % 各个节点的紧急包的的数据速率,单位kbps
    Nodes.tranRates = repmat(parameters.PHY.RateSet(3), 1, Nodes.Num); % 配置的节点传输速率
    Nodes.packet_length = repmat(500,1,Nodes.Num);
    Nodes.buffer_size = repmat(100*1000,1,Nodes.Num); %缓存的大小，单位bit
    Nodes.num_packet_buffer = floor(Nodes.buffer_size./Nodes.packet_length); %节点缓存所能保存包的数量
    Nodes.lambda_Emer =floor(Nodes.Emer_SrcRates.*parameters.MAC.T_Frame./Nodes.packet_length);
    parameters.Nodes = Nodes; % 节点的参数
    % 身体姿势相关
    Postures.Num = 3; 
    Postures.Name = {'still','walk','run'};
    Postures.P_state = [0.5, 0.3, 0.2]; % 各个身体姿势的稳态概率
    Postures.P_ini = [0.7,0.5,0.5; 0.15,0.3,0.2; 0.15,0.2,0.3;]; %初始化状态转移矩阵,一列的和为1
    parameters.Postures = Postures;
    
    %% Constraints
    Constraints.Nor_Delay_th = 500; % 普通包时延门限，单位ms
    Constraints.Emer_Delay_th = 400; % 紧急包时延门限，单位ms
    Constraints.Nor_PLR_th = 0.1; %普通包丢包率门限
    Constraints.Emer_PLR_th = 0.05; %紧急包丢包率门限
    parameters.Constraints = Constraints;
    
    %% Energy Harvesting
    EnergyHarvest.EH_pos_min = [0.001, 0.1286, 0.7242]; % 不同姿势下的能量采集功率的最小值，单位mw，刚好mw*ms=uJ
    EnergyHarvest.EH_pos_max = [0.0048, 0.186,0.910]; % 不同姿势下的能量采集功率的最大值，单位mw，刚好mw*ms=uJ
    EnergyHarvest.EH_P_state = {[0.9,0.1],[0.3,0.7],[0.4,0.6]}; % 不同姿势下能量采集状态为ON的概率
    EnergyHarvest.EH_P_ini = {[0.8,0.7;0.2,0.3],[0.4,0.35;0.6,0.65],[0.45,0.35;0.55,0.65]}; %初始化状态转移矩阵
    EnergyHarvest.t_cor_EH = 12; % 单个能量采集状态所维持的时间，一般设置为T_Slot的整数倍,单位ms
    parameters.EnergyHarvest = EnergyHarvest;

    
   
    
   
    
   


    
    
    