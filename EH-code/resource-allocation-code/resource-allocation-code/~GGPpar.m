clc
clear all
%% 参数设置    
    %计算总运行时间
    tic  
    %超帧相关
    T_Slot=3.5;%d单个时隙长度为3.5ms
    T_Frame=122.5;  %帧长为122.5ms
    %排队与时延
    Normal_D_th=1000;    %正常通信的时延，单位ms
    Emergency_D_th=500;     %紧急通信的时延，单位ms
    Normal_P_Block=0;       %阻塞率
    Emergency_P_Block=0;    
    Normal_Kesee_A=0;   
    Normal_Kesee_B=[1;1;1;1;1]; %正常通信数据服务速率的方差值
    Emergency_Kesee_B=[0.5;0.5;0.5;0.5;0.5]; %紧急通信数据服务速率的方差值
    %节点
    distance=[69;36;48;23;34];%五个不同的节点到hub的距离，单位为cm
    d0=10; %参考距离为10cm
    P0_dB=[35.2;48.4];
    n=[3.11;5.9];
    sigma_X=[6.1;5];
    LOSorNLOS=[1,2,1,1,2];%为1表示LOS其它表示NLOS
    P_Noise_dB=-100;%噪声功率
    P_Out_th=0.01;%中断率门限
    P_Sensitivity=-90; %这里为了计算简单，将接收灵敏度设置为与数据速率无关的固定值
    BandWidth=1000;%单位kbps
    DataRate=[121.4;242.8;485.6;971.2]; %可选择的数据速率
    R_basic=121.4;    %节点数据速率
    Normal_SourceRate=[16;4.8;7;32;6.4];    %正常通信的数据速率，单位kbps
    Emergency_SourceRate_Ave=[4;1;2;6;2];     %紧急通信的平均数据速率,单位kbps
    %发射功率相关
    P_tx_min_dBm=-30;%设置的最小发射功率，单位为dBm
    P_tx_max_dBm=3;%设置的最大发射功率，单位为dBm。 
    %电路能耗和发射能耗相关参数
    a=2.4;
    b=5.8;    
    %包大小
    Normal_L_packet=ceil(Normal_SourceRate*T_Frame);    %设置包的大小
    index=find(Normal_L_packet>255*8);
        %如果有产生的数据量大于一个包所能发送的最大数据量，将这些数据进行均匀分包
        if size(index,1)>0  
              Normal_L_packet(index)=ceil(Normal_L_packet(index)/ceil(Normal_L_packet(index)/(255*8))); %根据T内产生的数据比特数，进行均匀分包
        end;
    Emergency_L_packet=ceil(Emergency_SourceRate_Ave*T_Frame);    
    index=find(Emergency_L_packet>255*8);
         %如果有产生的数据量大于一个包所能发送的最大数据量，将这些数据进行均匀分包
        if size(index,1)>0  
              Emergency_L_packet(index)=ceil(Emergency_L_packet(index)/ceil(Emergency_L_packet(index)/(255*8))); %根据T内产生的数据比特数，进行均匀分包
        end;
    %BCH编码
    n_BCH_PSDU=63;  %BCH编码参数
    k_BCH_PSDU=51;
    t_BCH_PSDU=2;
    %丢包率门限->误比特率
    Normal_PLR_th=0.05; %正常通信的丢包率门限
    Emergency_PLR_th=0.002; %紧急通信的丢包率门限 

    %计算硬件导致的发射门限
    P_tx_min=power(10,P_tx_min_dBm/10); %最小发射功率，单位为mw
    P_tx_max=power(10,P_tx_max_dBm/10); %最大发射功率，单位为mw
    
    

