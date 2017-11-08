function []=channelQoSPar(PNoise,deltaPL,miuTh,avePLRth)

%% 计算由于平均丢包率约束所引入的参数
    % 加载配置文件
    format short %开启高精度
    configureChannelPar

%% 参数设置    
%计算总运行时间
    tic  
    Normal_P_Block=0;       %阻塞率
    Emergency_P_Block=0;       
    %BCH编码
    n_BCH_PSDU=63;  %BCH编码参数
    k_BCH_PSDU=51;
    t_BCH_PSDU=2;
    %节点
    N_Node=5;%节点数
    NoDis=[60,36,48,34,100];%节点与Hub之间的距离
    No_n=[3.11,3.23,3.35,3.45,3.11];%节点路径损耗系数
    N0P0=[35.2,41.2,32.2,32.5,35.2];%参考位置（10cm）出的路径损耗值
    NoPL=(N0P0+10.*No_n.*log10(NoDis./10))+deltaPL;%% 备注：这里如果加上一个常数是为了试验中提高路径损耗来观察实验结果
    d0=10; %参考距离为10cm
    P_Sensitivity=-85; %这里为了计算简单，将接收灵敏度设置为与数据速率无关的固定值
    BandWidth=1000;%单位kbps
    DataRate=[121.4;242.8;485.6;971.2]; %可选择的数据速率
    R_basic=121.4;    %节点数据速率

    PTxThmiuTh2(1:1:6,:)=miuTh+repmat(NoPL,6,1)+PNoise;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%% 计算QoS约束的系数%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    QoS_PiR=(BandWidth^-1)*power(10,PTxThmiuTh2/10);%计算平均丢包率系数，
    QoS_Rt=repmat((1./(1-avePLRth')),1,N_Node).* Rate*T_Frame+eps;
    QoS_D=repmat(delayTh-T_Frame*0.5,1,N_Node);
    QoS_iR=lenPacket./repmat((1-avePLRth)',1,N_Node);
    QoS_tmpV=ones(2,N_Node);
    QoS_N_Rt=2*Normal_L_packet;
    QoS_N_RtRtiTmpV=avePLRth(1)*(1-avePLRth(1))*Rate(1,:)*T_Frame./Normal_L_packet;%((KeseeB(1,:))*Rate(1,:)*T_Frame);
    QoS_N_Con=(2./(1-avePLRth(1)).*Normal_L_packet.*Rate(1,:)*T_Frame);
    QoS_E_Rt=repmat(2*(1-avePLRth(2)),1,N_Node);
    QoS_E_iRtTmpV=((1./(1-avePLRth(2))).*Emergency_L_packet.*Rate(2,:).*T_Frame);
    QoS_E_RtiTmpV=avePLRth(2).*(1-avePLRth(2))*Rate(2,:).*T_Frame./Emergency_L_packet;%(Rate(2,:).*T_Frame.*KeseeB(2,:));
    QoS_E_Con=(2.*Rate(2,:).*T_Frame);
    QoS_PtxMin=power(10,P_tx_min_dBm/10);
    QoS_PtxMax=power(10,P_tx_max_dBm/10);

    %计算硬件导致的发射门限
    P_tx_min=power(10,P_tx_min_dBm/10); %最小发射功率，单位为mw
    P_tx_max=power(10,P_tx_max_dBm/10); %最大发射功率，单位为mw
    %保存有用数据
    PLRInfo=strcat('./data/PLRN',num2str(avePLRth(1)),'E',num2str(avePLRth(2)))
    ChannelParPATH =strcat(PLRInfo,'_channel_Pnoise',num2str(PNoise),'_deltaPL',num2str(deltaPL),'.mat')
    QoSParPATH=strcat(PLRInfo,'_QoS_Pnoise',num2str(PNoise),'_deltaPL',num2str(deltaPL),'.mat')
    save(ChannelParPATH );
    save(QoSParPATH,'QoS_*');





 
