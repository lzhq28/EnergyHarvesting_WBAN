%加载配置文件
shadowAndNumPacketPATH='shadowAndNumPacket.mat';
load(shadowAndNumPacketPATH)

%配置基本参数
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

%研究节点1，在walk姿势下，研究不同数据速率情况下平均丢包率与功率之间的关系图
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
