
N_Node=5;
posNum=3; %���Ƶ�����
%% ʵ������Ҫ�޸ĵĲ���
T_Slot=0.5;%d����ʱ϶����Ϊ1ms
T_Frame=100;  %֡��Ϊ100ms
N_ch=1000; %ʵ��ĳ�֡��
Normal_D_th=1000;    %����ͨ�ŵ�ʱ�ӣ���λms
Emergency_D_th=500;     %����ͨ�ŵ�ʱ�ӣ���λms
delayTh=[Normal_D_th;Emergency_D_th];

%����������->�������
 
Normal_SourceRate=[40,68,34,50,35];    %����ͨ�ŵ��������ʣ���λkbps
Emergency_SourceRate_Ave=[10,10,10,10,10];     %����ͨ�ŵ�ƽ����������,��λkbps
%avePLRth=[0.05,0.005]; %ƽ�������ʵ�����
Rate=[Normal_SourceRate;Emergency_SourceRate_Ave];

%���书�����
P_tx_min_dBm=-30;%���õ���С���书�ʣ���λΪdBm
P_tx_max_dBm=0;%���õ�����书�ʣ���λΪdBm�� 
%P_rx = 400uw; %���ý��չ���
%��·�ܺ��Ƿ��书�ʵ����Թ�ϵ
a=2.4;%��·�ܺĺͷ����ܺ���ز���
b=0; 
PNoise=-94;
deltaPL=18;

figureShow =0;
%����С
maxLenPacket=255;
Normal_L_packet=ceil(Rate(1,:)*T_Frame);    %���ð��Ĵ�С
index=find(Normal_L_packet>maxLenPacket*8);
%����в���������������һ�������ܷ��͵����������������Щ���ݽ��о��ȷְ�
if size(index,1)>0  
      Normal_L_packet(index)=ceil(Normal_L_packet(index)./ceil(Normal_L_packet(index)/(maxLenPacket*8))); %����T�ڲ��������ݱ����������о��ȷְ�
end;
numNormalPacket=ceil(ceil(Rate(1,:)*T_Frame)./Normal_L_packet);
Emergency_L_packet=ceil(ceil(Rate(2,:)*T_Frame));    
index=find(Emergency_L_packet>maxLenPacket*8);
     %����в���������������һ�������ܷ��͵����������������Щ���ݽ��о��ȷְ�
if size(index,1)>0  
      Emergency_L_packet(index)=ceil(Emergency_L_packet(index)./ceil(Emergency_L_packet(index)/(maxLenPacket*8))); %����T�ڲ��������ݱ����������о��ȷְ�
end;
Emergency_Size_Byte=50;
Emergency_L_packet=ones(1,N_Node)*Emergency_Size_Byte*8;
numEmergencyPacket=ceil(ceil(Rate(2,:)*T_Frame)./Emergency_L_packet);
lenPacket=[Normal_L_packet;Emergency_L_packet];

%% ���ڲ�ͬ�������µ�����ȷ������ֵ
Posture={'still','walk','run'};
probPosture=[0.5 0.3 0.2]; %��ͬ����״̬�µ���̬����
N_Posture=size(Posture,2);%���Ƶĸ���
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
NodeKese(1,:)=sqrt(NodeKeseTmp{1}(1,:).^2+NodeKeseTmp{1}(2,:).^2);%��ͬ״̬�µ�����ȱ�׼��
NodeKese(2,:)=sqrt(NodeKeseTmp{2}(1,:).^2+NodeKeseTmp{2}(2,:).^2);
NodeKese(3,:)=sqrt(NodeKeseTmp{3}(1,:).^2+NodeKeseTmp{3}(2,:).^2);
 