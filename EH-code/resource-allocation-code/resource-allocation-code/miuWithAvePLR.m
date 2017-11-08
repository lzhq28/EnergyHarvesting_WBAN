%% 计算不同节点在不同的丢包率约束下的miuTH,并将结果进行保存并返回值,运行时间将会比较长
function [miuThNode,avePLRSet]=miuWithAvePLR()
%加载配置文件
% clc
% clear all
%% 判断要求数据是否已经存在，如果存在直接加载，否则进行计算得到
    format short %开启高精度
    configureChannelPar
    avePLRSet=[0.3 0.275 0.25 0.225 0.2 0.175 0.15 0.125 0.1 0.075 0.05 0.025 0.01 0.005];
    pathInfo='./data/miuThNode';
    for i=1:size(avePLRSet,2)
        if i==size(avePLRSet,2)
            pathInfo=strcat(pathInfo,num2str(avePLRSet(i)),'.mat');
        else
            pathInfo=strcat(pathInfo,num2str(avePLRSet(i)),'-');
        end
    end;
    if(exist(pathInfo,'file')==2) %
       load(pathInfo')
       disp(strcat(['函数miuWithAvePLR提示：','数据文件存在将直接加载获得。']))
       return
    end
%% 参数设置 
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
    numEmergencyPacket=ceil(ceil(Rate(2,:)*T_Frame)./Emergency_L_packet);
%% 求在不同的姿势下的信噪比方差，经验值
    Posture={'still','walk','run'};

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

    lenPacket=[Normal_L_packet;Emergency_L_packet];
%% miu参数设置
    miuMin=0;
    miuMax=30;
    delta=[0.001 0.0005];
    %% 并行计算,思想，在给定的平均丢包率门限情况下，可以使用二分法来求出相应的门限值
    parFlag=1; %是否采用并行计算
    if(parFlag)
        tmpMiuThNode={};
        parfor i=1:N_Node
            tmpResult={};
            for pos =1:size(Posture,2)
                NP=N_Node*pos-N_Node+i
                disp(strcat(['(NP,i,pos):',num2str(NP),',',num2str(i),',',num2str(pos)]))
                kesi=NodeKese(pos,i);
                sliceResult=[]
                tic
                for h=1:size(avePLRSet,2)
                    for m=1:2
                        length = lenPacket(m,i);
                        sliceResult(m,h) = binarySearch(miuMin,miuMax,kesi,length,avePLRSet(h),delta(m));
                        %miuThNode{i,pos}(m,h)=binarySearch(miuMin,miuMax,kesi,length,avePLRSet(h),delta(m));
                    end
                end
                toc
                tmpResult{pos}=sliceResult;
            end
            tmpMiuThNode{i}=tmpResult;
        end
        % 对miuTh结果按照{nodeIndex,postureType}(normalORemergency,plrTH)进行重新排序
        for i=1:N_Node 
            for pos =1:size(Posture,2)
                miuThNode{i,pos}=tmpMiuThNode{i}{pos}
            end
        end
    else %否则不是并行进行计算
        %由方差得到相应的均值与平均丢包率之间的关系。
         for h=1:size(avePLRSet,2)
            for i=1:N_Node
                for pos=1:size(Posture,2)
                    kesi=NodeKese(pos,i);          
                    for m=1:2
                         length=lenPacket(m,i);
                         miuThNode{i,pos}(m,h)=binarySearch(miuMin,miuMax,kesi,length,avePLRSet(h),delta(m));                
                    end;
                end;
            end;
         end;
    end

%% 保存数据
    save(pathInfo,'miuThNode','avePLRSet','pathInfo')
 

