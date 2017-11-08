%���������ļ�
shadowAndNumPacketPATH='shadowAndNumPacket.mat';
load(shadowAndNumPacketPATH)

%���û�������
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

%�о��ڵ�1����walk�����£��о���ͬ�������������ƽ���������빦��֮��Ĺ�ϵͼ
P_tx_dB=repmat(miuThNode{1,1}(1,:)+NoPL(1)+PNoise,4,1)-repmat(10*log10(BandWidth./DataRate),size(miuThNode{1,1}(1,:)),1)

figure()
plot(100*avePLRSet,P_tx_dB(1,:),'--o','Color',[0.043 0.518 0.78],'lineWidth',2.5,'MarkerSize',8)
hold on
plot(100*avePLRSet,P_tx_dB(2,:),'--o','Color',[1.0 0.4 0.4],'lineWidth',2.5,'MarkerSize',8)
hold on
plot(100*avePLRSet,P_tx_dB(3,:),'--*','Color',[0.043 1 1],'lineWidth',2.5,'MarkerSize',8)
hold on
plot(100*avePLRSet,P_tx_dB(4,:),'--*','Color',[1.0 0.5 1],'lineWidth',2.5,'MarkerSize',8)
grid on
ylabel('Transmission Power (dB)')
xlabel('Average PLR(%)')
title('Transmission Power VS Average PLR')
legend('Tranmission Rate=121.4kbps','Tranmission Rate=242.8;kbps','Tranmission Rate=485.6kbps','Tranmission Rate=971.2kbps')
