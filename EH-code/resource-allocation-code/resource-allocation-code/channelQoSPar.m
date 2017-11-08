function []=channelQoSPar(PNoise,deltaPL,miuTh,avePLRth)

%% ��������ƽ��������Լ��������Ĳ���
    % ���������ļ�
    format short %�����߾���
    configureChannelPar

%% ��������    
%����������ʱ��
    tic  
    Normal_P_Block=0;       %������
    Emergency_P_Block=0;       
    %BCH����
    n_BCH_PSDU=63;  %BCH�������
    k_BCH_PSDU=51;
    t_BCH_PSDU=2;
    %�ڵ�
    N_Node=5;%�ڵ���
    NoDis=[60,36,48,34,100];%�ڵ���Hub֮��ľ���
    No_n=[3.11,3.23,3.35,3.45,3.11];%�ڵ�·�����ϵ��
    N0P0=[35.2,41.2,32.2,32.5,35.2];%�ο�λ�ã�10cm������·�����ֵ
    NoPL=(N0P0+10.*No_n.*log10(NoDis./10))+deltaPL;%% ��ע�������������һ��������Ϊ�����������·��������۲�ʵ����
    d0=10; %�ο�����Ϊ10cm
    P_Sensitivity=-85; %����Ϊ�˼���򵥣�����������������Ϊ�����������޹صĹ̶�ֵ
    BandWidth=1000;%��λkbps
    DataRate=[121.4;242.8;485.6;971.2]; %��ѡ�����������
    R_basic=121.4;    %�ڵ���������

    PTxThmiuTh2(1:1:6,:)=miuTh+repmat(NoPL,6,1)+PNoise;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%% ����QoSԼ����ϵ��%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    QoS_PiR=(BandWidth^-1)*power(10,PTxThmiuTh2/10);%����ƽ��������ϵ����
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

    %����Ӳ�����µķ�������
    P_tx_min=power(10,P_tx_min_dBm/10); %��С���书�ʣ���λΪmw
    P_tx_max=power(10,P_tx_max_dBm/10); %����书�ʣ���λΪmw
    %������������
    PLRInfo=strcat('./data/PLRN',num2str(avePLRth(1)),'E',num2str(avePLRth(2)))
    ChannelParPATH =strcat(PLRInfo,'_channel_Pnoise',num2str(PNoise),'_deltaPL',num2str(deltaPL),'.mat')
    QoSParPATH=strcat(PLRInfo,'_QoS_Pnoise',num2str(PNoise),'_deltaPL',num2str(deltaPL),'.mat')
    save(ChannelParPATH );
    save(QoSParPATH,'QoS_*');





 
