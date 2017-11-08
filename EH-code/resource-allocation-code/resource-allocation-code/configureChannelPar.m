
N_Node=5;
posNum=3; %姿势的数量
%% 实验中需要修改的参数
T_Slot=0.5;%d单个时隙长度为1ms
T_Frame=100;  %帧长为100ms
N_ch=1000; %实验的超帧数
Normal_D_th=1000;    %正常通信的时延，单位ms
Emergency_D_th=500;     %紧急通信的时延，单位ms
delayTh=[Normal_D_th;Emergency_D_th];

%丢包率门限->误比特率
 
Normal_SourceRate=[40,68,34,50,35];    %正常通信的数据速率，单位kbps
Emergency_SourceRate_Ave=[10,10,10,10,10];     %紧急通信的平均数据速率,单位kbps
%avePLRth=[0.05,0.005]; %平均丢包率的门限
Rate=[Normal_SourceRate;Emergency_SourceRate_Ave];

%发射功率相关
P_tx_min_dBm=-30;%设置的最小发射功率，单位为dBm
P_tx_max_dBm=0;%设置的最大发射功率，单位为dBm。 
%P_rx = 400uw; %设置接收功率
%电路能耗是发射功率的线性关系
a=2.4;%电路能耗和发射能耗相关参数
b=0; 
PNoise=-94;
deltaPL=18;

figureShow =0;
%包大小
maxLenPacket=255;
Normal_L_packet=ceil(Rate(1,:)*T_Frame);    %设置包的大小
index=find(Normal_L_packet>maxLenPacket*8);
%如果有产生的数据量大于一个包所能发送的最大数据量，将这些数据进行均匀分包
if size(index,1)>0  
      Normal_L_packet(index)=ceil(Normal_L_packet(index)./ceil(Normal_L_packet(index)/(maxLenPacket*8))); %根据T内产生的数据比特数，进行均匀分包
end;
numNormalPacket=ceil(ceil(Rate(1,:)*T_Frame)./Normal_L_packet);
Emergency_L_packet=ceil(ceil(Rate(2,:)*T_Frame));    
index=find(Emergency_L_packet>maxLenPacket*8);
     %如果有产生的数据量大于一个包所能发送的最大数据量，将这些数据进行均匀分包
if size(index,1)>0  
      Emergency_L_packet(index)=ceil(Emergency_L_packet(index)./ceil(Emergency_L_packet(index)/(maxLenPacket*8))); %根据T内产生的数据比特数，进行均匀分包
end;
Emergency_Size_Byte=50;
Emergency_L_packet=ones(1,N_Node)*Emergency_Size_Byte*8;
numEmergencyPacket=ceil(ceil(Rate(2,:)*T_Frame)./Emergency_L_packet);
lenPacket=[Normal_L_packet;Emergency_L_packet];

%% 求在不同的姿势下的信噪比方差，经验值
Posture={'still','walk','run'};
probPosture=[0.5 0.3 0.2]; %不同姿势状态下的稳态概率
N_Posture=size(Posture,2);%姿势的个数
NodeKeseTmp{1}=[
    6.0475	4.8124	5.1064	2.6247	2.2669
    0.28	0.60	0.26	0.24	0.24    
];
NodeKeseTmp{2}=[
    4.9483	7.2704	4.2025	3.0444	2.5985
    2.20	1.52	2.66	3.27	2.57
];
NodeKeseTmp{3}=[
    5.7060	7.5404	3.8987	3.5210	1.9647
    2.19	2.00	2.37	1.98	1.80
];
NodeKese(1,:)=sqrt(NodeKeseTmp{1}(1,:).^2+NodeKeseTmp{1}(2,:).^2);%不同状态下的信噪比标准差
NodeKese(2,:)=sqrt(NodeKeseTmp{2}(1,:).^2+NodeKeseTmp{2}(2,:).^2);
NodeKese(3,:)=sqrt(NodeKeseTmp{3}(1,:).^2+NodeKeseTmp{3}(2,:).^2);
 